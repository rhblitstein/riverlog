import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void
    var isRecording: Bool = false

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isRecording ? "stop.fill" : "location.fill")
                    .font(.system(size: 18, weight: .semibold))

                Text(isRecording ? "Recording..." : "Record Trip")
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(isRecording ? Color.red : Color.accentColor)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .foregroundColor(.white)
            .scaleEffect(isPulsing && isRecording ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startPulsingAnimation()
            } else {
                stopPulsingAnimation()
            }
        }
        .onAppear {
            if isRecording {
                startPulsingAnimation()
            }
        }
    }

    private func startPulsingAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
        ) {
            isPulsing = true
        }
    }

    private func stopPulsingAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            isPulsing = false
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FloatingActionButton(action: {}, isRecording: false)
        FloatingActionButton(action: {}, isRecording: true)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
