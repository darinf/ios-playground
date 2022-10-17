// Copyright 2022 Darin Fisher. All rights reserved.

import Foundation
import UIKit

class ScrollViewObserver: NSObject, ObservableObject {
    enum ScrollDirection {
        case none
        case up
        case down
    }

    @Published private(set) var direction: ScrollDirection = .none

    private let scrollView: UIScrollView
    private var lastContentOffset: CGFloat = 0

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

        self.scrollView.addGestureRecognizer(self.panGesture)
        self.scrollView.delegate = self  // weak reference
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let containerView = scrollView.superview else {
            return
        }

        let translation = gesture.translation(in: containerView)
        let delta = lastContentOffset - translation.y

        if delta > 0 {
            direction = .down
        } else if delta < 0 {
            direction = .up
        }

        lastContentOffset = translation.y

        if gesture.state == .ended || gesture.state == .cancelled {
            lastContentOffset = 0
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
        direction = .up
        return true
    }
}
