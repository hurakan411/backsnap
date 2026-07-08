import SwiftUI
import AVFoundation
import AVKit

// MARK: - Video Player View (UIKit AVPlayerLayer ベース)
/// AVPlayerLayer を直接使用したビデオプレビュー。
/// SwiftUI の VideoPlayer コンポーネントの再生不可バグを回避します。

struct VideoPlayerView: View {
    let url: URL
    @Binding var currentTime: TimeInterval
    @Binding var isPlaying: Bool
    let duration: TimeInterval

    @State private var player: AVPlayer?
    @State private var timeObserver: Any?
    @State private var isFileReady = false

    var body: some View {
        ZStack {
            // 動画プレーヤー本体 (UIKit AVPlayerLayer ベース)
            if isFileReady, let player = player {
                AVPlayerLayerView(player: player)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    .allowsHitTesting(false) // タップ判定を遮らないようにする
            } else {
                // 読み込み待ち状態のプレースホルダー
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.inset)
                    .overlay(
                        VStack(spacing: AppTheme.Spacing.md) {
                            ProgressView()
                                .tint(.white)
                            Text(L10n.tr(.reviewLoadingVideo))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    )
            }

            // 再生/一時停止アイコン（ビジュアルのみ、タップはZStack全体で検知）
            if isFileReady {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .opacity(isPlaying ? 0.3 : 0.8)
                    .animation(.easeInOut(duration: 0.2), value: isPlaying)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isFileReady {
                togglePlayback()
            }
        }
        .task {
            print("[VideoPlayerView] 🟣 プレイヤーの起動 - 動画ロード開始: \(url.lastPathComponent)")
            await MainActor.run {
                isFileReady = true
                setupPlayer(with: url)
            }
        }
        .onDisappear {
            cleanupPlayer()
        }
        .onChange(of: currentTime) { _, newTime in
            seekTo(newTime)
        }
    }

    // MARK: - Player Setup
    private func setupPlayer(with targetURL: URL) {
        let asset = AVURLAsset(url: targetURL)
        let playerItem = AVPlayerItem(asset: asset)
        let avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer.actionAtItemEnd = .pause

        // 時間監視
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let seconds = time.seconds
            if !seconds.isNaN && !seconds.isInfinite {
                self.currentTime = seconds
            }
        }

        // 再生終了通知
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            isPlaying = false
        }

        self.player = avPlayer
    }

    private func cleanupPlayer() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player?.pause()
        player = nil
    }

    private func togglePlayback() {
        guard let player = player else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if currentTime >= duration - 0.1 {
                player.seek(to: .zero)
            }
            player.play()
            isPlaying = true
        }
        HapticFeedback.light()
    }

    private func seekTo(_ time: TimeInterval) {
        guard let player = player else { return }
        guard !isPlaying else { return }

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        // ドラッグ（シーク）中の詰まりを防ぐため、許容誤差を極小（0.05秒相当）に設定してデコードと描画を超高速化します
        let tolerance = CMTime(value: 3, timescale: 60)
        player.seek(to: cmTime, toleranceBefore: tolerance, toleranceAfter: tolerance)
    }
}

// MARK: - AVPlayerLayer UIView Wrapper
/// UIKit の AVPlayerLayer を SwiftUI にブリッジする UIViewRepresentable。
/// SwiftUI の VideoPlayer コンポーネントの再生不可バグを完全に回避します。
struct AVPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }

    class PlayerUIView: UIView {
        override class var layerClass: AnyClass {
            AVPlayerLayer.self
        }

        var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }
    }
}
