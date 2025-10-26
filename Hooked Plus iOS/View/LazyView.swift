//
//  LazyView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/24/25.
//

import SwiftUI

struct LazyView<Content: View>: View {
    private let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: some View {
        build()
    }
}
