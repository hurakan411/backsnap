import Foundation

// MARK: - Localized Strings Registry (L10n)
struct L10n {
    
    // MARK: - Keys Enum
    enum Key: String {
        // Common / Onboarding
        case skip = "common.skip"
        case next = "common.next"
        case closeTutorial = "common.closeTutorial"
        case startApp = "common.startApp"
        
        // Onboarding Pages
        case onboardingP1Title = "onboarding.p1.title"
        case onboardingP1Subtitle = "onboarding.p1.subtitle"
        case onboardingP1Description = "onboarding.p1.description"
        
        case onboardingP2Title = "onboarding.p2.title"
        case onboardingP2Subtitle = "onboarding.p2.subtitle"
        case onboardingP2Description = "onboarding.p2.description"
        
        case onboardingP3Title = "onboarding.p3.title"
        case onboardingP3Subtitle = "onboarding.p3.subtitle"
        case onboardingP3Description = "onboarding.p3.description"
        
        // Settings Screen
        case settingsTitle = "settings.title"
        case settingsBack = "settings.back"
        case settingsDefaultSettings = "settings.defaultSettings"
        case settingsResolution = "settings.resolution"
        case settingsFps = "settings.fps"
        case settingsStorage = "settings.storage"
        case settingsTempCache = "settings.tempCache"
        case settingsTempCacheDesc = "settings.tempCacheDesc"
        case settingsDelete = "settings.delete"
        case settingsHelp = "settings.help"
        case settingsHowTo = "settings.howTo"
        case settingsSupport = "settings.support"
        case settingsReview = "settings.review"
        case settingsContact = "settings.contact"
        case settingsInfo = "settings.info"
        case settingsAppName = "settings.appName"
        case settingsVersion = "settings.version"
        case settingsConcept = "settings.concept"
        case settingsConceptVal = "settings.conceptVal"
        case settingsLanguage = "settings.language"
        
        // Review Screen
        case reviewBack = "review.back"
        case reviewProcessing = "review.processing"
        case reviewTrimRange = "review.trimRange"
        case reviewModeVideo = "review.modeVideo"
        case reviewModePhoto = "review.modePhoto"
        case reviewSave = "review.save"
        case reviewSavePhoto = "review.savePhoto"
        case reviewShare = "review.share"
        case reviewSharePhoto = "review.sharePhoto"
        case reviewToastSaved = "review.toast.saved"
        case reviewToastSavedPhoto = "review.toast.savedPhoto"
        case reviewLoadingVideo = "review.loadingVideo"
        case reviewSeconds = "review.seconds"
        
        // Library Screen
        case libraryTitle = "library.title"
        case libraryClose = "library.close"
        case libraryNoVideos = "library.noVideos"
        case libraryNoAccess = "library.noAccess"
        case libraryAllowAccess = "library.allowAccess"
        case libraryLoading = "library.loading"
    }
    
    // MARK: - Translation Method
    /// 指定されたキーに対応する現在の言語の翻訳テキストを取得します
    static func tr(_ key: Key) -> String {
        let activeLang = LanguageManager.shared.selectedLanguage
        return translations[key.rawValue]?[activeLang] ?? translations[key.rawValue]?[.english] ?? key.rawValue
    }
    
