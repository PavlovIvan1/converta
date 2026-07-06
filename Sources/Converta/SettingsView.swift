import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultInputFormat") private var defaultInputFormat = MediaFormat.webm.rawValue
    @AppStorage("defaultOutputFormat") private var defaultOutputFormat = MediaFormat.mp4.rawValue
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("autoCheckForUpdates") private var autoCheckForUpdates = true
    @AppStorage("notifyOnCompletion") private var notifyOnCompletion = false
    @AppStorage("appLanguage") private var appLanguageRaw = AppLanguage.systemDefault.rawValue
    @State private var loginItemError: String?

    private var t: L { L(lang: AppLanguage(rawValue: appLanguageRaw) ?? .systemDefault) }

    var body: some View {
        Form {
            Section(t.settingsFormatSection) {
                Picker(t.settingsInputLabel, selection: $defaultInputFormat) {
                    ForEach(MediaFormat.allCases) { format in
                        Text(format.label).tag(format.rawValue)
                    }
                }
                Picker(t.settingsOutputLabel, selection: $defaultOutputFormat) {
                    ForEach(MediaFormat.allCases) { format in
                        Text(format.label).tag(format.rawValue)
                    }
                }
            }

            Section(t.settingsLanguageSection) {
                Picker(t.settingsLanguageLabel, selection: $appLanguageRaw) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }
            }

            Section(t.settingsGeneralSection) {
                Toggle(t.settingsLaunchAtLogin, isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        do {
                            try LoginItemManager.setEnabled(newValue)
                            loginItemError = nil
                        } catch {
                            loginItemError = error.localizedDescription
                            launchAtLogin.toggle()
                        }
                    }
                if let loginItemError {
                    Text(loginItemError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Toggle(t.settingsNotifyOnCompletion, isOn: $notifyOnCompletion)
                    .onChange(of: notifyOnCompletion) { newValue in
                        if newValue {
                            NotificationManager.requestAuthorizationIfNeeded()
                        }
                    }

                Toggle(t.settingsAutoCheckUpdates, isOn: $autoCheckForUpdates)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 360)
    }
}
