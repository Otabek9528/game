"""
Muslim Vegukin Bot - Generic Places API (Protected)
====================================================
Flask API with rate limiting - handles Mosques, Restaurants, Shops, and QnA

Database: 350+ places (mosques, restaurants, shops)
QnA: 75,000+ questions via Qdrant Cloud
Expected usage: 1000 daily users
Rate limit: 200 requests/hour per IP (prevents scraping)
"""

from flask import Flask, request, jsonify, send_file, Response, session, redirect
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import sqlite3
from math import radians, cos, sin, asin, sqrt
import os
from datetime import datetime, timedelta
import threading
import time
import requests
import csv
import pytz
import json
import random
from dotenv import load_dotenv

# === Load environment variables ===
# Keys and passwords live in .env next to this file (owner-only, chmod 600),
# not in the code. To rotate one: edit .env, then restart the service:
#     sudo systemctl restart vegukin.service
import sys as _sys
_ENV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env')
load_dotenv(_ENV_PATH)


def _secret(name, required=True):
    """A value from .env. A required one that is missing stops the API with a clear message."""
    value = os.getenv(name, '').strip()
    if not value and required:
        raise RuntimeError(f'{name} is missing from {_ENV_PATH}. Add it there and restart the service.')
    if not value:
        print(f'WARNING: {name} is not set in {_ENV_PATH}; the feature that uses it is off.', file=_sys.stderr)
    return value


def _secret_list(name, required=False):
    """A comma-separated list from .env."""
    return [v.strip() for v in _secret(name, required).split(',') if v.strip()]


ADMIN_PASSWORD = _secret('ADMIN_PASSWORD')


def _admin_password_ok(given):
    """Constant-time check; never true while ADMIN_PASSWORD is empty."""
    import hmac
    return bool(ADMIN_PASSWORD) and hmac.compare_digest(str(given or ''), ADMIN_PASSWORD)

# Cohere and Qdrant imports for QnA
import cohere
from qdrant_client import QdrantClient

#from subscription_manager import SubscriptionManager

from barcode_scanner_api import barcode_scanner_bp, admin_main_products_bp
from admin_parcels import admin_parcels_bp
from job_group_bp import job_group_bp
from store_products_api import store_products_bp
from barcode_v2_api import barcode_v2_bp
from hikorea_api import bp as hikorea_bp
from admin_hikorea import bp as admin_hikorea_bp
from car_api import bp as car_api_bp
from admin_cars_api import admin_cars_bp
from aviaticket import flight_bp

from housing import bp as housing_bp, init_housing
from admin_housing import bp as admin_housing_bp
    
from admin_store_products import admin_store_bp

from place_submissions_api import (bp as place_submissions_bp, get_pending_fields,
                                   move_submitter, delete_submitter)
from place_notifications_api import (bp as place_notifications_bp, init_place_notifications,
                                     wants_notify, optional_user, place_watch_info,
                                     place_from_row, tracked_changes, prepare_place_event,
                                     enqueue_messages, delete_place_notify_rows)

from tg_auth import init_tg_auth
from app_accounts import (bp as app_accounts_bp, init_app_accounts,
                          on_user_moved, on_user_deleted)
from business_api import bp as business_bp, init_business
from interaction_logs import bp as interaction_logs_bp, init_interaction_logs, record_interaction
from admin_business_api import bp as admin_business_bp

#from ramadan_calendar_api import ramadan_calendar_bp

app = Flask(__name__)
CORS(app)  # Enable CORS for web app access


# ============================================
# RATE LIMITING - PROTECTS YOUR DATA
# ============================================

limiter = Limiter(
    app=app,
    key_func=get_remote_address,  # Track by IP address
    default_limits=["10000 per hour"],  # 200 requests per hour per IP
    storage_uri="memory://"  # Use memory storage (simple for free tier)
)

app.register_blueprint(barcode_scanner_bp)
app.register_blueprint(admin_main_products_bp)
app.register_blueprint(admin_parcels_bp)
app.register_blueprint(job_group_bp)
app.register_blueprint(store_products_bp)
app.register_blueprint(barcode_v2_bp)
app.register_blueprint(hikorea_bp)
app.register_blueprint(admin_hikorea_bp)
app.register_blueprint(car_api_bp)
app.register_blueprint(admin_cars_bp)
def _load_secret_key():
    """
    Session cookies (the admin login) are signed with this key. It used to be
    the placeholder 'your_long_random_secret_key', which let anyone who knew it
    forge an admin session. Now: FLASK_SECRET_KEY from the environment, or a
    random key created once and kept in a file next to the databases, so a
    restart does not log admins out.
    """
    env = os.getenv('FLASK_SECRET_KEY')
    if env:
        return env
    path = os.getenv('FLASK_SECRET_KEY_FILE', '/home/ubuntu/vegukin_api/data/flask_secret.key')
    try:
        with open(path) as f:
            key = f.read().strip()
        if len(key) >= 32:
            return key
    except FileNotFoundError:
        pass
    import secrets
    key = secrets.token_hex(32)
    try:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, 'w') as f:
            f.write(key)
    except OSError as e:
        # Still safe, only less convenient: admins log in again after a restart.
        print(f"WARNING: could not save the session key to {path}: {e}")
    return key


app.secret_key = _load_secret_key()
# Admin session cookie: sent over HTTPS only, unreadable by page scripts, and
# not attached to requests other sites trigger. If the panel is ever opened
# over plain http, put SESSION_COOKIE_SECURE=0 in .env (login fails otherwise).
app.config.update(
    SESSION_COOKIE_SECURE=os.getenv('SESSION_COOKIE_SECURE', '1') != '0',
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE='Lax',
)

app.config["HOUSING_DB"] = "/home/ubuntu/vegukin_api/data/housing.sqlite"
app.register_blueprint(housing_bp)
init_housing(app)
app.register_blueprint(admin_housing_bp)

app.register_blueprint(admin_store_bp)

app.register_blueprint(flight_bp)

@app.after_request
def after_request(response):

    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, X-Init-Data, X-Debug-User-Id, Authorization'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
    # Browsers may reuse a preflight answer (the extra OPTIONS round trip
    # before calls with X-Init-Data) this long. 7200 s is Chrome's maximum.
    response.headers['Access-Control-Max-Age'] = '7200'
    return response


# Custom rate limit messages
@app.errorhandler(429)
def ratelimit_handler(e):
    return jsonify({
        'success': False,
        'error': 'Rate limit exceeded. Please try again later.',
        'retry_after': str(e.description)
    }), 429

# ============================================
# CONFIGURATION
# ============================================

# Database paths
DATABASE_PATH = '/home/ubuntu/vegukin_api/data/main_db.sqlite'
PARCELS_DATABASE_PATH = '/home/ubuntu/vegukin_api/data/parcels.sqlite'
app.config["CARS_DB"]        = "/home/ubuntu/arbayt_bot/data/cars.sqlite"
app.config["CARS_MEDIA_DIR"] = "/home/ubuntu/arbayt_bot/data/media"
 
# Job Group Invite Configuration
JOB_GROUP_ID = -1002553359624 # -> Ish e'lonlari Group
#JOB_GROUP_ID = -1003889709109 # -> Ish e'lonlari YANGI group
#TAXI_GROUP_ID = -1003094050555
TELEGRAM_BOT_TOKEN = _secret("VEGUKIN_BOT_TOKEN")
# JOB_HUNTER_PAYMENT_BOT_TOKEN: value kept in .env as JOB_HUNTER_PAYMENT_BOT_TOKEN (this line was commented out and stays unused)

#sub_manager = SubscriptionManager(
#    db_path='data/subscriptions.sqlite',
#    bot_token=JOB_HUNTER_PAYMENT_BOT_TOKEN,
#    vegukin_bot_token=TELEGRAM_BOT_TOKEN,
#    job_group_id=JOB_GROUP_ID,
#    taxi_group_id=TAXI_GROUP_ID
#)


#sub_manager.start_scheduler()

# Valid building types
VALID_BUILDING_TYPES = ['Masjid', 'Oshxona', "Do'kon"]

# Logging for monitoring (helps detect scrapers)
import logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('api_usage.log'),  # Saves to file
        logging.StreamHandler()  # Also prints to console
    ]
)
logger = logging.getLogger(__name__)
# --- Community place submissions (social links + owner note) ---
# The blueprint reads its settings from app.config so the DB path and the bot
# token stay defined once, here.
app.config["PLACE_SUBMISSIONS_DB"] = DATABASE_PATH
app.config["PLACE_SUBMISSIONS_BOT_TOKEN"] = TELEGRAM_BOT_TOKEN

# Extra bot tokens whose initData is also accepted.
#
# initData is signed by whichever bot OPENED the Mini App. While testing from
# the test bot, its initData is signed with the TEST bot's token, so verifying
# against the production token alone fails every submission as `bad_signature`.
# Both tokens are tried in turn, so production and test work side by side and
# there is nothing to switch back when testing ends.
#
# Prefer the env var. The empty default is ignored, so an unset var is safe.
TEST_BOT_TOKEN = _secret("TEST_BOT_TOKEN", required=False)
app.config["PLACE_SUBMISSIONS_BOT_TOKENS"] = [TEST_BOT_TOKEN]
app.config["PLACE_SUBMISSIONS_ADMIN_CHAT_ID"] = 352835325
app.config["PLACE_SUBMISSIONS_ADMIN_URL"] = "https://vegukin-api.duckdns.org/admin/places"
# Verify the Telegram initData signature on every submission. Turning this off
# makes the per-user daily quota bypassable — leave it on in production.
app.config["PLACE_SUBMISSIONS_REQUIRE_SIGNATURE"] = True
app.register_blueprint(place_submissions_bp)

# --- Places for the app: every place of a type at once, and reviews (one per
# person per place, which its writer can change or delete). places_public_api.py.
from places_public_api import bp as places_public_bp
app.config["PLACES_DB"] = DATABASE_PATH
app.register_blueprint(places_public_bp)


# --- Biznes Katalogi ---
# Its own database file, same isolation as housing/cars/parcels.
app.config["BUSINESS_DB"] = "/home/ubuntu/vegukin_api/data/business.sqlite"
app.config["BUSINESS_BOT_TOKEN"] = TELEGRAM_BOT_TOKEN
app.config["BUSINESS_ADMIN_CHAT_ID"] = 352835325
app.config["BUSINESS_ADMIN_URL"] = "https://vegukin-api.duckdns.org/admin/business"
app.config["BUSINESS_LOGO_DIR"] = "/home/ubuntu/vegukin_api/data/business_logos"

# Shared initData verification. Both tokens are tried in turn, so the test bot
# works alongside production without anything to switch back afterwards.
init_tg_auth(app, tokens=[TELEGRAM_BOT_TOKEN, TEST_BOT_TOKEN])


