import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastItem?

    @State private var dismissTask: Task<Void, Never>?
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if let toast, isVisible {
                    ToastView(item: toast) {
                        dismiss()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .padding(.top, 8)
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onEnded { value in
                                if value.translation.height < -10 {
                                    dismiss()
                                }
                            }
                    )
                }
            }
            .onChange(of: toast) { oldValue, newValue in
                dismissTask?.cancel()
                if newValue != nil {
                    withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                        isVisible = true
                    }
                    dismissTask = Task { @MainActor in
                        try? await Task.sleep(for: .seconds(3))
                        guard !Task.isCancelled else { return }
                        dismiss()
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.25)) {
                        isVisible = false
                    }
                }
            }
            .animation(.spring(duration: 0.35, bounce: 0.2), value: isVisible)
    }

    private func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) {
            isVisible = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            toast = nil
        }
    }
}

extension View {
    func toastOverlay(toast: Binding<ToastItem?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
