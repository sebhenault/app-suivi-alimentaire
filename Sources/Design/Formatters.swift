import Foundation

enum Fmt {
    /// Arrondi lisible : 1234.5 -> "1235", 12.34 -> "12".
    static func n(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    static func kcal(_ value: Double) -> String { "\(n(value)) kcal" }
    static func g(_ value: Double) -> String { "\(n(value)) g" }
    static func mg(_ value: Double) -> String { "\(n(value)) mg" }

    static func dayTitle(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Aujourd'hui" }
        if cal.isDateInYesterday(date) { return "Hier" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMMM"
        return f.string(from: date).capitalized
    }

    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.timeStyle = .short
        return f.string(from: date)
    }
}
