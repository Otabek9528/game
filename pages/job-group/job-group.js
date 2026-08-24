// job-group.js - Job Group: Join (landing) + Post sheet + My Posts

const tg = window.Telegram.WebApp;
tg.ready();
tg.disableVerticalSwipes();
try { tg.expand(); } catch (e) {}

// ===========================================
// CONFIG
// ===========================================
const API_BASE_URL = 'https://vegukin-api.duckdns.org/';
const LINK_DURATION = 15;
const FINISH_DELAY_MS = 3 * 60 * 60 * 1000; // 3 hours

// Mirrors the footnote the backend appends to the group message.
const FOOTNOTE_PREVIEW = {
  yes: "👉 Bu e'lon faqat shu guruhga qo'yildi.\n👉 Ishga qatnashgan har bir kishi ish egasiga bir martalik komissiyani: 10,000 KRW ish haqini olish vaqtida to'laydi.\n👉 E'lon egasiga murojaat qilish orqali siz ushbu to'lovga rozilik bildirasiz.",
  no: "👉 Bu e'lon faqat shu guruhga qo'yildi.\n👉 Bu e'lon uchun hech qanday komissiya olinmaydi.",
};

// ===========================================
// DOM — LANDING
// ===========================================
const initialState = document.getElementById('initialState');
const loadingState = document.getElementById('loadingState');
const linkState = document.getElementById('linkState');
const expiredState = document.getElementById('expiredState');
const errorState = document.getElementById('errorState');
const getLinkBtn = document.getElementById('getLinkBtn');
const retryBtn = document.getElementById('retryBtn');
const errorRetryBtn = document.getElementById('errorRetryBtn');
const joinBtn = document.getElementById('joinBtn');
const copyLinkBtn = document.getElementById('copyLinkBtn');
const linkText = document.getElementById('linkText');
const timerText = document.getElementById('timerText');
const timerProgress = document.getElementById('timerProgress');
const copyIcon = document.getElementById('copyIcon');
const errorText = document.getElementById('errorText');

// DOM — DOCK + SHEET SHELL
const actionDock = document.getElementById('actionDock');
const dockPostBtn = document.getElementById('dockPostBtn');
const dockMyPostsBtn = document.getElementById('dockMyPostsBtn');
const dockMyPostsCount = document.getElementById('dockMyPostsCount');
const postSheet = document.getElementById('postSheet');
const sheetHead = document.getElementById('sheetHead');
const sheetScroll = document.getElementById('sheetScroll');
const sheetBackBtn = document.getElementById('sheetBackBtn');

// DOM — POST / MY POSTS
const subnavFormBtn = document.getElementById('subnavFormBtn');
const subnavMyPostsBtn = document.getElementById('subnavMyPostsBtn');
const postFormView = document.getElementById('postFormView');
const myPostsView = document.getElementById('myPostsView');
const myPostsBadge = document.getElementById('myPostsBadge');
const myPostsList = document.getElementById('myPostsList');
const emptyPosts = document.getElementById('emptyPosts');
const emptyCtaBtn = document.getElementById('emptyCtaBtn');

const postFormState = document.getElementById('postFormState');
const postLoadingState = document.getElementById('postLoadingState');
const postLoadingText = document.getElementById('postLoadingText');
const postSuccessState = document.getElementById('postSuccessState');
const postErrorState = document.getElementById('postErrorState');
const postMessage = document.getElementById('postMessage');
const postContact = document.getElementById('postContact');
const charCount = document.getElementById('charCount');
const postSubmitBtn = document.getElementById('postSubmitBtn');
const postSubmitText = document.getElementById('postSubmitText');
const postAgainBtn = document.getElementById('postAgainBtn');
const viewPostsBtn = document.getElementById('viewPostsBtn');
const postErrorRetryBtn = document.getElementById('postErrorRetryBtn');
const postErrorText = document.getElementById('postErrorText');
const successTitle = document.getElementById('successTitle');
const successText = document.getElementById('successText');
const successChip = document.getElementById('successChip');

const editBanner = document.getElementById('editBanner');
const editCancelBtn = document.getElementById('editCancelBtn');

