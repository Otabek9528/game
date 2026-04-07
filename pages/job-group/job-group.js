// job-group.js - Job Group: Join + Post functionality

const tg = window.Telegram.WebApp;
tg.ready();
tg.disableVerticalSwipes();

try {
  tg.expand();
} catch (e) {}

// ===========================================
// CONFIGURATION
// ===========================================

const API_BASE_URL = 'https://vegukin-api.duckdns.org/'; // Your API base URL
const LINK_DURATION = 15; // seconds

// ===========================================
// DOM ELEMENTS — TABS
// ===========================================

const tabBtns = document.querySelectorAll('.tab-btn');
const tabSwipeTrack = document.getElementById('tabSwipeTrack');
const tabSwipeContainer = document.getElementById('tabSwipeContainer');
const tabJoin = document.getElementById('tabJoin');
const tabPost = document.getElementById('tabPost');

// ===========================================
// DOM ELEMENTS — TAB 1 (JOIN)
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

// ===========================================
// DOM ELEMENTS — TAB 2 (POST)
// ===========================================

const postFormState = document.getElementById('postFormState');
const postLoadingState = document.getElementById('postLoadingState');
const postSuccessState = document.getElementById('postSuccessState');
const postErrorState = document.getElementById('postErrorState');

const postMessage = document.getElementById('postMessage');
const postContact = document.getElementById('postContact');
const charCount = document.getElementById('charCount');
const postSubmitBtn = document.getElementById('postSubmitBtn');
const postAgainBtn = document.getElementById('postAgainBtn');
const postErrorRetryBtn = document.getElementById('postErrorRetryBtn');
const postErrorText = document.getElementById('postErrorText');

// Contact elements
const contactAuto = document.getElementById('contactAuto');
const contactManual = document.getElementById('contactManual');
const contactUsername = document.getElementById('contactUsername');
const contactLabel = document.getElementById('contactLabel');
const contactToggleBtn = document.getElementById('contactToggleBtn');
const contactToggleText = document.getElementById('contactToggleText');
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
let activeTab = 0; // 0 = join, 1 = post

// ===========================================
// TAB SWITCHING + SWIPE
// ===========================================

function switchTab(index) {
  activeTab = index;
  tabSwipeTrack.style.transform = `translateX(-${index * 50}%)`;

  tabBtns.forEach((b, i) => {
    b.classList.toggle('active', i === index);
  });

  if (tg.HapticFeedback) {
    tg.HapticFeedback.selectionChanged();
  }
}

tabBtns.forEach((btn, i) => {
  btn.addEventListener('click', () => switchTab(i));
});

// --- Touch swipe ---
let swipeStartX = 0;
let swipeStartY = 0;
let swiping = false;
let swipeDeltaX = 0;

tabSwipeContainer.addEventListener('touchstart', (e) => {
  swipeStartX = e.touches[0].clientX;
  swipeStartY = e.touches[0].clientY;
  swiping = false;
  swipeDeltaX = 0;
}, { passive: true });

tabSwipeContainer.addEventListener('touchmove', (e) => {
  const dx = e.touches[0].clientX - swipeStartX;
  const dy = e.touches[0].clientY - swipeStartY;

  // Only start swiping if horizontal movement dominates
  if (!swiping && Math.abs(dx) > 10 && Math.abs(dx) > Math.abs(dy) * 1.5) {
    swiping = true;
    tabSwipeTrack.classList.add('no-transition');
  }

  if (swiping) {
    e.preventDefault();
    swipeDeltaX = dx;
    const baseOffset = activeTab * 50;
    // Convert px to % of container width
    const containerW = tabSwipeContainer.offsetWidth;
    const pctDelta = (dx / containerW) * 50;
    // Clamp so you can't over-scroll
    const raw = -baseOffset + pctDelta;
    const clamped = Math.max(-50, Math.min(0, raw));
    tabSwipeTrack.style.transform = `translateX(${clamped}%)`;
  }
}, { passive: false });

tabSwipeContainer.addEventListener('touchend', () => {
  if (!swiping) return;
  tabSwipeTrack.classList.remove('no-transition');

  const threshold = tabSwipeContainer.offsetWidth * 0.2;

  if (swipeDeltaX < -threshold && activeTab === 0) {
    switchTab(1);
  } else if (swipeDeltaX > threshold && activeTab === 1) {
    switchTab(0);
  } else {
    // Snap back
    tabSwipeTrack.style.transform = `translateX(-${activeTab * 50}%)`;
  }

  swiping = false;
  swipeDeltaX = 0;
}, { passive: true });

// ===========================================
// UI STATE MANAGEMENT — TAB 1 (JOIN)
// ===========================================

