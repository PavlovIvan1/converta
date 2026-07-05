import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultInputFormat") private var defaultInputFormat = MediaFormat.webm.rawValue
    @AppStorage("defaultOutputFormat") private var defaultOutputFormat = MediaFormat.mp4.rawValue

    var body: some View {
        Form {
            Picker("Формат по умолчанию (вход):", selection: $defaultInputFormat) {
                ForEach(MediaFormat.allCases) { format in
                    Text(format.label).tag(format.rawValue)
                }
            }
            Picker("Формат по умолчанию (выход):", selection: $defaultOutputFormat) {
                ForEach(MediaFormat.allCases) { format in
                    Text(format.label).tag(format.rawValue)
                }
            }
        }
        .padding(24)
        .frame(width: 340)
    }
}
