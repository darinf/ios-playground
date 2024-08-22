import Foundation

/// This is a keep-alive cache for WebContent.
final class WebContentCache {
    private enum Metrics {
        static let maxCount = 10
    }

    // Since maxCount is small, we can just use a simple array here.
    private var store: [WebContent] = []

    func insert(_ webContent: WebContent) {
        let index = store.firstIndex(where: { $0.id == webContent.id })
        if let index {
            touch(byIndex: index)
        } else {
            store.append(webContent)
        }
        if store.count > Metrics.maxCount {
            store.remove(at: 0)
        }
    }

    func remove(_ webContent: WebContent) {
        guard let index = store.firstIndex(where: { $0.id == webContent.id }) else { return }
        store.remove(at: index)
    }

    private func touch(byIndex index: Int) {
        guard index < store.endIndex - 1 else { return }
        store.append(store.remove(at: index))
    }
}
