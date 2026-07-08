import Foundation
import SwiftUI

// MARK: - Common Extensions

extension TimeInterval {
    /// 秒数をMM:SS形式のタイムコード文字列に変換
    var timecodeString: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// 秒数をM:SS.S形式（小数1桁付き）に変換
    var preciseTimecodeString: String {
        let minutes = Int(self) / 60
        let seconds = self.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%04.1f", minutes, seconds)
    }
}

extension Date {
    /// 時刻を HH:mm:ss 形式で返す
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: self)
    }
}

extension URL {
    /// 一時ディレクトリにユニークなファイル名を生成
    static func temporaryVideoURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
        let filename = "backsnap_\(UUID().uuidString).mov"
        return directory.appendingPathComponent(filename)
    }

    /// リングバッファ用ディレクトリ
    static var ringBufferDirectory: URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackSnapBuffer", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

extension View {
    /// ハプティックフィードバック（軽い衝撃）
    func hapticLight() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// ハプティックフィードバック（中程度の衝撃）
    func hapticMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// ハプティックフィードバック（強い衝撃）
    func hapticHeavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}

/// ハプティックフィードバックユーティリティ
enum HapticFeedback {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
