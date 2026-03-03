import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ComposerView: View {
    @Bindable var viewModel: SessionDetailViewModel
    @FocusState.Binding var isFocused: Bool

    @State private var showAttachmentMenu = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.pendingAttachments.isEmpty {
                attachmentPreviewStrip
            }

            HStack(alignment: .bottom, spacing: 8) {
                attachmentButton
                textField
                sendButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.separator, lineWidth: 0.5)
                }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 5 - viewModel.pendingAttachments.count,
            matching: .images
        )
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .onChange(of: selectedPhotos) { _, items in
            Task { await handlePhotoSelection(items) }
            selectedPhotos = []
        }
    }

    // MARK: - Subviews

    private var attachmentButton: some View {
        Button { showAttachmentMenu = true } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
        }
        .confirmationDialog("Add Attachment", isPresented: $showAttachmentMenu) {
            Button("Photo Library") { showPhotoPicker = true }
            Button("Choose File") { showFilePicker = true }
        }
    }

    private var textField: some View {
        TextField("Message Devin...", text: $viewModel.messageText, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(1...8)
            .focused($isFocused)
    }

    private var sendButton: some View {
        Button {
            Task { await viewModel.sendMessage() }
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    .white,
                    viewModel.canSend ? Color.devinGreen : .gray
                )
        }
        .disabled(!viewModel.canSend || viewModel.isSending)
    }

    private var attachmentPreviewStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.pendingAttachments) { attachment in
                    AttachmentThumbnailView(attachment: attachment) {
                        viewModel.removeAttachment(id: attachment.id)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }

    // MARK: - Handlers

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            let fileName = "photo_\(UUID().uuidString.prefix(8)).jpg"
            let thumbnail = generateThumbnail(from: data)
            viewModel.addAttachment(PendingAttachment(
                data: data,
                fileName: fileName,
                mimeType: "image/jpeg",
                thumbnail: thumbnail
            ))
        }
    }

    private func handleFileImport(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                guard let data = try? Data(contentsOf: url) else { continue }

                let ext = url.pathExtension.lowercased()
                let mimeType = UTType(filenameExtension: ext)?.preferredMIMEType ?? "application/octet-stream"
                let isImage = mimeType.hasPrefix("image/")
                let thumbnail = isImage ? generateThumbnail(from: data) : nil

                viewModel.addAttachment(PendingAttachment(
                    data: data,
                    fileName: url.lastPathComponent,
                    mimeType: mimeType,
                    thumbnail: thumbnail
                ))
            }
        case .failure:
            viewModel.toast = .error("Could not access selected files")
        }
    }

    private func generateThumbnail(from imageData: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: 120,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.jpegData(compressionQuality: 0.7)
    }
}