const contactAuto = document.getElementById('contactAuto');
const contactManual = document.getElementById('contactManual');
const contactUsername = document.getElementById('contactUsername');
const contactLabel = document.getElementById('contactLabel');
const contactToggleBtn = document.getElementById('contactToggleBtn');
const contactBackBtn = document.getElementById('contactBackBtn');
const agreementLabel = document.getElementById('agreementLabel');
const agreementCheckbox = document.getElementById('agreementCheckbox');

const commissionOptions = document.getElementById('commissionOptions');
const commissionRadios = document.querySelectorAll('input[name="commission"]');
const commissionPreview = document.getElementById('commissionPreview');
const commissionPreviewText = document.getElementById('commissionPreviewText');

const hiwHeader = document.getElementById('hiwHeader');
const hiwBody = document.getElementById('hiwBody');
const hiwToggle = document.getElementById('hiwToggle');
const howItWorks = document.getElementById('howItWorks');

// ===========================================
// STATE
// ===========================================
let currentLink = null;
let timerInterval = null;
let timeRemaining = LINK_DURATION;
let userHasUsername = false;
let telegramUsername = null;
let useManualContact = false;
let sheetOpen = false;
let editingPostId = null;
let myPosts = [];

function getUserId() {
  return tg.initDataUnsafe?.user?.id;
}

function getCommissionChoice() {
  const checked = document.querySelector('input[name="commission"]:checked');
  return checked ? checked.value : null;
}

// ===========================================
// POST SHEET — OPEN / CLOSE
// ===========================================
function openSheet(view) {
  sheetOpen = true;
  postSheet.classList.add('open');
  postSheet.setAttribute('aria-hidden', 'false');
  document.body.classList.add('sheet-open');
  actionDock.classList.add('hidden');
  showSubView(view || 'form');
  sheetScroll.scrollTop = 0;
  if (tg.HapticFeedback) tg.HapticFeedback.impactOccurred('light');
}

function closeSheet() {
  sheetOpen = false;
  postSheet.classList.remove('open');
  postSheet.setAttribute('aria-hidden', 'true');
  document.body.classList.remove('sheet-open');
  actionDock.classList.remove('hidden');
  postSheet.style.transform = '';
  if (tg.HapticFeedback) tg.HapticFeedback.impactOccurred('light');
}

dockPostBtn.addEventListener('click', () => openSheet('form'));
dockMyPostsBtn.addEventListener('click', () => openSheet('myPosts'));
sheetBackBtn.addEventListener('click', closeSheet);

// Swipe down on the sheet header to close it
let dragStartY = 0, dragging = false, dragDeltaY = 0;
sheetHead.addEventListener('touchstart', (e) => {
  dragStartY = e.touches[0].clientY; dragging = true; dragDeltaY = 0;
  postSheet.classList.add('no-transition');
}, { passive: true });

sheetHead.addEventListener('touchmove', (e) => {
  if (!dragging) return;
  dragDeltaY = Math.max(0, e.touches[0].clientY - dragStartY);
  postSheet.style.transform = `translateY(${dragDeltaY}px)`;
}, { passive: true });

sheetHead.addEventListener('touchend', () => {
  if (!dragging) return;
  dragging = false;
  postSheet.classList.remove('no-transition');
  postSheet.style.transform = '';
  if (dragDeltaY > 90) closeSheet();
  dragDeltaY = 0;
}, { passive: true });

// ===========================================
// SUB-NAV (inside the sheet)
// ===========================================
function showSubView(view) {
  if (view === 'form') {
    postFormView.style.display = 'block';
    myPostsView.style.display = 'none';
    subnavFormBtn.classList.add('active');
    subnavMyPostsBtn.classList.remove('active');
  } else {
    postFormView.style.display = 'none';
    myPostsView.style.display = 'block';
    subnavFormBtn.classList.remove('active');
    subnavMyPostsBtn.classList.add('active');
    fetchMyPosts();
  }
  sheetScroll.scrollTop = 0;
}

async function fetchMyPosts() {
  const userId = getUserId();
  if (!userId) { renderMyPosts(); return; }
  try {
    const resp = await fetch(`${API_BASE_URL}/api/group/posts?user_id=${userId}`, { signal: AbortSignal.timeout(10000) });
    const data = await resp.json();
    if (data.success) {
      myPosts = data.posts.map(p => ({
        id: p.id,
        text: p.message,
        contact: p.contact,
        status: p.status,
        commission: p.commission !== false,
        created_at: p.created_at,
        reserved_at: p.reserved_at,
        finished_at: p.finished_at,
      }));
    }
  } catch (e) {
    console.error('Failed to fetch posts:', e);
  }
  renderMyPosts();
}

