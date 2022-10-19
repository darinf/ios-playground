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
    @ObservedObject var card: WebContentsCardModel

    @State var hideOverlays: Bool = false
    @State var bottomPadding: CGFloat = OmniBarUX.dockedHeight

    var body: some View {
        WebViewContainerView(webView: card.webView)
            .padding(.bottom, bottomPadding)
            .onReceive(card.$hideOverlays) {
                // Defer expanding bottomPadding until after the animation to show
                // the overlay completes. Do that by using a local `hideOverlays`
                // state variable. Don't directly animate `bottomPadding` as the
                // web page may struggle to keep up with the animation. This way
                // we just update the web page once after our animation completes.
                if $0 {
                    hideOverlays = true
                    bottomPadding = 0
                } else {
                    withAnimation {
                        hideOverlays = false
                    }
                }
            }
            .onAnimationCompleted(for: hideOverlays) {
                bottomPadding = OmniBarUX.dockedHeight
            }
    }
}
