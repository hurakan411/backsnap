import SwiftUI

// MARK: - Settings View
/// 設定画面
/// 最低限の設定（画質＆アプリ情報）のみ表示。コンパクトなヘッダー。

struct SettingsView: View {
    @Bindable var settings: AppSettings
    let onDismiss: () -> Void

    @State private var showTutorial = false
    @State private var languageManager = LanguageManager.shared
    
    // マットネイビーカラー（濃いめで落ち着きのあるシックな紺色）
    private let matteNavy = Color(red: 0.18, green: 0.30, blue: 0.52)

    var body: some View {
        ZStack {
            // 背景
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー（コンパクト化 + ノッチ裏背景自動伸長）
                header
                    .background(AppTheme.surface.ignoresSafeArea(edges: .top))

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // デフォルト設定
                        videoQualitySection

                        // アプリの言語
                        languageSection

                        // ストレージ管理
                        storageSection

                        // ヘルプ & ガイド
                        helpSection

                        // フィードバック
                        feedbackSection

                        // アプリ情報
                        appInfoSection
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
            }
        }
        .sheet(isPresented: $showTutorial) {
            OnboardingView(
                isPresentedAsTutorial: true,
                onComplete: {}
            )
        }
    }

    // MARK: - Header（コンパクト版 - 高さを48ptに固定ロック）
    private var header: some View {
        HStack {
            Button {
                settings.save()
                HapticFeedback.light()
                onDismiss()
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text(L10n.tr(.settingsBack))
                        .font(.system(size: 15))
                }
                .foregroundColor(AppTheme.textPrimary)
            }

            Spacer()

            Text(L10n.tr(.settingsTitle))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            // 戻るボタンとのバランス用透明スペーサー
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .frame(height: 48) // 高さを完全に48ptにロック
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Default Camera Configuration Section
    private var videoQualitySection: some View {
        settingsSection(title: L10n.tr(.settingsDefaultSettings), icon: "camera.badge.ellipsis") {
            VStack(spacing: AppTheme.Spacing.md) {
                // 1. デフォルト解像度 (HD vs 4K)
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(L10n.tr(.settingsResolution))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(["HD", "4K"], id: \.self) { res in
                            let isSelected = settings.defaultResolution == res
                            Button {
                                settings.defaultResolution = res
                                HapticFeedback.light()
                            } label: {
                                Text(res == "HD" ? "HD (1080p)" : "4K (2160p)")
                                    .font(AppTheme.Typography.button)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                            .fill(isSelected ? AppTheme.surface : AppTheme.inset)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                            .stroke(isSelected ? matteNavy.opacity(0.8) : Color.clear, lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // 2. デフォルトフレームレート (30 fps vs 60 fps)
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(L10n.tr(.settingsFps))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach([30, 60], id: \.self) { fps in
                            let isSelected = settings.defaultFPS == fps
                            Button {
                                settings.defaultFPS = fps
                                HapticFeedback.light()
                            } label: {
                                Text("\(fps) fps")
                                    .font(AppTheme.Typography.button)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                            .fill(isSelected ? AppTheme.surface : AppTheme.inset)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                            .stroke(isSelected ? matteNavy.opacity(0.8) : Color.clear, lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Storage Section
    private var storageSection: some View {
        settingsSection(title: L10n.tr(.settingsStorage), icon: "internaldrive.fill") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.tr(.settingsTempCache))
                        .font(AppTheme.Typography.button)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(L10n.tr(.settingsTempCacheDesc))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Text(settings.cacheSizeString)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.trailing, 8)
                
                Button {
                    settings.clearCache()
                    HapticFeedback.success()
                } label: {
                    Text(L10n.tr(.settingsDelete))
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .onAppear {
                settings.updateCacheSize()
            }
        }
    }

    // MARK: - Help & Guide Section
    private var helpSection: some View {
        settingsSection(title: L10n.tr(.settingsHelp), icon: "questionmark.circle.fill") {
            Button {
                showTutorial = true
                HapticFeedback.light()
            } label: {
                HStack {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 16))
                        .foregroundColor(matteNavy)
                    
                    Text(L10n.tr(.settingsHowTo))
                        .font(AppTheme.Typography.button)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textDim)
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(AppTheme.inset)
                )
            }
        }
    }

    // MARK: - Support & Feedback Section
    private var feedbackSection: some View {
        settingsSection(title: L10n.tr(.settingsSupport), icon: "heart.fill") {
            VStack(spacing: AppTheme.Spacing.sm) {
                // レビューボタン
                Button {
                    settings.openAppStoreReview()
                    HapticFeedback.light()
                } label: {
                    HStack {
                        Image(systemName: "star.bubble.fill")
                            .font(.system(size: 16))
                            .foregroundColor(matteNavy)
                        
                        Text(L10n.tr(.settingsReview))
                            .font(AppTheme.Typography.button)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textDim)
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.inset)
                    )
                }
                
                // お問い合わせボタン
                Button {
                    if let url = URL(string: "https://forms.gle/m6x2xoeiMjcnFhKs5") {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                    HapticFeedback.light()
                } label: {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 16))
                            .foregroundColor(matteNavy)
                        
                        Text(L10n.tr(.settingsContact))
                            .font(AppTheme.Typography.button)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward.app.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textDim)
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.inset)
                    )
                }
            }
        }
    }

    // MARK: - App Info
    private var appInfoSection: some View {
        settingsSection(title: L10n.tr(.settingsInfo), icon: "info.circle.fill") {
            VStack(spacing: AppTheme.Spacing.sm) {
                infoRow(title: L10n.tr(.settingsAppName), value: "QuickCam")
                infoRow(title: L10n.tr(.settingsVersion), value: "1.0.0 (MVP)")
                infoRow(title: L10n.tr(.settingsConcept), value: L10n.tr(.settingsConceptVal))
            }
        }
    }

    // MARK: - Language Picker Section
    private var languageSection: some View {
        settingsSection(title: L10n.tr(.settingsLanguage), icon: "globe") {
            HStack {
                Text(L10n.tr(.settingsLanguage))
                    .font(AppTheme.Typography.button)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Picker("", selection: $languageManager.selectedLanguage) {
                    ForEach(Language.allCases) { lang in
                        Text(lang.displayName)
                            .tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(matteNavy)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(AppTheme.inset)
            )
        }
    }

    // MARK: - Helper Views
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(matteNavy)
                Text(title)
                    .font(AppTheme.Typography.subtitle)
                    .foregroundColor(AppTheme.textPrimary)
            }

            content()
        }
        .padding(AppTheme.Spacing.md)
        .neumorphicRaised(cornerRadius: AppTheme.CornerRadius.large)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.vertical, 4)
    }
}
