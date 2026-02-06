//
//  MultiRouteNavigatorApp.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 6/2/26.
//

import SwiftUI

private enum SampleTab: Hashable {
    case home
    case settings
}

private enum HomeRouteExample: Hashable {
    case details
    case account
}

private enum AccountRouteExample: Hashable {
    case edit
    case followers
}

private enum SettingsRouteExample: Hashable {
    case about
    case terms
}

struct MultiRouteNavigatorApp: View {
    @State private var homeNavigator = MultiRouteNavigator()
    @State private var settingsNavigator = MultiRouteNavigator()
    @State private var selectedTab: SampleTab = .home

    var body: some View {
        Group {
            if #available(iOS 18, *) {
                TabView(selection: $selectedTab) {
                    Tab("Home", systemImage: "house", value: SampleTab.home) {
                        HomeTabScreen(navigator: homeNavigator)
                    }
                    Tab("Settings", systemImage: "gear", value: SampleTab.settings) {
                        SettingsTabScreen(navigator: settingsNavigator)
                    }
                }
            } else {
                TabView(selection: $selectedTab) {
                    HomeTabScreen(navigator: homeNavigator)
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }
                        .tag(SampleTab.home)

                    SettingsTabScreen(navigator: settingsNavigator)
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(SampleTab.settings)
                }
            }
        }
    }
}

private struct HomeTabScreen: View {
    @Bindable var navigator: MultiRouteNavigator

    var body: some View {
        NavigationStack(path: $navigator.routes) {
            VStack(alignment: .leading, spacing: 16) {
                Button("Navigate to Details") {
                    navigator.navigate(to: HomeRouteExample.details)
                }
                Button("Navigate to Account") {
                    navigator.navigate(to: HomeRouteExample.account)
                }
            }
            .navigationTitle("Home")
            .navigationDestination(for: HomeRouteExample.self) { route in
                switch route {
                case .details:
                    Text("Details Screen")
                case .account:
                    AccountScreen(navigator: navigator)
                }
            }
        }
    }
}

private struct AccountScreen: View {
    @Bindable var navigator: MultiRouteNavigator

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button("Navigate to Edit") {
                navigator.navigate(to: AccountRouteExample.edit)
            }
            Button("Navigate to Followers") {
                navigator.navigate(to: AccountRouteExample.followers)
            }
        }
        .navigationTitle("Account")
        .navigationDestination(for: AccountRouteExample.self) { route in
            switch route {
            case .edit:
                Text("Edit Screen")
            case .followers:
                Text("Followers Screen")
            }
        }
    }
}

private struct SettingsTabScreen: View {
    @Bindable var navigator: MultiRouteNavigator

    var body: some View {
        NavigationStack(path: $navigator.routes) {
            VStack(alignment: .leading, spacing: 16) {
                Button("Navigate to About") {
                    navigator.navigate(to: SettingsRouteExample.about)
                }
                Button("Navigate to Terms") {
                    navigator.navigate(to: SettingsRouteExample.terms)
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsRouteExample.self) { route in
                switch route {
                case .about:
                    Text("About Screen")
                case .terms:
                    Text("Terms & Conditions Screen")
                }
            }
        }
    }
}

#Preview {
    MultiRouteNavigatorApp()
}
