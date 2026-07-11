import WidgetKit
import SwiftUI
import AppIntents

// MARK: - QuickCam Control Widget
/// iOS 18 のコントロールセンターおよびロック画面ショートカット用コントロール Widget
@main
struct QuickCamControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.hashinokuchishougo.QuickCam.Control"
        ) {
            ControlWidgetButton(action: LaunchQuickCamIntent()) {
                Label("QuickCam", systemImage: "video.fill")
            }
        }
        .displayName("QuickCam")
        .description("QuickCamを即起動して常時バッファ録画を開始します。")
    }
}
