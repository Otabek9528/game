"""
qna_qdrant.py

Lightweight Qdrant client for Islamic Q&A WebApp.
Location: pages/qna/qna_qdrant.py

This module handles all communication with Qdrant Cloud.
Includes Cohere API key rotation with usage tracking.

No heavy files loaded - just API calls!
Memory usage: ~5-10 MB
"""

import cohere
import random
import json
import os
from qdrant_client import QdrantClient
from typing import List, Dict, Optional

# Import transliterate from same folder
from transliterate import to_cyrillic

# ===========================================
# CONFIGURATION
# ===========================================

# Qdrant Cloud credentials
QDRANT_URL = "https://5985899f-60ff-4657-844f-f9052bcf5d46.eu-west-2-0.aws.cloud.qdrant.io"
QDRANT_API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2Nlc3MiOiJtIn0.aYxqZA6Y-OG2iGcyOe8NvaJF1WyzZxK8UqhvgqzNDnM"  # Paste your full Qdrant API key

COLLECTION_NAME = "islamic_qna"

# Cohere API configuration
COHERE_API_KEYS = [
    "ZQEpb8IZ9gIUjUnlklSES8T0euW9LIzRuJRJxQPS",
    "di2dA6wQxxpF16zMenQZlVUghh52zkQWFYGwgedt",
    "po3Qr9b0CDnJ2e1uyOzeDmopfmqNKtt9UL04oLmh",
    "fgaLYghOXrfQsKhPxmFBLi7qmsudxVnYUxut3ovL",
]
COHERE_MODEL = "multilingual-22-12"
COHERE_API_KEY_LIMIT = 1000  # Max queries per key per month

# File to track API key usage (in same folder)
# Get the directory where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
API_KEY_USAGE_FILE = os.path.join(SCRIPT_DIR, "api_key_usage.json")


# ===========================================
# API KEY USAGE TRACKING
# ===========================================

