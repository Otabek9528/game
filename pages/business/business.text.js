/* =========================================================
   BIZNES KATALOGI — MATNLAR / TEXT

   Every word the business directory shows a person lives in this
   file and nowhere else. Edit the Uzbek here; nothing in
   business.js or business.html needs to be touched.

   HOW TO EDIT
   -----------
   Change only what is between the quotes:

       submit: 'Yuborish',
                ^^^^^^^^  edit this

   Leave the name before the colon alone — the page looks the
   string up by that name.

   PLACEHOLDERS
   ------------
   {n}, {name}, {amount} and the like are filled in at runtime.
   Keep them exactly as written, including the braces. They may be
   moved around inside the sentence:

       'Bu yo‘nalishda {n} ta o‘rin bo‘sh'
       '{n} ta o‘rin bu yo‘nalishda bo‘sh'      ← also fine

   APOSTROPHES
   -----------
   Uzbek o‘ and g‘ use the turned comma ‘ (U+2018), and ’ (U+2019)
   is the apostrophe in ma’lumot. Copy them from a line nearby
   rather than typing ' — a straight quote would end the string
   early and break the page.

   LENGTH
   ------
   Lines marked "short" sit in a narrow control (a chip, a button,
   a title bar) and are cut with … if they run long. The rest wrap
   freely.
   ========================================================= */

