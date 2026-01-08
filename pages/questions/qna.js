// qna.js - Q&A page functionality with real API
// Location: pages/qna/qna.js

const tg = window.Telegram.WebApp;
tg.ready();
tg.disableVerticalSwipes();

try {
  tg.expand();
} catch (e) {}

// ===========================================
// API CONFIGURATION
// ===========================================

// Base URL for API calls - Your AWS server
const API_BASE_URL = 'https://vegukin-api.duckdns.org';

// API Endpoints
const API = {
  search: `${API_BASE_URL}/api/questions/search`,
  browse: `${API_BASE_URL}/api/questions/browse`,
  detail: (id) => `${API_BASE_URL}/api/questions/${id}`,
  stats: `${API_BASE_URL}/api/questions/stats`,
  health: `${API_BASE_URL}/api/questions/health`
};

// ===========================================
// STATE MANAGEMENT
// ===========================================

let currentView = 'browse'; // 'browse' | 'results'
let currentQuestions = [];
let displayedCount = 10;
let searchResults = [];
let currentQuestion = null;

// ===========================================
// DOM ELEMENTS
// ===========================================

const searchInput = document.getElementById('searchInput');
const searchBtn = document.getElementById('searchBtn');
const browseSection = document.getElementById('browseSection');
const resultsSection = document.getElementById('resultsSection');
const answerModal = document.getElementById('answerModal');
const loadingOverlay = document.getElementById('loadingOverlay');
const questionCards = document.getElementById('questionCards');
const refreshBtn = document.getElementById('refreshBtn');
const loadMoreBtn = document.getElementById('loadMoreBtn');
const backToSearchBtn = document.getElementById('backToSearchBtn');
const modalClose = document.getElementById('modalClose');
const modalOverlay = document.getElementById('modalOverlay');
const resultsCards = document.getElementById('resultsCards');

// ===========================================
// API FUNCTIONS
// ===========================================

async function fetchBrowseQuestions(limit = 15) {
  try {
    const response = await fetch(`${API.browse}?limit=${limit}`);
    const data = await response.json();
    
    if (data.success) {
      return data.questions;
    } else {
      console.error('Browse API error:', data.error);
      return [];
    }
  } catch (error) {
    console.error('Failed to fetch browse questions:', error);
    return [];
  }
}

async function searchQuestionsAPI(query, limit = 10) {
  try {
    // Get Telegram user info if available
    const userId = tg.initDataUnsafe?.user?.id || 'anonymous';
    const username = tg.initDataUnsafe?.user?.username || 'unknown';
    
    const response = await fetch(API.search, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ 
        query, 
        limit,
        user_id: userId,
        username: username
      })
    });
    const data = await response.json();
    
    if (data.success) {
      console.log(`Search completed: ${data.count} results, alphabet: ${data.alphabet}`);
      return data.questions;
    } else {
      console.error('Search API error:', data.error);
      return [];
    }
  } catch (error) {
    console.error('Failed to search questions:', error);
    return [];
  }
}

async function fetchQuestionDetail(questionId) {
  try {
    const response = await fetch(API.detail(questionId));
    const data = await response.json();
    
    if (data.success) {
      return data;
    } else {
      console.error('Detail API error:', data.error);
      return null;
    }
  } catch (error) {
    console.error('Failed to fetch question detail:', error);
    return null;
  }
}

// ===========================================
// ALPHABET AUTO-DETECTION (for display purposes)
// ===========================================

function detectAlphabet(text) {
  const cyrillicPattern = /[\u0400-\u04FF\u0401\u0451\u040E\u045E\u049A\u049B\u04A2\u04A3\u04B0\u04B1\u04D8\u04D9]/;
  return cyrillicPattern.test(text) ? 'cyrillic' : 'latin';
}

// ===========================================
// UTILITY FUNCTIONS
// ===========================================

function showLoading() {
  loadingOverlay.style.display = 'flex';
}

function hideLoading() {
  loadingOverlay.style.display = 'none';
}

function formatViews(views) {
  if (!views) return '';
  if (views >= 1000) {
    return `${(views / 1000).toFixed(1)}k`;
  }
  return views.toString();
}

// ===========================================
// RENDER FUNCTIONS
// ===========================================

