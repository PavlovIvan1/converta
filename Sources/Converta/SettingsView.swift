import SwiftUI
import AppKit

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
        VStack(spacing: 0) {
            settingsForm
            footer
        }
        .frame(width: 380, height: 380)
    }

    private var settingsForm: some View {
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
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text(t.settingsFooterMadeWith)
            Button(t.settingsFooterStarLink) {
                NSWorkspace.shared.open(URL(string: "https://github.com/PavlovIvan1/converta")!)
            }
            .buttonStyle(.plain)
            .underline()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.bottom, 14)
    }
}
