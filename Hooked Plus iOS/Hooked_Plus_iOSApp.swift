//
//  Hooked_Plus_iOSApp.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn
import Swinject

// ------------------------------------------------------
// MARK: - Global App Initialization State
// ------------------------------------------------------

final class AppInitializationState: ObservableObject {
    @Published var isReady: Bool = false
}

// Global instance accessible to both App and AppDelegate
let appInitializationState = AppInitializationState()


// ------------------------------------------------------
// MARK: - Root App
// ------------------------------------------------------

@main
struct Hooked_Plus_iOSApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootLaunchView()
                .environmentObject(appInitializationState)
                .environment(\.imageCache, TemporaryImageCache())
        }
    }
}


// ------------------------------------------------------
// MARK: - AppDelegate
// ------------------------------------------------------

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    static let container = Container()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        // Firebase setup
        FirebaseApp.configure()
        
        // 2. Set up UNUserNotificationCenter
        UNUserNotificationCenter.current().delegate = self
        
        // 3. Set up Firebase Messaging Delegate
        Messaging.messaging().delegate = self
        
        // 4. Request notification permission
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications() // Register with APNs
            }
        }

        // Swinject setup
        let assembly = HookedAssembly()
        assembly.assemble(container: AppDelegate.container)

        // Trigger camera permissions (your existing code)
        _ = HookedAssembly.resolver.resolve(CameraHost.self)

        // Notify SwiftUI that initialization is finished
        DispatchQueue.main.async {
            appInitializationState.isReady = true
        }

        return true
    }

    // Google Sign-In handler
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    // Link APNs token to FCM
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
        
    // Handle FCM registration token refresh (for targeted messaging)
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        // TODO: If this token is new, send it to your server for saving
    }
    
    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}


// ------------------------------------------------------
// MARK: - RootLaunchView (Splash → Router)
// ------------------------------------------------------

struct RootLaunchView: View {

    @EnvironmentObject var initState: AppInitializationState

    var body: some View {
        ZStack {
            if !initState.isReady {
                SplashView()
                    .transition(.opacity)
            } else {
                Router()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: initState.isReady)
    }
}
