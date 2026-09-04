import AppKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

extension CanvasView {
    /// Finder and other macOS sources expose image files through a mix of concrete UTIs and
    /// `public.file-url`. Keep the concrete formats explicit while `.image` admits future image
    /// types that conform to the system image supertype.
    static let imageDropTypes: [UTType] = [
        .image,
        .webP,
        .jpeg,
        .png,
        .bmp,
        .gif,
        .fileURL,
        .url
    ]

    /// Starts the same review flyout used by the toolbar/file-import path for an image dragged
    /// onto the canvas. Return `false` for unrelated drops so other system drop handlers can run.
    @discardableResult
    func handleImageDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { imageDropTypeIdentifier(for: $0) != nil }),
              let typeIdentifier = imageDropTypeIdentifier(for: provider) else {
            return false
        }

        if typeIdentifier == UTType.fileURL.identifier {
            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                let data = url.flatMap { try? Data(contentsOf: $0, options: .mappedIfSafe) }
                Task { @MainActor in
                    self.finishImageDrop(data: data, error: error)
                }
            }
        } else if typeIdentifier == UTType.url.identifier {
            provider.loadObject(ofClass: NSURL.self) { object, error in
                let url = object as? NSURL
                let data = url.flatMap { Self.fileData(for: $0 as URL) }
                Task { @MainActor in
                    self.finishImageDrop(data: data, error: error)
                }
            }
        } else {
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                Task { @MainActor in
                    self.finishImageDrop(data: data, error: error)
                }
            }
        }

        return true
    }

    private func imageDropTypeIdentifier(for provider: NSItemProvider) -> String? {
        if let imageIdentifier = provider.registeredTypeIdentifiers.first(where: { identifier in
            guard let type = UTType(identifier) else { return false }
            return type.conforms(to: .image)
        }) {
            return imageIdentifier
        }

        guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else {
            return provider.hasItemConformingToTypeIdentifier(UTType.url.identifier)
                ? UTType.url.identifier
                : nil
        }
        return UTType.fileURL.identifier
    }

    nonisolated private static func fileData(for url: URL) -> Data? {
        guard url.isFileURL else { return nil }
        return try? Data(contentsOf: url, options: .mappedIfSafe)
    }

    @MainActor
    private func finishImageDrop(data: Data?, error: Error?) {
        guard let data else {
            presentedError = .fileImportFailed(
                error?.localizedDescription ?? String(localized: "The dropped image could not be read.")
            )
            return
        }
        Task { await importImage(data: data, targetID: nil) }
    }

    func addLink(_ text: String) {
        let target = linkTargetCardID
        linkTargetCardID = nil
        guard let url = normalizedURL(text) else {
            presentedError = .invalidLink
            return
        }

        guard let target,
              let card = targetCard(target),
              card.isSupportedKind,
              card.kind == .image else {
            presentedError = .targetCardMissing
            return
        }
        selectedCardID = card.id
        card.urlString = url.absoluteString
    }

    func handleImageImport(_ result: Result<URL, Error>) {
        let target = imageTargetCardID
        imageTargetCardID = nil
        switch result {
        case .failure(let error):
            handleImageImportFailure(error)
        case .success(let url):
            Task { await importImage(from: url, targetID: target) }
        }
    }

    private func handleImageImportFailure(_ error: Error) {
        guard (error as NSError).code != NSUserCancelledError else { return }
        presentedError = .fileImportFailed(error.localizedDescription)
    }

    private func importImage(from url: URL, targetID: UUID?) async {
        do {
            let data = try await loadSecurityScopedData(from: url)
            await importImage(data: data, targetID: targetID)
        } catch ImageLoadingError.securityScopeDenied {
            presentedError = .imageAccessDenied
        } catch {
            presentedError = .fileImportFailed(error.localizedDescription)
        }
    }

    private func importImage(data: Data, targetID: UUID?) async {
        let requestID = UUID()
        imageProcessingRequestID = requestID
        imageProcessingTargetCardID = targetID
        imageProcessingSourceData = data
        imageProcessingCutoutData = nil
        imageProcessingPhase = .processing
        showImageProcessing = true

        let cutout = await Task.detached(priority: .userInitiated) {
            ImageSubjectCropper.crop(data: data)
        }.value

        // A cancelled or superseded request must never replace the current review state.
        guard imageProcessingRequestID == requestID else { return }
        imageProcessingCutoutData = cutout
        guard cutout != nil else {
            imageProcessingPhase = .unavailable
            return
        }

        // Keep the finding state on screen briefly after Vision returns so the contour and
        // moving grid can settle together before the still confirmation result appears.
        guard !accessibilityReduceMotion else {
            imageProcessingPhase = .ready
            return
        }
        try? await Task.sleep(nanoseconds: CopycolaColors.imageProcessingFindingNanoseconds)
        guard !Task.isCancelled, imageProcessingRequestID == requestID else { return }
        imageProcessingPhase = .settling

        try? await Task.sleep(nanoseconds: CopycolaColors.imageProcessingSettlingNanoseconds)
        guard !Task.isCancelled, imageProcessingRequestID == requestID else { return }
        imageProcessingPhase = .ready
    }

    func approvePendingImage() {
        guard imageProcessingPhase == .ready,
              let cutoutData = imageProcessingCutoutData else { return }

        if let targetID = imageProcessingTargetCardID {
            guard let card = targetCard(targetID),
                  !card.isDeleted,
                  card.isSupportedKind,
                  card.kind == .image else {
                presentedError = .targetCardMissing
                cancelImageProcessing()
                return
            }
            selectedCardID = card.id
            card.imageData = cutoutData
            card.imageRevision = UUID()
        } else {
            let card = newCard(.image)
            card.imageData = cutoutData
            card.imageRevision = UUID()
            selectedCardID = card.id
        }

        // Save synchronously so approval is the commit point for the permanent card collection.
        try? context.save()
        cancelImageProcessing()
    }

    func cancelImageProcessing() {
        showImageProcessing = false
    }

    func resetImageProcessing() {
        imageProcessingRequestID = nil
        imageProcessingTargetCardID = nil
        imageProcessingSourceData = nil
        imageProcessingCutoutData = nil
        imageProcessingPhase = .processing
    }

    /// Resolves a target id to an existing card, when a flow is editing rather than creating.
    func targetCard(_ id: UUID?) -> Card? {
        guard let id else { return nil }
        return board.cards.first { $0.id == id }
    }

    func cardForOperation(targetID: UUID?, kind: CardKind) -> Card? {
        guard let targetID else { return newCard(kind) }
        guard let card = targetCard(targetID), !card.isDeleted else {
            presentedError = .targetCardMissing
            return nil
        }
        return card
    }
}
