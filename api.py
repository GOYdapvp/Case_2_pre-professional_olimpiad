from fastapi import APIRouter, HTTPException
from services import fetch_tile, fetch_coords, assemble_map, calculate_stations

router = APIRouter()

@router.get("/tile")
async def get_tile():
    tile = fetch_tile()
    if not tile:
        raise HTTPException(status_code=404, detail="Tile not found")
    return tile

@router.get("/coords")
async def get_coords():
    coords = fetch_coords()
    if not coords:
        raise HTTPException(status_code=404, detail="Coordinates not found")
    return coords

@router.get("/map")
async def get_map():
    map = assemble_map()
    return map

@router.get("/stations")
async def get_stations():
    stations = calculate_stations()
    return stations
