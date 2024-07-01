import Combine
import UIKit

final class URLBarView: CapsuleButton {
    enum Action {
        case clicked
    }

    private let handler: (Action) -> Void

    private lazy var progressContainerView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var progressView = {
        let view = UIView()
        view.backgroundColor = .systemTeal.withAlphaComponent(0.5)
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var progressViewWidthConstraint = {
        progressView.widthAnchor.constraint(equalToConstant: 0)
    }()

    init(cornerRadius: CGFloat, handler: @escaping (Action) -> Void) {
        self.handler = handler
        super.init(cornerRadius: cornerRadius) {
            handler(.clicked)
        }

        addSubview(progressContainerView)
        progressContainerView.layer.cornerRadius = cornerRadius
        progressContainerView.clipsToBounds = true
        progressContainerView.addSubview(progressView)

        sendSubviewToBack(progressContainerView)

        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setProgress(_ progress: Double?) {
        if let progress {
            UIView.animate(withDuration: 0.2) { [self] in
                progressViewWidthConstraint.constant = progress * bounds.width
                progressContainerView.layoutIfNeeded()
            }
        } else if progressViewWidthConstraint.constant != 0 {
            UIView.animate(withDuration: 0.2) { [self] in
                progressViewWidthConstraint.constant = bounds.width
                progressContainerView.layoutIfNeeded()
            } completion: { [self] _ in
                UIView.animate(withDuration: 0.01, delay: 0.35) { [self] in
                    progressViewWidthConstraint.constant = 0
                    progressContainerView.layoutIfNeeded()
                }
            }
        }
    }

    func setDisplayText(_ displayText: String) {
        setTitle(displayText, for: .normal)
    }

    private func setupConstraints() {
        progressContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressContainerView.topAnchor.constraint(equalTo: topAnchor),
            progressContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressContainerView.leftAnchor.constraint(equalTo: leftAnchor),
            progressContainerView.rightAnchor.constraint(equalTo: rightAnchor)
        ])

        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: progressContainerView.topAnchor),
            progressView.bottomAnchor.constraint(equalTo: progressContainerView.bottomAnchor),
            progressView.leftAnchor.constraint(equalTo: progressContainerView.leftAnchor),
            progressViewWidthConstraint
        ])
    }
}
