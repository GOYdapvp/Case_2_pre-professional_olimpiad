"""
Этот файл используется для распределения API.
"""

from fastapi import APIRouter, HTTPException
from typing import List
from app.models.product import Product, ProductBase
from app.db.connection import get_db_connection
from datetime import datetime

router = APIRouter(prefix="/products", tags=["Products"])


@router.get("/", response_model=List[Product])
def get_all_products():
    """Функция получения списка всех продуктов."""
    query = """
    SELECT main.id, main.name, product_types.name AS product_type, units.name AS unit,
           main.quantity, main.nutritional_info, main.manufacture_date, main.expiration_date
    FROM main
    JOIN product_types ON main.type_id = product_types.id
    JOIN units ON main.unit_id = units.id;
    """
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute(query)
            products = cursor.fetchall()
            return products
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.post("/", response_model=List[Product])
def add_products(products: List[ProductBase]):
    """Функция добавления продуктов."""
    get_type_query = "SELECT id FROM product_types WHERE name = %s;"
    get_unit_query = "SELECT id FROM units WHERE name = %s;"
    insert_query = """
    INSERT INTO main (name, type_id, manufacture_date, expiration_date, quantity, nutritional_info, unit_id)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
    RETURNING id, name, manufacture_date, expiration_date, quantity, nutritional_info;
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
                    product.name, type_id, product.manufacture_date, product.expiration_date,
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
def get_product_by_id(product_id: int):
    """Функция получения продуктов по ID."""
    query = """
    SELECT main.id, main.name, product_types.name AS product_type, units.name AS unit,
           main.quantity, main.nutritional_info, main.manufacture_date, main.expiration_date
    FROM main
    JOIN product_types ON main.type_id = product_types.id
    JOIN units ON main.unit_id = units.id
    WHERE main.id = %s;
    """
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute(query, (product_id,))
            product = cursor.fetchone()
            if not product:
                raise HTTPException(status_code=404, detail="Продукт с таким ID не найден")
            return product
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()
