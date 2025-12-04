#!/bin/bash

# Скрипт для быстрого запуска JivoChat-Telegram Bridge

echo "🚀 Запуск JivoChat-Telegram Bridge..."
echo ""

# Активация виртуального окружения
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✅ Виртуальное окружение активировано"
else
    echo "❌ Виртуальное окружение не найдено!"
    echo "Создайте его командой: python3 -m venv venv"
    exit 1
fi

# Проверка зависимостей
if ! python -c "import flask" &> /dev/null; then
    echo "📦 Установка зависимостей..."
    pip install -r requirements.txt
fi

echo ""
echo "🌐 Сервер будет доступен на: http://localhost:5000"
echo "🧪 Тест: http://localhost:5000/test"
echo "📊 Статус: http://localhost:5000/health"
echo ""
echo "Нажмите Ctrl+C для остановки сервера"
echo ""

# Запуск приложения
python app.py
