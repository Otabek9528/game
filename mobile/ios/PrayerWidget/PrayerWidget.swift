import SwiftUI
import WidgetKit

// The iOS home-screen widgets, like the Android ones (android/…/widget/):
// the app hands them a week of prayer times with every label already in the
// user's language (lib/features/widget/home_widget_bridge.dart, through
// ios/Runner/VegukinPlugin.swift), so they keep counting down and roll over
// to new days without the app.
//
// Small: the next prayer, its time and the countdown. Medium: the day's six
// times, the next one marked, the dates and the countdown. Lock screen
// (iOS 16+): the next prayer and its countdown.

private let appGroup = "group.com.vegukin.muslimVegukin"
private let dataKey = "prayer_widget"
// As on Android, in light and dark mode alike: white and gold on the brand
// emerald (android/…/res/values/colors.xml, drawable/widget_bg.xml).
private let accent = Color(red: 0.969, green: 0.835, blue: 0.420)  // #F7D56B
private let emerald = LinearGradient(
  colors: [
    Color(red: 0.016, green: 0.220, blue: 0.169),  // #04382B
    Color(red: 0.024, green: 0.373, blue: 0.275),  // #065F46
    Color(red: 0.016, green: 0.471, blue: 0.341),  // #047857
  ],
  startPoint: .topLeading,
  endPoint: .bottomTrailing
)

/// What the app sent (widgetPayload in home_widget_bridge.dart).
struct PrayerData: Decodable {
  struct Day: Decodable {
    let date: String
    let line1: String
    let line2: String
    let short: String
    /// Fajr, sunrise, Dhuhr, Asr, Maghrib, Isha: milliseconds since 1970.
    let times: [Double]
  }

  let brand: String
  let message: String
  let city: String?
  let names: [String]?
  let until: [String]?
  let days: [Day]?

  static func load() -> PrayerData? {
    guard let json = UserDefaults(suiteName: appGroup)?.string(forKey: dataKey),
          let data = json.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(PrayerData.self, from: data)
  }
}

/// Where a moment stands: the day to show and the next prayer.
struct Moment {
  let day: PrayerData.Day
  /// Index of the next prayer in [day], or nil once the day's last has begun.
  let nextInDay: Int?
  let next: Date
  let nextName: String
  let nextUntil: String

  init?(_ data: PrayerData?, at now: Date) {
    guard let data, let days = data.days, let names = data.names, let until = data.until,
          names.count == 6, until.count == 6
    else { return nil }
    let all = days.flatMap { day in day.times.enumerated().map { (day, $0.offset, Date(timeIntervalSince1970: $0.element / 1000)) } }
    guard let upcoming = all.first(where: { $0.2 > now }) else { return nil }
    let today = days.first { $0.date == Moment.dayKey(now) } ?? upcoming.0
    self.day = today
    nextInDay = upcoming.0.date == today.date ? upcoming.1 : nil
    next = upcoming.2
    nextName = names[upcoming.1]
    nextUntil = until[upcoming.1]
  }

  static func dayKey(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
  }

  static func clock(_ millis: Double) -> String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f.string(from: Date(timeIntervalSince1970: millis / 1000))
  }
}

struct PrayerEntry: TimelineEntry {
  let date: Date
  let data: PrayerData?
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry {
    PrayerEntry(date: Date(), data: PrayerData.load())
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(PrayerEntry(date: Date(), data: PrayerData.load()))
  }

  /// A new entry at each prayer time and at midnight, for two days; then
  /// WidgetKit asks again. The countdowns tick by themselves.
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let data = PrayerData.load()
    let now = Date()
    let horizon = now.addingTimeInterval(48 * 3600)
    var moments = (data?.days ?? []).flatMap(\.times).map { Date(timeIntervalSince1970: $0 / 1000) }
    var midnight = Calendar.current.startOfDay(for: now)
    while midnight < horizon {
      midnight = Calendar.current.date(byAdding: .day, value: 1, to: midnight)!
      moments.append(midnight)
    }
    let entries = [PrayerEntry(date: now, data: data)]
      + moments.filter { $0 > now && $0 < horizon }.sorted().map { PrayerEntry(date: $0, data: data) }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

struct PrayerWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PrayerEntry

  var body: some View {
    Group {
      if let moment = Moment(entry.data, at: entry.date) {
        switch family {
        case .systemMedium: medium(moment)
        case .accessoryRectangular: rectangular(moment)
        case .accessoryInline: Text("\(moment.nextName) \(moment.next, style: .timer)")
        default: small(moment)
        }
      } else {
        empty
      }
    }
    .widgetURL(URL(string: "muslimvegukin://prayers"))
    // White text (.primary) and light grey (.secondary) on the emerald.
    .environment(\.colorScheme, .dark)
    .widgetBackground()
  }

  private func small(_ m: Moment) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(entry.data?.city ?? "").font(.caption2.weight(.semibold)).foregroundStyle(.secondary).lineLimit(1)
      Spacer(minLength: 0)
      Text(m.nextName).font(.headline).lineLimit(1)
      Text(m.next, style: .time).font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(accent)
        .minimumScaleFactor(0.6).lineLimit(1)
      Text(m.nextUntil).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).lineLimit(1)
      Text(m.next, style: .timer).font(.subheadline.monospacedDigit().weight(.semibold))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func medium(_ m: Moment) -> some View {
    VStack(spacing: 8) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 1) {
          Text(m.day.line1).font(.caption.weight(.semibold)).lineLimit(1)
          Text(m.day.line2).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
          Link(destination: URL(string: "muslimvegukin://location")!) {
            Label(entry.data?.city ?? "", systemImage: "location.fill").font(.caption2).foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 1) {
          Text(m.nextUntil).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).lineLimit(1)
          Text(m.next, style: .timer).font(.title3.monospacedDigit().weight(.bold)).foregroundStyle(accent)
            .multilineTextAlignment(.trailing)
        }
      }
      HStack(spacing: 4) {
        ForEach(0..<6, id: \.self) { i in
          VStack(spacing: 2) {
            Text(entry.data?.names?[i] ?? "").font(.system(size: 10, weight: .medium)).lineLimit(1)
              .minimumScaleFactor(0.7)
            Text(Moment.clock(m.day.times[i])).font(.system(size: 13, weight: .semibold).monospacedDigit())
          }
          .padding(.vertical, 6)
          .frame(maxWidth: .infinity)
          .foregroundStyle(i == m.nextInDay ? accent : .primary)
          .background(RoundedRectangle(cornerRadius: 8).fill(i == m.nextInDay ? accent.opacity(0.12) : .clear))
        }
      }
    }
  }

  private func rectangular(_ m: Moment) -> some View {
    VStack(alignment: .leading) {
      Text(m.nextName).font(.headline)
      Text(m.next, style: .timer).monospacedDigit()
    }
  }

  private var empty: some View {
    VStack(spacing: 6) {
      Text(entry.data?.brand ?? "Muslim Vegukin").font(.headline)
      Text(entry.data?.message ?? "").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
    }
  }
}

private extension View {
  /// The emerald; iOS 17 asks widgets for their background this way.
  @ViewBuilder func widgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { emerald }
    } else {
      padding().background(emerald)
    }
  }
}

@main
struct PrayerWidgetBundle: WidgetBundle {
  var body: some Widget {
    PrayerWidget()
  }
}

struct PrayerWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "PrayerWidget", provider: Provider()) { entry in
      PrayerWidgetView(entry: entry)
    }
    .configurationDisplayName("Muslim Vegukin")
    .description(Text("Prayer times"))
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
  }
}
