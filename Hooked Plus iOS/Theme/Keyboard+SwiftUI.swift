//
//  Keyboard+SwiftUI.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/30/25.
//

import SwiftUI

// Extension to dismiss the keyboard using the underlying UIKit or AppKit functionality
extension View {
    func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #elseif os(macOS)
        NSApp.keyWindow?.makeFirstResponder(nil)
        #endif
    }
}
