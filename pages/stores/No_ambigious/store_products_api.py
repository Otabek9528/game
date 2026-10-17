"""
Store Products API — Flask Blueprint
======================================
Endpoints for the Store-Based Halal Product Collector.
Trusted-user feature: submissions go directly into `store_products`.

Import into your main Flask app:
    from store_products_api import store_products_bp
    app.register_blueprint(store_products_bp)

Database: same SQLite file as the scanner (products.sqlite).
Tables:
    - store_products   — the crowdsourced per-store halal entries
    - store_audit      — write-action log (add/edit/delete) for forensics

Photo folder:
    - data/store_products/photos/   — product photos

Notes:
- No HMAC validation (deferred per product decision).
- `user_id` comes from client via window.Telegram.WebApp.initDataUnsafe.user.id.
- Ownership on edit/delete is enforced by matching submitted `userId` against row.
- Categories stored as English keys; UI maps them to Uzbek labels.
- Photos may be shared across rows (cross-store reuse). Files are only
  deleted from disk when no remaining row references them.
"""

from flask import Blueprint, request, jsonify, send_from_directory
import sqlite3
import os
import base64
import uuid
from datetime import datetime, timezone, timedelta

# All timestamps use Korea Standard Time (UTC+9) regardless of server TZ.
KST = timezone(timedelta(hours=9))

def _now_kst():
    return datetime.now(KST)

# ============================================
# CONFIG
# ============================================

DB_PATH = '/home/ubuntu/vegukin_api/data/products.sqlite'

STORE_PHOTO_DIR = '/home/ubuntu/vegukin_api/data/store_products/photos'
LOCAL_PHOTOS_DIR = '/home/ubuntu/vegukin_api/data'

ALLOWED_STORES = {'GS25', 'CU', '7-Eleven', 'Emart24', 'No Brand'}
ALLOWED_CATEGORIES = {
    'Drinks', 'Snacks', 'Sweets', 'Ice Cream', 'Baked Goods',
    'Cup Noodles/Ramen', 'Lunchbox/Dosirak', 'Dairy', 'Canned Food',
    'Frozen Food', 'Condiments/Sauces', 'Fruits/Vegetables', 'Dried Food'
}

# ============================================
# BLUEPRINT
# ============================================

store_products_bp = Blueprint('store_products', __name__)


# ============================================
# DATABASE HELPERS
# ============================================

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    _ensure_tables(conn)
    return conn


def _ensure_tables(conn):
    conn.execute('''
        CREATE TABLE IF NOT EXISTS store_products (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            public_id     TEXT NOT NULL UNIQUE,
            barcode       TEXT NOT NULL,
            store         TEXT NOT NULL,
            category      TEXT NOT NULL,
            photo_path    TEXT,
            pork          INTEGER DEFAULT 0,
            alcohol       INTEGER DEFAULT 0,
            meat          INTEGER DEFAULT 0,
            seafood       INTEGER DEFAULT 0,
            same_factory  INTEGER DEFAULT 0,
            all_halal     INTEGER DEFAULT 0,
            verdict       TEXT,
            user_id       TEXT,
            created_at    TEXT,
            updated_at    TEXT,
            UNIQUE(barcode, store)
        )
    ''')
    conn.execute('''
        CREATE INDEX IF NOT EXISTS idx_store_products_barcode
        ON store_products(barcode)
    ''')
    conn.execute('''
        CREATE TABLE IF NOT EXISTS store_audit (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            action      TEXT,
            product_id  INTEGER,
            public_id   TEXT,
            user_id     TEXT,
            ip          TEXT,
            user_agent  TEXT,
            at          TEXT
        )
    ''')
    # Migration: add all_halal if the table was created before M1.
    try:
        cols = [r[1] for r in conn.execute('PRAGMA table_info(store_products)').fetchall()]
        if 'all_halal' not in cols:
            conn.execute('ALTER TABLE store_products ADD COLUMN all_halal INTEGER DEFAULT 0')
    except Exception:
        pass
    conn.commit()


def _determine_verdict(pork, alcohol, meat, seafood, same_factory, all_halal):
    """
    Precedence:
      pork|alcohol|meat|seafood → 'harom'
      only same_factory         → 'shubhali'
      all_halal (nothing else)  → 'halol'
      nothing selected          → None  (caller must reject)
    """
    if pork or alcohol or meat or seafood:
        return 'harom'
    if same_factory:
        return 'shubhali'
    if all_halal:
        return 'halol'
    return None


