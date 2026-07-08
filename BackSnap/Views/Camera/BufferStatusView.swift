import SwiftUI

// MARK: - Buffer Status View (モノトーン版)
/// 録画状態を表示するビュー。黒と白のみで構成されたミニマルなデザイン。

struct BufferStatusView: View {
    let currentSeconds: TimeInterval
    let maxSeconds: Int
    let isRecording: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                // 録画中の白丸インジケーター（点滅）
                Circle()
                    .fill(isRecording ? Color.white : AppTheme.textDim)
                    .frame(width: 8, height: 8)
                    .shadow(color: isRecording ? Color.white.opacity(0.6) : .clear, radius: 4)

                Text(isRecording ? "RECORDING..." : "STANDBY")
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .foregroundColor(isRecording ? Color.white : AppTheme.textSecondary)
                    .tracking(1)

                Spacer()

                // 録画経過秒数
                Text(currentSeconds.timecodeString)
                    .font(AppTheme.Typography.timecode)
                    .foregroundColor(Color.white)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        BufferStatusView(currentSeconds: 45.2, maxSeconds: 60, isRecording: true)
            .padding()
    }
}
