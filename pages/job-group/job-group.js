// job-group.js - Job Group: Join + Post + My Posts

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

// ===========================================
// DOM — TABS
// ===========================================
const tabBtns = document.querySelectorAll('.tab-btn');
const tabSwipeTrack = document.getElementById('tabSwipeTrack');
const tabSwipeContainer = document.getElementById('tabSwipeContainer');

// DOM — TAB 1
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

// DOM — TAB 2
const subnavFormBtn = document.getElementById('subnavFormBtn');
const subnavMyPostsBtn = document.getElementById('subnavMyPostsBtn');
const postFormView = document.getElementById('postFormView');
const myPostsView = document.getElementById('myPostsView');
const myPostsBadge = document.getElementById('myPostsBadge');
const myPostsList = document.getElementById('myPostsList');
const emptyPosts = document.getElementById('emptyPosts');
const lotteryTickets = document.getElementById('lotteryTickets');

const postFormState = document.getElementById('postFormState');
const postLoadingState = document.getElementById('postLoadingState');
const postSuccessState = document.getElementById('postSuccessState');
const postErrorState = document.getElementById('postErrorState');
const postMessage = document.getElementById('postMessage');
const postContact = document.getElementById('postContact');
const charCount = document.getElementById('charCount');
const postSubmitBtn = document.getElementById('postSubmitBtn');
const postAgainBtn = document.getElementById('postAgainBtn');
const viewPostsBtn = document.getElementById('viewPostsBtn');
const postErrorRetryBtn = document.getElementById('postErrorRetryBtn');
const postErrorText = document.getElementById('postErrorText');

const contactAuto = document.getElementById('contactAuto');
const contactManual = document.getElementById('contactManual');
const contactUsername = document.getElementById('contactUsername');
const contactLabel = document.getElementById('contactLabel');
const contactToggleBtn = document.getElementById('contactToggleBtn');
const contactBackBtn = document.getElementById('contactBackBtn');
const agreementCheckbox = document.getElementById('agreementCheckbox');

// ===========================================
// STATE
// ===========================================
let currentLink = null;
let timerInterval = null;
let timeRemaining = LINK_DURATION;
let userHasUsername = false;
let telegramUsername = null;
let useManualContact = false;
let activeTab = 0;

// ===========================================
// POSTS DATA (loaded from API)
// ===========================================
let myPosts = [];

function getUserId() {
  return tg.initDataUnsafe?.user?.id;
}

// ===========================================
// TAB SWITCHING + SWIPE
// ===========================================
function switchTab(index) {
  activeTab = index;
  tabSwipeTrack.style.transform = `translateX(-${index * 50}%)`;
  tabBtns.forEach((b, i) => b.classList.toggle('active', i === index));
  if (tg.HapticFeedback) tg.HapticFeedback.selectionChanged();
}

tabBtns.forEach((btn, i) => btn.addEventListener('click', () => switchTab(i)));

let swipeStartX = 0, swipeStartY = 0, swiping = false, swipeDeltaX = 0;
tabSwipeContainer.addEventListener('touchstart', (e) => {
  swipeStartX = e.touches[0].clientX; swipeStartY = e.touches[0].clientY;
  swiping = false; swipeDeltaX = 0;
}, { passive: true });

tabSwipeContainer.addEventListener('touchmove', (e) => {
  const dx = e.touches[0].clientX - swipeStartX;
  const dy = e.touches[0].clientY - swipeStartY;
  if (!swiping && Math.abs(dx) > 10 && Math.abs(dx) > Math.abs(dy) * 1.5) {
    swiping = true; tabSwipeTrack.classList.add('no-transition');
  }
  if (swiping) {
    e.preventDefault(); swipeDeltaX = dx;
    const pctDelta = (dx / tabSwipeContainer.offsetWidth) * 50;
    const clamped = Math.max(-50, Math.min(0, -(activeTab * 50) + pctDelta));
    tabSwipeTrack.style.transform = `translateX(${clamped}%)`;
  }
}, { passive: false });

