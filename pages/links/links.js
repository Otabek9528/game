// links.js - Useful Links page functionality

const tg = window.Telegram.WebApp;
tg.ready();
tg.disableVerticalSwipes();

try {
  tg.expand();
} catch (e) {}

// ===========================================
// LINK DATA
// ===========================================

const arbaytLinks = [
  { name: "Ansanda ish", url: "https://t.me/Ansanish" },
  { name: "Anseong work", url: "https://t.me/anseong_work" },
  { name: "Ansongda ish guruhi", url: "https://t.me/Ansongda_ish" },
  { name: "Bucheon Logen tekpe", url: "https://t.me/Bucheon_Logen_tekpe" },
  { name: "Busan - ish e'lonlari", url: "https://t.me/ishbusan" },
  { name: "Busan ish e'lon", url: "https://t.me/pusan_ish" },
  { name: "Cheongjudagi(청주) o'zbeklar", url: "https://t.me/cheongjuuzbekgroup" },
  { name: "Chonan Asan o'zbeklar ishi va faoliyati", url: "https://t.me/ChonanAsanuzbeklar" },
  { name: "Chonan o'zbeklar", url: "https://t.me/chonanuzbeklar" },
  { name: "Daejeon arbayt guruhi", url: "https://t.me/daejeonarbayt" },
  { name: "Daejeon, Gunsan arbayt", url: "https://t.me/gruppa_ishbor" },
  { name: "Daeso arbayt", url: "https://t.me/daesoarbayt" },
  { name: "Daeso Deoksan Jincheon Mgueok", url: "https://t.me/daeso_deoksan_jincheon_samseong" },
  { name: "Dejon City", url: "https://t.me/salievdejon" },
  { name: "Gunsandagi musofirlar", url: "https://t.me/Gunsandaishbor" },
  { name: "Help in Yangju", url: "https://t.me/helpinyangju" },
  { name: "Icheon City", url: "https://t.me/icheon_city" },
  { name: "Iksan ish", url: "https://t.me/koreaish1" },
  { name: "Incheon Lotte tekpe", url: "https://t.me/Incheon_Lotte_tekpe" },
  { name: "Jecheon va Danyang(제천 단양)", url: "https://t.me/jecheonish" },
  { name: "Katta Gwangju | 광주광역시", url: "https://t.me/Katta_Gwangju_gvangju" },
  { name: "Kimhe ish 김해 일", url: "https://t.me/Kimheish" },
  { name: "Gimpodagi o'zbeklar", url: "https://t.me/Gimpodagiuzbeklar" },
  { name: "Korea ish bor", url: "https://t.me/korea_ish_bor" },
  { name: "Koreya tekpe arbayt", url: "https://t.me/Koreya_tekpe_arbayt_ozbeklar" },
  { name: "Paju city e'lonlari", url: "https://t.me/paju_uz" },
  { name: "Seongnam ish e'lon", url: "https://t.me/SeongnamGroup" },
  { name: "Seoul Lotte tekpe", url: "https://t.me/Seoul_Lotte_tekpe" },
  { name: "Seoul tekpe", url: "https://t.me/Seoul_tekpe_arbayt" },
  { name: "Seonghwanada ish bor", url: "https://t.me/Seonghwanuz" },
  { name: "Uijeongbudagilar guruhi", url: "https://t.me/Ijongbudagi_uzbeklar" },
  { name: "Yeosu guruh", url: "https://t.me/YsuStuents" },
  { name: "Ансан (Работа)", url: "https://t.me/ansansadonrabota" },
  { name: "Гр.Паран. Реклама", url: "https://t.me/KoreaParanReklama" },
];

