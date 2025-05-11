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
        sensor_status
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
        sensor_status
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
        sensor_status INT NOT NULL);'''

db: mysql.pooling.PooledMySQLConnection | mysql.connection.MySQLConnection
api = fastapi.FastAPI()
logger = logging.getLogger(__name__)

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

    return (composite_aqi, get_aqi_classification(composite_aqi))

def get_measurement_data_from_row(row: mysql_types.RowType) -> dict[str, t.Any]:
    (timestamp,
     particle_concentration,
     temperature,
     humidity,
     co2_concentration,
     tvoc_concentration,
     sensor_status) = row
    air_quality_score, air_quality = calculate_aqi(particle_concentration, co2_concentration, tvoc_concentration) # type: ignore[arg-type]

    return {
        'timestamp': timestamp,
        'sensor_status': sensor_status,
        'air_quality_index': {
            'score': air_quality_score,
            'classification': air_quality},
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
    cursor = db.cursor()
    cursor.execute(GET_MEASUREMENTS_QUERY, (limit, skip))

    rows = cursor.fetchall()

    cursor.close()

    return {
        'first': skip,
        'count': len(rows),
        'measurements': [get_measurement_data_from_row(x) for x in rows]}

@api.get('/measurement')
async def get_measurement():
    cursor = db.cursor()
    cursor.execute(GET_LATEST_MEASUREMENT_QUERY)

    row = cursor.fetchone()

    cursor.close()

    return get_measurement_data_from_row(row)