subnavFormBtn.addEventListener('click', () => { if (editingPostId) cancelEdit(); showSubView('form'); });
subnavMyPostsBtn.addEventListener('click', () => showSubView('myPosts'));
viewPostsBtn.addEventListener('click', () => showSubView('myPosts'));
emptyCtaBtn.addEventListener('click', () => showSubView('form'));

// ===========================================
// LANDING — STATE MANAGEMENT
// ===========================================
function showState(name) {
  [initialState, loadingState, linkState, expiredState, errorState].forEach(el => el.style.display = 'none');
  const map = { initial: initialState, loading: loadingState, link: linkState, expired: expiredState, error: errorState };
  if (map[name]) map[name].style.display = 'block';
}

function showPostState(name) {
  [postFormState, postLoadingState, postSuccessState, postErrorState].forEach(el => el.style.display = 'none');
  const map = { form: postFormState, loading: postLoadingState, success: postSuccessState, error: postErrorState };
  if (map[name]) map[name].style.display = 'block';
  howItWorks.style.display = name === 'form' ? 'block' : 'none';
}

// ===========================================
// TIMER
// ===========================================
function startTimer() {
  timeRemaining = LINK_DURATION; updateTimerDisplay();
  timerInterval = setInterval(() => {
    timeRemaining--; updateTimerDisplay();
    if (timeRemaining <= 0) { clearInterval(timerInterval); timerInterval = null; handleLinkExpired(); }
  }, 1000);
}
function updateTimerDisplay() {
  timerText.textContent = timeRemaining;
  const progress = (timeRemaining / LINK_DURATION) * 283;
  timerProgress.style.strokeDashoffset = 283 - progress;
  timerText.classList.remove('warning', 'danger');
  timerProgress.classList.remove('warning', 'danger');
  if (timeRemaining <= 5) { timerText.classList.add('danger'); timerProgress.classList.add('danger'); }
  else if (timeRemaining <= 10) { timerText.classList.add('warning'); timerProgress.classList.add('warning'); }
}
function stopTimer() { if (timerInterval) { clearInterval(timerInterval); timerInterval = null; } }

// ===========================================
// LANDING — API
// ===========================================
async function requestInviteLink() {
  showState('loading'); stopTimer();
  try {
    const userId = tg.initDataUnsafe?.user?.id;
    if (!userId) throw new Error('Telegram foydalanuvchi ID topilmadi');
    const response = await fetch(`${API_BASE_URL}/api/group/invite`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: userId }), signal: AbortSignal.timeout(15000)
    });
    if (!response.ok) { const d = await response.json().catch(() => ({})); throw new Error(d.message || `Server xatosi: ${response.status}`); }
    const data = await response.json();
    if (data.success && data.invite_link) { currentLink = data.invite_link; displayLink(currentLink); }
    else throw new Error(data.message || 'Link yaratishda xatolik');
  } catch (error) { showError(error.message || 'Link yaratishda xatolik yuz berdi'); }
}
function displayLink(link) {
  linkText.textContent = link; joinBtn.href = link; showState('link'); startTimer();
  if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('success');
}
function handleLinkExpired() {
  currentLink = null; showState('expired');
  if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('warning');
}
function showError(message) {
  errorText.textContent = message; showState('error');
  if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('error');
}

// ===========================================
// COPY
// ===========================================
async function copyLink() {
  if (!currentLink) return;
  try {
    if (navigator.clipboard?.writeText) await navigator.clipboard.writeText(currentLink);
    else { const ta = document.createElement('textarea'); ta.value = currentLink; ta.style.cssText = 'position:fixed;opacity:0'; document.body.appendChild(ta); ta.select(); document.execCommand('copy'); document.body.removeChild(ta); }
    copyIcon.textContent = '✅';
    if (tg.HapticFeedback) tg.HapticFeedback.impactOccurred('light');
    setTimeout(() => copyIcon.textContent = '📋', 1500);
  } catch (err) { copyIcon.textContent = '❌'; setTimeout(() => copyIcon.textContent = '📋', 1500); }
}

