import SwiftUI

struct SettingsNavigationScreen: View {
    @Bindable var navigator: Navigator<SettingsRoute>
    let onGoToHomeTab: () -> Void

    var body: some View {
        NavigationStack(path: $navigator.routes) {
            VStack(alignment: .leading, spacing: 16) {
                Button("Navigate to About") {
                    navigator.navigate(to: .about)
                }
                Button("Go To Home Tab") {
                    onGoToHomeTab()
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .about:
                    Text("About this app")
                        .navigationTitle("About")
                }
            }
        }
    }
}
