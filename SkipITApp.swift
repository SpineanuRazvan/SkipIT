import SwiftUI
import SwiftData

@main
struct SkipITApp: App {
    var sharedModelContainer: ModelContainer = {
            let schema = Schema([Subject.self, AttendanceDetail.self, Exam.self])
            let groupID = "group.com.razvan.skipit"
            
            guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
                fatalError("EROARE: App Group negasit.")
            }
            
            let storeURL = groupURL.appendingPathComponent("SkipIT.sqlite")
            let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
            
            return try! ModelContainer(for: schema, configurations: [modelConfiguration])
        }()

    // --- REPARATIE: Cerem permisiunea imediat ce pornește aplicația ---
    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// --- EXACT COLOR PALETTE FROM SCREENSHOT ---
extension Color {
    static let appDustyPeach = Color(red: 0.77, green: 0.54, blue: 0.54)
    static let appSelectedDay = Color(red: 0.95, green: 0.91, blue: 0.82)
    static let appDeepText = Color(red: 0.35, green: 0.15, blue: 0.12)
    static let appDeleteRed = Color(red: 0.82, green: 0.35, blue: 0.35)
    static let porcelainMist = Color(red: 244/255, green: 241/255, blue: 234/255)
}
