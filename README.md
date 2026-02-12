# AGNavigator

A lightweight, reusable navigation layer for modern SwiftUI apps.
AGNavigator is intentionally simple: it is a set of small wrappers around SwiftUI navigation APIs, not a complex framework.

It helps you model navigation with typed routes, keep flows testable, and compose both single-stack and tab-based apps without locking into a rigid architecture.
Instead of a monolithic router, it gives you clear, focused building blocks:
- `Navigator<Route>` for stack navigation
- `MultiRouteNavigator` for multiple route types in a single stack
- `ModalPresenter<Route>` for sheet/full-screen presentation
- `DeepLinkParser` for URL parsing

Built for modern SwiftUI (`NavigationStack`, `@Observable`, iOS 17+).

## Features

- Supports both single-stack navigation and tab-based navigation apps
- Adds `MultiRouteNavigator` for a single stack with multiple route types
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
- `replace(with:animated:)` - Replaces the entire stack with new routes.
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

### `MultiRouteNavigator`

- `routes: NavigationPath` - The current path for a `NavigationStack(path:)`.
- `presentedRoute(of:)` - Returns the top route of a given type.
- `hasPresentedRoutes: Bool` - `true` when the path is not empty.
- `navigate(to:animated:)` - Pushes a new route (any Hashable type).
- `replace(with:animated:)` - Replaces the entire path with new routes.
- `popLast(_:animated:)` - Pops the last N routes (default is 1).
- `popToRoot(animated:)` - Clears the path and returns to root.
- `contains(_:)/contains(of:where:)` - Checks for route existence by value or predicate.

How it works:
- `MultiRouteNavigator` exposes a single `NavigationPath` (`routes`) that you bind to `NavigationStack(path:)`.
- Every push/pop/replace operation updates that path, so SwiftUI drives the actual screen transitions from state.
- Because one `NavigationPath` can contain different `Hashable` route types, each feature can register its own `navigationDestination(for:)` without sharing one global route enum.
- `contains` and `presentedRoute` provide typed introspection for routes pushed through `MultiRouteNavigator` APIs.
- Compared with `Navigator<Route>`, which uses a typed `[Route]` stack for a single route type, `MultiRouteNavigator` trades strict compile-time route typing for flexibility across multiple route types in one stack.

State contract:
- `contains` and `presentedRoute` are guaranteed only for routes added through `MultiRouteNavigator` APIs (`navigate` / `replace`).
- If `routes` is mutated externally (for example via `NavigationStack` binding), those externally added elements are not available to typed introspection.

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

### When To Use What

- Use `Navigator<Route>` when a flow uses a single route type, including tab-based apps (one navigator per tab flow).
- Use `MultiRouteNavigator` only when one `NavigationStack` must support multiple route types.
- Use `ModalPresenter<Route>` to manage sheet/full-screen modal state.
- Use `DeepLinkParser` to parse URLs, then map the parsed request to your app routes.

## Examples

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

### 4) Use MultiRouteNavigator in a Single Stack

Use `MultiRouteNavigator` when a single `NavigationStack` needs to support **multiple route types**, so you can keep each flow’s `navigationDestination` separate.
In the example below, the HomeScreen handles `HomeRoute` destinations, while the AccountScreen registers its own `AccountRoute` destinations on the same stack.
This keeps each flow focused and prevents a single, oversized route enum just to support nested navigation.
In most scenarios, the simple `Navigator<Route>` is enough.

```swift
import SwiftUI
import Observation
import AGNavigator

enum HomeRoute: Hashable {
    case details
    case account
}

enum AccountRoute: Hashable {
    case edit
    case followers
}

struct HomeStackScreen: View {
    @State private var navigator = MultiRouteNavigator()

    var body: some View {
        NavigationStack(path: $navigator.routes) {
            VStack(alignment: .leading, spacing: 16) {
                Button("Open Details") {
                    navigator.navigate(to: HomeRoute.details)
                }
                Button("Open Account") {
                    navigator.navigate(to: HomeRoute.account)
                }
            }
            .navigationTitle("Home")
            .navigationDestination(for: HomeRoute.self) { route in
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

struct AccountScreen: View {
    @Bindable var navigator: MultiRouteNavigator

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button("Edit Profile") {
                navigator.navigate(to: AccountRoute.edit)
            }
            Button("Followers") {
                navigator.navigate(to: AccountRoute.followers)
            }
        }
        .navigationTitle("Account")
        .navigationDestination(for: AccountRoute.self) { route in
            switch route {
            case .edit:
                Text("Edit Screen")
            case .followers:
                Text("Followers Screen")
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

Default canonicalization rules:
- Path segments keep original casing.
- Query keys are normalized to lowercase.
- Duplicate query keys use last value wins.
- Query items without value are ignored.
- URL fragment is ignored.

`DeepLinkParser` also supports `Options` for:
- including/excluding custom-scheme host in path
- lowercasing path segments
- preserving query key casing
- choosing duplicate-key policy (`firstWins` / `lastWins`)

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

Example mapping to a route:

```swift
func handleDeepLink(_ url: URL, navigator: Navigator<HomeRoute>) {
    guard let request = DeepLinkParser.parse(url: url) else { return }

    guard request.root == "home" else { return }
    if request.childPath.first == "detail",
       let id = request.data["id"] {
        navigator.navigate(to: .detail(id: id))
    }
}
```

## UIKit Coordinator Parallels

If you’re used to UIKit coordinators, the mental model is similar: keep flow logic out of view code, make navigation explicit, and keep it testable. The main shift in SwiftUI is that navigation becomes **state-driven** rather than **imperative**—you describe the stack and SwiftUI renders it.

Here’s how familiar UIKit coordinator concepts map to SwiftUI:

- **Root coordinator**: In UIKit this owns the app’s top-level flow and decides which child flow starts. In SwiftUI this becomes your app-level composition that wires together the main navigators and initial state (often a tab-based root).

```swift
@Observable
final class AppNavigator {
    var home = Navigator<HomeRoute>()
    var settings = Navigator<SettingsRoute>()
    var selectedTab: AppTab = .home
}