function renderQuestionCard(question, container) {
  const card = document.createElement('div');
  card.className = 'question-card';
  card.style.animationDelay = `${Math.random() * 0.2}s`;
  
  // Build view count HTML only if available
  const viewCountHtml = question.views 
    ? `<span class="view-count">👁️ ${formatViews(question.views)}</span>` 
    : '';
  
  // Only show scholar section if answerSource exists
  const scholarHtml = question.answerSource 
    ? `<div class="card-scholar">
        <span class="scholar-icon">📚</span>
        <span>${question.answerSource}</span>
      </div>`
    : '';

  card.innerHTML = `
    <div class="card-header">
      <span class="topic-badge">${question.topic || '📚 Boshqa'}</span>
      ${viewCountHtml}
    </div>
    <h3 class="card-title">${question.title}</h3>
    ${scholarHtml}
    <div class="card-action">
      <span class="read-more">Ko'rish →</span>
    </div>
  `;
  
  card.addEventListener('click', () => {
    openAnswerModal(question);
  });
  
  container.appendChild(card);
}

function renderBrowseQuestions() {
  questionCards.innerHTML = '';
  
  const questionsToShow = currentQuestions.slice(0, displayedCount);
  questionsToShow.forEach(q => renderQuestionCard(q, questionCards));
  
  // Show/hide load more button
  if (displayedCount >= currentQuestions.length) {
    loadMoreBtn.style.display = 'none';
  } else {
    loadMoreBtn.style.display = 'flex';
  }
}

function renderSearchResults() {
  resultsCards.innerHTML = '';
  
  if (searchResults.length === 0) {
    resultsCards.innerHTML = `
      <div style="text-align: center; padding: 40px 20px;">
        <p style="font-size: 3rem; margin-bottom: 12px;">😔</p>
        <p style="font-size: 1.1rem; font-weight: 600; color: var(--text-secondary); margin-bottom: 8px;">
          Ҳеч қандай натижа топилмади
        </p>
        <p style="font-size: 0.9rem; color: var(--text-muted);">
          Илтимос, бошқа сўз билан қидиринг
        </p>
      </div>
    `;
    return;
  }
  
  document.getElementById('resultsCount').textContent = searchResults.length;
  searchResults.forEach(q => renderQuestionCard(q, resultsCards));
}

// ===========================================
// MODAL FUNCTIONS
// ===========================================

async function openAnswerModal(question) {
  currentQuestion = question;
  
  // Populate modal content with what we have
  document.getElementById('modalCategory').textContent = question.topic || '📚 Boshqa';
  document.getElementById('questionTitle').textContent = question.title;
  document.getElementById('questionBody').textContent = question.questionBody || '';
  // Only show source if available
  const sourceText = question.answerSource || '';
  document.getElementById('answerSource').querySelector('.source-text').textContent = sourceText;
  
  // Hide source section if no answerSource
  const answerSourceEl = document.getElementById('answerSource');
  answerSourceEl.style.display = sourceText ? 'flex' : 'none';
  document.getElementById('answerBody').textContent = question.answerBody || '';
  document.getElementById('sourceLink').href = question.link || '#';
  
  // Show modal immediately with available data
  answerModal.style.display = 'block';
  document.body.style.overflow = 'hidden';
  
  // Scroll modal to top
  document.querySelector('.modal-content').scrollTop = 0;
  
  // Fetch related questions from API (if we have question ID)
  if (question.id) {
    try {
      const detail = await fetchQuestionDetail(question.id);
      if (detail && detail.related) {
        renderRelatedQuestions(detail.related);
      }
    } catch (error) {
      console.error('Failed to fetch related questions:', error);
      // Clear related questions section on error
      document.getElementById('relatedList').innerHTML = '';
    }
  }
}

function closeAnswerModal() {
  answerModal.style.display = 'none';
  document.body.style.overflow = 'auto';
}

function renderRelatedQuestions(relatedQuestions) {
  const relatedList = document.getElementById('relatedList');
  relatedList.innerHTML = '';
  
  if (!relatedQuestions || relatedQuestions.length === 0) {
    relatedList.innerHTML = '<p style="color: var(--text-muted); font-size: 0.9rem;">Ўхшаш саволлар топилмади</p>';
    return;
  }
  
  relatedQuestions.forEach(q => {
    const item = document.createElement('div');
    item.className = 'related-item';
    item.textContent = q.title;
    item.addEventListener('click', async () => {
      // Fetch full question detail and open modal
      showLoading();
      const detail = await fetchQuestionDetail(q.id);
      hideLoading();
      
      if (detail && detail.question) {
        openAnswerModal(detail.question);
      }
    });
    relatedList.appendChild(item);
  });
}

