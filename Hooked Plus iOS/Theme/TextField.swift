//
//  TextFild.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/11/25.
//

import SwiftUI

/// A TextField style with rounded corners, transparent background, and custom border color.
struct RoundedBorderTextFieldStyle: TextFieldStyle {
    let cornerRadius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    
    init(
        cornerRadius: CGFloat = 12,
        borderColor: Color = ColorToken.buttonSecondary.color,
        borderWidth: CGFloat = 1.5
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.clear)                     // Transparent background
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)  // Custom border
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
