import os
import re
import json
import logging
import asyncio
from datetime import datetime
import pytz
import csv
from dotenv import load_dotenv
from telethon import TelegramClient, events
import hashlib
import time

# === 1. Load environment variables ===
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))

TARGET_CHAT = int(os.getenv('TARGET_CHAT'))
KEYWORDS_FILE = os.getenv('KEYWORDS_FILE', 'data/keywords.txt')
LOG_FILE = os.getenv('LOG_FILE', 'data/matches.json')

# === 2. Keyword Alerting (Job Bot) Setup ===
recent_alerts = {}
ALERT_WINDOW_SECONDS = 10 * 60

QUESTION_MARKERS = ['?', 'bormi', 'bor mi', 'kerakmi', 'ish bormi', 'yozaymi', 'yozvoraymi', 'борми', 'бор ми', 'керакми', 'иш борми', 'ёзайми', 'ёзворайми', 'UZOQDAN KELGANLARGA', 'uy kerak', 'uy bormi', 'one room', 'vanrum', '원룸', 'уй керак', 'уй борми', 'joy bor', 'deposit', 'depozit', 'sherik kerak', 'депозит', 'шерик керак']
CLOSURE_KEYWORDS = ["olindi", "band", "topildi", "yopildi", "bitdi", "berildi", "sold", "closed", "Олинди", 'топилди']

# === Helper Functions ===
def normalize_for_hash(text):
    return re.sub(r'\s+', ' ', text.strip().lower())

def generate_message_hash(sender_id, message_text):
    base_string = f"{sender_id}-{normalize_for_hash(message_text)}"
    return hashlib.md5(base_string.encode()).hexdigest()

def load_keywords():
    if not os.path.exists(KEYWORDS_FILE):
        return []
    with open(KEYWORDS_FILE, 'r', encoding='utf-8') as f:
        return [line.strip().lower() for line in f if line.strip()]

def load_allowed_chat_ids(csv_file=os.path.join(os.path.dirname(__file__), '..', 'data', 'allowed_chats.csv')):
    allowed_ids = set()
    chat_names = {}
    try:
        with open(csv_file, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                try:
                    cid = int(row['chat_id'])
                    allowed_ids.add(cid)
                    chat_names[cid] = row.get('name', 'Unknown')
                except ValueError:
                    continue
    except FileNotFoundError:
        print(f"[WARNING] {csv_file} not found.")
    return allowed_ids, chat_names

def load_log():
    if not os.path.exists(LOG_FILE):
        return []
    with open(LOG_FILE, 'r', encoding='utf-8') as f:
        return [json.loads(line) for line in f if line.strip()]

def log_matched_message(data):
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False)
        f.write('\n')

def normalize(text):
    return re.sub(r'[^\w\s]', '', text.lower())

def is_question(text):
    text = text.lower()
    return any(marker in text for marker in QUESTION_MARKERS)

# === Load data ===
keywords = load_keywords()
ALLOWED_CHAT_IDS, ALLOWED_CHAT_NAMES = load_allowed_chat_ids()


def setup(client: TelegramClient):
    """Register the job keyword alert handler on the given client."""

    @client.on(events.NewMessage)
    async def handler(event):
        try:
            chat = await event.get_chat()
            chat_id = chat.id
            chat_name = getattr(chat, 'title', 'Unknown Group')
            print(f"[DEBUG] Message received from chat ID: {chat_id} ({chat_name})")

            if chat_id not in ALLOWED_CHAT_IDS:
                print(f"[SKIP] Chat {chat_id} not in allowed list.")
                return

            sender = await event.get_sender()
            sender_name = getattr(sender, 'first_name', 'Unknown')
            message_text = event.message.message or ""

            #print(f"[DEBUG] Message text: {message_text}")

            normalized_text = normalize(message_text)
            matched = [kw for kw in keywords if re.search(rf'\b{re.escape(kw)}\b', normalized_text) and not is_question(message_text)]

            print(f"[DEBUG] Matched keywords: {matched}")

            # Closure reply handling
            if event.message.is_reply and any(kw in normalized_text for kw in CLOSURE_KEYWORDS):
                reply_msg = await event.message.get_reply_message()
                if not reply_msg:
                    return
                original_text = reply_msg.text or ""
                print(f"[REPLY DETECTED] Message indicates closure: replying to → {original_text[:40]}...")

                log_data = load_log()
                for entry in log_data:
                    if entry['sender_id'] == reply_msg.sender_id and entry['original_text'] == original_text:
                        try:
                            updated_msg = entry['full_alert'] + "\n\n✅ <b>⚠️ BU ISHGA ODAM OLINDI!</b>"
                            await client.edit_message(TARGET_CHAT, entry['forwarded_msg_id'], updated_msg, parse_mode='html', link_preview=False)
                            print("[MATCH] Original message successfully edited to reflect closure.")
                        except Exception as e:
                            print(f"[ERROR] Failed to edit message: {e}")
                        return

            #Dublicate prevent mechanism
            msg_hash = generate_message_hash(sender.id, message_text)
            now = time.time()

            last_seen = recent_alerts.get(msg_hash)
            if last_seen and now - last_seen < ALERT_WINDOW_SECONDS:
                print(f"[DUPLICATE] Skipped duplicate alert (within 10 min) for user {sender.id}")
                return
            else:
                recent_alerts[msg_hash] = now  # Save/update timestamp

            
            # Regular keyword match handler
            if matched:
                timestamp = datetime.now(pytz.timezone('Asia/Seoul')).strftime('%Y-%m-%d %H:%M:%S')
                chat_id_str = str(chat.id)

                if getattr(chat, 'username', None):
                    group_url = f'<a href="https://t.me/{chat.username}">{chat_name}</a>'
                elif chat_id_str.startswith("-100"):
                    group_url = f'<a href="https://t.me/c/{chat_id_str[4:]}">{chat_name}</a>'
                else:
                    group_url = f'🔒 <i>{chat_name} (Yopiq Guruh)</i>'

                if getattr(sender, 'username', None):
                    sender_link = f"https://t.me/{sender.username}"
                else:
                    sender_link = f"tg://user?id={sender.id}"

                sender_display = f'<a href="{sender_link}">{sender_name}</a>'

                alert = (
                    f"⚠️ <b>Yangi xabar ma'lumotlari:</b>\n"
                    f"<b>Guruh:</b> {group_url}\n"
                    f"<b>Xabar egasi:</b> {sender_display}\n"
                    f"<b>Xabar vaqti:</b> {timestamp}\n\n"
                    f"<b>Xabar matni:</b>\n{message_text}\n\n"
                    "@muslim_vegukin_bot"
                )

                sent = await client.send_message(TARGET_CHAT, alert, parse_mode='html', link_preview=False)

                log_matched_message({
                    'group': chat_name,
                    'chat_id': chat.id,
                    'sender_id': sender.id,
                    'sender': sender.username if sender else None,
                    'timestamp': timestamp,
                    'matched_keywords': matched,
                    'original_text': message_text,
                    'forwarded_msg_id': sent.id,
                    'full_alert': alert
                })

                print(f"[ALERT] Alert sent for keywords: {matched}")
            else:
                print("[DEBUG] No keywords matched.")

        except Exception as e:
            logging.error(f"Error in handler: {e}")

    logging.info("[job_keyword_alert_bot] Handlers registered.")
