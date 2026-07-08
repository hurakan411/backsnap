import SwiftUI

// MARK: - Waveform View (モノトーン・手動編集特化版)
/// 音声波形表示ビュー。AIピーク表示を排除し、白と黒のみで構成されています。

struct WaveformView: View {
    let samples: [Float]
    let currentTime: TimeInterval
    let duration: TimeInterval
    let trimStart: TimeInterval
    let trimEnd: TimeInterval

    /// 波形の高さ
    private let waveformHeight: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                // 背景（沈み込み）
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(AppTheme.inset)

                // 波形バー
                HStack(alignment: .center, spacing: 1) {
                    ForEach(0..<samples.count, id: \.self) { index in
                        let sample = CGFloat(samples[index])
                        let barTimestamp = duration * Double(index) / Double(samples.count)
                        let isInTrimRange = barTimestamp >= trimStart && barTimestamp <= trimEnd

                        RoundedRectangle(cornerRadius: 1)
                            .fill(barColor(isInTrimRange: isInTrimRange, sample: sample))
                            .frame(
                                width: max(1, (width - CGFloat(samples.count)) / CGFloat(samples.count)),
                                height: max(2, sample * waveformHeight)
                            )
                    }
                }
                .frame(height: waveformHeight)

                // 再生位置インジケーター
                let playheadX = width * (currentTime / max(0.01, duration))
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 1.5, height: waveformHeight + 4)
                    .position(x: playheadX, y: waveformHeight / 2)
                    .shadow(color: Color.white.opacity(0.5), radius: 2)
            }
        }
        .frame(height: waveformHeight)
    }

    private func barColor(isInTrimRange: Bool, sample: CGFloat) -> Color {
        if isInTrimRange {
            return sample > 0.7 ? Color.white : Color.white.opacity(0.6)
        } else {
            return AppTheme.textDim.opacity(0.3)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()

        WaveformView(
            samples: (0..<200).map { _ in Float.random(in: 0...1) },
            currentTime: 15,
            duration: 60,
            trimStart: 10,
            trimEnd: 20
        )
        .padding()
    }
}
