import SwiftUI

struct GlassCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.warmBeigePalette)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(35)
        .overlay(
            RoundedRectangle(cornerRadius: 35)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(1.0), .white.opacity(0.5), .white.opacity(1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
    }
}
