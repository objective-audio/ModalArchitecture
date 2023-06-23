import Foundation

@MainActor
final class EndPresenter<ParentContent: ModalContent>: ObservableObject {
    private weak var content: EndContent<ParentContent>?
    private weak var rootContent: RootContent?

    init(content: EndContent<ParentContent>,
         rootContent: RootContent = .shared) {
        self.content = content
        self.rootContent = rootContent
    }

    var title: String {
        content?.title ?? "Unknown"
    }
}

extension EndPresenter {
    func close() {
        content?.close()
    }

    func closeAll() {
        rootContent?.closeChild()
    }
}
