"""
qna_routes.py

Flask API routes for Islamic Q&A WebApp.
Location: pages/qna/qna_routes.py

Usage in your main Flask app:
    
    import sys
    sys.path.insert(0, 'pages/qna')  # Add qna folder to path
    from qna_routes import qna_bp
    
    app.register_blueprint(qna_bp, url_prefix='/api')
    
Or if serving from a different structure, adjust the import accordingly.
"""

from flask import Blueprint, request, jsonify

# Import from same folder
from qna_qdrant import (
    search_questions,
    get_browse_questions,
    get_question_detail,
    get_collection_stats
)

# Create Blueprint
qna_bp = Blueprint('qna', __name__)


# ===========================================
# API ENDPOINTS
# ===========================================

@qna_bp.route('/questions/search', methods=['POST'])
def api_search_questions():
    """
    Search questions using semantic similarity.
    
    POST /api/questions/search
    Body: { "query": "намоз вақти", "limit": 10 }
    
    Response: {
        "success": true,
        "query": "намоз вақти",
        "alphabet": "cyrillic",
        "count": 10,
        "questions": [
            {
                "id": 123,
                "topic": "🕌 Namoz",
                "title": "...",
                "questionBody": "...",
                "answerSource": "...",
                "answerBody": "...",
                "link": "https://savollar.islom.uz/...",
                "score": 0.95
            },
            ...
        ]
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'query' not in data:
            return jsonify({
                "success": False,
                "error": "Missing 'query' in request body"
            }), 400
        
        query = data['query'].strip()
        limit = data.get('limit', 10)
        
        # Validate query
        if len(query) < 3:
            return jsonify({
                "success": False,
                "error": "Query must be at least 3 characters"
            }), 400
        
        # Validate limit
        if not isinstance(limit, int) or limit < 1 or limit > 50:
            limit = 10
        
        # Perform search
        result = search_questions(query, limit=limit)
        
        return jsonify(result)
    
    except Exception as e:
        print(f"[API Search Error] {e}")
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500


@qna_bp.route('/questions/browse', methods=['GET'])
def api_browse_questions():
    """
    Get random questions for browse/discovery.
    
    GET /api/questions/browse?limit=15
    
    Response: {
        "success": true,
        "count": 15,
        "questions": [...]
    }
    """
    try:
        limit = request.args.get('limit', 15, type=int)
        
        # Validate limit
        if limit < 1 or limit > 30:
            limit = 15
        
        result = get_browse_questions(limit=limit)
        
        return jsonify(result)
    
    except Exception as e:
        print(f"[API Browse Error] {e}")
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500


@qna_bp.route('/questions/<int:question_id>', methods=['GET'])
def api_question_detail(question_id: int):
    """
    Get full details for a single question including related questions.
    
    GET /api/questions/123
    
    Response: {
        "success": true,
        "question": {
            "id": 123,
            "topic": "🕌 Namoz",
            "title": "...",
            "questionBody": "...",
            "answerSource": "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
            "answerBody": "...",
            "link": "https://savollar.islom.uz/..."
        },
        "related": [
            {"id": 456, "title": "...", "topic": "🕌 Namoz"},
            {"id": 789, "title": "...", "topic": "🕌 Namoz"},
            {"id": 101, "title": "...", "topic": "🕌 Namoz"}
        ]
    }
    """
    try:
        if question_id < 1:
            return jsonify({
                "success": False,
                "error": "Invalid question ID"
            }), 400
        
        result = get_question_detail(question_id)
        
        if not result["success"]:
            return jsonify(result), 404
        
        return jsonify(result)
    
    except Exception as e:
        print(f"[API Detail Error] {e}")
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500


@qna_bp.route('/questions/stats', methods=['GET'])
def api_collection_stats():
    """
    Get collection statistics.
    
    GET /api/questions/stats
    
    Response: {
        "success": true,
        "points_count": 75605,
        "status": "green"
    }
    """
    try:
        result = get_collection_stats()
        return jsonify(result)
    
    except Exception as e:
        print(f"[API Stats Error] {e}")
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500


@qna_bp.route('/questions/health', methods=['GET'])
def api_health_check():
    """
    Health check endpoint for monitoring.
    
    GET /api/questions/health
    
    Response: {
        "status": "healthy",
        "qdrant": "connected",
        "questions_count": 75605
    }
    """
    stats = get_collection_stats()
    
    if stats["success"]:
        return jsonify({
            "status": "healthy",
            "qdrant": "connected",
            "questions_count": stats["points_count"]
        })
    else:
        return jsonify({
            "status": "unhealthy",
            "qdrant": "disconnected",
            "error": stats.get("error", "Unknown error")
        }), 503
