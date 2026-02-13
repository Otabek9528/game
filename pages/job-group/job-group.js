// job-group.js - Job Group Invite Link functionality

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
const joinBtn = document.getElementById('joinBtn');
const copyLinkBtn = document.getElementById('copyLinkBtn');

const linkText = document.getElementById('linkText');
const timerText = document.getElementById('timerText');
const timerProgress = document.getElementById('timerProgress');
const copyIcon = document.getElementById('copyIcon');
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
  // Hide all states
  initialState.style.display = 'none';
  loadingState.style.display = 'none';
  linkState.style.display = 'none';
  expiredState.style.display = 'none';
  errorState.style.display = 'none';
  
  // Show requested state
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
  // Update text
  timerText.textContent = timeRemaining;
  
  // Update progress circle (283 is circumference of circle with r=45)
  const progress = (timeRemaining / LINK_DURATION) * 283;
  timerProgress.style.strokeDashoffset = 283 - progress;
  
  // Update colors based on time remaining
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
    // Get user ID from Telegram WebApp
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
      signal: AbortSignal.timeout(15000) // 15 second timeout
    });
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
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
    alert('Error: ' + error.message);  // Add this line temporarily
    showError(error.message || 'Link yaratishda xatolik yuz berdi');
  }
}

function displayLinks(links) {
  document.getElementById('jobLinkText').textContent = links.job;
  document.getElementById('jobJoinBtn').href = links.job;
  document.getElementById('taxiLinkText').textContent = links.taxi;
  document.getElementById('taxiJoinBtn').href = links.taxi;
  showState('link');
  startTimer();
  if (tg.HapticFeedback) tg.HapticFeedback.notificationOccurred('success');
}

function copyToClipboard(type) {
  if (!currentLinks) return;
  const link = type === 'job' ? currentLinks.job : currentLinks.taxi;
  navigator.clipboard.writeText(link).then(() => {
    if (tg.HapticFeedback) tg.HapticFeedback.impactOccurred('light');
  }).catch(err => console.error('Copy failed:', err));
}

function handleLinkExpired() {
  currentLinks = null;
  showState('expired');
  
  // Haptic feedback
  if (tg.HapticFeedback) {
    tg.HapticFeedback.notificationOccurred('warning');
  }
}

function showError(message) {
  errorText.textContent = message;
  showState('error');
  
  // Haptic feedback
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
      // Fallback
      const textarea = document.createElement('textarea');
      textarea.value = currentLink;
      textarea.style.position = 'fixed';
      textarea.style.opacity = '0';
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
    }
    
    // Show success feedback
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
copyLinkBtn.addEventListener('click', copyLink);

// Handle join button click - stop timer since user is joining
joinBtn.addEventListener('click', () => {
  // Don't stop timer - let it continue in case user comes back
  // The server will handle link revocation on use
});

// ===========================================
// INITIALIZATION
// ===========================================

function initPage() {
  showState('initial');
  console.log('✅ Job Group page loaded');
}

document.addEventListener('DOMContentLoaded', initPage);

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  stopTimer();
});