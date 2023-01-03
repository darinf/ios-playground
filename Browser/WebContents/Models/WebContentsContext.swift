// Copyright 2022 Darin Fisher. All rights reserved.

import Foundation
import WebKit

class WebContentsContext {
    let store: Store

    lazy var userContentController = {
        return WKUserContentController()
    }()

    lazy var defaultConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.ignoresViewportScaleLimits = true
        configuration.allowsInlineMediaPlayback = true
        configuration.upgradeKnownHostsToHTTPS = true
        configuration.userContentController = userContentController
        return configuration
    }()

    init(store: Store) {
        self.store = store
        setupUserScripts()
    }

    func setupUserScripts() {
        FaviconObserver.setup(userContentController: userContentController)
    }
}
