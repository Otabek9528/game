/* =========================================================
   JOYLAR — MATNLAR / PLACES — TEXT

   Every word the places pages show — the list, the place page,
   the photo viewer, the notifications feature and the bot's
   messages — lives in this file, in all three languages, side by
   side. Edit the words here; nothing in the .js or .html files
   needs to be touched.

   HOW TO EDIT
   -----------
   Change only what is between the double quotes:

       searchButton: { uz: "Qidirish", ru: "Поиск", en: "Search" },
                           ^^^^^^^^        ^^^^^        ^^^^^^
                           edit these

   Leave the name before the colon alone — the page looks the
   text up by that name.

   QUOTES AND APOSTROPHES
   ----------------------
   Text sits between double quotes "…", so the apostrophe in
   o'z, ma'lumot, e'lon is safe to type as it is (' or ‘ ’ both
   work). The one character you cannot type inside the text is a
   plain double quote " — use «…» or “…” instead.

   PLACEHOLDERS
   ------------
   {n}, {name}, {type}, {city} and the like are filled in when the
   page runs. Keep them exactly as written, including the braces.
   They may be moved around inside the sentence.
   \n inside the text starts a new line.

   LENGTH
   ------
   Lines marked "short" sit in a narrow control (a pill, a button,
   a tab) and are cut with … if they run long. The rest wrap freely.

   BOT MESSAGES
   ------------
   The "bot" and "admin" sections are sent by the server, not by a
   page. They are kept here so all wording is reviewed in one place.
   ========================================================= */