// ===========================================
// CONTACT FIELD
// ===========================================
function initContactField() {
  telegramUsername = tg.initDataUnsafe?.user?.username || null;
  userHasUsername = !!telegramUsername;
  if (userHasUsername) {
    contactUsername.textContent = telegramUsername;
    contactAuto.style.display = 'block'; contactManual.style.display = 'none';
    contactBackBtn.style.display = 'none'; useManualContact = false;
  } else {
    contactAuto.style.display = 'none'; contactManual.style.display = 'block';
    contactLabel.innerHTML = 'Bog\'lanish uchun kontakt: <span class="label-req">majburiy</span>';
    postContact.placeholder = 'Tel raqam yoki Telegram username kiriting';
  }
}
function useManualContactField(value) {
  useManualContact = true;
  contactAuto.style.display = 'none';
  contactManual.style.display = 'block';
  contactBackBtn.style.display = userHasUsername ? 'flex' : 'none';
  if (value !== undefined) postContact.value = value;
}
contactToggleBtn.addEventListener('click', () => {
  useManualContactField('');
  postContact.focus(); validateForm();
});
contactBackBtn.addEventListener('click', () => {
  useManualContact = false; contactAuto.style.display = 'block';
  contactManual.style.display = 'none'; postContact.value = ''; validateForm();
});

// ===========================================
// COMMISSION CHOICE
// ===========================================
function updateCommissionUI() {
  const choice = getCommissionChoice();
  commissionOptions.querySelectorAll('.commission-option').forEach(opt => {
    opt.classList.toggle('selected', opt.dataset.value === choice);
  });
  if (choice) {
    commissionPreviewText.textContent = FOOTNOTE_PREVIEW[choice];
    commissionPreview.style.display = 'block';
  } else {
    commissionPreview.style.display = 'none';
  }
}

commissionRadios.forEach(radio => radio.addEventListener('change', () => {
  updateCommissionUI();
  if (tg.HapticFeedback) tg.HapticFeedback.selectionChanged();
  validateForm();
}));

// ===========================================
// FORM VALIDATION
// ===========================================
function validateForm() {
  const hasMsg = postMessage.value.trim().length >= 10;
  const hasContact = (userHasUsername && !useManualContact) || postContact.value.trim().length >= 3;
  const hasCommission = !!getCommissionChoice();
  const agreed = editingPostId ? true : agreementCheckbox.checked;
  postSubmitBtn.disabled = !(hasMsg && hasContact && hasCommission && agreed);

  if (!postSubmitBtn.disabled) {
    const hint = document.querySelector('.submit-hint');
    if (hint) { hint.classList.remove('visible'); setTimeout(() => hint.remove(), 300); }
  }
}
postMessage.addEventListener('input', () => {
  const len = postMessage.value.length;
  charCount.textContent = `${len} / 1000`;
  charCount.classList.remove('near-limit', 'at-limit');
  if (len >= 1000) charCount.classList.add('at-limit');
  else if (len >= 800) charCount.classList.add('near-limit');
  validateForm();
});
postContact.addEventListener('input', validateForm);
agreementCheckbox.addEventListener('change', validateForm);

// ===========================================
// SUBMIT — CREATE OR EDIT
// ===========================================
function currentContactValue() {
  return (userHasUsername && !useManualContact) ? '@' + telegramUsername : postContact.value.trim();
}

async function submitPost() {
  const message = postMessage.value.trim();
  if (message.length < 10) return;
  const contact = currentContactValue();
  if (!contact || contact.length < 3) return;
  const choice = getCommissionChoice();
  if (!choice) return;
  const commission = choice === 'yes';
  const userId = getUserId();
  const userName = tg.initDataUnsafe?.user?.first_name || '';
  const isEdit = !!editingPostId;

  postLoadingText.textContent = isEdit ? "O'zgarishlar saqlanmoqda..." : "E'lon yuborilmoqda...";
  showPostState('loading');

  try {
    if (!userId) throw new Error('Telegram foydalanuvchi ID topilmadi');
    const url = isEdit ? `${API_BASE_URL}/api/group/post/edit` : `${API_BASE_URL}/api/group/post`;
    const payload = isEdit
      ? { post_id: editingPostId, user_id: userId, message, contact, commission }
      : { user_id: userId, user_name: userName, message, contact, commission };

    const response = await fetch(url, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload), signal: AbortSignal.timeout(15000)
    });
    if (!response.ok) { const d = await response.json().catch(() => ({})); throw new Error(d.message || `Server xatosi: ${response.status}`); }
    const data = await response.json();
    if (!data.success) throw new Error(data.message || "E'lon yuborishda xatolik");

    successTitle.textContent = isEdit ? "E'lon yangilandi!" : "E'lon yuborildi!";
    successText.textContent = isEdit
      ? "O'zgarishlar guruhdagi xabarga ham qo'llanildi."
      : "E'loningiz guruhga muvaffaqiyatli joylandi.";
    successChip.textContent = commission ? '💰 Komissiyali e\'lon — 10,000 KRW' : '🤝 Komissiyasiz e\'lon';
    successChip.classList.toggle('neutral', !commission);
    exitEditMode();
    showPostState('success');
    if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('success');
    fetchMyPosts();
  } catch (error) {
    postErrorText.textContent = error.message || "E'lon yuborishda xatolik yuz berdi";
    showPostState('error');
    if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('error');
  }
}

