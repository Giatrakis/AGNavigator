# AGNavigator

AGNavigator is a lightweight, reusable navigation layer for modern SwiftUI apps.

It helps you model navigation with typed routes, keep flows testable, and compose both single-stack and tab-based apps without locking into a rigid architecture.
Instead of a monolithic router, it gives you clear, focused building blocks:
- `Navigator<Route>` for stack navigation
- `ModalPresenter<Route>` for sheet/full-screen presentation
- `DeepLinkParser` for URL parsing

Built for modern SwiftUI (`NavigationStack`, `@Observable`, iOS 17+).

## Features

- Supports both single-stack navigation and tab-based navigation apps
- Typed destinations with enums (`NavigationRoute`)
- Navigate/pop with animation control
- Present/dismiss modals with animation control
- Sheet and full-screen support from one presenter
- URL deep-link parsing (`URL -> DeepLinkRequest`)
- `@MainActor` APIs and unit-tested core

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Giatrakis/AGNavigator", branch: "main")
]
```

```swift
import AGNavigator
```

## Core API

### `Navigator<Route: NavigationRoute>`

- `routes: [Route]` - The current stack for a `NavigationStack(path:)`.
- `presentedRoute: Route?` - The top route in the stack (`routes.last`).
- `hasPresentedRoutes: Bool` - `true` when the stack is not empty (useful for UI state decisions).
- `navigate(to:animated:)` - Pushes a new route to the stack.
- `popLast(_:animated:)` - Pops the last N routes (default is 1).
- `popToRoot(animated:)` - Clears the stack and returns to root.
- `contains(_ route: Route?, where:)` - Checks if a specific route (or predicate match) exists in the stack.

Animation control examples:

```swift
navigator.navigate(to: .detail(id: "42")) // `animated` defaults to `true`
navigator.popToRoot(animated: false)
```

Example: hide tab bar while a stack is pushed

```swift
NavigationStack(path: $navigator.routes) {
    HomeView()
}
.toolbar(navigator.hasPresentedRoutes ? .hidden : .visible, for: .tabBar)
```

### `ModalPresenter<Route: NavigationRoute>`

- `presentedRoute: Route?` - The currently presented modal route (if any).
- `presentedStyle: ModalStyle?` - Whether the current modal is `.sheet` or `.fullScreen`.
- `presentedSheet: Route?` - Current route only when style is `.sheet` (bind directly to `.sheet(item:)`).
- `presentedFullScreen: Route?` - Current route only when style is `.fullScreen` (bind to `.fullScreenCover(item:)`).
- `present(_:as:animated:policy:)` - Presents a route as sheet/full-screen with animation + policy control.
- `dismiss(animated:)` - Dismisses the currently presented modal route.

Animation control examples:

```swift
modalPresenter.present(.info(message: "Hello"), as: .sheet) // `animated` defaults to `true`
modalPresenter.dismiss(animated: false)
```

### `DeepLinkParser`

- `parse(url:)` - Parses a `URL` into a `DeepLinkRequest` (`path` + `data`).
- `parse(urlString:)` - Convenience overload for parsing from a raw string.

### Supporting types

- `NavigationRoute` - Route constraint (`Hashable + Identifiable`) used by navigators/presenters.
- `ModalStyle` (`sheet`, `fullScreen`) - Chooses the modal presentation style.
- `ModalPresentationPolicy` (`replaceCurrent`, `ignoreIfAlreadyPresented`) - Defines what happens when a modal is already visible.
- `DeepLinkRequest` (`path`, `data`, `root`, `childPath`) - Parsed deep-link payload used by your mapping logic.

## Quick Start

### 1) Define routes

```swift
import AGNavigator

enum HomeRoute: NavigationRoute {
    case detail(id: String)
    case subDetail(id: String)
}

enum SearchRoute: NavigationRoute {
    case results(query: String)
}

enum SettingsRoute: String, NavigationRoute {
    case about
}

enum ModalRoute: NavigationRoute {
    case info(message: String)
    case welcome
}
```

### 2) Build a Single-Tab App

This example uses dependency injection. In the next example (`Tab-Based App`), we use environment object injection.

```swift
import SwiftUI
import AGNavigator

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
                navigator.routes = [.detail(id: routeValue)]
            case "subdetail", "sub-detail":
                navigator.routes = [.subDetail(id: routeValue)]
            default:
                return
            }
        }
    }
}

struct HomeNavigationScreen: View {
    @Bindable var navigator: Navigator<HomeRoute>
    @Bindable var modalPresenter: ModalPresenter<ModalRoute>

    var body: some View {
        NavigationStack(path: $navigator.routes) {
            Button("Open Detail") {
                navigator.navigate(to: .detail(id: "home-001"))
            }
        }
        .sheet(item: $modalPresenter.presentedSheet) { route in
            switch route {
            case .info(let message):
                Text(message)
            case .welcome:
                EmptyView()
            }
        }
    }
}
```

### 3) Build a Tab-Based App

```swift
import SwiftUI
import Observation
import AGNavigator

enum AppTab: String {
    case home, search, settings
}

@MainActor
@Observable
final class TabAppNavigator {
    var selectedTab: AppTab = .home

    var home = Navigator<HomeRoute>()
    var search = Navigator<SearchRoute>()
    var settings = Navigator<SettingsRoute>()

    var modal = ModalPresenter<ModalRoute>()

    func changeTab(to tab: AppTab) {
        selectedTab = tab
    }
}

struct MainScreen: View {
    @State private var appNavigator = TabAppNavigator()

    var body: some View {
        @Bindable var appNavigator = appNavigator

        TabView(selection: $appNavigator.selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                HomeNavigationScreen()
            }

            Tab("Search", systemImage: "magnifyingglass", value: AppTab.search) {
                SearchNavigationScreen()
            }

            Tab("Settings", systemImage: "gear", value: AppTab.settings) {
                SettingsNavigationScreen()
            }
        }
        .environment(appNavigator)
    }
}

struct SearchNavigationScreen: View {
    @Environment(TabAppNavigator.self) private var appNavigator

    var body: some View {
        @Bindable var navigator = appNavigator.search

        NavigationStack(path: $navigator.routes) {
            Button("Open Results") {
                navigator.navigate(to: .results(query: "swiftui"))
            }
        }
    }
}
```

## Deep Links

`DeepLinkParser` converts URLs to `DeepLinkRequest`:

```swift
let request = DeepLinkParser.parse(url: url)
// request?.path      -> ["home", "detail", "123"]
// request?.data      -> ["query": "swiftui"]
// request?.root      -> "home"
// request?.childPath -> ["detail", "123"]
```

- Custom scheme (`myapp://home/detail/123`) includes host as first path segment.
- Universal link (`https://example.com/home/detail/123`) uses URL path segments.

Typical integration:

```swift
.onOpenURL { url in
    guard let request = DeepLinkParser.parse(url: url) else { return }

    switch request.root {
    case "home":
        // map childPath/data to HomeRoute
        break
    case "search":
        // map childPath/data to SearchRoute
        break
    default:
        break
    }
}
```

## Requirements

- Swift 5.10+
- iOS 17+
- macOS 14+
- tvOS 17+
- watchOS 10+

## License

AGNavigator is released under the MIT License. See the `LICENSE` file for details.
