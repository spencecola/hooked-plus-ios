//
//  Router.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/6/25.
//

import SwiftUI

struct Router: View {
    @StateObject private var authManager = AuthManager()

    var body: some View {
        Group {
            if case .unauthenticated = authManager.state {
                LoginView()
                    .environmentObject(authManager)
            } else if case .authenticated(_) = authManager.state {
                AuthenticatedTabBarView()
                    .environmentObject(authManager)
            } else {
                EmptyView()
            }
        }.loading(isLoading: authManager.isLoading())
            .background(ColorToken.lightGray.color)
    }
}

struct Router_Previews: PreviewProvider {
    static var previews: some View {
        Router()
    }
}
