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

const API_BASE_URL = 'https://vegukin-api.duckdns.org';

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

let currentView = 'browse';
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

const searchTrigger = document.getElementById('searchTrigger');
const searchExpandable = document.getElementById('searchExpandable');
const searchCancel = document.getElementById('searchCancel');

let isSearchExpanded = false;

function expandSearch() {
  isSearchExpanded = true;
  searchSection.classList.add('expanded');
  searchExpandable.style.maxHeight = searchExpandable.scrollHeight + 'px';
  setTimeout(() => {
    searchInput.focus();
  }, 300);
}

function collapseSearch() {
  isSearchExpanded = false;
  searchSection.classList.remove('expanded');
  searchExpandable.style.maxHeight = '0';
  searchInput.value = '';
}

searchTrigger.addEventListener('click', () => {
  if (isSearchExpanded) {
    collapseSearch();
  } else {
    expandSearch();
  }
});

if (searchCancel) {
  searchCancel.addEventListener('click', () => {
    collapseSearch();
  });
}

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
// HELPER FUNCTIONS
// ===========================================

function formatTextWithLinks(text) {
  if (!text) return '';
  
  // Add space before http if stuck to other text
  let processed = text.replace(/([^\s])(https?:\/\/)/g, '$1 $2');
  
  // Handle multiple URLs stuck together
  processed = processed.replace(/(\.0|\.html|\.php|\.uz)(https?:\/\/)/g, '$1 $2');
  
  // Convert URLs to clickable links with shortened display
  const urlPattern = /(https?:\/\/[^\s]+)/g;
  return processed.replace(urlPattern, (url) => {
    let displayUrl = url;
    if (url.length > 50) {
      displayUrl = url.substring(0, 47) + '...';
    }
    return `<a href="${url}" target="_blank" rel="noopener noreferrer">${displayUrl}</a>`;
  });
}

function detectAlphabet(text) {
  const cyrillicPattern = /[\u0400-\u04FF]/;
  return cyrillicPattern.test(text) ? 'cyrillic' : 'latin';
}

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
  
  const viewCountHtml = question.views 
    ? `<span class="view-count">${formatViews(question.views)} ko'rilgan</span>` 
    : '';
  
  const scholarHtml = question.answerSource 
    ? `<div class="card-scholar">
        <span class="scholar-icon">📖</span>
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
      <span class="read-more">Batafsil →</span>
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
  
  if (displayedCount >= currentQuestions.length) {
    // Transform into refresh button
    loadMoreBtn.innerHTML = `
      <span>Yangi savollar yuklash</span>
      <svg class="load-more-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15"/>
      </svg>
    `;
    loadMoreBtn.classList.add('as-refresh');
    loadMoreBtn.style.display = 'flex';
  } else {
    // Normal load more state
    loadMoreBtn.innerHTML = `
      <span>Yana ko'rsatish</span>
      <svg class="load-more-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M6 9l6 6 6-6"/>
      </svg>
    `;
    loadMoreBtn.classList.remove('as-refresh');
    loadMoreBtn.style.display = 'flex';
  }
}

function renderSearchResults() {
  resultsCards.innerHTML = '';
  
  if (searchResults.length === 0) {
    resultsCards.innerHTML = `
      <div class="empty-state">
        <div class="empty-icon">🔍</div>
        <p class="empty-title">Hech qanday natija topilmadi</p>
        <p class="empty-description">Boshqa so'z bilan qidirib ko'ring</p>
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
  
  // Set category badge
  document.getElementById('modalCategory').textContent = question.topic || 'Boshqa';
  
  // Set question content
  document.getElementById('questionTitle').textContent = question.title;
  document.getElementById('questionBody').textContent = question.questionBody || '';
  
  // Handle answer source
  const sourceText = question.answerSource || '';
  const answerSourceEl = document.getElementById('answerSource');
  const sourceTextEl = answerSourceEl.querySelector('.source-text');
  
  if (sourceText) {
    sourceTextEl.textContent = sourceText;
    answerSourceEl.style.display = 'flex';
  } else {
    answerSourceEl.style.display = 'none';
  }
  
  // Set answer body with formatted links
  document.getElementById('answerBody').innerHTML = formatTextWithLinks(question.answerBody || '');
  
  // Set source link
  document.getElementById('sourceLink').href = question.link || '#';
  
  // Show modal
  answerModal.style.display = 'block';
  document.body.style.overflow = 'hidden';
  
  // Scroll to top
  document.querySelector('.modal-content').scrollTop = 0;
  
  // Fetch related questions
  if (question.id) {
    try {
      const detail = await fetchQuestionDetail(question.id);
      if (detail && detail.related) {
        renderRelatedQuestions(detail.related);
      }
    } catch (error) {
      console.error('Failed to fetch related questions:', error);
      document.getElementById('relatedList').innerHTML = '';
    }
  }
}

