import SwiftUI

/// Палитра из 10 мягких цветов для тегов (индексы 0–9): green, yellow, orange, red, purple, blue, sky, lime, pink, black.
enum TagPalette {
    static let count = 10

    static func color(for index: Int) -> Color {
        let i = max(0, min(9, index))
        return colors[i]
    }

    static var colors: [Color] {
        [
            Color(red: 0.70, green: 0.88, blue: 0.72),   // green — мягкий зелёный
            Color(red: 0.95, green: 0.92, blue: 0.68),   // yellow — кремово-жёлтый
            Color(red: 0.95, green: 0.82, blue: 0.65),   // orange — персиковый
            Color(red: 0.95, green: 0.70, blue: 0.68),   // red — мягкий красный
            Color(red: 0.82, green: 0.75, blue: 0.92),   // purple — лавандовый
            Color(red: 0.70, green: 0.82, blue: 0.95),   // blue — пудровый синий
            Color(red: 0.68, green: 0.86, blue: 0.95),   // sky — небесно-голубой
            Color(red: 0.80, green: 0.92, blue: 0.65),   // lime — мягкий лайм
            Color(red: 0.95, green: 0.76, blue: 0.85),   // pink — приглушённый розовый
            Color(red: 0.45, green: 0.45, blue: 0.48),   // black — мягкий тёмно-серый
        ]
    }
}
