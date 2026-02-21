import SwiftUI

/// Палитра из 8 мягких цветов для тегов (индексы 0–7).
enum TagPalette {
    static let count = 8

    static func color(for index: Int) -> Color {
        let i = max(0, min(7, index))
        return colors[i]
    }

    static var colors: [Color] {
        [
            Color(red: 0.85, green: 0.75, blue: 0.65),   // песочный
            Color(red: 0.70, green: 0.82, blue: 0.75),   // мятный
            Color(red: 0.75, green: 0.78, blue: 0.88),   // лавандовый
            Color(red: 0.90, green: 0.80, blue: 0.70),   // персиковый
            Color(red: 0.78, green: 0.85, blue: 0.82),   // аква
            Color(red: 0.88, green: 0.82, blue: 0.78),   // беж
            Color(red: 0.82, green: 0.75, blue: 0.85),   // сиреневый
            Color(red: 0.76, green: 0.82, blue: 0.78),   // серо-зелёный
        ]
    }
}
