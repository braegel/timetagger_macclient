import SwiftUI

struct ButtonMatrixView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("TimeTagger")
                .font(.headline)
            Text("Button Matrix — Phase 5")
                .foregroundStyle(.secondary)
        }
        .frame(width: 320, height: 400)
        .padding()
    }
}

#Preview {
    ButtonMatrixView()
}
