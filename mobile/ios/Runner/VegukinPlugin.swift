import CoreLocation
import Flutter
import UIKit
import UserNotifications
import WidgetKit

/// The app's own native side on iOS: the channels MainActivity.kt answers on
/// Android, for what lib/ asks.
///
/// * `vegukin/widget`: the home-screen widget's data (ios/PrayerWidget), and
///   what a widget or reminder tap opened the app for;
/// * `vegukin/qibla` and the `vegukin/compass` events: the Qibla page;
/// * `vegukin/reminders`: prayer reminders;
/// * `vegukin/system`: banking apps, and this phone for a bug report;
/// * `vegukin/share`: the share sheet;
/// * `vegukin/alerts`: whether notifications show, and the test one.
final class VegukinPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  /// Notifications the app shows itself; the rest are Firebase's.
  static let notificationPrefix = "vegukin."

  /// Shared with the widget extension: the prayer times it shows.
  static let appGroup = "group.com.vegukin.muslimVegukin"
  static let widgetKey = "prayer_widget"

  /// A widget opens the app with muslimvegukin://prayers.
  static let urlScheme = "muslimvegukin"

  /// Korean banking apps, by their Android package (lib/features/support/
  /// support_data.dart), as iOS knows them: by URL scheme. Only schemes
  /// known for certain; the others don't show on iPhone. Each must also be
  /// in Info.plist's LSApplicationQueriesSchemes.
  static let bankSchemes = [
    "viva.republica.toss": "supertoss://",
    "com.kakaobank.channel": "kakaobank://",
    "com.kbstar.kbbank": "kbbank://",
  ]

  /// Flutter holds plugins weakly; this one lives as long as the app.
  private static var instance: VegukinPlugin?

  private let compass = QiblaCompass()
  private let camera: QiblaCamera
  private let reminders = PrayerReminders()
  private var widgetChannel: FlutterMethodChannel?

  /// What a widget or a reminder opened the app for; Flutter takes it once.
  private var launchAction: String?

  private init(textures: FlutterTextureRegistry) {
    camera = QiblaCamera(textures: textures)
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = VegukinPlugin(textures: registrar.textures())
    instance = plugin
    registrar.addApplicationDelegate(plugin)
    registrar.addSceneDelegate(plugin)
    let messenger = registrar.messenger()
    func channel(_ name: String, _ handler: @escaping FlutterMethodCallHandler) -> FlutterMethodChannel {
      let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
      channel.setMethodCallHandler(handler)
      return channel
    }
    plugin.widgetChannel = channel("vegukin/widget") { plugin.onWidget($0, $1) }
    _ = channel("vegukin/qibla") { plugin.onQibla($0, $1) }
    _ = channel("vegukin/reminders") { plugin.onReminders($0, $1) }
    _ = channel("vegukin/system") { plugin.onSystem($0, $1) }
    _ = channel("vegukin/share") { plugin.onShare($0, $1) }
    _ = channel("vegukin/alerts") { plugin.onAlerts($0, $1) }
    FlutterEventChannel(name: "vegukin/compass", binaryMessenger: messenger).setStreamHandler(plugin.compass)
  }

  // MARK: - Channels

  private func onWidget(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "update":
      if let json = call.arguments as? String {
        UserDefaults(suiteName: Self.appGroup)?.set(json, forKey: Self.widgetKey)
        WidgetCenter.shared.reloadAllTimelines()
      }
      result(nil)
    case "exactAlarmsMissing":
      // iOS delivers scheduled notifications on time without asking.
      result(false)
    case "openExactAlarmSettings":
      result(nil)
    case "takeLaunchAction":
      result(launchAction)
      launchAction = nil
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func onQibla(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "hasCompass":
      result(CLLocationManager.headingAvailable())
    case "keepScreenOn":
      UIApplication.shared.isIdleTimerDisabled = (call.arguments as? Bool) ?? false
      result(nil)
    case "startCamera":
      camera.start(result)
    case "stopCamera":
      camera.stop()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func onReminders(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "update":
      reminders.save(json: call.arguments as? String ?? "[]")
      result(nil)
    case "preview":
      reminders.preview(mode: call.arguments as? String ?? "")
      result(nil)
    case "notificationsAllowed":
      Self.notificationsShown { result($0) }
    case "openNotificationSettings":
      Self.openNotificationSettings()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func onSystem(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "installed":
      // iOS lends no other app's icon; the page draws its own.
      let packages = call.arguments as? [String] ?? []
      result(packages.filter { Self.bankURL($0).map(UIApplication.shared.canOpenURL) ?? false }.map { ["package": $0] })
    case "open":
      guard let package = call.arguments as? String, let url = Self.bankURL(package) else {
        result(false)
        return
      }
      UIApplication.shared.open(url) { result($0) }
    case "device":
      let info = Bundle.main.infoDictionary ?? [:]
      let version = "\(info["CFBundleShortVersionString"] ?? "?") (\(info["CFBundleVersion"] ?? "?"))"
      let device: [String: String] = [
        "manufacturer": "Apple",
        "model": Self.machine(),
        // The key Android fills; here, the iOS version.
        "android": "iOS \(UIDevice.current.systemVersion)",
        "version": version,
      ]
      result(device)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func onShare(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard call.method == "text" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let text = call.arguments as? String, let top = Self.topViewController() else {
      result(nil)
      return
    }
    let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    sheet.popoverPresentationController?.sourceView = top.view
    sheet.popoverPresentationController?.sourceRect = CGRect(
      x: top.view.bounds.midX, y: top.view.bounds.maxY, width: 0, height: 0)
    top.present(sheet, animated: true)
    result(nil)
  }

  private func onAlerts(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "shown":
      Self.notificationsShown { result($0) }
    case "show":
      // The test notification, which arrived while the app is open: shown
      // as a real one (see willPresent below).
      let args = call.arguments as? [String: Any]
      let content = UNMutableNotificationContent()
      content.title = args?["title"] as? String ?? ""
      content.body = args?["body"] as? String ?? ""
      content.sound = .default
      let request = UNNotificationRequest(identifier: Self.notificationPrefix + "alert", content: content, trigger: nil)
      UNUserNotificationCenter.current().add(request)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Notifications (forwarded by FlutterAppDelegate)

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Only the app's own; Firebase answers for its notifications.
    guard notification.request.identifier.hasPrefix(Self.notificationPrefix) else { return }
    completionHandler([.banner, .list, .sound])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    guard response.notification.request.identifier.hasPrefix(PrayerReminders.prefix) else { return }
    setLaunchAction("open_prayers")
    completionHandler()
  }

  // MARK: - Opened from the widget (scene URLs)

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions?) -> Bool {
    handle(connectionOptions?.urlContexts ?? [])
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    handle(URLContexts)
  }

  private func handle(_ contexts: Set<UIOpenURLContext>) -> Bool {
    guard let url = contexts.map(\.url).first(where: { $0.scheme == Self.urlScheme }) else { return false }
    setLaunchAction(url.host == "location" ? "refresh_location" : "open_prayers")
    return true
  }

  /// Kept for Flutter to take, and Flutter told at once: the app may be
  /// running already, past the moment it looks.
  private func setLaunchAction(_ action: String) {
    launchAction = action
    widgetChannel?.invokeMethod("launchAction", arguments: nil)
  }

  // MARK: - Helpers

  static func notificationsShown(_ done: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      let allowed: [UNAuthorizationStatus] = [.authorized, .provisional, .ephemeral]
      let shown = allowed.contains(settings.authorizationStatus)
      DispatchQueue.main.async { done(shown) }
    }
  }

  static func openNotificationSettings() {
    let address: String
    if #available(iOS 16.0, *) {
      address = UIApplication.openNotificationSettingsURLString
    } else {
      address = UIApplication.openSettingsURLString
    }
    if let url = URL(string: address) { UIApplication.shared.open(url) }
  }

  private static func bankURL(_ package: String) -> URL? {
    bankSchemes[package].flatMap(URL.init(string:))
  }

  /// "iPhone15,2": the model's identifier.
  private static func machine() -> String {
    var system = utsname()
    uname(&system)
    return Mirror(reflecting: system.machine).children.reduce(into: "") { name, element in
      if let byte = element.value as? Int8, byte != 0 { name.append(Character(UnicodeScalar(UInt8(byte)))) }
    }
  }

  private static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}
