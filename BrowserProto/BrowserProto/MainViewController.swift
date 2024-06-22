import UIKit

class MainViewController: UIViewController {
    private lazy var backgroundView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }()

    private lazy var bottomBarViewController = BottomBarViewController()

    private lazy var bottomBarViewHeightConstraint: NSLayoutConstraint = {
        .init(
            item: bottomBarViewController.view!,
            attribute: NSLayoutConstraint.Attribute.height,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: nil,
            attribute: NSLayoutConstraint.Attribute.notAnAttribute,
            multiplier: 1,
            constant: BottomBarViewConstants.baseHeight
        )
    }()

    override func loadView() {
        view = backgroundView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(bottomBarViewController)
        bottomBarViewController.didMove(toParent: self)
        view.addSubview(bottomBarViewController.view)

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
        let bottomBarView = bottomBarViewController.view!
        bottomBarView.translatesAutoresizingMaskIntoConstraints = false
        let horizontalConstraint = NSLayoutConstraint(
            item: bottomBarView,
            attribute: NSLayoutConstraint.Attribute.centerX,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: view,
            attribute: NSLayoutConstraint.Attribute.centerX,
            multiplier: 1,
            constant: 0
        )
        let verticalConstraint = NSLayoutConstraint(
            item: bottomBarView,
            attribute: NSLayoutConstraint.Attribute.bottom,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: view,
            attribute: NSLayoutConstraint.Attribute.bottom,
            multiplier: 1,
            constant: 0
        )
        let widthConstraint = NSLayoutConstraint(
            item: bottomBarView,
            attribute: NSLayoutConstraint.Attribute.width,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: view,
            attribute: NSLayoutConstraint.Attribute.width,
            multiplier: 1,
            constant: 0
        )
        let heightConstraint = bottomBarViewHeightConstraint
        view.addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
    }
}
