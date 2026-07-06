import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ConversionViewModel()
    @StateObject private var updateChecker = UpdateChecker()
    @AppStorage("autoCheckForUpdates") private var autoCheckForUpdates = true
    @AppStorage("hasShownStarPrompt") private var hasShownStarPrompt = false
    @AppStorage("appLanguage") private var appLanguageRaw = AppLanguage.systemDefault.rawValue
    @State private var isTargeted = false
    @State private var showFailureAlert = false
    @State private var showStarPrompt = false

    private var t: L { L(lang: AppLanguage(rawValue: appLanguageRaw) ?? .systemDefault) }

    var body: some View {
        VStack(spacing: 28) {
            HStack(alignment: .center, spacing: 20) {
                DropZoneView(fileName: viewModel.inputURL?.lastPathComponent, isTargeted: isTargeted, placeholder: t.dropFilePlaceholder)
                    .onTapGesture { pickFile() }
                    .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted, perform: handleDrop)

                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.tertiary)

                OutputPreviewView(status: viewModel.status)
            }

            HStack(spacing: 20) {
                FormatPicker(selection: $viewModel.inputFormat)
                    .frame(width: 150)
                Color.clear.frame(width: 18, height: 1)
                FormatPicker(selection: $viewModel.outputFormat)
                    .frame(width: 150)
            }

            Divider()

            bottomBar
        }
        .padding(32)
        .frame(minWidth: 440, minHeight: 360)
        .alert(t.conversionErrorTitle, isPresented: $showFailureAlert, presenting: failureMessage) { _ in
            Button(t.okButton, role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .onChange(of: statusFailed) { failed in
            showFailureAlert = failed
        }
        .alert(t.starPromptTitle, isPresented: $showStarPrompt) {
            Button(t.starPromptLater, role: .cancel) {}
            Button(t.starPromptStar) {
                NSWorkspace.shared.open(URL(string: "https://github.com/PavlovIvan1/converta")!)
            }
        } message: {
            Text(t.starPromptMessage)
        }
        .overlay(alignment: .topTrailing) {
            UpdateBannerView(checker: updateChecker)
        }
        .task {
            if autoCheckForUpdates {
                await updateChecker.checkForUpdates()
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.chooseOutputFolder()
            } label: {
                Image(systemName: "folder")
            }
            .help(viewModel.outputFolder?.path ?? t.chooseFolderTooltip)

            Text(viewModel.outputFolder?.lastPathComponent ?? t.outputFolderNotSelected)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 12)

            actionButton
                .frame(width: 190)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.status {
        case .converting:
            Button {} label: {
                HStack {
                    ProgressView().controlSize(.small)
                    Text(t.converting)
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(true)
            .controlSize(.large)
        case .done:
            Button {
                viewModel.revealOutputInFinder()
                promptForStarIfNeeded()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(t.showInFinder)
                }
                .frame(maxWidth: .infinity)
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
        default:
            Button {
                viewModel.convert()
            } label: {
                Text(t.convert)
                    .frame(maxWidth: .infinity)
            }
            .disabled(!viewModel.canConvert)
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
        }
    }

    private var statusFailed: Bool {
        if case .failed = viewModel.status { return true }
        return false
    }

    private func promptForStarIfNeeded() {
        guard !hasShownStarPrompt else { return }
        hasShownStarPrompt = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showStarPrompt = true
        }
    }

    private var failureMessage: String? {
        if case .failed(let message) = viewModel.status { return message }
        return nil
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.urls.first {
            viewModel.acceptFile(at: url)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async {
                viewModel.acceptFile(at: url)
            }
        }
        return true
    }
}

private struct DropZoneView: View {
    let fileName: String?
    let isTargeted: Bool
    let placeholder: String

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.4))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.gray.opacity(0.05))
            )
            .frame(width: 150, height: 150)
            .overlay {
                VStack(spacing: 10) {
                    Image(systemName: fileName == nil ? "arrow.down.doc" : "film.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text(fileName ?? placeholder)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
    }
}

private struct OutputPreviewView: View {
    let status: ConversionStatus
    @State private var isFlipped = false

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.gray.opacity(0.05))
            .frame(width: 150, height: 150)
            .overlay {
                Image(systemName: symbolName)
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 1, y: 0, z: 0)
                    )
            }
            .onChange(of: status) { newStatus in
                updateFlipping(for: newStatus)
            }
            .onAppear {
                updateFlipping(for: status)
            }
    }

    private func updateFlipping(for status: ConversionStatus) {
        if status == .converting {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                isFlipped = true
            }
        } else {
            withAnimation(.default) {
                isFlipped = false
            }
        }
    }

    private var symbolName: String {
        switch status {
        case .done: return "checkmark.circle.fill"
        case .converting: return "hourglass"
        default: return "film"
        }
    }
}

private struct FormatPicker: View {
    @Binding var selection: MediaFormat

    var body: some View {
        Menu {
            ForEach(MediaFormat.allCases) { format in
                Button(format.label) { selection = format }
            }
        } label: {
            Text(selection.label)
                .frame(maxWidth: .infinity)
        }
        .menuStyle(.borderedButton)
    }
}
