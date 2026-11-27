"""
Reviews of places, one per person per place.

  POST   /api/review/submit                     write a review, or rewrite one's own
  DELETE /api/review/<place_id>                 take one's review back

(Update 6 also listed every place of a type at /api/places/all. It is gone:
the places are shown five at a time, nearest first, so they can't be copied
in one request.)

Reviews used to pile up: anyone could post any number about the same place.
Now a person has one review per place. Writing again replaces it (the app
shows it as theirs, to change or delete), and at most REVIEWS_PER_DAY new
ones a day. The writer comes from the app's token (signed in) or the Mini
App's signed initData, as before.
"""
import logging
import sqlite3
from datetime import datetime, timedelta, timezone

from flask import Blueprint, current_app, jsonify, request

from place_submissions_api import _clean, resolve_submitter

logger = logging.getLogger(__name__)

bp = Blueprint('places_public', __name__)

DEFAULT_DB_PATH = '/home/ubuntu/vegukin_api/data/main_db.sqlite'
REVIEW_TEXT_MAX = 1000
REVIEWS_PER_DAY = 10


def _db():
    conn = sqlite3.connect(current_app.config.get('PLACES_DB', DEFAULT_DB_PATH))
    conn.row_factory = sqlite3.Row
    return conn


def _err(code, message, status):
    return jsonify({'success': False, 'code': code, 'error': message}), status


def _writer():
    """(user id as stored in reviews, None) or (None, error response)."""
    user, err = resolve_submitter()
    if err:
        code, message = err
        return None, _err(code, message, 503 if code == 'server_misconfigured' else 401)
    return str(int(user['id'])), None


def _stamp(moment):
    # The shape the Mini App used to send (toISOString), so old and new rows sort together.
    return moment.strftime('%Y-%m-%dT%H:%M:%S.') + f'{moment.microsecond // 1000:03d}Z'


@bp.route('/api/review/submit', methods=['POST'])
def submit_review():
    """
    JSON body: place_id (or mosque_id), rating 1-5, review_text (optional, up
    to 1000 characters). Someone who has reviewed the place before rewrites
    that review: {"updated": true}.
    """
    user_id, error = _writer()
    if error:
        return error
    data = request.get_json(silent=True) or {}
    try:
        place_id = int(data.get('place_id') or data.get('mosque_id'))
        rating = int(data.get('rating'))
    except (TypeError, ValueError):
        return _err('invalid_input', 'place_id and rating are required', 400)
    if not 1 <= rating <= 5:
        return _err('invalid_rating', 'Rating must be between 1 and 5', 400)
    text = _clean(data.get('review_text'))
    if len(text) > REVIEW_TEXT_MAX:
        return _err('text_too_long', f'At most {REVIEW_TEXT_MAX} characters', 400)

    now = datetime.now(timezone.utc)
    conn = _db()
    try:
        if not conn.execute("SELECT 1 FROM main_db WHERE Unique_number = ?", (place_id,)).fetchone():
            return _err('place_not_found', 'That place no longer exists.', 404)
        mine = [r[0] for r in conn.execute(
            "SELECT rowid FROM reviews WHERE Unique_number = ? AND User_ID = ? ORDER BY Timestamp DESC",
            (place_id, user_id))]
        if mine:
            conn.execute("UPDATE reviews SET Rating = ?, Review_Text = ?, Timestamp = ? WHERE rowid = ?",
                         (rating, text, _stamp(now), mine[0]))
            # Older ones from before there was one per person go: the new one says it all.
            conn.executemany("DELETE FROM reviews WHERE rowid = ?", [(r,) for r in mine[1:]])
        else:
            today = conn.execute("SELECT COUNT(*) FROM reviews WHERE User_ID = ? AND Timestamp >= ?",
                                 (user_id, _stamp(now - timedelta(days=1)))).fetchone()[0]
            if today >= REVIEWS_PER_DAY:
                return _err('too_many_reviews', 'Too many reviews today', 429)
            conn.execute("INSERT INTO reviews (Unique_number, User_ID, Rating, Review_Text, Timestamp) "
                         "VALUES (?, ?, ?, ?, ?)", (place_id, user_id, rating, text, _stamp(now)))
        conn.commit()
    except sqlite3.Error:
        logger.exception('Review for place %s failed', place_id)
        return _err('server_error', 'Failed to submit review', 500)
    finally:
        conn.close()
    logger.info('Review %s for place %s by %s (rating %s)', 'rewritten' if mine else 'written',
                place_id, user_id, rating)
    return jsonify({'success': True, 'updated': bool(mine), 'message': 'Review submitted successfully'})


@bp.route('/api/review/<int:place_id>', methods=['DELETE'])
def delete_review(place_id):
    user_id, error = _writer()
    if error:
        return error
    conn = _db()
    try:
        deleted = conn.execute("DELETE FROM reviews WHERE Unique_number = ? AND User_ID = ?",
                               (place_id, user_id)).rowcount
        conn.commit()
    finally:
        conn.close()
    return jsonify({'success': True, 'deleted': deleted})
