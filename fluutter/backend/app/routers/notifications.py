from fastapi import APIRouter, Query
from datetime import datetime, timedelta
import time
from db.connection import get_db_connection

router = APIRouter(prefix="/notifications", tags=["Notifications"])

NOTIFY_DAYS = 3

@router.get("/")
def get_notifications(user_id: int = Query(..., description="ID пользователя")):
    """Долгий HTTP-запрос, который ждет появления уведомлений."""
    timeout = 30
    start_time = time.time()

    while time.time() - start_time < timeout:
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                today = datetime.today().date()
                query = """
                SELECT name, expiration_date
                FROM main
                WHERE user_id = %s AND expiration_date = %s;
                """
                cursor.execute(query, (user_id, today + timedelta(days=NOTIFY_DAYS)))
                products = cursor.fetchall()

                if products:
                    return [
                        {"message": f"Продукт '{p['name']}' истекает через {NOTIFY_DAYS} дня!"}
                        for p in products
                    ]
        finally:
            conn.close()

        time.sleep(2)

    return []
