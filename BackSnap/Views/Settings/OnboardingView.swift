import SwiftUI

// MARK: - Onboarding View
/// App onboarding tutorial and usage guide (neumorphism & matte navy design)
struct OnboardingView: View {
    let isPresentedAsTutorial: Bool
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var languageManager = LanguageManager.shared
    
    private let totalPages = 3
    
    // 繝槭ャ繝医ロ繧､繝薙�繧ｫ繝ｩ繝ｼ�域ｿ�＞繧√〒關ｽ縺｡逹縺阪�縺ゅｋ繧ｷ繝�け縺ｪ邏ｺ濶ｲ��
    private let matteNavy = Color(red: 0.18, green: 0.30, blue: 0.52)

    var body: some View {
        ZStack {
            // 閭梧勹: 繝九Η繝ｼ繝｢繝ｼ繝輔ぅ繧ｺ繝�縺ｮ蝓ｺ譛ｬ閭梧勹濶ｲ
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: 繝倥ャ繝繝ｼ
                HStack {
                    Spacer()
                    if isPresentedAsTutorial {
                        Button {
                            HapticFeedback.light()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(20)
                        }
                    } else {
                        // 蛻晏屓襍ｷ蜍墓凾繧ｹ繧ｭ繝��
                        Button {
                            HapticFeedback.medium()
                            onComplete()
                        } label: {
                            Text(L10n.tr(.skip))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.white.opacity(0.3))
                                .padding(20)
                        }
                    }
                }
                .frame(height: 50)

                // MARK: 繝｡繧､繝ｳ繧ｹ繝ｩ繧､繝�
                TabView(selection: $currentPage) {
                    // 繝壹�繧ｸ1: 隱ｲ鬘梧署襍ｷ
                    onboardingPage(
                        imageName: "video.slash.fill",
                        title: L10n.tr(.onboardingP1Title),
                        subtitle: L10n.tr(.onboardingP1Subtitle),
                        description: L10n.tr(.onboardingP1Description),
                        tag: 0
                    )

                    // 繝壹�繧ｸ2: 隗｣豎ｺ繧ｳ繝ｳ繧ｻ繝励ヨ
                    onboardingPage(
                        imageName: "clock.arrow.2.circlepath",
                        title: L10n.tr(.onboardingP2Title),
                        subtitle: L10n.tr(.onboardingP2Subtitle),
                        description: L10n.tr(.onboardingP2Description),
                        tag: 1
                    )

                    // 繝壹�繧ｸ3: 蜈ｷ菴鍋噪縺ｪ讖溯�
                    onboardingPage(
                        imageName: "scissors.badge.ellipsis",
                        title: L10n.tr(.onboardingP3Title),
                        subtitle: L10n.tr(.onboardingP3Subtitle),
                        description: L10n.tr(.onboardingP3Description),
                        tag: 2
                    )
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentPage)

                // MARK: 繝輔ャ繧ｿ繝ｼ繧｢繧ｯ繧ｷ繝ｧ繝ｳ繧ｨ繝ｪ繧｢�医ル繝･繝ｼ繝｢繝ｼ繝輔ぅ繝�け繝懊ち繝ｳ��
                VStack(spacing: AppTheme.Spacing.md) {
                    if currentPage == totalPages - 1 {
                        // 譛邨ゅ�繝ｼ繧ｸ�壹悟ｧ九ａ繧九阪∪縺溘�縲碁哩縺倥ｋ縲�
                        Button {
                            HapticFeedback.heavy()
                            if isPresentedAsTutorial {
                                dismiss()
                            } else {
                                onComplete()
                            }
                        } label: {
                            Text(isPresentedAsTutorial ? L10n.tr(.closeTutorial) : L10n.tr(.startApp))
                                .font(AppTheme.Typography.button)
                                .fontWeight(.bold)
                                .foregroundColor(matteNavy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.lg)
                                .neumorphicRaised(cornerRadius: AppTheme.CornerRadius.medium)
                        }
                        .padding(.horizontal, 30)
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // 荳ｭ髢薙�繝ｼ繧ｸ�壹梧ｬ｡縺ｸ縲阪�繧ｿ繝ｳ
                        Button {
                            HapticFeedback.light()
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            HStack {
                                Text(L10n.tr(.next))
                                    .fontWeight(.bold)
                                Image(systemName: "chevron.right")
                                    .fontWeight(.bold)
                            }
                            .font(AppTheme.Typography.button)
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.lg)
                            .neumorphicRaised(cornerRadius: AppTheme.CornerRadius.medium)
                        }
                        .padding(.horizontal, 30)
                        .transition(.opacity)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Onboarding Page Component
    @ViewBuilder
    private func onboardingPage(
        imageName: String,
        title: String,
        subtitle: String,
        description: String,
        tag: Int
    ) -> some View {
        VStack(spacing: 30) {
            // 繝九Η繝ｼ繝｢繝ｼ繝輔ぅ繧ｺ繝��亥�蝙狗屁繧贋ｸ翫′繧奇ｼ峨い繧､繧ｳ繝ｳ繧ｳ繝ｳ繝�リ
            ZStack {
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 130, height: 130)
                    .neumorphicRaised(cornerRadius: 65)
                
                Image(systemName: imageName)
                    .font(.system(size: 44))
                    .foregroundColor(matteNavy)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(AppTheme.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(matteNavy)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Text(description)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .frame(maxHeight: 120, alignment: .top)

            Spacer()
        }
        .tag(tag)
    }
}
