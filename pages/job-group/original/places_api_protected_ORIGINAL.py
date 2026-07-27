"""
Muslim Vegukin Bot - Generic Places API (Protected)
====================================================
Flask API with rate limiting - handles Mosques, Restaurants, Shops, and QnA

Database: 350+ places (mosques, restaurants, shops)
QnA: 75,000+ questions via Qdrant Cloud
Expected usage: 1000 daily users
Rate limit: 200 requests/hour per IP (prevents scraping)
"""

from flask import Flask, request, jsonify
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

# Cohere and Qdrant imports for QnA
import cohere
from qdrant_client import QdrantClient

from subscription_manager import SubscriptionManager


#from ramadan_calendar_api import ramadan_calendar_bp

app = Flask(__name__)
CORS(app)  # Enable CORS for web app access


# ============================================
# RATE LIMITING - PROTECTS YOUR DATA
# ============================================

limiter = Limiter(
    app=app,
    key_func=get_remote_address,  # Track by IP address
    default_limits=["200 per hour"],  # 200 requests per hour per IP
    storage_uri="memory://"  # Use memory storage (simple for free tier)
)


@app.after_request
def after_request(response):
    """Add CORS headers to all responses"""
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
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
 
# Job Group Invite Configuration
JOB_GROUP_ID = -1002553359624
TAXI_GROUP_ID = -1003094050555
TELEGRAM_BOT_TOKEN = "6929337047:AAETIZya-NkjnLDw3z4ZsXaRoKUSgKthkSY" 


