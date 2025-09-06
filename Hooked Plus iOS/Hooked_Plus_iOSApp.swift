//
//  Hooked_Plus_iOSApp.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import SwiftUI
import FirebaseCore

@main
struct Hooked_Plus_iOSApp: App {
    
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
