// qna.js - Q&A page functionality with dummy data

const tg = window.Telegram.WebApp;
tg.ready();
tg.disableVerticalSwipes();

try {
  tg.expand();
} catch (e) {}

// ===========================================
// DUMMY DATA
// ===========================================

const dummyQuestions = [
  {
    id: 1,
    topic: "🕌 Namoz",
    title: "Juma namozini o'qish uchun nechta kishi bo'lishi shart?",
    questionBody: "Assalomu alaykum! Juma namozini to'g'ri o'qish uchun masjidda kamida nechta kishi bo'lishi kerak? Va agar bu miqdor to'lmasa, juma namozi sog'mi yoki yo'qmi?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Жума намози шаҳар аҳлига фарз қилинган. Шаҳар аҳли дегани камида қирқ киши демакдир. Демак, қирқ кишига етмаган жойда жума ўқилмайди. Агар қирқта ниятланиб, жума ўқишни бошласалар, аммо биров кетиб қолса-ю, қирқдан кам бўлиб қолса, жума жоиз бўлмайди, ҳаммалари зуҳр ўқишлари керак.\n\nЖума намозининг шартлари:\n1. Шаҳарда ўқилиши\n2. Камида қирқ киши бўлиши\n3. Жамоат билан ўқилиши\n4. Хутба ўқилиши\n5. Зуҳр вақтида ўқилиши\n\nШунинг учун агар бу шартлардан бири тўлмаса, жума намози сог' бўлмайди.",
    link: "https://savollar.islom.uz/s/12345",
    views: 72242
  },
  {
    id: 2,
    topic: "🌙 Ro'za",
    title: "Рамазон ойида саҳарлик еб бўлиб, тонг отганини билмай ухлаб қолсам",
    questionBody: "Ассалому алайкум! Агар мен саҳарлик еб бўлиб, тонг отганини билмай ухлаб қолсам ва кундузи уйғониб қолсам, рўзам тўғрими? Қазо қилишим керакми?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Агар сиз тонг отганини билмай, билиб туриб емаган, ичмаган бўлсангиз, рўзангиз тўғри. Чунки: «Қасддан қилинмаган хато гуноҳ эмас» деган қоида бор.\n\nАммо бу ҳолда икки нарсани тушуниш керак:\n1. Агар тонг отишидан олдин еган-ичган бўлсангиз, кейин ухлаб қолсангиз - рўзангиз тўғри\n2. Агар тонг отганидан кейин еган-ичган бўлсангиз (гарчи билмаган бўлсангиз ҳам) - қазо қилишингиз керак\n\nШунинг учун саҳарлик еганингиздан кейин албатта вақтни текшириб олинг.",
    link: "https://savollar.islom.uz/s/12346",
    views: 45123
  },
  {
    id: 3,
    topic: "💍 Oila va turmush",
    title: "Аёл киши бегона эркакларга қараши ҳақида",
    questionBody: "Ассалому алайкум! Менинг хотиним бегона эркакларга кўп қарайди. Мен буни кўп маротаба такрорлаган едим, аммо фойдаси бўлмайди. Бу ҳақда нима дейиш мумкин?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Аёллар ҳам эркаклар каби бегона жинсга қараши ман этилган. Аллоҳ таоло Қуръони каримда шундай марҳамат қилади:\n\n«Мўъмина аёлларга айт: кўзларини (ҳаромдан) тийсинлар» (Нур сураси, 31-оят)\n\nБу масалада:\n1. Хотинингизга насиҳат қилинг, аммо камтарлик билан\n2. Бу гуноҳнинг оқибатлари ҳақида гапиринг\n3. Шариат китобларидан ўқитинг\n4. Яхши ўрнак бўлинг - ўзингиз ҳам бегона аёлларга қараманг\n5. Дуо қилинг\n\nАгар ҳали ҳам тузалмаса, оилавий маслаҳатчига мурожаат қилинг.",
    link: "https://savollar.islom.uz/s/12347",
    views: 68920
  },
  {
    id: 4,
    topic: "🍽️ Halol va harom",
    title: "Телефонда мусиқа тинглаш аксессуарларини сотиш жоизми?",
    questionBody: "Ассалому алайкум! Мен дўконда телефон жиҳозлари ёки мусиқа эшитиш учун мўлжалланган аксессуарлар (наушник, кабеллар) сотаман. Бу жоизми?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Наушник ва кабеллар фақат мусиқа учун эмас, балки турли мақсадлар учун ишлатилади:\n- Қуръон тинглаш\n- Дарс тинглаш\n- Телефон қилиш\n- Аудио китоб тинглаш\n\nШунинг учун бу аксессуарларни сотиш жоиз. Чунки:\n1. Асл вазифаси товуш узатиш\n2. Ҳаром ишда ишлатилиши мажбурий эмас\n3. Халол ишда кўп фойдаланилади\n\nАммо агар махсус мусиқа асбоби (масалан, гитара) бўлса, уни сотиш жоиз эмас.",
    link: "https://savollar.islom.uz/s/12348",
    views: 34567
  },
  {
    id: 5,
    topic: "💰 Zakot",
    title: "Олтин заргарликка закот тўлашми?",
    questionBody: "Ассалому алайкум! Менинг хотинимнинг турли олтин заргарликлари бор. Шуларга закот тўлаш керакми? Қанча бўлганда тўлаш керак?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Олтин заргарликка закот фарз. Бунинг учун икки шарт бор:\n\n1. Нисоб миқдорига етиши - 85 грамм\n2. Бир йил устида турган бўлиши\n\nАгар заргарликлар жами 85 граммдан ортиқ бўлса ва бир йил ўтган бўлса, 2.5% закот тўланади.\n\nМисол: Агар 100 грамм олтин бўлса:\n- 100 х 2.5% = 2.5 грамм олтин ёки унга тенг пул\n\nИстисно:\nАгар хотин ҳар куни таққан заргарликлари бўлса ва улар одатдан ташқари кўп бўлмаса, баъзи уламолар закот тўланмаслигини айтганлар. Лекин закот тўлаш афзалроқ.",
    link: "https://savollar.islom.uz/s/12349",
    views: 52341
  },
  {
    id: 6,
    topic: "💧 Tahоrat",
    title: "Қуръон ўқийман деб ният қилиб таҳорат олсам, шу таҳорат билан намоз ўқиса бўладими?",
    questionBody: "Ассалому алайкум! Қуръон ўқийман деб ният қилиб таҳорат олсам, кейин шу таҳорат билан фарз намозларни ўқиса бўладими?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Ҳа, бўлади. Таҳорат нияти умумий бўлади. Яъни:\n\n1. Фақат таҳорат олмоқ учун ният қилсангиз ҳам кифоя\n2. Намоз учун ният қилиб олсангиз ҳам, Қуръон ўқишга ҳам ярайди\n3. Қуръон учун олсангиз, намозга ҳам ярайди\n\nЧунки таҳоратнинг ўзи покланишдир. Қайси ибодат учун олишингиз муҳим эмас, барча покликни талаб қилувчи ишларга яроқли.\n\nАммо бир нарсани эслатиб ўтай: таҳорат бузилмаган экан, қайта олишга ҳожат йўқ.",
    link: "https://savollar.islom.uz/s/12350",
    views: 28765
  },
  {
    id: 7,
    topic: "👶 Bola tarbiyasi",
    title: "Болаларни неча ёшдан намозга ўргатиш керак?",
    questionBody: "Ассалому алайкум! Менинг болаларим 5 ва 7 ёшда. Уларни намозга қачондан ўргатишни бошлашим керак?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Росулуллоҳ соллаллоҳу алайҳи васаллам марҳамат қилганлар:\n\n«Болаларингизни етти ёшида намозга буюринглар, ўн ёшида (ўқимаса) уринглар» (Абу Довуд)\n\nДемак:\n\n1. 7 ёшдан бошлаб намозга ўргатиш бошланади\n2. 10 ёшда қатъий талаб қилинади\n3. Аммо 7 ёшгача ҳам тайёрлаш керак:\n   - Сиз намоз ўқиганингизда кузатсин\n   - Таҳорат олишни кўрсатинг\n   - Қисқа суралар ўргатинг\n\nМуҳими: зўрлик билан эмас, севги ва сабр билан ўргатинг. Намозни ёқтириш керак, қўрқиш эмас.\n\n5 ёшли болангиз учун:\n- Таҳорат ва намоз ҳақида ҳикоялар\n- Сиз билан бирга туришга рухсат беринг\n- Таҳсин ва рағбатлантиринг",
    link: "https://savollar.islom.uz/s/12351",
    views: 41234
  },
  {
    id: 8,
    topic: "🕋 Haj va umra",
    title: "Ҳаж қилмасдан умра қилиш мумкинми?",
    questionBody: "Ассалому алайкум! Мен ҳали ҳажга бормаганман, лекин умрага бориш имконияти бор. Аввал умрага борсам бўладими, ёки аввал ҳажни қилишим шартми?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Ҳа, аввал умрага бориш мумкин. Ҳаж билан умра ўртасида тартиб йўқ.\n\nСабаби:\n1. Умра йил давомида қилинади, ҳаж фақат зулҳижжа ойида\n2. Ҳаж фарз (шарт бўлса), умра сунна\n3. Умра қилиш ҳажга тайёрланишга ёрдам беради\n\nАммо:\n- Агар имкониятингиз ҳам ҳаж, ҳам умрага етса, аввал ҳажни қилинг\n- Агар ҳаж фарз бўлган бўлса (молиявий имконият, саломатлик), уни кечиктирманг\n- Умра савоби катта, лекин ҳаж фарзни бажаришдан кейин қилинг\n\nХулоса: Аввал умра қилсангиз ҳам жоиз, лекин ҳаж имконияти бўлса, уни биринчи ўринга қўйинг.",
    link: "https://savollar.islom.uz/s/12352",
    views: 38901
  },
  {
    id: 9,
    topic: "⚕️ Tabоbat",
    title: "Тиббиёт дарсларида одам расмини чизиш мумкинми?",
    questionBody: "Ассалому алайкум! Мен тиббиёт факультетида ўқийман. Дарсларда одам ва унинг ички аъзоларининг расмини чизиш талаб қилинади. Бу ман этилганми?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Тиббиёт ўқиш ва ўргатиш учун зарур бўлган расм чизиш жоиз.\n\nСабаблари:\n1. Зарурат қонунда рухсат беради\n2. Тиббиёт ўрганиш фарзи кифоядир (жамоа учун фарз)\n3. Мақсад санъат эмас, илм\n\nШартлар:\n- Фақат ўқиш мақсадида\n- Зарур миқдорда\n- Бутун жонли махлуқ расмини безаш учун эмас\n\nДемак, анатомия китобларидаги расмлар, медицина дарсликларидаги чизмалар - жоиз.\n\nАммо:\n- Одамни бутун қиёфасини безаш учун чизиш - макруҳ\n- Фотосурат олиш зарурат бўлса - жоиз\n- Ҳайкал ясаш - ҳаром",
    link: "https://savollar.islom.uz/s/12353",
    views: 33456
  },
  {
    id: 10,
    topic: "📖 Quron",
    title: "Қуръонни тушунмай ўқиш савоб берадими?",
    questionBody: "Ассалому алайкум! Мен арабча билмайман, лекин Қуръон ўқий оламан. Маъносини тушунмасам ҳам савоб оламанми?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Ҳа, Қуръон тиловат қилиш маъносини билмаганда ҳам савоб беради.\n\nРосулуллоҳ соллаллоҳу алайҳи васаллам марҳамат қилганлар:\n«Қуръондан бир ҳарф ўқиган киши бир савоб олади. Бир савоб ўн баравар. Мен «Алиф-лом-мим» бир ҳарф демаяпман. Балки алиф бир ҳарф, лом бир ҳарф, мим бир ҳарфдир» (Термизий)\n\nАммо:\n1. Маънони билиб ўқиш яхшироқ ва фойдалироқ\n2. Камида таржимасини ўқиш керак\n3. Амал қилиш учун маъно билиш шарт\n\nШунинг учун:\n- Ҳар куни тиловат қилаверинг (савоб олиш учун)\n- Паралель равишда таржимасини ўқинг (тушуниш учун)\n- Тафсир дарсларига қатнашинг (чуқур англаш учун)",
    link: "https://savollar.islom.uz/s/12354",
    views: 56789
  },
  {
    id: 11,
    topic: "🕌 Namoz",
    title: "Витр намозини қачон ўқиш афзал?",
    questionBody: "Ассалому алайкум! Витр намозини хуфтондан кейин дарҳол ўқиш яхшими ёки кечаси уйғониб ўқиш яхшими?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Витр намозини кечқурун ухлашдан олдин ўқиш сунна. Лекин вақт ва ҳолатга қараб икки усул бор:\n\n1. Агар кечаси уйғонишга ишончингиз бўлмаса:\n   - Хуфтондан кейин дарҳол витр ўқинг\n   - Бу Росулуллоҳнинг Абу Ҳурайрага қилган тавсияси\n\n2. Агар кечаси уйғонишга ишончингиз бор бўлса:\n   - Тонг отишидан олдин витр ўқинг\n   - Бу афзалроқ, чунки тонг отишга яқин дуо қабул бўлади\n\nМуҳими: витр бир кечада икки марта ўқилмайди. Агар хуфтондан кейин ўқиган бўлсангиз, кечаси яна ўқимайсиз.",
    link: "https://savollar.islom.uz/s/12355",
    views: 44321
  },
  {
    id: 12,
    topic: "💍 Oila va turmush",
    title: "Хотиннинг ота-онасига хизмат қилиш мажбурми?",
    questionBody: "Ассалому алайкум! Эрим менинг ота-онамга кўп хизмат қилишимни талаб қиляпти. Мен унинг ота-онасига қанчалик хизмат қилишим керак?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Хотиннинг қайнона-қайнотага хизмат қилиши:\n\n1. Шариатда мажбур эмас - чунки хотиннинг асл мажбурияти эрига\n2. Лекин яхши ахлоқ - хизмат қилса яхши\n3. Эр талаб қилса, имкони борича бажариш керак\n\nАммо:\n- Ҳаддан ошмаслиги керак\n- Хотиннинг соғлиғи ва имконияти ҳисобга олинсин\n- Ўз ота-онасига ҳам вақт ажратсин\n\nЭр учун:\n- Хотиндан ҳаддан ошиқ талаб қилманг\n- Унинг имкониятини ҳурмат қилинг\n- Ўзингиз ҳам ота-онангизга хизмат қилинг\n\nОила тинчлиги учун икки томон тушунишга келиши керак.",
    link: "https://savollar.islom.uz/s/12356",
    views: 39876
  },
  {
    id: 13,
    topic: "💰 Moliya va tijоrat",
    title: "Банк кредити билан уй олиш жоизми?",
    questionBody: "Ассалому алайкум! Мен уй олмоқчиман, лекин пулим етмайди. Банкдан кредит олсам бўладими?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Одатдаги банк кредити (фоизли) ҳаром. Чунки:\n\n1. Аллоҳ риборо (фоиз)ни қатъий ман этган\n2. «Аллоҳ савдо-сотиқни ҳалол, риборони ҳаром қилди» (Бақара, 275)\n3. Фоиз олиш ва бериш ҳаром\n\nАммо:\n1. Исломий банклардан мурабаҳа (фойдага сотиш) усулида олиш жоиз\n2. Оила аъзоларидан ёки дўстлардан фоизсиз қарз олиш яхши\n3. Тежамкорлик қилиб, аста-секин пул йиғиш\n\nМуҳтож бўлган ҳолатда:\n- Баъзи уламолар дейишларича, зарурат бўлганда рухсат бор\n- Лекин бу масалада эҳтиёт қилиш керак\n- Исломий банк бўлса, ундан фойдаланинг",
    link: "https://savollar.islom.uz/s/12357",
    views: 61234
  },
  {
    id: 14,
    topic: "🌙 Ro'za",
    title: "Оғиз бўшлиғини чайқашда сув ютиб юборсам, рўза бузиладими?",
    questionBody: "Ассалому алайкум! Рўза тутган ҳолда тишларимни ювишда сув ҳалқимга ўтиб кетди. Рўзам бузилдими?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Агар қасддан ичмаган бўлсангиз, рўзангиз бузилмайди.\n\nСабаби:\n1. Билиб туриб қилмаган хато - гуноҳ эмас\n2. Унутиб еса ёки ичса - рўза бузилмайди\n3. Мажбуран бўлса - рўза тўғри\n\nАммо эҳтиёт чоралари:\n1. Оғиз чайқашда эҳтиёт қилинг\n2. Кучли чайқаманг\n3. Ҳалқумга сув бормасин\n\nАгар қасддан ютсангиз:\n- Рўза бузилади\n- Қазо қилиш керак\n- Каффора (жарима) ҳам керак бўлиши мумкин\n\nШунинг учун рўза тутаётганда оғиз чайқашда жуда эҳтиёт бўлинг.",
    link: "https://savollar.islom.uz/s/12358",
    views: 48765
  },
  {
    id: 15,
    topic: "🧕 Ayollarga oid",
    title: "Аёл кишига ишга чиқиш жоизми?",
    questionBody: "Ассалому алайкум! Мен ишга чиқмоқчиман, лекин оилам қарши. Аёлга ишлаш жоизми?",
    answerSource: "Шайх Муҳаммад Содиқ Муҳаммад Юсуф",
    answerBody: "Аёлнинг ишлаши асосан жоиз. Аммо шартлар билан:\n\n1. Эрнинг рухсати бўлиши керак (турмушга чиққан бўлса)\n2. Шариат қоидаларига риоя қилиниши керак:\n   - Ҳижоб\n   - Бегона эркаклар билан хилват қилмаслик\n   - Адаб-ахлоқ сақланиши\n\n3. Оила мажбуриятларига зарар етказмаслик:\n   - Болаларни парвариш қилиш\n   - Уй ишлари\n   - Эрга хизмат\n\nАгар бу шартлар бажарилса, аёл ишлаши мумкин:\n- Тиббиёт (аёллар касаллари)\n- Таълим (қизлар мактаби)\n- Бошқа ҳалол касблар\n\nМуҳими: оила тинчлиги ва шариат қоидалари устун.",
    link: "https://savollar.islom.uz/s/12359",
    views: 54321
  }
];

