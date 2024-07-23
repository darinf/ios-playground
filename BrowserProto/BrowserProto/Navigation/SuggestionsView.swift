import SwiftUI

struct SuggestionsView: View {
    enum Action {
        case suggestionAccepted(URLInputViewModel.Suggestion)
    }

    @ObservedObject var model: URLInputViewModel
    let handler: (Action) -> Void

    var body: some View {
        List(model.suggestions) { suggestion in
            Text(suggestion.text)
                .onTapGesture {
                    handler(.suggestionAccepted(suggestion))
                }
        }
    }
}
