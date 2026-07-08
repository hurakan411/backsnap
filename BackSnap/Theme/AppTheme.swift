import SwiftUI

// MARK: - Color Palette
/// Dark Neumorphic & Cyber Gadget デザインシステム
/// kikakusyo.md セクション8.2 カラースキームに準拠
enum AppTheme {

    // MARK: Base Colors
    /// ベースカラー: 深みのあるダークチャコールグレー（ほのかに紫や青の温度感を持つ黒）
    static let background = Color(red: 0.09, green: 0.09, blue: 0.12)
    /// やや明るいサーフェス（カード、パネル用）
    static let surface = Color(red: 0.12, green: 0.12, blue: 0.16)
    /// サブカラー: 光を吸収するマットブラック（スライダー溝、トグル背景）
    static let inset = Color(red: 0.06, green: 0.06, blue: 0.08)

    // MARK: Accent Colors
    /// アクセントカラー: ネオンシアン（鮮やかな水色）
    static let neonCyan = Color(red: 0.0, green: 0.87, blue: 0.96)
    /// ディープパープル（グラデーション終点）
    static let deepPurple = Color(red: 0.47, green: 0.11, blue: 0.85)
    /// ネオンシアン → ディープパープル グラデーション
    static let accentGradient = LinearGradient(
        colors: [neonCyan, deepPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
    /// 縦方向グラデーション
    static let accentGradientVertical = LinearGradient(
        colors: [neonCyan, deepPurple],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: Text Colors
    /// プライマリテキスト: ホワイト（柔らかい白）
    static let textPrimary = Color(red: 0.93, green: 0.93, blue: 0.95)
    /// セカンダリテキスト: ライトグレー
    static let textSecondary = Color(red: 0.60, green: 0.60, blue: 0.65)
    /// ディム: 非常に薄いテキスト
    static let textDim = Color(red: 0.40, green: 0.40, blue: 0.45)

    // MARK: Semantic Colors
    /// 成功: グリーン
    static let success = Color(red: 0.20, green: 0.85, blue: 0.50)
    /// 警告: アンバー
    static let warning = Color(red: 0.95, green: 0.70, blue: 0.20)
    /// エラー: レッド
    static let error = Color(red: 0.95, green: 0.25, blue: 0.30)

    // MARK: Shadow Colors
    /// ニューモーフィック ライトシャドウ（明るい方）
    static let shadowLight = Color(red: 0.16, green: 0.16, blue: 0.20)
    /// ニューモーフィック ダークシャドウ（暗い方）
    static let shadowDark = Color(red: 0.03, green: 0.03, blue: 0.05)

    // MARK: - Typography
    /// タイポグラフィ: SF Pro ベース（Light / Regular / Bold）
    enum Typography {
        /// 大見出し（Bold）
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
        /// 見出し
        static let title = Font.system(size: 22, weight: .semibold, design: .default)
        /// サブ見出し
        static let subtitle = Font.system(size: 17, weight: .regular, design: .default)
        /// 本文
        static let body = Font.system(size: 15, weight: .light, design: .default)
        /// キャプション
        static let caption = Font.system(size: 12, weight: .light, design: .default)
        /// タイムコード表示（等幅・Bold）
        static let timecode = Font.system(size: 14, weight: .bold, design: .monospaced)
        /// ボタンラベル
        static let button = Font.system(size: 16, weight: .medium, design: .default)
        /// BackSnap ロゴ（Bold）
        static let logo = Font.system(size: 20, weight: .bold, design: .default)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let pill: CGFloat = 100
    }

    // MARK: - Animation
    enum Animation {
        /// 呼吸アニメーション: ゆっくりした往復
        static let breathing = SwiftUI.Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        /// ボタン押下: 素早い沈み込み
        static let press = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.6)
        /// 波紋: 拡散
        static let ripple = SwiftUI.Animation.easeOut(duration: 0.6)
        /// 画面遷移: フェード
        static let transition = SwiftUI.Animation.easeInOut(duration: 0.35)
    }
}