// ===========================================
// STATE MANAGEMENT
// ===========================================

let currentView = 'browse'; // 'browse' | 'results' | 'modal'
let selectedAlphabet = 'cyrillic';
let currentQuestions = [];
let displayedCount = 10;
let searchResults = [];
let currentQuestion = null;

// ===========================================
// DOM ELEMENTS
// ===========================================

const alphabetSelector = document.getElementById('alphabetSelector');
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
// ALPHABET SELECTOR
// ===========================================

document.querySelectorAll('.alphabet-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    // Remove active class from all buttons
    document.querySelectorAll('.alphabet-btn').forEach(b => b.classList.remove('active'));
    
    // Add active class to clicked button
    btn.classList.add('active');
    
    // Update selected alphabet
    selectedAlphabet = btn.dataset.alphabet;
    
    // Update placeholder
    if (selectedAlphabet === 'latin') {
      searchInput.placeholder = "Savolingizni bu yerga yozing...";
    } else {
      searchInput.placeholder = "Саволингизни бу ерга ёзинг...";
    }
    
    console.log(`Alphabet changed to: ${selectedAlphabet}`);
  });
});

// ===========================================
// UTILITY FUNCTIONS
// ===========================================

function shuffleArray(array) {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

function getRandomQuestions(count = 10) {
  const shuffled = shuffleArray(dummyQuestions);
  return shuffled.slice(0, count);
}

function formatViews(views) {
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
  
  card.innerHTML = `
    <div class="card-header">
      <span class="topic-badge">${question.topic}</span>
      <span class="view-count">👁️ ${formatViews(question.views)}</span>
    </div>
    <h3 class="card-title">${question.title}</h3>
    <div class="card-scholar">
      <span class="scholar-icon">📚</span>
      <span>${question.answerSource}</span>
    </div>
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
        <p style="font-size: 1.1rem; font-weight: 600; color: #555; margin-bottom: 8px;">
          Ҳеч қандай натижа топилмади
        </p>
        <p style="font-size: 0.9rem; color: #888;">
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

function openAnswerModal(question) {
  currentQuestion = question;
  
  // Populate modal content
  document.getElementById('modalCategory').textContent = question.topic;
  document.getElementById('questionTitle').textContent = question.title;
  document.getElementById('questionBody').textContent = question.questionBody;
  document.getElementById('answerSource').querySelector('.source-text').textContent = question.answerSource;
  document.getElementById('answerBody').textContent = question.answerBody;
  document.getElementById('sourceLink').href = question.link;
  
  // Render related questions
  renderRelatedQuestions(question);
  
  // Show modal
  answerModal.style.display = 'block';
  document.body.style.overflow = 'hidden';
  
  // Scroll to top of modal
  document.querySelector('.modal-content').scrollTop = 0;
}

function closeAnswerModal() {
  answerModal.style.display = 'none';
  document.body.style.overflow = 'auto';
}

function renderRelatedQuestions(currentQuestion) {
  const relatedList = document.getElementById('relatedList');
  relatedList.innerHTML = '';
  
  // Get 3 random questions from same topic (excluding current)
  const sameTopic = dummyQuestions.filter(q => 
    q.topic === currentQuestion.topic && q.id !== currentQuestion.id
  );
  
  const related = shuffleArray(sameTopic).slice(0, 3);
  
  related.forEach(q => {
    const item = document.createElement('div');
    item.className = 'related-item';
    item.textContent = q.title;
    item.addEventListener('click', () => {
      openAnswerModal(q);
    });
    relatedList.appendChild(item);
  });
}

// ===========================================
// SEARCH FUNCTIONALITY
// ===========================================

function simulateSearch(query) {
  // Show loading
  loadingOverlay.style.display = 'flex';
  
  setTimeout(() => {
    // Simple search: check if query words are in title or question body
    const queryWords = query.toLowerCase().split(' ').filter(w => w.length > 2);
    
    searchResults = dummyQuestions.filter(q => {
      const searchText = (q.title + ' ' + q.questionBody).toLowerCase();
      return queryWords.some(word => searchText.includes(word));
    });
    
    // Sort by relevance (mock: just shuffle)
    searchResults = shuffleArray(searchResults).slice(0, 10);
    
    // Hide loading
    loadingOverlay.style.display = 'none';
    
    // Show results
    showResultsView();
  }, 1500);
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
    alert('Илтимос, камида 3 та ҳарф ёзинг');
    return;
  }
  
  console.log(`Searching for: ${query} (Alphabet: ${selectedAlphabet})`);
  simulateSearch(query);
});

// Search on Enter key
searchInput.addEventListener('keypress', (e) => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    searchBtn.click();
  }
});

refreshBtn.addEventListener('click', () => {
  currentQuestions = getRandomQuestions(15);
  displayedCount = 10;
  renderBrowseQuestions();
  
  // Animate button
  refreshBtn.style.transform = 'rotate(360deg)';
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
  if (currentView === 'results') {
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

function initQnAPage() {
  console.log('✅ Q&A page initialized');
  console.log(`   Total questions in database: ${dummyQuestions.length}`);
  
  // Load initial random questions
  currentQuestions = getRandomQuestions(15);
  displayedCount = 10;
  renderBrowseQuestions();
  
  console.log(`   Showing ${displayedCount} questions initially`);
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', initQnAPage);
