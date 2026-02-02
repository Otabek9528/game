"""
Ramadan Calendar Image Generator - Flask API Endpoint
Add this to your Flask app

Endpoint: /api/ramadan/calendar-image
Method: GET
Parameters:
  - lat: latitude (required)
  - lon: longitude (required)  
  - city: city name (required)

Returns: PNG image
"""

from flask import Blueprint, request, send_file, jsonify
from playwright.sync_api import sync_playwright
from datetime import datetime, timedelta
import requests
import io
import os

ramadan_calendar_bp = Blueprint('ramadan_calendar', __name__)

# ===========================================
# CONFIGURATION
# ===========================================

RAMADAN_START = datetime(2026, 2, 18)
RAMADAN_DAYS = 30
ALADHAN_API = 'https://api.aladhan.com/v1/timings'
METHOD = 3  # Muslim World League
SCHOOL = 1  # Hanafi

MONTHS_UZ = {
    1: 'Yan', 2: 'Fev', 3: 'Mar', 4: 'Apr',
    5: 'May', 6: 'Iyn', 7: 'Iyl', 8: 'Avg',
    9: 'Sen', 10: 'Okt', 11: 'Noy', 12: 'Dek'
}

WEEKDAYS_UZ = ['Dush', 'Sesh', 'Chor', 'Pay', 'Juma', 'Shan', 'Yak']

# ===========================================
# HELPER FUNCTIONS
# ===========================================

def fetch_prayer_times(lat, lon):
    """Fetch all 30 days of Ramadan prayer times from Aladhan API"""
    times = []
    
    for i in range(RAMADAN_DAYS):
        date = RAMADAN_START + timedelta(days=i)
        date_str = date.strftime('%d-%m-%Y')
        
        try:
            url = f"{ALADHAN_API}/{date_str}?latitude={lat}&longitude={lon}&method={METHOD}&school={SCHOOL}"
            response = requests.get(url, timeout=10)
            data = response.json()
            
            if data['code'] == 200:
                timings = data['data']['timings']
                times.append({
                    'day': i + 1,
                    'date': date,
                    'date_str': f"{date.day}-{MONTHS_UZ[date.month]}",
                    'weekday': WEEKDAYS_UZ[date.weekday()],
                    'is_friday': date.weekday() == 4,
                    'suhur': timings['Fajr'][:5],
                    'iftar': timings['Maghrib'][:5]
                })
            else:
                times.append(get_placeholder_day(i, date))
        except Exception as e:
            print(f"Error fetching day {i+1}: {e}")
            times.append(get_placeholder_day(i, date))
    
    return times

def get_placeholder_day(i, date):
    """Return placeholder data if API fails"""
    return {
        'day': i + 1,
        'date': date,
        'date_str': f"{date.day}-{MONTHS_UZ[date.month]}",
        'weekday': WEEKDAYS_UZ[date.weekday()],
        'is_friday': date.weekday() == 4,
        'suhur': '--:--',
        'iftar': '--:--'
    }

