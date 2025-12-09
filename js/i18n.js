// i18n.js - Internationalization System for Muslim Vegukin Bot
// Supports: Uzbek (uz), Russian (ru), English (en)

const I18N = {
  currentLang: 'uz',
  STORAGE_KEY: 'vegukin_language',

  availableFeatures: {
    uz: ['mosque', 'restaurant', 'shop', 'qibla', 'parcel', 'links', 'jobs', 'donation', 'barcode', 'community', 'news', 'events', 'market'],
    ru: ['mosque', 'restaurant', 'shop', 'qibla', 'donation', 'community'],
    en: ['mosque', 'restaurant', 'shop', 'qibla', 'donation', 'community']
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
    'feature.parcel': { uz: 'Pochta', ru: 'Почта', en: 'Parcel' },
    'feature.links': { uz: 'Foydali linklar', ru: 'Полезные ссылки', en: 'Useful Links' },
    'feature.jobs': { uz: 'Ish e\'lonlari', ru: 'Вакансии', en: 'Job Listings' },
    'feature.donation': { uz: 'Qo\'llab-quvvatlash', ru: 'Поддержать', en: 'Support' },
    'feature.barcode': { uz: 'Shtrix Kod', ru: 'Штрих-код', en: 'Barcode' },
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
    'community.allowed1': { uz: '<strong>Yangi manzillar haqida xabar berish</strong> — yangi masjid, restoran yoki do\'kon qo\'shilishi kerak bo\'lsa', ru: '<strong>Сообщения о новых адресах</strong> — если нужно добавить новую мечеть, ресторан или магазин', en: '<strong>Report new locations</strong> — if a new mosque, restaurant or shop needs to be added' },
    'community.allowed2': { uz: '<strong>Takliflar va g\'oyalar</strong> — botni yaxshilash uchun fikrlaringiz', ru: '<strong>Предложения и идеи</strong> — ваши мысли по улучшению бота', en: '<strong>Suggestions and ideas</strong> — your thoughts on improving the bot' },
    'community.allowed3': { uz: '<strong>Xatolar haqida xabar berish</strong> — agar botda muammo topsangiz', ru: '<strong>Сообщения об ошибках</strong> — если вы нашли проблему в боте', en: '<strong>Bug reports</strong> — if you find a problem in the bot' },
    'community.allowed4': { uz: '<strong>Bot yangiliklari</strong> — yangi funksiyalar va o\'zgarishlar haqida e\'lonlar', ru: '<strong>Новости бота</strong> — объявления о новых функциях и изменениях', en: '<strong>Bot news</strong> — announcements about new features and changes' },
    'community.allowed5': { uz: '<strong>Beta versiyalar muhokamasi</strong> — yangi funksiyalarni ommaga chiqarishdan oldin sinab ko\'rish', ru: '<strong>Обсуждение бета-версий</strong> — тестирование новых функций перед публичным релизом', en: '<strong>Beta version discussions</strong> — testing new features before public release' },
    'community.allowed6': { uz: '<strong>Bot haqida savollar</strong> — qanday ishlatish, funksiyalar haqida', ru: '<strong>Вопросы о боте</strong> — как использовать, о функциях', en: '<strong>Questions about the bot</strong> — how to use, about features' },
    'community.allowed7': { uz: '<strong>Jamiyat bilan muloqot</strong> — boshqa foydalanuvchilar bilan tajriba almashish', ru: '<strong>Общение с сообществом</strong> — обмен опытом с другими пользователями', en: '<strong>Community interaction</strong> — sharing experiences with other users' },
    'community.rulesTitle': { uz: 'Guruh qoidalari', ru: 'Правила группы', en: 'Group rules' },
    'community.rulesWarning': { uz: 'Quyidagi turdagi xabarlar <strong>o\'chirib tashlanadi</strong>:', ru: 'Следующие типы сообщений <strong>будут удалены</strong>:', en: 'The following types of messages <strong>will be deleted</strong>:' },
    'community.prohibited1': { uz: '<strong>Reklama va savdo e\'lonlari</strong> — har qanday turdagi sotish yoki xarid e\'lonlari', ru: '<strong>Реклама и торговые объявления</strong> — любые объявления о продаже или покупке', en: '<strong>Ads and sales announcements</strong> — any buy or sell advertisements' },
    'community.prohibited2': { uz: '<strong>O\'quv kurslari reklamasi</strong> — til kurslari, o\'quv markazlari va boshqalar', ru: '<strong>Реклама курсов</strong> — языковые курсы, учебные центры и прочее', en: '<strong>Course advertisements</strong> — language courses, learning centers, etc.' },
    'community.prohibited3': { uz: '<strong>Bot bilan bog\'liq bo\'lmagan savollar</strong> — umumiy savollar uchun boshqa guruhlardan foydalaning', ru: '<strong>Вопросы не о боте</strong> — для общих вопросов используйте другие группы', en: '<strong>Non-bot related questions</strong> — use other groups for general questions' },
    'community.prohibited4': { uz: '<strong>Spam va takroriy xabarlar</strong> — bir xil xabarlarni qayta-qayta yozish', ru: '<strong>Спам и повторяющиеся сообщения</strong> — многократная отправка одинаковых сообщений', en: '<strong>Spam and repetitive messages</strong> — sending the same messages repeatedly' },
    'community.prohibited5': { uz: '<strong>Mavzudan tashqari munozaralar</strong> — bot bilan aloqasi bo\'lmagan suhbatlar', ru: '<strong>Оффтопик дискуссии</strong> — разговоры не связанные с ботом', en: '<strong>Off-topic discussions</strong> — conversations unrelated to the bot' },
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
    'month.11': { uz: 'Dekabr', ru: 'Декабрь', en: 'December' }
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