window.PLACES_TEXT = {

  /* -------------------------------------------------------
     UMUMIY / SHARED
     Used on more than one page.
     ------------------------------------------------------- */
  common: {
    cancel:       { uz: "Bekor qilish", ru: "Отмена", en: "Cancel" },
    save:         { uz: "Saqlash", ru: "Сохранить", en: "Save" },
    undo:         { uz: "Qaytarish", ru: "Вернуть", en: "Undo" },
    error: {
      uz: "Xatolik yuz berdi. Qayta urinib ko‘ring.",
      ru: "Что-то пошло не так. Попробуйте ещё раз.",
      en: "Something went wrong. Please try again."
    },
    network: {
      uz: "Internetga ulanib bo‘lmadi. Qayta urinib ko‘ring.",
      ru: "Нет подключения к интернету. Попробуйте ещё раз.",
      en: "No internet connection. Please try again."
    },
    timeout: {
      uz: "Server javob bermadi. Qayta urinib ko‘ring.",
      ru: "Сервер не ответил. Попробуйте ещё раз.",
      en: "The server didn’t respond. Please try again."
    },
    telegramOnly: {
      uz: "Buning uchun sahifani Telegram ichida oching.",
      ru: "Откройте страницу в Telegram, чтобы сделать это.",
      en: "Open this page inside Telegram to do this."
    }
  },

  /* -------------------------------------------------------
     JOY TURLARI / PLACE TYPES
     ------------------------------------------------------- */
  types: {
    mosque:      { uz: "Masjid", ru: "Мечеть", en: "Mosque" },
    restaurant:  { uz: "Oshxona", ru: "Ресторан", en: "Restaurant" },
    shop:        { uz: "Do‘kon", ru: "Магазин", en: "Shop" },
    mosques:     { uz: "Masjidlar", ru: "Мечети", en: "Mosques" },
    restaurants: { uz: "Oshxonalar", ru: "Рестораны", en: "Restaurants" },
    shops:       { uz: "Do‘konlar", ru: "Магазины", en: "Shops" },
    all:         { uz: "Hammasi", ru: "Все", en: "All types" }
  },

  /* -------------------------------------------------------
     JOYLAR RO‘YXATI / PLACES LIST PAGE
     places.html — search buttons, results, cards.
     ------------------------------------------------------- */
  places: {
    searchNearby:       { uz: "O'z atrofimdan izlash", ru: "Искать рядом со мной", en: "Search nearby" },
    searchByAddress:    { uz: "Boshqa manzil atrofidan izlash", ru: "Искать по адресу", en: "Search by address" },
    searchHint: {
      uz: "💡 Biror manzilni KOREYS tilida kiritish orqali o'sha hudud atrofidagi joylarni qidirish mumkin.",
      ru: "💡 Введите адрес на КОРЕЙСКОМ языке для поиска мест в этом районе.",
      en: "💡 Enter an address in KOREAN to search for places in that area."
    },
    searchButton:       { uz: "Qidirish", ru: "Поиск", en: "Search" },
    placeholderText: {
      uz: "Yuqoridagi tugmalardan birini tanlang",
      ru: "Выберите одну из кнопок выше",
      en: "Select one of the buttons above"
    },
    placeholderSubtext: {
      uz: "O'z joylashuvingiz atrofidan yoki boshqa kiritilgan manzil atrofidan izlang",
      ru: "Ищите рядом с вашим местоположением или по другому адресу",
      en: "Search near your location or around another address"
    },
    loading:            { uz: "Joylar yuklanmoqda...", ru: "Загрузка мест...", en: "Loading places..." },
    loadingPhotos:      { uz: "Rasmlar yuklanmoqda...", ru: "Загрузка фото...", en: "Loading photos..." },
    loadingHint: {
      uz: "Internet tezligingizga bog'liq",
      ru: "Зависит от скорости интернета",
      en: "Depends on internet speed"
    },
    noResultsHint: {
      uz: "Iltimos, boshqa manzilni sinab ko'ring",
      ru: "Попробуйте другой адрес",
      en: "Please try another address"
    },
    // Contains a link. Keep the <a ...> ... </a> part as it is; edit the words around it.
    infoFooter: {
      uz: "Yangi joy haqida xabar berish uchun <a href='https://t.me/MuslimVegukin' target='_blank'>guruhimizga</a> o'tishingizni so'raymiz.",
      ru: "Чтобы сообщить о новом месте, присоединяйтесь к <a href='https://t.me/MuslimVegukin' target='_blank'>нашей группе</a>.",
      en: "To report a new place, please join <a href='https://t.me/MuslimVegukin' target='_blank'>our group</a>."
    },
    noInfo:             { uz: "Ma'lumot yo'q", ru: "Нет данных", en: "No info" },
    noAddress:          { uz: "Manzil ma'lumoti yo'q", ru: "Адрес не указан", en: "No address info" },
    noRating:           { uz: "Izoh qoldirilmagan", ru: "Нет отзывов", en: "No reviews" },
    error:              { uz: "Xatolik yuz berdi", ru: "Произошла ошибка", en: "An error occurred" },
    loadError: {
      uz: "Joylarni yuklashda xatolik yuz berdi",
      ru: "Ошибка загрузки мест",
      en: "Error loading places"
    },
    addressError: {
      uz: "Manzil bo'yicha qidirishda xatolik",
      ru: "Ошибка поиска по адресу",
      en: "Error searching by address"
    },
    timeoutError: {
      uz: "Server javob bermadi. Iltimos, qaytadan urinib ko'ring.",
      ru: "Сервер не отвечает. Попробуйте снова.",
      en: "Server not responding. Please try again."
    },
    locationError: {
      uz: "Joylashuv ma'lumotlari topilmadi",
      ru: "Местоположение не найдено",
      en: "Location not found"
    },
    locating: {
      uz: "Joylashuvingiz aniqlanmoqda...",
      ru: "Определяем ваше местоположение...",
      en: "Getting your location..."
    },
    // {city} and {when} are filled in, e.g. "Seoul (2 soat oldin)".
    savedLocationNote: {
      uz: "Joriy joylashuvni aniqlab bo'lmadi — {city} ({when}) bo'yicha ko'rsatilmoqda",
      ru: "Не удалось определить текущее местоположение — показано для {city} ({when})",
      en: "Couldn't get your current location — showing results for {city} ({when})"
    },
    // Per place type. searchExample is the example address shown inside the search box.
    mosque: {
      pageTitle:     { uz: "Sizga eng yaqin 5 masjid", ru: "5 ближайших мечетей", en: "5 nearest mosques" },
      searchedTitle: {
        uz: "Izlangan joyga eng yaqinlari",
        ru: "Ближайшие к искомому месту",
        en: "Nearest to searched location"
      },
      noResults:     { uz: "Hech qanday masjid topilmadi", ru: "Мечети не найдены", en: "No mosques found" },
      searchExample: { uz: "서울 강동구 구천면로 271", ru: "서울 강동구 구천면로 271", en: "서울 강동구 구천면로 271" }
    },
    restaurant: {
      pageTitle:     { uz: "Sizga eng yaqin 5 oshxona", ru: "5 ближайших ресторанов", en: "5 nearest restaurants" },
      searchedTitle: {
        uz: "Izlangan joyga eng yaqinlari",
        ru: "Ближайшие к искомому месту",
        en: "Nearest to searched location"
      },
      noResults:     { uz: "Hech qanday oshxona topilmadi", ru: "Рестораны не найдены", en: "No restaurants found" },
      searchExample: { uz: "서울 강남구 테헤란로 123", ru: "서울 강남구 테헤란로 123", en: "서울 강남구 테헤란로 123" }
    },
    shop: {
      pageTitle:     { uz: "Sizga eng yaqin 5 do'kon", ru: "5 ближайших магазинов", en: "5 nearest shops" },
      searchedTitle: {
        uz: "Izlangan joyga eng yaqinlari",
        ru: "Ближайшие к искомому месту",
        en: "Nearest to searched location"
      },
      noResults:     { uz: "Hech qanday do'kon topilmadi", ru: "Магазины не найдены", en: "No shops found" },
      searchExample: { uz: "서울 용산구 이태원로 123", ru: "서울 용산구 이태원로 123", en: "서울 용산구 이태원로 123" }
    },
    // Browser tab title. {type} becomes the plural type, e.g. "Masjidlar".
    pageTitle:          { uz: "Yaqin {type}", ru: "{type} рядом", en: "Nearby {type}" },
    // Read aloud by screen readers; not shown.
    searchModeLabel:    { uz: "Qidiruv turi", ru: "Тип поиска", en: "Search type" },
    // Read aloud by screen readers; not shown.
    clearSearch:        { uz: "Tozalash", ru: "Очистить", en: "Clear" },
    unknownCity:        { uz: "Shahar ko'rsatilmagan", ru: "Город не указан", en: "Unknown city" },
    noDistance:         { uz: "N/A", ru: "N/A", en: "N/A" },
    distanceKm:         { uz: "{n} km", ru: "{n} км", en: "{n} km" },
    // Read aloud by screen readers; not shown.
    photoAlt:           { uz: "{name} rasmi", ru: "Фото: {name}", en: "{name} photo" }
  },

  /* -------------------------------------------------------
     JOY SAHIFASI / PLACE DETAIL PAGE
     places-detail.html — contacts, reviews, social links, info note.
     ------------------------------------------------------- */
  detail: {
    retry:             { uz: "Qaytadan urinish", ru: "Попробовать снова", en: "Try again" },
    contact:           { uz: "Kontakt", ru: "Контакт", en: "Contact" },
    address:           { uz: "Manzil", ru: "Адрес", en: "Address" },
    reviews:           { uz: "Izohlar", ru: "Отзывы", en: "Reviews" },
    navigation:        { uz: "Navigatsiya", ru: "Навигация", en: "Navigation" },
    leaveReview:       { uz: "Izoh qoldirish", ru: "Оставить отзыв", en: "Leave a review" },
    noReviews:         { uz: "Hali izoh yo'q", ru: "Пока нет отзывов", en: "No reviews yet" },
    noReviewsYet:      { uz: "Hali Izohlar yo'q", ru: "Пока нет отзывов", en: "No reviews yet" },
    noReviewText:      { uz: "Izoh matni yo'q", ru: "Нет текста отзыва", en: "No review text" },
    addressCopied:     { uz: "Manzil nusxalandi! ✅", ru: "Адрес скопирован! ✅", en: "Address copied! ✅" },
    reviewHintTitle: {
      uz: "Izohingizda quyidagilarni yozishingiz mumkin:",
      ru: "В отзыве вы можете написать:",
      en: "In your review you can write:"
    },
    reviewHint2: {
      uz: "Ochilish va yopilish vaqtlari",
      ru: "Время открытия и закрытия",
      en: "Opening and closing times"
    },
    reviewHint3: {
      uz: "Kirish eshikdagi parol (agar bor bo'lsa)",
      ru: "Пароль на входной двери (если есть)",
      en: "Door password (if any)"
    },
    reviewHint4: {
      uz: "Lokatsiyaga olib boriladigan yo'l tushuntirishlar",
      ru: "Описание пути к месту",
      en: "Directions to the location"
    },
    rate:              { uz: "Baholang:", ru: "Оцените:", en: "Rate:" },
    reviewPlaceholder: { uz: "Izohingizni yozing ...", ru: "Напишите ваш отзыв ...", en: "Write your review ..." },
    reviewSubmit:      { uz: "Yuborish", ru: "Отправить", en: "Submit" },
    loading:           { uz: "Yuklanmoqda...", ru: "Загрузка...", en: "Loading..." },
    thankYou:          { uz: "Rahmat!", ru: "Спасибо!", en: "Thank you!" },
    reviewReceived: {
      uz: "Izohingiz muvaffaqiyatli qabul qilindi va ko'rib chiqilmoqda.",
      ru: "Ваш отзыв успешно получен и находится на рассмотрении.",
      en: "Your review has been received and is being reviewed."
    },
    selectRating: {
      uz: "Iltimos, baho tanlang!",
      ru: "Пожалуйста, выберите оценку!",
      en: "Please select a rating!"
    },
    submitError: {
      uz: "Xatolik yuz berdi. Internetni tekshiring.",
      ru: "Произошла ошибка. Проверьте интернет.",
      en: "An error occurred. Check your internet."
    },
    tryAgain:          { uz: "Qaytadan urinib ko'ring", ru: "Попробуйте снова", en: "Try again" },
    idNotFound: {
      uz: "ID topilmadi. Iltimos, orqaga qaytib, qaytadan tanlang.",
      ru: "ID не найден. Вернитесь назад и выберите снова.",
      en: "ID not found. Please go back and select again."
    },
    loadError: {
      uz: "Ma'lumotlarni yuklashda xatolik yuz berdi. Iltimos, internetni tekshirib, qaytadan urinib ko'ring.",
      ru: "Ошибка загрузки данных. Проверьте интернет и попробуйте снова.",
      en: "Error loading data. Please check internet and try again."
    },
    timeoutError: {
      uz: "Server javob bermadi (30 soniya). Server uyg'onayotgan bo'lishi mumkin, iltimos 1 daqiqa kuting va qaytadan urinib ko'ring.",
      ru: "Сервер не отвечает (30 сек). Сервер может просыпаться, подождите 1 минуту и попробуйте снова.",
      en: "Server not responding (30 sec). Server may be waking up, please wait 1 minute and try again."
    },
    notFound: {
      uz: "Topilmadi. Bu bazadan o'chirilgan bo'lishi mumkin.",
      ru: "Не найдено. Возможно, удалено из базы.",
      en: "Not found. May have been removed from database."
    },
    // Per place type. title is the browser tab title; reviewPrompt is the first hint in the review form.
    mosque: {
      title:        { uz: "Masjid Ma'lumotlari", ru: "Информация о мечети", en: "Mosque Information" },
      reviewPrompt: { uz: "Masjid haqida fikringiz", ru: "Ваше мнение о мечети", en: "Your opinion about the mosque" }
    },
    restaurant: {
      title:        { uz: "Oshxona Ma'lumotlari", ru: "Информация о ресторане", en: "Restaurant Information" },
      reviewPrompt: {
        uz: "Oshxona haqida fikringiz",
        ru: "Ваше мнение о ресторане",
        en: "Your opinion about the restaurant"
      }
    },
    shop: {
      title:        { uz: "Do'kon Ma'lumotlari", ru: "Информация о магазине", en: "Shop Information" },
      reviewPrompt: { uz: "Do'kon haqida fikringiz", ru: "Ваше мнение о магазине", en: "Your opinion about the shop" }
    },
    social: {
      title:         { uz: "Ijtimoiy tarmoqlarda", ru: "Соцсети", en: "Social media" },
      addMorePrompt: {
        uz: "Boshqa tarmoqdagi sahifasini bilasizmi?",
        ru: "Знаете страницу в другой соцсети?",
        en: "Know a page on another network?"
      },
      emptyPrompt: {
        uz: "Bu joy ijtimoiy tarmoqlarda bormi?",
        ru: "Знаете соцсети этого места?",
        en: "Do you know this place's social media?"
      },
      add:           { uz: "Qo'shish", ru: "Добавить", en: "Add" },
      inviteLink:    { uz: "Havola", ru: "Ссылка", en: "Link" }
    },
    sheet: {
      pickTitle: {
        uz: "Nimani qo'shmoqchisiz?",
        ru: "Что хотите добавить?",
        en: "What would you like to add?"
      },
      addTitle: {
        uz: "{platform} havolasini qo'shish",
        ru: "Добавить ссылку {platform}",
        en: "Add {platform} link"
      },
      editTitle: {
        uz: "{platform} havolasini o'zgartirish",
        ru: "Изменить ссылку {platform}",
        en: "Change {platform} link"
      },
      noteAddTitle:    { uz: "Ma'lumot qo'shish", ru: "Добавить информацию", en: "Add information" },
      noteEditTitle:   { uz: "Ma'lumotni o'zgartirish", ru: "Изменить информацию", en: "Change information" },
      current:         { uz: "Hozirgi", ru: "Сейчас", en: "Current" },
      telegramHint: {
        uz: "@username yoki t.me havolasi",
        ru: "@username или ссылка t.me",
        en: "@username or a t.me link"
      },
      tiktokHint: {
        uz: "@username yoki tiktok.com havolasi",
        ru: "@username или ссылка tiktok.com",
        en: "@username or a tiktok.com link"
      },
      instagramHint: {
        uz: "@username yoki instagram.com havolasi",
        ru: "@username или ссылка instagram.com",
        en: "@username or an instagram.com link"
      },
      noteHint: {
        uz: "Ish vaqti, dam olish kunlari yoki e'lon.",
        ru: "Часы работы, выходные или объявление.",
        en: "Opening hours, days off or an announcement."
      },
      // \n starts a new line.
      notePlaceholder: {
        uz: "Masalan:\nDu-Ju: 11:00 - 22:00\nShanba: yopiq",
        ru: "Например:\nПн-Пт: 11:00 - 22:00\nСуббота: выходной",
        en: "For example:\nMon-Fri: 11:00 - 22:00\nSaturday: closed"
      },
      moderationNote: {
        uz: "Taklifingiz admin tekshiruvidan so'ng chop etiladi.",
        ru: "Ваше предложение появится после проверки админом.",
        en: "Your suggestion will appear after an admin reviews it."
      },
      send:            { uz: "Yuborish", ru: "Отправить", en: "Send" },
      sending:         { uz: "Yuborilmoqda...", ru: "Отправляется...", en: "Sending..." }
    },
    note: {
      title:  { uz: "Muassasa haqida", ru: "О заведении", en: "About the venue" },
      empty: {
        uz: "Ish vaqti va dam olish kunlari hali qo'shilmagan.",
        ru: "Часы работы и выходные пока не указаны.",
        en: "Opening hours and days off have not been added yet."
      },
      addCta: { uz: "Ma'lumot qo'shish", ru: "Добавить информацию", en: "Add information" }
    },
    // Answers to the "add a social link / info note" form.
    submit: {
      ok: {
        uz: "Rahmat! Taklifingiz ko'rib chiqilmoqda.",
        ru: "Спасибо! Ваше предложение на проверке.",
        en: "Thank you! Your suggestion is under review."
      },
      // One line per error code the server can send back. Keep the names; edit the words.
      err: {
        empty: {
          uz: "Avval to'ldiring.",
          ru: "Сначала заполните поле.",
          en: "Please fill this in first."
        },
        too_short:            { uz: "Juda qisqa.", ru: "Слишком коротко.", en: "That is too short." },
        too_long: {
          uz: "Matn juda uzun — 500 belgidan oshmasin.",
          ru: "Текст слишком длинный — не более 500 символов.",
          en: "That is too long — please keep it under 500 characters."
        },
        wrong_host: {
          uz: "Bu havola boshqa saytga tegishli. Iltimos, to'g'ri havolani kiriting.",
          ru: "Эта ссылка ведёт на другой сайт. Введите правильную ссылку.",
          en: "That link points to a different site. Please enter the right one."
        },
        invalid_handle: {
          uz: "Username noto'g'ri. Faqat harflar, raqamlar va pastki chiziq.",
          ru: "Неверный username. Только буквы, цифры и подчёркивание.",
          en: "That username is not valid. Letters, digits and underscores only."
        },
        invalid_url: {
          uz: "Bu havolaga o'xshamaydi.",
          ru: "Это не похоже на ссылку.",
          en: "That does not look like a link."
        },
        invalid_scheme: {
          uz: "Faqat http va https havolalar qabul qilinadi.",
          ru: "Принимаются только ссылки http и https.",
          en: "Only http and https links are accepted."
        },
        incomplete:           { uz: "Havola to'liq emas.", ru: "Ссылка неполная.", en: "That link is incomplete." },
        invalid_invite: {
          uz: "Taklif havolasi to'liq emas.",
          ru: "Пригласительная ссылка неполная.",
          en: "That invite link is incomplete."
        },
        not_a_profile: {
          uz: "Bu post havolasi. Iltimos, profil havolasini yuboring.",
          ru: "Это ссылка на публикацию. Отправьте ссылку на профиль.",
          en: "That is a link to a post. Please send the profile link."
        },
        already_pending: {
          uz: "Bu ma'lumot bo'yicha taklif allaqachon ko'rib chiqilmoqda.",
          ru: "Предложение по этому полю уже на проверке.",
          en: "A change to this is already waiting for review."
        },
        same_as_current: {
          uz: "Bu allaqachon saqlangan ma'lumot.",
          ru: "Это уже сохранено.",
          en: "That is already what is saved."
        },
        rate_limited: {
          uz: "Bugungi takliflar limitiga yetdingiz. Ertaga urinib ko'ring.",
          ru: "Вы исчерпали лимит предложений на сегодня. Попробуйте завтра.",
          en: "You have reached today's limit. Please try again tomorrow."
        },
        place_not_found: {
          uz: "Bu joy topilmadi.",
          ru: "Это место не найдено.",
          en: "That place was not found."
        },
        invalid_field:        { uz: "Noma'lum maydon.", ru: "Неизвестное поле.", en: "Unknown field." },
        no_init_data: {
          uz: "Iltimos, bu sahifani Telegram ichida oching.",
          ru: "Пожалуйста, откройте эту страницу внутри Telegram.",
          en: "Please open this page inside Telegram."
        },
        bad_init_data: {
          uz: "Iltimos, sahifani qaytadan oching.",
          ru: "Пожалуйста, откройте страницу заново.",
          en: "Please reopen the page."
        },
        bad_signature: {
          uz: "Telegram hisobingizni tasdiqlab bo'lmadi.",
          ru: "Не удалось подтвердить ваш аккаунт Telegram.",
          en: "Could not verify your Telegram account."
        },
        stale_init_data: {
          uz: "Sessiya muddati tugadi. Sahifani qaytadan oching.",
          ru: "Сессия истекла. Откройте страницу заново.",
          en: "Your session expired. Please reopen the page."
        },
        no_user: {
          uz: "Telegram hisobingizni o'qib bo'lmadi.",
          ru: "Не удалось прочитать ваш аккаунт Telegram.",
          en: "Could not read your Telegram account."
        },
        server_misconfigured: {
          uz: "Takliflar vaqtincha ishlamayapti.",
          ru: "Предложения временно недоступны.",
          en: "Submissions are temporarily unavailable."
        },
        server_error: {
          uz: "Xatolik yuz berdi. Qaytadan urinib ko'ring.",
          ru: "Произошла ошибка. Попробуйте снова.",
          en: "Something went wrong. Please try again."
        },
        timeout: {
          uz: "Server javob bermadi. Qaytadan urinib ko'ring.",
          ru: "Сервер не ответил. Попробуйте снова.",
          en: "The server did not respond. Please try again."
        },
        network: {
          uz: "Internetga ulanib bo'lmadi. Qaytadan urinib ko'ring.",
          ru: "Нет соединения с интернетом. Попробуйте снова.",
          en: "Could not reach the internet. Please try again."
        }
      }
    },
    loadingPage:       { uz: "Yuklanmoqda...", ru: "Загрузка...", en: "Loading..." },
    loadErrorDefault: {
      uz: "Ma'lumotlarni yuklashda muammo. Iltimos, qaytadan urinib ko'ring.",
      ru: "Не удалось загрузить данные. Попробуйте ещё раз.",
      en: "Could not load the details. Please try again."
    },
    errorPrefix:       { uz: "Xatolik: {error}", ru: "Ошибка: {error}", en: "Error: {error}" }
  },

  /* -------------------------------------------------------
     RASMLAR / PHOTO VIEWER
     Full-screen photo viewer. Read aloud by screen readers; not shown.
     ------------------------------------------------------- */
  viewer: {
    close: { uz: "Yopish", ru: "Закрыть", en: "Close" },
    prev:  { uz: "Oldingi", ru: "Назад", en: "Previous" },
    next:  { uz: "Keyingi", ru: "Вперёд", en: "Next" }
  },

  /* =======================================================
     BILDIRISHNOMALAR / NOTIFICATIONS FEATURE
     Everything below is used by the notifications feature.
     ======================================================= */

  /* -------------------------------------------------------
     BILDIRISHNOMALAR SAHIFASI / NOTIFICATIONS PAGE
     ------------------------------------------------------- */
  page: {
    title: { uz: "Bildirishnomalar", ru: "Уведомления", en: "Notifications" },
    via: {
      uz: "Xabarlar Telegramda shu botdan keladi",
      ru: "Сообщения приходят в Telegram от этого бота",
      en: "Messages arrive in Telegram from this bot"
    },
    loading:   { uz: "Yuklanmoqda…", ru: "Загрузка…", en: "Loading…" },
    loadError: {
      uz: "Obunalaringizni yuklab bo‘lmadi.",
      ru: "Не удалось загрузить ваши подписки.",
      en: "Couldn’t load your subscriptions."
    },
    retry:     { uz: "Qayta urinish", ru: "Повторить", en: "Try again" }
  },

  /* -------------------------------------------------------
     BIRINCHI KIRISH / FIRST VISIT
     ------------------------------------------------------- */
  empty: {
    title:      { uz: "Hech narsani o‘tkazib yubormang", ru: "Ничего не пропустите", en: "Don’t miss a thing" },
    body: {
      uz: "O‘zgarishlarni Telegramda birinchilardan bo‘lib biling.",
      ru: "Узнавайте об изменениях в Telegram первыми.",
      en: "Be the first to hear about changes, right in Telegram."
    },
    areaTitle:  { uz: "Hududni kuzatish", ru: "Следить за районом", en: "Watch an area" },
    areaBody: {
      uz: "Manzil yoki joylashuvingiz atrofida yangi joy ochilsa, yopilsa yoki o‘zgarsa",
      ru: "Новые, закрытые и изменённые места рядом с адресом или с вами",
      en: "When places open, close or change around an address or your location"
    },
    placeTitle: { uz: "Joyni kuzatish", ru: "Следить за местом", en: "Watch a place" },
    placeBody: {
      uz: "Istalgan joy sahifasida «Kuzatish» tugmasini bosing",
      ru: "Нажмите «Следить» на странице любого места",
      en: "Tap “Watch” on any place’s page"
    },
    whenTitle:  { uz: "Qachon xabar keladi?", ru: "Когда приходят сообщения?", en: "When do messages arrive?" },
    whenNew:    { uz: "Yangi joy ochilsa", ru: "Открылось новое место", en: "A new place opens" },
    whenClosed: { uz: "Joy yopilsa", ru: "Место закрылось", en: "A place closes" },
    whenPhone:  { uz: "Telefon o‘zgarsa", ru: "Сменился телефон", en: "Phone number changes" },
    whenName:   { uz: "Nomi o‘zgarsa", ru: "Сменилось название", en: "Name changes" },
    whenOwner:  { uz: "Joy egasi e’lon bersa", ru: "Объявление владельца", en: "The owner posts news" },
    whenMosque: { uz: "Masjid e’lon bersa", ru: "Объявление мечети", en: "A mosque posts news" }
  },

  /* -------------------------------------------------------
     HUDUDLAR / AREAS
     ------------------------------------------------------- */
  areas: {
    title:           { uz: "Hududlar", ru: "Районы", en: "Areas" },
    add:             { uz: "Hudud qo‘shish", ru: "Добавить район", en: "Add area" },
    currentLocation: { uz: "Joriy joylashuvim", ru: "Моё местоположение", en: "My current location" },
    radius:          { uz: "{km} km radius", ru: "радиус {km} км", en: "{km} km radius" },
    fromLocation:    { uz: "Joylashuvimdan", ru: "По геолокации", en: "From my location" },
    inside:          { uz: "hozir {n} ta joy", ru: "сейчас мест: {n}", en: "{n} places now" },
    edit:            { uz: "Tahrirlash", ru: "Изменить", en: "Edit" },
    delete:          { uz: "O‘chirish", ru: "Удалить", en: "Delete" },
    menu:            { uz: "Amallar", ru: "Действия", en: "Actions" },
    deleteConfirm: {
      uz: "Bu hudud bo‘yicha xabarlar to‘xtatilsinmi?",
      ru: "Отключить сообщения по этому району?",
      en: "Stop messages for this area?"
    },
    saved:           { uz: "Hudud saqlandi", ru: "Район сохранён", en: "Area saved" },
    updated:         { uz: "Hudud yangilandi", ru: "Район обновлён", en: "Area updated" },
    deleted:         { uz: "Hudud o‘chirildi", ru: "Район удалён", en: "Area deleted" }
  },

  /* -------------------------------------------------------
     KUZATUVDAGI JOYLAR / WATCHED PLACES
     ------------------------------------------------------- */
  watchlist: {
    title:   { uz: "Kuzatuvdagi joylar", ru: "Отслеживаемые места", en: "Watched places" },
    hint: {
      uz: "Joyni kuzatish uchun uning sahifasidagi «Kuzatish» tugmasini bosing.",
      ru: "Чтобы следить за местом, нажмите «Следить» на его странице.",
      en: "To watch a place, tap “Watch” on its page."
    },
    removed: { uz: "Kuzatuvdan olib tashlandi", ru: "Удалено из отслеживаемых", en: "Removed from watched places" },
    stop:    { uz: "Kuzatishni to‘xtatish", ru: "Перестать следить", en: "Stop watching" }
  },

  /* -------------------------------------------------------
     HUDUDNI KUZATISH / ADD-AREA SHEET
     ------------------------------------------------------- */
  areaSheet: {
    addTitle:        { uz: "Hududni kuzatish", ru: "Следить за районом", en: "Watch an area" },
    editTitle:       { uz: "Hududni tahrirlash", ru: "Изменить район", en: "Edit area" },
    center:          { uz: "Markaz", ru: "Центр", en: "Centre" },
    myLocation:      { uz: "Joylashuvim", ru: "Моё место", en: "My location" },
    address:         { uz: "Manzil", ru: "Адрес", en: "Address" },
    addressHint: {
      uz: "Manzilni koreys tilida kiriting",
      ru: "Введите адрес на корейском",
      en: "Enter the address in Korean"
    },
    addressExample:  { uz: "서울 동대문구 회기로 56", ru: "서울 동대문구 회기로 56", en: "서울 동대문구 회기로 56" },
    located:         { uz: "Hozirgina aniqlandi", ru: "Определено только что", en: "Located just now" },
    locating:        { uz: "Joylashuv aniqlanmoqda…", ru: "Определяем местоположение…", en: "Finding your location…" },
    savedCenter:     { uz: "Saqlangan markaz", ru: "Сохранённый центр", en: "Saved centre" },
    relocate:        { uz: "Qayta aniqlash", ru: "Обновить", en: "Update" },
    find:            { uz: "Topish", ru: "Найти", en: "Find" },
    finding:         { uz: "Manzil qidirilmoqda…", ru: "Ищем адрес…", en: "Looking up the address…" },
    noCenter: {
      uz: "Markazni tanlang — bu yerda qamrov ko‘rinadi.",
      ru: "Выберите центр — здесь появится охват.",
      en: "Pick a centre to see what the circle covers."
    },
    nothingInside: {
      uz: "Bu radiusda hozircha joy yo‘q",
      ru: "В этом радиусе пока нет мест",
      en: "No places in this radius yet"
    },
    locationFailed: {
      uz: "Joylashuvni aniqlab bo‘lmadi. Manzilni kiriting yoki qayta urinib ko‘ring.",
      ru: "Не удалось определить местоположение. Введите адрес или попробуйте ещё раз.",
      en: "Couldn’t get your location. Enter an address or try again."
    },
    radius:          { uz: "Radius", ru: "Радиус", en: "Radius" },
    countMosque:     { uz: "{n} masjid", ru: "Мечети: {n}", en: "Mosques: {n}" },
    countRestaurant: { uz: "{n} oshxona", ru: "Рестораны: {n}", en: "Restaurants: {n}" },
    countShop:       { uz: "{n} do‘kon", ru: "Магазины: {n}", en: "Shops: {n}" },
    which:           { uz: "Qaysi joylar?", ru: "Какие места?", en: "Which places?" },
    pickOne: {
      uz: "Kamida bitta turni tanlang.",
      ru: "Выберите хотя бы один тип.",
      en: "Choose at least one type."
    },
    note: {
      uz: "Yangi joy ochilsa, yopilsa, telefon raqami yoki nomi o‘zgarsa va e’lon berilsa — Telegramda xabar olasiz.",
      ru: "Мы напишем в Telegram, если место откроется, закроется, сменит телефон или название, или опубликует объявление.",
      en: "We’ll message you in Telegram when a place opens, closes, changes its phone or name, or posts an announcement."
    }
  },

  /* -------------------------------------------------------
     XATOLAR / ERRORS from the notifications API, by code
     ------------------------------------------------------- */
  notifyErrors: {
    address_not_found: {
      uz: "Bu manzil topilmadi. Koreys tilida, aniqroq yozib ko‘ring.",
      ru: "Адрес не найден. Попробуйте написать точнее, на корейском.",
      en: "That address wasn’t found. Try writing it more precisely, in Korean."
    },
    rate_limited: {
      uz: "So‘rovlar juda ko‘p. Bir daqiqadan so‘ng urinib ko‘ring.",
      ru: "Слишком много запросов. Попробуйте через минуту.",
      en: "Too many requests. Please try again in a minute."
    },
    too_many_areas: {
      uz: "Hududlar juda ko‘p. Keraksizlarini o‘chiring.",
      ru: "Слишком много районов. Удалите ненужные.",
      en: "Too many areas. Delete the ones you don’t need."
    },
    place_not_found: {
      uz: "Bu joy endi mavjud emas.",
      ru: "Этого места больше нет.",
      en: "This place no longer exists."
    },
    stale_init_data: {
      uz: "Sessiya eskirdi. Sahifani Telegramda qayta oching.",
      ru: "Сессия устарела. Откройте страницу в Telegram заново.",
      en: "Your session expired. Reopen the page in Telegram."
    },
    not_found: {
      uz: "Bu hudud allaqachon o‘chirilgan.",
      ru: "Этот район уже удалён.",
      en: "This area was already deleted."
    }
  },

  /* -------------------------------------------------------
     KUZATISH TUGMASI / WATCH BUTTON (detail page)
     ------------------------------------------------------- */
  watch: {
    button:     { uz: "Kuzatish", ru: "Следить", en: "Watch" },
    watching:   { uz: "Kuzatilmoqda", ru: "Вы следите", en: "Watching" },
    toastOn: {
      uz: "Yangiliklar Telegramga keladi",
      ru: "Новости будут приходить в Telegram",
      en: "News will arrive in Telegram"
    },
    toastOff:   { uz: "Kuzatish to‘xtatildi", ru: "Вы больше не следите", en: "You stopped watching" },
    countLabel: { uz: "{n} kishi kuzatmoqda", ru: "Следят: {n}", en: "{n} people watching" }
  },

  /* -------------------------------------------------------
     EGALIK / OWNER CLAIM (restaurants and shops)
     ------------------------------------------------------- */
  claim: {
    prompt:  { uz: "Joy egasimisiz?", ru: "Вы владелец?", en: "Are you the owner?" },
    link:    { uz: "Egalikni tasdiqlang", ru: "Подтвердите", en: "Claim this place" },
    sent: {
      uz: "So‘rov yuborildi. Administrator siz bilan bog‘lanadi.",
      ru: "Запрос отправлен. Администратор свяжется с вами.",
      en: "Request sent. The admin will get in touch."
    },
    pending: {
      uz: "Egalik so‘rovingiz ko‘rib chiqilmoqda.",
      ru: "Ваш запрос на владение рассматривается.",
      en: "Your ownership request is being reviewed."
    }
  },

  /* -------------------------------------------------------
     E’LONLAR / ANNOUNCEMENTS
     ------------------------------------------------------- */
  announce: {
    ownerEntry:        { uz: "E’lon yuborish", ru: "Отправить объявление", en: "Send an announcement" },
    mosqueEntry:       { uz: "E’lon yozish", ru: "Написать объявление", en: "Write an announcement" },
    pendingLine:       { uz: "{n} ta e’lon tekshiruvda", ru: "На проверке: {n}", en: "{n} awaiting review" },
    title:             { uz: "E’lon yuborish", ru: "Объявление", en: "Announcement" },
    placeholderOwner: {
      uz: "Masalan: 25-dekabr kuni oshxonamiz yopiq bo‘ladi.",
      ru: "Например: 25 декабря мы не работаем.",
      en: "For example: We’re closed on 25 December."
    },
    placeholderMosque: {
      uz: "Masalan: Hayit namozi 07:00, 08:00 va 09:00 da o‘qiladi.",
      ru: "Например: праздничный намаз в 07:00, 08:00 и 09:00.",
      en: "For example: Eid prayer at 07:00, 08:00 and 09:00."
    },
    textOnly:          { uz: "Faqat matn", ru: "Только текст", en: "Text only" },
    reach: {
      uz: "Administrator tasdiqlagach, taxminan {n} kishiga yuboriladi.",
      ru: "После проверки администратором его получат примерно {n} человек.",
      en: "Once the admin approves it, about {n} people will receive it."
    },
    submit:            { uz: "Tekshiruvga yuborish", ru: "На проверку", en: "Send for review" },
    sentToast: {
      uz: "E’lon tekshiruvga yuborildi",
      ru: "Объявление отправлено на проверку",
      en: "Sent for review"
    },
    empty:             { uz: "Avval matn yozing.", ru: "Сначала напишите текст.", en: "Write something first." },
    tooLong: {
      uz: "Matn 1000 belgidan oshmasin.",
      ru: "Не больше 1000 символов.",
      en: "Keep it under 1000 characters."
    }
  },

  /* -------------------------------------------------------
     BOT XABARLARI / BOT MESSAGES — sent by the server
     ------------------------------------------------------- */
  bot: {
    newMosque:       { uz: "Yangi masjid ochildi", ru: "Открылась новая мечеть", en: "New mosque opened" },
    newRestaurant:   { uz: "Yangi oshxona ochildi", ru: "Открылся новый ресторан", en: "New restaurant opened" },
    newShop:         { uz: "Yangi do‘kon ochildi", ru: "Открылся новый магазин", en: "New shop opened" },
    phoneChanged:    { uz: "Telefon raqami o‘zgardi", ru: "Изменился номер телефона", en: "Phone number changed" },
    nameChanged:     { uz: "Nomi o‘zgardi", ru: "Изменилось название", en: "Name changed" },
    closed:          { uz: "Joy yopildi", ru: "Место закрылось", en: "Place closed" },
    closedBody: {
      uz: "{name} endi ishlamaydi.",
      ru: "{name} больше не работает.",
      en: "{name} is no longer open."
    },
    removedFromList: {
      uz: "Kuzatuv ro‘yxatingizdan olib tashlandi.",
      ru: "Удалено из ваших отслеживаемых мест.",
      en: "It has been removed from your watched places."
    },
    whyArea: {
      uz: "Hududingiz: {area} · {km} km",
      ru: "Ваш район: {area} · {km} км",
      en: "Your area: {area} · {km} km"
    },
    whyPlace: {
      uz: "Siz bu joyni kuzatyapsiz",
      ru: "Вы следите за этим местом",
      en: "You’re watching this place"
    },
    announcement:    { uz: "{name} · e’lon", ru: "{name} · объявление", en: "{name} · announcement" },
    fromOwner:       { uz: "Joy egasidan", ru: "От владельца", en: "From the owner" },
    btnOpen:         { uz: "Joyni ochish", ru: "Открыть", en: "Open place" },
    btnStop:         { uz: "To‘xtatish", ru: "Отключить", en: "Stop" },
    stoppedArea: {
      uz: "Bu hudud bo‘yicha xabarlar to‘xtatildi.",
      ru: "Сообщения по этому району отключены.",
      en: "Messages for this area are off."
    },
    stoppedPlace: {
      uz: "Bu joy bo‘yicha xabarlar to‘xtatildi.",
      ru: "Сообщения по этому месту отключены.",
      en: "Messages for this place are off."
    },
    approved: {
      uz: "E’loningiz tasdiqlandi va {n} kishiga yuborildi.",
      ru: "Ваше объявление одобрено и отправлено {n} людям.",
      en: "Your announcement was approved and sent to {n} people."
    },
    rejected: {
      uz: "E’loningiz rad etildi. Savollar bo‘lsa, administratorga yozing.",
      ru: "Ваше объявление отклонено. Если есть вопросы, напишите администратору.",
      en: "Your announcement was declined. Message the admin if you have questions."
    },
    claimApproved: {
      uz: "Siz {name} egasi sifatida tasdiqlandingiz.",
      ru: "Вы подтверждены как владелец «{name}».",
      en: "You’re now confirmed as the owner of {name}."
    }
  },

  /* -------------------------------------------------------
     ADMIN XABARLARI / ADMIN PINGS — sent by the server
     ------------------------------------------------------- */
  admin: {
    pendingPost: {
      uz: "Yangi e’lon tasdiqlashni kutmoqda",
      ru: "Новое объявление ждёт проверки",
      en: "New announcement awaiting approval"
    },
    pendingClaim: { uz: "Yangi egalik so‘rovi", ru: "Новый запрос на владение", en: "New ownership request" },
    last7:        { uz: "Oxirgi 7 kunda: {n} ta e’lon", ru: "За 7 дней: {n} объявл.", en: "Last 7 days: {n} posts" },
    openPanel:    { uz: "Admin panelda ochish", ru: "Открыть в админке", en: "Open in admin panel" }
  }

};