sub_manager = SubscriptionManager(
    db_path='data/subscriptions.sqlite',
    bot_token=TELEGRAM_BOT_TOKEN,
    job_group_id=JOB_GROUP_ID,
    taxi_group_id=TAXI_GROUP_ID
)
sub_manager.start_scheduler()

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
    1. Appends log immediately (fast - no file reading)
    2. Checks/stores user ID in background thread (doesn't block response)
    """
    log_file_path = 'data/interaction_logs.csv'
    
    # Set the interaction time if not provided
    if interaction_time is None:
        kst = pytz.timezone("Asia/Seoul")
        interaction_time = datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S')
    
    # FAST: Append log immediately (no reading required)
    try:
        with open(log_file_path, 'a', encoding='utf-8') as file:
            file.write(f'{interaction_time},{user_id},{username},{action}\n')
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


@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return response


@app.route('/api/log-interaction', methods=['POST', 'OPTIONS'])
@limiter.limit("20000 per hour")  # Override default 200/hour
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
@limiter.limit("200 per hour")
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
                (SELECT COUNT(*) FROM reviews WHERE reviews.Unique_number = main_db.Unique_number) AS review_count,
                (SELECT AVG(Rating) FROM reviews WHERE reviews.Unique_number = main_db.Unique_number) AS avg_rating
            FROM main_db
            WHERE Building_type = ?
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
@limiter.limit("200 per hour")
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
            kakao_url = f"https://dapi.kakao.com/v2/local/search/address.json?query={address}"
            kakao_headers = {
                "Authorization": "KakaoAK 7ed921d91204c7cf4b1adb5c6bc1e038"
            }
            
            kakao_response = requests.get(kakao_url, headers=kakao_headers, timeout=5)
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
                (SELECT COUNT(*) FROM reviews WHERE reviews.Unique_number = main_db.Unique_number) AS review_count,
                (SELECT AVG(Rating) FROM reviews WHERE reviews.Unique_number = main_db.Unique_number) AS avg_rating
            FROM main_db
            WHERE Building_type = ?
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
@limiter.limit("200 per hour")
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
                view_count
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
        conn.close()
        
        # Format reviews
        reviews = []
        for review in reviews_data:
            reviews.append({
                'rating': review['Rating'],
                'text': review['Review_Text'],
                'timestamp': review['Timestamp'],
                'userId': review['User_ID']
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
@limiter.limit("200 per hour")
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

@app.route('/api/review/submit', methods=['POST'])
@limiter.limit("10 per hour")  # Stricter limit for review submissions
def submit_review():
    """
    Submit a review for a place
    
    JSON Body:
    - place_id: ID of the place (required)
    - user_id: Telegram user ID (required)
    - rating: Rating 1-5 (required)
    - review_text: Review text (optional)
    - timestamp: ISO timestamp (required)
    
    Rate Limited: 10 submissions per hour per IP
    """
    ip = get_remote_address()
    logger.info(f"POST /api/review/submit from IP: {ip}")
    
    try:
        data = request.get_json()
        
        # Validate required fields
        place_id = data.get('mosque_id') or data.get('place_id')  # Support both for compatibility
        user_id = data.get('user_id')
        rating = data.get('rating')
        review_text = data.get('review_text', '')
        timestamp = data.get('timestamp')
        
        if not all([place_id, user_id, rating, timestamp]):
            return jsonify({
                'success': False,
                'error': 'Missing required fields'
            }), 400
        
        # Validate rating
        if not (1 <= rating <= 5):
            return jsonify({
                'success': False,
                'error': 'Rating must be between 1 and 5'
            }), 400
        
        # Insert review into database
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO reviews (Unique_number, User_ID, Rating, Review_Text, Timestamp)
            VALUES (?, ?, ?, ?, ?)
        """, (place_id, user_id, rating, review_text, timestamp))
        
        conn.commit()
        conn.close()
        
        logger.info(f"Review submitted for place {place_id} by user {user_id} (rating: {rating})")
        
        return jsonify({
            'success': True,
            'message': 'Review submitted successfully'
        })
        
    except Exception as e:
        logger.error(f"Error submitting review: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to submit review'
        }), 500

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
@limiter.limit("200 per hour")
def get_parcel_dates():
    """
    Get list of available parcel dates with post counts
    Only returns dates from today (Korea time) onwards
    """
    ip = get_remote_address()
    logger.info(f"GET /api/parcels/dates from IP: {ip}")
    
    try:
        conn = get_parcels_db_connection()
        cursor = conn.cursor()
        
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
@limiter.limit("200 per hour")
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
        
        cursor.execute("""
            SELECT telegram_id, username, message_text, flight_time, uzb_cities, kor_cities
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
                'kor_cities': row['kor_cities']
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
@limiter.limit("200 per hour")
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
    
    try:
        conn = get_parcels_db_connection()
        cursor = conn.cursor()
        
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
@limiter.limit("200 per hour")
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
    
    try:
        conn = get_parcels_db_connection()
        cursor = conn.cursor()
        
        cursor.execute(f"""
            SELECT telegram_id, username, message_text, flight_time, flight_time_formatted, uzb_cities, kor_cities
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
                'kor_cities': row['kor_cities']
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


@app.route('/api/interaction-logs', methods=['GET'])
@limiter.exempt  # Exempt from rate limiting since it's admin-only
def get_interaction_logs():
    """
    Return interaction logs as CSV
    Admin endpoint - should be called sparingly
    """
    try:
        log_file_path = '/home/ubuntu/vegukin_api/data/interaction_logs.csv'
        
        with open(log_file_path, 'r', encoding='utf-8') as f:
            csv_content = f.read()
        
        return csv_content, 200, {'Content-Type': 'text/csv'}
        
    except FileNotFoundError:
        return jsonify({'error': 'Log file not found'}), 404
    except Exception as e:
        logger.error(f"Error reading logs: {e}")
        return jsonify({'error': str(e)}), 500



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
@limiter.limit("10 per hour")  # Strict limit to prevent abuse
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

        # Schedule revocation after 10 seconds
        revoke_invite_link_after_delay(invite_link, delay=10)

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
QDRANT_URL = "https://5985899f-60ff-4657-844f-f9052bcf5d46.eu-west-2-0.aws.cloud.qdrant.io"
QDRANT_API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2Nlc3MiOiJtIn0.aYxqZA6Y-OG2iGcyOe8NvaJF1WyzZxK8UqhvgqzNDnM"  # Paste your full Qdrant API key
QNA_COLLECTION_NAME = "islamic_qna"

# Cohere API configuration
COHERE_API_KEYS = [
    "ZQEpb8IZ9gIUjUnlklSES8T0euW9LIzRuJRJxQPS",
    "di2dA6wQxxpF16zMenQZlVUghh52zkQWFYGwgedt",
    "po3Qr9b0CDnJ2e1uyOzeDmopfmqNKtt9UL04oLmh",
    "fgaLYghOXrfQsKhPxmFBLi7qmsudxVnYUxut3ovL",
]
COHERE_MODEL = "multilingual-22-12"
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
            response = self.client.embed(texts=texts, model=COHERE_MODEL)
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
    print("  • GET /api/stats")
    print("\n🚀 Starting server...")
    print("="*60 + "\n")
    
    # Run the app
    app.run(debug=False, host='0.0.0.0', port=5001)