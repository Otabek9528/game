// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get tagline => 'Для мусульман в Корее';

  @override
  String get greetingLabel => 'Ассаляму алейкум';

  @override
  String get languageQuestion => 'На каком языке продолжим?';

  @override
  String get languageNote => 'Часть разделов пока только на узбекском';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get saveAction => 'Сохранить';

  @override
  String get changeLaterHint => 'Язык можно изменить позже в настройках';

  @override
  String get changeLanguage => 'Сменить язык';

  @override
  String get prayerFajr => 'Фаджр';

  @override
  String get prayerSunrise => 'Восход';

  @override
  String get prayerDhuhr => 'Зухр';

  @override
  String get prayerAsr => 'Аср';

  @override
  String get prayerMaghrib => 'Магриб';

  @override
  String get prayerIsha => 'Иша';

  @override
  String get untilFajr => 'До Фаджра';

  @override
  String get untilFajrEnds => 'До конца Фаджра';

  @override
  String get untilDhuhr => 'До Зухра';

  @override
  String get untilAsr => 'До Асра';

  @override
  String get untilMaghrib => 'До Магриба';

  @override
  String get untilIsha => 'До Иши';

  @override
  String get locationPlaceholder => 'Местоположение';

  @override
  String get locating => 'Определяем…';

  @override
  String get locationJustNow => 'Только что';

  @override
  String locationMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минуты назад',
      many: '$count минут назад',
      few: '$count минуты назад',
      one: '$count минуту назад',
    );
    return '$_temp0';
  }

  @override
  String locationHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часа назад',
      many: '$count часов назад',
      few: '$count часа назад',
      one: '$count час назад',
    );
    return '$_temp0';
  }

  @override
  String locationDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня назад',
      many: '$count дней назад',
      few: '$count дня назад',
      one: '$count день назад',
    );
    return '$_temp0';
  }

  @override
  String get locationFailedShort => 'Не удалось';

  @override
  String get refreshLocation => 'Обновить местоположение';

  @override
  String get locationNeededTitle => 'Для времени намаза нужна геолокация';

  @override
  String get locationNeededBody =>
      'Время рассчитывается по вашему городу. Геолокация используется только для этого.';

  @override
  String get useMyLocation => 'Определить местоположение';

  @override
  String get locationDeniedBody =>
      'У приложения нет доступа к геолокации. Включите его в настройках приложения.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get locationOffBody => 'На телефоне выключена геолокация (GPS).';

  @override
  String get turnOnLocation => 'Включить';

  @override
  String get locationFailedBody => 'Не удалось определить местоположение.';

  @override
  String get timesFailedBody =>
      'Не удалось загрузить время намаза. Проверьте интернет.';

  @override
  String get retry => 'Повторить';

  @override
  String get newBadge => 'Новое';

  @override
  String get featurePrayers => 'Время намаза';

  @override
  String get featureMosques => 'Мечети';

  @override
  String get featureRestaurants => 'Рестораны';

  @override
  String get featureShops => 'Магазины';

  @override
  String get featureNotifications => 'Уведомления';

  @override
  String get featureQibla => 'Кибла';

  @override
  String get featureQna => 'Спросите знающих';

  @override
  String get featureBarcode => 'Проверка состава';

  @override
  String get featureHousing => 'Жильё';

  @override
  String get featureCars => 'Vegukin Cars';

  @override
  String get featureHikorea => 'Иммиграционные службы';

  @override
  String get featureJobs => 'Вакансии';

  @override
  String get featureParcel => 'Посылки';

  @override
  String get featureLinks => 'Полезные ссылки';

  @override
  String get featureDonation => 'Поддержать';

  @override
  String get featureCommunity => 'Сообщество';

  @override
  String get featureBusiness => 'Бизнес-каталог';

  @override
  String get businessTagline => 'Узбекский бизнес в Корее';

  @override
  String businessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count бизнеса',
      many: '$count бизнесов',
      few: '$count бизнеса',
      one: '$count бизнес',
    );
    return '$_temp0';
  }

  @override
  String categoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count направления',
      many: '$count направлений',
      few: '$count направления',
      one: '$count направление',
    );
    return '$_temp0';
  }

  @override
  String get webLoadFailed =>
      'Не удалось открыть страницу. Проверьте интернет.';

  @override
  String get webReload => 'Обновить';

  @override
  String get webOpenInBrowser => 'Открыть в браузере';

  @override
  String get cameraDenied => 'Нет доступа к камере';

  @override
  String get widgetOpenApp => 'Откройте приложение, чтобы увидеть время намаза';

  @override
  String get exactAlarmsTitle => 'Точное время';

  @override
  String get exactAlarmsBody =>
      'Чтобы напоминания о намазе и виджет срабатывали точно вовремя, включите «Будильники и напоминания» на следующей странице.';

  @override
  String get exactAlarmsAllow => 'Продолжить';

  @override
  String get exactAlarmsLater => 'Позже';

  @override
  String get prayersTitle => 'Время намаза';

  @override
  String get nextPrayer => 'Следующий намаз';

  @override
  String get remaining => 'осталось';

  @override
  String get suhoorLabel => 'Сухур (конец)';

  @override
  String get iftarLabel => 'Ифтар';

  @override
  String get chipNow => 'сейчас';

  @override
  String get chipNext => 'следующий';

  @override
  String get fastWindow => 'Время поста · от сухура до ифтара';

  @override
  String get dayToday => 'Сегодня';

  @override
  String get dayTomorrow => 'Завтра';

  @override
  String get dayYesterday => 'Вчера';

  @override
  String get previousDay => 'Предыдущий день';

  @override
  String get nextDay => 'Следующий день';

  @override
  String get backToToday => 'Вернуться к сегодня';

  @override
  String get dayLoading => 'Загрузка...';

  @override
  String get dayLoadFailed => 'Не удалось загрузить';

  @override
  String get commentFajr => 'Время Иша заканчивается';

  @override
  String get commentSunrise => 'Время Фаджр заканчивается';

  @override
  String get commentAsr => 'Время Зухр заканчивается';

  @override
  String get commentMaghrib => 'Время Аср заканчивается';

  @override
  String get commentIsha => 'Время Магриб заканчивается';

  @override
  String get settingsShort => 'Настройки';

  @override
  String get settingsTitle => 'Настройки намаза';

  @override
  String get settingsSubtitle => 'Выберите метод расчёта и мазхаб';

  @override
  String get methodLabel => 'Метод расчёта';

  @override
  String get madhabLabel => 'Мазхаб (для времени Аср)';

  @override
  String get schoolHanafi => 'Ханафи';

  @override
  String get schoolShafii => 'Шафии / Малики / Ханбали';

  @override
  String get schoolShafiiShort => 'Шафии';

  @override
  String get hanafiNote => 'Тень = 2× длина';

  @override
  String get shafiiNote => 'Тень = 1× длина';

  @override
  String get methodMwl => 'Muslim World League';

  @override
  String get methodKarachi => 'Карачи';

  @override
  String get methodMakkah => 'Мекка';

  @override
  String get methodEgypt => 'Египет';

  @override
  String get methodIsna => 'ISNA';

  @override
  String get methodMwlHint => 'Фаджр 18°, Иша 17°';

  @override
  String get methodKarachiHint => 'Фаджр 18°, Иша 18°';

  @override
  String get methodMakkahHint =>
      'Фаджр 18.5°, Иша - через 90 мин после Магриба';

  @override
  String get methodEgyptHint => 'Фаджр 19.5°, Иша 17.5°';

  @override
  String get methodIsnaHint => 'Фаджр 15°, Иша 15°';

  @override
  String get naflTitle => 'Время добровольных (нафль) молитв';

  @override
  String get tahajjudName => 'Тахаджуд намаз';

  @override
  String get tahajjudText =>
      'Совершаемая после молитвы Иша, после сна. Минимум - 2 ракаата, максимум - 8 ракаатов. Наилучшее время - последняя треть ночи - время, когда принимаются мольбы.';

  @override
  String get tahajjudQuote =>
      'Она приближает к вашему Господу, искупает дурные поступки и удерживает от грехов.';

  @override
  String get tahajjudSource => 'Источник: Ат-Тирмизи - Абу Умома (р.а.)';

  @override
  String get ishraqName => 'Шурук (Ишрак) намаз';

  @override
  String get ishraqQuote =>
      'Тому, кто прочитал фаджр в джамаате, сидел в зикре до восхода солнца и затем совершил два ракаата намаза - даётся полная награда хаджа и умры.';

  @override
  String get ishraqSource =>
      'Источник: Ат-Тирмизи - Муаз ибн Анас аль-Джухани (р.а.)';

  @override
  String get duhaName => 'Духа намаз';

  @override
  String get duhaText =>
      'Когда солнце поднимается на высоту копья, (время молитвы) начинается и продолжается до того, как до полудня остаётся один час. Предпочтительно совершить 4 ракаата. Наилучшее время - после того, как пройдет четверть утра.';

  @override
  String get duhaQuote =>
      'Кто постоянно совершает молитву духа (чошгох), тому будут прощены грехи, даже если они подобны морской пене.';

  @override
  String get duhaSource => 'Источник: Ат-Тирмизи - Абу Хурайра (р.а.)';

  @override
  String get statusNow => 'Сейчас';

  @override
  String get statusUpcoming => 'Ожидается';

  @override
  String get statusPassed => 'Прошло';

  @override
  String get statusOtherDay => 'Другой день';

  @override
  String get reminderHint =>
      'Нажмите на колокольчик, чтобы настроить напоминание для намаза';

  @override
  String reminderFor(String name) {
    return '$name: напоминание';
  }

  @override
  String reminderToday(String range) {
    return 'Сегодня: $range';
  }

  @override
  String get reminderHow => 'Как напомнить';

  @override
  String get reminderWhen => 'Когда';

  @override
  String get reminderOff => 'Выкл.';

  @override
  String get reminderOffHint => 'Без напоминания';

  @override
  String get reminderSilent => 'Тихо';

  @override
  String get reminderSilentHint => 'Только уведомление';

  @override
  String get reminderVibrate => 'Вибрация';

  @override
  String get reminderVibrateHint => 'Без звука';

  @override
  String get reminderSound => 'Звук';

  @override
  String get reminderSoundHint => 'Короткая мягкая мелодия';

  @override
  String get reminderPlay => 'Прослушать';

  @override
  String get reminderAt => 'Время напоминания';

  @override
  String get reminderDone => 'Готово';

  @override
  String get offsetOnTime => 'Вовремя';

  @override
  String offsetBefore(String duration) {
    return 'за $duration';
  }

  @override
  String offsetAfter(String duration) {
    return 'через $duration';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String durationHours(int hours) {
    return '$hours ч';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get notificationsOff =>
      'Уведомления выключены — напоминания не придут';

  @override
  String get notificationsTurnOn => 'Включить';

  @override
  String notifyAt(String name) {
    return 'Время намаза $name';
  }

  @override
  String notifyBefore(String name, String duration) {
    return 'До намаза $name $duration';
  }

  @override
  String notifyAfter(String name, String duration) {
    return 'Намаз $name начался $duration назад';
  }

  @override
  String get notifySunriseAt => 'Восход — время Фаджра закончилось';

  @override
  String notifySunriseBefore(String duration) {
    return 'До конца Фаджра $duration';
  }

  @override
  String notifySunriseAfter(String duration) {
    return 'Солнце взошло $duration назад';
  }

  @override
  String get notifyImsakAt => 'Время сухура закончилось';

  @override
  String notifyImsakBefore(String duration) {
    return 'До конца сухура $duration';
  }

  @override
  String notifyImsakAfter(String duration) {
    return 'Сухур закончился $duration назад';
  }

  @override
  String notifyBody(String name, String start, String end, String city) {
    return '$name: $start – $end · $city';
  }

  @override
  String get suhoorShort => 'Сухур';

  @override
  String get qiblaTitle => 'Направление Киблы';

  @override
  String get qiblaPreparing => 'Подготовка компаса...';

  @override
  String get qiblaHoldFlat => 'Держите устройство горизонтально';

  @override
  String get qiblaHoldFlatShort => 'Держите телефон ровно';

  @override
  String get qiblaNoLocation =>
      'Чтобы рассчитать направление Киблы, нужно ваше местоположение.';

  @override
  String get qiblaNoCompassTitle => 'Компас не найден';

  @override
  String get qiblaNoCompass => 'На этом устройстве нет датчика компаса.';

  @override
  String get qiblaNorth => 'Север';

  @override
  String get qiblaEast => 'Восток';

  @override
  String get qiblaSouth => 'Юг';

  @override
  String get qiblaWest => 'Запад';

  @override
  String get qiblaDirection => 'Направление';

  @override
  String get qiblaAngle => 'Угол Киблы';

  @override
  String get qiblaLocation => 'Город';

  @override
  String get qiblaToMakkah => 'До Мекки';

  @override
  String get qiblaSignal => 'Сигнал компаса';

  @override
  String get qiblaQualityExcellent => 'Отлично';

  @override
  String get qiblaQualityGood => 'Хорошо';

  @override
  String get qiblaQualityMedium => 'Средне';

  @override
  String get qiblaQualityPoor => 'Плохо';

  @override
  String get qiblaNeedsCalibration => 'Нужна калибровка';

  @override
  String get qiblaInterference => 'Рядом металл или электроника';

  @override
  String qiblaAccuracy(int degrees) {
    return '±$degrees°';
  }

  @override
  String qiblaDeclination(String degrees) {
    return 'Учтено магнитное склонение $degrees°';
  }

  @override
  String get qiblaTipsTitle => 'Для точного результата';

  @override
  String get qiblaTip1 => 'Держите телефон горизонтально';

  @override
  String get qiblaTip2 => 'Держитесь подальше от металла';

  @override
  String get qiblaTip3 => 'Отойдите от электроники';

  @override
  String get qiblaTip4 => 'Используйте на открытом воздухе';

  @override
  String get qiblaTip5 =>
      'В режиме камеры держите телефон вертикально и совместите метку Каабы с центром';

  @override
  String get qiblaAligned => 'Вы направлены на Киблу!';

  @override
  String get qiblaSlightlyRight => 'Немного поверните вправо';

  @override
  String get qiblaSlightlyLeft => 'Немного поверните влево';

  @override
  String get qiblaTurnRight => 'Поверните вправо';

  @override
  String get qiblaTurnLeft => 'Поверните влево';

  @override
  String get qiblaModeCompass => 'Компас';

  @override
  String get qiblaModeCamera => 'Камера';

  @override
  String get qiblaHoldUpright => 'Держите телефон вертикально';

  @override
  String get qiblaCameraFailed => 'Не удалось открыть камеру';

  @override
  String get qiblaSunTitle => 'Проверка по солнцу';

  @override
  String qiblaSunRight(int sun, int angle) {
    return 'Солнце сейчас на $sun°. Встаньте лицом к солнцу и повернитесь на $angle° вправо — это Кибла.';
  }

  @override
  String qiblaSunLeft(int sun, int angle) {
    return 'Солнце сейчас на $sun°. Встаньте лицом к солнцу и повернитесь на $angle° влево — это Кибла.';
  }

  @override
  String qiblaSunAhead(int sun) {
    return 'Солнце сейчас на $sun° — прямо в сторону Киблы.';
  }

  @override
  String get qiblaSunDown =>
      'Солнце за горизонтом. Днём Киблу можно проверить по солнцу — на него не влияют магниты.';

  @override
  String qiblaSunOverKaaba(String when) {
    return 'Солнце будет прямо над Каабой: $when. В эту минуту тени указывают в сторону, противоположную Кибле.';
  }

  @override
  String get qiblaPhaseMove => 'Движение';

  @override
  String get qiblaPhaseHold => 'Стабильность';

  @override
  String get qiblaCalibrateTitle => 'Откалибруйте компас';

  @override
  String get qiblaCalibrateMove =>
      'Вращайте телефон в форме ∞, поворачивая запястье, — не просто двигайте.';

  @override
  String get qiblaCalibrateHold => 'Держите пузырёк в центре и не двигайтесь.';

  @override
  String qiblaMovements(int count, int total) {
    return '$count/$total движений';
  }

  @override
  String get qiblaCalMoving => 'Двигайте телефон в форме ∞...';

  @override
  String get qiblaCalGood => 'Хорошо! Продолжайте...';

  @override
  String get qiblaCalHoldStill =>
      'Теперь держите телефон ровно и неподвижно...';

  @override
  String get qiblaCalChecking => 'Проверка стабильности...';

  @override
  String get qiblaCalDone => '✓ Калибровка завершена!';

  @override
  String get qiblaCalibrateShort => 'Калибровать';

  @override
  String get qiblaSkip => 'Пропустить';

  @override
  String get qiblaUndo => 'Отменить';

  @override
  String get qiblaSunMarker => 'Солнце';

  @override
  String get qiblaSunTapHint =>
      'Солнце не в кружке? Нажмите на настоящее солнце';

  @override
  String get qiblaSunNotThere =>
      'Нажмите на само солнце: оно на пунктирной линии';

  @override
  String qiblaSunCorrected(String degrees) {
    return 'Исправлено по солнцу: $degrees°';
  }

  @override
  String get qiblaSunCheckCamera => 'Проверить камерой';

  @override
  String get parcelTitle => 'Отправка посылок';

  @override
  String get parcelTagline => 'Найдите курьера и передайте посылку';

  @override
  String get parcelFrom => 'Откуда';

  @override
  String get parcelTo => 'Куда';

  @override
  String get parcelSwap => 'Поменять направление';

  @override
  String get parcelUzbekistan => 'Узбекистан';

  @override
  String get parcelKorea => 'Корея';

  @override
  String get parcelUzbToKor => 'Из Узбекистана в Корею';

  @override
  String get parcelKorToUzb => 'Из Кореи в Узбекистан';

  @override
  String get parcelByDate => 'По дате';

  @override
  String get parcelByCity => 'По городу';

  @override
  String parcelPostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count объявления',
      many: '$count объявлений',
      few: '$count объявления',
      one: '$count объявление',
    );
    return '$_temp0';
  }

  @override
  String get parcelNoDates => 'В этом направлении пока нет объявлений';

  @override
  String get parcelNoPosts => 'Объявления не найдены';

  @override
  String get parcelNoCities => 'Города не найдены';

  @override
  String parcelSeeOther(String route) {
    return 'Другое направление: $route';
  }

  @override
  String get parcelError =>
      'Не удалось загрузить. Проверьте интернет и попробуйте ещё раз.';

  @override
  String get parcelHowTitle => 'Как это работает?';

  @override
  String get parcelHow1 => 'Выберите направление и способ поиска';

  @override
  String get parcelHow2 => 'Прочитайте объявление и свяжитесь с курьером';

  @override
  String get parcelHow3 => 'Передайте посылку безопасно!';

  @override
  String get parcelWriteTelegram => 'Написать в Telegram';

  @override
  String get parcelCall => 'Позвонить';

  @override
  String get parcelContactInText => 'Контакт курьера указан в сообщении';

  @override
  String get parcelShowMore => 'Ещё';

  @override
  String get parcelShowLess => 'Свернуть';

  @override
  String get parcelSearchCity => 'Поиск города';

  @override
  String get parcelNoticeTitle => 'Будьте осторожны';

  @override
  String get parcelNotice =>
      'Эти объявления взяты из Telegram-групп. Мы не связаны с курьерами — мы только показываем их объявления. Среди них могут быть мошенники. Мы не несём ответственности за любой ущерб.';

  @override
  String get parcelNoticeShort =>
      'Объявления из Telegram-групп. Мы не связаны с курьерами.';

  @override
  String get parcelNoticeOk => 'Понятно';

  @override
  String get parcelWaking => 'Сервер запускается, подождите немного…';

  @override
  String get parcelOffline =>
      'Нет связи. Показаны последние загруженные объявления.';

  @override
  String get parcelSearch => 'Поиск';

  @override
  String get parcelSearchPosts => 'Поиск по объявлениям';

  @override
  String parcelSearching(int done, int total) {
    return 'Ищем… $done/$total дн.';
  }

  @override
  String get parcelNothingFound => 'Ничего не найдено';

  @override
  String get parcelSavedTitle => 'Сохранённые объявления';

  @override
  String get parcelSave => 'Сохранить';

  @override
  String get parcelUnsave => 'Убрать из сохранённых';

  @override
  String get parcelSavedEmpty =>
      'Сохранённых объявлений пока нет. Нажмите на значок в объявлении, чтобы сохранить его.';

  @override
  String get parcelRemoved => 'Удалено';

  @override
  String get parcelUndo => 'Отменить';

  @override
  String get parcelShare => 'Поделиться';

  @override
  String get parcelEnd => 'Больше объявлений нет';

  @override
  String parcelDraft(String route, String date) {
    return 'Здравствуйте! Пишу по поводу посылки на ваш рейс $date ($route).';
  }

  @override
  String parcelDraftNoDate(String route) {
    return 'Здравствуйте! Пишу по поводу посылки на ваш рейс ($route).';
  }

  @override
  String get linksTitle => 'Полезные ссылки';

  @override
  String linksSubtitle(int count) {
    return 'Telegram-группы и каналы: $count';
  }

  @override
  String get linksSearch => 'Группа, город или тема';

  @override
  String get linksJobs => 'Работа';

  @override
  String get linksLife => 'Жизнь в Корее';

  @override
  String get linksGroups => 'Группы';

  @override
  String get linksFavorites => 'Избранное';

  @override
  String get linksNearest => 'Рядом';

  @override
  String get linksByRegion => 'Регионы';

  @override
  String linksYourPlace(String city) {
    return 'Вы здесь: $city';
  }

  @override
  String get linksLocate =>
      'Определите местоположение — ближайшие группы будут первыми';

  @override
  String get linksLocateButton => 'Определить';

  @override
  String get linksNationwide => 'Вся Корея';

  @override
  String get linksNearby => 'Поблизости';

  @override
  String get linksFarther => 'Другие города';

  @override
  String get linksRegionCapital => 'Сеул и Кёнгидо';

  @override
  String get linksRegionChungcheong => 'Чхунчхон';

  @override
  String get linksRegionJeolla => 'Чолла';

  @override
  String get linksRegionGyeongsang => 'Кёнсан';

  @override
  String get linksOther => 'Другие';

  @override
  String get linksTopicOfficial => 'Официальные';

  @override
  String get linksTopicNews => 'Новости и информация';

  @override
  String get linksTopicLegal => 'Право и визы';

  @override
  String get linksTopicInsurance => 'Страхование';

  @override
  String get linksTopicWork => 'Работа и карьера';

  @override
  String get linksTopicEveryday => 'Повседневная жизнь';

  @override
  String get linksForEveryone => 'Общая';

  @override
  String get linksForWomen => 'Для женщин';

  @override
  String get linksOurs => 'Наша группа: для предложений и вопросов';

  @override
  String get linksSuggestTitle => 'Вашей группы нет в списке?';

  @override
  String get linksSuggestBody => 'Напишите в группу Muslim Vegukin — добавим.';

  @override
  String get linksOpen => 'Открыть в Telegram';

  @override
  String get linksCopy => 'Скопировать ссылку';

  @override
  String get linksCopied => 'Ссылка скопирована';

  @override
  String get linksShare => 'Поделиться';

  @override
  String get linksFavorite => 'В избранное';

  @override
  String get linksUnfavorite => 'Убрать из избранного';

  @override
  String get linksNothing => 'Ничего не найдено';

  @override
  String linksResults(int count) {
    return 'Найдено: $count';
  }

  @override
  String get donationTitle => 'Пожертвование';

  @override
  String get donationHeroTitle => 'Поддержите работу проекта';

  @override
  String get donationHeroSubtitle => 'С вашей помощью проект будет развиваться';

  @override
  String get donationMessage =>
      'Если этот бот оказался вам полезен и вы хотите внести свой вклад в его работу и развитие, вы можете отправить любую сумму на указанный ниже счёт.';

  @override
  String get donationName => 'Имя';

  @override
  String get donationAccount => 'Номер счёта';

  @override
  String get donationCopied => 'Скопировано!';

  @override
  String get donationUsageTitle => 'Собранные средства будут использованы для';

  @override
  String get donationUsage1 => 'Расходы на сервер и хостинг';

  @override
  String get donationUsage2 =>
      'Техническое обслуживание и регулярные обновления';

  @override
  String get donationUsage3 => 'Работа разработчиков и развитие проекта';

  @override
  String get donationThanksText => 'Любой ваш вклад очень важен для нас!';

  @override
  String get donationThanks => 'Спасибо!';

  @override
  String get communityTitle => 'Сообщество';

  @override
  String get communityHeroTitle => 'Официальная Telegram группа';

  @override
  String get communityHeroSubtitle => 'Сообщество пользователей бота';

  @override
  String get communityJoinNow => 'Присоединиться сейчас';

  @override
  String get communityPurposeTitle => 'Цель группы';

  @override
  String get communityPurposeText =>
      'Эта группа является официальной площадкой для обсуждения пользователями Muslim Vegukin Bot. Здесь вы можете обсудить все вопросы, связанные с ботом.';

  @override
  String get communityAllowedTitle => 'Темы для обсуждения в группе';

  @override
  String get communityTopicPlaceTitle => 'Сообщения о новых адресах';

  @override
  String get communityTopicPlaceBody =>
      'Если нужно добавить новую мечеть, ресторан или магазин';

  @override
  String get communityTopicIdeaTitle => 'Предложения и идеи';

  @override
  String get communityTopicIdeaBody => 'Ваши мысли по улучшению бота';

  @override
  String get communityTopicBugTitle => 'Сообщения об ошибках';

  @override
  String get communityTopicBugBody => 'Если вы нашли проблему в боте';

  @override
  String get communityTopicNewsTitle => 'Новости бота';

  @override
  String get communityTopicNewsBody =>
      'Объявления о новых функциях и изменениях';

  @override
  String get communityTopicBetaTitle => 'Обсуждение бета-версий';

  @override
  String get communityTopicBetaBody =>
      'Тестирование новых функций перед публичным релизом';

  @override
  String get communityTopicQuestionTitle => 'Вопросы о боте';

  @override
  String get communityTopicQuestionBody => 'Как использовать, о функциях';

  @override
  String get communityTopicPeopleTitle => 'Общение с сообществом';

  @override
  String get communityTopicPeopleBody =>
      'Обмен опытом с другими пользователями';

  @override
  String get communityRulesTitle => 'Правила группы';

  @override
  String get communityRulesWarning => 'Следующие типы сообщений будут удалены';

  @override
  String get communityBanned1Title => 'Реклама и торговые объявления';

  @override
  String get communityBanned1Body => 'Любые объявления о продаже или покупке';

  @override
  String get communityBanned2Title => 'Реклама курсов';

  @override
  String get communityBanned2Body => 'Языковые курсы, учебные центры и прочее';

  @override
  String get communityBanned3Title => 'Вопросы не о боте';

  @override
  String get communityBanned3Body =>
      'Для общих вопросов используйте другие группы';

  @override
  String get communityBanned4Title => 'Спам и повторяющиеся сообщения';

  @override
  String get communityBanned4Body =>
      'Многократная отправка одинаковых сообщений';

  @override
  String get communityBanned5Title => 'Оффтопик дискуссии';

  @override
  String get communityBanned5Body => 'Разговоры не связанные с ботом';

  @override
  String get communityPenaltyTitle => 'Предупреждение';

  @override
  String get communityPenaltyText =>
      'Сообщения, нарушающие правила, будут удалены. При повторном нарушении пользователь будет ограничен в правах на отправку сообщений.';

  @override
  String get communityCta =>
      'Приглашаем вас присоединиться к группе, соблюдая правила!';

  @override
  String get donationTransfer => 'Перевод';

  @override
  String get donationBank => 'Банк';

  @override
  String get donationCopyAccount => 'Скопировать номер счёта';

  @override
  String get donationCopyName => 'Скопировать имя';

  @override
  String get donationOpenApp => 'Перевести в приложении банка';

  @override
  String get donationOpenAppHint =>
      'Номер счёта скопируется — вставьте его в приложении';

  @override
  String get donationPasteHint =>
      'Номер счёта скопирован — вставьте его в приложении';

  @override
  String get donationShare => 'Поделиться реквизитами';

  @override
  String get donationAsk => 'Вопросы и предложения — в нашей группе';

  @override
  String get communityCopyLink => 'Скопировать ссылку';

  @override
  String get communityLinkCopied => 'Ссылка скопирована';

  @override
  String get communityShare => 'Поделиться';

  @override
  String get communityMore => 'Ещё в группе';

  @override
  String get communityTemplateHint =>
      'Шаблон скопируется. Вставьте его в группе и заполните.';

  @override
  String get communityTemplateGo => 'Скопировать и открыть группу';

  @override
  String get communityTemplateCopied =>
      'Шаблон скопирован — вставьте его в группе';

  @override
  String get communityTemplatePlace =>
      '📍 Новое место\nНазвание: \nТип: мечеть / ресторан / магазин\nАдрес: \nСсылка на карте: \nДополнительно: ';

  @override
  String communityTemplateBug(String phone, String version) {
    return '🐛 Ошибка\nВ каком разделе: \nЧто случилось: \nЧто должно было быть: \n\nТелефон: $phone\nПриложение: $version';
  }

  @override
  String get barcodeTitle => 'Проверка состава';

  @override
  String get barcodeHint => 'Наведите рамку на штрих-код';

  @override
  String get barcodeChecking => 'Проверка…';

  @override
  String get barcodeTypeCode => 'Ввести код';

  @override
  String get barcodeTorch => 'Фонарик';

  @override
  String get barcodeSwitchCamera => 'Сменить камеру';

  @override
  String get barcodeBackToCamera => 'Сканировать';

  @override
  String get barcodeCameraOffTitle => 'Нет доступа к камере';

  @override
  String get barcodeCameraOffBody =>
      'Разрешите доступ к камере, чтобы сканировать, или введите код вручную.';

  @override
  String get barcodeOpenSettings => 'Открыть настройки';

  @override
  String get barcodeCameraError => 'Не удалось подключиться к камере.';

  @override
  String get barcodeRetry => 'Повторить';

  @override
  String get barcodeVerdictJoiz => 'Допустимо';

  @override
  String get barcodeVerdictShubhali => 'Сомнительно';

  @override
  String get barcodeVerdictNojoiz => 'Запрещено';

  @override
  String get barcodeVerdictJoizDesc => 'Запрещённые ингредиенты не обнаружены';

  @override
  String get barcodeVerdictShubhaliDesc =>
      'Запрещённых веществ нет, но продукт произведён на том же заводе, или же некоторые ингредиенты МОГУТ быть животного происхождения.';

  @override
  String get barcodeVerdictNojoizDesc => 'Обнаружены запрещённые ингредиенты';

  @override
  String get barcodePork => 'Свинина';

  @override
  String get barcodeAlcohol => 'Алкоголь';

  @override
  String get barcodeMeat => 'Другое мясо';

  @override
  String get barcodeSeafood => 'Морепродукты';

  @override
  String get barcodeAbsent => 'нет';

  @override
  String get barcodePresent => 'есть';

  @override
  String get barcodeAmbiguous =>
      'Содержит 트랜스지방, 쇼트닝, 향료 или 글리세린 — может быть растительного или животного происхождения (жир).';

  @override
  String get barcodeFactoryWarn =>
      'Продукт произведён на оборудовании, где производятся запрещённые продукты.';

  @override
  String get barcodeFactoryOk =>
      'На заводе/оборудовании не производятся запрещённые продукты.';

  @override
  String get barcodeIngredients => 'Состав';

  @override
  String get barcodeDoubtfulLink => 'Можно ли есть сомнительные продукты?';

  @override
  String get barcodeFoundIn => 'Найдено:';

  @override
  String get barcodeGeneralDb => 'Общая база данных';

  @override
  String get barcodeStoreUnknown => 'Магазин не указан';

  @override
  String get barcodeAlsoAt => 'Также есть в этих магазинах:';

  @override
  String get barcodeCopyCode => 'Скопировать код';

  @override
  String get barcodeCopied => 'Скопировано';

  @override
  String get barcodeScanNext => 'Сканировать следующий';

  @override
  String get barcodeNotFound => 'Продукт не найден';

  @override
  String get barcodeNotFoundDesc =>
      'Этот продукт пока отсутствует в базе. Возможно, он будет добавлен позже.';

  @override
  String get barcodeOfflineTitle => 'Нет подключения';

  @override
  String get barcodeOfflineBody =>
      'Для проверки нужен интернет. Проверьте подключение и попробуйте снова.';

  @override
  String get barcodeSaved => 'Сохранённый результат · нет интернета';

  @override
  String get barcodeRecent => 'Недавние проверки';

  @override
  String get barcodeClear => 'Очистить';

  @override
  String get barcodeTypeTitle => 'Введите штрих-код';

  @override
  String get barcodeTypeHint => 'Цифры под штрихами: от 8 до 14.';

  @override
  String get barcodeSearch => 'Найти';

  @override
  String get barcodeErrEmpty => 'Введите штрих-код.';

  @override
  String get barcodeErrNonDigit => 'Используйте только цифры.';

  @override
  String get barcodeErrLength => 'Штрих-код должен содержать от 8 до 14 цифр.';

  @override
  String get barcodeErrChecksum => 'Штрих-код некорректен. Проверьте цифры.';

  @override
  String get barcodeStores => 'Магазины';

  @override
  String barcodeProducts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count товаров',
      few: '$count товара',
      one: '$count товар',
    );
    return '$_temp0';
  }

  @override
  String get barcodeSoon => 'Скоро';

  @override
  String get barcodeStoresError => 'Не удалось загрузить магазины';

  @override
  String get barcodeAll => 'Все';

  @override
  String get barcodeStoreEmpty => 'Товары не найдены';

  @override
  String get barcodeStoreEmptyDesc =>
      'Попробуйте другую категорию или вердикт.';

  @override
  String get barcodeProductsError => 'Не удалось загрузить товары';

  @override
  String get barcodeCheckConnection =>
      'Проверьте подключение и попробуйте снова.';

  @override
  String get barcodeContribTitle => 'Помогите нам собрать халяль-базу';

  @override
  String get barcodeContribBody =>
      'Для тех, кто умеет читать состав продуктов: вместе собираем халяль-базу для GS25, CU, 7-Eleven, Emart24, No Brand и Daiso. Каждая запись помогает тысячам людей.';

  @override
  String get barcodeContribCta => 'Написать админу';

  @override
  String get barcodeDisclaimer =>
      'Эта информация предоставлена только на основе состава продукта и *может содержать ошибки*. Мы не выносим официальных религиозных решений (фатва). Если нашли ошибку, сообщите в нашу Telegram-группу.';

  @override
  String get barcodeCatDrinks => 'Напитки';

  @override
  String get barcodeCatSnacks => 'Снеки';

  @override
  String get barcodeCatSweets => 'Сладости';

  @override
  String get barcodeCatIceCream => 'Мороженое';

  @override
  String get barcodeCatBaked => 'Выпечка';

  @override
  String get barcodeCatNoodles => 'Лапша / Рамен';

  @override
  String get barcodeCatLunchbox => 'Печенье / Выпечка';

  @override
  String get barcodeCatDairy => 'Молочные';

  @override
  String get barcodeCatCanned => 'Консервы';

  @override
  String get barcodeCatFrozen => 'Замороженные';

  @override
  String get barcodeCatSauces => 'Приправы / Соусы';

  @override
  String get barcodeCatFruits => 'Фрукты / Овощи';

  @override
  String get barcodeCatDried => 'Сушёные';

  @override
  String get qnaLabel => 'Центр вопросов и ответов';

  @override
  String get qnaVerseRef => 'Сура ан-Нахль, аят 43';

  @override
  String get qnaSource =>
      'Ответы шейха Мухаммада Содика Мухаммада Юсуфа и других учёных';

  @override
  String get qnaCount => '100 000+ вопросов';

  @override
  String get qnaAi => 'Поиск с ИИ';

  @override
  String get qnaSearchHint => 'Напишите вопрос на узбекском…';

  @override
  String get qnaUzbekNote =>
      'Вопросы и ответы — на узбекском языке (латиница или кириллица).';

  @override
  String get qnaDaily => 'Подборка дня';

  @override
  String get qnaDailySub => 'Каждый день — новые вопросы';

  @override
  String get qnaNewSet => 'Новые вопросы';

  @override
  String get qnaLoadError => 'Не удалось загрузить вопросы';

  @override
  String get qnaCheckConnection => 'Проверьте подключение и попробуйте снова.';

  @override
  String get qnaRetry => 'Повторить';

  @override
  String get qnaSaved => 'Сохранённые ответы';

  @override
  String get qnaSavedEmpty => 'Пока ничего не сохранено';

  @override
  String get qnaSavedHint =>
      'Сохраняйте ответы кнопкой-закладкой — их можно читать без интернета.';

  @override
  String get qnaSave => 'Сохранить';

  @override
  String get qnaUnsave => 'Убрать из сохранённых';

  @override
  String get qnaSavedNote => 'Сохранено';

  @override
  String get qnaRemovedNote => 'Убрано из сохранённых';

  @override
  String get qnaShare => 'Поделиться';

  @override
  String get qnaTextSize => 'Размер текста';

  @override
  String get qnaQuestion => 'Вопрос';

  @override
  String get qnaAnswer => 'Ответ';

  @override
  String get qnaOpenSource => 'Источник';

  @override
  String get qnaCopy => 'Копировать';

  @override
  String get qnaCopied => 'Вопрос и ответ скопированы';

  @override
  String get qnaRelated => 'Похожие вопросы';

  @override
  String get qnaAnswerError => 'Не удалось загрузить ответ';

  @override
  String get qnaOther => 'Другое';

  @override
  String get qnaSearchTitle => 'Поиск вопроса';

  @override
  String get qnaSearchButton => 'Найти';

  @override
  String get qnaMinLetters => 'Напишите хотя бы 3 буквы';

  @override
  String get qnaHowTitle => 'Как это работает?';

  @override
  String get qnaHowBody =>
      'Узбекская языковая модель понимает смысл вопроса и находит самые похожие среди тысяч вопросов и ответов. Слова не обязаны совпадать: чем полнее и грамотнее вопрос, тем точнее результат. Пишите на узбекском — латиницей или кириллицей.';

  @override
  String get qnaRecent => 'Недавние запросы';

  @override
  String get qnaClear => 'Очистить';

  @override
  String get qnaRemove => 'Удалить';

  @override
  String get qnaExamples => 'Например';

  @override
  String qnaResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count результатов',
      few: '$count результата',
      one: '$count результат',
    );
    return '$_temp0';
  }

  @override
  String get qnaNoResults => 'Ничего не найдено';

  @override
  String get qnaNoResultsHint =>
      'Попробуйте сформулировать вопрос иначе и полнее.';

  @override
  String get qnaOfflineTitle => 'Нет подключения';

  @override
  String get qnaOfflineBody =>
      'Для поиска нужен интернет. Сохранённые ответы открываются и без него.';

  @override
  String get bizTitle => 'Бизнес-каталог';

  @override
  String get bizTagline => 'Узбекский бизнес в Корее — в одном месте';

  @override
  String get bizSearchTitle => 'Поиск';

  @override
  String get bizSearchHint => 'Найти бизнес или услугу';

  @override
  String bizCountAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count бизнесов',
      few: '$count бизнеса',
      one: '$count бизнес',
    );
    return '$_temp0';
  }

  @override
  String bizCountFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдено: $count',
    );
    return '$_temp0';
  }

  @override
  String get bizTileEmpty => 'Пока пусто';

  @override
  String get bizDirectoryEmpty => 'Каталог пока пуст';

  @override
  String get bizDirectoryEmptyBody =>
      'Здесь будут собраны узбекские бизнесы в Корее.';

  @override
  String get bizSaved => 'Сохранённые';

  @override
  String get bizCategories => 'Разделы';

  @override
  String get bizOrderNote => 'Выше — те, что больше всего нравятся клиентам';

  @override
  String get bizCategoryEmpty => 'В этом разделе пока нет бизнесов';

  @override
  String get bizCategoryEmptyBody =>
      'Новые бизнесы появятся здесь после добавления. Загляните и в другие разделы.';

  @override
  String get bizSeeAll => 'Все';

  @override
  String get bizNothingFound => 'Ничего не найдено';

  @override
  String bizNothingFoundBody(String query) {
    return 'По запросу «$query» ничего не найдено. Попробуйте написать иначе или поищите по разделам.';
  }

  @override
  String get bizLoadError => 'Не удалось загрузить';

  @override
  String get bizCheckConnection => 'Проверьте подключение и попробуйте снова.';

  @override
  String get bizRetry => 'Повторить';

  @override
  String get bizUzbekNote => 'Описания бизнесов — на узбекском языке.';

  @override
  String get bizSave => 'Сохранить';

  @override
  String get bizUnsave => 'Убрать из сохранённых';

  @override
  String get bizSavedNote => 'Сохранено — контакты откроются и без интернета';

  @override
  String get bizRemovedNote => 'Убрано из сохранённых';

  @override
  String get bizShare => 'Поделиться';

  @override
  String get bizShareFooter => 'Из бизнес-каталога Muslim Vegukin';

  @override
  String bizViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count просмотров',
      few: '$count просмотра',
      one: '$count просмотр',
    );
    return '$_temp0';
  }

  @override
  String bizLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Понравилось $count людям',
      one: 'Понравилось $count человеку',
    );
    return '$_temp0';
  }

  @override
  String get bizLoadFailed => 'Не удалось загрузить данные.';

  @override
  String get bizLinks => 'Другие ссылки';

  @override
  String get bizAbout => 'О бизнесе';

  @override
  String get bizNoInfo => 'Этот бизнес пока не заполнил описание.';

  @override
  String get bizNoContact => 'Контакты не указаны.';

  @override
  String get bizNoContactAsk => 'Спросить у админа';

  @override
  String get bizReport => 'Неверные данные? Сообщите админу';

  @override
  String get bizCopyAddress => 'Копировать';

  @override
  String get bizAddressCopied => 'Адрес скопирован';

  @override
  String get bizPhoneCopied => 'Номер скопирован';

  @override
  String get bizActCall => 'Позвонить';

  @override
  String get bizActTelegram => 'Написать';

  @override
  String get bizActChannel => 'Открыть';

  @override
  String get bizActKakao => 'Написать';

  @override
  String get bizActWebsite => 'Открыть сайт';

  @override
  String get bizActInstagram => 'Открыть профиль';

  @override
  String get bizActTiktok => 'Открыть профиль';

  @override
  String get bizActYoutube => 'Смотреть';

  @override
  String get bizActFacebook => 'Открыть страницу';

  @override
  String get bizActPlay => 'Скачать';

  @override
  String get bizActAppStore => 'Скачать';

  @override
  String get bizActOpen => 'Открыть';

  @override
  String get bizChannelPhone => 'Телефон';

  @override
  String get bizChannelGroup => 'Telegram-канал / группа';

  @override
  String get bizChannelWebsite => 'Сайт';

  @override
  String get bizPrivateGroup => 'Закрытая группа';

  @override
  String get bizMapNaver => 'Naver Карты';

  @override
  String get bizMapKakao => 'Kakao Карты';

  @override
  String get bizMapGoogle => 'Google Карты';

  @override
  String get bizOwnerTitle => 'Вы владелец бизнеса?';

  @override
  String get bizOwnerBody =>
      'Добавьте свой бизнес в каталог — клиенты найдут вас здесь.';

  @override
  String get bizOwnerBodyEmpty => 'Станьте первым в этом разделе.';

  @override
  String get bizOwnerEyebrow => 'Для владельцев бизнеса';

  @override
  String get bizOwnerSheetTitle => 'Как попасть в каталог';

  @override
  String get bizStep1Title => 'Заявка';

  @override
  String get bizStep1Body =>
      'Укажите логотип, название, раздел и контакты бизнеса.';

  @override
  String get bizStep2Title => 'Оплата';

  @override
  String bizStep2Body(String amount) {
    return 'Разовый платёж — $amount. Скриншот оплаты отправляется админу.';
  }

  @override
  String get bizStep3Title => 'В каталоге';

  @override
  String get bizStep3Body =>
      'После подтверждения оплаты бизнес появится в каталоге.';

  @override
  String get bizOwnerFine =>
      'Порядок в каталоге зависит от числа лайков: самый любимый бизнес стоит выше всех.';

  @override
  String get bizOwnerHow =>
      'Заявка подаётся через Telegram: напишите админу, он поможет добавить бизнес.';

  @override
  String get bizOwnerContact => 'Написать админу';

  @override
  String bizCurrency(String amount) {
    return '$amount вон';
  }

  @override
  String get accountTitle => 'Аккаунт';

  @override
  String get signInTitle => 'Войдите в аккаунт';

  @override
  String get signInWhy =>
      'Отслеживание мест и уведомления работают и без входа. Чтобы писать отзывы, исправлять данные и публиковать объявления, войдите — другие должны знать, кто пишет.';

  @override
  String get signInTelegramNote =>
      'Этот раздел работает через Telegram. Войдите с аккаунтом из бота Muslim Vegukin — ваши объявления из бота будут видны и здесь.';

  @override
  String get signInTelegram => 'Войти через Telegram';

  @override
  String get signInWhatsApp => 'Войти через WhatsApp';

  @override
  String get signInGoogle => 'Войти через Google';

  @override
  String signInWaitingTitle(String app) {
    return 'Нажмите «Да, войти» в $app';
  }

  @override
  String get signInWaitingBody =>
      'Мы подождём здесь. Подтвердите и вернитесь в приложение.';

  @override
  String signInOpenAgain(String app) {
    return 'Открыть $app снова';
  }

  @override
  String get signInCancel => 'Отмена';

  @override
  String get signInExpired => 'Время вышло или вход отменён. Попробуйте снова.';

  @override
  String get signInFailed =>
      'Не получилось. Проверьте интернет и попробуйте снова.';

  @override
  String get signInDone => 'Вы вошли';

  @override
  String signedInWith(String provider) {
    return 'Вход через $provider';
  }

  @override
  String get signOut => 'Выйти';

  @override
  String get accountDelete => 'Удалить аккаунт';

  @override
  String get accountDeleteTitle => 'Удалить аккаунт?';

  @override
  String get accountDeleteBody =>
      'Ваши отслеживания, районы и отзывы будут удалены навсегда. Это нельзя отменить.';

  @override
  String get accountDeleteTelegram => 'Включая сделанные в Telegram-боте.';

  @override
  String get accountDeleteConfirm => 'Удалить';

  @override
  String get accountDeleted => 'Аккаунт удалён';

  @override
  String get accountPushOn => 'Уведомления приходят на этот телефон';

  @override
  String get accountPushOff =>
      'Сообщения всё равно попадут во «Входящие», но телефон их не покажет.';

  @override
  String get pushOpen => 'Открыть';

  @override
  String get inboxTitle => 'Входящие';

  @override
  String inboxUnread(int count) {
    return 'Новых: $count';
  }

  @override
  String get inboxEmptyTitle => 'Пока ничего нет';

  @override
  String get inboxEmptyBody =>
      'Здесь сохраняются все уведомления для вас — даже пропущенные.';

  @override
  String get inboxFailed => 'Не удалось загрузить. Проверьте интернет.';

  @override
  String get inboxEarlier => 'Показать более ранние';

  @override
  String get inboxPushOff =>
      'Уведомления на этом телефоне выключены. Новые сообщения всё равно появятся здесь.';

  @override
  String get inboxMessage => 'Сообщение';

  @override
  String inboxOpenSection(String section) {
    return 'Открыть «$section»';
  }

  @override
  String inboxPhoto(int index, int total) {
    return 'Фото $index из $total';
  }

  @override
  String get hkLede =>
      'Смотрите свободные дни в своём офисе. Если всё занято, включите слежение — сообщим, как только появится место.';

  @override
  String get hkSearchHint => 'Поиск офиса';

  @override
  String get hkMyWatches => 'Мои слежения';

  @override
  String hkActiveWatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активных слежений',
      few: '$count активных слежения',
      one: '$count активное слежение',
    );
    return '$_temp0';
  }

  @override
  String get hkLastViewed => 'Недавно смотрели';

  @override
  String get hkStep1 => 'Найдите свой офис';

  @override
  String get hkStep2 => 'Посмотрите свободные дни';

  @override
  String get hkStep3 => 'Запишитесь на HiKorea';

  @override
  String get hkAddressCardTitle => 'Не знаете свой офис?';

  @override
  String get hkAddressCardBody => 'Найдём его по вашему адресу';

  @override
  String get hkOffices => 'Иммиграционные офисы';

  @override
  String hkCounters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count окон',
      few: '$count окна',
      one: '$count окно',
    );
    return '$_temp0';
  }

  @override
  String get hkNoMatch =>
      'Офис не найден. Попробуйте другое слово или поиск по адресу.';

  @override
  String get hkLoadFailed => 'Не удалось загрузить. Проверьте интернет.';

  @override
  String get hkAddressTitle => 'Поиск по адресу';

  @override
  String get hkAddressLede =>
      'Каждый офис обслуживает свои районы. Выберите провинцию и введите домашний адрес по-корейски.';

  @override
  String get hkProvince => '1. Провинция';

  @override
  String get hkAddress => '2. Домашний адрес (по-корейски)';

  @override
  String get hkAddressHint =>
      'В адресе должен быть город или район (-시, -구, -군), например 안산시 단원구.';

  @override
  String get hkFindOffice => 'Найти офис';

  @override
  String get hkNeedProvince => 'Сначала выберите провинцию';

  @override
  String get hkNeedAddress => 'Введите адрес';

  @override
  String get hkYourOffice => 'Ваш офис:';

  @override
  String get hkPickOne => 'Выберите подходящий:';

  @override
  String get hkAddressNoMatch =>
      'Для этого адреса офис не найден. Введите адрес полностью.';

  @override
  String get hkCountersTitle => 'Какое окно вам нужно?';

  @override
  String get hkCountersLede =>
      'Окна выполняют одну работу, но могут отличаться местом, этажом или временем приёма. Прочитайте описание перед выбором.';

  @override
  String get hkFromAfternoon => 'Приём с 09:36';

  @override
  String get hkMore => 'Подробнее';

  @override
  String hkCounterN(int n) {
    return 'Окно $n';
  }

  @override
  String get hkCalendarHint =>
      'Нажмите на день — проверим места на HiKorea прямо сейчас.';

  @override
  String get hkCheckedNow => 'Проверено только что';

  @override
  String hkCheckedMinutes(int n) {
    return 'Проверено $n мин назад';
  }

  @override
  String hkCheckedHours(int n) {
    return 'Проверено $n ч назад';
  }

  @override
  String hkCheckedDays(int n) {
    return 'Проверено $n дн. назад';
  }

  @override
  String get hkEarliest => 'Ближайший свободный день';

  @override
  String get hkAllFull => 'Сейчас все дни заняты';

  @override
  String get hkAllFullBody =>
      'Поставьте слежение — сообщим, как только освободится место.';

  @override
  String get hkLegendOpen => 'Свободно';

  @override
  String get hkLegendSome => 'Есть брони';

  @override
  String get hkLegendFull => 'Занято';

  @override
  String get hkLegendClosed => 'Закрыто';

  @override
  String get hkNoDates =>
      'Сейчас ни одного дня не видно. Поставьте слежение — сообщим, как только появится место.';

  @override
  String get hkNotifyMe => 'Сообщить, когда появится место';

  @override
  String get hkChecking => 'Проверяем HiKorea…';

  @override
  String get hkDayClosed => 'В этот день офис закрыт';

  @override
  String get hkFullyBooked => 'Всё занято';

  @override
  String get hkLastOne => 'Осталось одно место';

  @override
  String hkSlotsFree(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n свободных мест',
      few: '$n свободных места',
      one: '$n свободное место',
    );
    return '$_temp0';
  }

  @override
  String get hkBookCue => 'Записаться можно на сайте HiKorea.';

  @override
  String get hkFullCue =>
      'Мест нет. Поставьте слежение — сообщим, когда появится место.';

  @override
  String hkBookedOf(int taken, int capacity) {
    return 'Занято $taken из $capacity';
  }

  @override
  String get hkMorning => 'Утро';

  @override
  String get hkAfternoon => 'После обеда';

  @override
  String hkLeft(int n) {
    return 'ост. $n';
  }

  @override
  String get hkSlotFull => 'Занято';

  @override
  String get hkBook => 'Записаться на HiKorea';

  @override
  String get hkFetchFailed =>
      'Не удалось связаться с HiKorea. Попробуйте чуть позже.';

  @override
  String get hkSessionExpired =>
      'Связь с HiKorea обновляется. Попробуйте чуть позже.';

  @override
  String get hkWatchTitle => 'За какими днями следить?';

  @override
  String get hkWatchLede =>
      'Как только в эти дни появится место, пришлём уведомление.';

  @override
  String hkNextDays(int n) {
    return '$n дней';
  }

  @override
  String get hkPickDates => 'Выбрать даты';

  @override
  String hkDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n дней',
      few: '$n дня',
      one: '$n день',
    );
    return '$_temp0';
  }

  @override
  String get hkStartWatching => 'Начать слежение';

  @override
  String get hkTooLong => 'Можно следить не больше 90 дней';

  @override
  String get hkDuplicate => 'Эти дни уже отслеживаются';

  @override
  String get hkMaxReached => 'Максимум 10 слежений. Сначала остановите одно.';

  @override
  String get hkCreateFailed =>
      'Не удалось поставить слежение. Попробуйте ещё раз.';

  @override
  String get hkDoneTitle => 'Слежение поставлено';

  @override
  String get hkDoneBody =>
      'Проверяем каждые 5 минут. Как только появится место, придёт уведомление.';

  @override
  String get hkPushOff =>
      'Уведомления на этом телефоне выключены — сообщения будут только во «Входящих».';

  @override
  String get hkSendTest => 'Тестовое уведомление';

  @override
  String get hkTestSent => 'Отправлено';

  @override
  String get hkTestFailed =>
      'Не удалось отправить. Проверьте, что уведомления включены.';

  @override
  String get hkSeeWatches => 'Мои слежения';

  @override
  String get hkWatchesEmpty => 'Пока нет слежений';

  @override
  String get hkWatchesEmptyBody =>
      'Выберите офис, посмотрите календарь и поставьте слежение.';

  @override
  String get hkStatusActive => 'Активно';

  @override
  String get hkStatusExpired => 'Завершено';

  @override
  String get hkStatusCancelled => 'Остановлено';

  @override
  String get hkStatusUndeliverable => 'Не доставлено';

  @override
  String get hkStop => 'Остановить';

  @override
  String get hkStopTitle => 'Остановить слежение?';

  @override
  String get hkStopped => 'Слежение остановлено';

  @override
  String get hkStopFailed => 'Не удалось остановить. Попробуйте ещё раз.';

  @override
  String get hkCalendar => 'Календарь';

  @override
  String get hkPastWatches => 'Завершённые';

  @override
  String get hkPickOffice => 'Выбрать офис';

  @override
  String get hkStep1Body => 'По названию или по домашнему адресу';

  @override
  String get hkStep2Body =>
      'Следующие 3 месяца каждого окна, обновляются каждые 5 минут';

  @override
  String get hkStep3Body =>
      'Если всё занято — включите слежение, сообщим, когда появится место';

  @override
  String get hkHowTitle => 'Как это работает';

  @override
  String get hkStartTitle => 'Какой офис ваш?';

  @override
  String get hkStartBody =>
      'Это зависит от адреса: каждый офис обслуживает свои районы.';

  @override
  String get hkStartOr => 'или выберите в списке ниже';

  @override
  String get hkYourWatches => 'Ваши слежения';

  @override
  String hkSeeAll(int count) {
    return 'Все ($count)';
  }

  @override
  String hkWatchFree(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'В ваши даты $n свободных дней',
      few: 'В ваши даты $n свободных дня',
      one: 'В ваши даты $n свободный день',
    );
    return '$_temp0';
  }

  @override
  String get hkWatchFull => 'Всё занято — следим';

  @override
  String hkEarliestShort(String day) {
    return 'Ближайший свободный: $day';
  }

  @override
  String get hkAllFullShort => 'Сейчас все дни заняты';

  @override
  String get hkOfficeMain => 'Иммиграционный офис';

  @override
  String get hkOfficeBranch => 'Филиал';

  @override
  String hkOfficeBranchOf(String office) {
    return 'Филиал · $office';
  }

  @override
  String get hkAllOffices => 'Все офисы';

  @override
  String hkFreeDays(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n свободных дней до $date',
      few: '$n свободных дня до $date',
      one: '$n свободный день до $date',
    );
    return '$_temp0';
  }

  @override
  String hkBookedUntil(String date) {
    return 'Занято до $date. Включите слежение — сообщим, как только появится место.';
  }

  @override
  String get hkHowBooking =>
      'Запись — на сайте HiKorea, со своей учётной записью HiKorea. Здесь вы видите свободные дни.';

  @override
  String get hkLegendLater => 'Запись ещё не открыта';

  @override
  String get hkWatchShort => 'Следить';

  @override
  String get hkStale =>
      'Это окно давно не удавалось проверить — дни могут быть устаревшими.';

  @override
  String get accountGuest => 'Гость';

  @override
  String get accountGuestBody =>
      'Войдите — ваше имя будет видно в отзывах, а слежения перейдут и на новый телефон.';

  @override
  String get accountSignIn => 'Войти';

  @override
  String get accountNoPhoto => 'WhatsApp не передаёт фото профиля приложениям.';

  @override
  String get accountNotifications => 'Уведомления';

  @override
  String get accountPushOffTitle => 'Уведомления выключены';

  @override
  String get accountTurnOn => 'Включить';

  @override
  String get accountWhatComes =>
      'Свободные места на HiKorea, новости мест и районов, за которыми вы следите, и объявления.';

  @override
  String get accountTelegramToo =>
      'Они приходят и от бота Muslim Vegukin в Telegram.';

  @override
  String get accountTestPush => 'Тестовое уведомление';

  @override
  String get accountTestSent => 'Отправлено — посмотрите на телефоне';

  @override
  String get accountTestFailed =>
      'Не удалось отправить. Попробуйте чуть позже.';

  @override
  String get accountActivity => 'Ваша активность';

  @override
  String get accountInboxNone => 'Сообщений пока нет';

  @override
  String accountInboxAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщений',
      few: '$count сообщения',
      one: '$count сообщение',
    );
    return '$_temp0';
  }

  @override
  String get accountApp => 'Приложение';

  @override
  String get accountLanguage => 'Язык';

  @override
  String get accountDarkMode => 'Тёмная тема';

  @override
  String get accountManage => 'Управление аккаунтом';

  @override
  String accountActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активных',
      few: '$count активных',
      one: '$count активное',
    );
    return '$_temp0';
  }

  @override
  String get hkDormantTitle => 'HiKorea не показывает дней в этом окне';

  @override
  String hkDormantBody(String date) {
    return 'С $date HiKorea не показывает здесь ни одного дня — ни свободного, ни занятого. Так бывает, когда HiKorea заменяет окно новым. Посмотрите другие окна этого офиса или проверьте на сайте HiKorea.';
  }

  @override
  String get hkDormantBodyNoDate =>
      'HiKorea не показывает здесь ни одного дня — ни свободного, ни занятого. Так бывает, когда HiKorea заменяет окно новым. Посмотрите другие окна этого офиса или проверьте на сайте HiKorea.';

  @override
  String get hkOtherCounters => 'Другие окна этого офиса';

  @override
  String get hkCheckOnHikorea => 'Проверить на HiKorea';

  @override
  String get hkNoDaysShort => 'На HiKorea нет дней';

  @override
  String get hkLeafLegend => 'Дата — ближайший свободный день';

  @override
  String get hkLeafFull => 'Занято';

  @override
  String get hkWatchingHere => 'Здесь у вас есть наблюдение';

  @override
  String get plNearest => 'Ближайшая';

  @override
  String plMetres(String n) {
    return '$n м';
  }

  @override
  String plKm(String n) {
    return '$n км';
  }

  @override
  String get plNoReviews => 'Пока нет отзывов';

  @override
  String plReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count отзыва',
      many: '$count отзывов',
      few: '$count отзыва',
      one: '$count отзыв',
    );
    return '$_temp0';
  }

  @override
  String get plAddressNotFound =>
      'Адрес не найден. Попробуйте написать точнее, на корейском.';

  @override
  String get plNothingFound => 'Ничего не найдено';

  @override
  String get plLoadFailed => 'Не удалось загрузить места. Проверьте интернет.';

  @override
  String get plMissingTitle => 'Знаете место, которого нет в списке?';

  @override
  String get plMissingBody => 'Напишите в нашу группу — добавим.';

  @override
  String get plWatchingBadge => 'Вы следите';

  @override
  String plPhotoCount(String i, String n) {
    return '$i / $n';
  }

  @override
  String get plWatch => 'Следить';

  @override
  String plWatchers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Следят $count',
      many: 'Следят $count',
      few: 'Следят $count',
      one: 'Следит $count',
    );
    return '$_temp0';
  }

  @override
  String get plWatchOn => 'Новости будут приходить на этот телефон';

  @override
  String get plWatchOff => 'Вы больше не следите';

  @override
  String get plWatchNoPush => 'Уведомления выключены — новости не придут';

  @override
  String get plWatchPushOn => 'Включить';

  @override
  String get plAddress => 'Адрес';

  @override
  String get plNoAddress => 'Адрес не указан';

  @override
  String get plPhone => 'Телефон';

  @override
  String get plMenu => 'Меню';

  @override
  String get plMenuOpen => 'Открыть меню';

  @override
  String get plAddressCopied => 'Адрес скопирован';

  @override
  String get plCopyAddress => 'Скопировать адрес';

  @override
  String get plMapAttribution => '© OpenStreetMap';

  @override
  String get plAbout => 'О заведении';

  @override
  String get plAboutEmpty => 'Часы работы и выходные пока не указаны.';

  @override
  String get plAboutAdd => 'Добавить информацию';

  @override
  String get plSuggestChange => 'Предложить изменение';

  @override
  String get plSocial => 'Соцсети';

  @override
  String get plSocialEmpty => 'Знаете соцсети этого места?';

  @override
  String get plSocialAdd => 'Добавить';

  @override
  String get plInviteLink => 'Ссылка';

  @override
  String plPendingField(String what) {
    return '$what: предложение на проверке';
  }

  @override
  String get plNoteLabel => 'Информация';

  @override
  String get plReviews => 'Отзывы';

  @override
  String get plReviewsFirst => 'Оставьте первый отзыв — это поможет другим.';

  @override
  String get plWriteReview => 'Оставить отзыв';

  @override
  String get plEditReview => 'Изменить отзыв';

  @override
  String get plYourReview => 'Ваш отзыв';

  @override
  String plAllReviews(int count) {
    return 'Показать все ($count)';
  }

  @override
  String get plNoText => 'Только оценка';

  @override
  String get plCorrections =>
      'Название, адрес или телефон неверны? Напишите в нашу группу.';

  @override
  String get plLoadDetailFailed => 'Не удалось загрузить. Проверьте интернет.';

  @override
  String get plGone => 'Место не найдено — возможно, его убрали из списка.';

  @override
  String get plRateQuestion => 'Ваша оценка?';

  @override
  String get plStar1 => 'Очень плохо';

  @override
  String get plStar2 => 'Плохо';

  @override
  String get plStar3 => 'Нормально';

  @override
  String get plStar4 => 'Хорошо';

  @override
  String get plStar5 => 'Отлично';

  @override
  String get plReviewHintMosque =>
      'Например: время намаза, код на двери, как добраться.';

  @override
  String get plReviewHintRestaurant =>
      'Например: блюда, цены, обслуживание, часы работы.';

  @override
  String get plReviewHintShop => 'Например: что продают, цены, часы работы.';

  @override
  String get plReviewPlaceholder => 'Ваш отзыв (необязательно)';

  @override
  String get plReviewPublic => 'Отзыв увидят все, а ваше имя — нет.';

  @override
  String get plReviewSend => 'Опубликовать';

  @override
  String get plReviewSave => 'Сохранить';

  @override
  String get plReviewPick => 'Сначала выберите оценку';

  @override
  String get plReviewPublished => 'Спасибо! Отзыв опубликован.';

  @override
  String get plReviewUpdated => 'Отзыв обновлён.';

  @override
  String get plReviewDelete => 'Удалить отзыв';

  @override
  String get plReviewDeleteAsk => 'Удалить ваш отзыв?';

  @override
  String get plReviewDeleted => 'Отзыв удалён.';

  @override
  String get plDelete => 'Удалить';

  @override
  String get plCancel => 'Отмена';

  @override
  String get plSend => 'Отправить';

  @override
  String get plSuggestPick => 'Что хотите добавить?';

  @override
  String plSuggestAddLink(String platform) {
    return 'Добавить ссылку $platform';
  }

  @override
  String plSuggestEditLink(String platform) {
    return 'Изменить ссылку $platform';
  }

  @override
  String get plSuggestAddNote => 'Добавить информацию';

  @override
  String get plSuggestEditNote => 'Изменить информацию';

  @override
  String plSuggestCurrent(String value) {
    return 'Сейчас: $value';
  }

  @override
  String get plHintTelegram => '@username или ссылка t.me';

  @override
  String get plHintTiktok => '@username или ссылка tiktok.com';

  @override
  String get plHintInstagram => '@username или ссылка instagram.com';

  @override
  String get plHintNote => 'Часы работы, выходные или объявление.';

  @override
  String get plNotePlaceholder =>
      'Например:\nПн–Пт: 11:00 – 22:00\nСуббота: выходной';

  @override
  String get plModeration => 'Появится после проверки админом.';

  @override
  String get plSuggestSent => 'Спасибо! Ваше предложение на проверке.';

  @override
  String get plAnnounceMosque => 'Написать объявление';

  @override
  String get plAnnounceOwner => 'Отправить объявление';

  @override
  String get plAnnounceWhyMosque =>
      'Например, время праздничного намаза — придёт тем, кто следит.';

  @override
  String get plAnnounceWhyOwner => 'Отправьте новость тем, кто следит.';

  @override
  String plAnnouncePending(int count) {
    return 'На проверке: $count';
  }

  @override
  String get plAnnounceTitle => 'Объявление';

  @override
  String get plAnnouncePlaceholderOwner =>
      'Например: 25 декабря мы не работаем.';

  @override
  String get plAnnouncePlaceholderMosque =>
      'Например: праздничный намаз в 07:00, 08:00 и 09:00.';

  @override
  String plAnnounceReach(int count) {
    return 'После проверки админом его получат примерно $count чел.';
  }

  @override
  String get plAnnounceSend => 'На проверку';

  @override
  String get plAnnounceSent => 'Объявление отправлено на проверку';

  @override
  String get plTextEmpty => 'Сначала напишите текст.';

  @override
  String get plClaimPrompt => 'Вы владелец этого места?';

  @override
  String get plClaimWhy =>
      'Владелец может отправлять объявления тем, кто следит.';

  @override
  String get plClaimConfirm =>
      'Ваше имя и контакт получит администратор. Он свяжется с вами, чтобы проверить владение. Продолжить?';

  @override
  String get plClaimContinue => 'Продолжить';

  @override
  String get plClaimSent => 'Запрос отправлен. Администратор свяжется с вами.';

  @override
  String get plClaimPending => 'Ваш запрос на владение рассматривается.';

  @override
  String get plYouOwn => 'Вы владелец этого места';

  @override
  String get plErrNetwork => 'Нет подключения к интернету. Попробуйте ещё раз.';

  @override
  String get plErrGeneric => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get plErrSignIn => 'Для этого войдите в аккаунт.';

  @override
  String get plErrTooManyReviews =>
      'Сегодня вы оставили слишком много отзывов. Попробуйте завтра.';

  @override
  String get plErrTooLong => 'Текст слишком длинный.';

  @override
  String get plErrTooShort => 'Слишком коротко.';

  @override
  String get plErrWrongHost =>
      'Эта ссылка ведёт на другой сайт. Введите правильную ссылку.';

  @override
  String get plErrHandle =>
      'Неверный username. Только буквы, цифры и подчёркивание.';

  @override
  String get plErrUrl => 'Это не похоже на ссылку.';

  @override
  String get plErrIncomplete => 'Ссылка неполная.';

  @override
  String get plErrNotProfile =>
      'Это ссылка на публикацию. Отправьте ссылку на профиль.';

  @override
  String get plErrPending => 'Предложение по этому полю уже на проверке.';

  @override
  String get plErrSame => 'Это уже сохранено.';

  @override
  String get plErrRateLimited =>
      'Вы исчерпали лимит на сегодня. Попробуйте завтра.';

  @override
  String get plErrGone => 'Этого места больше нет.';

  @override
  String get plErrNotOwner =>
      'Объявления для этого места может отправлять только подтверждённый владелец.';

  @override
  String get plErrHasOwner => 'Владелец этого места уже подтверждён.';

  @override
  String get plErrTooManyPending =>
      'У вас много запросов на проверке. Дождитесь их рассмотрения.';

  @override
  String get plPhotoFailed => 'Не удалось загрузить фото';

  @override
  String get plMosque => 'Мечеть';

  @override
  String get plRestaurant => 'Ресторан';

  @override
  String get plShop => 'Магазин';

  @override
  String get plNearMe => 'Искать рядом со мной';

  @override
  String get plByAddress => 'Искать у другого адреса';

  @override
  String get plAddressTip =>
      'Напишите адрес по-КОРЕЙСКИ: город, район, улица. Можно скопировать из карты.';

  @override
  String get plSearchButton => 'Найти';

  @override
  String get plRecentAddresses => 'Недавние адреса';

  @override
  String get plChooseTitle => 'Где искать?';

  @override
  String get plChooseBody =>
      'Выберите одну из кнопок выше: рядом с вами или у другого адреса — покажем 5 ближайших мест.';

  @override
  String plNearestMosques(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ближайших мечети',
      many: '$count ближайших мечетей',
      few: '$count ближайшие мечети',
      one: 'Ближайшая мечеть',
    );
    return '$_temp0';
  }

  @override
  String plNearestRestaurants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ближайших ресторана',
      many: '$count ближайших ресторанов',
      few: '$count ближайших ресторана',
      one: 'Ближайший ресторан',
    );
    return '$_temp0';
  }

  @override
  String plNearestShops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ближайших магазина',
      many: '$count ближайших магазинов',
      few: '$count ближайших магазина',
      one: 'Ближайший магазин',
    );
    return '$_temp0';
  }

  @override
  String get plNearestToAddress => 'Ближайшие к адресу';

  @override
  String plHereNow(String city, String when) {
    return 'Вы здесь: $city · $when';
  }

  @override
  String plHereNowNoCity(String when) {
    return 'Местоположение определено · $when';
  }

  @override
  String plSavedNote(String city, String when) {
    return 'Не удалось определить текущее место — показано для $city ($when)';
  }

  @override
  String plSavedNoteNoCity(String when) {
    return 'Не удалось определить текущее место — показано по прежнему ($when)';
  }

  @override
  String get plLocatingYou => 'Определяем ваше местоположение…';

  @override
  String get plLoadingPlaces => 'Загружаем места…';

  @override
  String get plDeniedBody =>
      'Разрешите доступ к геолокации, чтобы найти ближайшие места, или ищите по адресу.';

  @override
  String get plAllow => 'Разрешить';

  @override
  String get plBlockedBody =>
      'Доступ к геолокации выключен в настройках. Включите его или ищите по адресу.';

  @override
  String get plOffBody =>
      'Геолокация на телефоне выключена. Включите её или ищите по адресу.';

  @override
  String get plFailedBody =>
      'Не удалось определить местоположение. Попробуйте ещё раз или ищите по адресу.';

  @override
  String get plUseAddress => 'Искать по адресу';

  @override
  String get plDetails => 'Подробнее';

  @override
  String plKmFromYou(String km) {
    return 'От вас $km';
  }

  @override
  String plKmFromAddress(String km) {
    return 'От адреса $km';
  }

  @override
  String get themeToDay => 'Дневной режим';

  @override
  String get themeToNight => 'Ночной режим';

  @override
  String get plSocialMore => 'Знаете страницу в другой соцсети?';

  @override
  String get plCallNumber => 'Позвонить';

  @override
  String get plPhotoLoading => 'Загружаем фото…';

  @override
  String get plPhotoLoadingSpeed =>
      'Скорость загрузки зависит от вашего интернета';

  @override
  String get plGettingThere => 'Как добраться';

  @override
  String get plContact => 'Контакты';

  @override
  String get plNewsTitle => 'Новости';

  @override
  String get carMarket => 'Авто Базар';

  @override
  String get carTabBrowse => 'Обзор';

  @override
  String get carTabSearch => 'Поиск';

  @override
  String get carTabSaved => 'Избранное';

  @override
  String carListings(String count) {
    return 'Объявлений: $count';
  }

  @override
  String carAvailableSold(String available, String sold) {
    return '$available в продаже · $sold продано';
  }

  @override
  String get carSearchSub => 'По параметрам';

  @override
  String carSavedSub(String count) {
    return 'Сохранено: $count';
  }

  @override
  String get carLoading => 'Загрузка…';

  @override
  String get carMedianPrice => 'средняя цена';

  @override
  String get carNoneOnSale => 'Сейчас нет в продаже';

  @override
  String carSoldCount(String count) {
    return 'Продано: $count';
  }

  @override
  String get carSortNew => 'Новые';

  @override
  String get carSortValue => 'Выгодные';

  @override
  String get carSortPriceUp => 'Цена ↑';

  @override
  String get carSortPriceDown => 'Цена ↓';

  @override
  String get carSortMileage => 'Пробег ↑';

  @override
  String get carSortYear => 'Год ↓';

  @override
  String get carAll => 'Все';

  @override
  String get carAvailable => 'В продаже';

  @override
  String get carSold => 'Продано';

  @override
  String get carEmptyAllTitle => 'Пока нет объявлений';

  @override
  String get carEmptyAllBody => 'Скоро появятся новые машины';

  @override
  String get carEmptyModelTitle => 'По этой модели нет объявлений';

  @override
  String get carEmptyModelBody => 'Выберите другую модель вверху';

  @override
  String get carChannelTitle => 'Vegukin Avto — канал';

  @override
  String get carChannelBody => 'Все новые объявления появляются там сразу';

  @override
  String get carOpen => 'Открыть';

  @override
  String get carLoadFailed => 'Не удалось загрузить';

  @override
  String get carCheckInternet => 'Проверьте интернет';

  @override
  String get carDeal => 'Выгодно';

  @override
  String get carNegotiable => 'Торг';

  @override
  String get carNoPrice => 'Цена не указана';

  @override
  String get carFewDetails => 'Мало данных';

  @override
  String get carSeen => 'Просмотрено';

  @override
  String get carSave => 'Сохранить';

  @override
  String get carUnsave => 'Убрать из избранного';

  @override
  String get carFuelPetrol => 'Бензин';

  @override
  String get carFuelDiesel => 'Дизель';

  @override
  String get carFuelLpg => 'Газ (LPG)';

  @override
  String get carFuelHybrid => 'Гибрид';

  @override
  String get carAutomatic => 'Автомат';

  @override
  String get carManual => 'Механика';

  @override
  String get carNotGiven => 'Не указано';

  @override
  String get carPickModel => 'Выберите марку и модель';

  @override
  String get carPriceMax => 'Цена до, ₩';

  @override
  String get carMileageMax => 'Пробег до, км';

  @override
  String get carYearFrom => 'Год от';

  @override
  String get carFuel => 'Топливо';

  @override
  String get carStatus => 'Статус';

  @override
  String carResults(String count) {
    return 'Найдено: $count';
  }

  @override
  String get carNothingFound => 'Ничего не найдено';

  @override
  String get carWidenFilters => 'Ослабьте фильтры';

  @override
  String get carClearFilters => 'Сбросить';

  @override
  String get carSavedEmptyTitle => 'В избранном пусто';

  @override
  String get carSavedEmptyBody => 'Сохраняйте понравившиеся машины кнопкой ❤';

  @override
  String get carStartBrowsing => 'Начать просмотр';

  @override
  String get carPickBrand => 'Выберите марку';

  @override
  String get carAnyBrand => 'Любая';

  @override
  String get carAllBrands => 'все марки';

  @override
  String carBrandListings(String count) {
    return '$count объявл.';
  }

  @override
  String carAllOf(String brand) {
    return 'Все $brand';
  }

  @override
  String get carSearchHint => 'Поиск…';

  @override
  String get carCatalogFailed =>
      'Марки не загрузились. Проверьте интернет и откройте снова.';

  @override
  String carViews(String count) {
    return 'Просмотров: $count';
  }

  @override
  String get carNotice =>
      'Данные извлечены из текста объявления автоматически и могут быть неточны. Точную цену и детали смотрите в тексте объявления.';

  @override
  String get carPostText => 'Текст объявления';

  @override
  String get carNoText => 'Текста нет';

  @override
  String get carReadMore => 'Читать дальше';

  @override
  String get carReadLess => 'Свернуть';

  @override
  String carSource(String name) {
    return 'Источник: канал $name';
  }

  @override
  String get carPriceAnalysis => 'Анализ цены';

  @override
  String get carVeryCheap => 'Очень дёшево';

  @override
  String get carCheap => 'Дёшево';

  @override
  String get carAtMarket => 'По рынку';

  @override
  String get carPricier => 'Дороговато';

  @override
  String get carExpensive => 'Дорого';

  @override
  String get carNearAverage => 'около средней';

  @override
  String carBelowAverage(String percent) {
    return 'на $percent% ниже средней';
  }

  @override
  String carAboveAverage(String percent) {
    return 'на $percent% выше средней';
  }

  @override
  String carFewComparables(String count) {
    return 'сравнить можно лишь с $count';
  }

  @override
  String carScaleCheap(String price) {
    return 'дешевле $price';
  }

  @override
  String carScaleDear(String price) {
    return 'дороже $price';
  }

  @override
  String carNearYearBasis(String year, String count, String median) {
    return '$count машин около $year г. · средняя $median';
  }

  @override
  String carModelBasis(String count, String median) {
    return '$count в продаже · средняя $median';
  }

  @override
  String carSoldBasis(String count, String median) {
    return '$count продано · $median';
  }

  @override
  String get carDetails => 'Подробно';

  @override
  String get carGeneration => 'Поколение';

  @override
  String get carYear => 'Год';

  @override
  String get carMileage => 'Пробег';

  @override
  String get carGearbox => 'Коробка';

  @override
  String get carLegal => 'Документы';

  @override
  String get carLegalOk => 'Легально';

  @override
  String get carLegalNoReg => 'Без оформления';

  @override
  String get carRegistration => 'Переоформление';

  @override
  String get carRequired => 'Обязательно';

  @override
  String get carNotRequired => 'Не обязательно';

  @override
  String get carPosted => 'Опубликовано';

  @override
  String get carSourceLabel => 'Источник';

  @override
  String get carContact => 'Связаться';

  @override
  String get carSellerPhone => 'Телефон продавца';

  @override
  String get carCall => 'Позвонить';

  @override
  String get carCopy => 'Копировать';

  @override
  String get carCopied => 'Номер скопирован';

  @override
  String get carWriteOnTelegram => 'Написать в Telegram';

  @override
  String get carWrite => 'Написать';

  @override
  String get carNumberInText => 'Номер в тексте объявления';

  @override
  String get carSimilar => 'Похожие машины';

  @override
  String get carSimilarSub => 'по цене';

  @override
  String get carNoComparables => 'Не с чем сравнить';

  @override
  String get carListingFailed => 'Объявление не загрузилось';

  @override
  String carVideoSize(String size) {
    return 'Видео · $size МБ';
  }

  @override
  String get carListing => 'Объявление';

  @override
  String get carTabAlerts => 'Уведомления';

  @override
  String get carTabSell => 'Продать';

  @override
  String get carAlertsTitle => 'Уведомления';

  @override
  String carAlertsActive(String count) {
    return 'Активных: $count';
  }

  @override
  String get carNewAlert => 'Новое уведомление';

  @override
  String get carAnyCar => 'Все машины';

  @override
  String get carCreateAlert => 'Создать уведомление';

  @override
  String get carMyAlerts => 'Мои уведомления';

  @override
  String get carNoAlertsTitle => 'Уведомлений нет';

  @override
  String get carNoAlertsBody => 'Сообщим, когда появится подходящая машина';

  @override
  String get carAllListings => 'Все объявления';

  @override
  String get carAlertNeedsFilter =>
      'Выберите хотя бы один фильтр (модель, цена, пробег, год или топливо).';

  @override
  String get carAlertDuplicate => 'Такое уведомление уже есть.';

  @override
  String get carAlertLimit => 'Достигнут предел уведомлений.';

  @override
  String get carAlertCreated =>
      'Готово: подходящие объявления придут на телефон.';

  @override
  String get carAlertDeleted => 'Уведомление удалено';

  @override
  String get carSignInAlertsTitle => 'Сообщим о подходящей машине';

  @override
  String get carSignInAlertsBody =>
      'Для уведомлений войдите в аккаунт. Смотреть и сохранять можно без входа.';

  @override
  String get carSignInButton => 'Войти';

  @override
  String get carPushOff => 'Уведомления выключены — сообщения не придут.';

  @override
  String get carPushOn => 'Включить';

  @override
  String get carErrorGeneric => 'Ошибка. Попробуйте ещё раз.';

  @override
  String get carMyPosts => 'Мои объявления';

  @override
  String get carNewPost => 'Новое объявление';

  @override
  String get carNewPostSub => 'Продайте свою машину';

  @override
  String get carNoPostsTitle => 'Объявлений пока нет';

  @override
  String get carNoPostsBody =>
      'Разместите первое объявление кнопкой выше — это займёт пару минут.';

  @override
  String get carStatePending => 'На проверке';

  @override
  String get carStateApproved => 'Опубликовано';

  @override
  String get carStateRejected => 'Отклонено';

  @override
  String get carStateChanges => 'Нужны правки';

  @override
  String get carStateDraft => 'Черновик';

  @override
  String get carEdit => 'Изменить';

  @override
  String get carMarkSold => 'Продано';

  @override
  String get carDelete => 'Удалить';

  @override
  String get carSoldConfirmTitle => 'Отметить как проданное?';

  @override
  String get carSoldConfirmBody => 'Объявление будет показано как проданное.';

  @override
  String get carSoldConfirmYes => 'Да, продано';

  @override
  String get carMarkedSold => 'Отмечено как проданное';

  @override
  String get carDeleteConfirmTitle => 'Удалить объявление?';

  @override
  String get carDeleteConfirmBody => 'Это нельзя отменить.';

  @override
  String get carDeleted => 'Удалено';

  @override
  String get carCancel => 'Отмена';

  @override
  String get carSignInSellTitle => 'Продайте свою машину';

  @override
  String get carSignInSellBody =>
      'Чтобы разместить объявление, войдите в аккаунт.';

  @override
  String get carNewPostTitle => 'Новое объявление';

  @override
  String get carEditPostTitle => 'Изменить объявление';

  @override
  String get carPhotos => 'Фото и видео';

  @override
  String get carPhotosHint =>
      'Первое станет обложкой. До 10 файлов, видео ≤ 50 МБ.';

  @override
  String get carPhotosLocked => 'После отправки фото менять нельзя.';

  @override
  String get carAddMedia => 'Добавить';

  @override
  String get carCover => 'Обложка';

  @override
  String get carCarSection => 'Машина';

  @override
  String get carBrand => 'Марка';

  @override
  String get carModel => 'Модель';

  @override
  String get carPickBrandFirst => 'Сначала выберите марку';

  @override
  String get carPickModelTitle => 'Выберите модель';

  @override
  String get carOtherModel => 'Другая модель (вручную)';

  @override
  String get carModelHint => 'например: Sonata';

  @override
  String get carPickYear => 'Выберите год';

  @override
  String get carGenerationOptional => 'Поколение (необяз.)';

  @override
  String get carMileageLabel => 'Пробег (км)';

  @override
  String get carFuelType => 'Тип топлива';

  @override
  String get carPriceSection => 'Цена и документы';

  @override
  String get carPriceLabel => 'Цена (₩)';

  @override
  String get carNegotiableSub => 'Возможен торг с покупателем';

  @override
  String get carLegalLabel => 'Оформление';

  @override
  String get carLegalNo => 'Нелегально';

  @override
  String get carRegQuestion => 'Нужно переоформление?';

  @override
  String get carRegYes => 'Да, нужно';

  @override
  String get carPhoneLabel => 'Номер телефона';

  @override
  String get carContactHint => 'Заполните хотя бы одно.';

  @override
  String get carDescription => 'Описание';

  @override
  String get carDescriptionHint =>
      'Состояние, замены деталей, причина продажи...';

  @override
  String get carSubmit => 'Отправить на проверку';

  @override
  String get carSaveChanges => 'Сохранить';

  @override
  String get carRequiredMissing => 'Заполните обязательные поля';

  @override
  String get carChangesSaved => 'Сохранено';

  @override
  String get carSubmitted => 'Отправлено! Объявление появится после проверки.';

  @override
  String carUploading(String done, String total) {
    return 'Загрузка: $done / $total';
  }

  @override
  String get carVideoTooBig => 'Видео больше 50 МБ';

  @override
  String get carMediaLimit => 'Не больше 10';

  @override
  String get carNeedPhoto => 'Добавьте хотя бы одно фото';

  @override
  String get carDupTitle => 'Эта машина уже размещена';

  @override
  String get carDupBody =>
      'Есть объявление с тем же номером и машиной. Повторно разместить нельзя.';

  @override
  String get carDupOwn => 'Ваше объявление';

  @override
  String get carOk => 'Понятно';

  @override
  String get carChannelNudge =>
      'Подпишитесь на @vegukin_car, чтобы первыми видеть новые объявления';

  @override
  String get hsTabBoard => 'E’lonlar';

  @override
  String get hsTabMine => 'E’lonlarim';

  @override
  String get hsTabAlerts => 'Xabarnoma';

  @override
  String get hsTabPost => 'Joylash';

  @override
  String get hsSearchHint =>
      'Koreys tilida manzil yozsangiz, e’lonlar shu joyga yaqinligi bo‘yicha saralanadi.';

  @override
  String get hsSearch => 'Izlash';

  @override
  String get hsRecent => 'Eng yangi e’lonlar';

  @override
  String get hsNearest => 'Yaqinlik bo‘yicha';

  @override
  String hsCount(String count) {
    return '$count ta';
  }

  @override
  String get hsCancel => 'Bekor qilish';

  @override
  String get hsMore => 'Yana yuklash';

  @override
  String get hsAllShown => 'Barcha e’lonlar ko‘rsatildi';

  @override
  String get hsNew => 'Yangi';

  @override
  String get hsYours => 'Sizniki';

  @override
  String get hsSeeNumber => 'Raqamni ko‘rish';

  @override
  String get hsViaTelegram => 'Telegram orqali bog‘lanish';

  @override
  String get hsNoContact => 'Aloqa ma’lumoti yo‘q';

  @override
  String get hsEmptyTitle => 'Hozircha e’lon yo‘q';

  @override
  String get hsEmptyBody =>
      'Birinchi bo‘lib e’lon joylang — pastdagi «Joylash» tugmasini bosing.';

  @override
  String get hsPostAd => 'E’lon joylash';

  @override
  String get hsGeoTitle => 'Manzil topilmadi';

  @override
  String get hsGeoBody => 'Manzilni koreys tilida, to‘liqroq yozib ko‘ring:';

  @override
  String get hsRetry => 'Qayta urinish';

  @override
  String get hsLoadFailedTitle => 'E’lonlarni yuklab bo‘lmadi';

  @override
  String get hsLoadFailedBody =>
      'Internet aloqasini tekshiring va qayta urinib ko‘ring.';

  @override
  String get hsOpenFailedTitle => 'Ochib bo‘lmadi';

  @override
  String get hsOpenFailedBody =>
      'Bu e’lon o‘chirilgan yoki muddati tugagan bo‘lishi mumkin.';

  @override
  String get hsCopy => 'Nusxalash';

  @override
  String get hsNoPhone => 'Tel raqam ko‘rsatilmagan.';

  @override
  String get hsEdit => 'Tahrirlash';

  @override
  String get hsDelete => 'O‘chirish';

  @override
  String get hsCopied => 'Raqam nusxalab olindi';

  @override
  String get hsDeleteConfirm => 'E’lon o‘chirilsinmi? Buni qaytarib bo‘lmaydi.';

  @override
  String get hsDeleted => 'E’lon o‘chirildi';

  @override
  String get hsMineTitle => 'Mening e’lonlarim';

  @override
  String get hsMineSub =>
      'E’lonlar 30 kundan keyin ro‘yxatdan olinadi. Muddat tugashidan oldin shu yerdan uzaytiring.';

  @override
  String get hsActive => 'Faol';

  @override
  String get hsExpired => 'Muddati tugagan';

  @override
  String hsDaysLeft(String count) {
    return '$count kun qoldi';
  }

  @override
  String get hsHidden => 'Ro‘yxatda ko‘rinmaydi';

  @override
  String get hsExtend => 'Uzaytirish';

  @override
  String hsExtended(String count) {
    return 'Muddat yana $count kunga uzaytirildi';
  }

  @override
  String get hsMineEmptyTitle => 'Sizda e’lon yo‘q';

  @override
  String get hsMineEmptyBody => 'Joylagan e’lonlaringiz shu yerda ko‘rinadi.';

  @override
  String get hsFailedTitle => 'Yuklab bo‘lmadi';

  @override
  String get hsFailedBody => 'Qayta urinib ko‘ring.';

  @override
  String get hsNewTitle => 'Yangi e’lon';

  @override
  String get hsEditTitle => 'E’lonni tahrirlash';

  @override
  String get hsComposeSub => 'Manzil, telefon raqami va qisqa tavsif kifoya';

  @override
  String get hsAddress => 'Manzil';

  @override
  String get hsRequired => 'majburiy';

  @override
  String get hsAddressHint =>
      'Koreys tilida yozing. Manzil keyin o‘zgartirilmaydi.';

  @override
  String get hsAddressLocked =>
      'Manzilni o‘zgartirib bo‘lmaydi. Xato bo‘lsa, e’lonni o‘chirib, yangisini joylang.';

  @override
  String get hsPhone => 'Bog‘lanish uchun telefon raqam';

  @override
  String get hsContactHint =>
      'Telefon raqami yoki Telegram — kamida bittasi ko‘rsatilishi shart.';

  @override
  String get hsTelegramOptIn => 'Telegram orqali bog‘lanish';

  @override
  String hsYourUsername(String name) {
    return 'Sizning username: $name';
  }

  @override
  String get hsBody => 'E’lon matni';

  @override
  String get hsBodyHint =>
      'Ijara haqi, depozit, boshlanish sanasi, muddati va boshqa shartlarni yozing. Masalan: oyiga 500,000 won, depozit 5,000,000 won, avgust oyidan boshlab, kamida olti oyga. Kommunal alohida.';

  @override
  String get hsSubmit => 'E’lonni joylash';

  @override
  String get hsSave => 'O‘zgarishlarni saqlash';

  @override
  String get hsSaved => 'O‘zgarishlar saqlandi';

  @override
  String get hsPosted => 'E’loningiz joylandi';

  @override
  String get hsErrUsername =>
      '5-32 belgi: harflar, raqamlar va pastki chiziq. Harf bilan boshlansin.';

  @override
  String get hsErrContactRequired =>
      'Telefon raqami yoki Telegram — kamida bittasini ko‘rsating.';

  @override
  String get hsErrAddress => 'Manzilni koreys tilida, to‘liq yozing.';

  @override
  String get hsErrPhone => 'Telefon raqamini to‘g‘ri yozing.';

  @override
  String get hsErrBody => 'Matn kamida 20 ta belgidan iborat bo‘lsin.';

  @override
  String get hsErrUsernameEmpty =>
      'Username yozing yoki belgini olib tashlang.';

  @override
  String get hsErrGeocode => 'Manzil topilmadi. To‘liqroq yozib ko‘ring.';

  @override
  String get hsAlertsTitle => 'Bildirishnomalar';

  @override
  String get hsAlertsSub =>
      'Manzil va qidiruv radiusini kiriting. Shu radius ichida yangi e’lon qo‘yilsa, darhol xabar beramiz.';

  @override
  String get hsRadius => 'Qidiruv radiusi: shu masofadagi barcha e’lonlar';

  @override
  String get hsRadiusCustom => 'Yoki o‘zingiz kiriting';

  @override
  String get hsAdd => 'Qo‘shish';

  @override
  String get hsErrRadius => 'Doira 1 km dan 500 km gacha bo‘lsin.';

  @override
  String get hsAlertOff => 'O‘chirilgan — botni bloklagansiz';

  @override
  String hsAlertSent(String count) {
    return '$count ta xabar yuborilgan';
  }

  @override
  String get hsAlertDeleteConfirm => 'Bu bildirishnoma o‘chirilsinmi?';

  @override
  String get hsAlertAdded => 'Bildirishnoma qo‘shildi';

  @override
  String get hsAlertDeleted => 'Bildirishnoma o‘chirildi';

  @override
  String get hsAlertsEmptyTitle => 'Hozircha bildirishnoma yo‘q';

  @override
  String get hsAlertsEmptyBody =>
      'Yuqorida manzil yozib, qidiruv radiusini tanlang. Istalgancha bildirishnoma qo‘shishingiz mumkin.';

  @override
  String get hsSignInPostTitle => 'E’lon joylash uchun akkauntga kiring';

  @override
  String get hsSignInPostBody =>
      'E’lonlarni ko‘rish va raqamlarni ochish uchun kirish shart emas.';

  @override
  String get hsSignInAlertsTitle => 'Yangi e’lon chiqsa, xabar beramiz';

  @override
  String get hsSignInAlertsBody =>
      'Bildirishnoma uchun akkauntga kiring. Telefoningizga keladi.';

  @override
  String get hsSignIn => 'Akkauntga kirish';

  @override
  String get hsErrForbidden => 'Bu e’lon sizniki emas.';

  @override
  String get hsErrNotFound => 'E’lon topilmadi.';

  @override
  String get hsErrGone => 'E’lon o‘chirilgan yoki muddati tugagan.';

  @override
  String get hsErrGeoUnavailable =>
      'Manzil xizmati javob bermayapti. Birozdan keyin urinib ko‘ring.';

  @override
  String get hsErrUnavailable => 'Xizmat vaqtincha ishlamayapti.';

  @override
  String get hsErrServer => 'Serverda xatolik yuz berdi.';

  @override
  String hsErrRateSeconds(String count) {
    return 'Juda ko‘p urinish. $count soniyadan keyin qayta urining.';
  }

  @override
  String hsErrRateMinutes(String count) {
    return 'Juda ko‘p urinish. $count daqiqadan keyin qayta urining.';
  }

  @override
  String get hsErrNetwork => 'Serverga ulanib bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get hsErrGeneric => 'Xatolik yuz berdi.';

  @override
  String get hsSending => 'Yuborilmoqda…';

  @override
  String get jbTitle => 'Ish e’lonlari guruhi';

  @override
  String get jbSubtitle => 'Bot foydalanuvchilari uchun maxsus xizmat';

  @override
  String get jbBotDoes => 'Bot tomonidan:';

  @override
  String get jbPoint1 =>
      '50 dan ortiq ish e’lon guruhlari sizning o‘rningizga kunda 24 soat kuzatib boriladi';

  @override
  String get jbPoint2 =>
      'Faqat ish bilan bog‘liq bo‘lgan e’lonlar ajratib olinadi';

  @override
  String get jbPoint3 =>
      'Barcha ajratib olingan e’lonlar shu zahoti “Ish e’lonlari” guruhida e’lon qilib boriladi';

  @override
  String get jbGetLink => 'Guruh linkini olish';

  @override
  String get jbLinkNote =>
      'Havola faqat siz uchun yaratiladi va 15 soniya amal qiladi';

  @override
  String get jbLinkLoading => 'Link yaratilmoqda…';

  @override
  String get jbSecondsLeft => 'soniya qoldi';

  @override
  String get jbYourLink => 'Sizning havolangiz:';

  @override
  String get jbJoin => 'Guruhga qo‘shilish';

  @override
  String get jbLinkWarning =>
      'Diqqat! Havola faqat 15 soniya davomida amal qiladi. Shoshiling!';

  @override
  String get jbExpiredTitle => 'Havola muddati tugadi';

  @override
  String get jbExpiredBody =>
      'Yangi havola olish uchun quyidagi tugmani bosing';

  @override
  String get jbRetry => 'Qayta urinish';

  @override
  String get jbErrorTitle => 'Xatolik yuz berdi';

  @override
  String get jbLinkError => 'Link yaratishda xatolik.';

  @override
  String get jbCopied => 'Nusxa olindi';

  @override
  String get jbPost => 'E’lon joylash';

  @override
  String get jbMyPosts => 'E’lonlarim';

  @override
  String get jbNewPost => 'Yangi e’lon';

  @override
  String get jbHowTitle => 'Bu qanday ishlaydi?';

  @override
  String get jbHow1 => 'Ish e’loningizni yozing va komissiya turini tanlang';

  @override
  String get jbHow2 =>
      'E’loningiz faqat bot guruhiga joylanadi. Foydalanuvchilar siz bilan tez orada bog‘lanishadi';

  @override
  String get jbHow3 => 'Odam topilgach, e’lonni “Band” deb belgilang';

  @override
  String get jbHowCommission =>
      'Komissiya ixtiyoriy — o‘zingiz tanlaysiz. Tanlasangiz, ishni olgan har bir kishi sizga bir martalik 10,000 KRW to‘laydi';

  @override
  String get jbHowRule =>
      'Sharti: E’lon faqat bot guruhida e’lon qilinib, boshqa guruhlarga joylanmasligi kerak';

  @override
  String get jbHowWait =>
      'Agar 2-3 soat ichida odam topilmasa, boshqa guruhlarda e’lon qilishingiz mumkin';

  @override
  String get jbEditing => 'E’lonni tahrirlash';

  @override
  String get jbCancel => 'Bekor qilish';

  @override
  String get jbText => 'E’lon matni';

  @override
  String get jbContact => 'Bog‘lanish uchun';

  @override
  String get jbRequired => 'majburiy';

  @override
  String get jbContactManual => 'Yoki telefon raqamni kiritish';

  @override
  String get jbContactBack => 'Telegram username ishlatish';

  @override
  String get jbContactHint => 'Tel raqam yoki Telegram username kiriting';

  @override
  String get jbCommission => 'Komissiya';

  @override
  String get jbCommissionPick => 'tanlang';

  @override
  String get jbWithCommission => 'Komissiyali';

  @override
  String get jbWithCommissionBody =>
      'Ishni olgan har bir kishi sizga bir martalik 10,000 KRW to‘laydi.';

  @override
  String get jbNoCommission => 'Komissiyasiz';

  @override
  String get jbFree => 'Bepul';

  @override
  String get jbNoCommissionBody =>
      'Hech qanday to‘lov talab qilinmaydi — faqat e’lon joylanadi.';

  @override
  String get jbPreview => 'E’lon ostida shunday ko‘rinadi:';

  @override
  String get jbFootYes =>
      '👉 Bu e’lon faqat shu guruhga qo‘yildi.\n👉 Ishga qatnashgan har bir kishi ish egasiga bir martalik komissiyani: 10,000 KRW ish haqini olish vaqtida to‘laydi.\n👉 E’lon egasiga murojaat qilish orqali siz ushbu to‘lovga rozilik bildirasiz.';

  @override
  String get jbFootNo =>
      '👉 Bu e’lon faqat shu guruhga qo‘yildi.\n👉 Bu e’lon uchun hech qanday komissiya olinmaydi.';

  @override
  String get jbAgree =>
      'Ushbu xabar ish bilan bog‘liq e’lonligini tasdiqlayman va boshqa Telegram guruhlarga 2-3 soat ichida joylamayman.';

  @override
  String get jbSubmit => 'E’lonni joylash';

  @override
  String get jbSave => 'O‘zgarishlarni saqlash';

  @override
  String get jbBanWarning =>
      'Reklama, shaxsiy xabarlar yoki ish bilan bog‘liq bo‘lmagan e’lonlar davomiy qo‘ygan foydalanuvchi bloklanadi.';

  @override
  String get jbSending => 'E’lon yuborilmoqda…';

  @override
  String get jbSaving => 'O‘zgarishlar saqlanmoqda…';

  @override
  String get jbSentTitle => 'E’lon yuborildi!';

  @override
  String get jbSentBody => 'E’loningiz guruhga muvaffaqiyatli joylandi.';

  @override
  String get jbSavedTitle => 'E’lon yangilandi!';

  @override
  String get jbSavedBody => 'O‘zgarishlar guruhdagi xabarga ham qo‘llanildi.';

  @override
  String get jbChipCommission => 'Komissiyali e’lon — 10,000 KRW';

  @override
  String get jbChipFree => 'Komissiyasiz e’lon';

  @override
  String get jbPostAgain => 'Yana e’lon joylash';

  @override
  String get jbPostError => 'E’lon yuborishda xatolik.';

  @override
  String get jbEmptyTitle => 'Hali e’lon joylamadingiz';

  @override
  String get jbEmptyAction => 'Birinchi e’lonni joylash';

  @override
  String get jbHintText => 'E’lon matni kamida 10 belgi bo‘lishi kerak';

  @override
  String get jbHintContact => 'Bog‘lanish uchun kontakt ma’lumotini kiriting';

  @override
  String get jbHintCommission => 'Komissiya turini tanlang';

  @override
  String get jbHintAgree => 'Qoidalarga rozilik belgisini qo‘ying';

  @override
  String get jbActive => 'Faol';

  @override
  String get jbReserved => 'Band';

  @override
  String get jbFinished => 'Bajarildi';

  @override
  String get jbReserve => 'Band qilish';

  @override
  String get jbReopen => 'Faol qilish';

  @override
  String get jbFinish => 'Yakunlash';

  @override
  String get jbDone => 'Ish bajarildi';

  @override
  String get jbEdit => 'Tahrirlash';

  @override
  String get jbDelete => 'O‘chirish';

  @override
  String jbFinishIn(int hours, int minutes) {
    return 'Yakunlash uchun: $hours soat $minutes daq. qoldi';
  }

  @override
  String get jbReserveText =>
      'Ishchi topildimi? E’lonni band sifatida belgilashni xohlaysizmi?';

  @override
  String get jbReopenTitle => 'Qayta faollashtirish';

  @override
  String get jbReopenText => 'E’lonni qayta faol holatga o‘tkazmoqchimisiz?';

  @override
  String get jbFinishText =>
      'Ish bajarildi deb belgilamoqchimisiz? Bu qaytarib bo‘lmaydi.';

  @override
  String get jbDeleteTitle => 'E’lonni o‘chirish';

  @override
  String get jbDeleteText =>
      'E’lon guruhdan ham, ro‘yxatingizdan ham butunlay o‘chiriladi. Davom etasizmi?';

  @override
  String get jbYes => 'Ha';

  @override
  String get jbJustNow => 'hozirgina';

  @override
  String jbMinutesAgo(int n) {
    return '$n daq. oldin';
  }

  @override
  String jbHoursAgo(int n) {
    return '$n soat oldin';
  }

  @override
  String jbDaysAgo(int n) {
    return '$n kun oldin';
  }

  @override
  String get jbErrNetwork => 'Tarmoq xatosi. Qayta urinib ko‘ring.';

  @override
  String get jbSignInTitle => 'E’lon joylash uchun kiring';

  @override
  String get jbSignInBody =>
      'E’lonlaringiz akkauntingizga bog‘lanadi: keyin ularni band qilish, tahrirlash yoki o‘chirish mumkin.';

  @override
  String get jbSignIn => 'Kirish';

  @override
  String get jbLoadFailed => 'E’lonlarni yuklab bo‘lmadi';

  @override
  String homeVisitsToday(String count) {
    return 'Посещений сегодня: $count';
  }
}