// ===========================================
// SEARCH FUNCTIONALITY
// ===========================================

async function performSearch(query) {
  const detectedAlphabet = detectAlphabet(query);
  console.log(`Searching for: "${query}" (Detected alphabet: ${detectedAlphabet})`);
  
  // Show loading
  showLoading();
  
  // Call real API
  searchResults = await searchQuestionsAPI(query, 10);
  
  // Hide loading
  hideLoading();
  
  // Show results
  showResultsView();
}

// ===========================================
// VIEW MANAGEMENT
// ===========================================

function showBrowseView() {
  currentView = 'browse';
  browseSection.style.display = 'block';
  resultsSection.style.display = 'none';
  renderBrowseQuestions();
}

function showResultsView() {
  currentView = 'results';
  browseSection.style.display = 'none';
  resultsSection.style.display = 'block';
  renderSearchResults();
  window.scrollTo(0, 0);
}

// ===========================================
// EVENT LISTENERS
// ===========================================

searchBtn.addEventListener('click', () => {
  const query = searchInput.value.trim();
  
  if (query.length < 3) {
    alert('Илтимос, камида 3 та ҳарф ёзинг / Iltimos, kamida 3 ta harf yozing');
    return;
  }
  
  performSearch(query);
});

// Search on Enter key
searchInput.addEventListener('keypress', (e) => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    searchBtn.click();
  }
});

refreshBtn.addEventListener('click', async () => {
  // Animate button
  refreshBtn.style.transform = 'rotate(360deg)';
  
  // Fetch new random questions
  showLoading();
  currentQuestions = await fetchBrowseQuestions(15);
  hideLoading();
  
  displayedCount = 10;
  renderBrowseQuestions();
  
  // Reset animation
  setTimeout(() => {
    refreshBtn.style.transform = 'rotate(0deg)';
  }, 300);
});

loadMoreBtn.addEventListener('click', () => {
  displayedCount += 5;
  renderBrowseQuestions();
});

backToSearchBtn.addEventListener('click', () => {
  showBrowseView();
  searchInput.value = '';
});

modalClose.addEventListener('click', closeAnswerModal);
modalOverlay.addEventListener('click', closeAnswerModal);

// Close modal with Escape key
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && answerModal.style.display === 'block') {
    closeAnswerModal();
  }
});

// ===========================================
// TELEGRAM BACK BUTTON
// ===========================================

function handleBackButton() {
  if (answerModal.style.display === 'block') {
    closeAnswerModal();
  } else if (currentView === 'results') {
    showBrowseView();
  } else {
    // Go back to index
    window.location.href = "../../index.html";
  }
}

try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(handleBackButton);
  }
} catch (e) {
  console.log('Telegram BackButton not available');
}

// ===========================================
// INITIALIZATION
// ===========================================

async function initQnAPage() {
  console.log('✅ Q&A page initializing...');
  
  // Show loading while fetching initial data
  showLoading();
  
  // Fetch initial random questions from API
  currentQuestions = await fetchBrowseQuestions(15);
  
  hideLoading();
  
  if (currentQuestions.length > 0) {
    displayedCount = 10;
    renderBrowseQuestions();
    console.log(`✅ Q&A page initialized with ${currentQuestions.length} questions`);
  } else {
    // Show error state
    questionCards.innerHTML = `
      <div style="text-align: center; padding: 40px 20px;">
        <p style="font-size: 3rem; margin-bottom: 12px;">😕</p>
        <p style="font-size: 1.1rem; font-weight: 600; color: var(--text-secondary); margin-bottom: 8px;">
          Маълумотларни юклашда хатолик
        </p>
        <p style="font-size: 0.9rem; color: var(--text-muted);">
          Илтимос, саҳифани янгиланг
        </p>
      </div>
    `;
    console.error('❌ Failed to load initial questions');
  }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', initQnAPage);