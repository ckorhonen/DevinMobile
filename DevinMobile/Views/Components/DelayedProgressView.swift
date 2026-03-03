import SwiftUI

struct DelayedProgressView: View {
    var delay: Duration = .milliseconds(150)

    @State private var isVisible = false

    var body: some View {
        Group {
            if isVisible {
                ProgressView()
            }
        }
        .task {
            try? await Task.sleep(for: delay)
            isVisible = true
        }
    }
}
