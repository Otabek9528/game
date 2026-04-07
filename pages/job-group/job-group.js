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
// DUMMY DATA
// ===========================================
let myPosts = [
  {
    id: 'd1',
    text: "Restoranga oshpaz kerak\n📍 Manzil: Gangnam, Seoul\n👥 2 kishi\n🕐 09:00 – 18:00\n💰 Maosh: 170,000 won",
    contact: '@poster_user',
    status: 'available',
    created_at: Date.now() - 2 * 60 * 60 * 1000,
    reserved_at: null,
  },
  {
    id: 'd2',
    text: "Omborga yukchi kerak\n📍 Manzil: Bucheon\n👥 5 kishi\n🕐 20:00 – 06:00\n💰 Maosh: 150,000 won\n📋 Og'ir yuk ko'tara olishi kerak",
    contact: '010-1234-5678',
    status: 'reserved',
    created_at: Date.now() - 5 * 60 * 60 * 1000,
    reserved_at: Date.now() - 4 * 60 * 60 * 1000,
  },
  {
    id: 'd3',
    text: "Qurilish ishiga ishchi kerak\n📍 Manzil: Incheon\n👥 3 kishi\n🕐 08:00 – 17:00\n💰 Maosh: 180,000 won",
    contact: '@builder_bek',
    status: 'finished',
    created_at: Date.now() - 26 * 60 * 60 * 1000,
    reserved_at: Date.now() - 24 * 60 * 60 * 1000,
  },
];

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
    renderMyPosts();
  }
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
    contactLabel.innerHTML = 'Aloqa <span class="optional-tag" style="color:#e65100;font-weight:600;">majburiy</span>';
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
  postSubmitBtn.disabled = !(hasMsg && hasContact);
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
      // Add to local list (dummy — in prod this comes from server)
      myPosts.unshift({ id: 'p' + Date.now(), text: message, contact, status: 'available', created_at: Date.now(), reserved_at: null });
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
  postSubmitBtn.disabled = true; useManualContact = false; initContactField();
  showPostState('form');
}

// ===========================================
// MY POSTS — RENDERING
// ===========================================
function timeAgo(ts) {
  const diff = Math.floor((Date.now() - ts) / 1000);
  if (diff < 60) return 'hozirgina';
  if (diff < 3600) return Math.floor(diff / 60) + ' daq. oldin';
  if (diff < 86400) return Math.floor(diff / 3600) + ' soat oldin';
  return Math.floor(diff / 86400) + ' kun oldin';
}

function canFinish(post) {
  if (post.status !== 'reserved' || !post.reserved_at) return false;
  return (Date.now() - post.reserved_at) >= FINISH_DELAY_MS;
}

function finishTimeLeft(post) {
  if (!post.reserved_at) return '';
  const remaining = FINISH_DELAY_MS - (Date.now() - post.reserved_at);
  if (remaining <= 0) return '';
  const h = Math.floor(remaining / 3600000);
  const m = Math.floor((remaining % 3600000) / 60000);
  return `${h} soat ${m} daq. qoldi`;
}

function updateBadge() {
  const active = myPosts.filter(p => p.status !== 'finished').length;
  myPostsBadge.textContent = myPosts.length;
  const tickets = myPosts.filter(p => p.status === 'finished').length;
  lotteryTickets.textContent = `Sizda: ${tickets} ta chipta`;
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
      actions = `<button class="post-action-btn reserve" onclick="confirmAction('${post.id}','reserve')">🟡 Band qilish</button>`;
    } else if (post.status === 'reserved') {
      const can = canFinish(post);
      const hint = can ? '' : `<div class="finish-hint">⏳ Yakunlash uchun: ${finishTimeLeft(post)}</div>`;
      actions = `
        <button class="post-action-btn reopen" onclick="confirmAction('${post.id}','reopen')">↩️ Faol qilish</button>
        <button class="post-action-btn finish" ${can ? '' : 'disabled'} onclick="confirmAction('${post.id}','finish')">✅ Yakunlash</button>
      `;
      if (!can) actions += hint;
    } else {
      actions = `<div class="ticket-earned">🎟 Lotereya chiptagiga qo'shildi</div>`;
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
    finish: { title: 'Yakunlash', text: 'Ish bajarildi deb belgilamoqchimisiz? Bu qaytarib bo\'lmaydi va lotereya chiptasi beriladi.' },
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

function executeAction(postId, action) {
  const post = myPosts.find(p => p.id === postId);
  if (!post) return;

  if (action === 'reserve' && post.status === 'available') {
    post.status = 'reserved';
    post.reserved_at = Date.now();
  } else if (action === 'reopen' && post.status === 'reserved') {
    post.status = 'available';
    post.reserved_at = null;
  } else if (action === 'finish' && post.status === 'reserved' && canFinish(post)) {
    post.status = 'finished';
  }

  if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('success');
  renderMyPosts();

  // TODO: API call to update status on server
}

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
