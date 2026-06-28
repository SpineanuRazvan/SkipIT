import SwiftUI
import SwiftData
import WidgetKit

struct AttendanceDetailView: View {
    @Bindable var subject: Subject
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext // Pentru a salva modificările pe disc
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmBeigePalette.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 25) {
                        Text(subject.name).font(.title.bold()).foregroundStyle(Color.terracottaBrownPalette)
                        
                        ForEach(subject.attendanceDetails, id: \.self) { detail in
                            // Pasăm și obiectul subject pentru a cunoaște frecvența (Weekly / Every two weeks)
                            AttendanceEditorRow(subject: subject, detail: detail)
                        }
                        
                        Button("Save Changes") {
                            // Forțăm salvarea datelor și actualizarea widget-urilor la închidere
                            try? modelContext.save()
                            WidgetCenter.shared.reloadAllTimelines()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent).tint(Color.terracottaBrownPalette)
                    }.padding()
                }
            }
        }
    }
}

struct AttendanceEditorRow: View {
    let subject: Subject
    @Bindable var detail: AttendanceDetail
    
    // Stări pentru gestionarea alertei de Soft Cap
    @State private var showingAlert = false
    @State private var pendingValue = 0
    
    var body: some View {
        VStack {
            HStack {
                Text(detail.sessionType)
                Spacer()
                Text("\(detail.attended) / \(detail.total)").bold()
            }
            
            // Folosim un Binding personalizat pentru a valida valoarea înainte de a o salva
            Stepper("Adjust", value: Binding(
                get: { detail.attended },
                set: { newValue in
                    let currentWeek = SemesterManager.currentWeek
                    // Maximul teoretic acceptat pentru săptămâna curentă
                    let maxStandard = subject.frequency == "Weekly" ? currentWeek : (currentWeek + 1) / 2
                    
                    // Declanșăm alerta doar dacă este o CREȘTERE și depășește maximul teoretic al săptămânii
                    if newValue > detail.attended && newValue > maxStandard {
                        pendingValue = newValue
                        showingAlert = true
                    } else {
                        detail.attended = newValue
                    }
                }
            ), in: 0...detail.total)
        }
        .padding().background(Color.white.opacity(0.7)).cornerRadius(15)
        
        // Alerta soft-cap în limba engleză
        .alert("Extra Sessions?", isPresented: $showingAlert) {
            Button("Yes, add it") {
                detail.attended = pendingValue
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You are currently in Week \(SemesterManager.currentWeek), but trying to log attendance number \(pendingValue). Are you sure this was a recovery or extra class?")
        }
    }
}