def _save_photo(barcode, base64_data):
    """Save base64 photo; return relative path from LOCAL_PHOTOS_DIR."""
    os.makedirs(STORE_PHOTO_DIR, exist_ok=True)

    if ',' in base64_data:
        base64_data = base64_data.split(',', 1)[1]

    timestamp = _now_kst().strftime('%Y%m%d_%H%M%S_%f')
    filename = f'{barcode}_{timestamp}.jpg'
    filepath = os.path.join(STORE_PHOTO_DIR, filename)

    with open(filepath, 'wb') as f:
        f.write(base64.b64decode(base64_data))

    return os.path.relpath(filepath, LOCAL_PHOTOS_DIR)


def _photo_refcount(conn, rel_path):
    """How many rows reference this photo_path right now."""
    if not rel_path:
        return 0
    row = conn.execute(
        'SELECT COUNT(*) FROM store_products WHERE photo_path = ?', (rel_path,)
    ).fetchone()
    return row[0] if row else 0


def _delete_photo_file(rel_path):
    """Best-effort file removal. Caller must confirm refcount == 0."""
    if not rel_path:
        return
    try:
        full = os.path.join(LOCAL_PHOTOS_DIR, rel_path)
        if os.path.isfile(full):
            os.remove(full)
    except Exception:
        pass


def _photo_path_exists_in_db(conn, rel_path):
    """Confirm a photoPath was actually produced by us (referenced by some row).
    Prevents arbitrary-path injection via the photoPath field."""
    if not rel_path:
        return False
    row = conn.execute(
        'SELECT 1 FROM store_products WHERE photo_path = ? LIMIT 1', (rel_path,)
    ).fetchone()
    return row is not None


def _row_to_dict(row):
    if not row:
        return None
    photo = row['photo_path'] or ''
    image_url = f'/api/store/photo/{photo}' if photo else ''
    # all_halal may not exist on very old rows if migration just ran
    try:
        all_halal = bool(row['all_halal'])
    except (IndexError, KeyError):
        all_halal = False
    return {
        'id': row['id'],
        'publicId': row['public_id'],
        'barcode': row['barcode'],
        'store': row['store'],
        'category': row['category'],
        'photo': photo,
        'image': image_url,
        'pork': bool(row['pork']),
        'alcohol': bool(row['alcohol']),
        'meat': bool(row['meat']),
        'seafood': bool(row['seafood']),
        'sameFactory': bool(row['same_factory']),
        'allHalal': all_halal,
        'verdict': row['verdict'],
        'userId': row['user_id'] or '',
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
    }


