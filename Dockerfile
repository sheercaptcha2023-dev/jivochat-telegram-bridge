FROM python:3.11-slim

WORKDIR /app

# Установка зависимостей
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копирование приложения
COPY . .

# Открытие порта
EXPOSE 8080

# Запуск приложения
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