# --- App accounts (the Android / iOS app) ---
# Its own database file. The app signs its calls with a bearer token instead
# of initData; tg_auth and the place submissions accept either. Signing in
# with Telegram or WhatsApp goes through the bots, which confirm it with
# APP_LINK_KEY (the same value in their .env). See app_accounts.py.
app.config["APP_ACCOUNTS_DB"] = "/home/ubuntu/vegukin_api/data/accounts.sqlite"
app.config["APP_LINK_KEY"] = _secret("APP_LINK_KEY", required=False)
# The OAuth "web client" of the Firebase project (google-services.json,
# client_type 3): Google ID tokens from the app are issued for it.
# Not a secret, so read directly: unset is normal and means this default.
app.config["APP_GOOGLE_CLIENT_IDS"] = [
    c.strip() for c in os.getenv("APP_GOOGLE_CLIENT_IDS", "").split(",") if c.strip()
] or ["450113929398-oalac2gbfr1mv2b30593anj5djstph7u.apps.googleusercontent.com"]
app.config["APP_TELEGRAM_BOT"] = os.getenv("APP_TELEGRAM_BOT", "").strip()
app.config["APP_WHATSAPP_NUMBER"] = os.getenv("APP_WHATSAPP_NUMBER", "").strip()
# Service account JSON from the Firebase console, for push notifications.
# Unset: no pushes; Telegram messages go out as before.
app.config["FIREBASE_SERVICE_ACCOUNT"] = os.getenv("FIREBASE_SERVICE_ACCOUNT", "").strip()
app.register_blueprint(app_accounts_bp)
init_app_accounts(app)
on_user_moved(move_submitter)
on_user_deleted(delete_submitter)

app.register_blueprint(business_bp)
app.register_blueprint(admin_business_bp)
init_business(app)   # creates the schema and seeds the categories; idempotent


# --- Interaction logs ---
# Own database file. The legacy CSV is imported on startup and re-checked for
# new lines before each stats request, so anything still appending to it
# (bot / WhatsApp logging) keeps appearing in the stats.
app.config["INTERACTION_LOGS_DB"] = "/home/ubuntu/vegukin_api/data/interaction_logs.sqlite"
app.config["INTERACTION_LOGS_CSV"] = "/home/ubuntu/vegukin_api/data/interaction_logs.csv"
app.register_blueprint(interaction_logs_bp)
init_interaction_logs(app)   # creates the schema and imports the CSV; idempotent


# --- Push campaigns: the /admin/push panel (app and Telegram) ---
# Its own database and photo folder. A thread in this process sends.
from push_campaigns import bp as push_campaigns_bp, init_push_campaigns
app.config["PUSH_CAMPAIGNS_DB"] = "/home/ubuntu/vegukin_api/data/push_campaigns.sqlite"
app.config["PUSH_MEDIA_DIR"] = "/home/ubuntu/vegukin_api/data/push_media"
app.config["PUSH_PUBLIC_BASE"] = "https://vegukin-api.duckdns.org"
app.config["PUSH_TELEGRAM_BOT_TOKEN"] = _secret("PUSH_TELEGRAM_BOT_TOKEN", required=False)
app.register_blueprint(push_campaigns_bp)
init_push_campaigns(app)


# ============================================
# DATABASE FUNCTIONS
# ============================================

def get_db_connection():
    """Create database connection"""
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        conn.row_factory = sqlite3.Row
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {str(e)}")
        raise

def haversine(lat1, lon1, lat2, lon2):
    """
    Calculate distance between two points using Haversine formula
    Returns distance in kilometers
    """
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    
    r = 6371  # Radius of earth in kilometers
    return c * r


def get_parcels_db_connection():
    """Create parcels database connection"""
    try:
        conn = sqlite3.connect(PARCELS_DATABASE_PATH)
        conn.row_factory = sqlite3.Row
        return conn
    except Exception as e:
        logger.error(f"Parcels database connection error: {str(e)}")
        raise


# ============================================
# FAST INTERACTION LOGGING (WITH BACKGROUND USER TRACKING)
# ============================================

def store_user_if_new(user_id, username):
    """
    Runs in background thread - doesn't slow down the API response
    Checks if user exists and adds them if they're new
    """
    user_ids_file_path = 'data/user_ids.csv'
    
    try:
        # Check if user exists
        existing_ids = set()
        try:
            with open(user_ids_file_path, 'r', encoding='utf-8') as file:
                existing_ids = {row[0] for row in csv.reader(file) if row}
        except FileNotFoundError:
            pass
        
        # Add if new
        if str(user_id) not in existing_ids:
            with open(user_ids_file_path, 'a', newline='', encoding='utf-8') as file:
                csv.writer(file).writerow([user_id, username])
            logger.info(f"New user added: {user_id} ({username})")
                
    except Exception as e:
        logger.error(f"Background user store error: {e}")


def store_interaction(user_id, username, action, interaction_time=None):
    """
    FAST interaction logging:
    1. Inserts the log row into SQLite (single indexed insert)
    2. Checks/stores user ID in background thread (doesn't block response)
    """
    try:
        record_interaction(user_id, username, action, interaction_time)
    except Exception as e:
        logger.error(f"Log write error: {e}")
    
    # BACKGROUND: Check/store user ID without blocking the response
    thread = threading.Thread(target=store_user_if_new, args=(user_id, username))
    thread.daemon = True
    thread.start()
        
# ============================================
# API ENDPOINTS
# ============================================

@app.route('/api/health', methods=['GET'])
def health_check():
    """
    Health check endpoint
    No rate limit for health checks
    """
    return jsonify({
        'status': 'ok',
        'service': 'Muslim Vegukin Bot API',
        'version': '2.0.0 (Generic)',
        'protection': 'Rate limited (200/hour per IP)',
        'supported_types': VALID_BUILDING_TYPES
    })




@app.route('/api/log-interaction', methods=['POST', 'OPTIONS'])
@limiter.exempt 
def log_interaction_api():
    """
    Log user interaction - FAST version
    Returns immediately after appending log, user tracking happens in background
    """
    # Handle preflight OPTIONS request
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json()
        
        user_id = data.get('user_id')
        username = data.get('username', 'unknown')
        action = data.get('action')
        
        if not user_id or not action:
            return jsonify({'error': 'Missing user_id or action'}), 400
        
        # This is now FAST - returns immediately
        store_interaction(user_id, username, action)
        
        return jsonify({'success': True}), 200
    
    except Exception as e:
        logger.error(f"log-interaction error: {e}")
        return jsonify({'error': str(e)}), 500



