import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case ru, en

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        }
    }

    static var systemDefault: AppLanguage {
        Locale.current.language.languageCode?.identifier == "ru" ? .ru : .en
    }

    /// Reads the saved preference directly from UserDefaults, for use outside SwiftUI views
    /// (error enums, panel setup) where an `@AppStorage` binding isn't available.
    static var currentFromDefaults: AppLanguage {
        if let raw = UserDefaults.standard.string(forKey: "appLanguage"), let lang = AppLanguage(rawValue: raw) {
            return lang
        }
        return .systemDefault
    }
}

struct L {
    let lang: AppLanguage

    static var current: L { L(lang: .currentFromDefaults) }

    private func pick(_ ru: String, _ en: String) -> String {
        lang == .ru ? ru : en
    }

    var dropFilePlaceholder: String { pick("Перетащите файл", "Drop a file") }
    var convert: String { pick("Конвертировать", "Convert") }
    var converting: String { pick("Конвертация…", "Converting…") }
    var showInFinder: String { pick("Показать в Finder", "Show in Finder") }
    var conversionErrorTitle: String { pick("Ошибка конвертации", "Conversion Error") }
    var okButton: String { "OK" }
    var outputFolderNotSelected: String { pick("Папка не выбрана", "No folder selected") }
    var chooseFolderTooltip: String { pick("Выбрать папку вывода", "Choose output folder") }
    var chooseFolderPromptButton: String { pick("Выбрать", "Choose") }

    var starPromptTitle: String { pick("Нравится Converta?", "Enjoying Converta?") }
    var starPromptMessage: String {
        pick(
            "Если конвертер оказался полезным, поставьте звезду репозиторию на GitHub — это помогает другим найти проект.",
            "If the converter has been useful, please star the repo on GitHub — it helps others find the project."
        )
    }
    var starPromptLater: String { pick("Не сейчас", "Not now") }
    var starPromptStar: String { pick("Поставить звезду ⭐", "Star on GitHub ⭐") }

    var settingsFormatSection: String { pick("Формат по умолчанию", "Default format") }
    var settingsInputLabel: String { pick("Вход:", "Input:") }
    var settingsOutputLabel: String { pick("Выход:", "Output:") }
    var settingsGeneralSection: String { pick("Общие", "General") }
    var settingsLaunchAtLogin: String { pick("Запускать при входе в систему", "Launch at login") }
    var settingsNotifyOnCompletion: String { pick("Уведомлять по завершении конвертации", "Notify when conversion finishes") }
    var settingsAutoCheckUpdates: String { pick("Автоматически проверять обновления", "Automatically check for updates") }
    var settingsLanguageSection: String { pick("Язык", "Language") }
    var settingsLanguageLabel: String { pick("Язык приложения:", "App language:") }

    func updateBannerTitle(version: String) -> String { pick("Доступно обновление \(version)", "Update \(version) available") }
    var updateBannerNoNotes: String { pick("Список изменений недоступен.", "No release notes available.") }
    var updateBannerLater: String { pick("Позже", "Later") }
    var updateBannerOnGitHub: String { pick("На GitHub", "On GitHub") }
    var updateBannerUpdateButton: String { pick("Обновить", "Update") }
    var updateBannerDoneMessage: String { pick("Обновлено! Перезапустите Converta.", "Updated! Please restart Converta.") }

    var notificationTitle: String { pick("Конвертация завершена", "Conversion finished") }

    var ffmpegNotFound: String { pick("FFmpeg не найден. Установите его командой: brew install ffmpeg", "FFmpeg not found. Install it with: brew install ffmpeg") }
    var ffmpegFailedGeneric: String { pick("Конвертация не удалась.", "Conversion failed.") }
    var brewNotFound: String { pick("Homebrew не найден. Обновите вручную: brew upgrade --cask converta", "Homebrew not found. Update manually with: brew upgrade --cask converta") }
    var brewFailedGeneric: String { pick("Не удалось обновить приложение.", "Failed to update the app.") }
    var updateCheckerBadURL: String { pick("Некорректный адрес репозитория", "Invalid repository address") }
}
