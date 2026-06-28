import SwiftUI
import SwiftData

struct GradesView: View {
    @Query(sort: \Subject.name) var allSubjects: [Subject]
    
    var body: some View {
        ZStack {
            // Folosim sageGreenPalette pentru consistență
            Color.sageGreenPalette.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 15) {
                    let uniqueOnes = Dictionary(grouping: allSubjects, by: { $0.name })
                        .compactMap { $0.value.first }
                        .sorted { $0.name < $1.name }
                    
                    if uniqueOnes.isEmpty {
                        Text("No subjects found.")
                            .foregroundStyle(Color.terracottaBrownPalette.opacity(0.6))
                            .padding(.top, 100)
                    } else {
                        ForEach(uniqueOnes) { subject in
                            NavigationLink(destination: SubjectGradesDetailView(subject: subject)) {
                                SubjectSummaryCard(subject: subject)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Grades")
    }
}

struct SubjectSummaryCard: View {
    let subject: Subject
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(subject.name)
                    .font(.title3.bold())
                    .foregroundStyle(Color.terracottaBrownPalette)
                
                Text("Overall Average")
                    .font(.caption)
                    .foregroundStyle(Color.terracottaBrownPalette.opacity(0.7))
            }
            
            Spacer()
            
            Text(String(format: "%.2f", subject.finalGrade))
                .font(.system(size: 24, weight: .black, design: .rounded))
                // MODIFICARE: Folosim Color.appDeleteRed în loc de .red
                .foregroundStyle(subject.finalGrade >= 5 ? Color.terracottaBrownPalette : Color.appDeleteRed)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(LinearGradient(colors: [.white.opacity(1.0), .white.opacity(0.5)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        lineWidth: 1.5)
        )
    }
}
