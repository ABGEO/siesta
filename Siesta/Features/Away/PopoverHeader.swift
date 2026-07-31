import SwiftUI

/// Shared popover title row with a status dot and a Settings gear.
struct PopoverHeader: View {
    let title: String
    let dotColor: Color

    var body: some View {
        HStack {
            Circle()
                .fill(dotColor)
                .frame(width: 9, height: 9)
            Text(title)
                .font(.headline)
            Spacer()
            Button {
                NotificationCenter.default.post(name: .siestaOpenSettings, object: nil)
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PopoverHeader(title: "Siesta", dotColor: .green)
        PopoverHeader(title: "You're away", dotColor: .orange)
    }
    .padding()
    .frame(width: 300)
}