const koreaLifeLinks = [
  { name: "Koreyadagi O'zbekistonliklar uchun muhim yangiliklar", url: "https://t.me/uzbek_students_korea" },
  { name: "Huquqiy masalalar bo'yicha maslahat", url: "https://t.me/KoreyaQonun" },
  { name: "Koreya sog'liq sug'urtasi bo'yicha ma'lumotlar", url: "https://t.me/health_insurance_uz" },
  { name: "Yo'l harakati qonun-qoidalari va sug'urtasi haqida", url: "https://t.me/koreya_mashina_sugurta" },
  { name: "Koreyada ishlash, intervyu, rezyume, networking", url: "https://t.me/HaksengUz" },
  { name: "O'zbekiston yoshlar assotsiatsiyasi (Janubiy Korea)", url: "https://t.me/wayu_korea" },
  { name: "O'zbekiston elchixonasi rasmiy boti", url: "https://t.me/UzEmbassy_kr_bot" },
  { name: "Koreyaga endi kelmoqchi bo'lganlar uchun", url: "https://t.me/Koreyaginam" },
  { name: "Koreyadagilar uchun kanal", url: "https://t.me/salomkoreya" },
  { name: "Koreyadagi yurtdoshlarimiz bilishi kerak bo'ladigan nuktalar", url: "https://t.me/seul_global_markazi" },
  { name: "F-3 vizaga topshirganlar guruhi", url: "https://t.me/f3_vizaga" },
  { name: "Hammasi Koreya haqida", url: "https://t.me/uzbeknur_korea" },
  { name: "Koreya vizalari, grantlar va yangiliklar", url: "https://t.me/misterberd" },
  { name: "Yuridik yordam va tarjimonlik", url: "https://t.me/ganiev_tarjimon" },
  { name: "Koreyada dam olish joylari", url: "https://t.me/travelkoreabest" },
  { name: "Koreyada yo'l-yo'lakay taksi", url: "https://t.me/korea_taxi" },
  { name: "Kitoblar buyurtma qilish", url: "https://t.me/StarbooksKoreya" },
];

// ===========================================
// DOM ELEMENTS
// ===========================================

const categoriesSection = document.getElementById('categoriesSection');
const arbaytSection = document.getElementById('arbaytSection');
const koreaLifeSection = document.getElementById('koreaLifeSection');
const arbaytBtn = document.getElementById('arbaytBtn');
const koreaLifeBtn = document.getElementById('koreaLifeBtn');
const arbaytBackBtn = document.getElementById('arbaytBackBtn');
const koreaBackBtn = document.getElementById('koreaBackBtn');
const arbaytList = document.getElementById('arbaytList');
const koreaLifeList = document.getElementById('koreaLifeList');

// ===========================================
// NAVIGATION STATE
// ===========================================

let currentView = 'main'; // 'main', 'arbayt', 'koreaLife'

function showSection(sectionName) {
  // Hide all sections
  categoriesSection.style.display = 'none';
  arbaytSection.style.display = 'none';
  koreaLifeSection.style.display = 'none';
  
  // Show requested section
  switch(sectionName) {
    case 'main':
      categoriesSection.style.display = 'block';
      currentView = 'main';
      break;
    case 'arbayt':
      arbaytSection.style.display = 'block';
      currentView = 'arbayt';
      break;
    case 'koreaLife':
      koreaLifeSection.style.display = 'block';
      currentView = 'koreaLife';
      break;
  }
  
  // Scroll to top
  window.scrollTo(0, 0);
}

// ===========================================
// RENDER FUNCTIONS
// ===========================================

function renderLinksList(container, links) {
  container.innerHTML = '';
  
  links.forEach((link, index) => {
    const linkItem = document.createElement('a');
    linkItem.className = 'link-item';
    linkItem.href = link.url;
    linkItem.target = '_blank';
    linkItem.rel = 'noopener noreferrer';
    
    linkItem.innerHTML = `
      <div class="link-item-icon">🔗</div>
      <span class="link-item-text">${escapeHtml(link.name)}</span>
      <span class="link-item-arrow">↗</span>
    `;
    
    // Add staggered animation
    linkItem.style.animationDelay = `${index * 0.03}s`;
    
    container.appendChild(linkItem);
  });
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// ===========================================
// BACK BUTTON HANDLING
// ===========================================

function handleBackButton() {
  if (currentView === 'main') {
    // Go to index.html
    window.location.href = "../../index.html";
  } else {
    // Go back to main categories
    showSection('main');
  }
}

// Setup Telegram back button
try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(handleBackButton);
  }
} catch (e) {}

// ===========================================
// EVENT LISTENERS
// ===========================================

arbaytBtn.addEventListener('click', () => {
  showSection('arbayt');
});

koreaLifeBtn.addEventListener('click', () => {
  showSection('koreaLife');
});

arbaytBackBtn.addEventListener('click', () => {
  showSection('main');
});

koreaBackBtn.addEventListener('click', () => {
  showSection('main');
});

// ===========================================
// INITIALIZATION
// ===========================================

function initLinksPage() {
  // Render both lists (they're hidden by default)
  renderLinksList(arbaytList, arbaytLinks);
  renderLinksList(koreaLifeList, koreaLifeLinks);
  
  console.log('✅ Links page loaded');
  console.log(`   Arbayt links: ${arbaytLinks.length}`);
  console.log(`   Korea life links: ${koreaLifeLinks.length}`);
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', initLinksPage);