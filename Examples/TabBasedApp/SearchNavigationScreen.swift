import SwiftUI

struct SearchNavigationScreen: View {
    @Environment(TabAppNavigator.self) private var appNavigator

    var body: some View {
        @Bindable var navigator = appNavigator.search

        NavigationStack(path: $navigator.routes) {
            VStack(spacing: 16) {
                Button("Navigate to Results") {
                    navigator.navigate(to: .results(query: "swiftui"))
                }
            }
            .navigationTitle("Search")
            .navigationDestination(for: SearchRoute.self) { route in
                switch route {
                case .results(let query):
                    Text("Results for: \(query)")
                        .navigationTitle("Results")
                }
            }
        }
    }
}
