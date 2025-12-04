#!/bin/bash

# Скрипт автоматической установки на Ubuntu VPS
# Использование: sudo bash setup_server.sh

set -e  # Остановка при ошибке

echo "🚀 Начало установки JivoChat-Telegram Bridge на VPS"
echo "=================================================="
echo ""

# Проверка, что скрипт запущен с root правами
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Пожалуйста, запустите скрипт с правами root: sudo bash setup_server.sh"
    exit 1
fi

# 1. Обновление системы
echo "📦 Обновление системы..."
apt update
apt upgrade -y

# 2. Установка необходимых пакетов
echo "📦 Установка Python, Nginx, Certbot..."
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    certbot \
    python3-certbot-nginx \
    git \
    ufw \
    htop

# 3. Настройка firewall
echo "🔒 Настройка firewall..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# 4. Создание директории проекта
echo "📁 Создание директории проекта..."
mkdir -p /var/www/jivochat-telegram-bridge
cd /var/www/jivochat-telegram-bridge

echo ""
echo "✅ Базовая настройка сервера завершена!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Загрузите файлы проекта в /var/www/jivochat-telegram-bridge"
echo "2. Запустите setup_app.sh для настройки приложения"
echo ""