function resetPostForm() {
  exitEditMode();
  postMessage.value = ''; postContact.value = '';
  charCount.textContent = '0 / 1000'; charCount.classList.remove('near-limit', 'at-limit');
  postSubmitBtn.disabled = true; useManualContact = false;
  agreementCheckbox.checked = false;
  commissionRadios.forEach(r => { r.checked = false; });
  updateCommissionUI();
  initContactField();
  showPostState('form');
}

// ===========================================
// EDIT MODE
// ===========================================
function enterEditMode(post) {
  editingPostId = post.id;
  editBanner.style.display = 'flex';
  agreementLabel.style.display = 'none';
  postSubmitText.textContent = "O'zgarishlarni saqlash";

  postMessage.value = post.text;
  charCount.textContent = `${post.text.length} / 1000`;

  initContactField();
  if (!(userHasUsername && post.contact === '@' + telegramUsername)) {
    useManualContactField(post.contact);
  }

  const radio = post.commission ? document.getElementById('commissionYes') : document.getElementById('commissionNo');
  radio.checked = true;
  updateCommissionUI();

  showSubView('form');
  showPostState('form');
  validateForm();
}

function exitEditMode() {
  editingPostId = null;
  editBanner.style.display = 'none';
  agreementLabel.style.display = 'flex';
  postSubmitText.textContent = "E'lonni joylash";
}

function cancelEdit() {
  resetPostForm();
}

editCancelBtn.addEventListener('click', () => { cancelEdit(); showSubView('myPosts'); });

// ===========================================
// MY POSTS — RENDERING
// ===========================================
function parseKST(dtStr) {
  if (!dtStr) return null;
  // dtStr is "YYYY-MM-DD HH:MM:SS" in KST (UTC+9)
  return new Date(dtStr.replace(' ', 'T') + '+09:00');
}

function timeAgo(dtStr) {
  const dt = parseKST(dtStr);
  if (!dt) return '';
  const diff = Math.floor((Date.now() - dt.getTime()) / 1000);
  if (diff < 60) return 'hozirgina';
  if (diff < 3600) return Math.floor(diff / 60) + ' daq. oldin';
  if (diff < 86400) return Math.floor(diff / 3600) + ' soat oldin';
  return Math.floor(diff / 86400) + ' kun oldin';
}

function canFinish(post) {
  if (post.status !== 'reserved' || !post.reserved_at) return false;
  const dt = parseKST(post.reserved_at);
  return (Date.now() - dt.getTime()) >= FINISH_DELAY_MS;
}

function finishTimeLeft(post) {
  if (!post.reserved_at) return '';
  const dt = parseKST(post.reserved_at);
  const remaining = FINISH_DELAY_MS - (Date.now() - dt.getTime());
  if (remaining <= 0) return '';
  const h = Math.floor(remaining / 3600000);
  const m = Math.floor((remaining % 3600000) / 60000);
  return `${h} soat ${m} daq. qoldi`;
}

function updateBadge() {
  myPostsBadge.textContent = myPosts.length;
  dockMyPostsCount.textContent = myPosts.length;
  // The shortcut only earns its place once the user actually has posts.
  dockMyPostsBtn.style.display = myPosts.length ? 'block' : 'none';
}

