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
  String get exactAlarmsTitle => 'Точное время для виджета';

  @override
  String get exactAlarmsBody =>
      'Чтобы виджет на главном экране переключался на следующий намаз точно в срок, включите «Будильники и напоминания» на следующей странице.';

  @override
  String get exactAlarmsAllow => 'Продолжить';

  @override
  String get exactAlarmsLater => 'Позже';
}
