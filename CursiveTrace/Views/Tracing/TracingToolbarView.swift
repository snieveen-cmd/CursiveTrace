import SwiftUI

struct TracingToolbarView: View {
    let onClear: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button(action: onClear) {
                Label("Clear", systemImage: "trash")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(14)
            }

            Spacer()

            Button(action: onSubmit) {
                Label("Submit", systemImage: "checkmark.circle.fill")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(Color.indigo)
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
