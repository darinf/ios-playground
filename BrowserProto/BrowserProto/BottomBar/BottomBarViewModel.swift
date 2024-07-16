import Combine
import Foundation

final class BottomBarViewModel {
    @Published private(set) var expanded: Bool = false
    @Published private(set) var url: URL?
    @Published private(set) var canGoBack: Bool = false
    @Published private(set) var canGoForward: Bool = false
    @Published private(set) var progress: Double?

    func update(expanded: Bool) {
        if self.expanded != expanded {
            self.expanded = expanded
        }
    }

    func update(url: URL?) {
        if self.url != url {
            self.url = url
        }
    }

    func update(canGoBack: Bool) {
        if self.canGoBack != canGoBack {
            self.canGoBack = canGoBack
        }
    }

    func update(canGoForward: Bool) {
        if self.canGoForward != canGoForward {
            self.canGoForward = canGoForward
        }
    }

    func update(progress: Double?) {
        if self.progress != progress {
            self.progress = progress
        }
    }
}
