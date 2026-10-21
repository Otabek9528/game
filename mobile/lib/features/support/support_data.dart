// The donation and community pages' facts (pages/donation, pages/community).

/// Where donations go, as on the web page.
abstract final class DonationAccount {
  static const bank = 'KEB하나은행 (Hana Bank)';
  static const holder = 'SATTAROV OTABEK';
  static const number = '559-910261-05007';
}

/// Korean banking apps the donation page offers to open, with the account
/// number copied: those installed show up. Toss and KakaoBank also notice a
/// copied account number by themselves.
const bankApps = [
  ('Toss', 'viva.republica.toss'),
  ('KakaoBank', 'com.kakaobank.channel'),
  ('Hana 1Q', 'com.kebhana.hanapush'),
  ('KB Star', 'com.kbstar.kbbank'),
  ('Shinhan SOL', 'com.shinhan.sbanking'),
  ('Woori WON', 'com.wooribank.smart.npib'),
  ('NH Bank', 'nh.smart.banking'),
  ('IBK i-ONE', 'com.ibk.android.ionebank'),
];

/// The bot's official group.
abstract final class CommunityGroup {
  static const name = 'Muslim Vegukin';
  static const handle = '@MuslimVegukin';
  static const url = 'https://t.me/MuslimVegukin';
}
