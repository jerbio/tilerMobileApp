import UIKit
import Flutter

// Leaving the commented block below so in case in the future I need to handle google sign in manually I can look at the previous implementation
// @UIApplicationMain
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     GeneratedPluginRegistrant.register(with: self)
//     if #available(iOS 10.0, *) {
//       UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
//     }
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
    
//   override func application(
//     _ app: UIApplication,
//     open url: URL,
//     options: [UIApplication.OpenURLOptionsKey: Any] = [:]
//   ) -> Bool {
//     if url.scheme == "tilerapp" { // Replace with your actual redirect scheme
//       let appDelegate = UIApplication.shared.delegate as! FlutterAppDelegate
//       let flutterViewController = appDelegate.window.rootViewController as! FlutterViewController
//       let methodChannel = FlutterMethodChannel(name: "TILER_THIRD_PARTY_SIGNUP_CHANNEL", binaryMessenger: flutterViewController.binaryMessenger)
//       methodChannel.invokeMethod("handleAuthorizationCallback", arguments: url.absoluteString)
//     } else {
//       return super.application(app, open: url, options: options)
//     }
//     return true
//   }
    
// }

import app_links

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Retrieve the link from parameters
    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      // We have a link, propagate it to your Flutter app or not
      AppLinks.shared.handleLink(url: url)
      return true // Returning true will stop the propagation to other packages
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
