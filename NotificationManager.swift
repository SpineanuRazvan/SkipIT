import Foundation
import UserNotifications
import SwiftData
import WidgetKit

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Subject.self, AttendanceDetail.self, Exam.self])
        let groupID = "group.com.razvan.skipit"
        
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            fatalError("❌ EROARE: App Group negasit in NotificationManager.")
        }
        
        let storeURL = groupURL.appendingPathComponent("SkipIT.sqlite")
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: true
        )
        
        return try! ModelContainer(for: schema, configurations: [modelConfiguration])
    }()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        defineActions()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                print("✅ Notificări autorizate cu succes!")
                self.defineActions()
            }
        }
    }
    
    func defineActions() {
        let presentAction = UNNotificationAction(
            identifier: "CONFIRM_ACTION",
            title: "Yes",
            options: [.authenticationRequired]
        )
        
        let absentAction = UNNotificationAction(
            identifier: "SKIP_ACTION",
            title: "No",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: "ATTENDANCE_CHECK_CATEGORY",
            actions: [presentAction, absentAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "SkipIT: Test Notificare 🎓"
        content.body = "Confirmă prezența de test direct de pe ecran."
        content.categoryIdentifier = "ATTENDANCE_CHECK_CATEGORY"
        content.userInfo = ["SUBJECT_ID": "TEST_MODE"]
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "TEST_NOTIF", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        print("🚀 Alerta de test a fost trimisă!")
    }

    func rescheduleAllNotifications(with subjects: [Subject]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for subject in subjects {
            scheduleNotification(for: subject)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkPendingNotifications()
        }
    }

    private func scheduleNotification(for subject: Subject) {
        let content = UNMutableNotificationContent()
        content.title = "Did you attend \(subject.name)?"
        content.body = "Long press to mark your attendance. \(subject.type)."
        content.categoryIdentifier = "ATTENDANCE_CHECK_CATEGORY"
        content.userInfo = ["SUBJECT_ID": subject.id.uuidString]
        content.sound = .default
        
        let calendarWeekday = subject.dayOfWeek == 7 ? 1 : subject.dayOfWeek + 1
        var components = Calendar.current.dateComponents([.hour, .minute], from: subject.endTime)
        components.weekday = calendarWeekday
        components.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let requestID = "\(subject.name)-\(subject.dayOfWeek)-\(components.hour ?? 0)\(components.minute ?? 0)"
        
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func checkPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("\n====== 📅 TIMELINE ALERTE ACTIVE ÎN iOS: ======")
            if requests.isEmpty { print("❌ Coada este goală!") }
            for request in requests {
                print("• Materie: \(request.content.title)")
                if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
                    let comps = calendarTrigger.dateComponents
                    print("  -> Fixată pentru Ziua calendaristică: \(comps.weekday ?? 0) la Ora: \(comps.hour ?? 0):\(String(format: "%02d", comps.minute ?? 0))")
                }
            }
            print("================================================\n")
        }
    }

    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Accept both identifiers for backward compatibility
        if response.actionIdentifier == "CONFIRM_ACTION" || response.actionIdentifier == "YES_ACTION" {
            if let idString = userInfo["SUBJECT_ID"] as? String, let uuid = UUID(uuidString: idString) {
                updateAttendance(for: uuid)
            } else if userInfo["SUBJECT_ID"] as? String == "TEST_MODE" {
                print("✅ Test interactiv reușit!")
            }
        }
        completionHandler()
    }
        
    @MainActor
    private func updateAttendance(for subjectUUID: UUID) {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Subject>(predicate: #Predicate { $0.id == subjectUUID })
        
        do {
            if let subject = try context.fetch(descriptor).first {
                if let detail = subject.attendanceDetails.first {
                    detail.attended += 1
                    try context.save()
                    print("✅ Prezență pusă de aplicația principală pentru: \(subject.name)!")
                    // Refresh widgets after the save so they reflect the new attendance
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        } catch {
            print("❌ Eroare la salvare: \(error)")
        }
    }
}
