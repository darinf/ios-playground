import Foundation
import Combine
import UIKit

final class WebContentViewModel {
    @Published private(set) var requestedURL: URL?
    @Published private(set) var url: URL?
    @Published private(set) var canGoBack: Bool = false
    @Published private(set) var canGoForward: Bool = false
    @Published private(set) var progress: Double?
    @Published private(set) var panningDeltaY: CGFloat?

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

    func updateProgress(isLoading: Bool, estimatedProgress: Double) {
        let progress: Double?
        if isLoading {
            progress = estimatedProgress
        } else {
            progress = nil
        }
        if self.progress != progress {
            self.progress = progress
        }
    }

    func update(panningDeltaY: CGFloat?) {
        if self.panningDeltaY != panningDeltaY {
            self.panningDeltaY = panningDeltaY
        }
    }

    func navigate(to url: URL?) {
        requestedURL = url
    }
}
