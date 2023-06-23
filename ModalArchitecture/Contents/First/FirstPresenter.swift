import Foundation

// swiftlint:disable unused_setter_value

@MainActor
final class FirstPresenter: ObservableObject {
    @Published private var modal: Modal<FirstContent>?

    private weak var content: FirstContent?
    private weak var rootContent: RootContent?

    init(
        content: FirstContent,
        rootContent: RootContent = .shared
    ) {
        self.content = content
        self.rootContent = rootContent

        content.node
            .modalPublisher
            .assign(to: &$modal)
    }
}

extension FirstPresenter {
    var isFullScreen: Bool {
        switch content?.node.parent?.modal {
        case .fullScreenCover:
            return true
        default:
            return false
        }
    }

    var popover: TransitionPopover<FirstContent>? {
        get { .init(modal: modal, targets: [.popover]) }
        set {}
    }

    func openSecondSheet() {
        content?.openSecondSheet()
    }

    func openSecondEndSheet() {
        content?.openSecondEndSheet()
    }

    func openPopover() {
        content?.openPopover()
    }

    func openAlert() {
        content?.openAlert()
    }

    func reopenFirstSheet() {
        rootContent?.openFirstSheet()
    }

    func reopenFirstFullScreen() {
        rootContent?.openFirstFullScreenCover()
    }

    func close() {
        content?.close()
    }

    func closeAfter2Sec() {
        content?.closeAfter2Sec()
    }
}