function showState(stateName) {
  initialState.style.display = 'none';
  loadingState.style.display = 'none';
  linkState.style.display = 'none';
  expiredState.style.display = 'none';
  errorState.style.display = 'none';
  
  switch(stateName) {
    case 'initial':
      initialState.style.display = 'block';
      break;
    case 'loading':
      loadingState.style.display = 'block';
      break;
    case 'link':
      linkState.style.display = 'block';
      break;
    case 'expired':
      expiredState.style.display = 'block';
      break;
    case 'error':
      errorState.style.display = 'block';
      break;
  }
}

// ===========================================
// UI STATE MANAGEMENT — TAB 2 (POST)
// ===========================================

function showPostState(stateName) {
  postFormState.style.display = 'none';
  postLoadingState.style.display = 'none';
  postSuccessState.style.display = 'none';
  postErrorState.style.display = 'none';

  switch(stateName) {
    case 'form':
      postFormState.style.display = 'block';
      break;
    case 'loading':
      postLoadingState.style.display = 'block';
      break;
    case 'success':
      postSuccessState.style.display = 'block';
      break;
    case 'error':
      postErrorState.style.display = 'block';
      break;
  }
}

// ===========================================
// TIMER FUNCTIONS
// ===========================================

function startTimer() {
  timeRemaining = LINK_DURATION;
  updateTimerDisplay();
  
  timerInterval = setInterval(() => {
    timeRemaining--;
    updateTimerDisplay();
    
    if (timeRemaining <= 0) {
      clearInterval(timerInterval);
      timerInterval = null;
      handleLinkExpired();
    }
  }, 1000);
}

function updateTimerDisplay() {
  timerText.textContent = timeRemaining;
  
  const progress = (timeRemaining / LINK_DURATION) * 283;
  timerProgress.style.strokeDashoffset = 283 - progress;
  
  timerText.classList.remove('warning', 'danger');
  timerProgress.classList.remove('warning', 'danger');
  
  if (timeRemaining <= 5) {
    timerText.classList.add('danger');
    timerProgress.classList.add('danger');
  } else if (timeRemaining <= 10) {
    timerText.classList.add('warning');
    timerProgress.classList.add('warning');
  }
}

function stopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }
}

// ===========================================
// API FUNCTIONS — TAB 1 (JOIN)
// ===========================================

async function requestInviteLink() {
  showState('loading');
  stopTimer();
  
  try {
    const userId = tg.initDataUnsafe?.user?.id;
    
    if (!userId) {
      throw new Error('Telegram foydalanuvchi ID topilmadi');
    }
    
    const response = await fetch(`${API_BASE_URL}/api/group/invite`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user_id: userId
      }),
      signal: AbortSignal.timeout(15000)
    });
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `Server xatosi: ${response.status}`);
    }
    
    const data = await response.json();
    
    if (data.success && data.invite_link) {
      currentLink = data.invite_link;
      displayLink(currentLink);
    } else {
      throw new Error(data.message || 'Link yaratishda xatolik');
    }
    
  } catch (error) {
    console.error('Error requesting invite link:', error);
    showError(error.message || 'Link yaratishda xatolik yuz berdi');
  }
}

function displayLink(link) {
  linkText.textContent = link;
  joinBtn.href = link;
  showState('link');
  startTimer();
  
  if (tg.HapticFeedback) {
    tg.HapticFeedback.notificationOccurred('success');
  }
}

function handleLinkExpired() {
  currentLink = null;
  showState('expired');
  
  if (tg.HapticFeedback) {
    tg.HapticFeedback.notificationOccurred('warning');
  }
}

function showError(message) {
  errorText.textContent = message;
  showState('error');
  
  if (tg.HapticFeedback) {
    tg.HapticFeedback.notificationOccurred('error');
  }
}

// ===========================================
// COPY FUNCTIONALITY
// ===========================================

async function copyLink() {
  if (!currentLink) return;
  
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(currentLink);
    } else {
      const textarea = document.createElement('textarea');
      textarea.value = currentLink;
      textarea.style.position = 'fixed';
      textarea.style.opacity = '0';
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
    }
    
    copyIcon.textContent = '✅';
    
    if (tg.HapticFeedback) {
      tg.HapticFeedback.impactOccurred('light');
    }
    
    setTimeout(() => {
      copyIcon.textContent = '📋';
    }, 1500);
    
  } catch (err) {
    console.error('Copy failed:', err);
    copyIcon.textContent = '❌';
    setTimeout(() => {
      copyIcon.textContent = '📋';
    }, 1500);
  }
}

// ===========================================
// POST FORM LOGIC (TAB 2)
// ===========================================

