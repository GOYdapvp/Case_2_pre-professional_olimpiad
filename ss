import tkinter as tk
from tkinter import messagebox

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
