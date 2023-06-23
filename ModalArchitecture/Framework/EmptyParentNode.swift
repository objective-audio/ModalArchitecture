import Foundation

/// ルートの階層で定義するための、空の親のノード
final class EmptyParentNode: ModalParentNode {
    static let shared: EmptyParentNode = .init()

    func remove(for id: ModalId) {}
    func childDidAppear(id: ModalId) {}
    func childDidDisappear(id: ModalId) {}
    func isChild(for id: ModalId) -> Bool { true }
}
