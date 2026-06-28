import Foundation
import SwiftData

// MARK: - SEMESTER MANAGER (LOGICĂ CENTRALIZATĂ)
struct SemesterManager {
    static var startDate: Date {
        let ts = UserDefaults.standard.double(forKey: "semesterStartDate")
        return ts == 0 ? Date() : Date(timeIntervalSince1970: ts)
    }
    
    static var endDate: Date {
        let ts = UserDefaults.standard.double(forKey: "semesterEndDate")
        return ts == 0 ? Date().addingTimeInterval(3600*24*7*14) : Date(timeIntervalSince1970: ts) // Default 14 săptămâni
    }
    
    static var currentWeek: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())
        let diff = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        if diff < 0 { return 1 } // Înainte de începutul semestrului
        return (diff / 7) + 1
    }
    
    static var isEvenWeek: Bool {
        return currentWeek % 2 == 0
    }
    
    // Calculează câte ocazii (cursuri) mai sunt din ziua de AZI până la finalul semestrului
    static func remainingOpportunities(forDay dayOfWeek: Int, frequency: String) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let semEnd = calendar.startOfDay(for: endDate)
        
        guard today <= semEnd else { return 0 }
        
        var count = 0
        var checkDate = today
        
        while checkDate <= semEnd {
            let weekday = calendar.component(.weekday, from: checkDate)
            let appWeekday = weekday == 1 ? 7 : weekday - 1 // Aliniere Luni=1, Duminică=7
            
            if appWeekday == dayOfWeek {
                if frequency == "Weekly" {
                    count += 1
                } else { // Every two weeks
                    let start = calendar.startOfDay(for: startDate)
                    let diff = calendar.dateComponents([.day], from: start, to: checkDate).day ?? 0
                    let weekNum = (diff / 7) + 1
                    
                    // Considerăm implicit că materiile bi-săptămânale se țin în săptămânile impare (Săptămâna 1, 3, 5...)
                    if weekNum % 2 != 0 {
                        count += 1
                    }
                }
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = nextDay
        }
        return count
    }
}

@Model
class Subject {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var type: String
    var dayOfWeek: Int
    var startTime: Date
    var endTime: Date
    var room: String
    
    var frequency: String = "Weekly"
    var minRequired: Int = 7
    
    var courseGrade: Double = 0.0
    var seminarGrade: Double = 0.0
    var courseWeight: Double = 0.5
    var seminarWeight: Double = 0.5
    
    @Relationship(deleteRule: .cascade) var attendanceDetails: [AttendanceDetail] = []
    
    var finalGrade: Double {
        let result = (courseGrade * courseWeight) + (seminarGrade * seminarWeight)
        return result > 0 ? result : 0.0
    }
    
    var mainAttendance: AttendanceDetail? {
        attendanceDetails.first
    }
    
    // NOU: Calculează dinamic câte chiuluri mai ai disponibile
    var remainingSkips: Int {
        let attended = mainAttendance?.attended ?? 0
        let needed = max(0, minRequired - attended)
        let totalRemainingClasses = SemesterManager.remainingOpportunities(forDay: dayOfWeek, frequency: frequency)
        return max(0, totalRemainingClasses - needed)
    }
    
    // NOU: Verifică dacă materia se ține în săptămâna curentă
    var isScheduledThisWeek: Bool {
        if frequency == "Weekly" { return true }
        return !SemesterManager.isEvenWeek // Se ține în săptămânile impare (1, 3, 5...)
    }
    
    init(name: String, type: String, dayOfWeek: Int, startTime: Date, endTime: Date, room: String = "", frequency: String = "Weekly", totalHours: Int = 14, minRequired: Int = 7) {
        self.name = name
        self.type = type
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.room = room
        self.frequency = frequency
        self.minRequired = minRequired
        self.courseGrade = 0.0
        self.seminarGrade = 0.0
        self.courseWeight = 0.5
        self.seminarWeight = 0.5
        self.attendanceDetails = [AttendanceDetail(sessionType: type, attended: 0, total: totalHours)]
    }
}

@Model
class AttendanceDetail {
    var sessionType: String
    var attended: Int = 0
    var total: Int = 14
    
    init(sessionType: String, attended: Int = 0, total: Int = 14) {
        self.sessionType = sessionType
        self.attended = attended
        self.total = total
    }
}

@Model
class Exam {
    var subjectName: String
    var date: Date
    var room: String
    var type: String = "Examen"
    var grade: Double? = nil
    
    init(subjectName: String, date: Date, room: String, type: String = "Examen", grade: Double? = nil) {
        self.subjectName = subjectName
        self.date = date
        self.room = room
        self.type = type
        self.grade = grade
    }
}
