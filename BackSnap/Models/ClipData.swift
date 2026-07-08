import Foundation

// MARK: - Clip Data Model
/// 切り出しクリップのデータモデル
/// レビュー画面でのトリミング範囲管理に使用

struct ClipData: Identifiable {
    let id = UUID()
    /// 元のバッファ動画URL
    let sourceURL: URL
    /// バッファの合計秒数
    let sourceDuration: TimeInterval
    /// 切り出し開始時刻（秒）
    var startTime: TimeInterval
    /// 切り出し終了時刻（秒）
    var endTime: TimeInterval
    /// AIサジェストによる開始時刻（変更不可の参考値）
    let suggestedStartTime: TimeInterval
    /// AIサジェストによる終了時刻（変更不可の参考値）
    let suggestedEndTime: TimeInterval
    /// AIサジェストのピークスコア
    let peakScore: Double

    /// 切り出しクリップの秒数
    var clipDuration: TimeInterval {
        max(0, endTime - startTime)
    }

    /// AIサジェスト通りの範囲かどうか
    var isUsingAISuggestion: Bool {
        abs(startTime - suggestedStartTime) < 0.1 &&
        abs(endTime - suggestedEndTime) < 0.1
    }

    /// AIサジェスト範囲にリセット
    mutating func resetToAISuggestion() {
        startTime = suggestedStartTime
        endTime = suggestedEndTime
    }
}

/// AIサジェスト候補
struct SuggestCandidate: Identifiable {
    let id = UUID()
    /// ピーク時刻（秒）
    let peakTimestamp: TimeInterval
    /// スコア
    let score: Double
    /// 推奨開始時刻
    let startTime: TimeInterval
    /// 推奨終了時刻
    let endTime: TimeInterval
    /// ランク（1が最高）
    let rank: Int
}