    // MARK: - Translations Table
    private static let translations: [String: [Language: String]] = [
        // Common / Onboarding
        Key.skip.rawValue: [
            .japanese: "スキップ",
            .english: "Skip"
        ],
        Key.next.rawValue: [
            .japanese: "次へ",
            .english: "Next"
        ],
        Key.closeTutorial.rawValue: [
            .japanese: "使い方ガイドを閉じる",
            .english: "Close Guide"
        ],
        Key.startApp.rawValue: [
            .japanese: "QuickCamを始める",
            .english: "Start QuickCam"
        ],
        
        // Onboarding Slide 1
        Key.onboardingP1Title.rawValue: [
            .japanese: "こんなとき、困っていませんか？",
            .english: "Ever Had This Problem?"
        ],
        Key.onboardingP1Subtitle.rawValue: [
            .japanese: "撮り逃してしまった決定的瞬間",
            .english: "Missed the decisive moment"
        ],
        Key.onboardingP1Description.rawValue: [
            .japanese: "子供やペットの可愛い瞬間、\n突然起こるハプニング。\n「あ、今の撮りたかった！」と思った時には、\nもう終わっていた...\n\nそんな悔しい撮り逃しはありませんか？",
            .english: "A child's first success, a cute pet moment, or a sudden surprise.\nBy the time you think, 'I wanted to record that!', the moment has passed.\nHave you ever missed a precious memory like that?"
        ],
        
        // Onboarding Slide 2
        Key.onboardingP2Title.rawValue: [
            .japanese: "QuickCamで、過去を切り抜く",
            .english: "Save the Past with QuickCam"
        ],
        Key.onboardingP2Subtitle.rawValue: [
            .japanese: "「起きてから」押せば間に合うカメラ",
            .english: "A camera that catches up to the action"
        ],
        Key.onboardingP2Description.rawValue: [
            .japanese: "QuickCamは起動中、常に自動で録画しています。\n『今の撮れた？』と思ったらボタンを押すだけ。\n直前の数秒〜数分を過去に遡って、\n自動的にキャプチャします。",
            .english: "QuickCam is always recording while open.\nWhen you think, 'Did I catch that?', just press the button.\nIt retroactively captures the last few seconds to minutes."
        ],
        
        // Onboarding Slide 3
        Key.onboardingP3Title.rawValue: [
            .japanese: "動画も、写真も、思いのまま",
            .english: "Both Videos and Photos"
        ],
        Key.onboardingP3Subtitle.rawValue: [
            .japanese: "切り出し・保存・共有も自由自在",
            .english: "Easily trim, save, and share"
        ],
        Key.onboardingP3Description.rawValue: [
            .japanese: "キャプチャした動画を、\nミリ秒単位でトリミングすることはもちろん、\nスライダーを動かして「完璧な一コマ」を写真として保存・共有することも可能です。",
            .english: "Trim captured videos down to the millisecond, or slide through frames to save and share the 'perfect shot' as a high-quality photo."
        ],
        
        // Settings Screen
        Key.settingsTitle.rawValue: [
            .japanese: "設定",
            .english: "Settings"
        ],
        Key.settingsBack.rawValue: [
            .japanese: "戻る",
            .english: "Back"
        ],
        Key.settingsDefaultSettings.rawValue: [
            .japanese: "デフォルト撮影設定",
            .english: "Default Capture Settings"
        ],
        Key.settingsResolution.rawValue: [
            .japanese: "デフォルト解像度",
            .english: "Default Resolution"
        ],
        Key.settingsFps.rawValue: [
            .japanese: "デフォルトフレームレート",
            .english: "Default Frame Rate"
        ],
        Key.settingsStorage.rawValue: [
            .japanese: "ストレージ管理",
            .english: "Storage Management"
        ],
        Key.settingsTempCache.rawValue: [
            .japanese: "一時キャッシュ",
            .english: "Temp Cache"
        ],
        Key.settingsTempCacheDesc.rawValue: [
            .japanese: "撮影中の一時保存データ",
            .english: "Temporary recording cache"
        ],
        Key.settingsDelete.rawValue: [
            .japanese: "削除",
            .english: "Clear"
        ],
        Key.settingsHelp.rawValue: [
            .japanese: "ヘルプ & ガイド",
            .english: "Help & Guides"
        ],
        Key.settingsHowTo.rawValue: [
            .japanese: "使い方 (ガイド)",
            .english: "How to Use"
        ],
        Key.settingsSupport.rawValue: [
            .japanese: "サポート & フィードバック",
            .english: "Support & Feedback"
        ],
        Key.settingsReview.rawValue: [
            .japanese: "App Store でレビューを書く",
            .english: "Write a Review on App Store"
        ],
        Key.settingsContact.rawValue: [
            .japanese: "お問い合わせ・ご要望",
            .english: "Contact / Feedback"
        ],
        Key.settingsInfo.rawValue: [
            .japanese: "アプリ情報",
            .english: "App Information"
        ],
        Key.settingsAppName.rawValue: [
            .japanese: "アプリ名",
            .english: "App Name"
        ],
        Key.settingsVersion.rawValue: [
            .japanese: "バージョン",
            .english: "Version"
        ],
        Key.settingsConcept.rawValue: [
            .japanese: "コンセプト",
            .english: "Concept"
        ],
        Key.settingsConceptVal.rawValue: [
            .japanese: "\"今の撮れた？\"をなくすカメラ",
            .english: "A camera to eliminate \"Did I catch that?\""
        ],
        Key.settingsLanguage.rawValue: [
            .japanese: "アプリの言語",
            .english: "App Language"
        ],
        
        // Review Screen
        Key.reviewBack.rawValue: [
            .japanese: "戻る",
            .english: "Back"
        ],
        Key.reviewProcessing.rawValue: [
            .japanese: "動画を処理中...",
            .english: "Processing video..."
        ],
        Key.reviewTrimRange.rawValue: [
            .japanese: "切り取り範囲",
            .english: "Trim Range"
        ],
        Key.reviewModeVideo.rawValue: [
            .japanese: "ビデオ切り出し",
            .english: "Video Trim"
        ],
        Key.reviewModePhoto.rawValue: [
            .japanese: "写真フレーム",
            .english: "Photo Frame"
        ],
        Key.reviewSave.rawValue: [
            .japanese: "保存",
            .english: "Save"
        ],
        Key.reviewSavePhoto.rawValue: [
            .japanese: "写真を保存",
            .english: "Save Photo"
        ],
        Key.reviewShare.rawValue: [
            .japanese: "共有",
            .english: "Share"
        ],
        Key.reviewSharePhoto.rawValue: [
            .japanese: "写真を共有",
            .english: "Share Photo"
        ],
        Key.reviewToastSaved.rawValue: [
            .japanese: "ライブラリに保存しました",
            .english: "Saved to library"
        ],
        Key.reviewToastSavedPhoto.rawValue: [
            .japanese: "写真を保存しました",
            .english: "Photo saved"
        ],
        Key.reviewLoadingVideo.rawValue: [
            .japanese: "動画データを読み込み中...",
            .english: "Loading video data..."
        ],
        Key.reviewSeconds.rawValue: [
            .japanese: "秒",
            .english: "s"
        ],
        
        // Library Screen
        Key.libraryTitle.rawValue: [
            .japanese: "写真フォルダ",
            .english: "Library"
        ],
        Key.libraryClose.rawValue: [
            .japanese: "閉じる",
            .english: "Close"
        ],
        Key.libraryNoVideos.rawValue: [
            .japanese: "動画や写真がありません",
            .english: "No videos or photos"
        ],
        Key.libraryNoAccess.rawValue: [
            .japanese: "写真ライブラリへのアクセスが\n許可されていません",
            .english: "Access to photo library\nis not allowed"
        ],
        Key.libraryAllowAccess.rawValue: [
            .japanese: "「設定」アプリからアクセスを許可してください",
            .english: "Please allow access in the Settings app"
        ],
        Key.libraryLoading.rawValue: [
            .japanese: "読み込み中...",
            .english: "Loading..."
        ]
    ]
}
