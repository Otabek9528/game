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
  String get uzOnlyHint => 'Только на узбекском';

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
}
