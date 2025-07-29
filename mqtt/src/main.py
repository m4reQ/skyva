import datetime
import json
import logging
import os
import typing as t

import mysql.connector as mysql
import paho.mqtt.client as mqtt
import paho.mqtt.properties as mqtt_properties
import paho.mqtt.reasoncodes as mqtt_reasoncodes

MQTT_LOGS_TOPIC_NAME = os.environ['MQTT_LOGS_TOPIC_NAME']
MQTT_MEASUREMENTS_TOPIC_NAME = os.environ['MQTT_MEASUREMENTS_TOPIC_NAME']
MQTT_MEASUREMENTS_PUBLIC_TOPIC_NAME = os.environ['MQTT_MEASUREMENTS_PUBLIC_TOPIC_NAME']
INSERT_MEASUREMENTS_QUERY = '''
    INSERT INTO measurements(
        timestamp,
        particle_concentration,
        temperature,
        humidity,
        co2_concentration,
        tvoc_concentration,
        sensor_status,
        aqi,
        aqi_classification)
    VALUES(
        %(timestamp)s,
        %(particle_concentration)s,
        %(temperature)s,
        %(humidity)s,
        %(co2_concentration)s,
        %(tvoc_concentration)s,
        %(sensor_status)s,
        %(aqi)s,
        %(aqi_classification)s);'''
DB_INIT_QUERY = '''
    CREATE TABLE IF NOT EXISTS measurements(
        id INT PRIMARY KEY AUTO_INCREMENT,
        timestamp TIMESTAMP NOT NULL DEFAULT now(),
        particle_concentration DOUBLE,
        temperature DOUBLE,
        humidity DOUBLE,
        co2_concentration INT,
        tvoc_concentration INT,
        sensor_status INT NOT NULL,
        aqi DOUBLE NOT NULL,
        aqi_classification VARCHAR(32) NOT NULL);'''
PARTICLE_CONCENTRATION_RANGE = (0, 150)
CO2_CONCENTRATION_RANGE = (400, 2000)
TVOC_CONCENTRATION_RANGE = (0, 2000)
PARTICLE_AQI_WEIGHT = 0.5
CO2_AQI_WEIGHT = 0.3
TVOC_AQI_WEIGHT = 0.2

class JSONEncoder(json.JSONEncoder):
    def default(self, o: t.Any) -> str:
        if isinstance(o, datetime.datetime):
            return o.isoformat()

        return super().default(o)

def calculate_partial_aqi(value: float, _range: tuple[float, float]) -> float:
    return min(100, max(0, ((value - _range[0]) / (_range[1] - _range[0])) * 100))

def get_aqi_classification(aqi: float) -> str:
    if 0 < aqi < 25:
        return 'good'
    elif 25 < aqi < 50:
        return 'moderate'
    elif 50 < aqi < 75:
        return 'poor'

    return 'hazardous'

def calculate_aqi(particle_concentration: float,
                  co2_concentration: float,
                  tvoc_concentration: float) -> tuple[float, str]:
    particle_aqi = calculate_partial_aqi(particle_concentration, PARTICLE_CONCENTRATION_RANGE)
    co2_aqi = calculate_partial_aqi(co2_concentration, CO2_CONCENTRATION_RANGE)
    tvoc_aqi = calculate_partial_aqi(tvoc_concentration, TVOC_CONCENTRATION_RANGE)
    composite_aqi = particle_aqi * PARTICLE_AQI_WEIGHT + co2_aqi * CO2_AQI_WEIGHT + tvoc_aqi * TVOC_AQI_WEIGHT

    return (composite_aqi / 100, get_aqi_classification(composite_aqi))

def try_decode_mqtt_payload_utf8(payload: bytes) -> str:
    try:
        return payload.decode('utf-8')
    except UnicodeError as e:
        logger.error('Failed to decode MQTT payload: %s.', e)
        return ''

def validate_measurement_data(data: dict[str, t.Any]) -> bool:
    return all((
        'particle_concentration' in data,
        'temperature' in data,
        'humidity' in data,
        'co2_concentration' in data,
        'tvoc_concentration' in data,
        'sensor_status' in data))

def try_decode_mqtt_data_to_json(payload: bytes) -> dict[str, t.Any] | None:
    payload_str = try_decode_mqtt_payload_utf8(payload)
    if len(payload_str) == 0:
        return None

    try:
        measurement_data = json.loads(payload_str)
    except json.JSONDecodeError as e:
        logger.error('Failed to decode JSON data string: %s.', e)
        return None

    return measurement_data

def save_db_measurement_data(measurement_data: dict[str, t.Any]) -> None:
    try:
        cursor = db.cursor()
        cursor.execute(INSERT_MEASUREMENTS_QUERY, measurement_data)
        cursor.close()
    except mysql.Error as e:
        logger.error('Failed to insert measurement data to database: %s.', e)

    logger.debug('Saved measurement data in database.')

