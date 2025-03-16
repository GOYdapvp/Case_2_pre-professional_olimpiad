import tkinter as tk
from tkinter import messagebox
import requests
import numpy as np
import matplotlib.pyplot as plt

def get_tile(url):
    response = requests.get(url)
    return response.json()['message']['data']

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
url = 'https://olimp.miet.ru/ppo_it/api'
map_data = assemble_map(url)
peaks = find_peaks(map_data)
stations = place_stations(peaks)

class Application(tk.Frame):
    def __init__(self, master=None):
        super().__init__(master)
        self.master = master
        self.pack()
        self.create_widgets()

    def create_widgets(self):
        self.url_label = tk.Label(self)
        self.url_label["text"] = "URL сервиса:"
        self.url_label.pack(side="top")

        self.url_entry = tk.Entry(self)
        self.url_entry.pack(side="top")

        self.assemble_button = tk.Button(self)
        self.assemble_button["text"] = "Собрать карту"
        self.assemble_button["command"] = self.assemble_map
        self.assemble_button.pack(side="top")

        self.show_stations_button = tk.Button(self)
        self.show_stations_button["text"] = "Показать базовые станции"
        self.show_stations_button["command"] = self.show_stations
        self.show_stations_button.pack(side="top")

        self.quit = tk.Button(self, text="QUIT", fg="red",
                              command=self.master.destroy)
        self.quit.pack(side="bottom")

    def assemble_map(self):
        url = self.url_entry.get()
        # Собрать карту и отобразить ее
        map_data = assemble_map(url)
        plt.imshow(map_data, cmap='gray')
        plt.show()

    def show_stations(self):
        url = self.url_entry.get()
        map_data = assemble_map(url)
        peaks = find_peaks(map_data)
        stations = place_stations(peaks)
        # Отобразить базовые станции на карте
        plt.imshow(map_data, cmap='gray')
        for station in stations:
            if station['type'] == 'Купер':
                plt.plot(station['location'][1], station['location'][0], 'bo')
            else:
                plt.plot(station['location'][1], station['location'][0], 'ro')
        plt.show()

root = tk.Tk()
app = Application(master=root)
app.mainloop()
