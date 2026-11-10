import SwiftUI

/// The hold-to-open control: a glass orb inside a progress ring.
struct HoldToOpenOrb: View {
    var state: UnlockState
    var size: CGFloat = 200
    var holdDuration: Double = 0.9
    var onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @GestureState private var isPressing = false

    private var ringWidth: CGFloat { size * 0.055 }
    private var isDone: Bool { state == .unlocked || state == .unlocking }
    private var ringColor: Color { state == .unlocked ? Theme.mintBright : Theme.violetSoft }
    private var iconName: String { state == .unlocked ? "lock.open.fill" : "lock.fill" }
    private var iconColor: Color { state == .unlocked ? Theme.mint : Theme.violet }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.violetSoft.opacity(0.18), lineWidth: ringWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: iconName)
                .font(.system(size: size * 0.32))
                .foregroundStyle(iconColor)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: size - ringWidth * 3, height: size - ringWidth * 3)
                .glassCircle()
        }
        .frame(width: size, height: size)
        .shadow(color: ringColor.opacity(0.28), radius: size * 0.12, y: size * 0.08)
        .contentShape(Circle())
        .gesture(
            LongPressGesture(minimumDuration: holdDuration)
                .updating($isPressing) { value, gestureState, _ in
                    gestureState = value
                }
                .onEnded { _ in
                    progress = 1
                    onComplete()
                }
        )
        .onChange(of: isPressing) { _, pressing in
            if pressing {
                withAnimation(.linear(duration: holdDuration)) { progress = 1 }
            } else if !isDone {
                withAnimation(.easeOut(duration: 0.25)) { progress = 0 }
            }
        }
        .onChange(of: state) { _, newState in
            if newState == .idle {
                withAnimation(.easeOut(duration: 0.3)) { progress = 0 }
            }
        }
        .sensoryFeedback(.success, trigger: state == .unlocked)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Open door")
        .accessibilityHint("Press and hold to unlock")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onComplete() }
    }
}