@app.route('/api/places/nearby', methods=['GET'])
@limiter.exempt 
def get_nearby_places():
    """
    Get nearby places (mosques, restaurants, shops) based on user location
    
    Query Parameters:
    - lat: User's latitude (required)
    - lon: User's longitude (required)
    - building_type: Type of building (Masjid, Oshxona, Do'kon) (required)
    - limit: Number of results (default: 5, max: 10)
    
    Rate Limited: 200 requests per hour per IP
    """
    ip = get_remote_address()
    
    try:
        # Get and validate parameters
        user_lat = float(request.args.get('lat'))
        user_lon = float(request.args.get('lon'))
        building_type = request.args.get('building_type', 'Masjid')
        limit = min(int(request.args.get('limit', 5)), 10)  # Max 10 results
        
        # Validate building type
        if building_type not in VALID_BUILDING_TYPES:
            logger.warning(f"Invalid building_type '{building_type}' from IP: {ip}")
            return jsonify({
                'success': False,
                'error': f'Invalid building_type. Must be one of: {", ".join(VALID_BUILDING_TYPES)}'
            }), 400
        
        logger.info(f"GET /api/places/nearby?building_type={building_type} from IP: {ip}")
        
        # Connect to database
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Query places by building type
        # Note: We fetch more results than needed because we're using approximate
        # Euclidean distance in SQL for initial filtering, then sorting by accurate
        # Haversine distance in Python
        fetch_limit = min(limit * 5, 50)  # Fetch 5x more, max 50
        
        cursor.execute("""
            SELECT 
                City_English,
                Name,
                Actual_address,
                Tel,
                Latitude,
                Longitude,
                KakaoMap_link,
                NaverMap_Link,
                Photo_path,
                Unique_number,
                Building_type,
                Menu_URL,
                telegram_url,
                tiktok_url,
                instagram_url,
                owner_note,
                (SELECT COUNT(*) FROM reviews WHERE reviews.Unique_number = main_db.Unique_number) AS review_count,
                (SELECT AVG(Rating) FROM reviews WHERE reviews.Unique_number = main_db.Unique_number) AS avg_rating
            FROM main_db
            WHERE Building_type = ?
              AND NOT (COALESCE(Latitude, 0) = 0 AND COALESCE(Longitude, 0) = 0)
            ORDER BY (
                (Latitude - ?)*(Latitude - ?) + 
                (Longitude - ?)*(Longitude - ?)
            ) ASC
            LIMIT ?
        """, (building_type, user_lat, user_lat, user_lon, user_lon, fetch_limit))
        
        results = cursor.fetchall()
        conn.close()
        
        # Calculate accurate Haversine distances for all results
        places_with_distance = []
        for row in results:
            distance = haversine(user_lat, user_lon, row['Latitude'], row['Longitude'])
            
            place = {
                'id': row['Unique_number'],
                'name': row['Name'],
                'city': row['City_English'],
                'address': row['Actual_address'],
                'phone': row['Tel'],
                'distance': round(distance, 2),
                'lat': row['Latitude'],
                'lon': row['Longitude'],
                'kakaoMapUrl': row['KakaoMap_link'],
                'naverMapUrl': row['NaverMap_Link'],
                'photo': row['Photo_path'],
                'buildingType': row['Building_type'],
                'menuUrl': row['Menu_URL'],
                'telegramUrl': row['telegram_url'],
                'tiktokUrl': row['tiktok_url'],
                'instagramUrl': row['instagram_url'],
                'ownerNote': row['owner_note'],
                'reviewCount': row['review_count'],
                'averageRating': round(row['avg_rating'], 1) if row['avg_rating'] else 0
            }
            places_with_distance.append((distance, place))
        
        # Sort by actual Haversine distance and take only the requested limit
        places_with_distance.sort(key=lambda x: x[0])
        places = [place for _, place in places_with_distance[:limit]]
        
        logger.info(f"Returned {len(places)} {building_type}(s) to IP: {ip}")
        
        return jsonify({
            'success': True,
            'count': len(places),
            'building_type': building_type,
            'places': places
        })
        
    except ValueError as e:
        logger.warning(f"Invalid coordinates from IP: {ip} - {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Invalid coordinates provided'
        }), 400
    except Exception as e:
        logger.error(f"Error in nearby_places: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@app.route('/api/places/by-address', methods=['GET'])
@limiter.exempt 
def get_places_by_address():
    """
    Get places near a specific address
    Uses Kakao API first (same as database), falls back to Nominatim API if needed
    
    Query Parameters:
    - address: Korean address (required)
    - building_type: Type of building (Masjid, Oshxona, Do'kon) (required)
    - limit: Number of results (default: 5, max: 10)
    
    Rate Limited: 200 requests per hour per IP
    """
    ip = get_remote_address()
    
    try:
        import requests
        
        address = request.args.get('address')
        building_type = request.args.get('building_type', 'Masjid')
        
        if not address:
            return jsonify({
                'success': False,
                'error': 'Address parameter is required'
            }), 400
        
        # Validate building type
        if building_type not in VALID_BUILDING_TYPES:
            return jsonify({
                'success': False,
                'error': f'Invalid building_type. Must be one of: {", ".join(VALID_BUILDING_TYPES)}'
            }), 400
        
        limit = min(int(request.args.get('limit', 5)), 10)
        
        logger.info(f"GET /api/places/by-address?building_type={building_type} from IP: {ip}")
        
        # Step 1: Try Kakao API first (same API used to populate database coordinates)
        lat = None
        lon = None
        geocode_source = None
        display_name = None

        try:
            kakao_url = "https://dapi.kakao.com/v2/local/search/address.json"
            kakao_headers = {
                "Authorization": f"KakaoAK {KAKAO_API_KEY}"
            }
            
            kakao_response = requests.get(kakao_url, params={"query": address}, headers=kakao_headers, timeout=5)
            kakao_data = kakao_response.json()
            
            if kakao_data.get('documents'):
                lat = float(kakao_data['documents'][0]['y'])
                lon = float(kakao_data['documents'][0]['x'])
                display_name = kakao_data['documents'][0].get('address_name', address)
                geocode_source = 'kakao'
                logger.info(f"Kakao geocoded '{address}' to ({lat}, {lon})")
        except Exception as e:
            logger.warning(f"Kakao geocoding failed for '{address}': {str(e)}")

        # Step 2: If Kakao fails, try Nominatim API as fallback
        if lat is None or lon is None:
            try:
                geocode_url = 'https://nominatim.openstreetmap.org/search'
                params = {
                    'q': address,
                    'format': 'json',
                    'limit': 1,
                    'countrycodes': 'kr'
                }
                headers = {
                    'User-Agent': 'MuslimVegukinBot/2.0'
                }
                
                response = requests.get(geocode_url, params=params, headers=headers, timeout=5)
                geocode_data = response.json()
                
                if geocode_data:
                    lat = float(geocode_data[0]['lat'])
                    lon = float(geocode_data[0]['lon'])
                    display_name = geocode_data[0].get('display_name')
                    geocode_source = 'nominatim'
                    logger.info(f"Nominatim geocoded '{address}' to ({lat}, {lon})")
            except Exception as e:
                logger.warning(f"Nominatim geocoding failed for '{address}': {str(e)}")

        # Step 3: If both fail, return error
        if lat is None or lon is None:
            logger.warning(f"Address not found by any geocoder: {address} from IP: {ip}")
            return jsonify({
                'success': False,
                'error': 'Address not found. Please use Korean address format.'
            }), 404
        
        # Query nearby places
        # Fetch more results for accurate sorting by Haversine distance
        fetch_limit = min(limit * 5, 50)
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT 
                City_English,
                Name,
                Actual_address,
                Tel,
                Latitude,
                Longitude,
                KakaoMap_link,
                NaverMap_Link,
                Photo_path,
                Unique_number,
                Building_type,
                Menu_URL,
                telegram_url,
                tiktok_url,
                instagram_url,
                owner_note,
                (SELECT COUNT(*) FROM reviews WHERE reviews.Unique_number = main_db.Unique_number) AS review_count,
                (SELECT AVG(Rating) FROM reviews WHERE reviews.Unique_number = main_db.Unique_number) AS avg_rating
            FROM main_db
            WHERE Building_type = ?
              AND NOT (COALESCE(Latitude, 0) = 0 AND COALESCE(Longitude, 0) = 0)
            ORDER BY (
                (Latitude - ?)*(Latitude - ?) + 
                (Longitude - ?)*(Longitude - ?)
            ) ASC
            LIMIT ?
        """, (building_type, lat, lat, lon, lon, fetch_limit))
        
        results = cursor.fetchall()
        conn.close()
        
        # Normalize the searched address for comparison (remove spaces and make lowercase)
        normalized_search_address = address.replace(" ", "").lower()
        
        places_with_distance = []
        for row in results:
            # Check if this is the exact address being searched
            normalized_db_address = row['Actual_address'].replace(" ", "").lower() if row['Actual_address'] else ""
            
            # If addresses match exactly, distance is 0
            # Otherwise, calculate Haversine distance
            if normalized_search_address == normalized_db_address:
                distance = 0.0
            else:
                distance = haversine(lat, lon, row['Latitude'], row['Longitude'])
            
            place = {
                'id': row['Unique_number'],
                'name': row['Name'],
                'city': row['City_English'],
                'address': row['Actual_address'],
                'phone': row['Tel'],
                'distance': round(distance, 2),
                'lat': row['Latitude'],
                'lon': row['Longitude'],
                'kakaoMapUrl': row['KakaoMap_link'],
                'naverMapUrl': row['NaverMap_Link'],
                'photo': row['Photo_path'],
                'buildingType': row['Building_type'],
                'menuUrl': row['Menu_URL'],
                'telegramUrl': row['telegram_url'],
                'tiktokUrl': row['tiktok_url'],
                'instagramUrl': row['instagram_url'],
                'ownerNote': row['owner_note'],
                'reviewCount': row['review_count'],
                'averageRating': round(row['avg_rating'], 1) if row['avg_rating'] else 0
            }
            places_with_distance.append((distance, place))
        
        # Sort by actual Haversine distance and take only the requested limit
        places_with_distance.sort(key=lambda x: x[0])
        places = [place for _, place in places_with_distance[:limit]]
        
        logger.info(f"Address search '{address}' ({geocode_source}) returned {len(places)} {building_type}(s) to IP: {ip}")
        
        return jsonify({
            'success': True,
            'count': len(places),
            'building_type': building_type,
            'geocoded_location': {
                'lat': lat,
                'lon': lon,
                'display_name': display_name,
                'source': geocode_source
            },
            'places': places
        })
        
    except Exception as e:
        logger.error(f"Error in address search: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
    

@app.route('/api/place/<int:place_id>', methods=['GET'])
@limiter.exempt 
def get_place_details(place_id):
    """
    Get detailed information about a specific place (mosque, restaurant, or shop)
    
    Parameters:
    - place_id: Unique place ID
    
    Rate Limited: 200 requests per hour per IP
    """
    ip = get_remote_address()
    logger.info(f"GET /api/place/{place_id} from IP: {ip}")
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # The Mini App asks with ?view=1 instead of a separate POST /view call:
        # one round trip less every time a place page opens.
        if request.args.get('view') == '1':
            cursor.execute("UPDATE main_db SET view_count = COALESCE(view_count, 0) + 1 "
                           "WHERE Unique_number = ?", (place_id,))
            conn.commit()

        # Get place details (any building type)
        cursor.execute("""
            SELECT 
                City_English,
                Name,
                Actual_address,
                Tel,
                Latitude,
                Longitude,
                KakaoMap_link,
                NaverMap_Link,
                Photo_path,
                Unique_number,
                Building_type,
                view_count,
                Menu_URL,
                telegram_url,
                tiktok_url,
                instagram_url,
                owner_note
            FROM main_db
            WHERE Unique_number = ?
        """, (place_id,))
        
        row = cursor.fetchone()
        
        if not row:
            conn.close()
            logger.warning(f"Place {place_id} not found, requested by IP: {ip}")
            return jsonify({
                'success': False,
                'error': 'Place not found'
            }), 404
        
        # Get reviews
        cursor.execute("""
            SELECT Rating, Review_Text, Timestamp, User_ID
            FROM reviews
            WHERE Unique_number = ?
            ORDER BY Timestamp DESC
        """, (place_id,))
        
        reviews_data = cursor.fetchall()

        # Fields with a submission awaiting review, so the detail page can show
        # "waiting for review" instead of offering a form that would 409.
        pending_fields = get_pending_fields(conn, place_id)

        # Watcher count (public) and, when the Mini App sent its signed
        # initData, whether this user watches / owns the place.
        viewer = optional_user()
        watch_info = place_watch_info(conn, place_id, viewer)

        conn.close()
        
        # Format reviews. Who wrote one stays private (it used to send their
        # Telegram id to anyone); the asker's own is marked, to change or delete.
        viewer_id = str(int(viewer['id'])) if viewer and viewer.get('id') is not None else None
        reviews = []
        for review in reviews_data:
            reviews.append({
                'rating': review['Rating'],
                'text': review['Review_Text'],
                'timestamp': review['Timestamp'],
                'mine': viewer_id is not None and str(review['User_ID']) == viewer_id,
            })
        
        # Calculate average rating
        avg_rating = sum(r['rating'] for r in reviews) / len(reviews) if reviews else 0
        
        place = {
            'id': row['Unique_number'],
            'name': row['Name'],
            'city': row['City_English'],
            'address': row['Actual_address'],
            'phone': row['Tel'],
            'lat': row['Latitude'],
            'lon': row['Longitude'],
            'kakaoMapUrl': row['KakaoMap_link'],
            'naverMapUrl': row['NaverMap_Link'],
            'photo': row['Photo_path'],
            'buildingType': row['Building_type'],
            'menuUrl': row['Menu_URL'],
            'telegramUrl': row['telegram_url'],
            'tiktokUrl': row['tiktok_url'],
            'instagramUrl': row['instagram_url'],
            'ownerNote': row['owner_note'],
            'pendingFields': pending_fields,
            'watch': watch_info,
            'averageRating': round(avg_rating, 1),
            'reviewCount': len(reviews),
            'reviews': reviews,
            'view_count': row['view_count']
        }
        
        logger.info(f"Returned details for place {place_id} ({row['Building_type']}) to IP: {ip}")
        
        return jsonify({
            'success': True,
            'place': place
        })
        
    except Exception as e:
        logger.error(f"Error getting place details: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/place/<place_id>/view', methods=['POST'])
@limiter.exempt 
def increment_view_count(place_id):
    """Increment view count for a place"""
    ip = get_remote_address()
    logger.info(f"POST /api/place/{place_id}/view from IP: {ip}")
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE main_db 
            SET view_count = COALESCE(view_count, 0) + 1 
            WHERE Unique_number = ?
        """, (place_id,))
        
        conn.commit()
        
        # Get updated count
        cursor.execute("SELECT view_count FROM main_db WHERE Unique_number = ?", (place_id,))
        row = cursor.fetchone()
        conn.close()
        
        if row:
            return jsonify({'success': True, 'view_count': row['view_count']})
        return jsonify({'success': False, 'error': 'Place not found'}), 404
        
    except Exception as e:
        logger.error(f"Error incrementing view count: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# --- Reviews ---------------------------------------------------------------
# Writing and deleting them: places_public_api.py (one per person per place).
# Here, what follows a person whose app account changes or goes.


@on_user_moved
def _move_reviews(old_id, new_id):
    """An app user signed in and their id changed: their reviews follow."""
    conn = get_db_connection()
    try:
        conn.execute("UPDATE reviews SET User_ID = ? WHERE User_ID = ?", (str(new_id), str(old_id)))
        conn.commit()
    finally:
        conn.close()


@on_user_deleted
def _delete_reviews(user_id):
    """The person deleted their app account: their reviews go with it."""
    conn = get_db_connection()
    try:
        conn.execute("DELETE FROM reviews WHERE User_ID = ?", (str(user_id),))
        conn.commit()
    finally:
        conn.close()


@app.route('/api/stats', methods=['GET'])
def get_stats():
    """
    Get API usage statistics (for admin monitoring)
    No sensitive data exposed
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Count by building type
        stats = {}
        for building_type in VALID_BUILDING_TYPES:
            cursor.execute("SELECT COUNT(*) as count FROM main_db WHERE Building_type=?", (building_type,))
            stats[building_type] = cursor.fetchone()['count']
        
        # Total reviews
        cursor.execute("SELECT COUNT(*) as count FROM reviews")
        total_reviews = cursor.fetchone()['count']
        
        conn.close()
        
        return jsonify({
            'success': True,
            'stats': {
                'places_by_type': stats,
                'total_reviews': total_reviews,
                'rate_limit': '200 requests/hour per IP',
                'max_results_per_query': 10
            }
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/parcels/dates', methods=['GET'])
@limiter.exempt 
def get_parcel_dates():
    """
    Get list of available parcel dates with post counts
    Only returns dates from today (Korea time) onwards
    Query params: direction (optional, 0 = UZB→KOR, 1 = KOR→UZB)
    """
    ip = get_remote_address()
    direction = request.args.get('direction', type=int)
    logger.info(f"GET /api/parcels/dates?direction={direction} from IP: {ip}")
    
    try:
        conn = get_parcels_db_connection()
        cursor = conn.cursor()
        
        if direction is not None and direction in [0, 1]:
            cursor.execute("""
                SELECT flight_time, flight_time_formatted, COUNT(*) as count
                FROM parcel_posts
                WHERE direction = ?
                GROUP BY flight_time_formatted, flight_time
            """, (direction,))
        else:
            cursor.execute("""
                SELECT flight_time, flight_time_formatted, COUNT(*) as count
                FROM parcel_posts
                GROUP BY flight_time_formatted, flight_time
            """)
        rows = cursor.fetchall()
        conn.close()
        
        # Filter dates from today onwards (Korea timezone)
        from datetime import datetime
        import pytz
        korea_tz = pytz.timezone("Asia/Seoul")
        today_korea = datetime.now(korea_tz).date()
        
        dates = []
        for row in rows:
            try:
                flight_date = datetime.strptime(row['flight_time_formatted'], "%d.%m.%Y").date()
                if flight_date >= today_korea:
                    # Get weekday in Uzbek
                    uzbek_weekdays = ['Dush.', 'Sesh.', 'Chor.', 'Pay.', 'Juma', 'Shan.', 'Yak.']
                    weekday = uzbek_weekdays[flight_date.weekday()]
                    
                    dates.append({
                        'date_formatted': row['flight_time_formatted'],
                        'date_uzbek': row['flight_time'],
                        'weekday': weekday,
                        'count': row['count']
                    })
            except Exception as e:
                logger.warning(f"Invalid date format: {row['flight_time_formatted']}")
                continue
        
        # Sort by date
        dates.sort(key=lambda x: datetime.strptime(x['date_formatted'], "%d.%m.%Y"))
        
        return jsonify({
            'success': True,
            'count': len(dates),
            'dates': dates
        })
        
    except Exception as e:
        logger.error(f"Error fetching parcel dates: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/parcels/by-date', methods=['GET'])
@limiter.exempt 
def get_parcels_by_date():
    """
    Get parcel posts for a specific date
    Query params: date (format: DD.MM.YYYY)
    """
    ip = get_remote_address()
    date = request.args.get('date')
    
    if not date:
        return jsonify({
            'success': False,
            'error': 'Date parameter is required'
        }), 400
    
    logger.info(f"GET /api/parcels/by-date?date={date} from IP: {ip}")
    
    try:
        conn = get_parcels_db_connection()
        cursor = conn.cursor()
        
        direction = request.args.get('direction', type=int)
        
        if direction is not None and direction in [0, 1]:
            cursor.execute("""
                SELECT telegram_id, username, message_text, flight_time, uzb_cities, kor_cities, direction
                FROM parcel_posts
                WHERE flight_time_formatted = ? AND direction = ?
            """, (date, direction))
        else:
            cursor.execute("""
                SELECT telegram_id, username, message_text, flight_time, uzb_cities, kor_cities, direction
                FROM parcel_posts
                WHERE flight_time_formatted = ?
            """, (date,))
        rows = cursor.fetchall()
        conn.close()
        
        posts = []
        for row in rows:
            posts.append({
                'telegram_id': row['telegram_id'],
                'username': row['username'],
                'message_text': row['message_text'],
                'flight_time': row['flight_time'],
                'uzb_cities': row['uzb_cities'],
                'kor_cities': row['kor_cities'],
                'direction': row['direction']
            })
        
        return jsonify({
            'success': True,
            'count': len(posts),
            'date': date,
            'posts': posts
        })
        
    except Exception as e:
        logger.error(f"Error fetching parcels by date: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/parcels/cities', methods=['GET'])
@limiter.exempt 
def get_parcel_cities():
    """
    Get list of cities with parcel post counts
    Query params: country ('uzb' or 'kor')
    """
    ip = get_remote_address()
    country = request.args.get('country', 'uzb')
    
    if country not in ['uzb', 'kor']:
        return jsonify({
            'success': False,
            'error': 'Country must be "uzb" or "kor"'
        }), 400
    
    logger.info(f"GET /api/parcels/cities?country={country} from IP: {ip}")
    
    column = 'uzb_cities' if country == 'uzb' else 'kor_cities'
    direction = request.args.get('direction', type=int)
    
    try:
        conn = get_parcels_db_connection()
        cursor = conn.cursor()
        
        if direction is not None and direction in [0, 1]:
            cursor.execute(f"""
                SELECT {column}, flight_time_formatted
                FROM parcel_posts
                WHERE {column} IS NOT NULL AND direction = ?
            """, (direction,))
        else:
            cursor.execute(f"""
                SELECT {column}, flight_time_formatted
                FROM parcel_posts
                WHERE {column} IS NOT NULL
            """)
        rows = cursor.fetchall()
        conn.close()
        
        # Filter by date (today onwards in Korea timezone)
        from datetime import datetime
        from collections import Counter
        import pytz
        
        korea_tz = pytz.timezone("Asia/Seoul")
        today_korea = datetime.now(korea_tz).date()
        
        counter = Counter()
        
        for row in rows:
            try:
                flight_date = datetime.strptime(row['flight_time_formatted'], "%d.%m.%Y").date()
                if flight_date < today_korea:
                    continue
            except:
                continue
            
            city_field = row[column]
            if city_field:
                cities = city_field.split(",")
                cleaned = [c.strip().capitalize() for c in cities if c.strip()]
                counter.update(cleaned)
        
        # Sort alphabetically
        cities = [{'city': city, 'count': count} for city, count in sorted(counter.items())]
        
        return jsonify({
            'success': True,
            'country': country,
            'count': len(cities),
            'cities': cities
        })
        
    except Exception as e:
        logger.error(f"Error fetching parcel cities: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/parcels/by-city', methods=['GET'])
@limiter.exempt 
def get_parcels_by_city():
    """
    Get parcel posts for a specific city
    Query params: city, country ('uzb' or 'kor')
    """
    ip = get_remote_address()
    city = request.args.get('city')
    country = request.args.get('country', 'uzb')
    
    if not city:
        return jsonify({
            'success': False,
            'error': 'City parameter is required'
        }), 400
    
    if country not in ['uzb', 'kor']:
        return jsonify({
            'success': False,
            'error': 'Country must be "uzb" or "kor"'
        }), 400
    
    logger.info(f"GET /api/parcels/by-city?city={city}&country={country} from IP: {ip}")
    
    column = 'uzb_cities' if country == 'uzb' else 'kor_cities'
    direction = request.args.get('direction', type=int)
    
    try:
        conn = get_parcels_db_connection()
        cursor = conn.cursor()
        
        if direction is not None and direction in [0, 1]:
            cursor.execute(f"""
                SELECT telegram_id, username, message_text, flight_time, flight_time_formatted, uzb_cities, kor_cities, direction
                FROM parcel_posts
                WHERE {column} LIKE ? AND direction = ?
            """, (f"%{city}%", direction))
        else:
            cursor.execute(f"""
                SELECT telegram_id, username, message_text, flight_time, flight_time_formatted, uzb_cities, kor_cities, direction
                FROM parcel_posts
                WHERE {column} LIKE ?
            """, (f"%{city}%",))
        rows = cursor.fetchall()
        conn.close()
        
        # Filter by date (today onwards in Korea timezone)
        from datetime import datetime
        import pytz
        
        korea_tz = pytz.timezone("Asia/Seoul")
        today_korea = datetime.now(korea_tz).date()
        
        posts = []
        for row in rows:
            try:
                flight_date = datetime.strptime(row['flight_time_formatted'], "%d.%m.%Y").date()
                if flight_date < today_korea:
                    continue
            except:
                continue
            
            posts.append({
                'telegram_id': row['telegram_id'],
                'username': row['username'],
                'message_text': row['message_text'],
                'flight_time': row['flight_time'],
                'date_formatted': row['flight_time_formatted'],
                'uzb_cities': row['uzb_cities'],
                'kor_cities': row['kor_cities'],
                'direction': row['direction']
            })
        
        return jsonify({
            'success': True,
            'city': city,
            'country': country,
            'count': len(posts),
            'posts': posts
        })
        
    except Exception as e:
        logger.error(f"Error fetching parcels by city: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# /api/interaction-logs (CSV export) and /api/interaction-stats now live in
# interaction_logs.py, both behind the admin session.



#===========================================
# JOB GROUP INVITE ENDPOINT
# ============================================
def revoke_invite_link_after_delay(chat_id, invite_link, delay=10):
    def revoke():
        time.sleep(delay)
        try:
            revoke_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/revokeChatInviteLink"
            requests.post(revoke_url, json={
                "chat_id": chat_id,
                "invite_link": invite_link
            }, timeout=10)
            logger.info(f"Revoked invite link after {delay}s: {invite_link[:30]}...")
        except Exception as e:
            logger.error(f"Failed to revoke invite link: {str(e)}")
    thread = threading.Thread(target=revoke)
    thread.daemon = True
    thread.start()


#===========================================
# JOB GROUP INVITE ENDPOINT
# ============================================
def revoke_invite_link_after_delay(invite_link, delay=10):
    """Background task to revoke invite link after delay"""
    def revoke():
        time.sleep(delay)
        try:
            revoke_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/revokeChatInviteLink"
            requests.post(revoke_url, json={
                "chat_id": JOB_GROUP_ID,
                "invite_link": invite_link
            }, timeout=10)
            logger.info(f"Revoked invite link after {delay}s: {invite_link[:30]}...")
        except Exception as e:
            logger.error(f"Failed to revoke invite link: {str(e)}")

    thread = threading.Thread(target=revoke)
    thread.daemon = True
    thread.start()
@app.route('/api/group/invite', methods=['POST'])
@limiter.limit("100000 per hour")  # Strict limit to prevent abuse
def create_group_invite():
    """
    Create a one-time invite link for the Job Group

    JSON Body:
    - user_id: Telegram user ID (required)

    Rate Limited: 10 requests per hour per IP
    """
    ip = get_remote_address()

    try:
        data = request.get_json()
        user_id = data.get('user_id') if data else None

        if not user_id:
            return jsonify({
                'success': False,
                'error': 'User ID is required'
            }), 400

        if not TELEGRAM_BOT_TOKEN:
            logger.error("TELEGRAM_BOT_TOKEN not configured")
            return jsonify({
                'success': False,
                'error': 'Server configuration error'
            }), 500

        logger.info(f"POST /api/group/invite from user {user_id}, IP: {ip}")

        # Create invite link via Telegram Bot API
        create_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/createChatInviteLink"

        response = requests.post(create_url, json={
            "chat_id": JOB_GROUP_ID,
            "member_limit": 1,  # One-time use
            "name": f"web_user_{user_id}_{int(time.time())}"
        }, timeout=10)

        result = response.json()

        if not result.get('ok'):
            logger.error(f"Telegram API error: {result}")
            return jsonify({
                'success': False,
                'error': 'Failed to create invite link'
            }), 500

        invite_link = result['result']['invite_link']

        # Schedule revocation after 15 seconds
        revoke_invite_link_after_delay(invite_link, delay=15)  # what the page promises

        logger.info(f"Created invite link for user {user_id}: {invite_link[:30]}...")

        return jsonify({
            'success': True,
            'invite_link': invite_link
        })

    except Exception as e:
        logger.error(f"Error creating invite link: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ============================================================
# PAYMENT ENDPOINTS
# ============================================================
@app.route('/api/payment/create', methods=['POST'])
def create_payment():
    data = request.get_json()
    user_id = data.get('user_id')
    if not user_id:
        return jsonify({'success': False, 'error': 'User ID required'}), 400
    result = pay_manager.create_payment(user_id=user_id, amount=40000)
    if result:
        return jsonify({'success': True, **result})
    return jsonify({'success': False, 'error': 'Payment creation failed'}), 500


@app.route('/api/payment/check', methods=['POST'])
def check_payment():
    data = request.get_json()
    user_id = data.get('user_id')
    payment_id = data.get('payment_id')
    if not user_id:
        return jsonify({'success': False, 'error': 'User ID required'}), 400
    if not payment_id:
        latest = pay_manager.get_pending_payment(user_id)
        if not latest:
            return jsonify({'success': False, 'error': 'No payment found'}), 404
        payment_id = latest['payment_id']
    is_paid = pay_manager.check_payment(payment_id)
    if is_paid:
        sub_manager.activate_subscription(user_id)
        return jsonify({'success': True, 'paid': True, 'message': 'Obuna faollashtirildi!'})
    return jsonify({'success': True, 'paid': False, 'message': "To'lov topilmadi. Qayta urinib ko'ring."})


@app.route('/api/payment/mock-pay', methods=['POST'])
def mock_payment():
    """TESTING ONLY — remove in production"""
    data = request.get_json()
    payment_id = data.get('payment_id')
    if not payment_id:
        return jsonify({'success': False, 'error': 'Payment ID required'}), 400
    pay_manager.mock_pay(payment_id)
    return jsonify({'success': True, 'message': 'Mock payment completed'})


# ============================================================
# ADMIN ENDPOINTS
# ============================================================
@app.route('/admin')
def admin_dashboard():
    return send_file('templates/admin_dashboard.html')

@app.route('/admin/login', methods=['POST'])
@limiter.limit("10 per minute")   # keeps guessing the password impractical
def admin_login():
    data = request.get_json(silent=True) or {}
    if _admin_password_ok(data.get('password')):  # Same password as parcels
        session['admin_logged_in'] = True
        session['admin_authenticated'] = True  # Also set parcels session
        return jsonify({'success': True})
    logger.warning(f"[ADMIN] failed login from {get_remote_address()}")
    return jsonify({'success': False}), 401

@app.route('/admin/logout', methods=['POST'])
def admin_logout():
    session.pop('admin_logged_in', None)
    session.pop('admin_authenticated', None)
    return jsonify({'success': True})

@app.route('/admin/check-session')
def admin_check_session():
    return jsonify({'authenticated': session.get('admin_logged_in', False)})

@app.route('/admin/subscriptions')
def admin_subscriptions():
    if not session.get('admin_logged_in'):
        return redirect('/admin')
    return send_file('templates/admin_panel_v2.html')


@app.route('/api/admin/users', methods=['GET'])
def admin_get_users():
    users = sub_manager.get_all_users()
    return jsonify({'success': True, 'users': users})


@app.route('/api/admin/confirm', methods=['POST'])
def admin_confirm_payment():
    data = request.get_json()
    user_id = data.get('user_id')
    if not user_id:
        return jsonify({'success': False, 'error': 'User ID required'}), 400
    result = sub_manager.confirm_payment(user_id)
    return jsonify(result)


@app.route('/api/admin/kick', methods=['POST'])
def admin_kick_user():
    data = request.get_json()
    user_id = data.get('user_id')
    if not user_id:
        return jsonify({'success': False, 'error': 'User ID required'}), 400
    result = sub_manager.admin_kick(user_id)
    return jsonify(result)


@app.route('/api/admin/place/<int:place_id>/menu-url', methods=['POST', 'DELETE'])
def admin_set_menu_url(place_id):
    """
    Set or clear the Menu_URL for a place.
 
    POST body: { "menu_url": "https://muslimvegukin.com/menu/toshkent_halal/" }
    DELETE: removes the menu URL (sets to NULL)
 
    Returns: { ok: true, place_id, menu_url }
    """
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
 
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
 
        # Verify place exists and is a restaurant
        cursor.execute(
            "SELECT Unique_number, Name, Building_type FROM main_db WHERE Unique_number = ?",
            (place_id,)
        )
        row = cursor.fetchone()
        if not row:
            conn.close()
            return jsonify({'success': False, 'error': 'Place not found'}), 404
 
        if row['Building_type'] != "Oshxona":
            conn.close()
            return jsonify({
                'success': False,
                'error': f"Menu URL only applies to restaurants (Building_type='Oshxona'). This place is '{row['Building_type']}'."
            }), 400
 
        if request.method == 'DELETE':
            cursor.execute(
                "UPDATE main_db SET Menu_URL = NULL WHERE Unique_number = ?",
                (place_id,)
            )
            conn.commit()
            conn.close()
            logger.info(f"[ADMIN] Cleared Menu_URL for place {place_id} ({row['Name']})")
            return jsonify({'success': True, 'place_id': place_id, 'menu_url': None})
 
        # POST: set the URL
        body = request.get_json(silent=True) or {}
        menu_url = (body.get('menu_url') or '').strip()
        if not menu_url:
            conn.close()
            return jsonify({'success': False, 'error': 'menu_url is required'}), 400
        if not (menu_url.startswith('http://') or menu_url.startswith('https://')):
            conn.close()
            return jsonify({'success': False, 'error': 'menu_url must start with http:// or https://'}), 400
 
        cursor.execute(
            "UPDATE main_db SET Menu_URL = ? WHERE Unique_number = ?",
            (menu_url, place_id)
        )
        conn.commit()
        conn.close()
        logger.info(f"[ADMIN] Set Menu_URL for place {place_id} ({row['Name']}): {menu_url}")
        return jsonify({'success': True, 'place_id': place_id, 'menu_url': menu_url})
 
    except Exception as e:
        logger.error(f"Error setting Menu_URL for place {place_id}: {e}")
        return jsonify({'success': False, 'error': 'Internal server error'}), 500


# ============================================================
# SCREENSHOT ENDPOINTS
# ============================================================
@app.route('/api/admin/screenshot', methods=['POST'])
def submit_screenshot():
    """Receive screenshot from @job_hunter_acc bot"""
    data = request.get_json()
    user_id = data.get('user_id')
    file_id = data.get('file_id')
    if not user_id or not file_id:
        return jsonify({'success': False, 'error': 'user_id and file_id required'}), 400
    success = sub_manager.save_screenshot(
        user_id=user_id,
        first_name=data.get('first_name', ''),
        last_name=data.get('last_name', ''),
        username=data.get('username', ''),
        file_id=file_id
    )
    return jsonify({'success': success})


@app.route('/api/admin/pending', methods=['GET'])
def get_pending_screenshots():
    filter_status = request.args.get('filter', 'pending')
    screenshots = sub_manager.get_screenshots_by_status(filter_status)
    pending_count = sub_manager.get_pending_count()
    return jsonify({'success': True, 'screenshots': screenshots, 'pending_count': pending_count})


@app.route('/api/admin/approve', methods=['POST'])
def approve_screenshot_route():
    data = request.get_json()
    screenshot_id = data.get('screenshot_id')
    user_id = data.get('user_id')
    if not screenshot_id or not user_id:
        return jsonify({'success': False, 'error': 'screenshot_id and user_id required'}), 400
    result = sub_manager.approve_screenshot(screenshot_id, user_id)
    return jsonify(result)


@app.route('/api/admin/reject', methods=['POST'])
def reject_screenshot_route():
    data = request.get_json()
    screenshot_id = data.get('screenshot_id')
    user_id = data.get('user_id')
    if not screenshot_id or not user_id:
        return jsonify({'success': False, 'error': 'screenshot_id and user_id required'}), 400
    result = sub_manager.reject_screenshot(screenshot_id, user_id)
    return jsonify(result)


@app.route('/api/admin/screenshot-image/<file_id>')
def serve_screenshot(file_id):
    """Proxy Telegram image to admin panel"""
    try:
        # IMPORTANT: Use JOB_HUNTER_BOT_TOKEN here, not TELEGRAM_BOT_TOKEN
        # because file_ids are bot-specific
        file_info = requests.get(
            f"https://api.telegram.org/bot{JOB_HUNTER_PAYMENT_BOT_TOKEN}/getFile",
            params={"file_id": file_id},
            timeout=10
        ).json()

        if not file_info.get('ok'):
            return 'File not found', 404

        file_path = file_info['result']['file_path']
        image_resp = requests.get(
            f"https://api.telegram.org/file/bot{JOB_HUNTER_PAYMENT_BOT_TOKEN}/{file_path}",
            timeout=15
        )

        content_type = 'image/png' if file_path.endswith('.png') else 'image/jpeg'
        return Response(image_resp.content, content_type=content_type)

    except Exception as e:
        logger.error(f"Failed to serve screenshot: {str(e)}")
        return 'Error loading image', 500

# ============================================
# ADS CONFIGURATION
# ============================================

ADS_DATABASE_PATH = '/home/ubuntu/vegukin_api/data/ads.sqlite'

def get_ads_db_connection():
    """Create connection to ads database"""
    try:
        conn = sqlite3.connect(ADS_DATABASE_PATH)
        conn.row_factory = sqlite3.Row
        return conn
    except Exception as e:
        logger.error(f"Ads database connection error: {str(e)}")
        raise

def get_current_date_str():
    """Returns current date in Asia/Seoul timezone as YYYY-MM-DD"""
    kst = pytz.timezone("Asia/Seoul")
    return datetime.now(kst).date().isoformat()

# ============================================
# ADS API ENDPOINTS
# ============================================

@app.route('/api/ads/next', methods=['GET'])
@limiter.exempt  # No rate limit for ads
def get_next_ad():
    """
    Get next ad for user
    Query params: user_id (required)
    Returns next eligible ad in sequence, skipping recently hidden ads (last 7 days)
    """
    try:
        user_id = request.args.get('user_id', type=int)
        
        if not user_id:
            return jsonify({'success': False, 'error': 'user_id required'}), 400
        
        today = get_current_date_str()
        week_ago = (datetime.now(pytz.timezone("Asia/Seoul")) - timedelta(days=7)).isoformat()
        
        conn = get_ads_db_connection()
        cursor = conn.cursor()
        
        # Ensure tables exist
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS ad_sequence_tracker (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                next_ad_index INTEGER
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_hidden_ads (
                user_id INTEGER,
                ad_id TEXT,
                hidden_at TEXT,
                PRIMARY KEY (user_id, ad_id)
            )
        """)
        
        # Get next index
        cursor.execute("SELECT next_ad_index FROM ad_sequence_tracker WHERE id = 1")
        row = cursor.fetchone()
        next_index = row["next_ad_index"] if row else 0
        
        # Get active ads in order
        cursor.execute("""
            SELECT * FROM ads
            WHERE start_date <= ? AND end_date >= ?
            ORDER BY ad_id ASC
        """, (today, today))
        active_ads = cursor.fetchall()
        ad_count = len(active_ads)
        
        if ad_count == 0:
            conn.close()
            return jsonify({'success': True, 'ad': None})
        
        # Get user's recently hidden ads (within last 7 days)
        cursor.execute("""
            SELECT ad_id FROM user_hidden_ads
            WHERE user_id = ? AND hidden_at > ?
        """, (user_id, week_ago))
        hidden_ad_ids = {row["ad_id"] for row in cursor.fetchall()}
        
        # Try to find next visible ad
        for i in range(ad_count):
            ad = active_ads[(next_index + i) % ad_count]
            if ad["ad_id"] not in hidden_ad_ids:
                # Increment view count
                cursor.execute("""
                    UPDATE ads SET view_count = view_count + 1 WHERE ad_id = ?
                """, (ad["ad_id"],))
                
                # Update next index globally
                new_index = (next_index + i + 1) % ad_count
                if row:
                    cursor.execute("UPDATE ad_sequence_tracker SET next_ad_index = ? WHERE id = 1", (new_index,))
                else:
                    cursor.execute("INSERT INTO ad_sequence_tracker (id, next_ad_index) VALUES (1, ?)", (new_index,))
                
                conn.commit()
                
                # Return image filename only (web app will load from its own assets)
                image_filename = None
                if ad["image"]:
                    # Extract filename: 'data/ads_image/ad_001.jpg' -> 'ad_001.jpg'
                    image_filename = os.path.basename(ad["image"])
                
                result = {
                    'success': True,
                    'ad': {
                        'ad_id': ad["ad_id"],
                        'html': ad["html"],
                        'button_text': ad["button_text"],
                        'image': image_filename,  # Just filename, web app constructs full path
                        'view_count': ad["view_count"] + 1
                    }
                }
                
                conn.close()
                logger.info(f"Served ad {ad['ad_id']} to user {user_id}")
                return jsonify(result)
        
        # All ads hidden - advance index anyway
        new_index = (next_index + 1) % ad_count
        if row:
            cursor.execute("UPDATE ad_sequence_tracker SET next_ad_index = ? WHERE id = 1", (new_index,))
        else:
            cursor.execute("INSERT INTO ad_sequence_tracker (id, next_ad_index) VALUES (1, ?)", (new_index,))
        conn.commit()
        conn.close()
        
        logger.info(f"No visible ads for user {user_id}")
        return jsonify({'success': True, 'ad': None})
        
    except Exception as e:
        logger.error(f"Error fetching ad: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/ads/hide', methods=['POST'])
@limiter.exempt  # No rate limit for hiding ads
def hide_ad():
    """
    Mark ad as hidden for user (for 7 days)
    Body: {"user_id": 123, "ad_id": "ad-001"}
    """
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        ad_id = data.get('ad_id')
        
        if not user_id or not ad_id:
            return jsonify({'success': False, 'error': 'user_id and ad_id required'}), 400
        
        kst = pytz.timezone("Asia/Seoul")
        hidden_at = datetime.now(kst).isoformat()
        
        conn = get_ads_db_connection()
        cursor = conn.cursor()
        
        # INSERT OR REPLACE updates hidden_at if already exists
        cursor.execute("""
            INSERT OR REPLACE INTO user_hidden_ads (user_id, ad_id, hidden_at)
            VALUES (?, ?, ?)
        """, (user_id, ad_id, hidden_at))
        
        conn.commit()
        conn.close()
        
        logger.info(f"User {user_id} hid ad {ad_id}")
        return jsonify({'success': True, 'message': 'Ad hidden for 7 days'})
        
    except Exception as e:
        logger.error(f"Error hiding ad: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


# ============================================
# QNA CONFIGURATION
# ============================================

# Qdrant Cloud credentials
QDRANT_URL = _secret("QDRANT_URL", required=False)
QDRANT_API_KEY = _secret("QDRANT_API_KEY", required=False)
QNA_COLLECTION_NAME = "islamic_qna"

# Cohere API configuration
COHERE_API_KEYS = _secret_list("COHERE_API_KEYS")
COHERE_MODEL = "embed-multilingual-v3.0"
COHERE_API_KEY_LIMIT = 1000  # Max queries per key per month

# QnA data paths
QNA_DATA_DIR = '/home/ubuntu/vegukin_api/data/qna'
QNA_API_KEY_USAGE_FILE = os.path.join(QNA_DATA_DIR, 'api_key_usage.json')
QNA_SEARCH_LOGS_FILE = os.path.join(QNA_DATA_DIR, 'search_logs.csv')

# Ensure QnA data directory exists
os.makedirs(QNA_DATA_DIR, exist_ok=True)


# ============================================
# QNA: TRANSLITERATION (Import from transliterate.py)
# ============================================

# Import the full transliteration module
# Place transliterate.py in the same directory as this file
from transliterate import to_cyrillic


def detect_alphabet(text):
    """Detect if text is Cyrillic or Latin."""
    cyrillic_pattern = any('\u0400' <= char <= '\u04FF' for char in text)
    return 'cyrillic' if cyrillic_pattern else 'latin'


# ============================================
# QNA: COHERE API KEY MANAGER
# ============================================

class CohereKeyManager:
    """Manages Cohere API keys with usage tracking and rotation."""
    
    def __init__(self):
        self.api_keys = COHERE_API_KEYS
        self.limit = COHERE_API_KEY_LIMIT
        self.usage_file = QNA_API_KEY_USAGE_FILE
        self.current_index = 0
        self.lock = threading.Lock()
        
        # Load or initialize usage tracking
        self.usage = self._load_usage()
        
        # Find first available key (under limit)
        self._find_available_key()
        
        # Initialize Cohere client
        self.client = cohere.Client(self.api_keys[self.current_index])
        
        logger.info(f"[QnA Cohere] Initialized with key index {self.current_index}, usage: {self.get_current_usage()}/{self.limit}")
    
    def _load_usage(self):
        """Load API key usage from file."""
        if os.path.exists(self.usage_file):
            try:
                with open(self.usage_file, 'r') as f:
                    usage = json.load(f)
                    # Ensure all keys are tracked
                    for key in self.api_keys:
                        if key not in usage:
                            usage[key] = 0
                    return usage
            except (json.JSONDecodeError, IOError) as e:
                logger.error(f"[QnA Cohere] Error loading usage file: {e}")
        
        return {key: 0 for key in self.api_keys}
    
    def _save_usage(self):
        """Save API key usage to file."""
        try:
            with open(self.usage_file, 'w') as f:
                json.dump(self.usage, f, indent=2)
        except IOError as e:
            logger.error(f"[QnA Cohere] Error saving usage file: {e}")
    
    def _find_available_key(self):
        """Find the first key that hasn't reached the limit."""
        for i, key in enumerate(self.api_keys):
            if self.usage.get(key, 0) < self.limit:
                self.current_index = i
                return
        
        # All keys exhausted - reset (new month assumed)
        logger.warning("[QnA Cohere] All API keys exhausted! Resetting usage counts.")
        self.usage = {key: 0 for key in self.api_keys}
        self.current_index = 0
        self._save_usage()
    
    def _rotate_key(self):
        """Rotate to the next available API key."""
        old_index = self.current_index
        
        for _ in range(len(self.api_keys)):
            self.current_index = (self.current_index + 1) % len(self.api_keys)
            current_key = self.api_keys[self.current_index]
            
            if self.usage.get(current_key, 0) < self.limit:
                self.client = cohere.Client(current_key)
                logger.info(f"[QnA Cohere] Rotated from key {old_index} to {self.current_index}")
                self._save_usage()
                return True
        
        logger.warning("[QnA Cohere] All API keys exhausted!")
        return False
    
    def get_current_usage(self):
        """Get usage count for current key."""
        return self.usage.get(self.api_keys[self.current_index], 0)
    
    def get_all_usage(self):
        """Get usage counts for all keys (masked for security)."""
        return {f"key_{i}": count for i, (key, count) in enumerate(self.usage.items())}
    
    def increment_usage(self):
        """Increment usage for current key."""
        with self.lock:
            current_key = self.api_keys[self.current_index]
            self.usage[current_key] = self.usage.get(current_key, 0) + 1
            self._save_usage()
            
            if self.usage[current_key] >= self.limit:
                logger.info(f"[QnA Cohere] Key {self.current_index} reached limit. Rotating...")
                self._rotate_key()
    
    def embed(self, texts):
        """Generate embeddings with automatic key rotation on failure."""
        try:
            response = self.client.embed(texts=texts, model=COHERE_MODEL, input_type="search_query")
            self.increment_usage()
            return response.embeddings
        except Exception as e:
            logger.error(f"[QnA Cohere] Embed error: {e}. Rotating key...")
            
            if self._rotate_key():
                try:
                    response = self.client.embed(texts=texts, model=COHERE_MODEL)
                    self.increment_usage()
                    return response.embeddings
                except Exception as e2:
                    logger.error(f"[QnA Cohere] Embed failed after rotation: {e2}")
                    raise
            else:
                raise Exception("All Cohere API keys exhausted")


# ============================================
# QNA: QDRANT CLIENT
# ============================================

_qdrant_client = None
_cohere_manager = None

def get_qdrant_client():
    """Get or create Qdrant client singleton."""
    global _qdrant_client
    if _qdrant_client is None:
        _qdrant_client = QdrantClient(
            url=QDRANT_URL,
            api_key=QDRANT_API_KEY,
            timeout=30
        )
    return _qdrant_client


def get_cohere_manager():
    """Get or create Cohere key manager singleton."""
    global _cohere_manager
    if _cohere_manager is None:
        _cohere_manager = CohereKeyManager()
    return _cohere_manager


# ============================================
# QNA: LOGGING FUNCTIONS
# ============================================

def qna_log_search(user_id, username, query, results_count):
    """
    Log QnA search to CSV.
    Format: timestamp, user_id, username, query, results_count
    
    Note: User ID tracking is handled by the existing store_interaction() function.
    This only logs the search queries.
    """
    kst = pytz.timezone("Asia/Seoul")
    timestamp = datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S')
    
    try:
        with open(QNA_SEARCH_LOGS_FILE, 'a', encoding='utf-8') as file:
            # Escape query in case it contains commas
            file.write(f'{timestamp},{user_id},{username},"{query}",{results_count}\n')
        logger.info(f"[QnA] Search logged: {user_id} -> '{query}' ({results_count} results)")
    except Exception as e:
        logger.error(f"[QnA] Search log write error: {e}")


# ============================================
# QNA: HELPER FUNCTIONS
# ============================================

def format_qna_question(point):
    """Format a Qdrant point into a question dict for API response."""
    payload = point.payload
    return {
        "id": point.id,
        "topic": payload.get("topic", "📚 Boshqa"),
        "title": payload.get("title", ""),
        "questionBody": payload.get("question_body", ""),
        "answerSource": payload.get("answer_source", ""),
        "answerBody": payload.get("answer_body", ""),
        "link": payload.get("question_link", ""),
        "score": getattr(point, 'score', None)
    }


# ============================================
# QNA: API ENDPOINTS
# ============================================

@app.route('/api/questions/search', methods=['POST', 'OPTIONS'])
@limiter.limit("30 per minute")  # Stricter limit for search (uses Cohere API)
def qna_search():
    """
    Search questions using semantic similarity.
    
    POST /api/questions/search
    Body: { 
        "query": "намоз вақти", 
        "limit": 10,
        "user_id": 123456789,      # Optional - for logging
        "username": "john_doe"      # Optional - for logging
    }
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json()
        
        if not data or 'query' not in data:
            return jsonify({"success": False, "error": "Missing 'query' in request body"}), 400
        
        query = data['query'].strip()
        limit = data.get('limit', 10)
        user_id = data.get('user_id', 'anonymous')
        username = data.get('username', 'unknown')
        
        if len(query) < 3:
            return jsonify({"success": False, "error": "Query must be at least 3 characters"}), 400
        
        if not isinstance(limit, int) or limit < 1 or limit > 50:
            limit = 10
        
        # Detect and convert to Cyrillic if needed
        alphabet = detect_alphabet(query)
        if alphabet == 'latin':
            query_cyrillic = to_cyrillic(query)
            logger.info(f"[QnA Search] Converted: '{query}' -> '{query_cyrillic}'")
        else:
            query_cyrillic = query
        
        # Generate embedding
        cohere_mgr = get_cohere_manager()
        embeddings = cohere_mgr.embed([query_cyrillic])
        query_embedding = embeddings[0]
        
        # Search in Qdrant
        client = get_qdrant_client()
        results = client.query_points(
            collection_name=QNA_COLLECTION_NAME,
            query=query_embedding,
            limit=limit,
            with_payload=True
        )
        
        # Format results
        questions = [format_qna_question(point) for point in results.points]
        
        # Log the search
        qna_log_search(user_id, username, query, len(questions))
        
        logger.info(f"[QnA Search] User {user_id}: '{query}' -> {len(questions)} results")
        
        return jsonify({
            "success": True,
            "query": query,
            "alphabet": alphabet,
            "count": len(questions),
            "questions": questions
        })
    
    except Exception as e:
        logger.error(f"[QnA Search] Error: {e}")
        return jsonify({"success": False, "error": str(e), "questions": []}), 500


@app.route('/api/questions/browse', methods=['GET'])
@limiter.exempt
def qna_browse():
    """
    Get random questions for browse/discovery.
    
    GET /api/questions/browse?limit=15
    """
    try:
        limit = request.args.get('limit', 15, type=int)
        
        if limit < 1 or limit > 30:
            limit = 15
        
        client = get_qdrant_client()
        
        # Use scroll to get random sample
        # Fetch more than needed to ensure we get enough after any filtering
        points, _ = client.scroll(
            collection_name=QNA_COLLECTION_NAME,
            limit=limit * 3,  # Fetch extra
            with_payload=True
        )
        
        # Randomly sample from retrieved points
        if len(points) > limit:
            points = random.sample(points, limit)
        
        random.shuffle(points)
        
        questions = [format_qna_question(point) for point in points]
        
        return jsonify({
            "success": True,
            "count": len(questions),
            "questions": questions
        })
    
    except Exception as e:
        logger.error(f"[QnA Browse] Error: {e}")
        return jsonify({"success": False, "error": str(e), "questions": []}), 500


@app.route('/api/questions/<int:question_id>', methods=['GET'])
@limiter.exempt  # No rate limit (doesn't use Cohere)
def qna_detail(question_id):
    """
    Get full details for a single question including related questions.
    
    GET /api/questions/123
    """
    try:
        if question_id < 1:
            return jsonify({"success": False, "error": "Invalid question ID"}), 400
        
        client = get_qdrant_client()
        
        # Retrieve the question with vector
        points = client.retrieve(
            collection_name=QNA_COLLECTION_NAME,
            ids=[question_id],
            with_payload=True,
            with_vectors=True
        )
        
        if not points:
            return jsonify({"success": False, "error": "Question not found", "question": None}), 404
        
        point = points[0]
        question = format_qna_question(point)
        
        # Find related questions
        related_results = client.query_points(
            collection_name=QNA_COLLECTION_NAME,
            query=point.vector,
            limit=4,
            with_payload=True
        )
        
        # Filter out current question
        related = []
        for p in related_results.points:
            if p.id != question_id:
                related.append({
                    "id": p.id,
                    "title": p.payload.get("title", ""),
                    "topic": p.payload.get("topic", "📚 Boshqa")
                })
            if len(related) >= 3:
                break
        
        return jsonify({
            "success": True,
            "question": question,
            "related": related
        })
    
    except Exception as e:
        logger.error(f"[QnA Detail] Error: {e}")
        return jsonify({"success": False, "error": str(e), "question": None}), 500


@app.route('/api/questions/stats', methods=['GET'])
@limiter.exempt
def qna_stats():
    """
    Get QnA collection and API usage statistics.
    
    GET /api/questions/stats
    """
    try:
        client = get_qdrant_client()
        info = client.get_collection(QNA_COLLECTION_NAME)
        
        cohere_mgr = get_cohere_manager()
        
        return jsonify({
            "success": True,
            "collection": {
                "points_count": info.points_count,
                "status": str(info.status)
            },
            "cohere_api": {
                "current_key_index": cohere_mgr.current_index,
                "current_key_usage": cohere_mgr.get_current_usage(),
                "limit_per_key": COHERE_API_KEY_LIMIT,
                "all_keys_usage": cohere_mgr.get_all_usage()
            }
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/questions/health', methods=['GET'])
@limiter.exempt
def qna_health():
    """
    Health check for QnA service.
    
    GET /api/questions/health
    """
    try:
        client = get_qdrant_client()
        info = client.get_collection(QNA_COLLECTION_NAME)
        
        return jsonify({
            "status": "healthy",
            "qdrant": "connected",
            "questions_count": info.points_count
        })
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "qdrant": "disconnected",
            "error": str(e)
        }), 503


# ============================================================
# PLACES ADMIN ENDPOINTS — Add to places_api_protected.py
# ============================================================

# 1. Add KAKAO_API_KEY near your config section
KAKAO_API_KEY = _secret("KAKAO_REST_KEY", required=False)


# 2. Add route to serve the admin page
@app.route('/admin/places')
def admin_places_page():
    if not session.get('admin_logged_in'):
        return redirect('/admin')
    return send_file('templates/admin_places.html')


# 3. GET — List all places
@app.route('/api/admin/places', methods=['GET'])
def admin_list_places():
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    try:
        conn = get_db_connection()
        rows = conn.execute("""
            SELECT City_Korean, City_English, Building_type, Name, Tel,
                   Actual_address, Latitude, Longitude, KakaoMap_link,
                   NaverMap_Link, Unique_number, Photo_path,
                   telegram_url, tiktok_url, instagram_url, owner_note,
                   (SELECT COUNT(*) FROM reviews
                     WHERE reviews.Unique_number = main_db.Unique_number) AS review_count
            FROM main_db
            ORDER BY Building_type, City_English, Name
        """).fetchall()
        conn.close()
        return jsonify({'success': True, 'places': [dict(r) for r in rows]})
    except Exception as e:
        logger.error(f"Failed to list places: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


# 4. POST — Add a new place
@app.route('/api/admin/places', methods=['POST'])
def admin_add_place():
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    try:
        d = request.get_json()
        conn = get_db_connection()

        # Check if Unique_number already exists
        existing = conn.execute("SELECT 1 FROM main_db WHERE Unique_number = ?", (d['Unique_number'],)).fetchone()
        if existing:
            conn.close()
            return jsonify({'success': False, 'error': 'Unique number already exists'}), 400

        conn.execute("""
            INSERT INTO main_db (City_Korean, City_English, Building_type, Name, Tel,
                                 Actual_address, Latitude, Longitude, KakaoMap_link,
                                 NaverMap_Link, Unique_number, Photo_path,
                                 telegram_url, tiktok_url, instagram_url, owner_note)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (d.get('City_Korean',''), d.get('City_English',''), d.get('Building_type',''),
              d.get('Name',''), d.get('Tel',''), d.get('Actual_address',''),
              d.get('Latitude',0), d.get('Longitude',0), d.get('KakaoMap_link',''),
              d.get('NaverMap_Link',''), d.get('Unique_number',''), d.get('Photo_path',''),
              _blank_to_null(d.get('telegram_url')), _blank_to_null(d.get('tiktok_url')),
              _blank_to_null(d.get('instagram_url')), _blank_to_null(d.get('owner_note'))))
        conn.commit()

        # Send tick in the panel: tell area watchers that a place opened nearby.
        # A failure here is logged and reported, but the place stays saved.
        notified, notify_error = 0, None
        if wants_notify(d.get('notify')):
            try:
                row = conn.execute("SELECT * FROM main_db WHERE Unique_number = ?",
                                   (d['Unique_number'],)).fetchone()
                if row:
                    msgs = prepare_place_event(conn, 'new', place_from_row(row))
                    notified = enqueue_messages(msgs, f"place:{d['Unique_number']}:new")
            except Exception as e:
                notify_error = str(e)
                logger.error(f"[NOTIFY] add place #{d.get('Unique_number')}: {e}")
        conn.close()
        logger.info(f"Admin added place: {d.get('Name')} #{d.get('Unique_number')}")
        return jsonify({'success': True, 'notified': notified, 'notifyError': notify_error})
    except Exception as e:
        logger.error(f"Failed to add place: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


# 5. PUT — Update an existing place
@app.route('/api/admin/places/<int:place_id>', methods=['PUT'])
def admin_update_place(place_id):
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    try:
        d = request.get_json()
        conn = get_db_connection()

        # The whole row, not just "exists": the old name and phone are compared
        # after the save to decide what a Send tick announces.
        existing = conn.execute("SELECT * FROM main_db WHERE Unique_number = ?", (place_id,)).fetchone()
        if not existing:
            conn.close()
            return jsonify({'success': False, 'error': 'Place not found'}), 404

        conn.execute("""
            UPDATE main_db SET
                City_Korean = ?, City_English = ?, Building_type = ?,
                Name = ?, Tel = ?, Actual_address = ?,
                Latitude = ?, Longitude = ?,
                KakaoMap_link = ?, NaverMap_Link = ?, Photo_path = ?,
                telegram_url = ?, tiktok_url = ?, instagram_url = ?, owner_note = ?
            WHERE Unique_number = ?
        """, (d.get('City_Korean',''), d.get('City_English',''), d.get('Building_type',''),
              d.get('Name',''), d.get('Tel',''), d.get('Actual_address',''),
              d.get('Latitude',0), d.get('Longitude',0), d.get('KakaoMap_link',''),
              d.get('NaverMap_Link',''), d.get('Photo_path',''),
              _blank_to_null(d.get('telegram_url')), _blank_to_null(d.get('tiktok_url')),
              _blank_to_null(d.get('instagram_url')), _blank_to_null(d.get('owner_note')),
              place_id))
        conn.commit()

        # Send tick in the panel: only a change of name or phone is announced.
        notified, notify_error = 0, None
        if wants_notify(d.get('notify')):
            try:
                row = conn.execute("SELECT * FROM main_db WHERE Unique_number = ?", (place_id,)).fetchone()
                changes = tracked_changes(existing, row)
                if changes:
                    msgs = prepare_place_event(conn, 'changed', place_from_row(row), changes)
                    notified = enqueue_messages(msgs, f"place:{place_id}:changed")
            except Exception as e:
                notify_error = str(e)
                logger.error(f"[NOTIFY] update place #{place_id}: {e}")
        conn.close()
        logger.info(f"Admin updated place #{place_id}")
        return jsonify({'success': True, 'notified': notified, 'notifyError': notify_error})
    except Exception as e:
        logger.error(f"Failed to update place: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


# 6. DELETE — Remove a place
@app.route('/api/admin/places/<int:place_id>', methods=['DELETE'])
def admin_delete_place(place_id):
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    try:
        conn = get_db_connection()
        conn.isolation_level = None      # explicit BEGIN/COMMIT below
        existing = conn.execute("SELECT * FROM main_db WHERE Unique_number = ?", (place_id,)).fetchone()
        if not existing:
            conn.close()
            return jsonify({'success': False, 'error': 'Place not found'}), 404

        # Send tick in the panel (?notify=1). Who to tell is worked out now,
        # because the cascade below removes the watchers; the messages are only
        # queued once the delete has committed.
        body = request.get_json(silent=True) or {}
        closing_msgs = []
        if wants_notify(request.args.get('notify'), body.get('notify')):
            try:
                closing_msgs = prepare_place_event(conn, 'closed', place_from_row(existing))
            except Exception as e:
                logger.error(f"[NOTIFY] delete place #{place_id}: {e}")

        # Cascade by hand: there is no foreign key, and Unique_number is
        # recycled (the panel assigns max+1, so deleting the highest-numbered
        # place frees that number for the next one). Leaving reviews behind
        # would silently attach a dead place's reviews to a future place.
        conn.execute('BEGIN')
        try:
            reviews_deleted = conn.execute(
                "DELETE FROM reviews WHERE Unique_number = ?", (place_id,)).rowcount
            try:
                subs_deleted = conn.execute(
                    "DELETE FROM place_submissions WHERE place_id = ?", (place_id,)).rowcount
            except sqlite3.OperationalError:
                subs_deleted = 0      # migration not run yet
            # Watches, owner, claims and announcements go with the place:
            # Unique_number is reused, and must not hand them to a new place.
            notify_deleted = delete_place_notify_rows(conn, place_id)
            conn.execute("DELETE FROM main_db WHERE Unique_number = ?", (place_id,))
            conn.execute('COMMIT')
        except Exception:
            conn.execute('ROLLBACK')
            raise
        conn.close()
        notified, notify_error = 0, None
        if closing_msgs:
            try:
                notified = enqueue_messages(closing_msgs, f"place:{place_id}:closed")
            except Exception as e:
                notify_error = str(e)
                logger.error(f"[NOTIFY] delete place #{place_id}: {e}")
        logger.info(f"[ADMIN] Deleted place #{place_id} "
                    f"with {reviews_deleted} review(s), {subs_deleted} submission(s), "
                    f"{sum(notify_deleted.values())} notification row(s)")
        return jsonify({'success': True,
                        'reviews_deleted': reviews_deleted,
                        'submissions_deleted': subs_deleted,
                        'notified': notified,
                        'notifyError': notify_error})
        logger.info(f"Admin deleted place #{place_id}")
        return jsonify({'success': True})
    except Exception as e:
        logger.error(f"Failed to delete place: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


def _blank_to_null(v):
    """
    '' and NULL mean different things here: the detail page treats NULL as
    "nothing registered" and shows the submit prompt, while '' would render an
    empty link. Clearing a field in the panel must therefore store NULL.
    """
    if v is None:
        return None
    v = str(v).strip()
    return v or None


# ============================================
# ADMIN — REVIEWS
# ============================================
#
# `reviews` has no id column, so rows are addressed by SQLite's implicit rowid.
# It is stable for the life of a row, which is all this needs.

@app.route('/api/admin/reviews', methods=['GET'])
def admin_list_reviews():
    """All reviews, or just one place's. Newest first."""
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    try:
        place_id = request.args.get('place_id')
        q = (request.args.get('q') or '').strip()
        try:
            limit = min(int(request.args.get('limit', 200)), 500)
        except (TypeError, ValueError):
            limit = 200

        sql = ("SELECT r.rowid AS id, r.Unique_number, r.User_ID, r.Rating, "
               "       r.Review_Text, r.Timestamp, "
               "       m.Name AS place_name, m.Building_type "
               "FROM reviews r "
               "LEFT JOIN main_db m ON m.Unique_number = r.Unique_number ")
        where, params = [], []
        if place_id:
            where.append("r.Unique_number = ?")
            params.append(place_id)
        if q:
            where.append("(r.Review_Text LIKE ? OR m.Name LIKE ? OR r.User_ID LIKE ?)")
            params += [f'%{q}%', f'%{q}%', f'%{q}%']
        if where:
            sql += "WHERE " + " AND ".join(where) + " "
        sql += "ORDER BY r.Timestamp DESC LIMIT ?"
        params.append(limit)

        conn = get_db_connection()
        rows = [dict(r) for r in conn.execute(sql, params).fetchall()]
        total = conn.execute("SELECT COUNT(*) FROM reviews").fetchone()[0]
        conn.close()
        return jsonify({'success': True, 'reviews': rows, 'total': total})
    except Exception as e:
        logger.error(f"Failed to list reviews: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/admin/reviews/<int:review_id>', methods=['PUT'])
def admin_update_review(review_id):
    """Edit a review's rating and/or text."""
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    try:
        d = request.get_json() or {}
        conn = get_db_connection()

        row = conn.execute(
            "SELECT rowid AS id, Rating, Review_Text FROM reviews WHERE rowid = ?",
            (review_id,)).fetchone()
        if not row:
            conn.close()
            return jsonify({'success': False, 'error': 'Review not found'}), 404

        rating = d.get('Rating', row['Rating'])
        try:
            rating = int(rating)
        except (TypeError, ValueError):
            conn.close()
            return jsonify({'success': False, 'error': 'Rating must be a number'}), 400
        if not (1 <= rating <= 5):
            conn.close()
            return jsonify({'success': False, 'error': 'Rating must be between 1 and 5'}), 400

        text = d.get('Review_Text', row['Review_Text'])
        text = '' if text is None else str(text)

        conn.execute("UPDATE reviews SET Rating = ?, Review_Text = ? WHERE rowid = ?",
                     (rating, text, review_id))
        conn.commit()
        conn.close()
        logger.info(f"[ADMIN] Updated review #{review_id}")
        return jsonify({'success': True})
    except Exception as e:
        logger.error(f"Failed to update review {review_id}: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/admin/reviews/<int:review_id>', methods=['DELETE'])
def admin_delete_review(review_id):
    """Remove a review outright — used for spam and abuse."""
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    try:
        conn = get_db_connection()
        row = conn.execute("SELECT rowid FROM reviews WHERE rowid = ?",
                           (review_id,)).fetchone()
        if not row:
            conn.close()
            return jsonify({'success': False, 'error': 'Review not found'}), 404
        conn.execute("DELETE FROM reviews WHERE rowid = ?", (review_id,))
        conn.commit()
        conn.close()
        logger.info(f"[ADMIN] Deleted review #{review_id}")
        return jsonify({'success': True})
    except Exception as e:
        logger.error(f"Failed to delete review {review_id}: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


# 7. GET — Geocode an address using Kakao API
@app.route('/api/admin/places/geocode', methods=['GET'])
def admin_geocode():
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    address = request.args.get('address', '').strip()
    if not address:
        return jsonify({'success': False, 'error': 'Address required'}), 400
    try:
        resp = requests.get(
            'https://dapi.kakao.com/v2/local/search/address.json',
            headers={'Authorization': f'KakaoAK {KAKAO_API_KEY}'},
            params={'query': address},
            timeout=10
        ).json()
        if resp.get('documents'):
            doc = resp['documents'][0]
            return jsonify({
                'success': True,
                'latitude': doc['y'],
                'longitude': doc['x']
            })
        return jsonify({'success': False, 'error': 'Address not found'})
    except Exception as e:
        logger.error(f"Geocode error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ============================================
# PLACE NOTIFICATIONS  (watch places / areas, bot messages)
# ============================================
app.config["PLACE_NOTIFY_DB"] = DATABASE_PATH
app.config["PLACE_NOTIFY_BOT_TOKEN"] = TELEGRAM_BOT_TOKEN
app.config["PLACE_NOTIFY_KAKAO_KEY"] = KAKAO_API_KEY
# Base URL of the Mini App's places folder on the production frontend. The
# bot's "Open place" and "Stop" buttons open pages under it. An empty value
# sends messages without buttons. The env var, if set, wins.
app.config["PLACE_NOTIFY_WEBAPP_URL"] = os.getenv("PLACE_NOTIFY_WEBAPP_URL",
                                                  "https://vegukin-twa.pages.dev/pages/places/")
app.register_blueprint(place_notifications_bp)
init_place_notifications(app)   # creates the tables, starts the sender; idempotent


# ============================================
# RUN APPLICATION
# ============================================

if __name__ == '__main__':
    # Check database exists
    if not os.path.exists(DATABASE_PATH):
        print(f"⚠️  WARNING: Database not found at {DATABASE_PATH}")
        print("Please update DATABASE_PATH in the script")
    else:
        print(f"✅ Database found at {DATABASE_PATH}")
    
    print("\n" + "="*60)
    print("🕌 Muslim Vegukin Bot API - Generic Places (Protected)")
    print("="*60)
    print("\n📊 Configuration:")
    print(f"  • Rate Limit: 200 requests/hour per IP")
    print(f"  • Max Results: 10 places per query")
    print(f"  • Database: {DATABASE_PATH}")
    print(f"  • Logging: api_usage.log")
    print(f"  • Supported Types: {', '.join(VALID_BUILDING_TYPES)}")
    print("\n🔒 Data Protection:")
    print(f"  • Database file NOT exposed to users")
    print(f"  • Only query results returned")
    print(f"  • Rate limiting prevents mass scraping")
    print(f"  • All requests logged for monitoring")
    print("\n📍 Endpoints:")
    print("  • GET /api/health")
    print("  • GET /api/places/nearby?lat=X&lon=Y&building_type=Masjid&limit=5")
    print("  • GET /api/places/by-address?address=서울시&building_type=Oshxona&limit=5")
    print("  • GET /api/place/<id>")
    print("  • POST /api/review/submit")
    print("  • POST /api/place/<id>/submit   (community submissions)")
    print("  • GET /api/stats")
    print("\n🚀 Starting server...")
    print("="*60 + "\n")
    
    # Run the app
    app.run(debug=False, host='0.0.0.0', port=5001)