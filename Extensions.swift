import SwiftUI

// 1. Extensia pentru CULORI (Paleta Earthy Liquid Glass)
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
    
    static let sageGreenPalette = Color(hex: "98A086")
    static let dustyRosePalette = Color(hex: "A76D5E")
    static let goldenTanPalette = Color(hex: "C4A071")
    static let warmBeigePalette = Color(hex: "DFCCB1")
    static let terracottaBrownPalette = Color(hex: "846044")
    
}

// 2. Extensia pentru DATE (Formatare dinamică)
extension Date {
    
    /// Formatează ora în funcție de preferința utilizatorului (24h sau AM/PM)
    func formatTime(is24Hour: Bool) -> String {
        let formatter = DateFormatter()
        // HH:mm pentru 24h, hh:mm a pentru AM/PM
        formatter.dateFormat = is24Hour ? "HH:mm" : "hh:mm a"
        return formatter.string(from: self)
    }
    
    /// Returnează ziua (ex: "19")
    func formatAsDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: self)
    }
    
    /// Returnează luna prescurtată (ex: "MAR")
    func formatAsMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self).uppercased()
    }
}
