import SwiftUI

enum Theme {
    static let violet = Color(red: 0.294, green: 0.239, blue: 0.878)      // #4B3DE0
    static let violetSoft = Color(red: 0.357, green: 0.294, blue: 1.0)    // #5B4BFF
    static let mint = Color(red: 0.043, green: 0.478, blue: 0.353)        // #0B7A5A
    static let mintBright = Color(red: 0.071, green: 0.663, blue: 0.498)  // #12A97F
    static let alert = Color(red: 0.706, green: 0.137, blue: 0.094)       // #B42318
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: scheme == .dark
                    ? [Color(red: 0.07, green: 0.07, blue: 0.12), Color(red: 0.05, green: 0.05, blue: 0.09)]
                    : [Color(red: 0.969, green: 0.957, blue: 0.937), Color(red: 0.945, green: 0.953, blue: 0.980)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Theme.violetSoft.opacity(scheme == .dark ? 0.28 : 0.15), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}
