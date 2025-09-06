//
//  Hooked_Plus_iOSApp.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct Hooked_Plus_iOSApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        FirebaseApp.configure()
        print("Firebase configured: \(FirebaseApp.app() != nil)") // Debug to confirm initialization
    }
    
    var body: some Scene {
        WindowGroup {
            Router()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
