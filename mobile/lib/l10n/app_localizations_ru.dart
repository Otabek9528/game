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
      'Уведомления выключены. Включите их в настройках.';

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
  String get themeToDay => 'Дневной режим';

  @override
  String get themeToNight => 'Ночной режим';
}
