//
//  Colors.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import SwiftUI
import UIKit

enum ColorToken {
    case headerPrimary
    case buttonSecondary
    case darkGray
    case lightGray
    case backgroundPrimary
    
    var color: Color {
        switch self {
        case .headerPrimary:
            return Color(hex: "#133456") | Color(hex: "#E6F0FA") // Pale blue for dark mode
        case .buttonSecondary:
            return Color(hex: "#EF7F18") | Color(hex: "#108080") // Muted teal for dark mode
        case .darkGray:
            return Color(hex: "#1B1A1D") | Color(hex: "#F9F9FA") // Light gray for dark mode
        case .lightGray:
            return Color(hex: "#F9F9FA") | Color(hex: "#1B1A1D") // Dark gray for dark mode
        case .backgroundPrimary:
            return Color(hex: "#FFFFFF") | Color(hex: "#133456") // Black for dark mode
        }
    }
}

// Extension to initialize Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// Extension on Text to set font and color
extension Text {
    func fontAndColor(font: Font, token: ColorToken) -> Text {
        self
            .font(font)
            .foregroundColor(token.color)
    }
}

infix operator |: AdditionPrecedence
internal extension Color {
    static func | (lightMode: Color, darkMode: Color) -> Color {
        return Color(uiColor: UIColor { (traitCollection) -> UIColor in
            return traitCollection.userInterfaceStyle == .light ? UIColor(lightMode) : UIColor(darkMode)
        })
    }
}
