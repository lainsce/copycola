import SwiftUI
import SwiftData
import UniformTypeIdentifiers

extension CanvasView {
    func addLink(_ text: String) {
        let target = linkTargetCardID
        linkTargetCardID = nil
        guard let url = normalizedURL(text) else {
            presentedError = .invalidLink
            return
        }

        guard let card = cardForOperation(targetID: target, kind: .link) else { return }
        selectedCardID = card.id
        card.urlString = url.absoluteString
        card.title = url.host ?? url.absoluteString
        card.detail = nil
        card.themeColorHex = nil
        card.faviconData = nil
        card.faviconRevision = UUID()
        Task { await applyLinkMetadata(to: card, from: url) }
    }

    private func applyLinkMetadata(to card: Card, from url: URL) async {
        let meta = await fetchLinkMetadata(for: url)

        // Do not apply metadata from an older request after the card URL changed.
        guard !card.isDeleted, card.urlString == url.absoluteString else { return }

        if let title = meta.title { card.title = title }
        card.faviconData = meta.iconData
        card.faviconRevision = UUID()
        card.detail = meta.description
        card.themeColorHex = meta.themeColorHex
    }

    func addMap(_ query: String) {
        let target = mapTargetCardID
        mapTargetCardID = nil
        Task {
            do {
                let location = try await searchLocation(query)
                guard let card = cardForOperation(targetID: target, kind: .map) else { return }
                selectedCardID = card.id
                card.title = location.name
                card.latitude = location.latitude
                card.longitude = location.longitude
            } catch LocationSearchError.noResults {
                presentedError = .locationNotFound
            } catch {
                presentedError = .locationSearchFailed(error.localizedDescription)
            }
        }
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
            guard let card = cardForOperation(targetID: targetID, kind: .image) else { return }
            selectedCardID = card.id
            card.imageData = data
            card.imageRevision = UUID()
        } catch ImageLoadingError.securityScopeDenied {
            presentedError = .imageAccessDenied
        } catch {
            presentedError = .fileImportFailed(error.localizedDescription)
        }
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
