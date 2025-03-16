import requests
import numpy as np
import matplotlib.pyplot as plt

def get_tile(url):
    response = requests.get(url)
    return response.json()['data']

def assemble_map(url):
    tiles = []
    while len(tiles) < 16:
        tile = get_tile(url)
        if tile not in tiles:
            tiles.append(tile)
    # Собрать тайлы в единую карту
    map_data = np.zeros((256, 256))
    for i, tile in enumerate(tiles):
        x = (i % 4) * 64
        y = (i // 4) * 64
        map_data[y:y+64, x:x+64] = tile
    return map_data

def find_peaks(map_data):
    peaks = []
    for i in range(1, 255):
        for j in range(1, 255):
            if map_data[i, j] > map_data[i-1, j] and map_data[i, j] > map_data[i+1, j] and \
               map_data[i, j] > map_data[i, j-1] and map_data[i, j] > map_data[i, j+1]:
                peaks.append((i, j))
    return peaks

def place_stations(peaks):
    stations = []
    for peak in peaks:
        # Разместить станцию типа "Купер"
        stations.append({'type': 'Купер', 'location': peak})
    
    # Разместить станции типа "Энгель" между пиками
    for i in range(len(peaks) - 1):
        mid_x = (peaks[i][0] + peaks[i+1][0]) // 2
        mid_y = (peaks[i][1] + peaks[i+1][1]) // 2
        stations.append({'type': 'Энгель', 'location': (mid_x, mid_y)})
    
    return stations

# Пример использования
url = 'http://example.com/tile'
map_data = assemble_map(url)
peaks = find_peaks(map_data)
stations = place_stations(peaks)

# Отображение карты и базовых станций
plt.imshow(map_data, cmap='gray')
for station in stations:
    if station['type'] == 'Купер':
        plt.plot(station['location'][1], station['location'][0], 'bo')
    else:
        plt.plot(station['location'][1], station['location'][0], 'ro')
plt.show()