enum HomeRoute: NavigationRoute {
    case detail(id: String)
    case profile
}

enum SettingsRoute: NavigationRoute {
    case about
    case contact
}

enum AppTab {
    case home
    case settings
}

@main
struct AGNavigatorApp: App {
    @State private var appNavigator = AppNavigator()

    var body: some Scene {
        WindowGroup {
            TabView(selection: $appNavigator.selectedTab) {
                Tab("Home", systemImage: "house", value: AppTab.home) {
                    HomeScreen()
                }
                Tab("Settings", systemImage: "gear", value: AppTab.settings) {
                    SettingsScreen()
                }
            }
            .environment(appNavigator)
        }
    }
}
```
- **Child coordinators**: In UIKit these isolate a specific flow (Onboarding, Profile, Checkout), centralize its screens and routing, and keep the parent coordinator lean. In SwiftUI you can mirror that separation by keeping each flow’s `navigationDestination` in its own view, and use `MultiRouteNavigator` when a single stack needs multiple route types.

```swift
struct HomeScreen: View {
    @State private var navigator = MultiRouteNavigator()

    var body: some View {
        NavigationStack(path: $navigator.routes) {
            Button("Open Profile") {
                navigator.navigate(to: HomeRoute.profile)
            }
        }
        .navigationDestination(for: HomeRoute.self) { route in
            switch route {
            case .detail(let id):
                HomeDetailScreen(id: id)
            case .profile:
                ProfileScreen(navigator: navigator)
            }
        }
    }
}

struct ProfileScreen: View {
    @Bindable var navigator: MultiRouteNavigator

    var body: some View {
        VStack {
            Button("Edit") {
                navigator.navigate(to: ProfileRoute.edit)
            }
            
            Button("Followers") {
                navigator.navigate(to: ProfileRoute.followers)
            }
        }
        .navigationDestination(for: ProfileRoute.self) { route in
            switch route {
            case .edit:
                EditProfileScreen()
            case .followers:
                FollowersScreen()
            }
        }
    }
}
```
- **Navigation stack**: UIKit pushes and pops view controllers on a `UINavigationController`. SwiftUI replaces that with a `routes` array bound to `NavigationStack(path:)`.

```swift
NavigationStack(path: $navigator.routes) {
    HomeScreen()
}
```

- **start(animated:)**: UIKit coordinators build a root view controller and push it. SwiftUI starts a flow by setting the initial route state and composing the root view.
- **push / pop**: UIKit calls `pushViewController` and `popViewController`. SwiftUI updates state via `navigate`, `popLast`, and `popToRoot`.

```swift
navigator.navigate(to: .detail(id: "42"))
navigator.popLast()
navigator.popLast(2)
navigator.popToRoot()
```

- **Modal flow**: UIKit coordinators present modals and dismiss them. SwiftUI uses `ModalPresenter` to hold modal state for sheets and full-screen covers.

```swift
modalPresenter.present(.info(message: "Hello"), as: .sheet)
modalPresenter.dismiss()
```

- **Dependency injection**: UIKit passes coordinators into view controllers. SwiftUI passes navigators explicitly or injects them via the environment.

```swift
// Explicit
HomeScreen(navigator: navigator)

// Environment
.environment(appNavigator)
```

- **Flow cleanup**: UIKit removes child coordinators when a flow ends. SwiftUI clears state (for example, resetting routes) to unwind a flow.

```swift
navigator.popToRoot()
```

## Requirements

- Swift 5.10+
- iOS 17+
- macOS 14+
- tvOS 17+
- watchOS 10+

## License

AGNavigator is released under the MIT License. See the `LICENSE` file for details.
