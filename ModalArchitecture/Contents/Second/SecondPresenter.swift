import Foundation

@MainActor
final class SecondPresenter: ObservableObject {
    private weak var content: SecondContent?
    private weak var rootContent: RootContent?

    init(
        content: SecondContent,
        rootContent: RootContent = .shared
    ) {
        self.content = content
        self.rootContent = rootContent
    }
}

extension SecondPresenter {
    func reopenSecondSheet() {
        rootContent?.openSecondSheet()
    }

    func openFirstPopoverA() {
        rootContent?.openPopoverA()
    }

    func close() {
        content?.close()
    }

    func closeAll() {
        rootContent?.node.remove()
    }
}
