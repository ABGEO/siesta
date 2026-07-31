import SwiftUI

struct ServiceChip: View {
    let title: String
    var systemImage: String = "checkmark"
    var active: Bool = true

    var body: some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                active ? AnyShapeStyle(.green.opacity(0.16)) : AnyShapeStyle(.quaternary),
                in: .capsule
            )
            .foregroundStyle(active ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
    }
}

#Preview {
    HStack(spacing: 6) {
        ServiceChip(title: "Slack")
        ServiceChip(title: "Calendar")
        ServiceChip(title: "Offline", systemImage: "xmark", active: false)
    }
    .padding()
}
