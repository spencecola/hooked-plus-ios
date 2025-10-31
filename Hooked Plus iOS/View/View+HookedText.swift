//
//  View+HookedText.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/31/25.
//

import SwiftUI

extension Text {
    func hookedText(font: Font? = nil, color: Color = ColorToken.textPrimary.color) -> some View {
        self.font(font).foregroundColor(color)
    }
}
