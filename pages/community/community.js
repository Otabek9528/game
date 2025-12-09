// community.js - Community page functionality with I18N support

// ===========================================
// I18N HELPER
// ===========================================

function t(key, fallback) {
  if (window.I18N) {
    const trans = I18N.t(key);
    return trans !== key ? trans : fallback;
  }
  return fallback;
}

// ===========================================
// TELEGRAM WEBAPP INITIALIZATION
// ===========================================

const tg = window.Telegram.WebApp;
tg.ready();

// Disable vertical swipes for better UX
try {
  tg.disableVerticalSwipes();
} catch (e) {
  console.log('disableVerticalSwipes not available');
}

// Expand the WebApp to full height
try {
  tg.expand();
} catch (e) {
  console.log('expand not available');
}

// ===========================================
// BACK BUTTON HANDLING
// ===========================================

try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(() => {
      window.location.href = "../../index.html";
    });
  }
} catch (e) {
  console.log('BackButton not available');
}

// ===========================================
// I18N UI UPDATE
// ===========================================

function updateUITranslations() {
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (window.I18N) {
      const trans = I18N.t(key);
      if (trans !== key) {
        // Preserve HTML structure for items with <strong> tags
        if (trans.includes('<strong>') || trans.includes('</strong>')) {
          el.innerHTML = trans;
        } else {
          el.textContent = trans;
        }
      }
    }
  });
  
  // Update page title
  document.title = t('community.pageTitle', 'Jamoa - Telegram Guruh');
}

// Listen for language changes
window.addEventListener('languageChanged', () => {
  updateUITranslations();
});

// ===========================================
// HAPTIC FEEDBACK ON BUTTON CLICKS
// ===========================================

function addHapticFeedback() {
  // Add haptic feedback to all buttons and links
  const interactiveElements = document.querySelectorAll('button, a.join-group-btn, a.cta-btn');
  
  interactiveElements.forEach(element => {
    element.addEventListener('click', () => {
      try {
        if (tg.HapticFeedback) {
          tg.HapticFeedback.impactOccurred('light');
        }
      } catch (e) {
        // Haptic feedback not available
      }
    });
  });
}

// ===========================================
// SMOOTH SCROLL TO SECTIONS
// ===========================================

function smoothScrollToTop() {
  window.scrollTo({
    top: 0,
    behavior: 'smooth'
  });
}

// ===========================================
// ANIMATION ON SCROLL (INTERSECTION OBSERVER)
// ===========================================

function initScrollAnimations() {
  const observerOptions = {
    root: null,
    rootMargin: '0px',
    threshold: 0.1
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('animate-in');
        observer.unobserve(entry.target);
      }
    });
  }, observerOptions);

  // Observe all info sections
  const sections = document.querySelectorAll('.info-section, .telegram-card, .penalty-card, .cta-section');
  sections.forEach(section => {
    section.classList.add('animate-ready');
    observer.observe(section);
  });
}

// ===========================================
// ADD CSS FOR ANIMATIONS
// ===========================================

function injectAnimationStyles() {
  const style = document.createElement('style');
  style.textContent = `
    .animate-ready {
      opacity: 0;
      transform: translateY(20px);
      transition: opacity 0.5s ease-out, transform 0.5s ease-out;
    }
    
    .animate-in {
      opacity: 1;
      transform: translateY(0);
    }
    
    /* Staggered animation delays */
    .info-section:nth-child(1) { transition-delay: 0.1s; }
    .info-section:nth-child(2) { transition-delay: 0.2s; }
    .info-section:nth-child(3) { transition-delay: 0.3s; }
    .penalty-card { transition-delay: 0.4s; }
    .cta-section { transition-delay: 0.5s; }
  `;
  document.head.appendChild(style);
}

// ===========================================
// COPY GROUP LINK (OPTIONAL FEATURE)
// ===========================================

const GROUP_LINK = 'https://t.me/MuslimVegukin';

async function copyGroupLink() {
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(GROUP_LINK);
    } else {
      // Fallback for older browsers
      const textarea = document.createElement('textarea');
      textarea.value = GROUP_LINK;
      textarea.style.position = 'fixed';
      textarea.style.opacity = '0';
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
    }
    
    // Haptic feedback
    if (tg.HapticFeedback) {
      tg.HapticFeedback.notificationOccurred('success');
    }
    
    // Show native popup if available
    if (tg.showAlert) {
      tg.showAlert(t('community.linkCopied', 'Link nusxa olindi! ✅'));
    }
    
    return true;
  } catch (err) {
    console.error('Copy failed:', err);
    return false;
  }
}

// ===========================================
// TRACK JOIN BUTTON CLICK (ANALYTICS)
// ===========================================

function trackJoinClick() {
  // You can add analytics tracking here if needed
  console.log('📊 User clicked join group button');
  
  // Send event to Telegram if needed
  try {
    if (tg.sendData) {
      // Optional: send data back to bot
      // tg.sendData(JSON.stringify({ action: 'join_community_click' }));
    }
  } catch (e) {
    // sendData not available
  }
}

// Add click tracking to join buttons
function initClickTracking() {
  const joinButtons = document.querySelectorAll('a[href*="t.me/MuslimVegukin"]');
  joinButtons.forEach(btn => {
    btn.addEventListener('click', trackJoinClick);
  });
}

// ===========================================
// INITIALIZATION
// ===========================================

function initCommunityPage() {
  // Update UI translations
  updateUITranslations();
  
  // Inject animation styles
  injectAnimationStyles();
  
  // Initialize scroll animations
  initScrollAnimations();
  
  // Add haptic feedback
  addHapticFeedback();
  
  // Initialize click tracking
  initClickTracking();
  
  // Scroll to top on load
  smoothScrollToTop();
  
  console.log('✅ Community page loaded with I18N');
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', initCommunityPage);

// Export functions for potential external use
window.CommunityPage = {
  copyGroupLink,
  GROUP_LINK
};
