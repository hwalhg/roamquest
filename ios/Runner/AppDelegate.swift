import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle incoming URL (for OAuth deep links)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Log the incoming URL for debugging
    print("🔗 Deep link received: \(url.absoluteString)")

    // Check if this is a Supabase auth callback
    if url.absoluteString.contains("auth/callback") {
      print("✅ Detected Supabase auth callback")
    }

    // Always call super to ensure proper handling
    return super.application(app, open: url, options: options)
  }
}