window.BUSINESS_TEXT = {

  /* -------------------------------------------------------
     UMUMIY / SHARED
     Used in more than one place.
     ------------------------------------------------------- */
  common: {
    // Money, everywhere it appears. {amount} arrives already
    // grouped, e.g. "5,000".
    currency:      '{amount} won',
    // Stands in for a value that does not exist yet.
    empty:         '—',
    close:         'Yopish',
    back:          'Orqaga',
    retry:         'Qayta urinish',
    // Shown when something failed and we have nothing specific to say.
    error:         'Xatolik yuz berdi. Qayta urinib ko‘ring.',
    saveFailed:    'Saqlab bo‘lmadi. Qayta urinib ko‘ring',
    // The action needs a verified Telegram account, so it cannot
    // work in an ordinary browser tab.
    telegramOnly:  'Buning uchun sahifani Telegram ichida oching',
    saved:         'Saqlandi',
    adminContact:  'Admin bilan bog‘lanish'
  },

  /* -------------------------------------------------------
     SAHIFA TEPASI / PAGE HEADER
     The title bar and the search field, on every screen.
     ------------------------------------------------------- */
  header: {
    // Browser tab, and the title on the first screen. (short)
    pageTitle:      'Biznes katalogi',
    // Title while showing search results. (short)
    searchTitle:    'Qidiruv',
    searchPlaceholder: 'Biznes yoki xizmatni qidiring',
    // Read aloud by screen readers; not shown on screen.
    searchLabel:    'Qidirish',
    searchClear:    'Qidiruvni tozalash',
    // Inside a category the title opens the category list.
    switchLabel:    '{name} — yo‘nalishni almashtirish',
    // Beside the title. (short — keep to two or three words)
    countAll:       '{n} ta biznes',
    countInCategory: '{n} ta',
    countFound:     '{n} ta topildi'
  },

  /* -------------------------------------------------------
     YO‘NALISHLAR RO‘YXATI / DIRECTORY
     The first screen: every business type as a tile.
     ------------------------------------------------------- */
  directory: {
    tileCount:  '{n} ta biznes',
    // A category nobody has joined yet. (short)
    tileEmpty:  'Hozircha bo‘sh',
    emptyTitle: 'Katalog hozircha bo‘sh',
    emptyBody:  'Bu yerda Koreyadagi o‘zbek bizneslari to‘planadi.'
  },

  /* -------------------------------------------------------
     YO‘NALISH TAVSIFLARI / WHAT EACH CATEGORY COVERS
     One line under each category name, so somebody who does not
     already know what "Tarjima va apostil" means does not have to
     open it to find out. (short — one line on a tile)

     The name on the left is the category's slug in the database.
     A category with no line here simply shows none.
     ------------------------------------------------------- */
  categoryAbout: {
    'halal-market': 'Halol go‘sht, ziravorlar, oziq-ovqat',
    'pishiriqlar':  'Non, patir, somsa, shirinliklar',
    'tarjima':      'Hujjat tarjimasi va apostil',
    'pochta':       'O‘zbekistonga posilka va yuk',
    'aviakassa':    'Aviabilet va yo‘l hujjatlari',
    'sim-telefon':  'SIM karta, telefon, aksessuarlar',
    'sugurta':      'Sug‘urta va moliyaviy xizmatlar',
    'consulting':   'Universitet va viza maslahati',
    'repetitor':    'Til va fan o‘qituvchilari',
    'kosmetika':    'Koreys kosmetikasi va parvarish'
  },

  /* -------------------------------------------------------
     BIR YO‘NALISH ICHIDA / INSIDE A CATEGORY
     ------------------------------------------------------- */
  category: {
    // Heading over the paid positions. Shown only where positions
    // are actually being bid on.
    podiumTitle: 'Yuqori o‘rinlar',
    // Behind the (i) beside that heading. Says plainly why those
    // businesses are on top.
    podiumHint:  'Bu o‘rinlar biznes egalari tomonidan band qilingan.',
    // Heading over everyone else.
    restTitle:   'Boshqa bizneslar',
    emptyTitle:  'Bu yo‘nalishda hali biznes yo‘q',
    emptyBody:   'Yangi bizneslar qo‘shilgach shu yerda ko‘rinadi. Boshqa yo‘nalishlarga ham qarab ko‘ring.',
    // Read aloud for the small numbered badge on a logo.
    rankLabel:   '{n}-o‘rin',
    infoLabel:   'Izoh'
  },

  /* -------------------------------------------------------
     QIDIRUV / SEARCH RESULTS
     ------------------------------------------------------- */
  search: {
    // Opens the full category behind a group of results. (short)
    seeAll:    'Barchasi',
    emptyTitle: 'Hech narsa topilmadi',
    emptyBody: '“{query}” bo‘yicha biznes topilmadi. Boshqacha yozib ko‘ring yoki yo‘nalishlardan qidiring.'
  },

  /* -------------------------------------------------------
     BIZNES KARTASI / THE BUSINESS CARD
     The screen a person opens to decide whether to contact a
     business. The most-read screen on the page.
     ------------------------------------------------------- */
  business: {
    // Under the name. Only appears once at least one person has
    // reacted.
    likes:        '{n} kishiga yoqdi',
    // Read aloud for the logo, which opens full screen.
    zoomLabel:    '{name} — rasmni kattalashtirish',

    // Section headings on the card.
    factsTitle:   'Asosiy ma’lumotlar',
    aboutTitle:   'Biznes haqida',
    linksTitle:   'Boshqa havolalar',

    // A long description is folded after five lines.
    readMore:     'To‘liq o‘qish',
    readLess:     'Yashirish',

    // The business gave no phone, Telegram or website at all.
    noContact:    'Aloqa ma’lumotlari ko‘rsatilmagan.',
    noContactAsk: 'Admin orqali so‘rash',
    // No contacts, no description, nothing.
    noInfo:       'Bu biznes hali to‘liq ma’lumot kiritmagan.',
    loadFailed:   'Ma’lumotni yuklab bo‘lmadi.',

    // The like / dislike row at the bottom.
    reactLabel:   'Bu biznes sizga yoqdimi?',
    reactUp:      'Yoqdi',
    reactDown:    'Yoqmadi',
    // A person's way to flag a wrong number or a closed shop.
    report:       'Ma’lumot noto‘g‘rimi? Adminga xabar bering'
  },

  /* -------------------------------------------------------
     BOG‘LANISH TUGMALARI / CONTACT BUTTONS
     What the button says the tap will do. The icon already says
     which app it is, so these name the outcome instead. (short —
     two buttons share one row)
     ------------------------------------------------------- */
  actions: {
    // Android dials directly.
    phoneCall:  'Qo‘ng‘iroq qilish',
    // On iPhone dialling from inside Telegram is unreliable, so the
    // number is copied instead — and the button says so first.
    phoneCopy:  'Raqamni nusxalash',
    telegram:   'Telegramda yozish',
    kakao:      'KakaoTalkda yozish',
    website:    'Saytni ochish',
    instagram:  'Instagramda ko‘rish',
    tiktok:     'TikTokda ko‘rish',
    playstore:  'Google Play’da ochish',
    appstore:   'App Store’da ochish',
    open:       'Ochish',
    map:        'Xaritada ko‘rish',
    // Toast after the number is on the clipboard.
    phoneCopied: 'Raqam nusxalandi: {number}'
  },

  /* -------------------------------------------------------
     ALOQA TURLARI / CONTACT CHANNEL NAMES
     The name of each channel. Shown on the small chips under the
     main buttons, and as the labels in the owner's form.
     ------------------------------------------------------- */
  channels: {
    phone:     'Telefon',
    telegram:  'Telegram',
    kakao:     'KakaoTalk',
    website:   'Veb-sayt',
    instagram: 'Instagram',
    tiktok:    'TikTok',
    appstore:  'App Store',
    playstore: 'Google Play'
  },

  /* -------------------------------------------------------
     HAVOLA NOMLARI / PASTED LINK NAMES
     When an owner pastes a link into their description, the page shows
     the name of the place it goes instead of the raw address. Brand
     names (Instagram, YouTube) need no translation; only these do.
     ------------------------------------------------------- */
  hosts: {
    naverMap:  'Naver xarita',
    kakaoMap:  'Kakao xarita',
    googleMap: 'Google xarita'
  },

  /* -------------------------------------------------------
     BIZNES EGALARI UCHUN / FOR BUSINESS OWNERS
     The one owner-facing card in the public views, at the end of
     every list, and the sheet behind it.
     ------------------------------------------------------- */
  owner: {
    cardTitle:   'Biznes egasimisiz?',
    // Normal case.
    cardBody:    'Biznesingizni katalogga qo‘shing — mijozlar sizni shu yerdan topadi.',
    // Shown in a category that has no businesses at all.
    cardBodyEmpty: 'Bu yo‘nalishga birinchi bo‘lib qo‘shiling.',
    // Shown where a top position is still free.
    cardBodySlots: 'Biznesingizni qo‘shing. Bu yo‘nalishda {n} ta yuqori o‘rin bo‘sh.',

    eyebrow:     'Biznes egalari uchun',
    title:       'Katalogga qo‘shilish',

    step1Title:  'Biznesni kiritish',
    step1Body:   'Bir martalik to‘lov — {amount}. Biznesingiz katalogda doimiy qoladi.',
    step2Title:  'Yuqori o‘rin (ixtiyoriy)',
    step2Body:   'Har bir yo‘nalishda dastlabki 3 ta o‘rin uchun taklif berish mumkin. Bu kiritish to‘lovidan alohida.',
    step3Title:  'O‘rinni egallash',
    step3Body:   'Hozirgi egasidan kamida {amount} ko‘proq summa taklif qilasiz. Avval taklif bergan bo‘lsangiz, faqat farqini to‘laysiz.',

    // The price table, shown only inside a category.
    pricesLabel: '{category} — hozirgi narxlar',
    pricesFrom:  'dan boshlab',
    pricesFine:  'Ko‘rsatilgan summa yoki undan ko‘prog‘ini taklif qilsangiz, shu o‘rin yoki undan yuqorisi sizniki bo‘ladi. To‘lov admin orqali amalga oshiriladi va tasdiqlangach o‘rin yangilanadi. To‘lov qaytarilmaydi.',
    // Shown instead of the table when no category is open yet.
    pricesPick:  'Yo‘nalish bo‘yicha narxlarni ko‘rish',

    submit:      'Biznesimni qo‘shish',
    mine:        'Mening bizneslarim'
  },

  /* -------------------------------------------------------
     BIZNES QO‘SHISH SHAKLI / THE SUBMISSION FORM
     ------------------------------------------------------- */
  form: {
    eyebrowNew:  'Yangi biznes',
    titleNew:    'Biznesni qo‘shish',
    titleEdit:   'Ma’lumotlarni tahrirlash',

    // Beside a field label. (short)
    required:    'majburiy',
    optional:    'ixtiyoriy',
    atLeastOne:  'kamida bittasi',

    nameLabel:       'Biznes nomi',
    namePlaceholder: 'Masalan: Samarqand Non',

    categoryLabel:   'Yo‘nalish',
    categoryPick:    'Tanlang',

    descLabel:       'Biznes haqida',
    // The card turns "Nomi: qiymati" lines into their own rows, so
    // the placeholder shows that shape rather than describing it.
    descPlaceholder: 'Manzil: Seoul, Itaewon-ro 12\nIsh vaqti: 09:00–21:00\nXizmatlar: yetkazib berish, buyurtma…',
    descNote:        'Har bir ma’lumotni alohida qatorga yozing — “Manzil: …”, “Ish vaqti: …”. Shunday yozilganlari mijozga alohida qator bo‘lib ko‘rinadi.',
    // Characters used out of the limit.
    counter:         '{n} / {max}',

    linksLabel:      'Aloqa',

    logoLabel:       'Logo',
    logoHint:        'PNG yoki JPG, kvadrat bo‘lsa yaxshi.',
    logoHintNew:     'Ixtiyoriy. PNG yoki JPG, kvadrat bo‘lsa yaxshi.',
    logoPick:        'Rasm tanlash',
    logoReplace:     'Almashtirish',
    logoPreparing:   'Tayyorlanmoqda…',
    logoUploading:   'Yuklanmoqda…',
    logoChosen:      'Tanlandi. Biznes bilan birga yuboriladi.',
    logoSaved:       'Saqlandi',

    fineNew:     'Arizangizni admin ko‘rib chiqadi. Katalogga kiritish to‘lovi — {amount}, admin bilan kelishib to‘lanadi.',
    fineEdit:    'O‘zgarishlar darhol saqlanadi, admin xabardor qilinadi.',

    send:        'Yuborish',
    sending:     'Yuborilmoqda…',
    save:        'Saqlash',
    saving:      'Saqlanmoqda…',
    sendingLogo: 'Logo yuklanmoqda…'
  },

  /* -------------------------------------------------------
     YUBORILGANDAN KEYIN / AFTER SENDING
     ------------------------------------------------------- */
  submitted: {
    title:      'Ariza yuborildi',
    body:       'Admin ko‘rib chiqqach biznesingiz katalogda paydo bo‘ladi. To‘lov bo‘yicha admin siz bilan bog‘lanadi.',
    // The listing went through but its picture did not.
    logoFailed: 'Biznes yuborildi, lekin logoni yuklab bo‘lmadi. Uni keyinroq «Mening bizneslarim» bo‘limidan qo‘shishingiz mumkin.'
  },

  /* -------------------------------------------------------
     MENING BIZNESLARIM / MY BUSINESSES
     The owner's own screen. Numbers only an owner cares about —
     how many people opened the listing, which position it holds —
     appear here and nowhere else.
     ------------------------------------------------------- */
  mine: {
    title:      'Mening bizneslarim',
    empty:      'Siz hali biznes qo‘shmagansiz.',
    loadFailed: 'Yuklab bo‘lmadi. Qayta urinib ko‘ring.',
    add:        'Yangi biznes qo‘shish',

    edit:       'Tahrirlash',
    bid:        'Yuqori o‘rin olish',
    cancelBid:  'Taklifni bekor qilish',

    // The three figures on an active listing. Labels sit under the number,
    // so keep them to one short word. (short)
    statViews:  'Ko‘rilgan',
    statLikes:  'Yoqtirgan',
    statPosition: 'O‘rin',

    // Used in the bidding sheet, where the position is named in a sentence.
    position:   '{n}-o‘rin',
    pendingBid: 'Taklif: {amount} — kutilmoqda',

    bidCancelled:    'Taklif bekor qilindi',
    bidCancelFailed: 'Bekor qilib bo‘lmadi'
  },

  /* -------------------------------------------------------
     HOLAT BELGILARI / LISTING STATUS
     The chip on each of the owner's listings. (short)
     ------------------------------------------------------- */
  status: {
    pending_review: 'Ko‘rib chiqilmoqda',
    unpaid:         'To‘lov kutilmoqda',
    active:         'Katalogda',
    rejected:       'Qabul qilinmadi',
    suspended:      'To‘xtatilgan'
  },

  /* -------------------------------------------------------
     YUQORI O‘RIN UCHUN TAKLIF / BIDDING
     ------------------------------------------------------- */
  bid: {
    title:        'Yuqori o‘rin olish',
    nowPosition:  'Hozirgi o‘rin',
    nowBid:       'Sizning taklifingiz',
    lead:         'O‘rinni tanlang. Avvalgi taklifingiz bo‘lsa, faqat farqini to‘laysiz.',

    // Under each amount: what this position costs from zero…
    optionMin:    'eng kam summa',
    // …or, if the owner already holds a bid, the difference.
    optionDue:    'qo‘shimcha to‘lov: {amount}',

    pickFirst:    'Avval o‘rinni tanlang',
    sendWith:     'Taklif yuborish — {amount}',
    send:         'Taklif yuborish',
    sending:      'Yuborilmoqda…',

    fine:         'Taklif admin to‘lovni tasdiqlagandan keyin kuchga kiradi. Shu orada boshqa biznes yuqoriroq taklif bersa, o‘rningiz o‘zgarishi mumkin. To‘lov qaytarilmaydi.',
    sentTitle:    'Taklif yuborildi',
    sentBody:     'To‘lov bo‘yicha admin siz bilan bog‘lanadi. To‘lov tasdiqlangach o‘rningiz yangilanadi.'
  },

  /* -------------------------------------------------------
     YO‘NALISHNI TANLASH / CATEGORY PICKER
     ------------------------------------------------------- */
  picker: {
    // When switching which category you are reading.
    title:       'Yo‘nalishlar',
    // When choosing one for your own business in the form.
    titleChoose: 'Yo‘nalishni tanlang',
    all:         'Barcha yo‘nalishlar'
  },

  /* -------------------------------------------------------
     RASMNI KO‘RISH / IMAGE VIEWER
     ------------------------------------------------------- */
  viewer: {
    label: 'Rasm'
  },

  /* -------------------------------------------------------
     SAHIFA YUKLANMASA / WHEN THE PAGE CANNOT LOAD
     ------------------------------------------------------- */
  pageError: {
    title: 'Yuklab bo‘lmadi',
    body:  'Internet aloqasini tekshirib, qayta urinib ko‘ring.'
  },

  /* -------------------------------------------------------
     SHAKL XATOLARI / FORM ERRORS
     Shown in red under the form. The name on the left is the code
     the server sends back — do not change those, only the Uzbek.
     ------------------------------------------------------- */
  submitErrors: {
    bad_name:             'Nomni tekshiring: 2 tadan 80 tagacha belgi.',
    bad_category:         'Yo‘nalishni tanlang.',
    description_too_long: 'Tavsif juda uzun (500 belgigacha).',
    no_contact:           'Kamida bitta aloqa usulini kiriting.',
    invalid_phone:        'Telefon raqami noto‘g‘ri.',
    invalid_handle:       'Username noto‘g‘ri: faqat harf, raqam, nuqta va pastki chiziq.',
    invalid_url:          'Havola noto‘g‘ri.',
    wrong_host:           'Havola bu maydonga mos emas.',
    link_too_long:        'Havola juda uzun.',
    duplicate:            'Bu nomdagi biznesingiz allaqachon yuborilgan.',
    rate_limited:         'Bugungi limitga yetdingiz. Ertaga urinib ko‘ring.',
    no_init_data:         'Buning uchun sahifani Telegram ichida oching.',
    bad_signature:        'Telegram hisobingizni tasdiqlab bo‘lmadi.'
  },

  /* -------------------------------------------------------
     LOGO XATOLARI / LOGO UPLOAD ERRORS
     ------------------------------------------------------- */
  logoErrors: {
    too_large:            'Rasm juda katta (6 MB gacha).',
    not_an_image:         'Bu fayl rasm emas.',
    bad_format:           'Bu format qo‘llab-quvvatlanmaydi.',
    no_file:              'Rasm tanlanmadi.',
    server_misconfigured: 'Rasm yuklash vaqtincha ishlamayapti.',
    // Any other failure.
    generic:              'Yuklab bo‘lmadi. Boshqa rasm sinab ko‘ring.'
  },

  /* -------------------------------------------------------
     TAKLIF XATOLARI / BIDDING ERRORS
     ------------------------------------------------------- */
  bidErrors: {
    too_low:        'Taklif juda past.',
    not_higher:     'Taklif hozirgi summangizdan yuqori bo‘lishi kerak.',
    already_pending: 'Sizda ko‘rib chiqilayotgan taklif bor.',
    bidding_closed: 'Bu yo‘nalishda hali o‘rin uchun taklif qabul qilinmaydi.',
    not_active:     'Biznes hali katalogda emas.',
    bad_amount:     'Summani tekshiring.'
  }

};
