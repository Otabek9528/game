// donation.js - Donation page functionality with I18N support

// ============================================
// I18N HELPER
// ============================================

function t(key, fallback) {
  if (window.I18N) {
    const trans = I18N.t(key);
    return trans !== key ? trans : fallback;
  }
  return fallback;
}

// ============================================
// TELEGRAM WEBAPP INITIALIZATION
// ============================================

const tg = window.Telegram.WebApp;
tg.ready();
tg.disableVerticalSwipes();

try {
  tg.expand();
} catch (e) {}

// Setup back button
try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(() => {
      window.location.href = "../../index.html";
    });
  }
} catch (e) {}

// ============================================
// DOM ELEMENTS
// ============================================

const copyBtn = document.getElementById('copyBtn');
const copyIcon = document.getElementById('copyIcon');
const copyText = document.getElementById('copyText');
const accountNumber = document.getElementById('accountNumber');

// ============================================
// I18N UI UPDATE
// ============================================

function updateUITranslations() {
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (window.I18N) {
      const trans = I18N.t(key);
      if (trans !== key) {
        el.textContent = trans;
      }
    }
  });
  
  // Update page title
  document.title = t('donation.pageTitle', 'Xayriya - Loyihani Qo\'llab-Quvvatlash');
}

// Listen for language changes
window.addEventListener('languageChanged', () => {
  updateUITranslations();
});

// ============================================
// COPY FUNCTIONALITY
// ============================================

copyBtn.addEventListener('click', async () => {
  const textToCopy = accountNumber.textContent;
  
  // Get translated texts
  const copiedText = t('donation.copied', 'Nusxa olindi!');
  const copyDefaultText = t('donation.copy', 'Nusxa olish');
  const errorText = t('donation.copyError', 'Xatolik!');
  
  try {
    // Try modern clipboard API first
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(textToCopy);
    } else {
      // Fallback for older browsers
      const textarea = document.createElement('textarea');
      textarea.value = textToCopy;
      textarea.style.position = 'fixed';
      textarea.style.opacity = '0';
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
    }
    
    // Show success feedback
    copyIcon.textContent = '✅';
    copyText.textContent = copiedText;
    copyBtn.classList.add('copied');
    
    // Haptic feedback if available
    if (tg.HapticFeedback) {
      tg.HapticFeedback.notificationOccurred('success');
    }
    
    // Reset after 2 seconds
    setTimeout(() => {
      copyIcon.textContent = '📋';
      copyText.textContent = copyDefaultText;
      copyBtn.classList.remove('copied');
    }, 2000);
    
  } catch (err) {
    console.error('Copy failed:', err);
    
    // Show error feedback
    copyIcon.textContent = '❌';
    copyText.textContent = errorText;
    
    setTimeout(() => {
      copyIcon.textContent = '📋';
      copyText.textContent = copyDefaultText;
    }, 2000);
  }
});

// ============================================
// INITIALIZATION
// ============================================

document.addEventListener('DOMContentLoaded', () => {
  updateUITranslations();
});

console.log('✅ Donation page loaded with I18N');
