import Combine
import UIKit

class MainViewController: UIViewController {
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var backgroundView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }()

    private lazy var bottomBarView = {
        BottomBarView()
    }()

    private lazy var bottomBarViewHeightConstraint: NSLayoutConstraint = {
        bottomBarView.heightAnchor.constraint(equalToConstant: BottomBarView.Constants.baseHeight)
    }()

    override func loadView() {
        view = backgroundView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(bottomBarView)

        setupInitialConstraints()
        setupObservers()
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
        bottomBarViewHeightConstraint.constant = BottomBarView.Constants.baseHeight + view.safeAreaInsets.bottom
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

    private func setupObservers() {
        bottomBarView.model.$expanded.dropFirst().sink { [weak self] expanded in
            self?.onUpdateBottomBarHeight(expanded: expanded)
        }.store(in: &subscriptions)
    }

    private func onUpdateBottomBarHeight(expanded: Bool) {
        let additionalHeight: CGFloat = expanded ? 50 : 0

        let newHeight = BottomBarView.Constants.baseHeight + view.safeAreaInsets.bottom + additionalHeight
        UIView.animate(withDuration: 0.2, delay: 0.0) {
            self.bottomBarViewHeightConstraint.constant = newHeight
            self.view.layoutIfNeeded()
        }
    }
}
