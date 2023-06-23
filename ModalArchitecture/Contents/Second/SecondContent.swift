import Foundation
import SwiftUI

final class SecondContent: ModalContent {
    typealias ChildContent = EmptyChildContent
    typealias DialogTarget = EmptyTarget
    typealias ParentNode = ModalNode<FirstContent>

    let node: ModalNode<SecondContent>

    init(parentNode: ModalNode<FirstContent>) {
        self.node = .init(parent: parentNode)
    }

    func makeBaseView() -> some View {
        SecondView(presenter: .init(content: self))
    }
}

extension SecondContent {
    func close() {
        node.removeFromParent()
    }
}
