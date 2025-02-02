"""
Этот файл используется для распределения API.
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List
from app.models.product import Product, ProductBase
from app.db.connection import get_db_connection

router = APIRouter(prefix="/products", tags=["Products"])


# В твоем маршруте get_all_products()
@router.get("/", response_model=List[Product])
def get_all_products(user_id: int = Query(..., description="ID пользователя")):
    """Функция получения списка всех продуктов для конкретного пользователя."""
    query = """
    SELECT main.id, main.name, product_types.name AS product_type, units.name AS unit,
           main.quantity, main.nutritional_info, main.manufacture_date, main.expiration_date
    FROM main
    JOIN product_types ON main.type_id = product_types.id
    JOIN units ON main.unit_id = units.id
    WHERE main.user_id = %s;
    """
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute(query, (user_id,))
            products = cursor.fetchall()

            # Преобразуем кортежи в формат, который соответствует модели Product
            result = [
                Product(
                    id=product["id"],
                    name=product["name"],
                    product_type=product["product_type"],
                    unit=product["unit"],
                    quantity=product["quantity"],
                    nutritional_info=product["nutritional_info"],
                    manufacture_date=product["manufacture_date"],
                    expiration_date=product["expiration_date"],
                    user_id=user_id  # Здесь добавляем user_id
                )
                for product in products
            ]
            return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()




@router.post("/", response_model=List[Product])
def add_products(products: List[ProductBase]):
    """Функция добавления продуктов с user_id."""
    get_type_query = "SELECT id FROM product_types WHERE name = %s;"
    get_unit_query = "SELECT id FROM units WHERE name = %s;"
    insert_query = """
    INSERT INTO main (user_id, name, type_id, manufacture_date, expiration_date, quantity, nutritional_info, unit_id)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    RETURNING id, user_id, name, manufacture_date, expiration_date, quantity, nutritional_info;
    """
    conn = None
    added_products = []
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            for product in products:
                cursor.execute(get_type_query, (product.product_type,))
                type_result = cursor.fetchone()
                if not type_result:
                    raise HTTPException(status_code=400, detail=f"Тип продукта '{product.product_type}' не найден")
                type_id = type_result["id"]

                cursor.execute(get_unit_query, (product.unit,))
                unit_result = cursor.fetchone()
                if not unit_result:
                    raise HTTPException(status_code=400, detail=f"Единица измерения '{product.unit}' не найдена")
                unit_id = unit_result["id"]

                cursor.execute(insert_query, (
                    product.user_id, product.name, type_id, product.manufacture_date, product.expiration_date,
                    product.quantity, product.nutritional_info, unit_id
                ))
                new_product = cursor.fetchone()
                new_product["product_type"] = product.product_type
                new_product["unit"] = product.unit
                added_products.append(new_product)
            conn.commit()
        return added_products
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.get("/{product_id}", response_model=Product)
def get_product_by_id(product_id: int, user_id: int = Query(..., description="ID пользователя")):
    """Функция получения продукта по ID и user_id."""
    query = """
    SELECT main.id, main.user_id, main.name, product_types.name AS product_type, units.name AS unit,
           main.quantity, main.nutritional_info, main.manufacture_date, main.expiration_date
    FROM main
    JOIN product_types ON main.type_id = product_types.id
    JOIN units ON main.unit_id = units.id
    WHERE main.id = %s AND main.user_id = %s;
    """
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute(query, (product_id, user_id))
            product = cursor.fetchone()
            if not product:
                raise HTTPException(status_code=404, detail="Продукт с таким ID не найден или не принадлежит пользователю")
            return product
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()

