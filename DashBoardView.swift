import SwiftUI

struct DashboardView: View {
    @AppStorage("studentName") private var studentName = "Student"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background: Terracotta Brown
                Color.terracottaBrownPalette.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    
                    // Updated card grid
                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            NavigationLink(destination: ScheduleView()) {
                                GlassCard(title: "SCHEDULE", subtitle: "Weekly Plan", icon: "calendar.badge.clock", color: .clear)
                            }
                            NavigationLink(destination: GradesView()) {
                                GlassCard(title: "GRADES", subtitle: "Calculator", icon: "chart.bar.fill", color: .clear)
                            }
                        }
                        
                        HStack(spacing: 20) {
                            NavigationLink(destination: ExamsView()) {
                                GlassCard(title: "EXAMS", subtitle: "Session", icon: "graduationcap.fill", color: .clear)
                            }
                            
                            NavigationLink(destination: AttendanceMainView()) {
                                GlassCard(title: "ATTENDANCE", subtitle: "Track Presence", icon: "checkmark.circle.fill", color: .clear)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
    }

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SkipIT")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Hello, \(studentName)!")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.warmBeigePalette)
        }
        .padding(.vertical, 25)
    }
}
