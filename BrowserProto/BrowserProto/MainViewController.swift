import UIKit

class MainViewController: UIViewController {
    private lazy var backgroundView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }()

    private lazy var bottomBarView = {
        BottomBarView(onPanUp: onPanUp)
    }()

    private lazy var bottomBarViewHeightConstraint: NSLayoutConstraint = {
        bottomBarView.heightAnchor.constraint(equalToConstant: BottomBarViewConstants.baseHeight)
    }()

    override func loadView() {
        view = backgroundView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(bottomBarView)

        setupInitialConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(">>> viewDidAppear, safeAreaInsets: \(view.safeAreaInsets)")
        view.setNeedsUpdateConstraints()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        print(">>> viewSafeAreaInsetsDidChange()")
        view.setNeedsUpdateConstraints()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        print(">>> updateViewConstraints")
        bottomBarViewHeightConstraint.constant = BottomBarViewConstants.baseHeight + view.safeAreaInsets.bottom
    }

    private func setupInitialConstraints() {
        bottomBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBarView.widthAnchor.constraint(equalTo: view.widthAnchor),
            bottomBarViewHeightConstraint
        ])
    }

    private func onPanUp(translation: CGFloat) {
        print(">>> onPanUp, translation: \(translation)")

        if translation > 50 {
            print(">>> opening...")
            let newHeight = BottomBarViewConstants.baseHeight + view.safeAreaInsets.bottom + 50
            UIView.animate(withDuration: 0.2, delay: 0.0) {
                self.bottomBarViewHeightConstraint.constant = newHeight
                self.view.layoutIfNeeded()
            }
        }
    }
}
