import SwiftUI
import SwiftData

struct ExamsView: View {
    @Query(sort: \Exam.date) var exams: [Exam]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAddSheet = false
    @State private var examToEdit: Exam?
    @State private var examForGrading: Exam? // Examenul pe care l-am apăsat pentru notă

    var body: some View {
        ZStack {
            Color.dustyRosePalette.ignoresSafeArea()
            
            VStack(spacing: 0) {
                List {
                    if exams.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(exams) { exam in
                            ExamRow(exam: exam)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(Visibility.hidden)
                                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                .onTapGesture {
                                    examForGrading = exam // Deschidem meniul de notă la tap
                                }
                                .swipeActions(edge: HorizontalEdge.trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        modelContext.delete(exam)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(Color.appDeleteRed)
                                    
                                    Button {
                                        examToEdit = exam
                                        showingAddSheet = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(Color.goldenTanPalette)
                                }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Exam Session")
        .tint(.white)
        .toolbar {
            Button(action: {
                examToEdit = nil
                showingAddSheet = true
            }) {
                Image(systemName: "plus.app.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        // Meniul pentru adăugare/editare examen
        .sheet(isPresented: $showingAddSheet) {
            AddExamView(examToEdit: examToEdit)
        }
        // Meniul mic pentru introducere NOTĂ
        .sheet(item: $examForGrading) { exam in
            ExamGradeSheet(exam: exam)
                .presentationDetents([.height(300)]) // Îl facem mic, la baza ecranului
                .presentationDragIndicator(.visible)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(Color.warmBeigePalette.opacity(0.4))
            Text("No exams scheduled yet.\nTap + to add one.")
                .font(.headline.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(Visibility.hidden)
        .padding(.top, 100)
    }
}

// MARK: - Meniul Mic de Notare (Sheet)
struct ExamGradeSheet: View {
    @Bindable var exam: Exam
    @Environment(\.dismiss) var dismiss
    
    // Folosim un String pentru input ca să putem gestiona și punctul și virgula
    @State private var gradeInputString: String = ""
    
    var body: some View {
        ZStack {
            Color.warmBeigePalette.ignoresSafeArea()
            
            VStack(spacing: 25) {
                VStack(spacing: 8) {
                    Text("Final Result")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.terracottaBrownPalette.opacity(0.7))
                    
                    Text(exam.subjectName)
                        .font(.title2.bold())
                        .foregroundStyle(Color.terracottaBrownPalette)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 15) {
                    Text("Grade:")
                        .font(.headline)
                        .foregroundStyle(Color.terracottaBrownPalette)
                    
                    TextField("0.0", text: $gradeInputString)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(Color.terracottaBrownPalette)
                        .multilineTextAlignment(.center)
                        .frame(width: 140)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.4))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.terracottaBrownPalette.opacity(0.2), lineWidth: 1)
                        )
                        .onChange(of: gradeInputString) { _, newValue in
                            // Permitem doar cifre, punct și virgulă
                            let filtered = newValue.filter { "0123456789.,".contains($0) }
                            if filtered != newValue {
                                gradeInputString = filtered
                            }
                        }
                }
                Spacer(minLength: 0)
                
                Button(action: {
                    saveValidatedGrade()
                }) {
                    Text("Save Grade")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.terracottaBrownPalette)
                        .cornerRadius(18)
                }
            }
            .padding(30)
        }
        .onAppear {
            // Încărcăm nota existentă în câmpul de text
            if let existingGrade = exam.grade {
                gradeInputString = String(format: "%.1f", existingGrade).replacingOccurrences(of: ".", with: ",")
            }
        }
    }
    
    // Logica de procesare a notei înainte de salvare
    private func saveValidatedGrade() {
        // Înlocuim virgula cu punct pentru a putea face conversia în Double
        let normalizedString = gradeInputString.replacingOccurrences(of: ",", with: ".")
        
        if let finalValue = Double(normalizedString) {
            // Limităm între 0 și 10 (Clamping)
            let clampedValue = max(0, min(10, finalValue))
            exam.grade = clampedValue
            dismiss()
        } else if gradeInputString.isEmpty {
            // Dacă utilizatorul șterge tot, putem decide să lăsăm nota nil
            exam.grade = nil
            dismiss()
        }
    }
}

struct ExamRow: View {
    let exam: Exam
    @AppStorage("use24HourFormat") private var use24HourFormat = true
    
    var body: some View {
        HStack(spacing: 15) {
            // Date Badge (Codul anterior...)
            VStack {
                Text(exam.date.formatAsDay())
                    .font(.system(size: 25, weight: .black, design: .rounded))
                Text(exam.date.formatAsMonth())
                    .font(.caption2.bold())
                    .textCase(.uppercase)
            }
            .frame(width: 65, height: 65)
            .background(.white.opacity(0.25))
            .cornerRadius(18)
            .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(exam.subjectName)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                
                HStack(spacing: 8) {
                    Text(exam.type.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.warmBeigePalette)
                        .cornerRadius(6)
                        .foregroundStyle(Color.terracottaBrownPalette)
                    
                    Text("Room \(exam.room) • \(exam.date.formatTime(is24Hour: use24HourFormat))")
                        .font(.caption.bold())
                        .foregroundStyle(Color.warmBeigePalette)
                }
            }
            
            Spacer()
            
            // NOU: Afișăm nota în dreapta dacă există
            if let grade = exam.grade {
                Text(String(format: "%.1f", grade))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(grade >= 5 ? Color.white.opacity(0.2) : Color.red.opacity(0.4))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(1.0), .white.opacity(0.5), .white.opacity(1.0)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}
