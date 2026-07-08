import WidgetKit
import SwiftUI
import AppIntents

// MARK: - BackSnap Control Widget
/// iOS 18 のコントロールセンターおよびロック画面ショートカット用コントロール Widget
@main
struct BackSnapControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.hashinokuchishougo.BackSnap.Control"
        ) {
            ControlWidgetButton(action: LaunchBackSnapIntent()) {
                Label("BackSnap", systemImage: "video.fill")
            }
        }
        .displayName("BackSnap")
        .description("BackSnapを即起動して常時バッファ録画を開始します。")
    }
}
