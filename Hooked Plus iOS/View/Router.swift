//
//  Router.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/6/25.
//

import SwiftUI

struct Router: View {
    @StateObject private var authManager = AuthManager()

    @StateObject private var cameraHost = HookedAssembly.resolver.resolve(CameraHost.self)!
    
    var body: some View {
        Group {
            if case .unauthenticated = authManager.state {
                LoginView()
                    .environmentObject(authManager)
            } else if case .authenticated(_) = authManager.state {
                RecordingOverlayContainer {
                        AuthenticatedTabBarView()
                            .environmentObject(authManager)
                }
                .environmentObject(authManager)
                .environmentObject(cameraHost)
                .background(ColorToken.backgroundPrimary.color)
            } else {
                EmptyView()
            }
        }.loading(isLoading: authManager.isLoading())
            .tint(ColorToken.buttonSecondary.color)
            .background(ColorToken.backgroundPrimary.color)
    }
}

struct Router_Previews: PreviewProvider {
    static var previews: some View {
        Router()
    }
}
