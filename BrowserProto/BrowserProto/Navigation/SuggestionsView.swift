import Combine
import UIKit

final class SuggestionsView: UITableView {
    enum Action {
        case suggestionAccepted(SuggestionsViewModel.Suggestion)
    }

    private let model: SuggestionsViewModel
    private let handler: (Action) -> Void
    private var subscriptions: Set<AnyCancellable> = []
    private var suggestions: [SuggestionsViewModel.Suggestion] = []

    init(model: SuggestionsViewModel, handler: @escaping (Action) -> Void) {
        self.model = model
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
        model.$suggestions.dropFirst().sink { [weak self] suggestions in
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
