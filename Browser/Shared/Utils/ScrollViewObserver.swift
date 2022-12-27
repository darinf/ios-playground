// Copyright 2022 Darin Fisher. All rights reserved.

import Foundation
import UIKit

class ScrollViewObserver: NSObject, ObservableObject {
    @Published private(set) var panDelta: CGFloat = 0
    @Published private(set) var panning: Bool = false
    @Published private(set) var scrolledToTop: Bool = false

    private var scrollView: UIScrollView
    private var lastContentOffset: CGPoint = .zero
 
    private lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        panGesture.allowedScrollTypesMask = .all
        return panGesture
    }()

    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init()

        scrollView.addGestureRecognizer(self.panGesture)
        scrollView.delegate = self  // weak reference
    }

    deinit {
        scrollView.removeGestureRecognizer(self.panGesture)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let containerView = scrollView.superview else {
            return
        }

        panning = (gesture.state == .changed)

        if scrolledToTop {
            scrolledToTop = false
        }

        let translation = gesture.translation(in: containerView)
        let dy = lastContentOffset.y - translation.y

        if abs(translation.x) > abs(translation.y) {
            panDelta = 0
        } else {
            panDelta = dy
        }

        lastContentOffset = translation

        if gesture.state == .ended || gesture.state == .cancelled {
            lastContentOffset = .zero
        }
    }
}

extension ScrollViewObserver: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}

extension ScrollViewObserver: UIScrollViewDelegate {
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrolledToTop = true
        return true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        panning = false
    }
}
