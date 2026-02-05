import SwiftUI

struct TabBasedApp: View {
    @State private var navigator = TabAppNavigator()

    var body: some View {
        Group {
            if #available(iOS 18, *) {
                TabView(selection: $navigator.selectedTab) {
                    Tab("Home", systemImage: "house", value: AppTab.home) {
                        HomeNavigationScreen(
                            navigator: navigator.home,
                            modalPresenter: navigator.modal
                        )
                    }

                    Tab("Search", systemImage: "magnifyingglass", value: AppTab.search) {
                        SearchNavigationScreen()
                    }

                    Tab("Settings", systemImage: "gear", value: AppTab.settings) {
                        SettingsNavigationScreen(
                            navigator: navigator.settings,
                            onGoToHomeTab: { navigator.changeTab(to: .home) }
                        )
                    }
                }
            } else {
                TabView(selection: $navigator.selectedTab) {
                    HomeNavigationScreen(
                        navigator: navigator.home,
                        modalPresenter: navigator.modal
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(AppTab.home)

                    SearchNavigationScreen()
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(AppTab.search)

                    SettingsNavigationScreen(
                        navigator: navigator.settings,
                        onGoToHomeTab: { navigator.changeTab(to: .home) }
                    )
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(AppTab.settings)
                }
            }
        }
        .environment(navigator)
        .onOpenURL { url in
            navigator.handleDeepLink(url)
        }
    }
}

#Preview {
    TabBasedApp()
}
