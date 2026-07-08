import Foundation
import Observation

// MARK: - Language Enum
enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case japanese = "ja"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        }
    }
}

// MARK: - Language Manager
@Observable
final class LanguageManager {
    static let shared = LanguageManager()
    
    var selectedLanguage: Language {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "selected_language")
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "selected_language"),
           let lang = Language(rawValue: saved) {
            self.selectedLanguage = lang
        } else {
            // デフォルトはデバイスの言語に従う
            let preferred = Locale.preferredLanguages.first ?? "en"
            self.selectedLanguage = preferred.hasPrefix("ja") ? .japanese : .english
        }
    }
}
