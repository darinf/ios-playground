import Foundation
import Combine
import UIKit

final class WebContentViewModel {
    @Published var url: URL?
    @Published var overrideSafeAreaInsets: UIEdgeInsets?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
}
