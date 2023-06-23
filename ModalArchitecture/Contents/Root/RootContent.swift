import Foundation
import SwiftUI

final class RootContent: ModalContent {
    static let shared: RootContent = .init()

    enum Child {
        case first(FirstContent)
        case popoverA(EndContent<RootContent>)
        case popoverB(EndContent<RootContent>)
    }

    enum ChildTarget: ModalTarget {
        case popoverA
        case popoverB
    }

    final class ChildContent: ModalChildContent {
        let child: Child

        init(_ child: Child) {
            self.child = child
        }

        var node: ModalChildNode {
            switch child {
            case .first(let content):
                return content.node
            case .popoverA(let content), .popoverB(let content):
                return content.node
            }
        }

        var target: ChildTarget? {
            switch child {
            case .first:
                return nil
            case .popoverA:
                return .popoverA
            case .popoverB:
                return .popoverB
            }
        }

        func makeChildView() -> AnyView {
            switch child {
            case .first(let content):
                return AnyView(TransitionView(presenter: .init(content: content)))
            case .popoverA(let content), .popoverB(let content):
                return AnyView(TransitionView(presenter: .init(content: content)))
            }
        }
    }

    enum DialogTarget: ModalTarget {
        case dialogA
        case dialogB
    }

    typealias ParentNode = EmptyParentNode

    let node: ModalNode<RootContent>

    init() {
        self.node = .init(parent: EmptyParentNode.shared)
    }

    func makeBaseView() -> some View {
        RootView(presenter: .init(content: self))
    }
}

extension RootContent {
    func openFirstSheet() {
        node.add(.sheet(
            .init(.first(.init(parentNode: node)))
        ))
    }

    func openFirstFullScreenCover() {
        node.add(.fullScreenCover(
            .init(.first(.init(parentNode: node)))
        ))
    }

    func openAlert() {
        node.add(.alert(
            .init(
                parentNode: node,
                value: .init(
                    target: nil,
                    title: "Root Alert",
                    message: "Root Alert Message",
                    actions: [
                        .init(role: nil,
                              buttonTitle: "Open Sheet",
                              handler: { [weak self] in
                                  self?.openFirstSheet()
                        }),
                        .init(role: .cancel,
                              buttonTitle: "Cancel",
                              handler: { print("Root Alert Cancel") }),
                        .init(role: .destructive,
                              buttonTitle: "Destructive",
                              handler: { print("Root Alert Destructive") })
                    ]
                )
            )
        ))
    }

    func openDialogA() {
        node.add(.confirmationDialog(
            .init(
                parentNode: node,
                value: .init(
                    target: .dialogA,
                    title: "Root Dialog A",
                    message: "Root Dialog Message A",
                    actions: [
                        .init(role: nil,
                              buttonTitle: "OK",
                              handler: { print("Root Dialog A OK") }),
                        .init(role: .cancel,
                              buttonTitle: "Cancel",
                              handler: { print("Root Dialog A Cancel") }),
                        .init(role: .destructive,
                              buttonTitle: "Destructive",
                              handler: { print("Root Dialog A Destructive") })
                    ]
                )
            )
        ))
    }

    func openDialogB() {
        node.add(.confirmationDialog(
            .init(
                parentNode: node,
                value: .init(
                    target: .dialogB,
                    title: nil,
                    message: "Root Dialog Message B",
                    actions: [
                        .init(role: nil,
                              buttonTitle: "OK",
                              handler: { print("Root Dialog B OK") }),
                        .init(role: .cancel,
                              buttonTitle: "Cancel",
                              handler: { print("Root Dialog B Cancel") })
                    ]
                )
            )
        ))
    }

    func openPopoverA() {
        node.add(.popover(
            .init(.popoverA(.init(title: "First Popover A", parentNode: node)))
        ))
    }

    func openPopoverB() {
        node.add(.popover(
            .init(.popoverB(.init(title: "First Popover B", parentNode: node)))
        ))
    }

    func openPopoverAfter2Sec() {
        Task { [weak self] in
            try await Task.sleep(for: .seconds(2))
            self?.openPopoverA()
        }
    }

    func openSheetAfter2Sec() {
        Task { [weak self] in
            try await Task.sleep(for: .seconds(2))
            self?.openFirstSheet()
        }
    }

    func openSecondSheet() {
        let firstContent = FirstContent(parentNode: node)
        let firstNode = firstContent.node

        firstNode.add(.sheet(.init(.second(.init(parentNode: firstNode)))))
        node.add(.sheet(.init(.first(firstContent))))
    }

    func closeChild() {
        node.remove()
    }
}
