import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultInputFormat") private var defaultInputFormat = MediaFormat.webm.rawValue
    @AppStorage("defaultOutputFormat") private var defaultOutputFormat = MediaFormat.mp4.rawValue
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("autoCheckForUpdates") private var autoCheckForUpdates = true
    @AppStorage("notifyOnCompletion") private var notifyOnCompletion = false
    @State private var loginItemError: String?

    var body: some View {
        Form {
            Section("Формат по умолчанию") {
                Picker("Вход:", selection: $defaultInputFormat) {
                    ForEach(MediaFormat.allCases) { format in
                        Text(format.label).tag(format.rawValue)
                    }
                }
                Picker("Выход:", selection: $defaultOutputFormat) {
                    ForEach(MediaFormat.allCases) { format in
                        Text(format.label).tag(format.rawValue)
                    }
                }
            }

            Section("Общие") {
                Toggle("Запускать при входе в систему", isOn: $launchAtLogin)
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

                Toggle("Уведомлять по завершении конвертации", isOn: $notifyOnCompletion)
                    .onChange(of: notifyOnCompletion) { newValue in
                        if newValue {
                            NotificationManager.requestAuthorizationIfNeeded()
                        }
                    }

                Toggle("Автоматически проверять обновления", isOn: $autoCheckForUpdates)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 320)
    }
}