def add_aqi_to_measurement_data(data: dict[str, t.Any]) -> None:
    data['aqi'], data['aqi_classification'] = calculate_aqi(
        data['particle_concentration'],
        data['co2_concentration'],
        data['tvoc_concentration'])

def add_timestamp_to_measurement_data(data: dict[str, t.Any]) -> None:
    data['timestamp'] = datetime.datetime.now()

def publish_public_measurement_data(data: dict[str, t.Any]) -> None:
    payload = json.dumps(data, cls=JSONEncoder)
    mqtt_client.publish(MQTT_MEASUREMENTS_PUBLIC_TOPIC_NAME, payload)

    logger.debug('Queued measurement data publish on topic "%s".', MQTT_MEASUREMENTS_PUBLIC_TOPIC_NAME)

def mqtt_connect_callback(client: mqtt.Client,
               user_data: t.Any,
               flags: mqtt.ConnectFlags,
               reason_code: mqtt_reasoncodes.ReasonCode,
               properties: mqtt_properties.Properties) -> None:
    client.subscribe(MQTT_MEASUREMENTS_TOPIC_NAME)
    client.subscribe(MQTT_LOGS_TOPIC_NAME)
    logger.info('Connected to MQTT server.')

def mqtt_message_callback(client: mqtt.Client,
                          user_data: t.Any,
                          message: mqtt.MQTTMessage) -> None:
    logger.info('MQTT message received (topic: %s, timestamp: %f).', message.topic, message.timestamp)

    if message.topic == MQTT_MEASUREMENTS_TOPIC_NAME:
        measurement_data = try_decode_mqtt_data_to_json(message.payload)
        if measurement_data is None:
            logger.warning('Ignoring MQTT message with malformed measurements data.')
            return

        if not validate_measurement_data(measurement_data):
            logger.error('Retrieved measurement data is incomplete.')
            return

        add_aqi_to_measurement_data(measurement_data)
        add_timestamp_to_measurement_data(measurement_data)

        publish_public_measurement_data(measurement_data)
        save_db_measurement_data(measurement_data)

        logger.info('Finished processing measurement data.')
    elif message.topic == MQTT_LOGS_TOPIC_NAME:
        log_data = try_decode_mqtt_data_to_json(message.payload)
        if log_data is None:
            logger.error('Received device message via MQTT but the payload was malformed.')
            return

        logger.info('Sensor message (machine timestamp: %d): %s', log_data.get('timestamp', 0), log_data.get('message'))
    else:
        logger.debug('Ignoring MQTT message on topic: %s.', message.topic)

def mqtt_log_callback(client: mqtt.Client, userdata: t.Any, level: int, msg: str) -> None:
    if level == mqtt.MQTT_LOG_DEBUG:
        logger.debug(msg)
    elif level == mqtt.MQTT_LOG_INFO or level == mqtt.MQTT_LOG_NOTICE:
        logger.info(msg)
    elif level == mqtt.MQTT_LOG_WARNING:
        logger.warning(msg)
    elif level == mqtt.MQTT_LOG_ERR:
        logger.error(msg)

def setup_database() -> None:
    global db

    host = os.environ['MYSQL_HOST']
    user = os.environ['MYSQL_USER']
    database = os.environ['MYSQL_DATABASE']
    db = mysql.connect(
        host=host,
        user=user,
        password=os.environ['MYSQL_PASSWORD'],
        database=database,
        init_command=DB_INIT_QUERY,
        autocommit=True)

    # Fixes bug inside mysql.connector that breaks when using `info_query`
    if isinstance(db, mysql.connection.MySQLConnectionAbstract):
        db._sql_mode = 'NO_AUTO_CREATE_USER,TRADITIONAL,REAL_AS_FLOAT'

    logger.info('Connected to the database at %s (user: %s, database: %s).', host, user, database)

def setup_mqtt() -> None:
    global mqtt_client

    mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id='SkyvaBridgeMQTTClient')
    mqtt_client.on_connect = mqtt_connect_callback # type: ignore[assignment]
    mqtt_client.on_message = mqtt_message_callback
    mqtt_client.on_log = mqtt_log_callback

    host = os.environ['MQTT_HOST']
    port = int(os.environ['MQTT_PORT'])
    mqtt_client.connect(host, port)

    logger.info('Created MQTT client on %s:%d.', host, port)

def main() -> None:
    logger.info('Starting MQTT bridge...')

    setup_database()
    setup_mqtt()

    logger.info('MQTT bridge running')

    mqtt_client.loop_forever(retry_first_connection=True)

    logger.info('Closing MQTT bridge...')

logger = logging.getLogger(__name__)
mqtt_client: mqtt.Client
db: mysql.pooling.PooledMySQLConnection | mysql.connection.MySQLConnectionAbstract

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG if __debug__ else logging.INFO)
    main()
