# Импорт необходимых библиотек
import tkinter as tk
from tkinter import messagebox
import requests
import numpy as np
import matplotlib.pyplot as plt

# Функция для получения тайла карты по URL
def get_tile(url):
    """
    Получает тайл карты из указанного URL.
    
    :param url: URL для получения тайла
    :return: Данные тайла
    """
    response = requests.get(url)
    return response.json()['message']['data']

# Функция для сборки полной карты из тайлов
def assemble_map(url):
    """
    Собирает полную карту из тайлов, полученных по URL.
    
    :param url: URL для получения тайлов
    :return: Данные полной карты
    """
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

# Функция для поиска пиков на карте
def find_peaks(map_data):
    """
    Находит пики на карте, где значение больше соседних точек.
    
    :param map_data: Данные карты
    :return: Список пиков
    """
    peaks = []
    for i in range(1, 255):
        for j in range(1, 255):
            if map_data[i, j] > map_data[i-1, j] and map_data[i, j] > map_data[i+1, j] and \
               map_data[i, j] > map_data[i, j-1] and map_data[i, j] > map_data[i, j+1]:
                peaks.append((i, j))
    return peaks

# Функция для размещения станций на карте
def place_stations(peaks):
    """
    Размещает станции типа "Купер" на пиках и станции типа "Энгель" между пиками.
    
    :param peaks: Список пиков
    :return: Список станций
    """
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

# Функция для получения стоимости станций по URL
def get_station_costs(url):
    """
    Получает стоимость станций типа "Купер" и "Энгель" из указанного URL.
    
    :param url: URL для получения стоимости станций
    :return: Стоимость станций типа "Купер" и "Энгель"
    """
    try:
        response = requests.get(url)
        data = response.json()
        cost_kuper = data['message']['price'][0]
        cost_engel = data['message']['price'][1]
        return cost_kuper, cost_engel
    except Exception as e:
        messagebox.showerror("Ошибка", f"Не удалось получить стоимость станций: {e}")

# Функция для расчета общей стоимости станций
def calculate_cost(stations, cost_kuper, cost_engel):
    """
    Рассчитывает общую стоимость всех станций.
    
    :param stations: Список станций
    :param cost_kuper: Стоимость станции типа "Купер"
    :param cost_engel: Стоимость станции типа "Энгель"
    :return: Количество станций каждого типа и общая стоимость
    """
    total_cost = 0
    kuper_count = 0
    engel_count = 0
    for station in stations:
        if station['type'] == 'Купер':
            total_cost += cost_kuper
            kuper_count += 1
        else:
            total_cost += cost_engel
            engel_count += 1
    return kuper_count, engel_count, total_cost

# Класс для создания GUI-приложения
class Application(tk.Frame):
    def __init__(self, master=None):
        super().__init__(master)
        self.master = master
        self.pack()
        self.create_widgets()

    # Метод для создания виджетов в приложении
    def create_widgets(self):
        # Метка и поле для ввода URL карты
        self.map_url_label = tk.Label(self)
        self.map_url_label["text"] = "URL карты:"
        self.map_url_label.pack(side="top")

        self.map_url_entry = tk.Entry(self)
        self.map_url_entry.pack(side="top")

        # Метка и поле для ввода URL стоимости станций
        self.cost_url_label = tk.Label(self)
        self.cost_url_label["text"] = "URL стоимости станций:"
        self.cost_url_label.pack(side="top")

        self.cost_url_entry = tk.Entry(self)
        self.cost_url_entry.pack(side="top")

        # Кнопка для сборки карты
        self.assemble_button = tk.Button(self)
        self.assemble_button["text"] = "Собрать карту"
        self.assemble_button["command"] = self.assemble_map
        self.assemble_button.pack(side="top")

        # Кнопка для показа базовых станций
        self.show_stations_button = tk.Button(self)
        self.show_stations_button["text"] = "Показать базовые станции"
        self.show_stations_button["command"] = self.show_stations
        self.show_stations_button.pack(side="top")

        # Кнопка для выхода из приложения
        self.quit = tk.Button(self, text="QUIT", fg="red",
                              command=self.master.destroy)
        self.quit.pack(side="bottom")

    # Метод для сборки и отображения карты
    def assemble_map(self):
        url = self.map_url_entry.get()
        # Собрать карту и отобразить ее
        map_data = assemble_map(url)
        plt.imshow(map_data, cmap='gray')
        plt.show()

    # Метод для показа базовых станций на карте
    def show_stations(self):
        map_url = self.map_url_entry.get()
        cost_url = self.cost_url_entry.get()
        
        # Собрать карту
        map_data = assemble_map(map_url)
        
        # Найти пики на карте
        peaks = find_peaks(map_data)
        
        # Разместить станции на карте
        stations = place_stations(peaks)
        
        # Получить стоимость станций
        cost_kuper, cost_engel = get_station_costs(cost_url)
        
        # Рассчитать общую стоимость станций
        kuper_count, engel_count, total_cost = calculate_cost(stations, cost_kuper, cost_engel)
        
        # Отобразить базовые станции на карте
        plt.imshow(map_data, cmap='gray')
        for station in stations:
            if station['type'] == 'Купер':
                plt.plot(station['location'][1], station['location'][0], 'bo')
            else:
                plt.plot(station['location'][1], station['location'][0], 'ro')
        plt.show()
        
        # Отобразить информацию о станциях и затраты
        messagebox.showinfo("Информация о станциях",
                             f"Количество станций типа 'Купер': {kuper_count}\n"
                             f"Количество станций типа 'Энгель': {engel_count}\n"
                             f"Общая стоимость: {round(total_cost,1)} байткоинов")

# Создать главное окно приложения
root = tk.Tk()
app = Application(master=root)
app.mainloop()

