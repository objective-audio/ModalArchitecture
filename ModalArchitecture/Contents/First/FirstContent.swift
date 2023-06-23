import Foundation
import SwiftUI

final class FirstContent: ModalContent {
    enum Child {
        case second(SecondContent)
        case secondEnd(EndContent<FirstContent>)
        case popover(EndContent<FirstContent>)
    }

    enum ChildTarget: ModalTarget {
        case popover
    }

    final class ChildContent: ModalChildContent {
        let child: Child

        init(_ child: Child) {
            self.child = child
        }

        var node: ModalChildNode {
            switch child {
            case .second(let content):
                return content.node
            case .secondEnd(let content), .popover(let content):
                return content.node
            }
        }

        var target: ChildTarget? {
            switch child {
            case .second, .secondEnd:
                return nil
            case .popover:
                return .popover
            }
        }

        func makeChildView() -> AnyView {
            switch child {
            case .second(let content):
                return AnyView(TransitionView<SecondContent>(presenter: .init(content: content)))
            case .secondEnd(let content), .popover(let content):
                return AnyView(TransitionView<EndContent>(presenter: .init(content: content)))
            }
        }
    }

    typealias DialogTarget = EmptyTarget

    typealias ParentNode = ModalNode<RootContent>

    let node: ModalNode<FirstContent>

    init(parentNode: ModalNode<RootContent>) {
        self.node = .init(parent: parentNode)
    }

    func makeBaseView() -> some View {
        FirstView(presenter: .init(content: self))
    }
}

extension FirstContent {
    func openSecondSheet() {
        node.add(.sheet(
            .init(.second(.init(parentNode: node)))
        ))
    }

    func openSecondEndSheet() {
        node.add(.sheet(
            .init(.secondEnd(.init(title: "Second End", parentNode: node)))
        ))
    }

    func openPopover() {
        node.add(.popover(
            .init(.popover(.init(title: "Second Popover", parentNode: node)))
        ))
    }

    func openAlert() {
        let content = DialogContent<FirstContent>(
            parentNode: node,
            value: .init(
                target: nil,
                title: "First Alert",
                message: "Auto close after 2 seconds",
                actions: []
            )
        )

        node.add(.alert(content))

        let alertId = content.id

        Task { [weak self] in
            try await Task.sleep(for: .seconds(2))
            guard let modalNode = self?.node else { return }
            modalNode.remove(for: alertId)
        }
    }

    func close() {
        node.removeFromParent()
    }

    func closeAfter2Sec() {
        Task { [weak self] in
            try await Task.sleep(for: .seconds(2))
            self?.close()
        }
    }
}
