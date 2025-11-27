//
//  SplashView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/14/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background – matches your launch screen
            ColorToken.backgroundSecondary.color   // add to Assets.xcassets
                .ignoresSafeArea()
            
            // Your logo / icon
            Image("splash_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeInOut(duration: 0.8).repeatCount(3, autoreverses: true),
                           value: isAnimating)
        }
        .onAppear { isAnimating = true }
    }
}
