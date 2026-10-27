import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Notifications go through this delegate, which hands them to the
    // plugins: Firebase for its own, VegukinPlugin for reminders and the
    // test notification. Set before the plugins register, so Firebase
    // doesn't take the place.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // The app's own native side (VegukinPlugin.swift).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VegukinPlugin") {
      VegukinPlugin.register(with: registrar)
    }
  }
}
