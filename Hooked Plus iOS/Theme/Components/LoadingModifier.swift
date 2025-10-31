//
//  LoadingModifier.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/6/25.
//

import SwiftUI

struct LoadingModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
//                    .background(ColorToken.backgroundPrimary.color.opacity(0.3))
                    .clipShape(Circle())
            }
        }
    }
}

extension View {
    func loading(isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}
