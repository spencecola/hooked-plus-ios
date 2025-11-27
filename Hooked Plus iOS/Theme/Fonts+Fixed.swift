//
//  Fonts+Fixed.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/22/25.
//

import SwiftUI

extension Font {
    /// Fixed caption that is always exactly caption size, ignores Dynamic Type
    static var fixedCaption: Font {
        .system(size: 12, weight: .regular, design: .default)
    }
    
    /// Slightly bolder version if you want
    static var fixedCaption2: Font {
        .system(size: 12, weight: .medium, design: .default)
    }
    
    /// Custom font at fixed size (e.g. SF Pro, Helvetica, etc.)
    static func fixedCustom(_ name: String, size: CGFloat = 12) -> Font {
        .custom(name, fixedSize: size)   // iOS 16+ best API
    }
}