// --- Contact field setup ---
function initContactField() {
  const user = tg.initDataUnsafe?.user;
  telegramUsername = user?.username || null;
  userHasUsername = !!telegramUsername;

  if (userHasUsername) {
    // User has a Telegram username — show it pre-filled
    contactUsername.textContent = telegramUsername;
    contactAuto.style.display = 'block';
    contactManual.style.display = 'none';
    contactBackBtn.style.display = 'none';
    useManualContact = false;
  } else {
    // No username — show manual input as required
    contactAuto.style.display = 'none';
    contactManual.style.display = 'block';
    contactLabel.innerHTML = 'Aloqa <span class="optional-tag" style="color:#e65100; font-weight:600;">majburiy</span>';
    postContact.placeholder = 'Tel raqam yoki Telegram username kiriting';
  }
}

// Toggle: switch from username to manual phone input
contactToggleBtn.addEventListener('click', () => {
  useManualContact = true;
  contactAuto.style.display = 'none';
  contactManual.style.display = 'block';
  contactBackBtn.style.display = 'flex';
  postContact.focus();
  validateForm();
});

// Toggle back: switch from manual back to username
contactBackBtn.addEventListener('click', () => {
  useManualContact = false;
  contactAuto.style.display = 'block';
  contactManual.style.display = 'none';
  postContact.value = '';
  validateForm();
});

// --- Form validation ---
function validateForm() {
  const msgLen = postMessage.value.trim().length;
  const hasMessage = msgLen >= 10;

  let hasContact = false;
  if (userHasUsername && !useManualContact) {
    // Using Telegram username — always valid
    hasContact = true;
  } else {
    // Manual input required
    hasContact = postContact.value.trim().length >= 3;
  }

  postSubmitBtn.disabled = !(hasMessage && hasContact);
}

// Character counter + validation
postMessage.addEventListener('input', () => {
  const len = postMessage.value.length;
  charCount.textContent = `${len} / 1000`;

  charCount.classList.remove('near-limit', 'at-limit');
  if (len >= 1000) {
    charCount.classList.add('at-limit');
  } else if (len >= 800) {
    charCount.classList.add('near-limit');
  }

  validateForm();
});

// Contact input validation
postContact.addEventListener('input', validateForm);

// --- Submit post ---
async function submitPost() {
  const message = postMessage.value.trim();
  if (message.length < 10) return;

  // Determine contact value
  let contact;
  if (userHasUsername && !useManualContact) {
    contact = '@' + telegramUsername;
  } else {
    contact = postContact.value.trim();
    if (contact.length < 3) return;
  }

  const userId = tg.initDataUnsafe?.user?.id;
  const userName = tg.initDataUnsafe?.user?.first_name || '';

  showPostState('loading');

  try {
    if (!userId) {
      throw new Error('Telegram foydalanuvchi ID topilmadi');
    }

    // TODO: Replace with actual API call when backend is ready
    const response = await fetch(`${API_BASE_URL}/api/group/post`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user_id: userId,
        user_name: userName,
        message: message,
        contact: contact
      }),
      signal: AbortSignal.timeout(15000)
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `Server xatosi: ${response.status}`);
    }

    const data = await response.json();

    if (data.success) {
      showPostState('success');
      if (tg.HapticFeedback) {
        tg.HapticFeedback.notificationOccurred('success');
      }
    } else {
      throw new Error(data.message || "E'lon yuborishda xatolik");
    }

  } catch (error) {
    console.error('Error submitting post:', error);
    postErrorText.textContent = error.message || "E'lon yuborishda xatolik yuz berdi";
    showPostState('error');
    if (tg.HapticFeedback) {
      tg.HapticFeedback.notificationOccurred('error');
    }
  }
}

// Reset form and go back to form state
function resetPostForm() {
  postMessage.value = '';
  postContact.value = '';
  charCount.textContent = '0 / 1000';
  charCount.classList.remove('near-limit', 'at-limit');
  postSubmitBtn.disabled = true;
  useManualContact = false;
  initContactField();
  showPostState('form');
}

// ===========================================
// BACK BUTTON
// ===========================================

try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(() => {
      stopTimer();
      window.location.href = "../../index.html";
    });
  }
} catch (e) {}

// ===========================================
// EVENT LISTENERS
// ===========================================

// Tab 1
getLinkBtn.addEventListener('click', requestInviteLink);
retryBtn.addEventListener('click', requestInviteLink);
errorRetryBtn.addEventListener('click', requestInviteLink);
copyLinkBtn.addEventListener('click', copyLink);

joinBtn.addEventListener('click', () => {
  // Let the link open; server handles revocation
});

// Tab 2
postSubmitBtn.addEventListener('click', submitPost);
postAgainBtn.addEventListener('click', resetPostForm);
postErrorRetryBtn.addEventListener('click', () => {
  showPostState('form');
});

// ===========================================
// INITIALIZATION
// ===========================================

function initPage() {
  showState('initial');
  showPostState('form');
  initContactField();
  console.log('✅ Job Group page loaded');
}

document.addEventListener('DOMContentLoaded', initPage);

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  stopTimer();
});
