import SwiftUI
import AVFoundation

// MARK: - Timeline View (モノトーン・手動編集特化版)
/// 手動トリミングスライダー。AIサジェストやピークハイライトを完全に排除し、黒と白のみで構成されたミニマルなデザイン。

struct TimelineView: View {
    let duration: TimeInterval
    let waveformSamples: [Float]
    let scores: [SceneScore]          // 互換性のために残す（空配列を受け取る）
    let candidates: [SuggestCandidate] // 互換性のために残す（空配列を受け取る）
    let peakTimestamps: [TimeInterval] // 互換性のために残す（空配列を受け取る）

    @Binding var trimStart: TimeInterval
    @Binding var trimEnd: TimeInterval
    @Binding var currentTime: TimeInterval

    @State private var isDraggingStart = false
    @State private var isDraggingEnd = false
    @State private var isDraggingPlayhead = false

    private let timelineHeight: CGFloat = 56

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // タイムコード表示
            timecodeBar

            // メインタイムライン
            GeometryReader { geometry in
                let width = geometry.size.width

                ZStack(alignment: .leading) {
                    // 背景（沈み込み）
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(AppTheme.inset)

                    // 選択範囲のハイライト（白色）
                    let startX = width * (trimStart / max(0.01, duration))
                    let endX = width * (trimEnd / max(0.01, duration))
                    let selectedWidth = endX - startX

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: max(0, selectedWidth), height: timelineHeight)
                        .position(x: startX + selectedWidth / 2, y: timelineHeight / 2)
                        .overlay(
                            // 選択範囲の上下ボーダー
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                .frame(width: max(0, selectedWidth), height: timelineHeight)
                                .position(x: startX + selectedWidth / 2, y: timelineHeight / 2)
                        )

                    // 再生ヘッド
                    let playheadX = width * (currentTime / max(0.01, duration))
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2, height: timelineHeight + 12)
                        .position(x: playheadX, y: timelineHeight / 2)
                        .shadow(color: Color.white.opacity(0.5), radius: 3)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDraggingPlayhead = true
                                    let newTime = max(0, min(duration, duration * Double(value.location.x / width)))
                                    currentTime = newTime
                                }
                                .onEnded { _ in
                                    isDraggingPlayhead = false
                                }
                        )

                    // トリムハンドル: 開始点
                    TrimHandleView(type: .start, isActive: isDraggingStart)
                        .position(x: startX, y: timelineHeight / 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDraggingStart = true
                                    let newStart = max(0, min(trimEnd - 1, duration * Double(value.location.x / width)))
                                    trimStart = newStart
                                    HapticFeedback.light()
                                }
                                .onEnded { _ in
                                    isDraggingStart = false
                                }
                        )

                    // トリムハンドル: 終了点
                    TrimHandleView(type: .end, isActive: isDraggingEnd)
                        .position(x: endX, y: timelineHeight / 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDraggingEnd = true
                                    let newEnd = max(trimStart + 1, min(duration, duration * Double(value.location.x / width)))
                                    trimEnd = newEnd
                                    HapticFeedback.light()
                                }
                                .onEnded { _ in
                                    isDraggingEnd = false
                                }
                        )
                }
            }
            .frame(height: timelineHeight)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

            // 波形
            WaveformView(
                samples: waveformSamples,
                currentTime: currentTime,
                duration: duration,
                trimStart: trimStart,
                trimEnd: trimEnd
            )
        }
    }

    // MARK: - Timecode Bar
    private var timecodeBar: some View {
        HStack {
            // 選択範囲の開始
            Text(trimStart.preciseTimecodeString)
                .font(AppTheme.Typography.timecode)
                .foregroundColor(.white)

            Spacer()

            // クリップ長さ
            let clipLength = trimEnd - trimStart
            Text("\(clipLength.preciseTimecodeString)")
                .font(AppTheme.Typography.timecode)
                .foregroundColor(AppTheme.textPrimary)
            Text(L10n.tr(.reviewSeconds))
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.textSecondary)

            Spacer()

            // 選択範囲の終了
            Text(trimEnd.preciseTimecodeString)
                .font(AppTheme.Typography.timecode)
                .foregroundColor(.white)
        }
    }
}
