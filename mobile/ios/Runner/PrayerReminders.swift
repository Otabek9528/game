import AVFoundation
import AudioToolbox
import UserNotifications

/// Prayer reminders (lib/features/reminders/), as PrayerReminders.kt on
/// Android: the app works out a week of them, texts included, in its own
/// language, and hands them over; iOS shows each at its time, with the app
/// closed. Each new list replaces the one before.
///
/// iOS keeps at most 64 scheduled notifications per app; a week is at most
/// 49 (seven a day), and the soonest 60 are kept.
///
/// "Vibrate" (the default): iOS has no vibration-only notification, so it
/// comes as a standard one, which vibrates with the ring switch on silent and
/// plays the usual sound otherwise. "Sound" plays the app's chime; "silent"
/// shows the notification only.
final class PrayerReminders {
  static let prefix = VegukinPlugin.notificationPrefix + "reminder."
  private static let limit = 60
  private static let chime = "vegukin_chime.caf"

  private var player: AVAudioPlayer?

  private struct Entry {
    let id: Int
    let at: Date
    let channel: String
    let title: String
    let body: String
  }

  func save(json: String) {
    guard let data = json.data(using: .utf8),
          let list = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
    else { return }
    let entries = list.compactMap(Self.entry)
    let center = UNUserNotificationCenter.current()
    center.getPendingNotificationRequests { pending in
      center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.prefix) })
      let now = Date()
      for entry in entries.filter({ $0.at > now }).sorted(by: { $0.at < $1.at }).prefix(Self.limit) {
        center.add(Self.request(entry))
      }
    }
  }

  /// Lets the user hear or feel a choice before keeping it.
  func preview(mode: String) {
    switch mode {
    case "sound":
      guard let url = Bundle.main.url(forResource: "vegukin_chime", withExtension: "caf") else { return }
      player = try? AVAudioPlayer(contentsOf: url)
      player?.play()
    case "vibrate":
      AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    default:
      break
    }
  }

  private static func entry(_ json: [String: Any]) -> Entry? {
    guard let id = json["id"] as? Int, let at = json["at"] as? Double else { return nil }
    return Entry(
      id: id,
      at: Date(timeIntervalSince1970: at / 1000),
      channel: json["channel"] as? String ?? "silent",
      title: json["title"] as? String ?? "",
      body: json["body"] as? String ?? "")
  }

  private static func request(_ entry: Entry) -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.title = entry.title
    content.body = entry.body
    content.threadIdentifier = "prayers"
    switch entry.channel {
    case "sound": content.sound = UNNotificationSound(named: UNNotificationSoundName(chime))
    case "vibrate": content.sound = .default
    default: break
    }
    // At the prayer's clock time; a new place or time zone brings a new
    // list from the app anyway.
    let when = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: entry.at)
    let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
    return UNNotificationRequest(identifier: prefix + String(entry.id), content: content, trigger: trigger)
  }
}
