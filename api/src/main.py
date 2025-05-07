import os

import fastapi
import mysql.connector as mysql

db: mysql.pooling.PooledMySQLConnection | mysql.connection.MySQLConnection
api = fastapi.FastAPI()

@api.on_event('startup')
def on_startup():
    global db

    db_init_command = '''
    CREATE TABLE IF NOT EXISTS test(
        id INT PRIMARY KEY AUTO_INCREMENT,
        timestamp TIMESTAMP NOT NULL DEFAULT now(),
        message VARCHAR(128) NOT NULL);'''
    db = mysql.connect(
        host=os.environ['MYSQL_HOST'],
        user=os.environ['MYSQL_USER'],
        password=os.environ['MYSQL_PASSWORD'],
        database=os.environ['MYSQL_DATABASE'],
        init_command=db_init_command)

@api.get('/test')
async def get_test():
    return {'Hello': 'world!'}

