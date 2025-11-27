//
//  Button.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/12/25.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = ColorToken.buttonPrimary.color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .background(backgroundColor) // Solid dark gray background
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // Slight shrink on press
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .shadow(radius: configuration.isPressed ? 2 : 5)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    var backgroundColor: Color = ColorToken.buttonSecondary.color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(backgroundColor)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(backgroundColor, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct TextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundColor(configuration.isPressed ? .gray : .blue)
            .font(.system(size: 16, weight: .medium))
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .background(Color.gray.opacity(configuration.isPressed ? 0.3 : 0.1))
            .clipShape(Circle())
            .foregroundColor(.primary)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}