tabSwipeContainer.addEventListener('touchend', () => {
  if (!swiping) return;
  tabSwipeTrack.classList.remove('no-transition');
  const threshold = tabSwipeContainer.offsetWidth * 0.2;
  if (swipeDeltaX < -threshold && activeTab === 0) switchTab(1);
  else if (swipeDeltaX > threshold && activeTab === 1) switchTab(0);
  else tabSwipeTrack.style.transform = `translateX(-${activeTab * 50}%)`;
  swiping = false; swipeDeltaX = 0;
}, { passive: true });

// ===========================================
// TAB 2 — SUB-NAV
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
        created_at: p.created_at,
        reserved_at: p.reserved_at,
        finished_at: p.finished_at,
      }));
      lotteryTickets.textContent = `Sizda: ${data.lottery_tickets} ta chipta`;
    }
  } catch (e) {
    console.error('Failed to fetch posts:', e);
  }
  renderMyPosts();
}

subnavFormBtn.addEventListener('click', () => showSubView('form'));
subnavMyPostsBtn.addEventListener('click', () => showSubView('myPosts'));
viewPostsBtn.addEventListener('click', () => showSubView('myPosts'));

// ===========================================
// TAB 1 — STATE MANAGEMENT
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
// TAB 1 — API
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
// TAB 2 — CONTACT FIELD
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
    contactLabel.innerHTML = 'Bog\'lanish uchun kontakt: <span class="optional-tag" style="color:#e65100;font-weight:600;">majburiy</span>';
    postContact.placeholder = 'Tel raqam yoki Telegram username kiriting';
  }
}
contactToggleBtn.addEventListener('click', () => {
  useManualContact = true; contactAuto.style.display = 'none';
  contactManual.style.display = 'block'; contactBackBtn.style.display = 'flex';
  postContact.focus(); validateForm();
});
contactBackBtn.addEventListener('click', () => {
  useManualContact = false; contactAuto.style.display = 'block';
  contactManual.style.display = 'none'; postContact.value = ''; validateForm();
});

// ===========================================
// TAB 2 — FORM VALIDATION
// ===========================================
function validateForm() {
  const hasMsg = postMessage.value.trim().length >= 10;
  const hasContact = (userHasUsername && !useManualContact) || postContact.value.trim().length >= 3;
  const agreed = agreementCheckbox.checked;
  postSubmitBtn.disabled = !(hasMsg && hasContact && agreed);
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
// TAB 2 — SUBMIT POST
// ===========================================
async function submitPost() {
  const message = postMessage.value.trim();
  if (message.length < 10) return;
  let contact = (userHasUsername && !useManualContact) ? '@' + telegramUsername : postContact.value.trim();
  if (!contact || contact.length < 3) return;
  const userId = tg.initDataUnsafe?.user?.id;
  const userName = tg.initDataUnsafe?.user?.first_name || '';
  showPostState('loading');
  try {
    if (!userId) throw new Error('Telegram foydalanuvchi ID topilmadi');
    const response = await fetch(`${API_BASE_URL}/api/group/post`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: userId, user_name: userName, message, contact }),
      signal: AbortSignal.timeout(15000)
    });
    if (!response.ok) { const d = await response.json().catch(() => ({})); throw new Error(d.message || `Server xatosi: ${response.status}`); }
    const data = await response.json();
    if (data.success) {
      updateBadge();
      showPostState('success');
      if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('success');
    } else throw new Error(data.message || "E'lon yuborishda xatolik");
  } catch (error) {
    postErrorText.textContent = error.message || "E'lon yuborishda xatolik yuz berdi";
    showPostState('error');
    if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('error');
  }
}

