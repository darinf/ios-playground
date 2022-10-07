// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI
import WebKit

struct WebViewContainerView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}

struct WebContentsView: View {
    @ObservedObject var model: WebContentsViewModel
    @ObservedObject var card: WebContentsCardModel

    var body: some View {
        WebViewContainerView(webView: card.webView)
//            .onAppear {
//                card.navigate(to: card.url)
//            }
//            .onDisappear {
//                card.takeSnapshot()
//            }
    }
}
