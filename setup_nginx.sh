#!/bin/bash

# Скрипт настройки Nginx
# Использование: sudo bash setup_nginx.sh your-domain.ru

set -e

echo "🌐 Настройка Nginx"
echo "=================="
echo ""

# Проверка аргумента домена
if [ -z "$1" ]; then
    echo "❌ Укажите домен в качестве аргумента!"
    echo "Использование: sudo bash setup_nginx.sh ваш-домен.ru"
    echo ""
    echo "Например:"
    echo "  sudo bash setup_nginx.sh jivochat.example.ru"
    exit 1
fi

DOMAIN=$1

echo "📝 Настройка Nginx для домена: $DOMAIN"

# Создание конфигурации Nginx
cat > /etc/nginx/sites-available/jivochat-bridge << EOF
server {
    listen 80;
    server_name $DOMAIN;

    access_log /var/log/nginx/jivochat-access.log;
    error_log /var/log/nginx/jivochat-error.log;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Активация конфигурации
echo "🔗 Активация конфигурации..."
ln -sf /etc/nginx/sites-available/jivochat-bridge /etc/nginx/sites-enabled/

# Удаление дефолтной конфигурации (опционально)
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
fi

# Проверка конфигурации
echo "🧪 Проверка конфигурации Nginx..."
nginx -t

# Перезапуск Nginx
echo "🔄 Перезапуск Nginx..."
systemctl restart nginx

echo ""
echo "✅ Nginx настроен!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Убедитесь, что домен $DOMAIN указывает на IP этого сервера"
echo "2. Получите SSL сертификат:"
echo "   sudo certbot --nginx -d $DOMAIN"
echo ""
echo "🌐 Проверьте работу:"
echo "   http://$DOMAIN"
echo ""
