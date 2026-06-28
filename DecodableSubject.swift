import Foundation

struct DecodableSubject: Decodable {
    let name: String
    let type: String       // "Lecture", "Seminar" sau "Lab"
    let dayOfWeek: Int     // 1 pentru Luni, 7 pentru Duminică
    let startTime: String  // Format "HH:mm" (ex: "08:00")
    let endTime: String    // Format "HH:mm" (ex: "09:30")
    let room: String
    let frequency: String  // "Weekly" sau "Every two weeks"
    
    // Convertim orele primite ca string în obiecte de tip Date pentru modelul tău
    func convertToDate(timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let timeDate = formatter.date(from: timeString) else { return Date() }
        
        // Aliniem ora pe componentele zilei curente pentru consistență
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: timeDate)
        return calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: Date()) ?? Date()
    }
}

// Structura care decodează rădăcina răspunsului de la Gemini
struct GeminiResponseRoot: Decodable {
    let subjects: [DecodableSubject]
}
