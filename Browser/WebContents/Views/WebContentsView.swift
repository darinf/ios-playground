// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI
import WebKit

struct WebViewContainerView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> UIView {
        return UIView()
    }

    func updateUIView(_ view: UIView, context: Context) {
        guard view.subviews.count != 1 || view.subviews.first != webView else { return }

        DispatchQueue.main.async {
            view.subviews.forEach { $0.removeFromSuperview() }
            view.addSubview(webView)

            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        }
    }
}

struct WebContentsView: View {
    @ObservedObject var model: WebContentsViewModel
    @ObservedObject var card: WebContentsCardModel

    var body: some View {
        WebViewContainerView(webView: card.webView)
    }
}