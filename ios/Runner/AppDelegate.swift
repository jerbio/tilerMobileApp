import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "tilerapp" { // Replace with your actual redirect scheme
      let appDelegate = UIApplication.shared.delegate as! FlutterAppDelegate
      let flutterViewController = appDelegate.window.rootViewController as! FlutterViewController
      let methodChannel = FlutterMethodChannel(name: "TILER_THIRD_PARTY_SIGNUP_CHANNEL", binaryMessenger: flutterViewController.binaryMessenger)
      methodChannel.invokeMethod("handleAuthorizationCallback", arguments: url.absoluteString)
    } else {
      return super.application(app, open: url, options: options)
    }
    return true
  }
    
}
