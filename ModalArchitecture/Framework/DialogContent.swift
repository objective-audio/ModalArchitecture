import Foundation
import SwiftUI

/// AlertとConfirmation DialogのContent
final class DialogContent<ParentContent: ModalContent>: ModalContent {
    typealias ChildContent = EmptyChildContent
    typealias BaseView = EmptyView
    typealias DialogTarget = EmptyTarget
    typealias ParentNode = ModalNode<ParentContent>

    let node: ModalNode<DialogContent<ParentContent>>
    let value: ModalDialog<ParentContent.DialogTarget>
    let sleeper: Sleeping

    init(parentNode: ParentNode,
         value: ModalDialog<ParentContent.DialogTarget>,
         sleeper: Sleeping = Sleeper()) {
        self.node = .init(parent: parentNode)
        self.value = value
        self.sleeper = sleeper
    }

    func makeBaseView() -> EmptyView { fatalError() }

    func onAction(_ action: ModalDialogAction) {
        node.didAppear()

        let isAppeared = node.state.isAppeared

        node.didDisappear()

        if isAppeared {
            action.handler?()
        }
    }

    func onAppear() {
        sleeper.sleep(for: .milliseconds(500)) { [weak self] in
            self?.node.didAppear()
        }
    }

    func onDisappear() {
        node.didDisappear()
    }
}
