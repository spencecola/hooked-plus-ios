import SwiftUI

struct CustomNavBar: ViewModifier {
    let appName: String = "Hooked+"
    let pageTitle: String
    let backgroundColor: Color
    let titleColor: Color  // For inline title text
    
    init(pageTitle: String, backgroundColor: Color = .blue, titleColor: Color = .white) {
        self.pageTitle = pageTitle
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
    }
    
    func body(content: Content) -> some View {
        NavigationStack {
            content
                .navigationTitle(pageTitle)  // Standard large title behavior
                .navigationBarTitleDisplayMode(.large)  // Enables large title (scroll-aware)
                .toolbarBackground(backgroundColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    // App name in leading (visible in inline mode)
                    ToolbarItem(placement: .topBarLeading) {
                        Text(appName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(titleColor)
                    }
                }
        }
    }
}

// Convenience extension
extension View {
    func customNavBar(title: String, backgroundColor: Color = ColorToken.headerPrimary.color, titleColor: Color = ColorToken.textPrimary.color) -> some View {
        self.modifier(CustomNavBar(pageTitle: title, backgroundColor: backgroundColor, titleColor: titleColor))
    }
}
