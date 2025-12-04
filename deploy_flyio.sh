#!/bin/bash

# Скрипт быстрого развертывания на Fly.io
# Использование: ./deploy_flyio.sh

set -e

echo "🚀 Развертывание JivoChat-Telegram Bridge на Fly.io"
echo "===================================================="
echo ""

# Проверка установки flyctl
if ! command -v flyctl &> /dev/null; then
    echo "❌ flyctl не установлен!"
    echo ""
    echo "Установите его командой:"
    echo "  brew install flyctl"
    echo ""
    exit 1
fi

echo "✅ flyctl установлен: $(flyctl version)"
echo ""

# Проверка авторизации
if ! flyctl auth whoami &> /dev/null; then
    echo "❌ Вы не авторизованы в Fly.io"
    echo ""
    echo "Выполните команду для входа:"
    echo "  flyctl auth login"
    echo ""
    echo "Или зарегистрируйтесь:"
    echo "  flyctl auth signup"
    echo ""
    exit 1
fi

echo "✅ Авторизация в Fly.io: $(flyctl auth whoami)"
echo ""

# Проверка необходимых файлов
if [ ! -f "app.py" ]; then
    echo "❌ Файл app.py не найден!"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    echo "❌ Файл Dockerfile не найден!"
    exit 1
fi

echo "✅ Все необходимые файлы на месте"
echo ""

# Проверка Git
if [ ! -d ".git" ]; then
    echo "📦 Инициализация Git репозитория..."
    git init
    git add .
    git commit -m "Initial commit for Fly.io deployment"
fi

echo "✅ Git репозиторий готов"
echo ""

# Проверка наличия fly.toml
if [ ! -f "fly.toml" ]; then
    echo "🔧 Запуск flyctl launch..."
    echo ""
    echo "⚠️  Ответьте на вопросы:"
    echo "   - App name: укажите уникальное имя"
    echo "   - Region: выберите ams (Amsterdam) или другой близкий"
    echo "   - PostgreSQL: No"
    echo "   - Redis: No"
    echo "   - Deploy now: No"
    echo ""
    
    flyctl launch --no-deploy
    
    echo ""
    echo "✅ Приложение создано!"
else
    echo "✅ fly.toml уже существует"
fi

echo ""

# Добавление секретов
echo "🔐 Настройка переменных окружения..."
echo ""

# Проверка наличия .env
if [ -f ".env" ]; then
    source .env
    
    if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        echo "Добавление TELEGRAM_BOT_TOKEN..."
        flyctl secrets set TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
    else
        echo "⚠️  TELEGRAM_BOT_TOKEN не найден в .env"
    fi
    
    if [ -n "$TELEGRAM_CHAT_ID" ]; then
        echo "Добавление TELEGRAM_CHAT_ID..."
        flyctl secrets set TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"
    else
        echo "⚠️  TELEGRAM_CHAT_ID не найден в .env"
    fi
else
    echo "⚠️  Файл .env не найден!"
    echo "Создайте его и добавьте:"
    echo "  TELEGRAM_BOT_TOKEN=ваш_токен"
    echo "  TELEGRAM_CHAT_ID=ваш_chat_id"
    echo ""
    exit 1
fi

echo ""
echo "✅ Секреты настроены"
echo ""

# Деплой
echo "🚀 Запуск деплоя..."
echo ""

flyctl deploy

echo ""
echo "="
echo "🎉 Деплой завершен!"
echo ""

# Получение URL
APP_NAME=$(grep "^app = " fly.toml | cut -d'"' -f2)
APP_URL="https://${APP_NAME}.fly.dev"

echo "✅ Ваше приложение доступно по адресу:"
echo "   $APP_URL"
echo ""
echo "📋 Следующие шаги:"
echo "1. Проверьте работу: $APP_URL/health"
echo "2. Протестируйте: $APP_URL/test"
echo "3. Настройте webhook в JivoChat:"
echo "   $APP_URL/webhook/jivochat"
echo ""
echo "📊 Полезные команды:"
echo "   flyctl logs          # Просмотр логов"
echo "   flyctl status        # Статус приложения"
echo "   flyctl dashboard     # Открыть dashboard"
echo ""
