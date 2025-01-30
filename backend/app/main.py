"""
Основной файл (его и запускать)
"""
from fastapi import FastAPI
import uvicorn
from app.routers import products

app = FastAPI()

# Подключение роутеров
app.include_router(products.router)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
