import Foundation
import Combine

/// モーダルの階層（ノード）
/// 主にここで様々なモーダルの問題を対処する
final class ModalNode<Content: ModalContent>: ModalParentNode, ModalChildNode {
    typealias State = ModalNodeState<Content>

    let id: ModalId = .init()

    /// 内部的に保持する状態
    private let stateSubject: CurrentValueSubject<State, Never> = .init(.appearing(reservedModal: nil))
    private(set) var state: State {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }

    /// Viewとバインディングするためのモーダルの状態
    var modal: Modal<Content>? { state.modal }
    var modalPublisher: AnyPublisher<Modal<Content>?, Never> {
        stateSubject
            .map(\.modal)
            .eraseToAnyPublisher()
    }

    private(set) weak var parent: Content.ParentNode?
    private let swapper: Swapper
    private let onceForAppearing: Once = .init()
    private let onceForDisappearing: Once = .init()
    private let onceForDialog: Once = .init()
    private let waiter: TickWaiting

    init(parent: Content.ParentNode,
         swapper: Swapper = .shared,
         waiter: TickWaiting = TickWaiter()) {
        self.parent = parent
        self.swapper = swapper
        self.waiter = waiter
    }

    /// 上の階層にモーダルを表示するために追加する
    func add(_ newModal: Modal<Content>) {
        switch state {
        case .appearing:
            // 自身が表示遷移中なので、開くモーダルを予約する
            state = .appearing(reservedModal: newModal)
        case .appeared:
            // 子のモーダルが表示されておらずアクティブな状態なので、モーダルを開き始める
            presentModal(newModal)
        case .childPresented(let modal):
            // 子のモーダルが表示されていてアクティブな状態なので、モーダルを閉じ始める
            dismissModal(modal: modal, reservedModal: newModal)
        case .childWaiting(let waitingId, _):
            // 子のモーダルが表示待機中なので、予約されたモーダルを入れ替える
            state = .childWaiting(waitingId: waitingId, reservedModal: newModal)
        case .childPresenting(let modal, _):
            // 子のモーダルが表示遷移中なので、次に開くモーダルを予約する
            state = .childPresenting(modal: modal, reserved: .add(newModal))
        case .childDismissing(let modal, _):
            // 子のモーダルが非表示遷移中なので、次に開くモーダルを予約する
            state = .childDismissing(modal: modal, reservedModal: newModal)
        case .disappearing:
            // すでに自身が非表示になっているので何もしない
            break
        }
    }

    /// モーダルのIDを指定して閉じる
    func remove(for id: ModalId) {
        switch state {
        case .appearing(let reservedModal), .childDismissing(_, let reservedModal):
            if reservedModal?.childNode.id == id {
                remove()
            }
        case .childWaiting(_, let modal), .childPresented(let modal):
            if modal.childNode.id == id {
                remove()
            }
        case .childPresenting(let modal, let reserved):
            // 表示中のモーダルが一致しても、次のアクションが予約されていればすでに閉じられた扱いなので無視する
            if modal.childNode.id == id && reserved.isNone {
                remove()
            } else if reserved.isChild(for: id) {
                remove()
            }
        case .appeared, .disappearing:
            break
        }
    }

    /// 表示中のモーダルを閉じる
    func remove() {
        switch state {
        case .appearing:
            // 自身が表示遷移中なので、予約されたモーダルを削除する
            state = .appearing(reservedModal: nil)
        case .childPresented(let modal):
            // 子のモーダルが表示されてアクティブな状態なので閉じ始める
            dismissModal(modal: modal, reservedModal: nil)
        case .childWaiting:
            // 子のモーダルが表示待機中なので、中断してアクティブな状態に戻す
            state = .appeared
        case .childPresenting(let modal, _):
            // 子のモーダルが表示遷移中なので、閉じる予約をする
            state = .childPresenting(modal: modal, reserved: .remove)
        case .childDismissing(let modal, _):
            // 子のモーダルが非表示遷移中なので、次に開く予約をされたモーダルを削除する
            state = .childDismissing(modal: modal, reservedModal: nil)
        case .appeared, .disappearing:
            // appeared -> モーダルが表示されていないので何もしない
            // disappearing -> すでに自身が非表示になっているので何もしない
            break
        }
    }

    /// 親から自身のモーダルを閉じる
    func removeFromParent() {
        parent?.remove(for: id)
    }

    /// 親から自身が削除されたら呼ばれ、非表示状態にする
    func didRemoveFromParent() {
        // 子孫も全て非表示状態にする
        modal?.childNode.didRemoveFromParent()
        state = .disappearing(modal: modal)
    }

    /// 自身を表示する遷移が終わったら呼ばれる
    func didAppear() {
        onceForAppearing.perform {
            // 親に遷移が終わったことを伝えて、親の状態を更新する
            parent?.childDidAppear(id: id)

            // まだ親にとって子であるなら、自身の状態を更新する
            if parent?.isChild(for: id) ?? false {
                switch state {
                case .appearing(let reservedModal):
                    if let reservedModal {
                        presentModal(reservedModal)
                    } else {
                        state = .appeared
                    }
                case .disappearing:
                    break
                case .appeared, .childWaiting, .childPresenting, .childPresented, .childDismissing:
                    assertionFailure()
                }
            }
        }
    }

    /// 自身を非表示にする遷移が終わったら呼ばれる
    func didDisappear() {
        onceForDisappearing.perform {
            removeFromParent()

            parent?.childDidDisappear(id: id)
        }
    }

    /// 子のモーダルが表示する遷移が終わったら呼ばれる
    func childDidAppear(id childId: ModalId) {
        if isChild(for: childId) {
            switch state {
            case .childPresenting(let modal, let reserved):
                switch reserved {
                case .add(let reservedModal):
                    dismissModal(modal: modal, reservedModal: reservedModal)
                case .remove:
                    dismissModal(modal: modal, reservedModal: nil)
                case .none:
                    state = .childPresented(modal: modal)
                }
            case .appeared, .childPresented, .childDismissing, .disappearing:
                break
            case .appearing, .childWaiting:
                assertionFailure()
            }
        }
    }

    /// 子のモーダルが非表示する遷移が終わったら呼ばれる
    func childDidDisappear(id childId: ModalId) {
        if case .childDismissing(let modal, let reservedModal) = state,
           modal.childNode.id == childId {
            if let reservedModal {
                presentModal(reservedModal)
            } else {
                state = .appeared
            }
        }
    }

    /// 表示中の子のモーダルとidが一致するか確認する
    func isChild(for childId: ModalId) -> Bool {
        state.modal?.childNode.id == childId
    }

    /// 子のモーダルを表示する遷移を開始する
    /// 開始して良い状態かは呼び出す前にチェックされている前提
    private func presentModal(_ newModal: Modal<Content>) {
        assert(modal == nil)

        swapper.swap()

        let id = ModalId()

        state = .childWaiting(waitingId: id, reservedModal: newModal)

        waiter.wait { [weak self] in
            // MenuやAlertなどを閉じてすぐ遷移できないことがあるので遅らせる
            if let self,
               case .childWaiting(let waitingId, let reservedModal) = self.state,
               waitingId == id {
                self.state = .childPresenting(modal: reservedModal, reserved: .none)
            }
        }
    }

    /// 子のモーダルを非表示にする遷移を開始する
    /// 開始して良い状態かは呼び出す前にチェックされている前提
    private func dismissModal(modal: Modal<Content>, reservedModal: Modal<Content>?) {
        state = .childDismissing(modal: modal, reservedModal: reservedModal)
        modal.childNode.didRemoveFromParent()
    }
}
