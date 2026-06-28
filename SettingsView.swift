import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Setări persistente
    @AppStorage("studentName") private var studentName = "Student"
    @AppStorage("studentGroup") private var studentGroup = "" // NOU: Editare grupă post-onboarding
    @AppStorage("use24HourFormat") private var use24HourFormat = true
    
    // Configurare Semestru
    @AppStorage("semesterStartDate") private var semesterStartDate = Date().timeIntervalSince1970
    @AppStorage("semesterEndDate") private var semesterEndDate = Date().addingTimeInterval(3600*24*7*14).timeIntervalSince1970
    
    @State private var showingResetAlert = false

    var body: some View {
        // Conversie automată între Double (stocat) și Date (afișat în Picker)
        let startBinding = Binding<Date>(
            get: { Date(timeIntervalSince1970: semesterStartDate) },
            set: { semesterStartDate = $0.timeIntervalSince1970 }
        )
        let endBinding = Binding<Date>(
            get: { Date(timeIntervalSince1970: semesterEndDate) },
            set: { semesterEndDate = $0.timeIntervalSince1970 }
        )

        ZStack {
            Color.warmBeigePalette.ignoresSafeArea()
            
            Form {
                Section(header: Text("Profile").foregroundStyle(Color.terracottaBrownPalette)) {
                    HStack {
                        Text("Your Name")
                            .foregroundStyle(Color.terracottaBrownPalette)
                        Spacer()
                        TextField("Enter name", text: $studentName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.terracottaBrownPalette)
                            .bold()
                    }
                    
                    // NOU: Câmpul pentru grupa studentului adăugat în Setări
                    HStack {
                        Text("Student Group")
                            .foregroundStyle(Color.terracottaBrownPalette)
                        Spacer()
                        TextField("e.g., IR3, A1", text: $studentGroup)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.terracottaBrownPalette)
                            .bold()
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                    }
                }
                .listRowBackground(Color.white.opacity(0.3))
                
                Section(header: Text("Semester Calendar").foregroundStyle(Color.terracottaBrownPalette)) {
                    DatePicker("Semester Start", selection: startBinding, displayedComponents: .date)
                        .foregroundStyle(Color.terracottaBrownPalette)
                    DatePicker("Semester End", selection: endBinding, displayedComponents: .date)
                        .foregroundStyle(Color.terracottaBrownPalette)
                }
                .listRowBackground(Color.white.opacity(0.3))
                
                Section(header: Text("Preferences").foregroundStyle(Color.terracottaBrownPalette)) {
                    Toggle("24-Hour Format", isOn: $use24HourFormat)
                        .tint(Color.dustyRosePalette)
                        .foregroundStyle(Color.terracottaBrownPalette)
                }
                .listRowBackground(Color.white.opacity(0.3))

                Section {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset All App Data")
                                .bold()
                            Spacer()
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.3))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .tint(Color.terracottaBrownPalette)
        .alert("Are you sure?", isPresented: $showingResetAlert) {
            Button("Delete Everything", role: .destructive) {
                resetData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your subjects, attendance logs, and exams. This action cannot be undone.")
        }
    }

    private func resetData() {
        try? modelContext.delete(model: Subject.self)
        try? modelContext.delete(model: Exam.self)
        studentName = "Student"
        studentGroup = "" // Curățăm și grupa la resetare
        semesterStartDate = Date().timeIntervalSince1970
        semesterEndDate = Date().addingTimeInterval(3600*24*7*14).timeIntervalSince1970
        print("All data has been wiped.")
    }
}