function renderMyPosts() {
  updateBadge();
  if (myPosts.length === 0) {
    myPostsList.innerHTML = '';
    emptyPosts.style.display = 'block';
    return;
  }
  emptyPosts.style.display = 'none';

  const statusLabels = { available: '🟢 Faol', reserved: '🟡 Band', finished: '✅ Bajarildi' };

  myPostsList.innerHTML = myPosts.map(post => {
    let primary = '';
    let hint = '';

    if (post.status === 'available') {
      primary = `<button class="post-action-btn reserve" onclick="confirmAction('${post.id}','reserve')">🟡 Band qilish</button>`;
    } else if (post.status === 'reserved') {
      const can = canFinish(post);
      if (!can) hint = `<div class="finish-hint">⏳ Yakunlash uchun: ${finishTimeLeft(post)}</div>`;
      primary = `
        <button class="post-action-btn reopen" onclick="confirmAction('${post.id}','reopen')">↩️ Faol qilish</button>
        <button class="post-action-btn finish" ${can ? '' : 'disabled'} onclick="confirmAction('${post.id}','finish')">✅ Yakunlash</button>
      `;
    } else {
      primary = `<div class="post-done-note">✅ Ish bajarildi</div>`;
    }

    // Editing rewrites the group message, so it is offered only while the post is still open.
    const editBtn = post.status === 'available'
      ? `<button class="post-icon-btn" onclick="startEdit('${post.id}')">✏️ Tahrirlash</button>`
      : '';

    const commissionChip = post.commission
      ? `<span class="commission-chip">💰 10,000 KRW</span>`
      : `<span class="commission-chip none">🤝 Komissiyasiz</span>`;

    return `
      <div class="my-post-card status-${post.status}">
        <div class="my-post-header">
          <span class="my-post-time">${timeAgo(post.created_at)}</span>
          <span class="status-badge ${post.status}">${statusLabels[post.status]}</span>
        </div>
        <div class="my-post-body">${escapeHtml(post.text)}</div>
        <div class="my-post-meta">${commissionChip}</div>
        <div class="my-post-actions">
          <div class="my-post-actions-row">${primary}</div>
          ${hint}
          <div class="my-post-actions-row secondary">
            ${editBtn}
            <button class="post-icon-btn danger" onclick="confirmAction('${post.id}','delete')">🗑 O'chirish</button>
          </div>
        </div>
      </div>
    `;
  }).join('');
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

function startEdit(postId) {
  const post = myPosts.find(p => String(p.id) === String(postId));
  if (!post) return;
  if (post.status !== 'available') {
    alert("Faqat faol e'lonni tahrirlash mumkin");
    return;
  }
  enterEditMode(post);
  if (tg.HapticFeedback) tg.HapticFeedback.impactOccurred('light');
}

// ===========================================
// CONFIRMATION MODAL
// ===========================================
function confirmAction(postId, action) {
  const messages = {
    reserve: { title: 'Band qilish', text: 'Ishchi topildimi? E\'lonni band sifatida belgilashni xohlaysizmi?', yes: 'Ha' },
    reopen: { title: 'Qayta faollashtirish', text: 'E\'lonni qayta faol holatga o\'tkazmoqchimisiz?', yes: 'Ha' },
    finish: { title: 'Yakunlash', text: 'Ish bajarildi deb belgilamoqchimisiz? Bu qaytarib bo\'lmaydi.', yes: 'Ha' },
    delete: { title: "E'lonni o'chirish", text: "E'lon guruhdan ham, ro'yxatingizdan ham butunlay o'chiriladi. Davom etasizmi?", yes: "O'chirish", danger: true },
  };
  const msg = messages[action];
  if (!msg) return;

  const overlay = document.createElement('div');
  overlay.className = 'confirm-overlay';
  overlay.innerHTML = `
    <div class="confirm-box">
      <h3 class="confirm-title">${msg.title}</h3>
      <p class="confirm-text">${msg.text}</p>
      <div class="confirm-actions">
        <button class="confirm-btn cancel" id="confirmCancel">Bekor qilish</button>
        <button class="confirm-btn yes ${msg.danger ? 'danger' : ''}" id="confirmYes">${msg.yes}</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);

  overlay.querySelector('#confirmCancel').addEventListener('click', () => overlay.remove());
  overlay.querySelector('#confirmYes').addEventListener('click', () => {
    executeAction(postId, action);
    overlay.remove();
  });
  overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
}

async function executeAction(postId, action) {
  const userId = getUserId();
  if (!userId) return;

  if (action === 'delete') return deletePost(postId, userId);

  const statusMap = { reserve: 'reserved', reopen: 'available', finish: 'finished' };
  const newStatus = statusMap[action];
  if (!newStatus) return;

  try {
    const resp = await fetch(`${API_BASE_URL}/api/group/post/status`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ post_id: postId, user_id: userId, status: newStatus }),
      signal: AbortSignal.timeout(10000),
    });
    const data = await resp.json();

    if (data.success) {
      if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('success');
      await fetchMyPosts();
    } else {
      alert(data.message || 'Xatolik yuz berdi');
      if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('error');
    }
  } catch (e) {
    console.error('Status update error:', e);
    alert("Tarmoq xatosi. Qayta urinib ko'ring.");
    if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('error');
  }
}

async function deletePost(postId, userId) {
  try {
    const resp = await fetch(`${API_BASE_URL}/api/group/post/delete`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ post_id: postId, user_id: userId }),
      signal: AbortSignal.timeout(10000),
    });
    const data = await resp.json();

    if (data.success) {
      if (editingPostId && String(editingPostId) === String(postId)) resetPostForm();
      if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('success');
      await fetchMyPosts();
    } else {
      alert(data.message || "O'chirishda xatolik");
      if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('error');
    }
  } catch (e) {
    console.error('Delete error:', e);
    alert("Tarmoq xatosi. Qayta urinib ko'ring.");
    if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('error');
  }
}

// ===========================================
// HOW IT WORKS — COLLAPSIBLE
// ===========================================
hiwHeader.addEventListener('click', () => {
  const isOpen = hiwBody.classList.toggle('open');
  hiwToggle.classList.toggle('open', isOpen);
  if (tg.HapticFeedback) tg.HapticFeedback.selectionChanged();
});

// ===========================================
// BACK BUTTON — closes the sheet first, then leaves the page
// ===========================================
try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(() => {
      if (sheetOpen) { closeSheet(); return; }
      stopTimer();
      window.location.href = '../../index.html';
    });
  }
} catch (e) {}

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && sheetOpen) closeSheet();
});

// ===========================================
// EVENT LISTENERS
// ===========================================
getLinkBtn.addEventListener('click', requestInviteLink);
retryBtn.addEventListener('click', requestInviteLink);
errorRetryBtn.addEventListener('click', requestInviteLink);
copyLinkBtn.addEventListener('click', copyLink);
joinBtn.addEventListener('click', () => {});
postSubmitBtn.addEventListener('click', submitPost);

// Show hint when tapping the disabled submit button
postSubmitBtn.parentElement.addEventListener('click', (e) => {
  if (!postSubmitBtn.disabled) return;
  const hasMsg = postMessage.value.trim().length >= 10;
  const hasContact = (userHasUsername && !useManualContact) || postContact.value.trim().length >= 3;
  const hasCommission = !!getCommissionChoice();
  const agreed = editingPostId ? true : agreementCheckbox.checked;

  let hint = '';
  if (!hasMsg) hint = 'E\'lon matni kamida 10 belgi bo\'lishi kerak';
  else if (!hasContact) hint = 'Bog\'lanish uchun kontakt ma\'lumotini kiriting';
  else if (!hasCommission) hint = 'Komissiya turini tanlang 💰';
  else if (!agreed) hint = 'Qoidalarga rozilik belgisini qo\'ying ☑️';

  if (hint) showSubmitHint(hint);
});

function showSubmitHint(text) {
  const old = document.querySelector('.submit-hint');
  if (old) { old.textContent = text; return; }

  const hint = document.createElement('div');
  hint.className = 'submit-hint';
  hint.textContent = text;
  postSubmitBtn.insertAdjacentElement('afterend', hint);

  if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('warning');

  setTimeout(() => hint.classList.add('visible'), 10);
}
postAgainBtn.addEventListener('click', resetPostForm);
postErrorRetryBtn.addEventListener('click', () => showPostState('form'));

// ===========================================
// INIT
// ===========================================
function initPage() {
  showState('initial');
  showPostState('form');
  initContactField();
  updateCommissionUI();
  updateBadge();
  fetchMyPosts();
  console.log('✅ Job Group page loaded');
}
document.addEventListener('DOMContentLoaded', initPage);
window.addEventListener('beforeunload', () => stopTimer());
