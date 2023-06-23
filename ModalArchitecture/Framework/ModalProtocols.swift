import Foundation
import Combine
import SwiftUI

/// 親のノードに必要なインターフェース
protocol ModalParentNode: AnyObject {
    func remove(for id: ModalId)
    func childDidAppear(id: ModalId)
    func childDidDisappear(id: ModalId)
    func isChild(for id: ModalId) -> Bool
}

/// Sheetなどのモーダルの内容に必要なインターフェース
@MainActor
protocol ModalContent: AnyObject {
    associatedtype ChildContent: ModalChildContent
    associatedtype BaseView: View
    associatedtype DialogTarget: ModalTarget
    associatedtype ParentNode: ModalParentNode

    var node: ModalNode<Self> { get }
    func makeBaseView() -> BaseView
}

extension ModalContent {
    var id: ModalId { node.id }
}

/// モーダルの子のノードに必要なインターフェース
@MainActor
protocol ModalChildNode {
    var id: ModalId { get }
    func didRemoveFromParent()
}

/// 子のモーダルの内容で必要なインターフェース
@MainActor
protocol ModalChildContent: AnyObject {
    associatedtype Target: ModalTarget

    var node: any ModalChildNode { get }
    var target: Target? { get }
    func makeChildView() -> AnyView
}

/// PopoverやDialogなどで指し示す先の対象
protocol ModalTarget: Equatable {
}
