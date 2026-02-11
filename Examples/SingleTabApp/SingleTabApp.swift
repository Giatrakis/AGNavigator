import SwiftUI

struct SingleTabApp: View {
    @State private var navigator = Navigator<HomeRoute>()
    @State private var modalPresenter = ModalPresenter<ModalRoute>()

    var body: some View {
        HomeNavigationScreen(
            navigator: navigator,
            modalPresenter: modalPresenter
        )
        .onOpenURL { url in
            guard let request = DeepLinkParser.parse(url: url) else { return }
            guard let path = request.root else { return }
            let routeValue = request.childPath.first ?? request.data["id"] ?? "default"

            switch path {
            case "detail":
                navigator.replace(with: [.detail(id: routeValue)])
            case "subdetail", "sub-detail":
                navigator.replace(with: [.subDetail(id: routeValue)])
            default:
                return
            }
        }
    }
}

#Preview {
    SingleTabApp()
}