function resetPostForm() {
  postMessage.value = ''; postContact.value = '';
  charCount.textContent = '0 / 1000'; charCount.classList.remove('near-limit', 'at-limit');
  postSubmitBtn.disabled = true; useManualContact = false;
  agreementCheckbox.checked = false;
  initContactField();
  showPostState('form');
}

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
  const active = myPosts.filter(p => p.status !== 'finished').length;
  myPostsBadge.textContent = myPosts.length;
  const tickets = myPosts.filter(p => p.status === 'finished').length;
  if (lotteryTickets) lotteryTickets.textContent = `Sizda: ${data.lottery_tickets} ta chipta`;
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
    let actions = '';
    if (post.status === 'available') {
      actions = `<div class="my-post-actions-row"><button class="post-action-btn reserve" onclick="confirmAction('${post.id}','reserve')">🟡 Band qilish</button></div>`;
    } else if (post.status === 'reserved') {
      const can = canFinish(post);
      const hint = can ? '' : `<div class="finish-hint">⏳ Yakunlash uchun: ${finishTimeLeft(post)}</div>`;
      actions = `
        <div class="my-post-actions-row">
          <button class="post-action-btn reopen" onclick="confirmAction('${post.id}','reopen')">↩️ Faol qilish</button>
          <button class="post-action-btn finish" ${can ? '' : 'disabled'} onclick="confirmAction('${post.id}','finish')">✅ Yakunlash</button>
        </div>
        ${hint}
      `;
    } else {
      actions = `<div class="ticket-earned">🎟 Lotereya chiptasiga qo'shildi</div>`;
    }

    return `
      <div class="my-post-card status-${post.status}">
        <div class="my-post-header">
          <span class="my-post-time">${timeAgo(post.created_at)}</span>
          <span class="status-badge ${post.status}">${statusLabels[post.status]}</span>
        </div>
        <div class="my-post-body">${escapeHtml(post.text)}</div>
        <div class="my-post-actions">${actions}</div>
      </div>
    `;
  }).join('');
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

// ===========================================
// CONFIRMATION MODAL
// ===========================================
function confirmAction(postId, action) {
  const messages = {
    reserve: { title: 'Band qilish', text: 'Ishchi topildimi? E\'lonni band sifatida belgilashni xohlaysizmi?' },
    reopen: { title: 'Qayta faollashtirish', text: 'E\'lonni qayta faol holatga o\'tkazmoqchimisiz?' },
    finish: { title: 'Yakunlash', text: 'Ish bajarildi deb belgilamoqchimisiz? Bu qaytarib bo\'lmaydi.' },
  };
  const msg = messages[action];

  const overlay = document.createElement('div');
  overlay.className = 'confirm-overlay';
  overlay.innerHTML = `
    <div class="confirm-box">
      <h3 class="confirm-title">${msg.title}</h3>
      <p class="confirm-text">${msg.text}</p>
      <div class="confirm-actions">
        <button class="confirm-btn cancel" id="confirmCancel">Bekor qilish</button>
        <button class="confirm-btn yes" id="confirmYes">Ha</button>
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

// ===========================================
// HOW IT WORKS — COLLAPSIBLE
// ===========================================
const hiwHeader = document.getElementById('hiwHeader');
const hiwBody = document.getElementById('hiwBody');
const hiwToggle = document.getElementById('hiwToggle');

hiwHeader.addEventListener('click', () => {
  const isOpen = hiwBody.classList.toggle('open');
  hiwToggle.classList.toggle('open', isOpen);
  if (tg.HapticFeedback) tg.HapticFeedback.selectionChanged();
});

// ===========================================
// BACK BUTTON
// ===========================================
try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(() => { stopTimer(); window.location.href = '../../index.html'; });
  }
} catch (e) {}

// ===========================================
// EVENT LISTENERS
// ===========================================
getLinkBtn.addEventListener('click', requestInviteLink);
retryBtn.addEventListener('click', requestInviteLink);
errorRetryBtn.addEventListener('click', requestInviteLink);
copyLinkBtn.addEventListener('click', copyLink);
joinBtn.addEventListener('click', () => {});
postSubmitBtn.addEventListener('click', submitPost);
postAgainBtn.addEventListener('click', resetPostForm);
postErrorRetryBtn.addEventListener('click', () => showPostState('form'));

// ===========================================
// INIT
// ===========================================
function initPage() {
  showState('initial');
  showPostState('form');
  initContactField();
  updateBadge();
  console.log('✅ Job Group page loaded');
}
document.addEventListener('DOMContentLoaded', initPage);
window.addEventListener('beforeunload', () => stopTimer());
