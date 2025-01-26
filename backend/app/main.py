from fastapi import FastAPI
from app.routers import products

app = FastAPI()

# Подключение роутеров
app.include_router(products.router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
