import requests
from database import SessionLocal

def fetch_tile():
    response = requests.get("https://olimp.miet.ru/ppo_it/api")
    return response.json()

def fetch_coords():
    response = requests.get("https://olimp.miet.ru/ppo_it/api/coords")
    return response.json()

def assemble_map():
    db = SessionLocal()
    # Logic to fetch and assemble tiles
    pass

def calculate_stations():
    # Logic to calculate station positions
    pass
