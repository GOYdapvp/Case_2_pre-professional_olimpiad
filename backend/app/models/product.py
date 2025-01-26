from pydantic import BaseModel, validator
from datetime import date

class ProductBase(BaseModel):
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
