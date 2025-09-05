//
//  Hooked_Plus_iOSApp.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct Hooked_Plus_iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
