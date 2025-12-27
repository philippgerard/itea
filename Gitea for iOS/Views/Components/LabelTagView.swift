import SwiftUI

struct LabelTagView: View {
    let label: Label

    var body: some View {
        Text(label.name)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(label.uiColor.opacity(0.2))
            .foregroundStyle(label.uiColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(label.uiColor, lineWidth: 1)
            )
    }
}

#Preview {
    LabelTagView(
        label: Label(
            id: 1,
            name: "bug",
            color: "d73a4a",
            description: nil
        )
    )
}
