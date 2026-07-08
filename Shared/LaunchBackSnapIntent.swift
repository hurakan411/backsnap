import AppIntents

// MARK: - Launch Intent (共有)
/// コントロールセンターからアプリを即前面に起動するための App Intent。
/// メインアプリとコントロール Widget Extension の両方のターゲットに含める必要があります。
struct LaunchBackSnapIntent: AppIntent {
    static var title: LocalizedStringResource = "BackSnapを起動"
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
