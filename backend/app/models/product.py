from pydantic import BaseModel, validator
from datetime import date

"""
ProductBase - список всех продуктов пользователя:
name - название продукта
product_type - тип продукта (хлеб/рыба/т.д.)
manufacture_date - дата изготовления
expiration_date - дата истечения срока годности
quantity - количество
nutritional_info - пищевая ценность
unit - единица измерения
"""


class ProductBase(BaseModel):
    user_id: int
    name: str
    product_type: str
    manufacture_date: date
    expiration_date: date
    quantity: float
    nutritional_info: float
    unit: str

    @validator("expiration_date")
    def validate_dates(cls, expiration_date, values):
        manufacture_date = values.get("manufacture_date")
        if manufacture_date and manufacture_date > expiration_date:
            raise ValueError("Дата производства не может быть позже срока годности")
        return expiration_date


class Product(ProductBase):
    id: int

    class Config:
        json_encoders = {
            date: lambda v: v.strftime("%Y-%m-%d"),
        }
