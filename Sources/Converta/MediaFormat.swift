import Foundation

enum MediaFormat: String, CaseIterable, Identifiable {
    case webm, mp4, mov, mkv, avi, gif

    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
    var fileExtension: String { rawValue }

    static func from(fileExtension ext: String) -> MediaFormat? {
        MediaFormat(rawValue: ext.lowercased())
    }
}
