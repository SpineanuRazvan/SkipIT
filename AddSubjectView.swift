import SwiftUI
import SwiftData
import WidgetKit

struct AddSubjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    var subject: Subject?
    
    @State private var name: String
    @State private var type: String
    @State private var dayOfWeek: Int
    @State private var room: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var frequency: String
    @State private var totalAttendances: Int
    @State private var minRequired: Int
    
    @AppStorage("use24HourFormat") private var use24HourFormat = true
    
    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    let types = ["Lecture", "Seminar", "Lab"]
    let frequencies = ["Weekly", "Every two weeks"]

    let porcelainMist = Color(red: 244/255, green: 241/255, blue: 234/255)

    // 2. Am adăugat initialDay ca parametru care preia ziua curentă
    init(subject: Subject? = nil, initialDay: Int = 1) {
        self.subject = subject
        _name = State(initialValue: subject?.name ?? "")
        _type = State(initialValue: subject?.type ?? "Lecture")
        // Setăm ziua primită (sau pe cea salvată dacă edităm)
        _dayOfWeek = State(initialValue: subject?.dayOfWeek ?? initialDay)
        _room = State(initialValue: subject?.room ?? "")
        _startTime = State(initialValue: subject?.startTime ?? Date())
        _endTime = State(initialValue: subject?.endTime ?? Date().addingTimeInterval(7200))
        _frequency = State(initialValue: subject?.frequency ?? "Weekly")
        _totalAttendances = State(initialValue: subject?.mainAttendance?.total ?? 14)
        _minRequired = State(initialValue: subject?.minRequired ?? 7)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                porcelainMist.ignoresSafeArea()
                
                // 4. ScrollView pentru ca ecranul să urce când apare tastatura
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 15) {
                        // 1. SECTION: GENERAL
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GENERAL").font(.caption2.bold()).foregroundStyle(.secondary).padding(.leading, 15)
                            VStack(spacing: 0) {
                                TextField("Subject Name", text: $name).padding().background(Color.white)
                                Divider().padding(.leading, 15)
                                TextField("Room", text: $room).padding().background(Color.white)
                                Divider().padding(.leading, 15)
                                Picker("Type", selection: $type) {
                                    ForEach(types, id: \.self) { Text($0) }
                                }.pickerStyle(.segmented).padding(10).background(Color.white)
                            }
                            .cornerRadius(12).shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        }

                        // 2. SECTION: SCHEDULE
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SCHEDULE").font(.caption2.bold()).foregroundStyle(.secondary).padding(.leading, 15)
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Day")
                                    Spacer()
                                    Picker("Day", selection: $dayOfWeek) {
                                        ForEach(1...7, id: \.self) { i in Text(days[i-1]).tag(i) }
                                    }.pickerStyle(.menu)
                                }.padding().background(Color.white)
                                
                                Divider().padding(.leading, 15)
                                
                                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                                    .environment(\.locale, use24HourFormat ? Locale(identifier: "en_GB") : Locale(identifier: "en_US"))
                                    .padding().background(Color.white)
                                
                                Divider().padding(.leading, 15)

                                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                                    .environment(\.locale, use24HourFormat ? Locale(identifier: "en_GB") : Locale(identifier: "en_US"))
                                    .padding().background(Color.white)
                                
                                Divider().padding(.leading, 15)
                                
                                Picker("Frequency", selection: $frequency) {
                                    ForEach(frequencies, id: \.self) { Text($0) }
                                }.pickerStyle(.segmented).padding(10).background(Color.white)
                            }
                            .cornerRadius(12).shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        }

                        // 3. SECTION: ATTENDANCE DETAILS
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ATTENDANCE DETAILS").font(.caption2.bold()).foregroundStyle(.secondary).padding(.leading, 15)
                            VStack(spacing: 0) {
                                Stepper("Total: \(totalAttendances)", value: $totalAttendances, in: 1...30).padding().background(Color.white)
                                Divider().padding(.leading, 15)
                                Stepper("Min. Required: \(minRequired)", value: $minRequired, in: 0...totalAttendances).padding().background(Color.white)
                            }
                            .cornerRadius(12).shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        }
                        Spacer()
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively) // Ascunde tastatura frumos la scroll
            }
            .navigationTitle(subject == nil ? "Add Subject" : "Edit Subject").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundStyle(Color.dustyRosePalette) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.isEmpty).fontWeight(.bold).foregroundStyle(name.isEmpty ? .gray : Color.dustyRosePalette)
                }
            }
        }
    }

    func save() {
            if let subject = subject {
                subject.name = name
                subject.type = type
                subject.dayOfWeek = dayOfWeek
                subject.startTime = startTime
                subject.endTime = endTime
                subject.room = room
                subject.frequency = frequency
                subject.minRequired = minRequired
                subject.mainAttendance?.total = totalAttendances
            } else {
                let newSubject = Subject(name: name, type: type, dayOfWeek: dayOfWeek, startTime: startTime, endTime: endTime, room: room, frequency: frequency, totalHours: totalAttendances, minRequired: minRequired)
                modelContext.insert(newSubject)
            }
            
            // Forțăm salvarea și updatăm widget-urile instant
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            
            dismiss()
        }
}