def _audit(conn, action, product_id, public_id, user_id):
    try:
        ip = request.headers.get('X-Forwarded-For', request.remote_addr) or ''
        ua = request.headers.get('User-Agent', '')[:500]
        conn.execute('''
            INSERT INTO store_audit
            (action, product_id, public_id, user_id, ip, user_agent, at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (action, product_id, public_id, user_id or '', ip, ua,
              _now_kst().isoformat()))
    except Exception:
        pass


# ============================================
# ENDPOINTS
# ============================================

@store_products_bp.route('/api/store/check/<store>/<barcode>', methods=['GET'])
def check_barcode(store, barcode):
    """
    Check a barcode for the selected store.
    Returns:
      {
        exact_match:  { ...product } | null,   # same (barcode, store)
        other_stores: [ ...products ]          # same barcode elsewhere
      }
    """
    try:
        if store not in ALLOWED_STORES:
            return jsonify({'error': f'Invalid store: {store}'}), 400

        conn = get_db()
        exact = conn.execute(
            'SELECT * FROM store_products WHERE barcode = ? AND store = ?',
            (barcode, store)
        ).fetchone()
        others = conn.execute(
            'SELECT * FROM store_products WHERE barcode = ? AND store != ? '
            'ORDER BY created_at DESC',
            (barcode, store)
        ).fetchall()
        conn.close()

        return jsonify({
            'exact_match': _row_to_dict(exact) if exact else None,
            'other_stores': [_row_to_dict(r) for r in others],
            'barcode': barcode,
            'store': store,
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@store_products_bp.route('/api/store/product/add', methods=['POST'])
def add_product():
    """
    Insert a new (barcode, store) entry.
    Accepts:
      barcode, store, category, userId,
      pork, alcohol, meat, seafood, sameFactory, allHalal,
      photo (base64 — new upload)  OR  photoPath (reuse existing row's path)
    """
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400

        barcode = (data.get('barcode') or '').strip()
        store = (data.get('store') or '').strip()
        category = (data.get('category') or '').strip()

        if not barcode:
            return jsonify({'error': 'barcode is required'}), 400
        if store not in ALLOWED_STORES:
            return jsonify({'error': f'Invalid store: {store}'}), 400
        if category not in ALLOWED_CATEGORIES:
            return jsonify({'error': f'Invalid category: {category}'}), 400

        pork = 1 if data.get('pork') else 0
        alcohol = 1 if data.get('alcohol') else 0
        meat = 1 if data.get('meat') else 0
        seafood = 1 if data.get('seafood') else 0
        same_factory = 1 if data.get('sameFactory') else 0
        all_halal = 1 if data.get('allHalal') else 0
        user_id = str(data.get('userId') or '')

        verdict = _determine_verdict(
            bool(pork), bool(alcohol), bool(meat), bool(seafood),
            bool(same_factory), bool(all_halal)
        )
        if verdict is None:
            return jsonify({
                'error': 'At least one flag must be selected',
                'code': 'NO_FLAG'
            }), 400

        conn = get_db()

        photo_path = ''
        photo_b64 = data.get('photo', '')
        reuse_path = (data.get('photoPath') or '').strip()

        if photo_b64:
            photo_path = _save_photo(barcode, photo_b64)
        elif reuse_path:
            if not _photo_path_exists_in_db(conn, reuse_path):
                conn.close()
                return jsonify({
                    'error': 'photoPath not recognised',
                    'code': 'BAD_PHOTO_PATH'
                }), 400
            photo_path = reuse_path

        public_id = str(uuid.uuid4())
        now = _now_kst().isoformat()

        try:
            cur = conn.execute('''
                INSERT INTO store_products
                (public_id, barcode, store, category, photo_path,
                 pork, alcohol, meat, seafood, same_factory, all_halal,
                 verdict, user_id, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                public_id, barcode, store, category, photo_path,
                pork, alcohol, meat, seafood, same_factory, all_halal,
                verdict, user_id, now, now
            ))
            new_id = cur.lastrowid
            _audit(conn, 'add', new_id, public_id, user_id)
            conn.commit()
        except sqlite3.IntegrityError:
            conn.close()
            # Only discard the file if we just uploaded it (don't nuke a shared one).
            if photo_b64 and photo_path:
                _delete_photo_file(photo_path)
            return jsonify({
                'error': 'This product is already registered for this store.',
                'code': 'DUPLICATE'
            }), 409

        row = conn.execute(
            'SELECT * FROM store_products WHERE id = ?', (new_id,)
        ).fetchone()
        conn.close()

        return jsonify({
            'success': True,
            'product': _row_to_dict(row),
            'verdict': verdict
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@store_products_bp.route('/api/store/mine', methods=['GET'])
def list_mine():
    """List submissions for a user_id (query param: userId)."""
    try:
        user_id = (request.args.get('userId') or '').strip()
        if not user_id:
            return jsonify({'error': 'userId is required'}), 400

        conn = get_db()
        rows = conn.execute(
            'SELECT * FROM store_products WHERE user_id = ? '
            'ORDER BY created_at DESC',
            (user_id,)
        ).fetchall()
        conn.close()

        return jsonify({
            'count': len(rows),
            'products': [_row_to_dict(r) for r in rows]
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@store_products_bp.route('/api/store/product/<public_id>', methods=['GET'])
def get_product(public_id):
    try:
        conn = get_db()
        row = conn.execute(
            'SELECT * FROM store_products WHERE public_id = ?', (public_id,)
        ).fetchone()
        conn.close()
        if not row:
            return jsonify({'error': 'Not found'}), 404
        return jsonify(_row_to_dict(row))
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@store_products_bp.route('/api/store/product/<public_id>', methods=['PUT'])
def edit_product(public_id):
    """
    Edit an entry. Requires ownership (userId match).
    All fields editable: barcode, store, category, flags, photo.
    Photo: send base64 in `photo` to replace; omit to keep.
    UNIQUE(barcode, store) re-checked → 409 on conflict.
    """
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400

        caller_user_id = str(data.get('userId') or '').strip()
        if not caller_user_id:
            return jsonify({'error': 'userId is required'}), 400

        conn = get_db()
        row = conn.execute(
            'SELECT * FROM store_products WHERE public_id = ?', (public_id,)
        ).fetchone()
        if not row:
            conn.close()
            return jsonify({'error': 'Not found'}), 404

        if (row['user_id'] or '') != caller_user_id:
            conn.close()
            return jsonify({'error': 'Not allowed: you did not submit this entry'}), 403

        barcode = (data.get('barcode') or row['barcode']).strip()
        store = (data.get('store') or row['store']).strip()
        category = (data.get('category') or row['category']).strip()

        if not barcode:
            conn.close()
            return jsonify({'error': 'barcode cannot be empty'}), 400
        if store not in ALLOWED_STORES:
            conn.close()
            return jsonify({'error': f'Invalid store: {store}'}), 400
        if category not in ALLOWED_CATEGORIES:
            conn.close()
            return jsonify({'error': f'Invalid category: {category}'}), 400

        pork = 1 if data.get('pork') else 0
        alcohol = 1 if data.get('alcohol') else 0
        meat = 1 if data.get('meat') else 0
        seafood = 1 if data.get('seafood') else 0
        same_factory = 1 if data.get('sameFactory') else 0
        all_halal = 1 if data.get('allHalal') else 0

        verdict = _determine_verdict(
            bool(pork), bool(alcohol), bool(meat), bool(seafood),
            bool(same_factory), bool(all_halal)
        )
        if verdict is None:
            conn.close()
            return jsonify({
                'error': 'At least one flag must be selected',
                'code': 'NO_FLAG'
            }), 400

        new_photo_path = row['photo_path']
        photo_b64 = data.get('photo', '')
        old_photo_to_maybe_delete = None
        if photo_b64:
            saved = _save_photo(barcode, photo_b64)
            old_photo_to_maybe_delete = row['photo_path']
            new_photo_path = saved

        now = _now_kst().isoformat()
        try:
            conn.execute('''
                UPDATE store_products
                SET barcode = ?, store = ?, category = ?, photo_path = ?,
                    pork = ?, alcohol = ?, meat = ?, seafood = ?,
                    same_factory = ?, all_halal = ?, verdict = ?, updated_at = ?
                WHERE public_id = ?
            ''', (barcode, store, category, new_photo_path,
                  pork, alcohol, meat, seafood, same_factory, all_halal,
                  verdict, now, public_id))
            _audit(conn, 'edit', row['id'], public_id, caller_user_id)
            conn.commit()
        except sqlite3.IntegrityError:
            conn.close()
            if photo_b64 and new_photo_path and new_photo_path != row['photo_path']:
                _delete_photo_file(new_photo_path)
            return jsonify({
                'error': 'Another entry already exists for this (barcode, store).',
                'code': 'DUPLICATE'
            }), 409

        # If the old photo was replaced and is no longer used anywhere, remove it.
        if old_photo_to_maybe_delete and old_photo_to_maybe_delete != new_photo_path:
            if _photo_refcount(conn, old_photo_to_maybe_delete) == 0:
                _delete_photo_file(old_photo_to_maybe_delete)

        updated = conn.execute(
            'SELECT * FROM store_products WHERE public_id = ?', (public_id,)
        ).fetchone()
        conn.close()
        return jsonify({'success': True, 'product': _row_to_dict(updated)})

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@store_products_bp.route('/api/store/product/<public_id>', methods=['DELETE'])
def delete_product(public_id):
    """
    Delete an entry. Requires ownership (userId match).
    userId via JSON body or ?userId= query param.
    Photo file removed only when no other row still references it.
    """
    try:
        caller_user_id = ''
        if request.is_json:
            body = request.get_json(silent=True) or {}
            caller_user_id = str(body.get('userId') or '').strip()
        if not caller_user_id:
            caller_user_id = (request.args.get('userId') or '').strip()
        if not caller_user_id:
            return jsonify({'error': 'userId is required'}), 400

        conn = get_db()
        row = conn.execute(
            'SELECT * FROM store_products WHERE public_id = ?', (public_id,)
        ).fetchone()
        if not row:
            conn.close()
            return jsonify({'error': 'Not found'}), 404

        if (row['user_id'] or '') != caller_user_id:
            conn.close()
            return jsonify({'error': 'Not allowed: you did not submit this entry'}), 403

        photo_path = row['photo_path']
        conn.execute('DELETE FROM store_products WHERE public_id = ?', (public_id,))
        _audit(conn, 'delete', row['id'], public_id, caller_user_id)
        conn.commit()

        still_referenced = _photo_refcount(conn, photo_path) > 0
        conn.close()
        if photo_path and not still_referenced:
            _delete_photo_file(photo_path)

        return jsonify({'success': True})

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@store_products_bp.route('/api/store/photo/<path:filepath>', methods=['GET'])
def serve_photo(filepath):
    """Serve a stored photo. Path-traversal guard enforces STORE_PHOTO_DIR scope."""
    try:
        full_path = os.path.normpath(os.path.join(LOCAL_PHOTOS_DIR, filepath))
        root = os.path.normpath(STORE_PHOTO_DIR)
        if not (full_path == root or full_path.startswith(root + os.sep)):
            return jsonify({'error': 'Invalid path'}), 400

        if not os.path.isfile(full_path):
            return jsonify({'error': 'Photo not found'}), 404

        directory = os.path.dirname(full_path)
        filename = os.path.basename(full_path)
        return send_from_directory(directory, filename)

    except Exception as e:
        return jsonify({'error': str(e)}), 500