def generate_html(city_name, prayer_times):
    """Generate the calendar HTML with actual prayer times"""
    
    def generate_table_rows(start_idx, end_idx):
        rows = ""
        for i in range(start_idx, end_idx):
            day = prayer_times[i]
            friday_class = ' class="friday"' if day['is_friday'] else ''
            rows += f'''
          <tr{friday_class}>
            <td>{day['day']}</td>
            <td class="date">{day['date_str']}</td>
            <td class="weekday">{day['weekday']}</td>
            <td class="time-suhur">{day['suhur']}</td>
            <td class="time-iftar">{day['iftar']}</td>
          </tr>'''
        return rows

    html = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Ramadan Calendar</title>
  <link href="https://fonts.googleapis.com/css2?family=Amiri:wght@400;700&family=Rubik:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    * {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }}
    
    body {{
      font-family: 'Rubik', sans-serif;
      background: transparent;
      margin: 0;
      padding: 0;
    }}
    
    .calendar {{
      width: 540px;
      background: linear-gradient(180deg, #0a0a0f 0%, #12100a 30%, #1a1510 50%, #12100a 70%, #0a0a0f 100%);
      border-radius: 16px;
      overflow: hidden;
      position: relative;
      padding: 14px 14px 16px 14px;
    }}
    
    .calendar::before {{
      content: '';
      position: absolute;
      top: 0;
      left: 50%;
      transform: translateX(-50%);
      width: 100%;
      height: 180px;
      background: radial-gradient(ellipse at top center, rgba(244,197,66,0.12) 0%, transparent 70%);
      pointer-events: none;
    }}
    
    .calendar::after {{
      content: '';
      position: absolute;
      top: 8px;
      left: 8px;
      right: 8px;
      bottom: 8px;
      border: 1px solid rgba(244,197,66,0.15);
      border-radius: 12px;
      pointer-events: none;
    }}
    
    .lanterns {{
      position: absolute;
      top: 12px;
      left: 0;
      right: 0;
      display: flex;
      justify-content: space-between;
      padding: 0 16px;
      font-size: 28px;
      z-index: 2;
      filter: drop-shadow(0 0 8px rgba(244,197,66,0.5));
    }}
    
    .header {{
      text-align: center;
      position: relative;
      z-index: 1;
      padding-top: 12px;
      margin-bottom: 16px;
    }}
    
    .arabic {{
      font-family: 'Amiri', serif;
      font-size: 32px;
      color: #f4c542;
      text-shadow: 0 0 20px rgba(244,197,66,0.4);
      margin-bottom: 2px;
    }}
    
    .title {{
      font-size: 18px;
      font-weight: 700;
      color: #fff;
      letter-spacing: 2px;
      text-transform: uppercase;
    }}
    
    .subtitle {{
      font-size: 11px;
      color: #f4c542;
      margin-top: 2px;
      letter-spacing: 0.5px;
    }}
    
    .subtitle .by-bot {{
      color: #94a3b8;
      font-size: 10px;
      margin-left: 4px;
    }}
    
    .subtitle .bot-name {{
      color: #10b981;
      font-weight: 500;
    }}
    
    .city {{
      display: inline-flex;
      align-items: center;
      gap: 4px;
      margin-top: 8px;
      padding: 4px 12px;
      background: rgba(244,197,66,0.1);
      border: 1px solid rgba(244,197,66,0.2);
      border-radius: 16px;
      font-size: 12px;
      color: #f4c542;
    }}
    
    .ashara-section {{
      position: relative;
      z-index: 1;
      margin-bottom: 12px;
    }}
    
    .ashara-section:last-of-type {{
      margin-bottom: 0;
    }}
    
    .ashara-title {{
      text-align: center;
      font-size: 13px;
      font-weight: 600;
      color: #f4c542;
      margin-bottom: 8px;
      padding: 6px 16px;
      background: linear-gradient(90deg, transparent, rgba(244,197,66,0.2), transparent);
    }}
    
    .days-table {{
      width: 100%;
      border-collapse: collapse;
      font-size: 11px;
      background: rgba(0,0,0,0.3);
      border-radius: 10px;
      overflow: hidden;
      border: 1px solid rgba(244,197,66,0.1);
    }}
    
    .days-table thead th {{
      background: linear-gradient(180deg, rgba(244,197,66,0.2), rgba(244,197,66,0.1));
      padding: 8px 4px;
      text-align: center;
      font-weight: 600;
      font-size: 9px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: #f4c542;
      border-bottom: 1px solid rgba(244,197,66,0.2);
    }}
    
    .days-table tbody tr {{
      border-bottom: 1px solid rgba(255,255,255,0.04);
    }}
    
    .days-table tbody tr:nth-child(odd) {{
      background: rgba(255,255,255,0.02);
    }}
    
    .days-table tbody tr:nth-child(even) {{
      background: rgba(0,0,0,0.1);
    }}
    
    .days-table tbody tr:last-child {{
      border-bottom: none;
    }}
    
    .days-table tbody tr.friday {{
      background: linear-gradient(90deg, rgba(244,197,66,0.15), rgba(245,158,11,0.1), rgba(244,197,66,0.15));
      border-left: 3px solid #f4c542;
    }}
    
    .days-table tbody tr.friday td {{
      color: #fff;
    }}
    
    .days-table tbody tr.friday td:first-child {{
      color: #f4c542;
    }}
    
    .days-table tbody tr.friday .weekday {{
      color: #f4c542;
      font-weight: 600;
    }}
    
    .days-table tbody td {{
      padding: 7px 4px;
      text-align: center;
      color: #cbd5e1;
    }}
    
    .days-table tbody td:first-child {{
      font-weight: 700;
      color: #f4c542;
      font-size: 12px;
    }}
    
    .days-table .date {{
      color: #94a3b8;
      font-size: 10px;
    }}
    
    .days-table .weekday {{
      color: #64748b;
      font-size: 10px;
    }}
    
    .days-table .time-suhur {{
      color: #a5b4fc;
      font-weight: 600;
      font-size: 11px;
    }}
    
    .days-table .time-iftar {{
      color: #fcd34d;
      font-weight: 600;
      font-size: 11px;
    }}
    
    .stars {{
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      pointer-events: none;
      overflow: hidden;
    }}
    
    .star {{
      position: absolute;
      color: #f4c542;
      font-size: 8px;
      opacity: 0.3;
    }}
    
    .star:nth-child(1) {{ top: 15%; left: 5%; }}
    .star:nth-child(2) {{ top: 8%; left: 20%; }}
    .star:nth-child(3) {{ top: 12%; right: 15%; }}
    .star:nth-child(4) {{ top: 20%; right: 8%; }}
    .star:nth-child(5) {{ top: 25%; left: 10%; }}
    .star:nth-child(6) {{ top: 5%; left: 40%; }}
  </style>
</head>
<body>
  <div class="calendar">
    <div class="stars">
      <span class="star">✦</span>
      <span class="star">✧</span>
      <span class="star">✦</span>
      <span class="star">✧</span>
      <span class="star">✦</span>
      <span class="star">✧</span>
    </div>
    
    <div class="lanterns">
      <span>🏮</span>
      <span>🏮</span>
    </div>
    
    <div class="header">
      <div class="arabic">رمضان مبارك</div>
      <div class="title">Ramazon Taqvimi</div>
      <div class="subtitle">1447 Hijriy / 2026 Milodiy <span class="by-bot">by <span class="bot-name">@muslim_vegukin_bot</span></span></div>
      <div class="city">📍 {city_name}</div>
    </div>
    
    <div class="ashara-section">
      <div class="ashara-title">═══ 1-O'N KUNLIK • Rahmat kunlari═══</div>
      <table class="days-table">
        <thead>
          <tr>
            <th>Kun</th>
            <th>Sana</th>
            <th>Hafta</th>
            <th>Saharlik</th>
            <th>Iftorlik</th>
          </tr>
        </thead>
        <tbody>
          {generate_table_rows(0, 10)}
        </tbody>
      </table>
    </div>
    
    <div class="ashara-section">
      <div class="ashara-title">═══ 2-O'N KUNLIK • Mag'firat kunlari═══</div>
      <table class="days-table">
        <thead>
          <tr>
            <th>Kun</th>
            <th>Sana</th>
            <th>Hafta</th>
            <th>Saharlik</th>
            <th>Iftorlik</th>
          </tr>
        </thead>
        <tbody>
          {generate_table_rows(10, 20)}
        </tbody>
      </table>
    </div>
    
    <div class="ashara-section">
      <div class="ashara-title">═══ 3-O'N KUNLIK • Najot kunlari═══</div>
      <table class="days-table">
        <thead>
          <tr>
            <th>Kun</th>
            <th>Sana</th>
            <th>Hafta</th>
            <th>Saharlik</th>
            <th>Iftorlik</th>
          </tr>
        </thead>
        <tbody>
          {generate_table_rows(20, 30)}
        </tbody>
      </table>
    </div>
  </div>
</body>
</html>'''
    
    return html

def render_html_to_image(html_content):
    """Use Playwright to render HTML and capture as PNG"""
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={'width': 600, 'height': 1200})
        
        page.set_content(html_content)
        page.wait_for_timeout(1500)  # Wait for fonts to load
        
        calendar = page.query_selector('.calendar')
        image_bytes = calendar.screenshot(type='png')
        
        browser.close()
        
        return image_bytes

# ===========================================
# API ENDPOINT
# ===========================================

@ramadan_calendar_bp.route('/api/ramadan/calendar-image', methods=['GET'])
def generate_calendar_image():
    """Generate Ramadan calendar image"""
    
    # Get parameters
    lat = request.args.get('lat')
    lon = request.args.get('lon')
    city = request.args.get('city', 'Unknown')
    
    if not lat or not lon:
        return jsonify({'error': 'lat and lon parameters are required'}), 400
    
    try:
        lat = float(lat)
        lon = float(lon)
    except ValueError:
        return jsonify({'error': 'Invalid lat/lon values'}), 400
    
    try:
        # Fetch prayer times
        prayer_times = fetch_prayer_times(lat, lon)
        
        # Generate HTML
        html_content = generate_html(city, prayer_times)
        
        # Render to image
        image_bytes = render_html_to_image(html_content)
        
        # Return image
        return send_file(
            io.BytesIO(image_bytes),
            mimetype='image/png',
            as_attachment=True,
            download_name=f'ramadan_2026_{city.replace(" ", "_")}.png'
        )
    
    except Exception as e:
        print("FULL ERROR:", repr(e))
        return jsonify({
            "error": "Failed to generate calendar image",
            "details": str(e)
        }), 500



# ===========================================
# USAGE IN YOUR MAIN FLASK APP
# ===========================================
# 
# from ramadan_calendar_api import ramadan_calendar_bp
# app.register_blueprint(ramadan_calendar_bp)
#
# Don't forget to install playwright:
# pip install playwright
# playwright install chromium
# ===========================================
