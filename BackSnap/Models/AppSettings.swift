import Foundation
import Observation
import UIKit

// MARK: - App Settings
/// アプリ設定データモデル
/// kikakusyo.md セクション7.4 設定画面に準拠

/// アプリ設定を管理する Observable クラス
@Observable
final class AppSettings {
    /// デフォルトの解像度 ("HD" または "4K")
    var defaultResolution: String = "HD"

    /// デフォルトのフレームレート (30 または 60)
    var defaultFPS: Int = 30

    /// 初回起動時のオンボーディングが完了したかどうか
    var hasCompletedOnboarding: Bool = false

    // MARK: - Persistence
    private static let resolutionKey = "settings_default_resolution"
    private static let fpsKey = "settings_default_fps"
    private static let onboardingCompletedKey = "settings_onboarding_completed"

    init() {
        load()
    }

    /// 現在の一時保存ファイルの容量文字列 (例: "124.5 MB")
    var cacheSizeString: String = "0.0 MB"

    func save() {
        UserDefaults.standard.set(defaultResolution, forKey: Self.resolutionKey)
        UserDefaults.standard.set(defaultFPS, forKey: Self.fpsKey)
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.onboardingCompletedKey)
        print("[AppSettings] ✅ 設定を保存しました: 解像度=\(defaultResolution), FPS=\(defaultFPS), オンボーディング完了=\(hasCompletedOnboarding)")
    }

    func load() {
        if let res = UserDefaults.standard.string(forKey: Self.resolutionKey) {
            defaultResolution = res
        }
        let fps = UserDefaults.standard.integer(forKey: Self.fpsKey)
        if fps == 30 || fps == 60 {
            defaultFPS = fps
        }
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
        print("[AppSettings] ✅ 設定を読み込みました: 解像度=\(defaultResolution), FPS=\(defaultFPS), オンボーディング完了=\(hasCompletedOnboarding)")
        
        // 起動時にキャッシュ容量を計算
        updateCacheSize()
    }

    /// オンボーディングを完了状態にして保存する
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
        print("[AppSettings] 🚀 オンボーディング完了フラグを保存しました")
    }

    // MARK: - Cache Management
    /// キャッシュ（一時フォルダの動画）の容量を再計算
    func updateCacheSize() {
        let tempDir = FileManager.default.temporaryDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.fileSizeKey]) else {
            cacheSizeString = "0.0 MB"
            return
        }
        
        var totalSize: Int64 = 0
        for file in files {
            let name = file.lastPathComponent
            // BackSnapが生成した一時動画ファイルのみを合算
            if name.hasPrefix("captured_") || name.hasPrefix("backsnap_") {
                if let attrs = try? file.resourceValues(forKeys: [.fileSizeKey]),
                   let size = attrs.fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        
        if totalSize == 0 {
            cacheSizeString = "0 KB"
            return
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB, .useKB]
        formatter.countStyle = .file
        cacheSizeString = formatter.string(fromByteCount: totalSize)
    }

    /// キャッシュ（一時フォルダの動画）をすべて削除
    func clearCache() {
        let tempDir = FileManager.default.temporaryDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil) else {
            return
        }
        
        for file in files {
            let name = file.lastPathComponent
            if name.hasPrefix("captured_") || name.hasPrefix("backsnap_") {
                try? FileManager.default.removeItem(at: file)
            }
        }
        print("[AppSettings] 🧹 一時キャッシュファイルを削除しました")
        updateCacheSize()
    }

    // MARK: - App Store Review
    /// App Storeのレビュー画面へ遷移する
    func openAppStoreReview() {
        // ※ 本物のApp Store登録後に取得できるApple ID（例: "6444837861"）に置き換えてください。
        // 現在はダミーのID ("1234567890") を使用します。
        let appId = "1234567890"
        
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)?action=write-review") else { return }
        
        #if targetEnvironment(simulator)
        // シミュレータ環境ではブラウザのApp StoreプレビューURLで代替
        if let simUrl = URL(string: "https://apps.apple.com/app/id\(appId)?action=write-review") {
            importUIKitAndOpen(url: simUrl)
        }
        #else
        importUIKitAndOpen(url: url)
        #endif
    }
    
    private func importUIKitAndOpen(url: URL) {
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // ブラウザ用のフォールバックURL
                let fallbackId = "1234567890"
                if let webUrl = URL(string: "https://apps.apple.com/app/id\(fallbackId)?action=write-review") {
                    UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
                }
            }
        }
    }
}
