import requests
import json

BASE_URL = "http://127.0.0.1:8000/products/"

# Функция для добавления продуктов
def add_products(products):
    response = requests.post(BASE_URL, json=products)
    if response.status_code == 200:
        print("Продукты успешно добавлены:")
        print(response.json())
    else:
        print(f"Ошибка при добавлении продуктов: {response.status_code} - {response.text}")

def get_all_products():
    response = requests.get(BASE_URL)
    if response.status_code == 200:
        print("Список всех продуктов:")
        data1 = response.json()
        data1.append("Список всех продуктов")
        return data1
    else:
        print(f"Ошибка при получении списка продуктов: {response.status_code} - {response.text}")

def get_product_by_id(product_id):
    response = requests.get(f"{BASE_URL}{product_id}/")
    if response.status_code == 200:
        print(f"Информация о продукте с ID {product_id}:")
        data1 = response.json()
        data1["comments"] = "Информация о продукте с ID " + str(product_id)
        return data1
    else:
        print(f"Ошибка при получении продукта с ID {product_id}: {response.status_code} - {response.text}")

def read_products_from_file(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as file:
            products = json.load(file)
            return products
    except UnicodeDecodeError as e:
        print(f"Ошибка кодировки при чтении файла {filename}: {e}")
        return []
    except Exception as e:
        print(f"Ошибка при чтении файла {filename}: {e}")
        return []


if __name__ == "__main__":
    filename = "file.json"
    products_to_add = read_products_from_file(filename)

    if products_to_add:
        if products_to_add[0]["request"] == "post":
            products_to_add[0] = {k: v for k, v in products_to_add[0].items() if k != 'request'}
            add_products(products_to_add)

        elif products_to_add[0]["request"] == "get":
            data = get_all_products()

            with open("products.json", "w", encoding="utf-8") as json_file:
                json_file.truncate(0)
                json.dump(data, json_file, ensure_ascii=False, indent=4)

        elif products_to_add[0]["request"] == "get_id":
            get_id = products_to_add[0]["get_id"]
            products_to_add[0] = {k: v for k, v in products_to_add[0].items() if k != 'request' and k != "get_id"}
            data = get_product_by_id(get_id)

            with open("products.json", "w", encoding="utf-8") as json_file:
                json_file.truncate(0)
                json.dump(data, json_file, ensure_ascii=False, indent=4)

    else:
        print("Нет продуктов для добавления.")
