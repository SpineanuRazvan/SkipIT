import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("studentName") private var studentName = "Student"
    @AppStorage("studentGroup") private var studentGroup = ""
    @AppStorage("semesterStartDate") private var semesterStartDate = Date().timeIntervalSince1970
    @AppStorage("semesterEndDate") private var semesterEndDate = Date().addingTimeInterval(3600*24*7*14).timeIntervalSince1970
    
    @State private var currentTab = 0
    
    // Bindings pentru DatePicker-uri
    private var startBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: semesterStartDate) },
            set: { semesterStartDate = $0.timeIntervalSince1970 }
        )
    }
    private var endBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: semesterEndDate) },
            set: { semesterEndDate = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        ZStack {
            Color.warmBeigePalette.ignoresSafeArea()
            
            VStack {
                // Indicator de progres discret în partea de sus
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(currentTab == index ? Color.terracottaBrownPalette : Color.terracottaBrownPalette.opacity(0.2))
                            .frame(width: currentTab == index ? 20 : 7, height: 7)
                            .animation(.spring(), value: currentTab)
                    }
                }
                .padding(.top, 20)
                
                TabView(selection: $currentTab) {
                    // Slide 1: Welcome
                    OnboardingSlide(
                        title: "Welcome to SkipIT",
                        description: "The ultimate smart companion designed to streamline your university schedule and track your academic progress flawlessly.",
                        icon: "graduationcap.fill"
                    ).tag(0)
                    
                    // Slide 2: MODIFICAT - Evidențiere Import AI & Disclaimer de verificare manuală
                    OnboardingSlide(
                        title: "AI Schedule Import",
                        description: "Upload your schedule (PDF or photo) and let AI organize it instantly. Verify the generated data and manually enter the total classes and minimum required attendance for each subject.",
                        icon: "doc.badge.gearshape.fill"
                    ).tag(1)
                    
                    // Slide 3: Skip Predictor
                    OnboardingSlide(
                        title: "Predictive Attendance",
                        description: "Know exactly how many times you can safely skip each class. The app automatically groups your lectures and seminars and tracks your missing slots based on target criteria.",
                        icon: "chart.bar.doc.horizontal.fill"
                    ).tag(2)
                    
                    // Slide 4: Quick Setup Form
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 50))
                                .foregroundStyle(Color.dustyRosePalette)
                            Text("Quick Setup")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(Color.terracottaBrownPalette)
                            Text("Let's calibrate the predictive engine for your current semester.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.terracottaBrownPalette.opacity(0.7))
                                .padding(.horizontal, 20)
                        }
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 14) {
                                // Câmp Nume
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("YOUR NAME")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.terracottaBrownPalette.opacity(0.6))
                                    TextField("Enter your name", text: $studentName)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .foregroundStyle(Color.terracottaBrownPalette)
                                        .bold()
                                }
                                
                                // Câmp Grupa Studentului
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("YOUR STUDENT GROUP / SUBGROUP")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.terracottaBrownPalette.opacity(0.6))
                                    TextField("e.g., IR3, A1, Group 2", text: $studentGroup)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .foregroundStyle(Color.terracottaBrownPalette)
                                        .bold()
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.characters)
                                }
                                
                                // Câmp Început Semestru
                                DatePicker("Semester Start", selection: startBinding, displayedComponents: .date)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .foregroundStyle(Color.terracottaBrownPalette)
                                
                                // Câmp Sfârșit Semestru
                                DatePicker("Semester End", selection: endBinding, displayedComponents: .date)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .foregroundStyle(Color.terracottaBrownPalette)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                        }
                    }
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Butonul de navigare din partea de jos
                Button {
                    withAnimation {
                        if currentTab < 3 {
                            currentTab += 1
                        } else {
                            hasCompletedOnboarding = true
                        }
                    }
                } label: {
                    Text(currentTab == 3 ? "Get Started" : "Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.terracottaBrownPalette)
                        .cornerRadius(15)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 25)
                }
            }
        }
    }
}

// Sub-componentă refolosibilă pentru slide-uri vizuale clare
struct OnboardingSlide: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(Color.dustyRosePalette)
                .padding(.bottom, 10)
            
            Text(title)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.terracottaBrownPalette)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.terracottaBrownPalette.opacity(0.7))
                .padding(.horizontal, 32)
                .lineSpacing(4)
            
            Spacer()
        }
    }
}