function closeAnswerModal() {
  answerModal.style.display = 'none';
  document.body.style.overflow = 'auto';
}

function shareQuestion() {
  const title = document.getElementById('questionTitle').textContent;
  const link = document.getElementById('sourceLink').href;
  
  const shareText = `📖 ${title}\n\n🔗 ${link}`;
  
  if (navigator.share) {
    navigator.share({
      title: title,
      text: shareText,
      url: link
    }).catch(err => console.log('Share cancelled'));
  } else if (tg.openTelegramLink) {
    const telegramUrl = `https://t.me/share/url?url=${encodeURIComponent(link)}&text=${encodeURIComponent('📖 ' + title)}`;
    tg.openTelegramLink(telegramUrl);
  } else {
    navigator.clipboard.writeText(shareText).then(() => {
      alert('Nusxa olindi!');
    });
  }
}

document.getElementById('shareBtn').addEventListener('click', shareQuestion);

function renderRelatedQuestions(relatedQuestions) {
  const relatedList = document.getElementById('relatedList');
  relatedList.innerHTML = '';
  
  if (!relatedQuestions || relatedQuestions.length === 0) {
    relatedList.innerHTML = '<p style="color: var(--text-muted); font-size: 0.9rem;">O\'xshash savollar topilmadi</p>';
    return;
  }
  
  relatedQuestions.forEach(q => {
    const item = document.createElement('div');
    item.className = 'related-item';
    item.textContent = q.title;
    item.addEventListener('click', async () => {
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
  
  showLoading();
  searchResults = await searchQuestionsAPI(query, 10);
  hideLoading();
  
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
    alert('Iltimos, kamida 3 ta harf yozing');
    return;
  }
  
  performSearch(query);
});

searchInput.addEventListener('keypress', (e) => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    searchBtn.click();
  }
});

refreshBtn.addEventListener('click', async () => {
  showLoading();
  currentQuestions = await fetchBrowseQuestions(15);
  hideLoading();
  
  displayedCount = 10;
  renderBrowseQuestions();
});

loadMoreBtn.addEventListener('click', async () => {
  if (loadMoreBtn.classList.contains('as-refresh')) {
    // Refresh behavior
    showLoading();
    currentQuestions = await fetchBrowseQuestions(15);
    hideLoading();
    displayedCount = 10;
    renderBrowseQuestions();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  } else {
    // Load more behavior
    displayedCount += 5;
    renderBrowseQuestions();
  }
});

backToSearchBtn.addEventListener('click', () => {
  showBrowseView();
  searchInput.value = '';
});

modalClose.addEventListener('click', closeAnswerModal);
modalOverlay.addEventListener('click', closeAnswerModal);

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
  
  showLoading();
  currentQuestions = await fetchBrowseQuestions(15);
  hideLoading();
  
  if (currentQuestions.length > 0) {
    displayedCount = 10;
    renderBrowseQuestions();
    console.log(`✅ Q&A page initialized with ${currentQuestions.length} questions`);
  } else {
    questionCards.innerHTML = `
      <div class="empty-state">
        <div class="empty-icon">😕</div>
        <p class="empty-title">Ma'lumotlarni yuklashda xatolik</p>
        <p class="empty-description">Iltimos, sahifani yangilang</p>
      </div>
    `;
    console.error('❌ Failed to load initial questions');
  }
}

document.addEventListener('DOMContentLoaded', initQnAPage);
