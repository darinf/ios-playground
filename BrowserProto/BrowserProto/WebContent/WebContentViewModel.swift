import Foundation
import Combine
import UIKit

final class WebContentViewModel {
    @Published private(set) var requestedURL: URL?
    @Published var url: URL?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published private(set) var progress: Double?
    @Published var panningDeltaY: CGFloat?

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

    func navigate(to url: URL?) {
        requestedURL = url
    }
}
