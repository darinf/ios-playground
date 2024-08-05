import Combine
import Foundation
import UIKit

final class WebContentModel {
    @Published var url: URL?
    @Published var title: String?
    @Published var favicon: UIImage?
    @Published var thumbnail: UIImage?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var canGoBackToOpener: Bool = false
    @Published private(set) var progress: Double?

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
}
