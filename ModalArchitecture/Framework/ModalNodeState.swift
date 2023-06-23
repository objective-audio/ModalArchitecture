import Foundation

/// モーダルのノードで内部的に保持する状態
enum ModalNodeState<Content: ModalContent> {
    /// 自身が親から開かれる遷移中の状態
    case appearing(reservedModal: Modal<Content>?)
    /// 自身が開かれる遷移が終わり、子のモーダルも表示していない状態。自身の階層で操作ができる
    case appeared
    /// 子のモーダルを開き始めて、まだViewには反映していない状態。modalが入れ替わっても良いように待ちのidを別で保持している
    case childWaiting(waitingId: ModalId, reservedModal: Modal<Content>)
    /// 子のモーダルを開く遷移中の状態
    case childPresenting(modal: Modal<Content>, reserved: ModalReserved<Content>)
    /// 子のモーダルが表示されアクティブな状態。孫が表示されている可能性はある
    case childPresented(modal: Modal<Content>)
    /// このモーダルを閉じる遷移中の状態
    case childDismissing(modal: Modal<Content>, reservedModal: Modal<Content>?)
    /// 自身が閉じられる遷移中の状態。モーダルが表示されていたらそのまま残して余計な遷移をしないようにする
    case disappearing(modal: Modal<Content>?)
}

extension ModalNodeState {
    /// Viewに反映するモーダルの状態
    var modal: Modal<Content>? {
        switch self {
        case .disappearing(let modal):
            return modal
        case .childPresented(let modal):
            return modal
        case .childWaiting:
            return nil
        case .childPresenting(let modal, _):
            return modal
        case .appeared, .appearing, .childDismissing:
            return nil
        }
    }

    var isAppeared: Bool {
        switch self {
        case .appeared:
            return true
        case .appearing, .childWaiting, .childPresenting, .childPresented, .childDismissing, .disappearing:
            return false
        }
    }
}
