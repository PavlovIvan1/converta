import Foundation

enum FFmpegError: LocalizedError {
    case notFound
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return L.current.ffmpegNotFound
        case .failed(let message):
            return message.isEmpty ? L.current.ffmpegFailedGeneric : message
        }
    }
}

struct FFmpegRunner {
    static func locateBinary() -> String? {
        let candidates = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/opt/local/bin/ffmpeg"
        ]
        if let found = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return found
        }

        let which = Process()
        which.executableURL = URL(fileURLWithPath: "/bin/zsh")
        which.arguments = ["-lc", "which ffmpeg"]
        let pipe = Pipe()
        which.standardOutput = pipe
        which.standardError = Pipe()
        do {
            try which.run()
            which.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let path, !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        } catch {
            return nil
        }
        return nil
    }

    static func convert(
        inputURL: URL,
        outputURL: URL,
        completion: @escaping (Result<URL, FFmpegError>) -> Void
    ) {
        guard let binary = locateBinary() else {
            completion(.failure(.notFound))
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = ["-y", "-i", inputURL.path, outputURL.path]

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()

        var stderrData = Data()
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            stderrData.append(handle.availableData)
        }

        process.terminationHandler = { finishedProcess in
            errorPipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async {
                if finishedProcess.terminationStatus == 0 {
                    completion(.success(outputURL))
                } else {
                    let message = String(data: stderrData, encoding: .utf8) ?? ""
                    completion(.failure(.failed(message)))
                }
            }
        }

        do {
            try process.run()
        } catch {
            completion(.failure(.failed(error.localizedDescription)))
        }
    }
}
