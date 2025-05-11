import json
import logging
import os
import typing as t

import mysql.connector as mysql
import paho.mqtt.client as mqtt
import paho.mqtt.properties as mqtt_properties
import paho.mqtt.reasoncodes as mqtt_reasoncodes

MEASUREMENTS_TOPIC_NAME = 'measurements'
INSERT_MEASUREMENTS_QUERY = '''
    INSERT INTO measurements(
        particle_concentration,
        temperature,
        humidity,
        co2_concentration,
        tvoc_concentration,
        sensor_status)
    VALUES(%s, %s, %s, %s, %s, %s);'''
DB_INIT_QUERY = '''
    CREATE TABLE IF NOT EXISTS measurements(
        id INT PRIMARY KEY AUTO_INCREMENT,
        timestamp TIMESTAMP NOT NULL DEFAULT now(),
        particle_concentration DOUBLE,
        temperature DOUBLE,
        humidity DOUBLE,
        co2_concentration INT,
        tvoc_concentration INT,
        sensor_status INT NOT NULL);'''

def try_decode_mqtt_payload_utf8(payload: bytes) -> str:
    try:
        return payload.decode('utf-8')
    except UnicodeError as e:
        logger.error('Failed to decode MQTT payload: %s.', e)
        return ''

def decode_measurement_data(payload: bytes) -> dict[str, t.Any]:
    payload_str = try_decode_mqtt_payload_utf8(payload)
    if len(payload_str) == 0:
        return {}

    try:
        return json.loads(payload_str)
    except json.JSONDecodeError as e:
        logger.error('Failed to decode JSON measurement data string: %s.', e)
        return {}

def get_measurement_query_params(measurement_data: dict[str, t.Any]) -> list[t.Any] | None:
    try:
        return [
            measurement_data['particle_concentration'],
            measurement_data['temperature'],
            measurement_data['humidity'],
            measurement_data['co2_concentration'],
            measurement_data['tvoc_concentration'],
            measurement_data['sensor_status']]
    except KeyError as e:
        logger.error('Failed to convert measurement data while preparing insert query: %s.', e)
        return None

def save_db_measurement_data(measurement_data: dict[str, t.Any]) -> None:
    query_params = get_measurement_query_params(measurement_data)
    if query_params is None:
        logger.warning('Ignoring measurement insert request because query params are empty.')
        return

    cursor = db.cursor()
    cursor.execute(INSERT_MEASUREMENTS_QUERY, query_params)
    cursor.close()

def on_connect(client: mqtt.Client,
               user_data: t.Any,
               flags: mqtt.ConnectFlags,
               reason_code: mqtt_reasoncodes.ReasonCode,
               properties: mqtt_properties.Properties) -> None:
    logger.info('Connected to MQTT server.')
    client.subscribe(MEASUREMENTS_TOPIC_NAME)

def on_message(client: mqtt.Client,
               user_data: t.Any,
               message: mqtt.MQTTMessage) -> None:
    logger.info('MQTT message received (topic: %s, timestamp: %f).', message.topic, message.timestamp)

    if message.topic == MEASUREMENTS_TOPIC_NAME:
        measurement_data = decode_measurement_data(message.payload)
        save_db_measurement_data(measurement_data)
        logger.info('Saved measurement data into database: %s.', measurement_data)
    else:
        logger.debug('Ignoring MQTT message on topic: %s.', message.topic)

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

    mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    mqtt_client.on_connect = on_connect # type: ignore[assignment]
    mqtt_client.on_message = on_message

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
