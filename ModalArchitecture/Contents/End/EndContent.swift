import Foundation
import SwiftUI

final class EndContent<ParentContent: ModalContent>: ModalContent {
    typealias ChildContent = EmptyChildContent
    typealias DialogTarget = EmptyTarget
    typealias ParentNode = ModalNode<ParentContent>

    let title: String
    let node: ModalNode<EndContent>

    init(title: String, parentNode: ModalNode<ParentContent>) {
        self.title = title
        self.node = .init(parent: parentNode)
    }

    func makeBaseView() -> some View {
        EndView(presenter: .init(content: self))
    }
}

extension EndContent {
    func close() {
        node.removeFromParent()
    }
}
