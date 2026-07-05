import Foundation
import AppKit
import SwiftUI

enum ConversionStatus: Equatable {
    case idle
    case ready
    case converting
    case done
    case failed(String)
}

@MainActor
final class ConversionViewModel: ObservableObject {
    @AppStorage("defaultInputFormat") private var defaultInputFormatRaw = MediaFormat.webm.rawValue
    @AppStorage("defaultOutputFormat") private var defaultOutputFormatRaw = MediaFormat.mp4.rawValue
    @AppStorage("notifyOnCompletion") private var notifyOnCompletion = false

    @Published var inputURL: URL?
    @Published var inputFormat: MediaFormat = .webm
    @Published var outputFormat: MediaFormat = .mp4
    @Published var outputFolder: URL?
    @Published var status: ConversionStatus = .idle
    @Published var outputURL: URL?

    init() {
        inputFormat = MediaFormat(rawValue: defaultInputFormatRaw) ?? .webm
        outputFormat = MediaFormat(rawValue: defaultOutputFormatRaw) ?? .mp4
    }

    var canConvert: Bool {
        inputURL != nil && status != .converting
    }

    func acceptFile(at url: URL) {
        inputURL = url
        if let detected = MediaFormat.from(fileExtension: url.pathExtension) {
            inputFormat = detected
        }
        if outputFolder == nil {
            outputFolder = url.deletingLastPathComponent()
        }
        status = .ready
        outputURL = nil
    }

    func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Выбрать"
        if panel.runModal() == .OK, let url = panel.urls.first {
            outputFolder = url
        }
    }

    func convert() {
        guard let inputURL else { return }
        let folder = outputFolder ?? inputURL.deletingLastPathComponent()
        let baseName = inputURL.deletingPathExtension().lastPathComponent
        let destination = folder.appendingPathComponent("\(baseName).\(outputFormat.fileExtension)")

        status = .converting
        FFmpegRunner.convert(inputURL: inputURL, outputURL: destination) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let url):
                self.outputURL = url
                self.status = .done
                if self.notifyOnCompletion {
                    NotificationManager.notifyConversionFinished(fileName: url.lastPathComponent)
                }
            case .failure(let error):
                self.status = .failed(error.localizedDescription)
            }
        }
    }

    func revealOutputInFinder() {
        guard let outputURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }

    func reset() {
        inputURL = nil
        outputURL = nil
        status = .idle
    }
}
