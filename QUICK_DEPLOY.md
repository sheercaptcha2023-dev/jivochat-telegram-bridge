# ⚡ Краткая инструкция по развертыванию на REG.RU

Упрощенная версия для быстрого старта.

---

## 🎯 Минимальные требования

- VPS на REG.RU (Start-1 или выше)
- Ubuntu 22.04 LTS
- Домен (необходим для SSL)

---

## 🚀 Развертывание за 5 шагов

### 1️⃣ Настройка домена на REG.RU

В панели управления доменом создайте A-запись:
- **Субдомен:** `jivochat` (или другое название)
- **IP-адрес:** IP вашего VPS
- **TTL:** 3600

Ваш адрес: `jivochat.ваш-домен.ru`

---

### 2️⃣ Подключение к VPS

```bash
ssh root@ваш-IP-адрес
# Введите пароль из письма REG.RU
```

---

### 3️⃣ Автоматическая установка

Выполните на сервере:

```bash
# Скачать и запустить скрипт установки
curl -o setup.sh https://raw.githubusercontent.com/ваш-repo/setup_server.sh
sudo bash setup.sh
```

**Или ручная установка:**

```bash
# 1. Обновить систему
apt update && apt upgrade -y

# 2. Установить ПО
apt install -y python3 python3-pip python3-venv nginx certbot python3-certbot-nginx git ufw

# 3. Настроить firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# 4. Создать директорию
mkdir -p /var/www/jivochat-telegram-bridge
cd /var/www/jivochat-telegram-bridge
```

---

### 4️⃣ Загрузка проекта

**Вариант A: Через Git**

```bash
cd /var/www
git clone https://github.com/ваш-username/jivochat-telegram-bridge.git
cd jivochat-telegram-bridge
```

**Вариант B: Через SFTP**

Используйте FileZilla/WinSCP:
- **Хост:** IP вашего VPS
- **Порт:** 22
- **Логин:** root
- **Пароль:** из письма REG.RU

Загрузите все файлы в `/var/www/jivochat-telegram-bridge`

---

### 5️⃣ Настройка и запуск

```bash
cd /var/www/jivochat-telegram-bridge

# Создать виртуальное окружение
python3 -m venv venv
source venv/bin/activate

# Установить зависимости
pip install -r requirements.txt

# Создать .env файл
nano .env
```

В .env вставьте:
```env
TELEGRAM_BOT_TOKEN=8560374126:AAGyGmyhK1NgdHfIhxW5jRxzaT6NNTTH_xk
TELEGRAM_CHAT_ID=-5069187781
DEBUG=False
```

Сохраните: `Ctrl+O`, `Enter`, `Ctrl+X`

```bash
# Установить права
chown -R www-data:www-data /var/www/jivochat-telegram-bridge

# Создать systemd сервис
nano /etc/systemd/system/jivochat-bridge.service
```

Вставьте:
```ini
[Unit]
Description=JivoChat-Telegram Bridge
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/jivochat-telegram-bridge
Environment="PATH=/var/www/jivochat-telegram-bridge/venv/bin"
Environment="TELEGRAM_BOT_TOKEN=8560374126:AAGyGmyhK1NgdHfIhxW5jRxzaT6NNTTH_xk"
Environment="TELEGRAM_CHAT_ID=-5069187781"
ExecStart=/var/www/jivochat-telegram-bridge/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Запустить сервис
systemctl daemon-reload
systemctl enable jivochat-bridge
systemctl start jivochat-bridge

# Проверить статус
systemctl status jivochat-bridge
```

---

### 6️⃣ Настройка Nginx

```bash
nano /etc/nginx/sites-available/jivochat-bridge
```

Вставьте (замените домен):
```nginx
server {
    listen 80;
    server_name jivochat.ваш-домен.ru;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Активировать конфигурацию
ln -s /etc/nginx/sites-available/jivochat-bridge /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

---

### 7️⃣ SSL сертификат

```bash
certbot --nginx -d jivochat.ваш-домен.ru
```

Следуйте инструкциям certbot.

---

### 8️⃣ Настройка JivoChat

1. Откройте JivoChat → **Управление** → **Каналы** → **Настройки** → **Настройки интеграции**
2. Включите webhook
3. URL: `https://jivochat.ваш-домен.ru/webhook/jivochat`
4. Сохраните

---

## ✅ Готово!

Проверьте работу:
```bash
# Статус сервиса
systemctl status jivochat-bridge

# Логи
tail -f /var/log/jivochat-bridge-error.log

# Тест
curl https://jivochat.ваш-домен.ru/health
```

---

## 🆘 Быстрая помощь

**Сервис не запускается:**
```bash
journalctl -u jivochat-bridge -n 50
```

**502 ошибка в Nginx:**
```bash
systemctl restart jivochat-bridge
systemctl restart nginx
```

**Проверка портов:**
```bash
netstat -tulpn | grep 5000
```

**Перезапуск всего:**
```bash
systemctl restart jivochat-bridge
systemctl restart nginx
```

---

## 📞 Полезные команды

```bash
# Логи приложения
tail -f /var/log/jivochat-bridge-error.log

# Логи systemd
journalctl -u jivochat-bridge -f

# Статус сервисов
systemctl status jivochat-bridge
systemctl status nginx

# Перезапуск
systemctl restart jivochat-bridge
systemctl restart nginx

# Обновление кода
cd /var/www/jivochat-telegram-bridge
git pull
systemctl restart jivochat-bridge
```

---

## 📚 Подробная инструкция

Полная документация: [DEPLOY_REGRU.md](DEPLOY_REGRU.md)
