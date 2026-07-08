import SwiftUI

// MARK: - BackSnap App Entry Point
/// アプリのエントリーポイント
/// kikakusyo.md に基づくスマートカメラアプリ

@main
struct BackSnapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("[BackSnapApp] 🌐 URLスキーム受信: \(url.absoluteString)")
                }
        }
    }
}
