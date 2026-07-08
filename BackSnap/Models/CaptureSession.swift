import Foundation

// MARK: - Recorded Video Model
/// 録画された動画のメタデータ。バッファリング名残のないシンプルな構造。

struct RecordedVideo: Identifiable {
    let id = UUID()
    /// 録画された動画ファイルのローカルURL
    let videoURL: URL
    /// 動画の合計再生時間（秒）
    let totalDuration: TimeInterval
    /// 録画完了時刻
    let capturedAt: Date
    /// 音声波形データ（プレビュー表示用）
    var waveformSamples: [Float] = []
    /// 各秒ごとのスコア情報
    var sceneScores: [SceneScore] = []
}

/// 各時刻のシーンスコア（波形レンダリング用）
struct SceneScore: Identifiable {
    let id = UUID()
    /// 相対時刻（秒）
    let timestamp: TimeInterval
    /// 総合スコア
    let totalScore: Double
    /// 検出されたシグナルの内訳
    let signals: [DetectedSignal]
}

/// 検出されたシグナル
struct DetectedSignal {
    let type: SignalType
    let score: Double
}

/// シグナルタイプ
enum SignalType: String, CaseIterable {
    case audioPeak = "audio_peak"
    case motionSpike = "motion_spike"
    case silentFlatAudio = "silent_flat_audio"
}
