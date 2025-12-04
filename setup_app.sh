#!/bin/bash

# Скрипт настройки приложения на VPS
# Использование: sudo bash setup_app.sh

set -e

echo "🔧 Настройка JivoChat-Telegram Bridge"
echo "======================================"
echo ""

# Проверка, что мы в правильной директории
if [ ! -f "app.py" ]; then
    echo "❌ Файл app.py не найден!"
    echo "Убедитесь, что вы находитесь в директории проекта"
    exit 1
fi

# 1. Создание виртуального окружения
echo "📦 Создание виртуального окружения..."
python3 -m venv venv
source venv/bin/activate

# 2. Установка зависимостей
echo "📦 Установка зависимостей Python..."
pip install --upgrade pip
pip install -r requirements.txt

# 3. Проверка .env файла
if [ ! -f ".env" ]; then
    echo "⚠️  Файл .env не найден!"
    echo "Создаю из .env.example..."
    cp .env.example .env
    echo ""
    echo "📝 Отредактируйте файл .env и укажите ваши токены:"
    echo "   nano .env"
    echo ""
    echo "После редактирования запустите этот скрипт снова"
    exit 1
fi

# 4. Установка прав
echo "🔒 Установка прав на файлы..."
chown -R www-data:www-data /var/www/jivochat-telegram-bridge
chmod -R 755 /var/www/jivochat-telegram-bridge

# 5. Создание systemd сервиса
echo "⚙️  Создание systemd сервиса..."

# Получаем токены из .env
source .env

cat > /etc/systemd/system/jivochat-bridge.service << EOF
[Unit]
Description=JivoChat-Telegram Bridge
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/jivochat-telegram-bridge
Environment="PATH=/var/www/jivochat-telegram-bridge/venv/bin"
Environment="TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}"
Environment="TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}"
ExecStart=/var/www/jivochat-telegram-bridge/venv/bin/gunicorn \\
    --workers 3 \\
    --bind 127.0.0.1:5000 \\
    --access-logfile /var/log/jivochat-bridge-access.log \\
    --error-logfile /var/log/jivochat-bridge-error.log \\
    app:app

Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 6. Запуск сервиса
echo "🚀 Запуск сервиса..."
systemctl daemon-reload
systemctl enable jivochat-bridge
systemctl start jivochat-bridge

# 7. Проверка статуса
sleep 2
if systemctl is-active --quiet jivochat-bridge; then
    echo "✅ Сервис успешно запущен!"
else
    echo "❌ Ошибка запуска сервиса!"
    echo "Проверьте логи: journalctl -u jivochat-bridge -n 50"
    exit 1
fi

echo ""
echo "✅ Приложение настроено!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Настройте Nginx: sudo bash setup_nginx.sh"
echo "2. Получите SSL сертификат: sudo certbot --nginx -d ваш-домен.ru"
echo ""
echo "📊 Полезные команды:"
echo "   systemctl status jivochat-bridge    # Статус сервиса"
echo "   journalctl -u jivochat-bridge -f    # Просмотр логов"
echo "   systemctl restart jivochat-bridge   # Перезапуск"
echo ""
