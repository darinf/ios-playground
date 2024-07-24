import Combine
import UIKit

final class SuggestionsView: UITableView {
    typealias SuggestionsPublisher = AnyPublisher<[URLInputViewModel.Suggestion], Never>

    enum Action {
        case suggestionAccepted(URLInputViewModel.Suggestion)
    }

    private let suggestionsPublisher: SuggestionsPublisher
    private let handler: (Action) -> Void
    private var subscriptions: Set<AnyCancellable> = []
    private var suggestions: [URLInputViewModel.Suggestion] = []

    init(suggestionsPublisher: SuggestionsPublisher, handler: @escaping (Action) -> Void) {
        self.suggestionsPublisher = suggestionsPublisher
        self.handler = handler
        super.init(frame: .zero, style: .plain)

        backgroundColor = .clear
        separatorStyle = .none

        register(UITableViewCell.self, forCellReuseIdentifier: "SuggestionsViewCell")
        dataSource = self
        delegate = self

        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupObservers() {
        suggestionsPublisher.dropFirst().sink { [weak self] suggestions in
            guard let self else { return }
            self.suggestions = suggestions
            reloadData()
        }.store(in: &subscriptions)
    }
}

extension SuggestionsView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionsViewCell", for: indexPath)
//        let item = self.items[indexPath.item]
        let suggestion = suggestions[indexPath.item]
        cell.textLabel?.text = suggestion.text
        cell.backgroundColor = .clear
        return cell
    }
}

extension SuggestionsView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(">>> didSelectRowAt: \(indexPath)")
        let suggestion = suggestions[indexPath.item]
        handler(.suggestionAccepted(suggestion))
    }
}
