from flask import Flask, request, jsonify
import requests
from datetime import datetime
import logging
import os

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('jivochat_bridge.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Конфигурация из переменных окружения
TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN', '8560374126:AAGyGmyhK1NgdHfIhxW5jRxzaT6NNTTH_xk')
TELEGRAM_CHAT_ID = os.getenv('TELEGRAM_CHAT_ID', '-5069187781')
TELEGRAM_API_URL = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"

# События, о которых отправлять уведомления
EVENTS_TO_NOTIFY = ['chat_started', 'chat_finished', 'offline_message', 'chat_accepted', 'chat_updated']


def send_telegram_message(text, parse_mode="HTML", reply_markup=None):
    """Отправка сообщения в Telegram группу"""
    payload = {
        "chat_id": TELEGRAM_CHAT_ID,
        "text": text,
        "parse_mode": parse_mode,
        "disable_web_page_preview": True
    }
    
    if reply_markup:
        payload["reply_markup"] = reply_markup
    
    try:
        response = requests.post(TELEGRAM_API_URL, json=payload, timeout=10)
        response.raise_for_status()
        logger.info(f"✅ Сообщение успешно отправлено в Telegram")
        return True
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ Ошибка отправки в Telegram: {e}")
        return False


def format_chat_finished(data):
    """Форматирование сообщения о завершенном чате"""
    visitor = data.get("visitor", {})
    agent = data.get("agent", {})
    chat_log = data.get("chat_log", [])
    
    # Формируем красивое сообщение
    message = f"""
🆕 <b>Новая заявка из JivoChat</b>

👤 <b>Клиент:</b> {visitor.get('name', 'Не указано')}
📧 <b>Email:</b> {visitor.get('email', 'Не указан')}
📱 <b>Телефон:</b> {visitor.get('phone', 'Не указан')}

👨‍💼 <b>Оператор:</b> {agent.get('name', 'Не указан')}

💬 <b>Сообщения ({len(chat_log)}):</b>
"""
    
    # Добавляем последние сообщения (максимум 5)
    for msg in chat_log[-5:]:
        sender = msg.get('sender', {})
        sender_name = sender.get('name', 'Неизвестно')
        text = msg.get('text', '')
        timestamp = msg.get('timestamp', 0)
        
        if timestamp:
            time_str = datetime.fromtimestamp(timestamp).strftime('%H:%M')
        else:
            time_str = "??"
        
        # Ограничиваем длину текста
        text_preview = text[:100] + '...' if len(text) > 100 else text
        message += f"\n<i>[{time_str}] {sender_name}:</i> {text_preview}"
    
    if len(chat_log) > 5:
        message += f"\n\n<i>... и еще {len(chat_log) - 5} сообщений</i>"
    
    return message


def format_offline_message(data):
    """Форматирование оффлайн сообщения"""
    visitor = data.get("visitor", {})
    message_data = data.get("message", {})
    message_text = message_data.get("text", "")
    
    message = f"""
📬 <b>Оффлайн сообщение из JivoChat</b>

👤 <b>От:</b> {visitor.get('name', 'Не указано')}
📧 <b>Email:</b> {visitor.get('email', 'Не указан')}
📱 <b>Телефон:</b> {visitor.get('phone', 'Не указан')}

💬 <b>Сообщение:</b>
{message_text}
"""
    return message


def format_chat_accepted(data):
    """Форматирование принятого чата"""
    visitor = data.get("visitor", {})
    agent = data.get("agent", {})
    
    message = f"""
✅ <b>Чат принят оператором</b>

👤 <b>Клиент:</b> {visitor.get('name', 'Не указано')}
📧 <b>Email:</b> {visitor.get('email', 'Не указан')}
👨‍💼 <b>Оператор:</b> {agent.get('name', 'Не указан')}
"""
    return message


def format_chat_started(data):
    """Форматирование начала нового чата"""
    visitor = data.get("visitor", {})
    
    message = f"""
🔔 <b>Новый чат начат!</b>

👤 <b>Клиент:</b> {visitor.get('name', 'Не указано')}
📧 <b>Email:</b> {visitor.get('email', 'Не указан')}
📱 <b>Телефон:</b> {visitor.get('phone', 'Не указан')}
🌐 <b>Страница:</b> {visitor.get('url', 'Не указана')}

⏰ <b>Ожидает ответа оператора...</b>
"""
    return message


def format_chat_updated(data):
    """Форматирование обновления информации о чате"""
    visitor = data.get("visitor", {})
    
    message = f"""
🔄 <b>Обновлена информация о клиенте</b>

👤 <b>Клиент:</b> {visitor.get('name', 'Не указано')}
📧 <b>Email:</b> {visitor.get('email', 'Не указан')}
📱 <b>Телефон:</b> {visitor.get('phone', 'Не указан')}
"""
    return message


@app.route('/webhook/jivochat', methods=['POST'])
def jivochat_webhook():
    """Обработчик webhook от JivoChat"""
    try:
        data = request.get_json()
        
        if not data:
            logger.warning("⚠️ Получен пустой запрос")
            return jsonify({"error": "No data received"}), 400
        
        event_name = data.get("event_name")
        logger.info(f"📥 Получено событие: {event_name}")
        
        # Проверяем, нужно ли отправлять уведомление для этого события
        if event_name not in EVENTS_TO_NOTIFY:
            logger.info(f"ℹ️ Событие {event_name} игнорируется (не в списке уведомлений)")
            return jsonify({"result": "ok", "message": "Event ignored"}), 200
        
        # Формируем сообщение в зависимости от типа события
        message = None
        
        if event_name == "chat_started":
            message = format_chat_started(data)
            
        elif event_name == "chat_finished":
            message = format_chat_finished(data)
            
        elif event_name == "offline_message":
            message = format_offline_message(data)
            
        elif event_name == "chat_accepted":
            message = format_chat_accepted(data)
            
        elif event_name == "chat_updated":
            message = format_chat_updated(data)
        
        # Отправляем сообщение в Telegram
        if message:
            send_telegram_message(message)
        
        # Отправляем подтверждение JivoChat
        return jsonify({"result": "ok"}), 200
        
    except Exception as e:
        logger.error(f"💥 Ошибка обработки webhook: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


@app.route('/health', methods=['GET'])
def health_check():
    """Проверка работоспособности сервера"""
    return jsonify({
        "status": "ok",
        "service": "JivoChat-Telegram Bridge",
        "telegram_bot_configured": bool(TELEGRAM_BOT_TOKEN),
        "telegram_chat_configured": bool(TELEGRAM_CHAT_ID)
    }), 200


@app.route('/test', methods=['GET'])
def test_telegram():
    """Тестовая отправка сообщения в Telegram"""
    test_message = f"""
🧪 <b>Тестовое сообщение</b>

Это тестовое сообщение от JivoChat-Telegram Bridge.
Если вы его видите, значит интеграция работает! ✅

⏰ Время: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
    
    success = send_telegram_message(test_message)
    
    if success:
        return jsonify({
            "status": "success",
            "message": "Тестовое сообщение отправлено в Telegram"
        }), 200
    else:
        return jsonify({
            "status": "error",
            "message": "Не удалось отправить сообщение в Telegram"
        }), 500


@app.route('/', methods=['GET'])
def index():
    """Главная страница"""
    return """
    <html>
        <head>
            <title>JivoChat-Telegram Bridge</title>
            <style>
                body { 
                    font-family: Arial, sans-serif; 
                    max-width: 800px; 
                    margin: 50px auto; 
                    padding: 20px;
                    background: #f5f5f5;
                }
                .container {
                    background: white;
                    padding: 30px;
                    border-radius: 10px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }
                h1 { color: #333; }
                .status { 
                    padding: 15px; 
                    background: #e8f5e9; 
                    border-radius: 5px;
                    margin: 20px 0;
                }
                .endpoint {
                    background: #f5f5f5;
                    padding: 15px;
                    border-radius: 5px;
                    margin: 10px 0;
                    font-family: monospace;
                }
                a.button {
                    display: inline-block;
                    padding: 10px 20px;
                    background: #4CAF50;
                    color: white;
                    text-decoration: none;
                    border-radius: 5px;
                    margin: 10px 5px;
                }
                a.button:hover {
                    background: #45a049;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🤖 JivoChat-Telegram Bridge</h1>
                <div class="status">
                    <strong>✅ Сервер работает</strong>
                </div>
                
                <h2>📡 Webhook Endpoints:</h2>
                <div class="endpoint">
                    POST /webhook/jivochat - Webhook для JivoChat
                </div>
                <div class="endpoint">
                    GET /health - Проверка здоровья сервера
                </div>
                <div class="endpoint">
                    GET /test - Тестовая отправка в Telegram
                </div>
                
                <h2>🧪 Тестирование:</h2>
                <a href="/test" class="button">Отправить тестовое сообщение</a>
                <a href="/health" class="button">Проверить статус</a>
                
                <h2>ℹ️ Информация:</h2>
                <p>Этот сервис пересылает уведомления из JivoChat в Telegram группу.</p>
                <p>Для настройки укажите этот URL в настройках webhooks JivoChat.</p>
            </div>
        </body>
    </html>
    """


if __name__ == '__main__':
    logger.info("🚀 Запуск JivoChat-Telegram Bridge...")
    logger.info(f"📱 Telegram Bot Token: {'Настроен' if TELEGRAM_BOT_TOKEN else 'НЕ НАСТРОЕН'}")
    logger.info(f"💬 Telegram Chat ID: {TELEGRAM_CHAT_ID if TELEGRAM_CHAT_ID else 'НЕ НАСТРОЕН'}")
    
    # Для разработки
    app.run(host='0.0.0.0', port=5000, debug=True)
