import Testing
@testable import AGNavigator

private enum TestModalRoute: NavigationRoute, Sendable {
    case about
    case info(message: String)
}

@Suite("ModalPresenter")
struct ModalPresenterTests {
    @Test("present defaults to sheet style")
    @MainActor
    func presentDefaultsToSheetStyle() {
        // Given
        let presenter = ModalPresenter<TestModalRoute>()

        // When
        presenter.present(.about)

        // Then
        #expect(presenter.presentedSheet == .about)
        #expect(presenter.presentedFullScreen == nil)
        #expect(presenter.presentedStyle == .sheet)
    }

    @Test("present full screen sets only full screen state")
    @MainActor
    func presentFullScreenSetsOnlyFullScreenState() {
        // Given
        let presenter = ModalPresenter<TestModalRoute>()

        // When
        presenter.present(.about, as: .fullScreen)

        // Then
        #expect(presenter.presentedSheet == nil)
        #expect(presenter.presentedFullScreen == .about)
        #expect(presenter.presentedStyle == .fullScreen)
    }

    @Test("present with ignore policy keeps current presentation")
    @MainActor
    func presentWithIgnorePolicyKeepsCurrentPresentation() {
        // Given
        let presenter = ModalPresenter<TestModalRoute>()
        presenter.present(.about, as: .sheet)

        // When
        presenter.present(.about, as: .fullScreen, policy: .ignoreIfAlreadyPresented)

        // Then
        #expect(presenter.presentedSheet == .about)
        #expect(presenter.presentedFullScreen == nil)
        #expect(presenter.presentedStyle == .sheet)
    }

    @Test("present replaces current presentation by default")
    @MainActor
    func presentReplacesCurrentPresentationByDefault() {
        // Given
        let presenter = ModalPresenter<TestModalRoute>()
        presenter.present(.about, as: .sheet)

        // When
        presenter.present(.about, as: .fullScreen)

        // Then
        #expect(presenter.presentedSheet == nil)
        #expect(presenter.presentedFullScreen == .about)
        #expect(presenter.presentedStyle == .fullScreen)
    }

    @Test("dismiss clears current presentation")
    @MainActor
    func dismissClearsCurrentPresentation() {
        // Given
        let presenter = ModalPresenter<TestModalRoute>()
        presenter.present(.about, as: .sheet)

        // When
        presenter.dismiss()

        // Then
        #expect(presenter.presentedRoute == nil)
        #expect(presenter.presentedStyle == nil)
        #expect(presenter.presentedSheet == nil)
        #expect(presenter.presentedFullScreen == nil)
    }

    @Test("presentedSheet binding setter dismisses sheet")
    @MainActor
    func presentedSheetSetterDismissesSheet() {
        // Given
        let presenter = ModalPresenter<TestModalRoute>()
        presenter.present(.about, as: .sheet)

        // When
        presenter.presentedSheet = nil

        // Then
        #expect(presenter.presentedRoute == nil)
        #expect(presenter.presentedStyle == nil)
    }

    @Test("presentedFullScreen nil setter is no-op while sheet is active")
    @MainActor
    func presentedFullScreenNilSetterIsNoOpWhileSheetIsActive() {
        // Given
        let presenter = ModalPresenter<TestModalRoute>()
        presenter.present(.about, as: .sheet)

        // When
        presenter.presentedFullScreen = nil

        // Then
        #expect(presenter.presentedSheet == .about)
        #expect(presenter.presentedFullScreen == nil)
        #expect(presenter.presentedStyle == .sheet)
    }

    @Test("ignore policy keeps current route for same style")
    @MainActor
    func ignorePolicyKeepsCurrentRouteForSameStyle() {
        // Given
        let presenter = ModalPresenter<TestModalRoute>()
        presenter.present(.info(message: "first"), as: .sheet)

        // When
        presenter.present(
            .info(message: "second"),
            as: .sheet,
            policy: .ignoreIfAlreadyPresented
        )

        // Then
        #expect(presenter.presentedSheet == .info(message: "first"))
        #expect(presenter.presentedStyle == .sheet)
    }

    @Test("non-animated present and dismiss update state")
    @MainActor
    func nonAnimatedPresentAndDismissUpdateState() {
        // Given
        let presenter = ModalPresenter<TestModalRoute>()

        // When
        presenter.present(.about, as: .fullScreen, animated: false)
        presenter.dismiss(animated: false)

        // Then
        #expect(presenter.presentedRoute == nil)
        #expect(presenter.presentedStyle == nil)
    }
}
