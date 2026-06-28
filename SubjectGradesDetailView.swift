import SwiftUI
import SwiftData

struct SubjectGradesDetailView: View {
    @Bindable var subject: Subject
    @Query var allSubjects: [Subject]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Fundal Sage Green
            Color.sageGreenPalette.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- SECȚIUNEA 1: INPUT-URI (FIXED TOP) ---
                VStack(spacing: 25) {
                    // Card Ponderare
                    VStack(spacing: 20) {
                        Text("Grading Formula")
                            .font(.headline)
                            .foregroundStyle(Color.terracottaBrownPalette)
                        
                        VStack(spacing: 15) {
                            LinkedWeightRow(title: "Lecture Weight",
                                            weight: $subject.courseWeight,
                                            otherWeight: $subject.seminarWeight)
                            
                            LinkedWeightRow(title: "Seminar/Lab Weight",
                                            weight: $subject.seminarWeight,
                                            otherWeight: $subject.courseWeight)
                        }
                    }
                    .padding()
                    .background(.white.opacity(0.2))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(1.0), .white.opacity(0.5), .white.opacity(1.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )

                    // Card Note
                    VStack(spacing: 15) {
                        Text("Grades")
                            .font(.headline)
                            .foregroundStyle(Color.terracottaBrownPalette)
                        
                        GradeInputField(label: "Lecture Grade", value: $subject.courseGrade)
                        GradeInputField(label: "Seminar/Lab Grade", value: $subject.seminarGrade)
                    }
                    .padding()
                    .background(.white.opacity(0.2))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(1.0), .white.opacity(0.5), .white.opacity(1.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                // --- SECȚIUNEA 2: REZULTAT + BUTON (FIXED BOTTOM) ---
                VStack(spacing: 20) {
                    VStack(spacing: 5) {
                        Text("CALCULATED AVERAGE")
                            .font(.caption.bold())
                            .foregroundStyle(Color.terracottaBrownPalette.opacity(0.7))
                        
                        Text(String(format: "%.2f", subject.finalGrade))
                            .font(.system(size: 85, weight: .black, design: .rounded))
                            // AICI am pus roșul coral în loc de .red
                            .foregroundStyle(subject.finalGrade >= 5 ? Color.terracottaBrownPalette : Color.appDeleteRed)
                            .shadow(color: .black.opacity(0.1), radius: 10)
                    }
                    
                    Button(action: {
                        syncGradesToAllInstances()
                        dismiss()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.terracottaBrownPalette)
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func syncGradesToAllInstances() {
        for s in allSubjects where s.name == subject.name {
            s.courseGrade = subject.courseGrade
            s.seminarGrade = subject.seminarGrade
            s.courseWeight = subject.courseWeight
            s.seminarWeight = subject.seminarWeight
        }
    }
}

// MARK: - Componente ajutătoare (STRUCTURILE CARE LIPSEAU)

struct LinkedWeightRow: View {
    let title: String
    @Binding var weight: Double
    @Binding var otherWeight: Double
    
    var body: some View {
        HStack {
            Text(title).bold().foregroundStyle(Color.terracottaBrownPalette)
            Spacer()
            HStack(spacing: 15) {
                Button(action: {
                    if weight > 0.04 {
                        weight -= 0.05
                        otherWeight += 0.05
                    }
                }) {
                    Image(systemName: "minus.circle.fill").font(.title2)
                }
                
                Text("\(Int(round(weight * 100)))%")
                    .font(.system(.body, design: .monospaced).bold())
                    .frame(width: 50)
                
                Button(action: {
                    if weight < 0.96 {
                        weight += 0.05
                        otherWeight -= 0.05
                    }
                }) {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
            }
            .foregroundStyle(Color.terracottaBrownPalette)
        }
    }
}

struct GradeInputField: View {
    let label: String
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Color.terracottaBrownPalette).bold()
            Spacer()
            TextField("0.0", value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .padding(8)
                .background(.white.opacity(0.3))
                .cornerRadius(10)
                .foregroundStyle(Color.terracottaBrownPalette)
                .bold()
                .onChange(of: value) { _, newValue in
                    if newValue > 10 {
                        value = 10
                    } else if newValue < 0 {
                        value = 0
                    }
                }
        }
    }
}
