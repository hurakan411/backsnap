import SwiftUI

// MARK: - BackSnap Button (iOS標準ビデオカメラ完全再現版)
/// 白い外枠の中に赤い丸があり、録画中(isRecording)になると赤い丸が角丸四角形へとアニメーション変形する、
/// iOS純正カメラのシャッターボタンを完全に再現したコンポーネント。

struct BackSnapButton: View {
    let isReady: Bool
    let isRecording: Bool // 録画中フラグを受け取る
    let action: () -> Void

    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 0

    private let outerSize: CGFloat = 76
    private let innerSizeNormal: CGFloat = 62
    private let innerSizeRecording: CGFloat = 30

    var body: some View {
        Button {
            triggerSnap()
        } label: {
            ZStack {
                // 外側の白い枠線
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .frame(width: outerSize, height: outerSize)

                // 外側へ広がるタップ時の赤波紋エフェクト
                Circle()
                    .fill(Color.red.opacity(rippleOpacity))
                    .frame(width: outerSize * rippleScale, height: outerSize * rippleScale)
                    .allowsHitTesting(false)

                // 内側の赤いマーク (録画状態に応じて丸から角丸四角へアニメーションモーフィング)
                RoundedRectangle(cornerRadius: isRecording ? 6 : innerSizeNormal / 2)
                    .fill(Color.red)
                    .frame(
                        width: isRecording ? innerSizeRecording : innerSizeNormal,
                        height: isRecording ? innerSizeRecording : innerSizeNormal
                    )
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isRecording)
            }
            .frame(width: outerSize, height: outerSize)
        }
        .buttonStyle(BackSnapShutterButtonStyle(isReady: isReady))
        .opacity(isReady ? 1.0 : 0.3)
    }

    // MARK: - Snap Trigger
    private func triggerSnap() {
        if !isReady {
            HapticFeedback.warning()
            return
        }

        HapticFeedback.heavy()

        // 波紋エフェクト
        rippleScale = 0.8
        rippleOpacity = 0.6
        withAnimation(.easeOut(duration: 0.5)) {
            rippleScale = 1.8
            rippleOpacity = 0
        }

        action()
    }
}

// MARK: - Shutter Button Style
struct BackSnapShutterButtonStyle: ButtonStyle {
    let isReady: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isReady ? 0.90 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
