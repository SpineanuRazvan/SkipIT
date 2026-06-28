import SwiftUI
import SwiftData
import WidgetKit

struct AttendanceMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subjects: [Subject]
    
    private var groupedSubjects: [String: [Subject]] {
        Dictionary(grouping: subjects, by: { $0.name })
    }
    
    private var sortedSubjectNames: [String] {
        groupedSubjects.keys.sorted()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmBeigePalette.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("My Progress")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(Color.terracottaBrownPalette)
                            .padding(.horizontal)
                        
                        if subjects.isEmpty {
                            ContentUnavailableView(
                                "No Subjects",
                                systemImage: "book.closed",
                                description: Text("Add subjects in the Schedule tab first.")
                            )
                            .padding(.top, 50)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(sortedSubjectNames, id: \.self) { name in
                                    if let componentSubjects = groupedSubjects[name] {
                                        AttendanceSummaryCard(subjectName: name, components: componentSubjects)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Attendance")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AttendanceSummaryCard: View {
    let subjectName: String
    let components: [Subject]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(subjectName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.terracottaBrownPalette)
                Spacer()
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.dustyRosePalette.opacity(0.6))
            }
            
            Divider()
                .background(Color.terracottaBrownPalette.opacity(0.1))
            
            VStack(spacing: 16) {
                ForEach(components.sorted(by: { $0.type < $1.type })) { subject in
                    NavigationLink(destination: AttendanceDetailView(subject: subject)) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(subject.type.uppercased())
                                    .font(.system(size: 11, weight: .black))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.dustyRosePalette.opacity(0.1))
                                    .foregroundStyle(Color.dustyRosePalette)
                                    .cornerRadius(6)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundStyle(Color.terracottaBrownPalette.opacity(0.3))
                            }
                            
                            ForEach(subject.attendanceDetails, id: \.self) { detail in
                                VStack(spacing: 8) {
                                    HStack {
                                        Text(detail.sessionType)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.terracottaBrownPalette.opacity(0.7))
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 4) {
                                            Text("\(detail.attended)")
                                                .font(.system(.subheadline, design: .rounded))
                                                .bold()
                                                .foregroundStyle(Color.goldenTanPalette)
                                            
                                            Text("/ \(subject.minRequired)")
                                                .font(.caption)
                                                .foregroundStyle(Color.terracottaBrownPalette.opacity(0.5))
                                        }
                                    }
                                    
                                    let progressTotal = subject.minRequired > 0 ? Double(subject.minRequired) : 1.0
                                    ProgressView(value: Double(detail.attended), total: progressTotal)
                                        .tint(Color.goldenTanPalette)
                                        .background(Color.terracottaBrownPalette.opacity(0.15))
                                        .scaleEffect(x: 1, y: 1.2, anchor: .center)
                                        .clipShape(Capsule())
                                    
                                    HStack {
                                        Spacer()
                                        Text("Available Skips: \(subject.remainingSkips)")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(subject.remainingSkips > 0 ? Color.sageGreenPalette : Color.appDeleteRed)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if subject.id != components.last?.id {
                        Divider()
                            .background(Color.terracottaBrownPalette.opacity(0.06))
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 5)
    }
}
