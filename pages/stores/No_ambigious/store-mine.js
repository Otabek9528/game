// store-mine.js — "My submissions" list
// Exposes: window.StoreMine
// ============================================

window.StoreMine = (() => {

  let _onEdit = null;
  let _onBack = null;

  function init(callbacks) {
    if (callbacks) {
      _onEdit = callbacks.onEdit || null;
      _onBack = callbacks.onBack || null;
    }
    document.getElementById('mineBackBtn').addEventListener('click', () => {
      if (_onBack) _onBack();
    });
  }

  async function open() {
    StoreUI.showState('mine');
    await _reload();
  }

  async function _reload() {
    const apiBase = window._API_BASE || '';
    const userId = _getUserId();

    if (!userId) {
      StoreUI.renderMineList([], apiBase, _handleEdit, _handleDelete);
      return;
    }

    try {
      const resp = await fetch(
        `${apiBase}/api/store/mine?userId=${encodeURIComponent(userId)}`
      );
      const data = await resp.json();
      const products = data.products || [];
      StoreUI.renderMineList(products, apiBase, _handleEdit, _handleDelete);
    } catch (err) {
      console.error('Failed to load my submissions:', err);
      StoreUI.renderMineList([], apiBase, _handleEdit, _handleDelete);
    }
  }

  function _handleEdit(product) {
    if (_onEdit) _onEdit(product);
  }

  async function _handleDelete(product) {
    const confirmed = await _confirmDelete(product);
    if (!confirmed) return;

    const apiBase = window._API_BASE || '';
    const userId = _getUserId();

    try {
      const resp = await fetch(
        `${apiBase}/api/store/product/${encodeURIComponent(product.publicId)}`,
        {
          method: 'DELETE',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ userId })
        }
      );
      const data = await resp.json();
      if (!resp.ok || !data.success) {
        throw new Error(data.error || 'Delete failed');
      }
      await _reload();
    } catch (err) {
      const tg = window.Telegram && window.Telegram.WebApp;
      const msg = 'Error: ' + ((err && err.message) || err);
      if (tg && tg.showAlert) tg.showAlert(msg);
      else alert(msg);
    }
  }

  function _confirmDelete(product) {
    const tg = window.Telegram && window.Telegram.WebApp;
    const msg = `O'chirish?\n\n${product.store} · ${product.category}\nShtrix-kod: ${product.barcode}`;
    return new Promise(resolve => {
      if (tg && tg.showConfirm) {
        tg.showConfirm(msg, (ok) => resolve(!!ok));
      } else {
        resolve(window.confirm(msg));
      }
    });
  }

  function _getUserId() {
    try {
      const u = window.Telegram && window.Telegram.WebApp && window.Telegram.WebApp.initDataUnsafe
                && window.Telegram.WebApp.initDataUnsafe.user;
      return u ? String(u.id) : '';
    } catch (e) { return ''; }
  }

  return { init, open, reload: _reload };
})();
