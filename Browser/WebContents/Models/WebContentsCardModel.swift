// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import Foundation
import UIKit
import WebKit

// One of these per tab
class WebContentsCardModel: CardModel {
    let id = UUID().uuidString
    var title: String {
        "Some title"
    }

    @Published var thumbnail = UIImage(systemName: "plus")!
    var favicon = UIImage(systemName: "plus")!

    @Published private(set) var url: URL

    init(url: URL) {
        self.url = url
    }

    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        return WKWebView(frame: .zero, configuration: configuration)
    }()

    func navigate(to url: URL) {
        self.url = url  // XXX need to instead observe webView.url
        webView.load(URLRequest(url: url))
    }

    func takeSnapshot(completion: @escaping () -> Void) {
        webView.takeSnapshot(with: nil) { image, error in
            if let image = image {
                self.thumbnail = image
            }
            completion()
        }
    }
}
