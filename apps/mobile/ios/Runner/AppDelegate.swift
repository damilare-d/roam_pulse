import Flutter
import UIKit
import WidgetKit

/// The native half of NativeWidgetService (Phase 10) — persists whatever
/// Flutter sends via the "com.roampulse.widget" channel and asks
/// WidgetKit to reload. Mirrors MainActivity.kt's method-call switch;
/// everything past "read the call arguments" is delegated to
/// WidgetDataStore (RoamPulseWidget/Shared/WidgetDataStore.swift, which
/// must also be added to this Runner target's membership in Xcode, not
/// just the widget extension's).
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let store = WidgetDataStore()
      let widgetChannel = FlutterMethodChannel(
        name: "com.roampulse.widget",
        binaryMessenger: controller.binaryMessenger
      )
      widgetChannel.setMethodCallHandler { call, result in
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "bad_args", message: "Expected a map", details: nil))
          return
        }
        switch call.method {
        case "updateConnectivity":
          store.updateConnectivity(
            state: args["state"] as? String ?? "",
            carrierName: args["carrierName"] as? String ?? "",
            technology: args["technology"] as? String ?? "",
            lastSyncedAt: args["lastSyncedAt"] as? String ?? ""
          )
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(nil)
        case "updatePlan":
          store.updatePlan(
            destinationCity: args["destinationCity"] as? String ?? "",
            countryCode: args["countryCode"] as? String ?? "",
            dataRemainingMb: args["dataRemainingMb"] as? Double ?? 0,
            dataAllowanceMb: args["dataAllowanceMb"] as? Double ?? 0,
            daysRemaining: args["daysRemaining"] as? Int ?? 0
          )
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
