import Foundation
import EventKit
import Observation

@Observable
class CalendarManager {
    static let shared = CalendarManager()
    let store = EKEventStore()
    var isAuthorized = false
    
    // MODIFICAT: Stocăm evenimentele pentru fiecare zi a săptămânii (1...7)
    var weeklyEvents: [Int: [EKEvent]] = [:]

    init() {
        self.isAuthorized = checkCalendarAuthorization()
    }

    private func checkCalendarAuthorization() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    func requestAccess() {
        if #available(iOS 17.0, *) {
            store.requestFullAccessToEvents { granted, _ in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                }
            }
        } else {
            store.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                }
            }
        }
    }

    // MODIFICAT: Descărcăm evenimentele pentru toată săptămâna dintr-O SINGURĂ RULARE
    func fetchWeeklyEvents() {
        guard isAuthorized else {
            self.weeklyEvents = [:]
            return
        }

        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Săptămâna începe Luni
        let now = Date()

        // Găsim începutul săptămânii curente
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return }

        var temporaryWeeklyEvents: [Int: [EKEvent]] = [:]

        // Trecem prin fiecare zi din săptămână (1 = Luni, 7 = Duminică)
        for day in 1...7 {
            if let targetDate = calendar.date(byAdding: .day, value: day - 1, to: weekStart) {
                let startOfDay = calendar.startOfDay(for: targetDate)
                if let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) {
                    
                    let predicate = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
                    let events = store.events(matching: predicate)
                    
                    temporaryWeeklyEvents[day] = events.sorted { $0.startDate < $1.startDate }
                }
            }
        }

        // Actualizăm interfața pe thread-ul principal
        DispatchQueue.main.async {
            self.weeklyEvents = temporaryWeeklyEvents
        }
    }
}
