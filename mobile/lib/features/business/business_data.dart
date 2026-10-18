import 'package:flutter/material.dart';

import '../../core/app_language.dart';
import '../../l10n/app_localizations.dart';

/// Where owners and readers reach the directory's admin.
final bizAdmin = Uri.parse('https://t.me/otabeksattarov');

/// One line under each category's name, so nobody has to open "Tarjima" to
/// learn it means documents and apostille (business.text.js categoryAbout),
/// by slug. A category not here shows none.
const _about = {
  'halal-market': ('Halol go‘sht, ziravorlar, oziq-ovqat', 'Халяль-мясо, специи, продукты', 'Halal meat, spices, groceries'),
  'pishiriqlar': ('Non, patir, somsa, shirinliklar', 'Хлеб, лепёшки, самса, сладости', 'Bread, flatbread, samsa, sweets'),
  'tarjima': ('Hujjat tarjimasi va apostil', 'Перевод документов и апостиль', 'Document translation and apostille'),
  'pochta': ('O‘zbekistonga posilka va yuk', 'Посылки и грузы в Узбекистан', 'Parcels and cargo to Uzbekistan'),
  'aviakassa': ('Aviabilet va yo‘l hujjatlari', 'Авиабилеты и проездные документы', 'Flights and travel papers'),
  'sim-telefon': ('SIM karta, telefon, aksessuarlar', 'SIM-карты, телефоны, аксессуары', 'SIM cards, phones, accessories'),
  'sugurta': ('Sug‘urta va moliyaviy xizmatlar', 'Страхование и финансовые услуги', 'Insurance and financial services'),
  'consulting': ('Universitet va viza maslahati', 'Консультации по вузам и визам', 'University and visa advice'),
  'repetitor': ('Til va fan o‘qituvchilari', 'Репетиторы по языкам и предметам', 'Language and subject tutors'),
  'kosmetika': ('Koreys kosmetikasi va parvarish', 'Корейская косметика и уход', 'Korean cosmetics and care'),
};

String? categoryAbout(String slug, AppLanguage language) {
  final about = _about[slug];
  if (about == null) return null;
  return switch (language) {
    AppLanguage.uz => about.$1,
    AppLanguage.ru => about.$2,
    AppLanguage.en => about.$3,
  };
}

/// Each kind of link's icon and colour.
(IconData, Color) linkLook(String kind) => switch (kind) {
      'phone' => (Icons.call_rounded, const Color(0xFF059669)),
      'telegram' => (Icons.telegram, const Color(0xFF229ED9)),
      'tgchannel' => (Icons.campaign_rounded, const Color(0xFF229ED9)),
      'kakao' => (Icons.chat_bubble_rounded, const Color(0xFFC9A400)),
      'instagram' => (Icons.camera_alt_rounded, const Color(0xFFE1306C)),
      'tiktok' => (Icons.tiktok, const Color(0xFF111111)),
      'youtube' => (Icons.smart_display_rounded, const Color(0xFFFF0000)),
      'facebook' => (Icons.facebook, const Color(0xFF1877F2)),
      'playstore' => (Icons.shop_rounded, const Color(0xFF01875F)),
      'appstore' => (Icons.apple, const Color(0xFF555555)),
      _ => (Icons.language_rounded, const Color(0xFF047857)),
    };

/// What a tap on a contact button will do; the icon already says which app.
String linkVerb(AppLocalizations s, String kind) => switch (kind) {
      'phone' => s.bizActCall,
      'telegram' => s.bizActTelegram,
      'tgchannel' => s.bizActChannel,
      'kakao' => s.bizActKakao,
      'website' => s.bizActWebsite,
      'instagram' => s.bizActInstagram,
      'tiktok' => s.bizActTiktok,
      'youtube' => s.bizActYoutube,
      'facebook' => s.bizActFacebook,
      'playstore' => s.bizActPlay,
      'appstore' => s.bizActAppStore,
      _ => s.bizActOpen,
    };

/// A channel's name.
String linkChannel(AppLocalizations s, String kind) => switch (kind) {
      'phone' => s.bizChannelPhone,
      'telegram' => 'Telegram',
      'tgchannel' => s.bizChannelGroup,
      'kakao' => 'KakaoTalk',
      'website' => s.bizChannelWebsite,
      'instagram' => 'Instagram',
      'tiktok' => 'TikTok',
      'youtube' => 'YouTube',
      'facebook' => 'Facebook',
      'playstore' => 'Google Play',
      'appstore' => 'App Store',
      _ => kind,
    };
