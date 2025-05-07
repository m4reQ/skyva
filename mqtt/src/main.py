import logging
import os
import typing as t

import mysql.connector as mysql
import paho.mqtt.client as mqtt
import paho.mqtt.properties as mqtt_properties
import paho.mqtt.reasoncodes as mqtt_reasoncodes


def insert_test_message(msg: str) -> None:
    cursor = db.cursor()
    cursor.execute('INSERT INTO test(message) VALUES(%s);', (msg,))
    cursor.close()

    db.commit()

def on_connect(client: mqtt.Client,
               user_data: t.Any,
               flags: mqtt.ConnectFlags,
               reason_code: mqtt_reasoncodes.ReasonCode,
               properties: mqtt_properties.Properties) -> None:
    logger.info('Connected to MQTT server.')
    client.subscribe('test')

def on_message(client: mqtt.Client,
               user_data: t.Any,
               message: mqtt.MQTTMessage) -> None:
    data = message.payload.decode('utf-8')
    logger.info('MQTT message received: %s (topic: %s, timestamp: %f).', data, message.topic, message.timestamp)

    if message.topic == 'test':
        insert_test_message(data)

def setup_database() -> None:
    global db

    host = os.environ['MYSQL_HOST']
    user = os.environ['MYSQL_USER']
    database = os.environ['MYSQL_DATABASE']
    db_init_command = '''
    CREATE TABLE IF NOT EXISTS test(
        id INT PRIMARY KEY AUTO_INCREMENT,
        timestamp TIMESTAMP NOT NULL DEFAULT now(),
        message VARCHAR(128) NOT NULL);'''
    db = mysql.connect(
        host=host,
        user=user,
        password=os.environ['MYSQL_PASSWORD'],
        database=database,
        init_command=db_init_command)

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
