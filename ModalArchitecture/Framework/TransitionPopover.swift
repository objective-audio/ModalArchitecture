import SwiftUI

/// Popoverの表示に必要なデータを提供する
@MainActor
final class TransitionPopover<Content: ModalContent>: Identifiable {
    let id: ModalId
    private weak var content: Content.ChildContent?

    init?(modal: Modal<Content>?, targets: [Content.ChildContent.Target]) {
        if case .popover(let childContent) = modal,
           let target = childContent.target,
           targets.contains(target) {
            self.id = childContent.node.id
            self.content = childContent
        } else {
            return nil
        }
    }

    func childView() -> AnyView {
        guard let view = content?.makeChildView() else {
            print("Child Popover Missing.")
            return AnyView(EmptyView())
        }
        return view
    }
}
