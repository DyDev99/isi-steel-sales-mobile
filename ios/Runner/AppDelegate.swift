import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Read from Info.plist, which resolves $(GOOGLE_MAPS_API_KEY) from
    // ios/Flutter/Env.xcconfig (generated from .env, git-ignored). The key was
    // previously a literal here and leaked via git history —
    // docs/SECURITY.md §9.
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String,
       !apiKey.isEmpty,
       !apiKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(apiKey)
    } else {
      // Maps tiles will not render. Deliberately not fatal: every non-map screen
      // still works offline, and a missing dev key must not brick the whole app.
      NSLog("[ISI] GoogleMapsApiKey missing — run tool/generate_ios_env.dart. Maps disabled.")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
