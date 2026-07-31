import SwiftUI

struct InfoSettingsView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var releaseNotesURL: URL {
        URL(string: "https://github.com/ABGEO/siesta/releases/tag/")!.appendingPathComponent("v\(version)")
    }

    private var tagline: String {
        "Siesta pauses your status across Slack and Google Calendar while you're away, and restores it when you're back."
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 8) {
                    if let icon = NSApplication.shared.applicationIconImage {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 64, height: 64)
                    }
                    Text("Siesta")
                        .font(.headline)
                    Text("Version v\(version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(tagline)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Links") {
                Link(destination: URL(string: "https://github.com/ABGEO/siesta")!) {
                    Label("View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/ABGEO/siesta/issues")!) {
                    Label("Report an Issue", systemImage: "ladybug")
                }
                Link(destination: releaseNotesURL) {
                    Label("Release Notes", systemImage: "tag")
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    InfoSettingsView()
        .frame(width: 460)
}
