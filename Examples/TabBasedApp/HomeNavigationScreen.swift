import SwiftUI

struct HomeNavigationScreen: View {
    @Bindable var navigator: Navigator<HomeRoute>
    @Bindable var modalPresenter: ModalPresenter<ModalRoute>

    var body: some View {
        NavigationStack(path: $navigator.routes) {
            VStack(alignment: .leading, spacing: 16) {
                Button("Navigate to Home Detail (Animated)") {
                    navigator.navigate(to: .detail(id: "home-001"))
                }
                Button("Navigate to Home Detail (No Animation)") {
                    navigator.navigate(to: .detail(id: "home-002"), animated: false)
                }
                Button("Present Sheet") {
                    modalPresenter.present(
                        .info(message: "Presented as sheet from Home"),
                        as: .sheet
                    )
                }
                Button("Present Sheet (No Animation)") {
                    modalPresenter.present(
                        .info(message: "Presented as sheet from Home (No Animation)"),
                        as: .sheet,
                        animated: false
                    )
                }
                Button("Present Full Screen") {
                    modalPresenter.present(.welcome, as: .fullScreen)
                }
            }
            .navigationTitle("Home")
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .detail(let id):
                    HomeDetailScreen(id: id, navigator: navigator)
                case .subDetail(let id):
                    HomeSubDetailScreen(id: id, navigator: navigator)
                }
            }
        }
        .sheet(item: $modalPresenter.presentedSheet) { route in
            switch route {
            case .info(let message):
                ModalSheetContent(message: message)
            case .welcome:
                EmptyView()
            }
        }
        .fullScreenCover(item: $modalPresenter.presentedFullScreen) { route in
            switch route {
            case .welcome:
                ModalFullScreenContent()
            case .info:
                EmptyView()
            }
        }
    }
}

struct HomeDetailScreen: View {
    let id: String
    let navigator: Navigator<HomeRoute>

    var body: some View {
        VStack(spacing: 16) {
            Button("Navigate to Nested Detail") {
                navigator.navigate(to: .subDetail(id: "nested-001"))
            }
        }
        .navigationTitle("Home Detail")
    }
}

struct HomeSubDetailScreen: View {
    let id: String
    let navigator: Navigator<HomeRoute>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button("Pop To Root (Animated)") {
                navigator.popToRoot()
            }
            Button("Pop To Root (No Animation)") {
                navigator.popToRoot(animated: false)
            }
        }
        .navigationTitle("Nested Detail")
    }
}

private struct ModalSheetContent: View {
    @Environment(\.dismiss) private var dismiss
    let message: String

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(message)
                Button("Dismiss Sheet") {
                    dismiss()
                }
                Button("Dismiss Sheet (No Animation)") {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        dismiss()
                    }
                }
            }
            .padding()
            .navigationTitle("Sheet")
        }
    }
}

private struct ModalFullScreenContent: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Full screen modal")
                Button("Dismiss Full Screen") {
                    dismiss()
                }
            }
            .padding()
            .navigationTitle("Full Screen")
        }
    }
}
