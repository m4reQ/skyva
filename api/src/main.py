import logging
import os
import typing as t

import fastapi
import mysql.connector as mysql
import mysql.connector.types as mysql_types

DEFAULT_MEASUREMENTS_GET_LIMIT = 10
PARTICLE_CONCENTRATION_RANGE = (0, 150)
CO2_CONCENTRATION_RANGE = (400, 2000)
TVOC_CONCENTRATION_RANGE = (0, 2000)
PARTICLE_AQI_WEIGHT = 0.5
CO2_AQI_WEIGHT = 0.3
TVOC_AQI_WEIGHT = 0.2
GET_MEASUREMENTS_QUERY = '''
    SELECT
        timestamp,
        particle_concentration,
        temperature,
        humidity,
        co2_concentration,
        tvoc_concentration,
        sensor_status,
        aqi,
        aqi_classification
    FROM measurements
    ORDER BY timestamp DESC
    LIMIT %s
    OFFSET %s;
    '''
GET_LATEST_MEASUREMENT_QUERY = '''
    SELECT
        timestamp,
        particle_concentration,
        temperature,
        humidity,
        co2_concentration,
        tvoc_concentration,
        sensor_status,
        aqi,
        aqi_classification
    FROM measurements
    ORDER BY timestamp DESC
    LIMIT 1;'''
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

db: mysql.pooling.PooledMySQLConnection | mysql.connection.MySQLConnection
api = fastapi.FastAPI()
logger = logging.getLogger(__name__)

def get_measurement_data_from_row(row: mysql_types.RowType) -> dict[str, t.Any]:
    (timestamp,
     particle_concentration,
     temperature,
     humidity,
     co2_concentration,
     tvoc_concentration,
     sensor_status,
     aqi,
     aqi_classification) = row

    return {
        'timestamp': timestamp,
        'sensor_status': sensor_status,
        'air_quality_index': {
            'score': aqi,
            'classification': aqi_classification},
        'particle_concentration': {
            'value': particle_concentration,
            'unit': 'ppm'},
        'temperature': {
            'value': temperature,
            'unit': 'celsius'},
        'humidity': {
            'value': humidity,
            'unit': 'percent'},
        'co2_concentration': {
            'value': co2_concentration,
            'unit': 'ppm'},
        'tvoc_concentration': {
            'value': tvoc_concentration,
            'unit': 'ppb'}}

def try_get_data_rows(limit: int, skip: int) -> list[mysql_types.RowType] | None:
    try:
        cursor = db.cursor()
        cursor.execute(GET_MEASUREMENTS_QUERY, (limit, skip))

        return cursor.fetchall()
    except mysql.errors.Error as e:
        logger.error('Failed to retrieve data rows: %s', e)
        return None
    finally:
        cursor.close()

def try_get_data_row() -> mysql_types.RowType | None:
    try:
        cursor = db.cursor()
        cursor.execute(GET_LATEST_MEASUREMENT_QUERY)

        return cursor.fetchone()
    except mysql.errors.Error as e:
        logger.error('Failed to retrieve data row: %s', e)
        return None
    finally:
        cursor.close()

def make_error_response(error_msg: str, status: int = fastapi.status.HTTP_500_INTERNAL_SERVER_ERROR) -> fastapi.Response:
    return fastapi.Response(content={'error': error_msg}, status_code=status)

@api.on_event('startup')
def on_startup():
    global db

    db = mysql.connect(
        host=os.environ['MYSQL_HOST'],
        user=os.environ['MYSQL_USER'],
        password=os.environ['MYSQL_PASSWORD'],
        database=os.environ['MYSQL_DATABASE'],
        init_command=DB_INIT_QUERY,
        autocommit=True)

@api.get('/test')
async def get_test():
    return {'Hello': 'world!'}

@api.get('/measurements')
async def get_measurements(skip: int = 0, limit: int = DEFAULT_MEASUREMENTS_GET_LIMIT):
    rows = try_get_data_rows(limit, skip)
    if rows is None:
        return make_error_response('Failed to retrieve data rows from database.')

    return {
        'first': skip,
        'count': len(rows),
        'measurements': [get_measurement_data_from_row(x) for x in rows]}

@api.get('/measurement')
async def get_measurement():
    row = try_get_data_row()
    if row is None:
        return make_error_response('Failed to retrieve data row from database.')

    return get_measurement_data_from_row(row)
