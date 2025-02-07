"""
Подключение к базе данных.
"""

import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi import HTTPException

DATABASE_CONFIG = {
    "dbname": "postgres",
    "user": "postgres",
    "password": "12345",
    "host": "localhost",
    "port": 5432,
    "options": "-c client_encoding=UTF8"
}

def get_db_connection():
    try:
        conn = psycopg2.connect(**DATABASE_CONFIG, cursor_factory=RealDictCursor)
        return conn
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка подключения к базе данных: {e}")

