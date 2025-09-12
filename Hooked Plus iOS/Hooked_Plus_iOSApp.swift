//
//  Hooked_Plus_iOSApp.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import Swinject

@main
struct Hooked_Plus_iOSApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            Router()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static let container = Container()
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            FirebaseApp.configure()
            // setup swinject dependencies
            let assembly = HookedAssembly()
            assembly.assemble(container: AppDelegate.container)

            return true
        }
}
