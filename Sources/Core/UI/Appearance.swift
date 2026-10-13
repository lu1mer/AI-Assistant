import SwiftUI

enum Appearance: String, CaseIterable {
    case system, light, dark

    static var storageKey: String {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") { return "ui-testing.appearance" }
        #endif
        return "appearance"
    }

    var title: String {
        switch self {
        case .system: "Как на устройстве"
        case .light: "Светлая"
        case .dark: "Тёмная"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
