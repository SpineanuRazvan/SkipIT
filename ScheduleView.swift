import SwiftUI
import SwiftData
import EventKit
import UniformTypeIdentifiers
import UserNotifications

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subjects: [Subject]
    
    @State private var showingAddSubject = false
    @State private var subjectToEdit: Subject?
    @State private var calendarManager = CalendarManager.shared
    
    @State private var showingFileImporter = false
    @State private var isParsingPDF = false
    
    // Preluăm grupa studentului salvată la onboarding pentru a o trimite către AI
    @AppStorage("studentGroup") private var studentGroup = ""
    @AppStorage("use24HourFormat") private var use24HourFormat = true
    
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    @State private var selectedDay: Int = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let weekday = calendar.component(.weekday, from: Date())
        return weekday == 1 ? 7 : weekday - 1
    }()

    var body: some View {
        ZStack {
            Color.dustyRosePalette.ignoresSafeArea()
            
            VStack(spacing: 0) {
                weekHeaderIndicator
                daySelectorHeader
                mainSchedulePages
            }
        }
        .navigationTitle("Schedule")
        .tint(.white)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingAddSubject) {
            AddSubjectView(initialDay: selectedDay)
        }
        .sheet(item: $subjectToEdit) { subject in
            AddSubjectView(subject: subject)
        }
        .onAppear {
            setupNotificationCategories()
            rescheduleAllNotifications()
            
            if !calendarManager.isAuthorized {
                calendarManager.requestAccess()
            } else {
                calendarManager.fetchWeeklyEvents()
            }
        }
        .onChange(of: calendarManager.isAuthorized) { _, authorized in
            if authorized {
                calendarManager.fetchWeeklyEvents()
            }
        }
        // Observator reactiv. Ori de câte ori baza de date se modifică, re-aliniem notificările în iOS
        .onChange(of: subjects) {
            rescheduleAllNotifications()
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.pdf, .image, .png, .jpeg],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result: result)
        }
    }
    
    // MARK: - SUB-VIEWS
    
    private var weekHeaderIndicator: some View {
        Text("Week \(SemesterManager.currentWeek) • \(SemesterManager.isEvenWeek ? "Even Week" : "Odd Week")")
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.12))
            .cornerRadius(20)
            .padding(.top, 10)
    }
    
    private var daySelectorHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(1...7, id: \.self) { i in
                    Button {
                        selectedDay = i
                    } label: {
                        Text(days[i-1])
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(selectedDay == i ? Color.warmBeigePalette : Color.white.opacity(0.15))
                            .foregroundColor(selectedDay == i ? Color.terracottaBrownPalette : .white)
                            .cornerRadius(15)
                    }
                }
            }
            .padding()
        }
    }
    
    private var mainSchedulePages: some View {
        TabView(selection: $selectedDay) {
            ForEach(1...7, id: \.self) { dayIndex in
                DayScheduleList(
                    dayIndex: dayIndex,
                    subjects: subjects,
                    calendarManager: calendarManager,
                    subjectToEdit: $subjectToEdit
                )
                .tag(dayIndex)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 16) {
                Button {
                    showingFileImporter = true
                } label: {
                    if isParsingPDF {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "doc.badge.gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
                .disabled(isParsingPDF)
                
                Button {
                    showingAddSubject = true
                } label: {
                    Image(systemName: "plus.app.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    // MARK: - BUSINESS LOGIC
    private func handleImportResult(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            isParsingPDF = true
            
            GeminiParserService.shared.parseSchedule(fileURL: selectedURL, studentGroup: studentGroup) { response in
                Task { @MainActor in
                    isParsingPDF = false
                    switch response {
                    case .success(let parsedSubjects):
                        for parsed in parsedSubjects {
                            let newSubject = Subject(
                                name: parsed.name,
                                type: parsed.type,
                                dayOfWeek: parsed.dayOfWeek,
                                startTime: parsed.convertToDate(timeString: parsed.startTime),
                                endTime: parsed.convertToDate(timeString: parsed.endTime),
                                room: parsed.room,
                                frequency: parsed.frequency,
                                totalHours: 14,
                                minRequired: 7
                            )
                            modelContext.insert(newSubject)
                        }
                        try? modelContext.save()
                        print("Successfully imported \(parsedSubjects.count) filtered classes for group \(studentGroup)!")
                        
                    case .failure(let error):
                        print("Gemini API Error: \(error.localizedDescription)")
                    }
                }
            }
        case .failure(let error):
            print("File Picker Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - LOGICĂ NOTIFICĂRI INTELIGENTE
    
    private func setupNotificationCategories() {
        let presentAction = UNNotificationAction(identifier: "CONFIRM_ACTION", title: "Yes", options: [.authenticationRequired])
        let absentAction = UNNotificationAction(identifier: "SKIP_ACTION", title: "No", options: [.destructive])
        
        // IMPORTANT: Use the same category identifier everywhere
        let category = UNNotificationCategory(
            identifier: "ATTENDANCE_CHECK_CATEGORY",
            actions: [presentAction, absentAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    private func rescheduleAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for subject in subjects {
            scheduleNotification(for: subject)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkPendingNotifications()
        }
    }
    
    private func scheduleNotification(for subject: Subject) {
        let content = UNMutableNotificationContent()
        content.title = "Did you attend \(subject.name)?"
        content.body = "Long press to mark your attendance for this \(subject.type)."
        // IMPORTANT: Match the category used by actions/extension
        content.categoryIdentifier = "ATTENDANCE_CHECK_CATEGORY"
        // IMPORTANT: Include SUBJECT_ID so the handler can find the Subject
        content.userInfo = ["SUBJECT_ID": subject.id.uuidString]
        content.sound = .default
        
        let calendarWeekday = subject.dayOfWeek == 7 ? 1 : subject.dayOfWeek + 1
        
        var components = Calendar.current.dateComponents([.hour, .minute], from: subject.endTime)
        components.weekday = calendarWeekday
        components.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let requestID = "\(subject.name)-\(subject.dayOfWeek)-\(components.hour ?? 0)\(components.minute ?? 0)"
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling for \(subject.name): \(error.localizedDescription)")
            }
        }
    }
    
    private func checkPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("\n====== 📅 TIMELINE ALERTE ACTIVE ÎN iOS: ======")
            if requests.isEmpty {
                print("❌ Coada este goală! Nicio notificare nu a fost programată.")
            }
            for request in requests {
                print("• Materie: \(request.content.title)")
                if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
                    let comps = calendarTrigger.dateComponents
                    print("  -> Fixată pentru Ziua calendaristică: \(comps.weekday ?? 0) (Sun=1, Mon=2, Sat=7) la Ora: \(comps.hour ?? 0):\(String(format: "%02d", comps.minute ?? 0))")
                }
            }
            print("================================================\n")
        }
    }
}

// MARK: - EXTRACTED DAY LIST VIEW
struct DayScheduleList: View {
    let dayIndex: Int
    let subjects: [Subject]
    let calendarManager: CalendarManager
    @Binding var subjectToEdit: Subject?
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        let daySubjects = subjects
            .filter { $0.dayOfWeek == dayIndex }
            .sorted { $0.startTime < $1.startTime }
        
        let dayEvents = calendarManager.weeklyEvents[dayIndex] ?? []
        
        List {
            if !daySubjects.isEmpty {
                Section {
                    ForEach(daySubjects) { subject in
                        ScheduleRow(subject: subject)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 25, style: .continuous))
                            .contextMenu {
                                Button {
                                    subjectToEdit = subject
                                } label: {
                                    Label("Edit Subject", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    modelContext.delete(subject)
                                } label: {
                                    Label("Delete Subject", systemImage: "trash")
                                }
                            } preview: {
                                ScheduleRow(subject: subject)
                                    .background(Color.terracottaBrownPalette)
                                    .cornerRadius(25)
                                    .frame(width: 350)
                            }
                    }
                } header: {
                    Text("University Classes")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            if calendarManager.isAuthorized && !dayEvents.isEmpty {
                Section {
                    ForEach(dayEvents, id: \.eventIdentifier) { event in
                        EventRow(event: event)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("Personal Calendar")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            if daySubjects.isEmpty && dayEvents.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.warmBeigePalette.opacity(0.4))
                    Text("No schedule today.\nEnjoy your free time!")
                        .font(.headline.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - ROWS
struct ScheduleRow: View {
    let subject: Subject
    @AppStorage("use24HourFormat") private var use24HourFormat = true
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = use24HourFormat ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Text(subject.name)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    
                    Text(subject.type.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.warmBeigePalette)
                        .cornerRadius(4)
                        .foregroundStyle(Color.terracottaBrownPalette)
                }
                Spacer()
                Text("\(formatTime(subject.startTime)) - \(formatTime(subject.endTime))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            if subject.frequency == "Every two weeks" {
                HStack(spacing: 4) {
                    Image(systemName: subject.isScheduledThisWeek ? "calendar.badge.checkmark" : "calendar.badge.minus")
                    Text(subject.isScheduledThisWeek ? "Takes place this week" : "No class this week (Next week)")
                }
                .font(.caption2.bold())
                .foregroundStyle(subject.isScheduledThisWeek ? Color.warmBeigePalette : .white.opacity(0.5))
                .padding(.vertical, 2)
            }
            
            if !subject.room.isEmpty {
                Text("Room \(subject.room)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            if let att = subject.mainAttendance {
                VStack(spacing: 6) {
                    ProgressView(value: Double(att.attended), total: Double(att.total))
                        .tint(Color.warmBeigePalette)
                        .background(Color.white.opacity(0.2))
                        .scaleEffect(x: 1, y: 1.2, anchor: .center)
                        .clipShape(Capsule())
                    
                    HStack {
                        Text("\(att.attended)/\(att.total)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                        Spacer()
                        Text("Skips left: \(subject.remainingSkips)")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(subject.remainingSkips > 0 ? Color.warmBeigePalette : Color.red)
                    }
                }
                .padding(.top, 5)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .opacity(subject.isScheduledThisWeek ? 1.0 : 0.55)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct EventRow: View {
    let event: EKEvent
    @AppStorage("use24HourFormat") private var use24HourFormat = true
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = use24HourFormat ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(event.calendar.cgColor))
                .frame(width: 5)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text(event.calendar.title)
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if event.isAllDay {
                    Text("All Day")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(formatTime(event.startDate))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(formatTime(event.endDate))")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(15)
        .background(.thinMaterial)
        .cornerRadius(18)
    }
}
