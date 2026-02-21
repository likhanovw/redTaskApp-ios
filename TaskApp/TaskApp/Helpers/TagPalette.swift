import SwiftUI

/// Палитра из 10 цветов для тегов (индексы 0–9). Адаптирована под светлую и тёмную тему.
enum TagPalette {
    static let count = 10

    static func color(for index: Int) -> Color {
        color(for: index, colorScheme: .light)
    }

    static func color(for index: Int, colorScheme: ColorScheme) -> Color {
        let i = max(0, min(9, index))
        return colorScheme == .dark ? darkColors[i] : lightColors[i]
    }

    /// Светлая тема — мягкие пастельные тона.
    static var lightColors: [Color] {
        [
            Color(red: 0.70, green: 0.88, blue: 0.72),   // green
            Color(red: 0.95, green: 0.92, blue: 0.68),   // yellow
            Color(red: 0.95, green: 0.82, blue: 0.65),   // orange
            Color(red: 0.95, green: 0.70, blue: 0.68),   // red
            Color(red: 0.82, green: 0.75, blue: 0.92),   // purple
            Color(red: 0.70, green: 0.82, blue: 0.95),   // blue
            Color(red: 0.68, green: 0.86, blue: 0.95),   // sky
            Color(red: 0.80, green: 0.92, blue: 0.65),   // lime
            Color(red: 0.95, green: 0.76, blue: 0.85),   // pink
            Color(red: 0.45, green: 0.45, blue: 0.48),   // black
        ]
    }

    /// Тёмная тема — приглушённые, но читаемые на тёмном фоне; текст .primary (белый) контрастирует.
    static var darkColors: [Color] {
        [
            Color(red: 0.22, green: 0.48, blue: 0.30),   // green
            Color(red: 0.55, green: 0.50, blue: 0.22),   // yellow
            Color(red: 0.58, green: 0.42, blue: 0.28),   // orange
            Color(red: 0.55, green: 0.28, blue: 0.28),   // red
            Color(red: 0.38, green: 0.32, blue: 0.52),   // purple
            Color(red: 0.25, green: 0.40, blue: 0.55),   // blue
            Color(red: 0.22, green: 0.45, blue: 0.55),   // sky
            Color(red: 0.35, green: 0.52, blue: 0.25),   // lime
            Color(red: 0.52, green: 0.32, blue: 0.42),   // pink
            Color(red: 0.28, green: 0.28, blue: 0.30),   // black
        ]
    }
}
