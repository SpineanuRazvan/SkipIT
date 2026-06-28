import SwiftUI

struct SkipITLogoView: View {
    let porcelainMist = Color(red: 244/255, green: 241/255, blue: 234/255)
    
    var body: some View {
        ZStack {
            // Fundalul opțional (pentru testare sau Launch Screen)
            porcelainMist.ignoresSafeArea()
            
            VStack(spacing: 25) {
                // ICONIȚA
                ZStack {
                    // Baza iconiței - Gradient specific paletei tale
                    RoundedRectangle(cornerRadius: 35, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.dustyRosePalette, Color.terracottaBrownPalette],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        // Umbră minimalistă
                        .shadow(color: Color.terracottaBrownPalette.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Simbolul abstract (S + Checkmark) din interior
                    ZStack {
                        Capsule()
                            .fill(Color.goldenTanPalette)
                            .frame(width: 24, height: 70)
                            .rotationEffect(.degrees(40))
                            .offset(x: 12, y: -10)
                        
                        Capsule()
                            .fill(Color.warmBeigePalette)
                            .frame(width: 24, height: 45)
                            .rotationEffect(.degrees(-45))
                            .offset(x: -16, y: 12)
                    }
                }
                
                // TYPOGRAPHY
                HStack(spacing: 2) {
                    Text("Skip")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(Color.terracottaBrownPalette)
                    
                    Text("IT")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(Color.goldenTanPalette)
                }
                
                Text("Smart Attendance Tracking")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.terracottaBrownPalette.opacity(0.6))
                    .letterSpacing(1.5)
            }
        }
    }
}

// Extensie pentru a adăuga spațiere între litere ușor
extension View {
    func letterSpacing(_ spacing: CGFloat) -> some View {
        if #available(iOS 16.0, *) {
            return self.kerning(spacing)
        } else {
            return self
        }
    }
}

#Preview {
    SkipITLogoView()
}
