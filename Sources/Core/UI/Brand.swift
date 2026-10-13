import SwiftUI

enum Brand {
    static let accent = Color.indigo
    static let buttonFill = Color(red: 0.28, green: 0.24, blue: 0.78)
    static let background = Color(uiColor: .secondarySystemBackground)
}

struct AsterMark: View {
    var size: CGFloat = 44
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * 0.48, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Brand.accent.gradient, in: RoundedRectangle(cornerRadius: size * 0.3))
            .accessibilityHidden(true)
    }
}
