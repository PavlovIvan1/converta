import Foundation

enum BrewError: LocalizedError {
    case notFound
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Homebrew не найден. Обновите вручную: brew upgrade --cask converta"
        case .failed(let message):
            return message.isEmpty ? "Не удалось обновить приложение." : message
        }
    }
}

enum BrewUpdater {
    static func locateBinary() -> String? {
        let candidates = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        return candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    }

    static func upgrade(completion: @escaping (Result<Void, BrewError>) -> Void) {
        guard let brew = locateBinary() else {
            completion(.failure(.notFound))
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: brew)
        process.arguments = ["upgrade", "--cask", "converta"]

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
                    completion(.success(()))
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
