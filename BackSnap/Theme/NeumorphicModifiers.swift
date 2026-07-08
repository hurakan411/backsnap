import SwiftUI

// MARK: - Neumorphic View Modifiers
/// kikakusyo.md セクション8.3 UIシェイプと質感に準拠
/// 隆起・沈み込み・グロー・呼吸アニメーションを提供

/// 隆起エフェクト（外側ソフトシャドウ）
/// ボタンやパネルが背景から「滑らかに盛り上がっている」ように表現
struct NeumorphicRaisedModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.surface)
                    .shadow(color: AppTheme.shadowLight, radius: 8, x: -4, y: -4)
                    .shadow(color: AppTheme.shadowDark, radius: 8, x: 4, y: 4)
            )
    }
}

/// 沈み込みエフェクト（内側インセットシャドウ）
/// 要素が「削り取られて沈み込んでいる」ように表現
struct NeumorphicSunkenModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.inset)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppTheme.shadowDark, lineWidth: 1)
                            .shadow(color: AppTheme.shadowDark, radius: 4, x: 2, y: 2)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppTheme.shadowLight.opacity(0.3), lineWidth: 0.5)
                            .offset(x: -1, y: -1)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    )
            )
    }
}

/// ネオングローエフェクト
/// パーツの底面からシアンのネオンライトがじんわり漏れ出る
struct NeonGlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat
    var intensity: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6 * intensity), radius: radius * 0.5, x: 0, y: 0)
            .shadow(color: color.opacity(0.3 * intensity), radius: radius, x: 0, y: 2)
            .shadow(color: color.opacity(0.15 * intensity), radius: radius * 1.5, x: 0, y: 4)
    }
}

/// 呼吸アニメーション（グロー強度の明滅）
struct BreathingGlowModifier: ViewModifier {
    var color: Color
    var minRadius: CGFloat
    var maxRadius: CGFloat
    @State private var isBreathing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isBreathing ? 0.6 : 0.2),
                radius: isBreathing ? maxRadius : minRadius,
                x: 0, y: 0
            )
            .shadow(
                color: color.opacity(isBreathing ? 0.3 : 0.1),
                radius: isBreathing ? maxRadius * 1.5 : minRadius,
                x: 0, y: 2
            )
            .onAppear {
                withAnimation(AppTheme.Animation.breathing) {
                    isBreathing = true
                }
            }
    }
}

/// 波紋エフェクト（タップ時に広がるシアンの波紋）
struct RippleEffectModifier: ViewModifier {
    @Binding var trigger: Bool
    var color: Color

    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(color.opacity(rippleOpacity))
                    .scaleEffect(rippleScale)
                    .allowsHitTesting(false)
            )
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    rippleScale = 0.3
                    rippleOpacity = 0.5
                    withAnimation(AppTheme.Animation.ripple) {
                        rippleScale = 2.5
                        rippleOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        trigger = false
                    }
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    /// 隆起（盛り上がり）エフェクト
    func neumorphicRaised(cornerRadius: CGFloat = AppTheme.CornerRadius.medium) -> some View {
        modifier(NeumorphicRaisedModifier(cornerRadius: cornerRadius))
    }

    /// 沈み込み（凹み）エフェクト
    func neumorphicSunken(cornerRadius: CGFloat = AppTheme.CornerRadius.medium) -> some View {
        modifier(NeumorphicSunkenModifier(cornerRadius: cornerRadius))
    }

    /// ネオングロー
    func neonGlow(
        color: Color = AppTheme.neonCyan,
        radius: CGFloat = 10,
        intensity: CGFloat = 1.0
    ) -> some View {
        modifier(NeonGlowModifier(color: color, radius: radius, intensity: intensity))
    }

    /// 呼吸するグロー
    func breathingGlow(
        color: Color = AppTheme.neonCyan,
        minRadius: CGFloat = 4,
        maxRadius: CGFloat = 16
    ) -> some View {
        modifier(BreathingGlowModifier(color: color, minRadius: minRadius, maxRadius: maxRadius))
    }

    /// 波紋エフェクト
    func rippleEffect(trigger: Binding<Bool>, color: Color = AppTheme.neonCyan) -> some View {
        modifier(RippleEffectModifier(trigger: trigger, color: color))
    }
}
