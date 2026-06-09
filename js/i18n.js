// i18n.js - Internationalization System for Muslim Vegukin Bot
// Supports: Uzbek (uz), Russian (ru), English (en)

const I18N = {
  currentLang: 'uz',
  STORAGE_KEY: 'vegukin_language',

  availableFeatures: {
    uz: ['mosque', 'restaurant', 'shop', 'qibla', 'qna', 'barcode', 'hikorea', 'jobs', 'parcel', 'vegukinShops', 'links', 'donation', 'community', 'news', 'events', 'market'],
    ru: ['mosque', 'restaurant', 'shop', 'qibla', 'barcode', 'donation', 'community', 'hikorea'],
    en: ['mosque', 'restaurant', 'shop', 'qibla', 'barcode', 'donation', 'community', 'hikorea']
  },

  translations: {
    // Common
    'app.title': { uz: 'Muslim Vegukin Bot', ru: 'Muslim Vegukin Bot', en: 'Muslim Vegukin Bot' },
    'common.loading': { uz: 'Yuklanmoqda...', ru: 'Загрузка...', en: 'Loading...' },

    // Feature cards
    'feature.mosques': { uz: 'Masjidlar', ru: 'Мечети', en: 'Mosques' },
    'feature.restaurants': { uz: 'Oshxonalar', ru: 'Рестораны', en: 'Restaurants' },
    'feature.shops': { uz: 'Do\'konlar', ru: 'Магазины', en: 'Shops' },
    'feature.qibla': { uz: 'Qibla', ru: 'Кибла', en: 'Qibla' },
    'feature.qna': { uz: 'Zikr ahlidan so\'rang', ru: 'Zikr ahlidan so\'rang', en: 'Zikr ahlidan so\'rang' },
    'feature.hikorea': { uz: 'Immigratsiya xizmatlari', ru: 'Иммиграционные службы', en: 'Immigration services' },
    'feature.jobs': { uz: 'Ish e\'lonlari', ru: 'Вакансии', en: 'Job Listings' },
    'feature.parcel': { uz: 'Pochta', ru: 'Почта', en: 'Parcel' },
    'feature.vegukinShops': { uz: 'Vegukin Shops', ru: 'Vegukin Shops', en: 'Vegukin Shops' },    
    'feature.links': { uz: 'Foydali linklar', ru: 'Полезные ссылки', en: 'Useful Links' },
    'feature.donation': { uz: 'Qo\'llab-quvvatlash', ru: 'Поддержать', en: 'Support' },
    'feature.barcode': { uz: 'Mahsulot tarkibini tekshirish', ru: 'Проверка состава', en: 'Ingredient Check' },
    'feature.news': { uz: 'Yangiliklar', ru: 'Новости', en: 'News' },
    'feature.events': { uz: 'Tadbirlar', ru: 'Мероприятия', en: 'Events' },
    'feature.market': { uz: 'Halal Bozor', ru: 'Халяль Маркет', en: 'Halal Market' },
    'feature.community': { uz: 'Jamoa', ru: 'Сообщество', en: 'Community' },

    // Prayer names
    'prayer.fajr': { uz: 'Bomdod', ru: 'Фаджр', en: 'Fajr' },
    'prayer.sunrise': { uz: 'Quyosh chiqishi', ru: 'Восход', en: 'Sunrise' },
    'prayer.dhuhr': { uz: 'Peshin', ru: 'Зухр', en: 'Dhuhr' },
    'prayer.asr': { uz: 'Asr', ru: 'Аср', en: 'Asr' },
    'prayer.maghrib': { uz: 'Shom', ru: 'Магриб', en: 'Maghrib' },
    'prayer.isha': { uz: 'Xufton', ru: 'Иша', en: 'Isha' },

    // Prayer page texts
    'prayer.pageTitle': { uz: 'Bugungi Namoz Vaqtlari', ru: 'Время намаза сегодня', en: 'Today\'s Prayer Times' },
    'prayer.dateLoading': { uz: 'Sana yuklanmoqda...', ru: 'Загрузка даты...', en: 'Loading date...' },
    'prayer.nextPrayer': { uz: 'Keyingi namoz', ru: 'Следующий намаз', en: 'Next prayer' },
    'prayer.never': { uz: 'Hech qachon', ru: 'Никогда', en: 'Never' },
    'prayer.infoTitle': { uz: 'Ma\'lumot', ru: 'Информация', en: 'Information' },
    'prayer.infoMethod': { 
      uz: 'Namoz vaqtlari <strong>Muslim World League</strong> usuli bilan hisoblab chiqildi.',
      ru: 'Время намаза рассчитано по методу <strong>Muslim World League</strong>.',
      en: 'Prayer times calculated using <strong>Muslim World League</strong> method.'
    },
    'prayer.adviceTitle': { uz: 'Ehtiyot chorasi sifatida:', ru: 'В качестве меры предосторожности:', en: 'As a precaution:' },
    'prayer.adviceSaharlik': { 
      uz: 'Saharlik: Bomdoddan <strong>5 daqiqa oldin</strong>',
      ru: 'Сухур: за <strong>5 минут до Фаджра</strong>',
      en: 'Suhoor: <strong>5 minutes before</strong> Fajr'
    },
    'prayer.adviceIftorlik': { 
      uz: 'Iftorlik: Shomdan <strong>5 daqiqa keyin</strong>',
      ru: 'Ифтар: через <strong>5 минут после Магриба</strong>',
      en: 'Iftar: <strong>5 minutes after</strong> Maghrib'
    },
    
    'prayer.suhoor.label': { uz: 'Saharlik (oxiri)', ru: 'Сухур (конец)', en: 'Suhoor (ends)' },
    'prayer.suhoor.hint':  { uz: "Ro'za boshlanishi", ru: 'Начало поста', en: 'Fast begins' },
    'prayer.iftar.label':  { uz: 'Iftorlik', ru: 'Ифтар', en: 'Iftar' },
    'prayer.iftar.hint':   { uz: "Ro'za ochilishi", ru: 'Разговение', en: 'Break fast' },
    'prayer.chip.next':  { uz: 'keyingi', ru: 'следующий', en: 'next' },
    'prayer.fastWindow': { uz: "Ro'za vaqti · Saharlikdan Iftorlikkacha", ru:     'Время поста · от сухура до ифтара', en: 'Fasting window · suhoor to  iftar' },
    'prayer.remaining': { uz: 'qoldi', ru: 'осталось', en: 'remaining' },
    
    'prayer.tab.today':    { uz: 'Bugun',  ru: 'Сегодня', en: 'Today' },
    'prayer.tab.tomorrow': { uz: 'Ertaga', ru: 'Завтра',  en: 'Tomorrow' },

    'prayer.advicePrayers': { 
      uz: 'Namozlar: Vaqt kirganidan <strong>10 daqiqa keyin</strong>',
      ru: 'Намазы: через <strong>10 минут после</strong> наступления времени',
      en: 'Prayers: <strong>10 minutes after</strong> time begins'
    },
    'prayer.recommendation': { 
      uz: 'qilib vaqt belgilashlikni maslahat beramiz.',
      ru: 'рекомендуем устанавливать время.',
      en: 'we recommend setting time.'
    },
    'prayer.lastUpdate': { uz: 'Oxirgi yangilanish', ru: 'Последнее обновление', en: 'Last update' },
    'prayer.staleWarning': { uz: 'Yangilashni maslahat beramiz', ru: 'Рекомендуем обновить', en: 'Recommend updating' },
    'prayer.comment.fajr': { uz: 'Xufton vaqti tugaydi', ru: 'Время Иша заканчивается', en: 'Isha time ends' },
    'prayer.comment.sunrise': { uz: 'Bomdod vaqti tugaydi', ru: 'Время Фаджр заканчивается', en: 'Fajr time ends' },
    'prayer.comment.asr': { uz: 'Peshin vaqti tugaydi', ru: 'Время Зухр заканчивается', en: 'Dhuhr time ends' },
    'prayer.comment.maghrib': { uz: 'Asr vaqti tugaydi', ru: 'Время Аср заканчивается', en: 'Asr time ends' },
    'prayer.comment.isha': { uz: 'Shom vaqti tugaydi', ru: 'Время Магриб заканчивается', en: 'Maghrib time ends' },
    
    // Asr by schools
    'prayer.asrBySchool': { uz: 'Asr vaqti mazhablar bo\'yicha', ru: 'Время Аср по мазхабам', en: 'Asr time by school' },
    'prayer.schoolHanafi': { uz: 'Hanafiy', ru: 'Ханафи', en: 'Hanafi' },
    'prayer.schoolOthers': { uz: 'Shofe\'iy / Molikiy / Hanbaliy', ru: 'Шафии / Малики / Ханбали', en: 'Shafi\'i / Maliki / Hanbali' },
    'prayer.hanafiNote': { uz: 'Soya = 2x uzunlik', ru: 'Тень = 2× длина', en: 'Shadow = 2x length' },
    'prayer.shafiiNote': { uz: 'Soya = 1x uzunlik', ru: 'Тень = 1× длина', en: 'Shadow = 1x length' },
    'prayer.asrHint': { uz: '💡 O\'z mazhabingizga mos vaqtni tanlang', ru: '💡 Выберите время по вашему мазхабу', en: '💡 Choose the time according to your school' },

    // ---------- Settings bottom sheet ----------
    'prayer.settings.title': {
      uz: 'Namoz sozlamalari',
      ru: 'Настройки намаза',
      en: 'Prayer settings'
    },
    'prayer.settings.subtitle': {
      uz: 'Hisoblash usuli va mazhabingizni tanlang',
      ru: 'Выберите метод расчёта и мазхаб',
      en: 'Choose your calculation method and madhab'
    },
    'prayer.settings.methodLabel': {
      uz: 'Hisoblash usuli',
      ru: 'Метод расчёта',
      en: 'Calculation method'
    },
    'prayer.settings.madhabLabel': {
      uz: 'Mazhab (Asr vaqti uchun)',
      ru: 'Мазхаб (для времени Аср)',
      en: 'Madhab (for Asr time)'
    },
     
    // ---------- Method short labels (shown in the pill) ----------
    'prayer.method.3.name':     { uz: 'Muslim World League',     ru: 'Muslim World League',     en: 'Muslim World League' },
    'prayer.method.1.name': { uz: 'Karachi', ru: 'Карачи',  en: 'Karachi' },
    'prayer.method.4.name':  { uz: 'Makka',   ru: 'Мекка',   en: 'Makkah' },
    'prayer.method.5.name':   { uz: 'Misr',    ru: 'Египет',  en: 'Egypt' },
    'prayer.method.2.name':    { uz: 'ISNA',    ru: 'ISNA',    en: 'ISNA' },
     
    // ---------- Method hints (shown under name in sheet) ----------
    'prayer.method.mwl.hint': {
      uz: 'Bomdod 18°, Xufton 17°',
      ru: 'Фаджр 18°, Иша 17°',
      en: 'Fajr 18°, Isha 17°'
    },
    'prayer.method.karachi.hint': {
      uz: 'Bomdod 18°, Xufton 18°',
      ru: 'Фаджр 18°, Иша 18°',
      en: 'Fajr 18°, Isha 18°'
    },
    'prayer.method.makkah.hint': {
      uz: 'Bomdod 18.5°, Xufton - Shomdan 90 daqiqa keyin',
      ru: 'Фаджр 18.5°, Иша - через 90 мин после Магриба',
      en: 'Fajr 18.5°, Isha - 90 min after Maghrib'
    },
    'prayer.method.egypt.hint': {
      uz: 'Bomdod 19.5°, Xufton 17.5°',
      ru: 'Фаджр 19.5°, Иша 17.5°',
      en: 'Fajr 19.5°, Isha 17.5°'
    },
    'prayer.method.isna.hint': {
      uz: 'Bomdod 15°, Xufton 15°',
      ru: 'Фаджр 15°, Иша 15°',
      en: 'Fajr 15°, Isha 15°'
    },
     
    // ---------- Sunnah & Nafl section ----------
    'prayer.sunnah.title': {
      uz: 'Nafl namoz vaqtlari',
      ru: 'Время добровольных (нафль) молитв',
      en: 'Times of voluntary (nafl) prayers'
    },
     
    // Ishraq
    'prayer.sunnah.ishraq.name': {
      uz: 'Shuruq (Ishroq) namozi',
      ru: 'Шурук (Ишрак) намаз',
      en: 'Shuruq (Ishraq) prayer'
    },

    'prayer.sunnah.ishraq.desc': {
      uz: '<span class="hadith-quote">Kim bomdodni jamoat bilan o\‘qisa, so\‘ngra quyosh chiqquncha Allohni zikr qilib o\‘tirsa, keyin ikki rakat namoz o\‘qisa, uning uchun haj va umraning ajridek bo\‘lur.</span>',
      ru: '<span class="hadith-quote">Тому, кто прочитал фаджр в джамаате, сидел в зикре до восхода солнца и затем совершил два ракаата намаза - даётся полная награда хаджа и умры.</span>',
      en: '<span class="hadith-quote">Whoever prays Fajr in congregation, remains in remembrance of Allah until sunrise, then prays two rak\'ahs - receives the full reward of Hajj and Umrah.</span>'
    },
    'prayer.sunnah.ishraq.source': {
      uz: 'Manba: Termiziy - Muoz ibn Anas al-Juhaniy (r.a.)',
      ru: 'Источник: Ат-Тирмизи - Муаз ибн Анас аль-Джухани (р.а.)',
      en: 'Source: Tirmidhi - from Mu\'adh ibn Anas al-Juhani (r.a.)'
    },
     
    // Duha / Chosht / Zuho
    'prayer.sunnah.duha.name': {
      uz: 'Zuho (Choshgoh) namozi',
      ru: 'Духа намаз',
      en: 'Duha prayer'
    },

    'prayer.sunnah.duha.desc': {
      uz: 'Quyosh bir nayza bo\'yi ko\'tarilganda kirib, zavolga bir soat qolguncha davom etadi. Afzali 4 rakat o\'qish. Eng afzal vaqti - nahorning to\'rtdan biri o\'tgandan keyin.<span class="hadith-quote">Kim choshgoh namozini bardavom o‘qisa, uning gunohlari dengiz ko‘pigicha bo‘lsa ham mag‘firat qilinadi.</span>',
      ru: 'Когда солнце поднимается на высоту копья, (время молитвы) начинается и продолжается до того, как до полудня остаётся один час. Предпочтительно совершить 4 ракаата. Наилучшее время - после того, как пройдет четверть утра.<span class="hadith-quote">Кто постоянно совершает молитву духа (чошгох), тому будут прощены грехи, даже если они подобны морской пене.</span>',
      en: 'When the sun rises to the height of a spear, it begins and continues until one hour remains before noon. It is most virtuous to pray 4 rak‘ahs. The most preferable time is after one quarter of the morning has passed.<span class="hadith-quote">Whoever consistently performs the Duha (forenoon) prayer, his sins will be forgiven even if they are as abundant as the foam of the sea.</span>'
    },
    'prayer.sunnah.duha.source': {
      uz: 'Manba: Termiziy - Abu Hurayra (r.a.)',
      ru: 'Источник: Ат-Тирмизи - Абу Хурайра (р.а.)',
      en: 'Source: Tirmidhi - from Abu Hurayra (r.a.)'
    },
     
    // Tahajjud
    'prayer.sunnah.tahajjud.name': {
      uz: 'Tahajjud namozi',
      ru: 'Тахаджуд намаз',
      en: 'Tahajjud prayer'
    },

    'prayer.sunnah.tahajjud.desc': {
      uz: 'Xuftondan keyin, uyqudan so\'ng o\'qiladigan nafl namoz. Ozi 2 rakat, ko\'pi 8 rakat. Eng afzal vaqti - kechaning oxirgi uchdan biri. Duolar qabul bo\'ladigan vaqt.<span class="hadith-quote">U Robbingizga qurbatdir, yomonliklarga kafforotdir, gunohlarni qaytaruvchidir.</span>',
      ru: 'Совершаемая после молитвы Иша, после сна. Минимум - 2 ракаата, максимум - 8 ракаатов. Наилучшее время - последняя треть ночи - время, когда принимаются мольбы.<span class="hadith-quote">Она приближает к вашему Господу, искупает дурные поступки и удерживает от грехов.</span>',
      en: 'Performed after the Isha prayer, following sleep. Its minimum is 2 rak‘ahs and its maximum is 8 rak‘ahs. The most virtuous time is the last third of the night - a time when supplications are accepted.<span class="hadith-quote">It brings one closer to your Lord, expiates bad deeds, and prevents sins.</span>'
    },
    'prayer.sunnah.tahajjud.source': {
      uz: 'Manba: Termiziy - Abu Umoma (r.a.)',
      ru: 'Источник: Ат-Тирмизи - Абу Умома (р.а.)',
      en: 'Source: Tirmidhi - from Abu Umoma (r.a.)'
    },
        
    'prayer.status.upcoming': {
      uz: 'Kutilmoqda',
      ru: 'Ожидается',
      en: 'Upcoming'
    },
    
    'prayer.justNow': {
      uz: 'hozirgina',
      ru: 'только что',
      en: 'just now'
    },
    'prayer.minAgo': {
      uz: 'daqiqa oldin',
      ru: 'мин назад',
      en: 'min ago'
    },
    'prayer.hrAgo': {
      uz: 'soat oldin',
      ru: 'ч назад',
      en: 'hr ago'
    },
    'prayer.dayAgo': {
      uz: 'kun oldin',
      ru: 'дн назад',
      en: 'd ago'
    },
    
    'prayer.updated': {
      uz: 'Yangilangan',
      ru: 'Обновлено',
      en: 'Updated'
    },
    
    'prayer.settings.short': {
      uz: 'Sozlamalar',
      ru: 'Настройки',
      en: 'Settings'
    },
     
    // Sunnah status pills
    'prayer.status.activeNow': {
      uz: 'Ayni vaqti',
      ru: 'Сейчас',
      en: 'Now'
    },
    'prayer.status.passed': {
      uz: 'Vaqti o\'tdi',
      ru: 'Прошло',
      en: 'Passed'
    },
        
    
    // Places page - Common
    'places.searchNearby': { uz: 'O\'z atrofimdan izlash', ru: 'Искать рядом со мной', en: 'Search nearby' },
    'places.searchByAddress': { uz: 'Boshqa manzil atrofidan izlash', ru: 'Искать по адресу', en: 'Search by address' },
    'places.searchHint': { 
      uz: '💡 Biror manzilni KOREYS tilida kiritish orqali o\'sha hudud atrofidagi joylarni qidirish mumkin.',
      ru: '💡 Введите адрес на КОРЕЙСКОМ языке для поиска мест в этом районе.',
      en: '💡 Enter an address in KOREAN to search for places in that area.'
    },
    'places.searchButton': { uz: 'Qidirish', ru: 'Поиск', en: 'Search' },
    'places.placeholderText': { uz: 'Yuqoridagi tugmalardan birini tanlang', ru: 'Выберите одну из кнопок выше', en: 'Select one of the buttons above' },
    'places.placeholderSubtext': { 
      uz: 'O\'z joylashuvingiz atrofidan yoki boshqa kiritilgan manzil atrofidan izlang',
      ru: 'Ищите рядом с вашим местоположением или по другому адресу',
      en: 'Search near your location or around another address'
    },
    'places.loading': { uz: 'Joylar yuklanmoqda...', ru: 'Загрузка мест...', en: 'Loading places...' },
    'places.loadingPhotos': { uz: 'Rasmlar yuklanmoqda...', ru: 'Загрузка фото...', en: 'Loading photos...' },
    'places.loadingHint': { uz: 'Internet tezligingizga bog\'liq', ru: 'Зависит от скорости интернета', en: 'Depends on internet speed' },
    'places.noResults': { uz: 'Hech qanday joy topilmadi', ru: 'Ничего не найдено', en: 'No places found' },
    'places.noResultsHint': { uz: 'Iltimos, boshqa manzilni sinab ko\'ring', ru: 'Попробуйте другой адрес', en: 'Please try another address' },
    'places.infoFooter': { 
      uz: 'Yangi joy haqida xabar berish uchun <a href="https://t.me/MuslimVegukin" target="_blank">guruhimizga</a> o\'tishingizni so\'raymiz.',
      ru: 'Чтобы сообщить о новом месте, присоединяйтесь к <a href="https://t.me/MuslimVegukin" target="_blank">нашей группе</a>.',
      en: 'To report a new place, please join <a href="https://t.me/MuslimVegukin" target="_blank">our group</a>.'
    },
    'places.noInfo': { uz: 'Ma\'lumot yo\'q', ru: 'Нет данных', en: 'No info' },
    'places.noAddress': { uz: 'Manzil ma\'lumoti yo\'q', ru: 'Адрес не указан', en: 'No address info' },
    'places.noRating': { uz: 'Izoh qoldirilmagan', ru: 'Нет отзывов', en: 'No reviews' },
    'places.error': { uz: 'Xatolik yuz berdi', ru: 'Произошла ошибка', en: 'An error occurred' },
    'places.loadError': { uz: 'Joylarni yuklashda xatolik yuz berdi', ru: 'Ошибка загрузки мест', en: 'Error loading places' },
    'places.addressError': { uz: 'Manzil bo\'yicha qidirishda xatolik', ru: 'Ошибка поиска по адресу', en: 'Error searching by address' },
    'places.timeoutError': { uz: 'Server javob bermadi. Iltimos, qaytadan urinib ko\'ring.', ru: 'Сервер не отвечает. Попробуйте снова.', en: 'Server not responding. Please try again.' },
    'places.locationError': { uz: 'Joylashuv ma\'lumotlari topilmadi', ru: 'Местоположение не найдено', en: 'Location not found' },

    // Places - Mosque specific
    'places.mosque.name': { uz: 'Masjid', ru: 'Мечеть', en: 'Mosque' },
    'places.mosque.namePlural': { uz: 'Masjidlar', ru: 'Мечети', en: 'Mosques' },
    'places.mosque.pageTitle': { uz: 'Sizga eng yaqin 5 masjid', ru: '5 ближайших мечетей', en: '5 nearest mosques' },
    'places.mosque.searchedTitle': { uz: 'Izlangan joyga eng yaqinlari', ru: 'Ближайшие к искомому месту', en: 'Nearest to searched location' },
    'places.mosque.noResults': { uz: 'Hech qanday masjid topilmadi', ru: 'Мечети не найдены', en: 'No mosques found' },

    // Places - Restaurant specific
    'places.restaurant.name': { uz: 'Oshxona', ru: 'Ресторан', en: 'Restaurant' },
    'places.restaurant.namePlural': { uz: 'Oshxonalar', ru: 'Рестораны', en: 'Restaurants' },
    'places.restaurant.pageTitle': { uz: 'Sizga eng yaqin 5 oshxona', ru: '5 ближайших ресторанов', en: '5 nearest restaurants' },
    'places.restaurant.searchedTitle': { uz: 'Izlangan joyga eng yaqinlari', ru: 'Ближайшие к искомому месту', en: 'Nearest to searched location' },
    'places.restaurant.noResults': { uz: 'Hech qanday oshxona topilmadi', ru: 'Рестораны не найдены', en: 'No restaurants found' },
    
    'places.menuAvailable': { uz: 'Menyu mavjud',         ru: 'Меню доступно',     en: 'Menu available' },
    'places.menuPreview':   { uz: 'Menyudan namunalar',   ru: 'Из меню',           en: 'From the menu' },
    'places.viewAllDishes': { uz: 'Hammasini ko\'rish',   ru: 'Все блюда',         en: 'View all' },
    
    'detail.menuCtaTitle':  { uz: 'Menyu va onlayn buyurtma',                              ru: 'Меню и онлайн-заказ',                       en: 'Menu & online order' },
'detail.menuCtaSub':    { uz: 'Stoldan yoki olib ketish uchun buyurtma bering',         ru: 'Закажите в зале или на вынос',              en: 'Order for dine-in or takeout' },
'detail.menuInfoLabel': { uz: 'RESTORAN EGASIMISIZ?',                                   ru: 'ВЫ ВЛАДЕЛЕЦ?',                              en: 'ARE YOU THE OWNER?' },
'detail.menuInfoText':  { uz: "Menyungizni Muslim Vegukin orqali onlayn taqdim qilish va mijozlardan to'g'ridan-to'g'ri buyurtma qabul qilishni xohlasangiz, biz bilan bog'laning.",
                          ru: 'Если вы хотите представить свое меню онлайн через Muslim Vegukin и принимать заказы напрямую от клиентов, свяжитесь с нами.',
                          en: 'If you would like to showcase your menu online through Muslim Vegukin and accept orders directly from customers, contact us.' },

    // Places - Shop specific
    'places.shop.name': { uz: 'Do\'kon', ru: 'Магазин', en: 'Shop' },
    'places.shop.namePlural': { uz: 'Do\'konlar', ru: 'Магазины', en: 'Shops' },
    'places.shop.pageTitle': { uz: 'Sizga eng yaqin 5 do\'kon', ru: '5 ближайших магазинов', en: '5 nearest shops' },
    'places.shop.searchedTitle': { uz: 'Izlangan joyga eng yaqinlari', ru: 'Ближайшие к искомому месту', en: 'Nearest to searched location' },
    'places.shop.noResults': { uz: 'Hech qanday do\'kon topilmadi', ru: 'Магазины не найдены', en: 'No shops found' },

    // Qibla page
    'qibla.title': { uz: 'Qibla Yo\'nalishi', ru: 'Направление Киблы', en: 'Qibla Direction' },
    'qibla.compassPreparing': { uz: 'Kompas tayyorlanmoqda...', ru: 'Подготовка компаса...', en: 'Preparing compass...' },
    'qibla.holdFlat': { uz: 'Qurilmangizni tekis ushlang', ru: 'Держите устройство горизонтально', en: 'Hold your device flat' },
    'qibla.permissionNeeded': { uz: 'Kompas ruxsati kerak', ru: 'Требуется разрешение компаса', en: 'Compass permission needed' },
    'qibla.permissionDesc': { uz: 'Qibla yo\'nalishini aniqlash uchun qurilmangizning kompas funksiyasidan foydalanishga ruxsat bering.', ru: 'Разрешите использование компаса устройства для определения направления Киблы.', en: 'Allow access to your device compass to determine Qibla direction.' },
    'qibla.grantPermission': { uz: 'Ruxsat berish', ru: 'Разрешить', en: 'Grant permission' },
    'qibla.safariNote': { uz: 'Safari so\'roviga "Allow" tugmasini bosing', ru: 'Нажмите "Allow" в запросе Safari', en: 'Press "Allow" on Safari prompt' },
    'qibla.error': { uz: 'Xatolik yuz berdi', ru: 'Произошла ошибка', en: 'An error occurred' },
    'qibla.errorDesc': { uz: 'Kompasga ulanib bo\'lmadi. Qurilma sozlamalarini tekshiring.', ru: 'Не удалось подключиться к компасу. Проверьте настройки устройства.', en: 'Could not connect to compass. Check device settings.' },
    'qibla.retry': { uz: 'Qaytadan urinish', ru: 'Попробовать снова', en: 'Try again' },
    'qibla.calibrateTitle': { uz: 'Kompasni kalibratsiya qiling', ru: 'Откалибруйте компас', en: 'Calibrate the compass' },
    'qibla.calibrateDesc': { uz: 'Aniq natija olish uchun telefonni havoda <strong>∞ (cheksizlik)</strong> belgisi shaklida bir necha marta harakatlantiring.', ru: 'Для точного результата перемещайте телефон в воздухе в форме знака <strong>∞ (бесконечность)</strong> несколько раз.', en: 'For accurate results, move your phone in the air in a <strong>∞ (figure-eight)</strong> pattern several times.' },
    'qibla.calibrateStep1': { uz: 'Telefonni ∞ shaklida harakatlantiring', ru: 'Двигайте телефон в форме ∞', en: 'Move phone in ∞ shape' },
    'qibla.calibrateStep2': { uz: '5-6 marta takrorlang', ru: 'Повторите 5-6 раз', en: 'Repeat 5-6 times' },
    'qibla.calibrating': { uz: 'Kalibratsiya qiling...', ru: 'Калибровка...', en: 'Calibrating...' },
    'qibla.calibrateMove': { uz: 'Telefonni ∞ shaklida harakatlantiring...', ru: 'Двигайте телефон в форме ∞...', en: 'Move phone in ∞ pattern...' },
    'qibla.calibrateGood': { uz: 'Yaxshi! Davom eting...', ru: 'Хорошо! Продолжайте...', en: 'Good! Keep going...' },
    'qibla.calibrateAlmost': { uz: 'Deyarli tayyor...', ru: 'Почти готово...', en: 'Almost ready...' },
    'qibla.calibrateDone': { uz: '✓ Kalibratsiya tayyor!', ru: '✓ Калибровка завершена!', en: '✓ Calibration complete!' },
    'qibla.turnDevice': { uz: 'Qurilmani aylantiring...', ru: 'Поворачивайте устройство...', en: 'Turn device...' },
    'qibla.remaining': { uz: 'qoldi', ru: 'осталось', en: 'remaining' },
    'qibla.qiblaAngle': { uz: 'Qibla burchagi', ru: 'Угол Киблы', en: 'Qibla angle' },
    'qibla.yourDirection': { uz: 'Siz qaragan yo\'nalish', ru: 'Ваше направление', en: 'Your direction' },
    'qibla.north': { uz: 'Shimol', ru: 'Север', en: 'North' },
    'qibla.east': { uz: 'Sharq', ru: 'Восток', en: 'East' },
    'qibla.south': { uz: 'Janub', ru: 'Юг', en: 'South' },
    'qibla.west': { uz: 'G\'arb', ru: 'Запад', en: 'West' },
    'qibla.direction': { uz: 'Yo\'nalish', ru: 'Направление', en: 'Direction' },
    'qibla.location': { uz: 'Joylashuv', ru: 'Местоположение', en: 'Location' },
    'qibla.distanceToMakkah': { uz: 'Makkagacha', ru: 'До Мекки', en: 'To Makkah' },
    'qibla.compassSignal': { uz: 'Kompas signali:', ru: 'Сигнал компаса:', en: 'Compass signal:' },
    'qibla.recalibrate': { uz: 'Qayta kalibratsiya', ru: 'Перекалибровать', en: 'Recalibrate' },
    'qibla.tipsTitle': { uz: 'Aniqroq natija uchun', ru: 'Для точного результата', en: 'For better accuracy' },
    'qibla.tip1': { uz: 'Telefonni gorizontal (tekis) ushlang', ru: 'Держите телефон горизонтально', en: 'Hold phone horizontally (flat)' },
    'qibla.tip2': { uz: 'Metall buyumlardan uzoqroq turing', ru: 'Держитесь подальше от металла', en: 'Stay away from metal objects' },
    'qibla.tip3': { uz: 'Elektron qurilmalardan uzoqlashing', ru: 'Отойдите от электроники', en: 'Move away from electronics' },
    'qibla.tip4': { uz: 'Ochiq maydonlarda ishlating', ru: 'Используйте на открытом воздухе', en: 'Use in open areas' },
    'qibla.qualityExcellent': { uz: 'A\'lo', ru: 'Отлично', en: 'Excellent' },
    'qibla.qualityGood': { uz: 'Yaxshi', ru: 'Хорошо', en: 'Good' },
    'qibla.qualityMedium': { uz: 'O\'rtacha', ru: 'Средне', en: 'Medium' },
    'qibla.qualityPoor': { uz: 'Yomon', ru: 'Плохо', en: 'Poor' },
    'qibla.aligned': { uz: 'Qiblaga to\'g\'ri yuzlangansiz!', ru: 'Вы направлены на Киблу!', en: 'You are facing Qibla!' },
    'qibla.turnSlightly': { uz: 'Biroz', ru: 'Немного', en: 'Slightly' },
    'qibla.turn': { uz: 'buriling', ru: 'поверните', en: 'turn' },
    'qibla.right': { uz: 'o\'ngga', ru: 'вправо', en: 'right' },
    'qibla.left': { uz: 'chapga', ru: 'влево', en: 'left' },
    'qibla.rightCap': { uz: 'O\'ngga', ru: 'Вправо', en: 'Right' },
    'qibla.leftCap': { uz: 'Chapga', ru: 'Влево', en: 'Left' },
    'qibla.unknown': { uz: 'Noma\'lum', ru: 'Неизвестно', en: 'Unknown' },
    'qibla.locationError': { uz: 'Joylashuvni aniqlab bo\'lmadi. Iltimos, brauzerda joylashuvni yoqing va sahifani yangilang.', ru: 'Не удалось определить местоположение. Включите геолокацию в браузере и обновите страницу.', en: 'Could not determine location. Please enable location in browser and refresh.' },
    'qibla.permissionDenied': { uz: 'Kompas ruxsati berilmadi. Iltimos, Safari sozlamalaridan ruxsat bering.', ru: 'Разрешение компаса отклонено. Разрешите в настройках Safari.', en: 'Compass permission denied. Please allow in Safari settings.' },
    'qibla.permissionError': { uz: 'Kompas ruxsatini so\'rashda xatolik yuz berdi.', ru: 'Ошибка при запросе разрешения компаса.', en: 'Error requesting compass permission.' },
    'qibla.noCompass': { uz: 'Bu qurilmada kompas mavjud emas.', ru: 'На этом устройстве нет компаса.', en: 'This device does not have a compass.' },
    'qibla.noCompassSensor': { uz: 'Bu qurilmada kompas sensori mavjud emas.', ru: 'На этом устройстве нет датчика компаса.', en: 'This device does not have a compass sensor.' },

    // Weekdays
    'weekday.monday': { uz: 'Dushanba', ru: 'Понедельник', en: 'Monday' },
    'weekday.tuesday': { uz: 'Seshanba', ru: 'Вторник', en: 'Tuesday' },
    'weekday.wednesday': { uz: 'Chorshanba', ru: 'Среда', en: 'Wednesday' },
    'weekday.thursday': { uz: 'Payshanba', ru: 'Четверг', en: 'Thursday' },
    'weekday.friday': { uz: 'Juma', ru: 'Пятница', en: 'Friday' },
    'weekday.saturday': { uz: 'Shanba', ru: 'Суббота', en: 'Saturday' },
    'weekday.sunday': { uz: 'Yakshanba', ru: 'Воскресенье', en: 'Sunday' },

    // Community page
    'community.pageTitle': { uz: 'Jamoa - Telegram Guruh', ru: 'Сообщество - Telegram группа', en: 'Community - Telegram Group' },
    'community.heroTitle': { uz: 'Rasmiy Telegram Guruhi', ru: 'Официальная Telegram группа', en: 'Official Telegram Group' },
    'community.heroSubtitle': { uz: 'Bot foydalanuvchilari jamiyati', ru: 'Сообщество пользователей бота', en: 'Bot users community' },
    'community.joinGroup': { uz: 'Guruhga qo\'shilish', ru: 'Присоединиться к группе', en: 'Join group' },
    'community.purposeTitle': { uz: 'Guruh maqsadi', ru: 'Цель группы', en: 'Group purpose' },
    'community.purposeText': { uz: 'Ushbu guruh <strong>Muslim Vegukin Bot</strong> foydalanuvchilari uchun rasmiy muhokama maydonidir. Bu yerda bot bilan bog\'liq barcha masalalarni muhokama qilishingiz mumkin.', ru: 'Эта группа является официальной площадкой для обсуждения пользователями <strong>Muslim Vegukin Bot</strong>. Здесь вы можете обсудить все вопросы, связанные с ботом.', en: 'This group is the official discussion platform for <strong>Muslim Vegukin Bot</strong> users. Here you can discuss all bot-related topics.' },
    'community.allowedTitle': { uz: 'Guruh muhokama mavzulari:', ru: 'Темы для обсуждения в группе:', en: 'Group discussion topics:' },
    'community.allowed1': { uz: '<strong>Yangi manzillar haqida xabar berish</strong> - yangi masjid, restoran yoki do\'kon qo\'shilishi kerak bo\'lsa', ru: '<strong>Сообщения о новых адресах</strong> - если нужно добавить новую мечеть, ресторан или магазин', en: '<strong>Report new locations</strong> - if a new mosque, restaurant or shop needs to be added' },
    'community.allowed2': { uz: '<strong>Takliflar va g\'oyalar</strong> - botni yaxshilash uchun fikrlaringiz', ru: '<strong>Предложения и идеи</strong> - ваши мысли по улучшению бота', en: '<strong>Suggestions and ideas</strong> - your thoughts on improving the bot' },
    'community.allowed3': { uz: '<strong>Xatolar haqida xabar berish</strong> - agar botda muammo topsangiz', ru: '<strong>Сообщения об ошибках</strong> - если вы нашли проблему в боте', en: '<strong>Bug reports</strong> - if you find a problem in the bot' },
    'community.allowed4': { uz: '<strong>Bot yangiliklari</strong> - yangi funksiyalar va o\'zgarishlar haqida e\'lonlar', ru: '<strong>Новости бота</strong> - объявления о новых функциях и изменениях', en: '<strong>Bot news</strong> - announcements about new features and changes' },
    'community.allowed5': { uz: '<strong>Beta versiyalar muhokamasi</strong> - yangi funksiyalarni ommaga chiqarishdan oldin sinab ko\'rish', ru: '<strong>Обсуждение бета-версий</strong> - тестирование новых функций перед публичным релизом', en: '<strong>Beta version discussions</strong> - testing new features before public release' },
    'community.allowed6': { uz: '<strong>Bot haqida savollar</strong> - qanday ishlatish, funksiyalar haqida', ru: '<strong>Вопросы о боте</strong> - как использовать, о функциях', en: '<strong>Questions about the bot</strong> - how to use, about features' },
    'community.allowed7': { uz: '<strong>Jamiyat bilan muloqot</strong> - boshqa foydalanuvchilar bilan tajriba almashish', ru: '<strong>Общение с сообществом</strong> - обмен опытом с другими пользователями', en: '<strong>Community interaction</strong> - sharing experiences with other users' },
    'community.rulesTitle': { uz: 'Guruh qoidalari', ru: 'Правила группы', en: 'Group rules' },
    'community.rulesWarning': { uz: 'Quyidagi turdagi xabarlar <strong>o\'chirib tashlanadi</strong>:', ru: 'Следующие типы сообщений <strong>будут удалены</strong>:', en: 'The following types of messages <strong>will be deleted</strong>:' },
    'community.prohibited1': { uz: '<strong>Reklama va savdo e\'lonlari</strong> - har qanday turdagi sotish yoki xarid e\'lonlari', ru: '<strong>Реклама и торговые объявления</strong> - любые объявления о продаже или покупке', en: '<strong>Ads and sales announcements</strong> - any buy or sell advertisements' },
    'community.prohibited2': { uz: '<strong>O\'quv kurslari reklamasi</strong> - til kurslari, o\'quv markazlari va boshqalar', ru: '<strong>Реклама курсов</strong> - языковые курсы, учебные центры и прочее', en: '<strong>Course advertisements</strong> - language courses, learning centers, etc.' },
    'community.prohibited3': { uz: '<strong>Bot bilan bog\'liq bo\'lmagan savollar</strong> - umumiy savollar uchun boshqa guruhlardan foydalaning', ru: '<strong>Вопросы не о боте</strong> - для общих вопросов используйте другие группы', en: '<strong>Non-bot related questions</strong> - use other groups for general questions' },
    'community.prohibited4': { uz: '<strong>Spam va takroriy xabarlar</strong> - bir xil xabarlarni qayta-qayta yozish', ru: '<strong>Спам и повторяющиеся сообщения</strong> - многократная отправка одинаковых сообщений', en: '<strong>Spam and repetitive messages</strong> - sending the same messages repeatedly' },
    'community.prohibited5': { uz: '<strong>Mavzudan tashqari munozaralar</strong> - bot bilan aloqasi bo\'lmagan suhbatlar', ru: '<strong>Оффтопик дискуссии</strong> - разговоры не связанные с ботом', en: '<strong>Off-topic discussions</strong> - conversations unrelated to the bot' },
    'community.penaltyTitle': { uz: 'Ogohlantirish', ru: 'Предупреждение', en: 'Warning' },
    'community.penaltyText': { uz: 'Qoidalarga zid xabarlar <strong>o\'chiriladi</strong>. Agar o\'chirilgan xabar qayta yozilsa, foydalanuvchi guruhda yozish huquqidan <strong>cheklanadi</strong> (restrict).', ru: 'Сообщения, нарушающие правила, <strong>будут удалены</strong>. При повторном нарушении пользователь <strong>будет ограничен</strong> в правах на отправку сообщений.', en: 'Messages violating rules <strong>will be deleted</strong>. If repeated, the user <strong>will be restricted</strong> from sending messages.' },
    'community.ctaText': { uz: '🌟 Qoidalarga rioya qilgan holda guruhga qo\'shilishingizni so\'rab qolamiz!', ru: '🌟 Приглашаем вас присоединиться к группе, соблюдая правила!', en: '🌟 We invite you to join the group while following the rules!' },
    'community.joinNow': { uz: 'Hoziroq qo\'shiling', ru: 'Присоединиться сейчас', en: 'Join now' },
    'community.linkCopied': { uz: 'Link nusxa olindi! ✅', ru: 'Ссылка скопирована! ✅', en: 'Link copied! ✅' },

    // Donation page
    'donation.pageTitle': { uz: 'Xayriya - Loyihani Qo\'llab-Quvvatlash', ru: 'Пожертвование - Поддержка проекта', en: 'Donation - Support the Project' },
    'donation.heroTitle': { uz: 'Loyiha faoliyatini qo\'llab-quvvatlang', ru: 'Поддержите работу проекта', en: 'Support the project' },
    'donation.heroSubtitle': { uz: 'Yordamingiz bilan loyiha yanada rivojlanadi', ru: 'С вашей помощью проект будет развиваться', en: 'With your help the project will grow' },
    'donation.message': { uz: 'Agar ushbu bot sizga foydali bo\'layotgan bo\'lsa va uning ishlashi hamda rivojlanishiga o\'z hissangizni qo\'shmoqchi bo\'lsangiz, quyidagi hisob raqamga istalgan miqdorda moddiy mablag\'laringizni yuborishingiz mumkin.', ru: 'Если этот бот оказался вам полезен и вы хотите внести свой вклад в его работу и развитие, вы можете отправить любую сумму на указанный ниже счёт.', en: 'If this bot has been useful to you and you would like to contribute to its operation and development, you can send any amount to the account below.' },
    'donation.name': { uz: 'Ism', ru: 'Имя', en: 'Name' },
    'donation.accountNumber': { uz: 'Hisob raqam', ru: 'Номер счёта', en: 'Account number' },
    'donation.copy': { uz: 'Nusxa olish', ru: 'Копировать', en: 'Copy' },
    'donation.copied': { uz: 'Nusxa olindi!', ru: 'Скопировано!', en: 'Copied!' },
    'donation.copyError': { uz: 'Xatolik!', ru: 'Ошибка!', en: 'Error!' },
    'donation.usageTitle': { uz: 'Yig\'ilgan mablag\'lar quyidagilar uchun ishlatiladi:', ru: 'Собранные средства будут использованы для:', en: 'Collected funds will be used for:' },
    'donation.usage1': { uz: 'Server va hosting xarajatlari', ru: 'Расходы на сервер и хостинг', en: 'Server and hosting costs' },
    'donation.usage2': { uz: 'Texnik xizmat va muntazam yangilanishlar', ru: 'Техническое обслуживание и регулярные обновления', en: 'Technical maintenance and regular updates' },
    'donation.usage3': { uz: 'Dasturchilar mehnati va loyihani rivojlantirish', ru: 'Работа разработчиков и развитие проекта', en: 'Developer work and project development' },
    'donation.thankYouText': { uz: 'Sizning har qanday hissangiz biz uchun katta ahamiyatga ega!', ru: 'Любой ваш вклад очень важен для нас!', en: 'Any contribution from you is very important to us!' },
    'donation.thankYou': { uz: 'Rahmat!', ru: 'Спасибо!', en: 'Thank you!' },

    // Weekdays
    'weekday.monday': { uz: 'Dushanba', ru: 'Понедельник', en: 'Monday' },
    'weekday.tuesday': { uz: 'Seshanba', ru: 'Вторник', en: 'Tuesday' },
    'weekday.wednesday': { uz: 'Chorshanba', ru: 'Среда', en: 'Wednesday' },
    'weekday.thursday': { uz: 'Payshanba', ru: 'Четверг', en: 'Thursday' },
    'weekday.friday': { uz: 'Juma', ru: 'Пятница', en: 'Friday' },
    'weekday.saturday': { uz: 'Shanba', ru: 'Суббота', en: 'Saturday' },
    'weekday.sunday': { uz: 'Yakshanba', ru: 'Воскресенье', en: 'Sunday' },

    // Detail page - Common
    'detail.retry': { uz: 'Qaytadan urinish', ru: 'Попробовать снова', en: 'Try again' },
    'detail.contact': { uz: 'Kontakt', ru: 'Контакт', en: 'Contact' },
    'detail.address': { uz: 'Manzil', ru: 'Адрес', en: 'Address' },
    'detail.reviews': { uz: 'Izohlar', ru: 'Отзывы', en: 'Reviews' },
    'detail.navigation': { uz: 'Navigatsiya', ru: 'Навигация', en: 'Navigation' },
    'detail.leaveReview': { uz: 'Izoh qoldirish', ru: 'Оставить отзыв', en: 'Leave a review' },
    'detail.noReviews': { uz: 'Hali izoh yo\'q', ru: 'Пока нет отзывов', en: 'No reviews yet' },
    'detail.noReviewsYet': { uz: 'Hali Izohlar yo\'q', ru: 'Пока нет отзывов', en: 'No reviews yet' },
    'detail.noReviewText': { uz: 'Izoh matni yo\'q', ru: 'Нет текста отзыва', en: 'No review text' },
    'detail.addressCopied': { uz: 'Manzil nusxalandi! ✅', ru: 'Адрес скопирован! ✅', en: 'Address copied! ✅' },
    'detail.reviewHintTitle': { uz: 'Izohingizda quyidagilarni yozishingiz mumkin:', ru: 'В отзыве вы можете написать:', en: 'In your review you can write:' },
    'detail.reviewHint2': { uz: 'Ochilish va yopilish vaqtlari', ru: 'Время открытия и закрытия', en: 'Opening and closing times' },
    'detail.reviewHint3': { uz: 'Kirish eshikdagi parol (agar bor bo\'lsa)', ru: 'Пароль на входной двери (если есть)', en: 'Door password (if any)' },
    'detail.reviewHint4': { uz: 'Lokatsiyaga olib boriladigan yo\'l tushuntirishlar', ru: 'Описание пути к месту', en: 'Directions to the location' },
    'detail.rate': { uz: 'Baholang:', ru: 'Оцените:', en: 'Rate:' },
    'detail.reviewPlaceholder': { uz: 'Izohingizni yozing ...', ru: 'Напишите ваш отзыв ...', en: 'Write your review ...' },
    'detail.submit': { uz: 'Yuborish', ru: 'Отправить', en: 'Submit' },
    'detail.loading': { uz: 'Yuklanmoqda...', ru: 'Загрузка...', en: 'Loading...' },
    'detail.thankYou': { uz: 'Rahmat!', ru: 'Спасибо!', en: 'Thank you!' },
    'detail.reviewReceived': { uz: 'Izohingiz muvaffaqiyatli qabul qilindi va ko\'rib chiqilmoqda.', ru: 'Ваш отзыв успешно получен и находится на рассмотрении.', en: 'Your review has been received and is being reviewed.' },
    'detail.selectRating': { uz: 'Iltimos, baho tanlang!', ru: 'Пожалуйста, выберите оценку!', en: 'Please select a rating!' },
    'detail.submitError': { uz: 'Xatolik yuz berdi. Internetni tekshiring.', ru: 'Произошла ошибка. Проверьте интернет.', en: 'An error occurred. Check your internet.' },
    'detail.tryAgain': { uz: 'Qaytadan urinib ko\'ring', ru: 'Попробуйте снова', en: 'Try again' },
    'detail.idNotFound': { uz: 'ID topilmadi. Iltimos, orqaga qaytib, qaytadan tanlang.', ru: 'ID не найден. Вернитесь назад и выберите снова.', en: 'ID not found. Please go back and select again.' },
    'detail.loadError': { uz: 'Ma\'lumotlarni yuklashda xatolik yuz berdi. Iltimos, internetni tekshirib, qaytadan urinib ko\'ring.', ru: 'Ошибка загрузки данных. Проверьте интернет и попробуйте снова.', en: 'Error loading data. Please check internet and try again.' },
    'detail.timeoutError': { uz: 'Server javob bermadi (30 soniya). Server uyg\'onayotgan bo\'lishi mumkin, iltimos 1 daqiqa kuting va qaytadan urinib ko\'ring.', ru: 'Сервер не отвечает (30 сек). Сервер может просыпаться, подождите 1 минуту и попробуйте снова.', en: 'Server not responding (30 sec). Server may be waking up, please wait 1 minute and try again.' },
    'detail.notFound': { uz: 'Topilmadi. Bu bazadan o\'chirilgan bo\'lishi mumkin.', ru: 'Не найдено. Возможно, удалено из базы.', en: 'Not found. May have been removed from database.' },

    // Detail page - Mosque specific
    'detail.mosque.title': { uz: 'Masjid Ma\'lumotlari', ru: 'Информация о мечети', en: 'Mosque Information' },
    'detail.mosque.reviewPrompt': { uz: 'Masjid haqida fikringiz', ru: 'Ваше мнение о мечети', en: 'Your opinion about the mosque' },

    // Detail page - Restaurant specific
    'detail.restaurant.title': { uz: 'Oshxona Ma\'lumotlari', ru: 'Информация о ресторане', en: 'Restaurant Information' },
    'detail.restaurant.reviewPrompt': { uz: 'Oshxona haqida fikringiz', ru: 'Ваше мнение о ресторане', en: 'Your opinion about the restaurant' },

    // Detail page - Shop specific
    'detail.shop.title': { uz: 'Do\'kon Ma\'lumotlari', ru: 'Информация о магазине', en: 'Shop Information' },
    'detail.shop.reviewPrompt': { uz: 'Do\'kon haqida fikringiz', ru: 'Ваше мнение о магазине', en: 'Your opinion about the shop' },

    // Months
    'month.0': { uz: 'Yanvar', ru: 'Январь', en: 'January' },
    'month.1': { uz: 'Fevral', ru: 'Февраль', en: 'February' },
    'month.2': { uz: 'Mart', ru: 'Март', en: 'March' },
    'month.3': { uz: 'Aprel', ru: 'Апрель', en: 'April' },
    'month.4': { uz: 'May', ru: 'Май', en: 'May' },
    'month.5': { uz: 'Iyun', ru: 'Июнь', en: 'June' },
    'month.6': { uz: 'Iyul', ru: 'Июль', en: 'July' },
    'month.7': { uz: 'Avgust', ru: 'Август', en: 'August' },
    'month.8': { uz: 'Sentyabr', ru: 'Сентябрь', en: 'September' },
    'month.9': { uz: 'Oktyabr', ru: 'Октябрь', en: 'October' },
    'month.10': { uz: 'Noyabr', ru: 'Ноябрь', en: 'November' },
    'month.11': { uz: 'Dekabr', ru: 'Декабрь', en: 'December' },

    // ========================================
    // Barcode Scanner Page
    // ========================================
    'bc.pageTitle': { uz: 'Tarkib Tekshirish', ru: 'Проверка состава', en: 'Ingredient Check' },

    // Hero / Permission screen
    'bc.badgeJoiz': { uz: '✅ Joiz', ru: '✅ Допустимо', en: '✅ Permissible' },
    'bc.badgeShubhali': { uz: '⚠️ Shubhali', ru: '⚠️ Сомнительно', en: '⚠️ Doubtful' },
    'bc.badgeTaqiqlangan': { uz: '⛔ Ta\'qiqlangan', ru: '⛔ Запрещено', en: '⛔ Prohibited' },
    'bc.heroTitle': { uz: 'Mahsulotni skanerlang', ru: 'Сканируйте продукт', en: 'Scan a product' },
    'bc.heroDesc': { 
      uz: 'Shtrix kodni kameraga ko\'rsating - tarkibida ta\'qiqlangan moddalar bor-yo\'qligini bir zumda bilib oling', 
      ru: 'Наведите камеру на штрих-код - мгновенно узнайте, содержит ли продукт запрещённые ингредиенты', 
      en: 'Point your camera at a barcode - instantly find out if the product contains prohibited ingredients' 
    },
    'bc.startScan': { uz: 'Skanerlashni boshlash', ru: 'Начать сканирование', en: 'Start scanning' },

    // Error states
    'bc.cameraError': { uz: 'Kameraga ulanib bo\'lmadi.', ru: 'Не удалось подключиться к камере.', en: 'Could not connect to camera.' },
    'bc.retry': { uz: '🔄 Qaytadan', ru: '🔄 Повторить', en: '🔄 Retry' },
    'bc.errNoCamera': { uz: 'Kamera topilmadi.', ru: 'Камера не найдена.', en: 'Camera not found.' },
    'bc.errCameraBusy': { uz: 'Kamera band. Boshqa ilovalarni yoping.', ru: 'Камера занята. Закройте другие приложения.', en: 'Camera busy. Close other apps.' },
    'bc.errCamera': { uz: 'Kamera xatoligi', ru: 'Ошибка камеры', en: 'Camera error' },
    'bc.errCameraSwitch': { uz: 'Kamerani almashtirib bo\'lmadi.', ru: 'Не удалось переключить камеру.', en: 'Could not switch camera.' },
    'bc.errPermDenied': { uz: 'Kamera ruxsati berilmagan. Brauzer sozlamalaridan ruxsat bering.', ru: 'Доступ к камере запрещён. Разрешите в настройках браузера.', en: 'Camera permission denied. Allow in browser settings.' },
    'bc.error': { uz: 'Xatolik', ru: 'Ошибка', en: 'Error' },

    // Scanner status
    'bc.searching': { uz: 'Qidirilmoqda...', ru: 'Поиск...', en: 'Searching...' },
    'bc.found': { uz: 'Topildi!', ru: 'Найдено!', en: 'Found!' },
    'bc.checking': { uz: 'Tekshirilmoqda...', ru: 'Проверка...', en: 'Checking...' },
    'bc.copied': { uz: 'Nusxalandi! ✅', ru: 'Скопировано! ✅', en: 'Copied! ✅' },

    // Verdict labels
    'bc.verdictJoiz': { uz: 'Joiz', ru: 'Допустимо', en: 'Permissible' },
    'bc.verdictTaqiqlangan': { uz: 'Joiz emas', ru: 'Запрещено', en: 'Prohibited' },
    'bc.verdictShubhali': { uz: 'Shubhali', ru: 'Сомнительно', en: 'Doubtful' },
    'bc.verdictJoizDesc': { uz: 'Tarkibida ta\'qiqlangan ingredientlar topilmadi', ru: 'Запрещённые ингредиенты не обнаружены', en: 'No prohibited ingredients found' },
    'bc.verdictTaqiqlanganDesc': { uz: 'Tarkibida ta\'qiqlangan ingredientlar aniqlandi', ru: 'Обнаружены запрещённые ингредиенты', en: 'Prohibited ingredients detected' },
    'bc.verdictShubhaliDesc': { uz: 'Ta\'qiqlangan moddalar yo\'q, lekin bir zavodda ishlab chiqarilgan yoki ayrim ingredientlar o\'zagi HAYVONlardan olingan bo\'lishi mumkin.', ru: 'Запрещенных веществ нет, но продукт произведен на том же заводе, или же некоторые ингредиенты МОГУТ быть животного происхождения.', en: 'No prohibited substances, but produced in same factory or the source of some ingredients MIGHT BE from the animal.' },
    
    
    'bc.cat.Drinks':            { uz: 'Ichimliklar',         ru: 'Напитки',           en: 'Drinks' },
    'bc.cat.Snacks':            { uz: 'Yengil ovqatlar',     ru: 'Снеки',              en: 'Snacks' },
    'bc.cat.Sweets':            { uz: 'Shirinliklar',        ru: 'Сладости',           en: 'Sweets' },
    'bc.cat.Ice Cream':         { uz: 'Muzqaymoq',           ru: 'Мороженое',          en: 'Ice Cream' },
    'bc.cat.Baked Goods':       { uz: 'Non mahsulotlari',    ru: 'Выпечка',            en: 'Baked Goods' },
    'bc.cat.Cup Noodles/Ramen': { uz: 'Lagʻmon/Ramen',     ru: 'Лапша / Рамен',      en: 'Noodles / Ramen' },
    'bc.cat.Lunchbox/Dosirak':  { uz: 'Pechenya/Pishiriqlar',   ru: 'Печенье/Выпечка', en: 'Cookies/Pastry' },
    'bc.cat.Dairy':             { uz: 'Sut mahsulotlari',    ru: 'Молочные',           en: 'Dairy' },
    'bc.cat.Canned Food':       { uz: 'Konserva',            ru: 'Консервы',           en: 'Canned Food' },
    'bc.cat.Frozen Food':       { uz: 'Muzlatilgan',         ru: 'Замороженные',       en: 'Frozen Food' },
    'bc.cat.Condiments/Sauces': { uz: 'Ziravor/Souslar',   ru: 'Приправы / Соусы',   en: 'Condiments / Sauces' },
    'bc.cat.Fruits/Vegetables': { uz: 'Meva/Sabzavot',     ru: 'Фрукты / Овощи',     en: 'Fruits / Vegetables' },
    'bc.cat.Dried Food':        { uz: 'Quritilgan',          ru: 'Сушёные',            en: 'Dried Food' },

 
    // ============================================
    // BARCODE - Result info banners (M4)
    // ============================================
    'bc.store.foundIn':       { uz: 'Topildi:',                                          ru: 'Найдено:',                                                en: 'Found in:' },
    
    'bc.store.generalDb':     { uz: 'Umumiy ma\'lumotlar bazasi',                        ru: 'Общая база данных',                                        en: 'General database' },
    'bc.store.storeUnknown':  { uz: '· Do\'kon belgilanmagan',                           ru: '· Магазин не указан',                                      en: '· Store not specified' },
    'bc.store.alsoAt':        { uz: 'Boshqa do\'konlarda ham bor:',                      ru: 'Также есть в этих магазинах:',                            en: 'Also available at:' },
    
    // ============================================
    // BARCODE - Store error states (M6)
    // ============================================
    'bc.store.metaError':       { uz: 'Do\'kon ma\'lumotlari yuklanmadi',                    ru: 'Не удалось загрузить данные магазина',                       en: "Couldn't load store data" },
    'bc.store.productsError':   { uz: 'Mahsulotlar yuklanmadi',                              ru: 'Не удалось загрузить товары',                                 en: "Couldn't load products" },
    'bc.store.checkConnection': { uz: 'Internetni tekshirib, qayta urinib ko\'ring.',        ru: 'Проверьте подключение и попробуйте снова.',                    en: 'Check your connection and try again.' },
    'bc.store.retry':           { uz: 'Qayta urinish',                                        ru: 'Повторить',                                                    en: 'Retry' },    
    
    // ============================================
    // BARCODE - Manual entry (M7)
    // ============================================
    'bc.manual.hint':        { uz: 'Skanerlash qiyin bo\'lyaptimi?',                                    ru: 'Не удаётся отсканировать?',                                    en: 'Trouble scanning?' },
    'bc.manual.label':       { uz: 'Shtrix-kodni qo\'lda kiriting:',                                    ru: 'Введите штрих-код вручную:',                                    en: 'Enter the barcode manually:' },
    'bc.manual.labelErr':    { uz: 'Yoki shtrix-kodni qo\'lda kiriting:',                               ru: 'Или введите штрих-код вручную:',                                en: 'Or enter the barcode manually:' },
    'bc.manual.placeholder': { uz: '8801234567890',                                            ru: '8801234567890',                                       en: 'e.g. 8801234567890' },
    'bc.manual.submit':      { uz: 'Qidirish',                                                          ru: 'Найти',                                                         en: 'Search' },
    
    'bc.manual.labelPerm':   { uz: 'Yoki shtrix-kodni qo\'lda kiriting:',                                ru: 'Или введите штрих-код вручную:',                                en: 'Or enter the barcode manually:' },
    // Validation errors
    'bc.manual.errEmpty':    { uz: 'Shtrix-kod kiriting.',                                              ru: 'Введите штрих-код.',                                            en: 'Please enter a barcode.' },
    'bc.manual.errNonDigit': { uz: 'Faqat raqamlar kiriting.',                                          ru: 'Используйте только цифры.',                                     en: 'Digits only.' },
    'bc.manual.errLength':   { uz: 'Shtrix-kod 8 dan 14 tagacha raqamdan iborat bo\'lishi kerak.',      ru: 'Штрих-код должен содержать от 8 до 14 цифр.',                   en: 'Barcode must be 8 to 14 digits.' },
    'bc.manual.errChecksum': { uz: 'Shtrix-kod noto\'g\'ri. Raqamlarni tekshiring.',                    ru: 'Штрих-код некорректен. Проверьте цифры.',                       en: 'Invalid barcode. Check the digits.' },
    'bc.manual.errInvalid':  { uz: 'Shtrix-kod noto\'g\'ri.',                                           ru: 'Некорректный штрих-код.',                                       en: 'Invalid barcode.' },
 
    // ============================================
    // BARCODE - Contributor recruitment banner (M4)
    // ============================================
    'bc.contrib.title': { uz: 'Halol baza yig\'ishga sherik bo\'ling',                                                                                         ru: 'Помогите нам собрать халяль-базу',                                                                                              en: 'Help us build the halal database' },
    'bc.contrib.body':  { uz: 'Mahsulotlar tarkibini o\'qiy oladiganlar uchun: GS25, CU, 7-Eleven, Emart24, No Brand va Daiso do\'konlaridagi halol mahsulotlar bazasini birgalikda yig\'amiz. Har bir yozuv minglab yurtdoshlarimizga yetib boradi - ortingizdan sadaqa-i joriyangizni qoldiring.', ru: 'Для тех, кто умеет читать состав продуктов: вместе собираем халяль-базу для GS25, CU, 7-Eleven, Emart24, No Brand и Daiso. Каждая запись помогает тысячам людей.', en: 'For those who can read product ingredients: together we collect a halal database for GS25, CU, 7-Eleven, Emart24, No Brand, and Daiso convenience stores. Every entry reaches thousands of people.' },
    'bc.contrib.cta':   { uz: 'Adminga yozish',                                                                                                                ru: 'Написать админу',                                                                                                                en: 'Contact admin' },
 
    // Product result
    'bc.ingredients': { uz: '🧪 Tarkibi', ru: '🧪 Состав', en: '🧪 Ingredients' },
    'bc.ingredientsTitle': { uz: '🧪 Mahsulot tarkibi', ru: '🧪 Состав продукта', en: '🧪 Product ingredients' },
    'bc.ingredientsLabel': { uz: '🧪 Tarkibi:', ru: '🧪 Состав:', en: '🧪 Ingredients:' },
    'bc.scanAgain': { uz: '📷 Qayta skanerlash', ru: '📷 Сканировать снова', en: '📷 Scan again' },
    'bc.infoLink': { uz: '🤔 Shubhali mahsulotni yesa bo\'ladimi?', ru: '🤔 Можно ли есть сомнительные продукты?', en: '🤔 Can I eat doubtful products?' },

    // Halal grid labels
    'bc.flag.pork': { uz: 'Cho\'chqa', ru: 'Свинина', en: 'Pork' },
    'bc.flag.alcohol': { uz: 'Alkogol', ru: 'Алкоголь', en: 'Alcohol' },
    'bc.grid.meat': { uz: 'Boshqa go\'sht', ru: 'Другое мясо', en: 'Other meat' },
    'bc.grid.seafood': { uz: 'Dengiz m.', ru: 'Морепродукты', en: 'Seafood' },
    'bc.absent': { uz: 'yo\'q', ru: 'нет', en: 'none' },
    'bc.present': { uz: 'bor', ru: 'есть', en: 'present' },

    // Factory
    'bc.flag.ambiguous': {uz: "Manbasi noma'lum", ru: "Неизвестное происхождение", en: "Unknown source"},
    'bc.ambiguousWarn': {uz: "Tarkibida 트랜스지방, 쇼트닝, 향료 yoki 글리세린 mavjud - o'simlik yoki HAYVON YO\'G\'Idan olinishi mumkin.", ru: "Содержит 트랜스지방, 쇼트닝, 향료 или 글리세린 - может быть растительного или животного  происхождения (жир).", en: "Contains 트랜스지방, 쇼트닝, 향료 or 글리세린 - may be of plant or animal FAT origin."},
    
    
    'bc.factoryWarn': { uz: 'Mahsulot ta\'qiqlangan ingredientlar tayyorlanadigan zavod/uskunalarda ishlab chiqarilgan.', ru: 'Продукт произведён на оборудовании, где производятся запрещённые продукты.', en: 'Product manufactured on equipment where prohibited products are produced.' },
    'bc.factoryOk': { uz: 'Mahsulot ishlab chiqarilgan zavod/uskunalarda ta\'qiqlangan mahsulotlar ishlatilmaydi.', ru: 'На заводе/оборудовании не производятся запрещённые продукты.', en: 'No prohibited products are manufactured on this equipment.' },

    // Not found
    'bc.notFound': { uz: 'Mahsulot topilmadi', ru: 'Продукт не найден', en: 'Product not found' },
    'bc.notFoundDesc': { uz: 'Ushbu mahsulot hozircha bazada yo\'q. Tez orada qo\'shilishi mumkin.', ru: 'Этот продукт пока отсутствует в базе. Возможно, он будет добавлен позже.', en: 'This product is not in the database yet. It may be added later.' },
    

    
 
    // ============================================
    // BARCODE - Stores section (M2)
    // ============================================
    'bc.stores.title':     { uz: '🏪 Do\'konlar', ru: '🏪 Магазины', en: '🏪 Stores' },
    'bc.stores.sub':       { uz: 'Do\'kon tanlang va mahsulotlarini ko\'ring', ru: 'Выберите магазин, чтобы увидеть его товары', en: 'Pick a store to browse its products' },
    'bc.stores.products':  { uz: 'ta mahsulot', ru: 'товаров', en: 'products' },
    'bc.stores.soon':      { uz: 'Yaqinda', ru: 'Скоро', en: 'Soon' },
    'bc.stores.loadError': { uz: 'Do\'konlar yuklanmadi', ru: 'Не удалось загрузить магазины', en: 'Could not load stores' },
    'bc.stores.empty':     { uz: 'Hozircha do\'konlar mavjud emas', ru: 'Магазинов пока нет', en: 'No stores available yet' },
 
    // ============================================
    // BARCODE - Store detail page (M3)
    // ============================================
    'bc.store.pageTitle':  { uz: 'Do\'kon Mahsulotlari', ru: 'Товары магазина', en: 'Store Products' },
    'bc.store.category': { uz: 'Turkum', ru: 'Категория', en: 'Category' },
    'bc.store.allCats':    { uz: 'Hammasi', ru: 'Все', en: 'All' },
    'bc.store.emptyTitle': { uz: 'Mahsulot topilmadi', ru: 'Товары не найдены', en: 'No products found' },
    'bc.store.emptyDesc':  { uz: 'Boshqa turkum yoki hukm bo\'yicha qidiring.', ru: 'Попробуйте другую категорию или вердикт.', en: 'Try another category or verdict.' },
    'bc.store.loadMore':   { uz: 'Ko\'proq ko\'rsatish', ru: 'Показать ещё', en: 'Show more' },
    
    
    
    'bc.flag.meat': { uz: 'Boshqa go\'shtlar', ru: 'Другое мясо', en: 'Other meats' },
    'bc.flag.seafood': { uz: 'Dengiz mahsulotlari', ru: 'Морепродукты', en: 'Seafood' },
        
    // Disclaimer
    'bc.disclaimer': { 
      uz: 'Bu ma\'lumotlar faqat mahsulot tarkibi asosida taqdim etilgan bo\'lib, <strong>xatoliklar bo\'lishi mumkin</strong>. Biz rasmiy diniy hukm (fatvo) bermaymiz. Xatolik topsangiz <a href="https://t.me/MuslimVegukin">Telegram guruhimizga</a> o\'tib xabar bering.',
      ru: 'Эта информация предоставлена только на основе состава продукта и <strong>может содержать ошибки</strong>. Мы не выносим официальных религиозных решений (фатва). Если нашли ошибку, сообщите в нашу <a href="https://t.me/MuslimVegukin">Telegram группу</a>.',
      en: 'This information is provided based on product ingredients only and <strong>may contain errors</strong>. We do not issue official religious rulings (fatwa). If you find an error, please report it in our <a href="https://t.me/MuslimVegukin">Telegram group</a>.'
    },
    
// Page title
    'hk.pageTitle': {
      uz: 'HiKorea - joy kuzatuvchi',
      ru: 'HiKorea - слежение за слотами',
      en: 'HiKorea - your slot watcher',
    },

    // Generic
    'hk.back': { uz: 'Orqaga', ru: 'Назад', en: 'Back' },
    'hk.time.now': { uz: 'hozir', ru: 'только что', en: 'just now' },
    'hk.time.ago': { uz: 'oldin', ru: 'назад',      en: 'ago' },

    // HOME
    'hk.home.title': {
      uz: 'Immigratsiyada joy bron qilish',
      ru: 'Найдите время записи',
      en: 'Find your appointment slot',
    },
    'hk.home.lede': {
      uz: 'Bot HiKorea websaytini 24/7 kuzatib, belgilagan vaqtingiz oralig\'ida joy ochilishi bilan sizga Telegram orqali xabar yuboradi.',
      ru: 'Бот круглосуточно отслеживает сайт HiKorea и отправляет вам уведомление через Telegram, когда появляется свободное место в указанный вами период времени.',
      en: "Bot monitors the HiKorea website 24/7 and sends you a message via Telegram when a spot opens up during the time period you specify.",
    },
    
    'hk.home.watchingPre':  { uz: 'Faol kuzatuvlar soni:', ru: 'Слежу за', en: 'Watching' },
    'hk.home.watchingPost': { uz: 'ta',  ru: 'диапазон(ов)', en: 'slot range(s)' },
    'hk.home.step1': { uz: 'Tegishli immigratsiya ofisini tanlang',       ru: 'Выберите офис',          en: 'Pick your office' },
    'hk.home.step2': { uz: "Mavjud sanalarni ko'ring",   ru: 'Посмотрите свободные даты', en: 'See open dates' },
    'hk.home.step3': {
      uz: 'Joy ochilganda Telegram orqali xabar oling',
      ru: 'Получите ping в Telegram, когда появится слот',
      en: 'Get a Telegram ping when a slot opens',
    },
    'hk.home.searchLabel': {
      uz: 'Qaysi immigratsiya ofisiga borasiz?',
      ru: 'Какой офис обрабатывает вашу заявку?',
      en: 'Which office handles your case?',
    },
    'hk.home.searchPlaceholder': {
      uz: 'Ofis nomini izlash...',
      ru: 'Поиск офиса...',
      en: 'Search by office name...',
    },
    'hk.home.addressLink': {
      uz: 'Uy manzilingizni kiritish orqali tegishli ofisni aniqlash →',
      ru: 'Не знаете свой офис? Найдите по домашнему адресу →',
      en: "Don't know your office? Find it by your home address →",
    },
    'hk.home.noMatch': {
      uz: 'Hech qanday ofis topilmadi. Boshqa so\'z bilan izlang yoki yuqoridagi "Uy manzili orqali topish" havolasini bosing.',
      ru: 'Ничего не найдено. Попробуйте другое слово или нажмите "Найти по адресу" выше.',
      en: "No offices match. Try a different word, or use 'Find by address' above.",
    },
    'hk.home.oneCounter':   { uz: '1 ta bo\'lim',  ru: '1 окно',  en: '1 counter'   },
    'hk.home.manyCounters': { uz: 'ta bo\'lim',    ru: 'окон',     en: 'counters'   },

    // BY-ADDRESS
    'hk.address.title': {
      uz: 'Uy manzili bo\'yicha immigratsiya ofisini izlash',
      ru: 'Найти офис по адресу',
      en: 'Find your office by address',
    },
    'hk.address.lede': {
      uz: 'Har bir ofis muayyan tumanlarga xizmat ko\'rsatadi. Yashash manzilingizni kiritish orqali tegishli ofisni topish.',
      ru: 'Каждый офис обслуживает определённые районы. Скажите, где живёте, и мы подберём.',
      en: "Each office serves specific districts. Tell us where you live and we'll match it.",
    },
    'hk.address.provinceLabel': {
      uz: '1. Viloyatingizni tanlang',
      ru: '1. Выберите провинцию',
      en: '1. Pick your province',
    },
    'hk.address.provincePlaceholder': { uz: '- tanlang -', ru: '- выбрать -', en: '- select -' },
    'hk.address.addressLabel': {
      uz: '2. To\'liq uy manzilingizni koreys tilida kiriting',
      ru: '2. Введите домашний адрес на корейском',
      en: '2. Type your home address in Korean',
    },
    'hk.address.hint': {
      uz: '💡 Manzilingizda tegishli shahar/tuman nomi (-시/-구/-군) bo\'lishi shart, masalan 강남구, 성남시 yoki 원주군.',
      ru: '💡 В вашем адресе должно быть указано соответствующее название города/района (-시/-구/-군), например, 강남구, 성남시 или 원주군.',
      en: '💡 Your address must contain the appropriate city/district name (-시/-구/-군), such as 강남구, 성남시, or 원주군.',
    },
    'hk.address.findBtn':      { uz: 'Ofisni izlash',       ru: 'Найти мой офис',           en: 'Find my office' },
    'hk.address.needProvince': { uz: 'Avval viloyatni tanlang.', ru: 'Сначала выберите провинцию.', en: 'Pick your province first' },
    'hk.address.needAddress':  { uz: 'Manzilingizni kiriting.',  ru: 'Введите адрес.',              en: 'Enter your address' },

    'hk.address.foundOne':     { uz: 'Immigratsiya ofisi:',  ru: 'Иммиграционная служба::',                en: "Immigration office:" },
    'hk.address.foundMany':    { uz: 'Mosini tanlang:',           ru: 'Выберите подходящий:',         en: 'Pick the one that matches:' },
    'hk.address.noMatch': {
      uz: 'Ushbu manzil uchun ofis topilmadi. Manzil to\'liq kiritilgan bo\'lishi kerak.',
      ru: 'Офис по этому адресу не найден. Адрес необходимо ввести полностью.',
      en: "No office was found for this address. The address must be entered in full.",
    },

    // BOOTH PICKER
    'hk.booth.title': { uz: 'Bir nechta bo\'limlar mavjud.', ru: 'Какое окно вам нужно?', en: 'Which counter do you need?' },
    'hk.booth.lede': {
          uz: 'Mavjud bo\'limlar o\'zining joylashuvi, qavati yoki ro\'yxat ochilish vaqti bilan farq qilishi mumkin. Lekin bir xil ishni bajaradi. Har birining kalendarini ko\'rib, o\'zingizga qulayini tanlang. Diqqat: ba\'zi bo\'limlar turli manzillarda joylashgan, shuning uchun tanlashdan oldin tegishli tavsifni o\'qing.',
          ru: 'Окна одного офиса могут отличаться расположением, этажом или временем начала записи - но выполняют одну и ту же работу. Посмотрите календарь каждого и выберите удобное. Важно: в некоторых офисах окна находятся в разных местах, поэтому перед выбором прочитайте описание.',
          en: "Counters at the same office can differ by location, floor, or when registration opens - but they do the same job. Check each one's calendar and pick whichever suits you. Note: at some offices the counters are in different places, so read the description before choosing.",
        },
    'hk.booth.none':      { uz: 'Bu ofisda bo\'lim mavjud emas.', ru: 'У офиса нет доступных окон.', en: 'No counters available for this office.' },
    'hk.booth.afternoon': { uz: 'Qabul 09:36 dan keyin boshlanadi.', ru: 'Регистрация начинается после 09:36.', en: 'Reception starts after 09:36.' },

    // CALENDAR
    'hk.cal.lede': {
      uz: "Sanani bosib, joylar borligini ko'ring. Yo'q bo'lsa pastdagi xabar berish tugmasini bosing. Joy ochilganda xabar yuboramiz.",
      ru: 'Нажмите на любую дату, чтобы увидеть слоты. Нет нужной? Жмите кнопку ниже - напишем, когда появится.',
      en: "Tap any date to see if it's bookable. Don't see what you want? Tap the button below - we'll notify you the moment a slot opens.",
    },

    'hk.cal.checked':   { uz: 'Tekshirildi:',          ru: 'Проверено:',           en: 'Checked:' },
    'hk.cal.notifyCta': {
      uz: 'Joy ochilganda xabar berish',
      ru: 'Сообщите, когда появится слот',
      en: 'Notify me when a slot opens',
    },
    'hk.cal.allFullNote': {
      uz: "Hozirda hamma sana band qilingan. Kimdir bekor qilishi ortidan joy ochilishi bilan sizga xabar yuboriladi.",
      ru: 'Сейчас всё занято - самое время поставить слежение. Напишем, как только что-то освободится.',
      en: "Looks like every visible date is full right now. That's exactly when a watch helps - we'll ping you the moment something opens.",
    },

    // DATE SHEET (plain-language phrases)
    'hk.sheet.bookNow':       { uz: "HiKorea'da band qilish →", ru: 'Забронировать на HiKorea →', en: 'Book on HiKorea →' },

    'hk.sheet.close':         { uz: 'Yopish',                   ru: 'Закрыть',                   en: 'Close' },
    'hk.sheet.bookCue': {
      uz: 'Tegishli vaqtni band qilish uchun HiKorea\' websaytiga o\'ting.',
      ru: 'Чтобы забронировать подходящее время, зайдите на сайт HiKorea.',
      en: 'To book a suitable time, go to HiKorea\'s website.',
    },
    'hk.sheet.fullCue': {
      uz: "Hozirda bo'sh joy yo'q. Kuzatishni yoqib qo'ysangiz, bo'sh joy ochilganda Telegram orqali xabar yuboriladi.",
      ru: 'В данный момент свободных мест нет - установите таймер, и мы пришлем вам уведомление, когда появится свободное место.',
      en: "No spots right now - set a watch and we'll send you a message when one opens.",
    },

    // WATCH SETUP
    'hk.watch.title': { uz: 'Kuzatuv muddati:', ru: 'Период наблюдения:', en: 'Watch period:' },
    'hk.watch.lede': {
      uz: 'Sizga kerakli sanalarni tanlang. Shu oraliqda joy ochilsa, darhol Telegram orqali xabar yuboriladi.',
      ru: 'Выберите даты, которые вам подходят. Если в этом диапазоне появится слот, тут же напишем в Telegram.',
      en: "Pick the dates you're flexible with. If a slot opens within this range, we'll send you a Telegram message right away.",
    },
    'hk.watch.quickLabel': { uz: "⚡ Tezkor tanlash", ru: '⚡ Быстрый выбор', en: '⚡ Quick pick' },
    'hk.watch.orLabel':    { uz: 'yoki aniq sanalarni tanlang', ru: 'или выберите конкретные даты', en: 'or pick specific dates' },
    'hk.watch.p7':  { uz: 'Keyingi 7 kun',  ru: '7 дней',  en: 'Next 7 days'  },
    'hk.watch.p14': { uz: 'Keyingi 14 kun', ru: '14 дней', en: 'Next 14 days' },
    'hk.watch.p30': { uz: 'Keyingi 30 kun', ru: '30 дней', en: 'Next 30 days' },
    'hk.watch.p60': { uz: 'Keyingi 60 kun', ru: '60 дней', en: 'Next 60 days' },
    'hk.watch.fromLabel': { uz: 'Boshlanishi', ru: 'С',  en: 'From' },
    'hk.watch.toLabel':   { uz: 'Tugashi',     ru: 'По', en: 'To'   },
    'hk.preview.watching':{ uz: 'Kuzatilmoqda',   ru: 'Слежу за',       en: 'Watching' },
    'hk.preview.days':    { uz: 'kun ichida',     ru: 'дней в окне',    en: 'days in your window' },
    'hk.preview.oneDay':  { uz: '1 kun ichida',   ru: '1 день в окне',  en: '1 day in your window' },
    'hk.watch.createBtn': { uz: 'Kuzatishni boshlash', ru: 'Начать слежение', en: 'Start watching' },
    
    
    // Calendar legend

    'hk.cal.legClosed': {
      uz: 'Yopiq / oyna tashqarisida',
      ru: 'Закрыто / вне окна',
      en: 'Closed / past the window',
    },
    'hk.cal.allFullNote': {
      uz: "Hozir hech qanday sana ko'rinmayapti. Kuzatish funksiyasini yoqing. Joy ochilishi bilan xabar yuboramiz.",
      ru: 'Сейчас нет доступных дат. Поставьте слежение - напишем, как только что-то появится.',
      en: "No dates visible right now. Set a watch and we'll ping you the moment one opens.",
    },

    // Date sheet - live fetch states (new)
    'hk.sheet.loading': {
      uz: 'HiKorea\'dan tekshirilmoqda…',
      ru: 'Проверяем HiKorea…',
      en: 'Checking HiKorea right now…',
    },
    'hk.sheet.fetchFail': {
      uz: 'HiKorea\'ga ulanib bo\'lmadi. Bir ozdan keyin urinib ko\'ring.',
      ru: 'Не удалось связаться с HiKorea. Попробуйте через минуту.',
      en: "Couldn't reach HiKorea just now. Try again in a moment.",
    },
    'hk.sheet.sessionExpired': {
      uz: 'HiKorea seansimiz yangilanishi kerak - administratorga xabar berildi. Bir muddatdan keyin urinib ko\'ring.',
      ru: 'Сессия HiKorea просрочена - администратор уведомлён. Попробуйте через минуту.',
      en: "Our HiKorea login needs refreshing - the admin has been notified. Try again in a moment.",
    },
    'hk.sheet.closed': {
      uz: 'Bu kunda ofis ishlamaydi',
      ru: 'Офис в этот день закрыт',
      en: 'Office closed this day',
    },
    'hk.sheet.fullyBooked': {
      uz: "To'la band qilingan",
      ru: 'Полностью занято',
      en: 'Fully booked',
    },
    'hk.sheet.lastOne': {
      uz: 'Faqat 1 ta joy - shoshiling',
      ru: 'Только 1 место - успейте!',
      en: 'Just 1 slot left - grab it!',
    },
    'hk.sheet.fewLeft': {
      uz: 'ta joy - shoshiling',
      ru: 'мест - поспешите!',
      en: 'slots left - hurry!',
    },
    'hk.sheet.slotsLeft': {
      uz: 'ta joy qoldi',
      ru: 'мест осталось',
      en: 'slots left',
    },
    'hk.sheet.slotsOpen': {
      uz: "ta joy bo'sh",
      ru: 'свободных мест',
      en: 'slots open',
    },

    // SUCCESS
    'hk.success.title': { uz: 'Tayyor', ru: 'Готово!',           en: "You're all set" },
    'hk.success.text':  {
      uz: "Tanlagan oralig'ingizda joy ochilishi bilan Telegram orqali xabar yuboramiz. Kuzatishlaringizni boshqarish uchun quyidagi tugmani bosing.",
      ru: 'Напишем в Telegram, как только в вашем диапазоне появится слот. Нажмите кнопку ниже, чтобы управлять своими слежениями.',
      en: "We'll send you a Telegram message the moment a slot opens in your range. Click the button below to manage your watches.",
    },
    'hk.success.ok': { uz: 'Kuzatishlarimni ko\'rish', ru: 'Мои слежения', en: 'See my watches' },

    // MY WATCHES
    'hk.watches.title': { uz: 'Faol kuzatishlar', ru: 'Активные слежения', en: 'Your active watches' },
    'hk.watches.lede': {
      uz: "Quyidagi sana oraliqlarini kuzatib turilmoqda. Joy ochilishi bilan Telegram orqali xabar beriladi.",
      ru: 'Отслеживаются следующие временные рамки. Уведомления будут отправлены через Telegram, как только появится свободное время.',
      en: "The following date ranges are being monitored. Notifications will be sent via Telegram as soon as a slot becomes available.",
      
    },
    'hk.watches.emptyTitle': { uz: "Hali kuzatish yo'q",  ru: 'Пока ничего',          en: 'No watches yet' },
    'hk.watches.emptySub': {
      uz: 'Immigratsiya ofisini tanlab, birinchi kuzatishingizni o\'rnating.',
      ru: 'Выберите офис и поставьте первое слежение.',
      en: 'Pick an office and set your first one.',
    },
    'hk.watches.cancel':  { uz: "To'xtatish",  ru: 'Остановить',  en: 'Stop watching' },
    'hk.watches.stopped': { uz: "To'xtatildi", ru: 'Остановлено', en: 'Watch stopped' },

    // ERRORS
    'hk.err.offices':   { uz: "Ofislarni yuklashda xatolik - qayta urinib ko'ring", ru: 'Ошибка загрузки офисы — пожалуйста, попробуйте еще раз.', en: "Couldn't load offices - please try again" },
    'hk.err.resolve':   { uz: "Ofisni topa olmadik - qayta urinib ko'ring",     ru: 'Не смогли найти офис - попробуйте ещё',     en: "Couldn't look up office - try again" },
    'hk.err.slots':     { uz: "Bu bo\'lim kalendarini yuklanmadi. Bir ozdan keyin urinib ko'ring.", ru: 'Не смогли загрузить календарь окна. Попробуйте через минуту.', en: "Couldn't load this counter's calendar. Try again in a moment." },
    'hk.err.watches':   { uz: "Kuzatishlaringizni yuklashda xatolik", ru: 'Не смогли загрузить ваши слежения', en: "Couldn't load your watches" },
    'hk.err.cancel':    { uz: "Kuzatishni to'xtatib bo'lmadi",    ru: 'Не удалось остановить',              en: "Couldn't stop the watch - try again" },
    'hk.err.create':    { uz: "Kuzatish yaratishda xatolik - qayta urinib ko'ring", ru: 'Не смогли создать - попробуйте ещё', en: "Couldn't create the watch - try again" },
    'hk.err.dup':       { uz: 'Bunday kuzatish allaqachon bor',   ru: 'Такое слежение уже есть',          en: "You've already set this watch" },
    'hk.err.max':       { uz: "Maksimal 10 ta - bittasini to'xtating", ru: 'Максимум 10 - остановите одно', en: "You've hit the limit (10). Cancel one first." },
    'hk.err.input':     { uz: 'Sanalarni tekshiring',              ru: 'Проверьте даты',                    en: 'Check your dates' },
    'hk.err.pickDates': { uz: "Sana tanlang",                      ru: 'Выберите даты',                    en: 'Pick a start and end date' },
    'hk.err.noUser':    { uz: 'Bu sahifani Telegram bot orqali oching.', ru: 'Откройте эту страницу через Telegram-бота.', en: 'Open this page from the Telegram bot first.' },
        
    'hk.cal.legEmpty':   { uz: "Bo'sh",         ru: 'Свободно',     en: 'Wide open' },
    'hk.cal.legPartial': { uz: 'Bandlik bor',   ru: 'Есть брони',   en: 'Some bookings' },
    'hk.cal.legFull':    { uz: "To'la band",    ru: 'Полностью занято', en: 'Fully booked' },
    'hk.cal.legClosed':  { uz: 'Yopiq',         ru: 'Закрыто',      en: 'Closed' },

    'hk.watches.status.active': {
      uz: 'Faol',         ru: 'Активно',     en: 'Active',
    },
    'hk.watches.status.undeliverable': {
      uz: 'Yetkazilmadi', ru: 'Не доставлено', en: 'Undeliverable',
    },
    'hk.watches.status.cancelled': {
      uz: "To'xtatilgan", ru: 'Остановлено', en: 'Cancelled',
    },
    'hk.watches.status.expired': {
      uz: 'Muddati tugagan', ru: 'Истекло',  en: 'Expired',
    },

    'hk.sheet.leftOne': {
      uz: "ta qoldi",  ru: 'осталось', en: 'left',
    },
    'hk.sheet.leftMany': {
      uz: "ta qoldi",  ru: 'осталось', en: 'left',
    },
    'hk.sheet.slotFull': {
      uz: "Band",   ru: 'Занято',   en: 'Full',
    },
    'hk.sheet.openOfTotal': {
      uz: "ta bo'sh",   ru: 'свободно', en: 'open',
    },
    'hk.sheet.allFull': {
      uz: "hammasi band",
      ru: 'всё занято',
      en: 'all full',
    },

    // Sheet morning/afternoon labels
    'hk.sheet.morning':   { uz: '🌅 Ertalab',     ru: '🌅 Утро',     en: '🌅 Morning' },
    'hk.sheet.afternoon': { uz: '🌇 Tushdan keyin', ru: '🌇 День',    en: '🌇 Afternoon' },

    // Sheet progress meta
    'hk.sheet.booked':    { uz: 'ta band',  ru: 'занято', en: 'booked' },
    'hk.sheet.openLabel': { uz: "ta bo'sh", ru: 'свободно', en: 'open' },
    

    // Success overlay - test notification
    'hk.success.testBtn': {
      uz: '📨 Sinov xabarini yuborish',
      ru: '📨 Отправить тестовое уведомление',
      en: '📨 Send me a test notification',
    },
    'hk.success.testHint': {
      uz: "Telegram'da haqiqiy bildirishnoma qanday ko'rinishini ko'ring.",
      ru: 'Посмотрите, как реальное уведомление будет выглядеть в Telegram.',
      en: 'See exactly what a real alert will look like in Telegram.',
    },
    'hk.success.testSending': { uz: 'Yuborilmoqda…',  ru: 'Отправляем…', en: 'Sending…' },
    'hk.success.testSent':    { uz: "Telegram'ni tekshiring", ru: 'Проверьте Telegram', en: 'Check your Telegram' },
    'hk.success.testFail':    {
      uz: "Yuborib bo'lmadi. Botni Telegram'da ishga tushirib, qayta urinib ko'ring.",
      ru: 'Не удалось отправить. Запустите бота в Telegram и попробуйте снова.',
      en: "Couldn't send. Make sure you've started the bot in Telegram, then try again.",
    },
    'hk.dow.mon': { uz: 'Dush', ru: 'Пон', en: 'Mon' },
    'hk.dow.tue': { uz: 'Sesh', ru: 'Втр', en: 'Tue' },
    'hk.dow.wed': { uz: 'Chor', ru: 'Срд', en: 'Wed' },
    'hk.dow.thu': { uz: 'Pay',  ru: 'Чтв', en: 'Thu' },
    'hk.dow.fri': { uz: 'Juma', ru: 'Птн', en: 'Fri' },
    'hk.dow.sat': { uz: 'Shan', ru: 'Сбт', en: 'Sat' },
    'hk.dow.sun': { uz: 'Yak',  ru: 'Вск', en: 'Sun' },
    'hk.dowFull.mon': { uz: 'Dushanba',  ru: 'Понедельник', en: 'Monday' },
    'hk.dowFull.tue': { uz: 'Seshanba',  ru: 'Вторник',     en: 'Tuesday' },
    'hk.dowFull.wed': { uz: 'Chorshanba',ru: 'Среда',       en: 'Wednesday' },
    'hk.dowFull.thu': { uz: 'Payshanba', ru: 'Четверг',     en: 'Thursday' },
    'hk.dowFull.fri': { uz: 'Juma',      ru: 'Пятница',     en: 'Friday' },
    'hk.dowFull.sat': { uz: 'Shanba',    ru: 'Суббота',     en: 'Saturday' },
    'hk.dowFull.sun': { uz: 'Yakshanba', ru: 'Воскресенье', en: 'Sunday' },
    'hk.month.1':  { uz: 'Yanvar',   ru: 'Январь',   en: 'January'   },
    'hk.month.2':  { uz: 'Fevral',   ru: 'Февраль',  en: 'February'  },
    'hk.month.3':  { uz: 'Mart',     ru: 'Март',     en: 'March'     },
    'hk.month.4':  { uz: 'Aprel',    ru: 'Апрель',   en: 'April'     },
    'hk.month.5':  { uz: 'May',      ru: 'Май',      en: 'May'       },
    'hk.month.6':  { uz: 'Iyun',     ru: 'Июнь',     en: 'June'      },
    'hk.month.7':  { uz: 'Iyul',     ru: 'Июль',     en: 'July'      },
    'hk.month.8':  { uz: 'Avgust',   ru: 'Август',   en: 'August'    },
    'hk.month.9':  { uz: 'Sentabr',  ru: 'Сентябрь', en: 'September' },
    'hk.month.10': { uz: 'Oktabr',   ru: 'Октябрь',  en: 'October'   },
    'hk.month.11': { uz: 'Noyabr',   ru: 'Ноябрь',   en: 'November'  },
    'hk.month.12': { uz: 'Dekabr',   ru: 'Декабрь',  en: 'December'  },
    'hk.summary.earliestLabel': {
      uz: 'Bron qilish uchun eng erta joy:', ru: 'Ближайший слот:', en: 'Earliest opening:',
    },

    'hk.summary.allFull': {
      uz: "Hozir hamma sana to'la",
      ru: 'Сейчас всё занято',
      en: 'Everything is fully booked',
    },
    'hk.summary.setWatch': {
      uz: "Kuzatish o'rnating - joy ochilishi bilan xabar yuboramiz.",
      ru: 'Поставьте слежение - напишем, как только освободится.',
      en: "Set a watch - we'll ping you when a slot opens.",
    },
    'hk.watch.tapPick': { uz: 'Sanani tanlang', ru: 'Выберите дату', en: 'Tap to pick' },
    'hk.cal.pullToRefresh':    { uz: 'Yangilash',   ru: 'Oбновления', en: 'Refresh' },
    'hk.cal.releaseToRefresh': { uz: 'Yangilash', ru: 'Oбновления', en: 'Refresh'},
    'hk.cal.refreshing':       { uz: 'Yangilanmoqda…',            ru: 'Обновление…',             en: 'Refreshing…' },
  },

  init() {
    const saved = localStorage.getItem(this.STORAGE_KEY);
    if (saved && ['uz', 'ru', 'en'].includes(saved)) {
      this.currentLang = saved;
    }
    console.log('✅ I18N initialized:', this.currentLang);
    return this.currentLang;
  },

  t(key) {
    const trans = this.translations[key];
    if (!trans) return key;
    return trans[this.currentLang] || trans['uz'] || key;
  },

  setLanguage(lang) {
    if (!['uz', 'ru', 'en'].includes(lang)) return false;
    this.currentLang = lang;
    localStorage.setItem(this.STORAGE_KEY, lang);
    window.dispatchEvent(new CustomEvent('languageChanged', { detail: { language: lang } }));
    console.log('✅ Language set to:', lang);
    return true;
  },

  getLanguage() {
    return this.currentLang;
  },

  getAvailableFeatures() {
    return this.availableFeatures[this.currentLang] || this.availableFeatures['uz'];
  }
};

I18N.init();
window.I18N = I18N;
window.t = (key) => I18N.t(key);