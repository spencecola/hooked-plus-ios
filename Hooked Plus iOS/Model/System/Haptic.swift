//
//  Haptic.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/13/25.
//

import Foundation
import UIKit

enum Haptic {
    /// provide light haptic feedback
    static func light() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    /// provide medium haptic feedback
    static func medium() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}
