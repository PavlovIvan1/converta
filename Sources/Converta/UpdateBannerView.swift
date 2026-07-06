import SwiftUI
import AppKit

struct UpdateBannerView: View {
    @ObservedObject var checker: UpdateChecker
    @State private var isExpanded = false
    @State private var isUpdating = false
    @State private var updateResult: String?
    @AppStorage("dismissedUpdateVersion") private var dismissedVersion = ""
    @AppStorage("appLanguage") private var appLanguageRaw = AppLanguage.systemDefault.rawValue

    private var t: L { L(lang: AppLanguage(rawValue: appLanguageRaw) ?? .systemDefault) }

    var body: some View {
        if case .available(let version, let notes, let url) = checker.state, dismissedVersion != version {
            VStack(alignment: .leading, spacing: isExpanded ? 12 : 0) {
                header(version: version)
                if isExpanded {
                    expandedContent(version: version, notes: notes, url: url)
                }
            }
            .padding(isExpanded ? 16 : 12)
            .frame(width: isExpanded ? 300 : 260)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.secondary.opacity(0.15))
            )
            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            .padding(16)
            .transition(.move(edge: .trailing).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isExpanded)
        }
    }

    private func header(version: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(Color.accentColor)
            Text(t.updateBannerTitle(version: version))
                .font(.callout)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button {
                isExpanded.toggle()
            } label: {
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func expandedContent(version: String, notes: String, url: URL) -> some View {
        Divider()

        ScrollView {
            Text(notes.isEmpty ? t.updateBannerNoNotes : notes)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 140)

        if let updateResult {
            Text(updateResult)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        HStack {
            Button(t.updateBannerLater) {
                dismissedVersion = version
                isExpanded = false
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Button(t.updateBannerOnGitHub) {
                NSWorkspace.shared.open(url)
            }

            Button {
                runUpdate(version: version)
            } label: {
                if isUpdating {
                    ProgressView().controlSize(.small)
                } else {
                    Text(t.updateBannerUpdateButton)
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(isUpdating)
        }
        .font(.callout)
    }

    private func runUpdate(version: String) {
        isUpdating = true
        updateResult = nil
        BrewUpdater.upgrade { result in
            isUpdating = false
            switch result {
            case .success:
                updateResult = L.current.updateBannerDoneMessage
            case .failure(let error):
                updateResult = error.localizedDescription
            }
        }
    }
}