class CohereKeyManager:
    """Manages Cohere API keys with usage tracking and rotation."""
    
    def __init__(self):
        self.api_keys = COHERE_API_KEYS
        self.limit = COHERE_API_KEY_LIMIT
        self.usage_file = API_KEY_USAGE_FILE
        self.current_index = 0
        
        # Load or initialize usage tracking
        self.usage = self._load_usage()
        
        # Find first available key (under limit)
        self._find_available_key()
        
        # Initialize Cohere client
        self.client = cohere.Client(self.api_keys[self.current_index])
        
        print(f"[Cohere] Initialized with key index {self.current_index}")
        print(f"[Cohere] Current usage: {self.usage}")
    
    def _load_usage(self) -> Dict[str, int]:
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
                print(f"[Cohere] Error loading usage file: {e}")
        
        # Initialize fresh usage tracking
        return {key: 0 for key in self.api_keys}
    
    def _save_usage(self):
        """Save API key usage to file."""
        try:
            os.makedirs(os.path.dirname(self.usage_file) if os.path.dirname(self.usage_file) else '.', exist_ok=True)
            with open(self.usage_file, 'w') as f:
                json.dump(self.usage, f, indent=2)
            print(f"[Cohere] Usage saved: key_index={self.current_index}, count={self.get_current_usage()}")
        except IOError as e:
            print(f"[Cohere] Error saving usage file: {e}")
    
    def _find_available_key(self):
        """Find the first key that hasn't reached the limit."""
        for i, key in enumerate(self.api_keys):
            if self.usage.get(key, 0) < self.limit:
                self.current_index = i
                return
        
        # All keys exhausted - reset and start over (new month assumed)
        print("[Cohere] WARNING: All API keys exhausted! Resetting usage counts.")
        self.usage = {key: 0 for key in self.api_keys}
        self.current_index = 0
        self._save_usage()
    
    def _rotate_key(self):
        """Rotate to the next available API key."""
        old_index = self.current_index
        
        # Try each key
        for _ in range(len(self.api_keys)):
            self.current_index = (self.current_index + 1) % len(self.api_keys)
            current_key = self.api_keys[self.current_index]
            
            if self.usage.get(current_key, 0) < self.limit:
                self.client = cohere.Client(current_key)
                print(f"[Cohere] Rotated from key {old_index} to {self.current_index}")
                self._save_usage()
                return True
        
        # All keys exhausted
        print("[Cohere] WARNING: All API keys exhausted!")
        return False
    
    def get_current_usage(self) -> int:
        """Get usage count for current key."""
        return self.usage.get(self.api_keys[self.current_index], 0)
    
    def get_all_usage(self) -> Dict[str, int]:
        """Get usage counts for all keys (masked for security)."""
        return {
            f"key_{i}": count 
            for i, (key, count) in enumerate(self.usage.items())
        }
    
    def increment_usage(self):
        """Increment usage for current key and check if rotation needed."""
        current_key = self.api_keys[self.current_index]
        self.usage[current_key] = self.usage.get(current_key, 0) + 1
        self._save_usage()
        
        # Check if we need to rotate
        if self.usage[current_key] >= self.limit:
            print(f"[Cohere] Key {self.current_index} reached limit ({self.limit}). Rotating...")
            self._rotate_key()
    
    def embed(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings with automatic key rotation on failure."""
        try:
            response = self.client.embed(texts=texts, model=COHERE_MODEL)
            self.increment_usage()
            return response.embeddings
        except Exception as e:
            print(f"[Cohere] Embed error: {e}. Trying to rotate key...")
            
            # Try rotating and retry once
            if self._rotate_key():
                try:
                    response = self.client.embed(texts=texts, model=COHERE_MODEL)
                    self.increment_usage()
                    return response.embeddings
                except Exception as e2:
                    print(f"[Cohere] Embed failed after rotation: {e2}")
                    raise
            else:
                raise Exception("All Cohere API keys exhausted")


# ===========================================
# CLIENT INITIALIZATION (Singletons)
# ===========================================

_qdrant_client = None
_cohere_manager = None

def get_qdrant_client() -> QdrantClient:
    """Get or create Qdrant client singleton."""
    global _qdrant_client
    if _qdrant_client is None:
        _qdrant_client = QdrantClient(
            url=QDRANT_URL,
            api_key=QDRANT_API_KEY,
            timeout=30
        )
    return _qdrant_client


def get_cohere_manager() -> CohereKeyManager:
    """Get or create Cohere key manager singleton."""
    global _cohere_manager
    if _cohere_manager is None:
        _cohere_manager = CohereKeyManager()
    return _cohere_manager


# ===========================================
# HELPER FUNCTIONS
# ===========================================

def detect_alphabet(text: str) -> str:
    """Detect if text is Cyrillic or Latin."""
    cyrillic_pattern = any('\u0400' <= char <= '\u04FF' for char in text)
    return 'cyrillic' if cyrillic_pattern else 'latin'


def format_question(point) -> Dict:
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


# ===========================================
# SEARCH FUNCTION
# ===========================================

def search_questions(query: str, limit: int = 10) -> Dict:
    """
    Search questions using semantic similarity.
    
    Args:
        query: User's question (Latin or Cyrillic)
        limit: Number of results to return (default 10)
    
    Returns:
        Dict with success status and questions list
    """
    try:
        # Detect and convert to Cyrillic if needed
        alphabet = detect_alphabet(query)
        if alphabet == 'latin':
            query_cyrillic = to_cyrillic(query)
            print(f"[QnA Search] Converted: '{query}' -> '{query_cyrillic}'")
        else:
            query_cyrillic = query
        
        # Generate embedding for query using Cohere (with key management)
        cohere_mgr = get_cohere_manager()
        embeddings = cohere_mgr.embed([query_cyrillic])
        query_embedding = embeddings[0]
        
        # Search in Qdrant
        client = get_qdrant_client()
        results = client.query_points(
            collection_name=COLLECTION_NAME,
            query=query_embedding,
            limit=limit,
            with_payload=True
        )
        
        # Format results
        questions = [format_question(point) for point in results.points]
        
        return {
            "success": True,
            "query": query,
            "alphabet": alphabet,
            "count": len(questions),
            "questions": questions
        }
    
    except Exception as e:
        print(f"[QnA Search] Error: {e}")
        return {
            "success": False,
            "error": str(e),
            "questions": []
        }


# ===========================================
# BROWSE FUNCTION (Random Questions)
# ===========================================

def get_browse_questions(limit: int = 15) -> Dict:
    """
    Get random questions for browse/discovery view.
    Does NOT use Cohere API (no embedding needed).
    
    Args:
        limit: Number of questions to return (default 15)
    
    Returns:
        Dict with success status and questions list
    """
    try:
        client = get_qdrant_client()
        
        # Get collection info to know total count
        collection_info = client.get_collection(COLLECTION_NAME)
        total_points = collection_info.points_count
        
        # Generate random IDs
        random_ids = random.sample(range(1, total_points + 1), min(limit, total_points))
        
        # Retrieve points by IDs
        points = client.retrieve(
            collection_name=COLLECTION_NAME,
            ids=random_ids,
            with_payload=True
        )
        
        # Format results
        questions = [format_question(point) for point in points]
        
        # Shuffle for variety
        random.shuffle(questions)
        
        return {
            "success": True,
            "count": len(questions),
            "questions": questions
        }
    
    except Exception as e:
        print(f"[QnA Browse] Error: {e}")
        return {
            "success": False,
            "error": str(e),
            "questions": []
        }


# ===========================================
# SINGLE QUESTION DETAIL
# ===========================================

def get_question_detail(question_id: int) -> Dict:
    """
    Get full details for a single question.
    Does NOT use Cohere API (uses stored vector for related questions).
    
    Args:
        question_id: The question number/ID
    
    Returns:
        Dict with question details and related questions
    """
    try:
        client = get_qdrant_client()
        
        # Retrieve the specific question
        points = client.retrieve(
            collection_name=COLLECTION_NAME,
            ids=[question_id],
            with_payload=True,
            with_vectors=True  # Need vector for finding related
        )
        
        if not points:
            return {
                "success": False,
                "error": "Question not found",
                "question": None
            }
        
        point = points[0]
        question = format_question(point)
        
        # Find related questions (similar vectors)
        related_results = client.query_points(
            collection_name=COLLECTION_NAME,
            query=point.vector,
            limit=4,  # Get 4 because first one will be the same question
            with_payload=True
        )
        
        # Filter out the current question and take top 3
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
        
        return {
            "success": True,
            "question": question,
            "related": related
        }
    
    except Exception as e:
        print(f"[QnA Detail] Error: {e}")
        return {
            "success": False,
            "error": str(e),
            "question": None
        }


# ===========================================
# UTILITY FUNCTIONS
# ===========================================

def get_collection_stats() -> Dict:
    """Get collection statistics."""
    try:
        client = get_qdrant_client()
        info = client.get_collection(COLLECTION_NAME)
        return {
            "success": True,
            "points_count": info.points_count,
            "status": str(info.status)
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


def get_api_usage_stats() -> Dict:
    """Get Cohere API key usage statistics."""
    try:
        cohere_mgr = get_cohere_manager()
        return {
            "success": True,
            "current_key_index": cohere_mgr.current_index,
            "current_key_usage": cohere_mgr.get_current_usage(),
            "limit_per_key": COHERE_API_KEY_LIMIT,
            "all_keys_usage": cohere_mgr.get_all_usage()
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


# ===========================================
# TEST (run directly to test)
# ===========================================

if __name__ == "__main__":
    print("=" * 60)
    print("Testing QnA Qdrant Module (with API Key Tracking)")
    print("=" * 60)
    print()
    
    # Test API usage stats
    print("1. Cohere API Usage Stats:")
    api_stats = get_api_usage_stats()
    print(f"   Current key index: {api_stats.get('current_key_index')}")
    print(f"   Current key usage: {api_stats.get('current_key_usage')}/{api_stats.get('limit_per_key')}")
    print(f"   All keys: {api_stats.get('all_keys_usage')}")
    print()
    
    # Test collection stats
    print("2. Qdrant Collection Stats:")
    stats = get_collection_stats()
    print(f"   {stats}")
    print()
    
    # Test browse (doesn't use Cohere)
    print("3. Browse (3 random questions) - NO Cohere API used:")
    browse = get_browse_questions(limit=3)
    if browse["success"]:
        for q in browse["questions"]:
            print(f"   - [{q['topic']}] {q['title'][:50]}...")
    else:
        print(f"   Error: {browse.get('error')}")
    print()
    
    # Test search (uses Cohere - will increment usage)
    print("4. Search for 'намоз вақти' - USES Cohere API:")
    search = search_questions("намоз вақти", limit=3)
    if search["success"]:
        for q in search["questions"]:
            print(f"   - [{q['score']:.4f}] {q['title'][:50]}...")
    else:
        print(f"   Error: {search.get('error')}")
    print()
    
    # Check updated usage
    print("5. Updated Cohere API Usage:")
    api_stats = get_api_usage_stats()
    print(f"   Current key usage: {api_stats.get('current_key_usage')}/{api_stats.get('limit_per_key')}")
    print()
    
    # Test Latin search (auto-converts to Cyrillic)
    print("6. Search for 'nikoh' (Latin) - USES Cohere API:")
    search_latin = search_questions("nikoh haqida", limit=3)
    if search_latin["success"]:
        print(f"   Detected alphabet: {search_latin['alphabet']}")
        for q in search_latin["questions"]:
            print(f"   - [{q['score']:.4f}] {q['title'][:50]}...")
    else:
        print(f"   Error: {search_latin.get('error')}")
    print()
    
    # Test detail (doesn't use Cohere)
    print("7. Get question detail (ID=100) - NO Cohere API used:")
    detail = get_question_detail(100)
    if detail["success"]:
        print(f"   Title: {detail['question']['title'][:60]}...")
        print(f"   Related: {len(detail['related'])} questions")
    else:
        print(f"   Error: {detail.get('error')}")
    print()
    
    # Final usage
    print("8. Final Cohere API Usage:")
    api_stats = get_api_usage_stats()
    print(f"   Current key usage: {api_stats.get('current_key_usage')}/{api_stats.get('limit_per_key')}")
    print(f"   All keys: {api_stats.get('all_keys_usage')}")
    print()
    
    print("=" * 60)
    print("✅ All tests completed!")
    print("=" * 60)
