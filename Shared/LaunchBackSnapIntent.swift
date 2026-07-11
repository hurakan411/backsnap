import AppIntents

// MARK: - Launch Intent (共有)
/// コントロールセンターからアプリを即前面に起動するための App Intent。
/// メインアプリとコントロール Widget Extension の両方のターゲットに含める必要があります。
struct LaunchQuickCamIntent: AppIntent {
    static var title: LocalizedStringResource = "QuickCamを起動"
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
