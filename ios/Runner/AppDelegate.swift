import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let mapsApiKey = configuredMapsApiKey()
    if !mapsApiKey.isEmpty {
      GMSServices.provideAPIKey(mapsApiKey)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configuredMapsApiKey() -> String {
    let value = (Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let isConfigured = !value.isEmpty && !value.contains("$(") && !value.hasPrefix("REPLACE_WITH_")

    guard isConfigured else {
      #if DEBUG
      assertionFailure(
        "GOOGLE_MAPS_API_KEY is not configured. Copy ios/Flutter/Maps.xcconfig.example to Maps.xcconfig."
      )
      return ""
      #else
      preconditionFailure("GOOGLE_MAPS_API_KEY must be configured for release builds.")
      #endif
    }

    return value
  }
}
