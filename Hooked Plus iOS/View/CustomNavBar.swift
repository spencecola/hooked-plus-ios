import SwiftUI

struct CustomNavBar: ViewModifier {
    let appName = "Hooked+"
    let pageTitle: String
    let backgroundColor: Color

    init(pageTitle: String,
         backgroundColor: Color = ColorToken.headerPrimary.color) {
        self.pageTitle = pageTitle
        self.backgroundColor = backgroundColor
    }

    func body(content: Content) -> some View {
        NavigationStack {
            content
                .navigationTitle(pageTitle)
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(backgroundColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                // <--- Force the nav bar to use "dark" appearance (white text/icons)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text(appName)
                            .font(.title2).bold()
                            .foregroundColor(.white)
                    }
                }
        }
    }
}

// MARK: – Convenience
extension View {
    func customNavBar(
        title: String,
        backgroundColor: Color = ColorToken.headerPrimary.color
    ) -> some View {
        modifier(CustomNavBar(pageTitle: title, backgroundColor: backgroundColor))
    }
}
