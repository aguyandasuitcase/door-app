import SwiftUI

struct LiveCard: View {
    @EnvironmentObject private var store: DoorStore
    var height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CameraPlaceholder()
            HStack(spacing: 10) {
                RoundGlassButton(systemName: "speaker.wave.2.fill", label: "Speaker")
                RoundGlassButton(systemName: "mic.fill", label: "Hold to talk")
            }
            .padding(12)
        }
        .overlay(alignment: .topLeading) {
            LiveChip(name: store.selectedStation.name).padding(12)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(8)
        .glassCard(cornerRadius: 36)
    }
}

/// Stand-in for the live video. Replace with the real video layer later.
struct CameraPlaceholder: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.655, green: 0.702, blue: 0.839),
                        Color(red: 0.459, green: 0.518, blue: 0.690),
                        Color(red: 0.290, green: 0.337, blue: 0.514)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.925, green: 0.937, blue: 0.984), Color(red: 0.718, green: 0.753, blue: 0.886)],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: geo.size.width * 0.34, height: geo.size.height * 0.78)
                    .shadow(color: .white.opacity(0.35), radius: 40)
            }
        }
        .accessibilityHidden(true)
    }
}

struct LiveChip: View {
    var name: String

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.red).frame(width: 8, height: 8)
            Text("\(name) · Live").font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassBackground(in: Capsule())
    }
}

struct RoundGlassButton: View {
    var systemName: String
    var label: String

    var body: some View {
        Button {
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .glassCircle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
