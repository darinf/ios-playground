import UIKit

final class BottomBarViewController: UIViewController {
    override func loadView() {
//        let view = UIView(frame: .zero)
//        view.addSubview(CircleButton(radius: 20.0, systemImage: "square"))
//
//        self.view = view
        view = BottomBarView()
    }
}
