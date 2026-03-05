// job-group.js - Job & Taxi Group Invite Link functionality

const tg = window.Telegram.WebApp;
tg.ready();
tg.disableVerticalSwipes();

try {
  tg.expand();
} catch (e) {}

// ===========================================
// CONFIGURATION
// ===========================================

const API_BASE_URL = 'https://vegukin-api.duckdns.org';
const LINK_DURATION = 15; // seconds

// ===========================================
// DOM ELEMENTS
// ===========================================

const initialState = document.getElementById('initialState');
const loadingState = document.getElementById('loadingState');
const linkState = document.getElementById('linkState');
const expiredState = document.getElementById('expiredState');
const errorState = document.getElementById('errorState');

const getLinkBtn = document.getElementById('getLinkBtn');
const retryBtn = document.getElementById('retryBtn');
const errorRetryBtn = document.getElementById('errorRetryBtn');

const jobLinkText = document.getElementById('jobLinkText');
const taxiLinkText = document.getElementById('taxiLinkText');
const jobJoinBtn = document.getElementById('jobJoinBtn');
const taxiJoinBtn = document.getElementById('taxiJoinBtn');

const timerText = document.getElementById('timerText');
const timerProgress = document.getElementById('timerProgress');
const errorText = document.getElementById('errorText');

// ===========================================
// STATE
// ===========================================

let currentLinks = null;
let timerInterval = null;
let timeRemaining = LINK_DURATION;

// ===========================================
// UI STATE MANAGEMENT
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
// API FUNCTIONS
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
        user_id: userId,
        first_name: tg.initDataUnsafe?.user?.first_name || '',
        last_name: tg.initDataUnsafe?.user?.last_name || '',
        username: tg.initDataUnsafe?.user?.username || ''
      }),
      signal: AbortSignal.timeout(15000)
    });
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      
    if (errorData.error === 'trial_used') {
        // Show payment instructions instead of generic error
        document.getElementById('errorText').innerHTML = 
            "<strong>Sizning sinov muddatingiz tugagan.</strong><br><br>" +
            "Guruhlarga qayta qo'shilish uchun oylik obuna sotib oling:<br><br>" +
            "💰 <strong>5,900 won/oy</strong><br><br>" +
            "📌 To'lov ma'lumotlari:<br>" +
            "🏦 Bank: [BANK_NAME]<br>" +
            "💳 Hisob raqam: [ACCOUNT_NUMBER]<br>" +
            "👤 Egasi: [ACCOUNT_HOLDER]<br><br>" +
            "✅ To'lovni amalga oshirgach, skrinshotini " +
            "<a href='https://t.me/job_hunter_2bot' style='color:#00a884;font-weight:700;'>@job_hunter_acc</a>" +
            " ga yuboring.";
        showState('error');
        // Hide retry button since it won't help
        document.getElementById('errorRetryBtn').style.display = 'none';
        return;
    }
      
      throw new Error(errorData.message || `Server xatosi: ${response.status}`);
    }
    
    const data = await response.json();
    
    if (data.success) {
      currentLinks = {
        job: data.job_invite_link,
        taxi: data.taxi_invite_link
      };
      displayLinks(currentLinks);
    } else {
      throw new Error(data.message || 'Link yaratishda xatolik');
    }
    
  } catch (error) {
    console.error('Error requesting invite link:', error);
    showError(error.message || 'Link yaratishda xatolik yuz berdi');
  }
}

function displayLinks(links) {
  jobLinkText.textContent = links.job;
  jobJoinBtn.href = links.job;
  taxiLinkText.textContent = links.taxi;
  taxiJoinBtn.href = links.taxi;
  showState('link');
  startTimer();
  
  if (tg.HapticFeedback) {
    tg.HapticFeedback.notificationOccurred('success');
  }
}

function handleLinkExpired() {
  currentLinks = null;
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

function copyToClipboard(type) {
  if (!currentLinks) return;
  const link = type === 'job' ? currentLinks.job : currentLinks.taxi;
  
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(link).then(() => {
      if (tg.HapticFeedback) {
        tg.HapticFeedback.impactOccurred('light');
      }
    }).catch(err => console.error('Copy failed:', err));
  } else {
    const textarea = document.createElement('textarea');
    textarea.value = link;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
  }
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

getLinkBtn.addEventListener('click', requestInviteLink);
retryBtn.addEventListener('click', requestInviteLink);
errorRetryBtn.addEventListener('click', requestInviteLink);

// ===========================================
// INITIALIZATION
// ===========================================

function initPage() {
  showState('initial');
  console.log('✅ Job Group page loaded');
}

document.addEventListener('DOMContentLoaded', initPage);

window.addEventListener('beforeunload', () => {
  stopTimer();
});
