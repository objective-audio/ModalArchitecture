import Foundation

/// AlertやConfirmation Dialogの表示に必要なデータを提供する
@MainActor
final class TransitionDialog<Content: ModalContent>: Identifiable {
    let id: ModalId
    var title: String { content?.value.title ?? "" }
    var message: String { content?.value.message ?? "" }
    var actions: [ModalDialogAction] {
        if let actions = content?.value.actions, !actions.isEmpty {
            return actions
        } else {
            return [ModalDialogAction.makeOkAction()]
        }
    }

    private weak var content: DialogContent<Content>?

    /// 表示対象のないAlert用のイニシャライザ
    init(content: DialogContent<Content>) {
        self.id = content.node.id
        self.content = content
    }

    /// 表示対象のあるConfirmationDialog用のイニシャライザ
    init?(content: DialogContent<Content>, targets: [Content.DialogTarget]) {
        if let target = content.value.target, targets.contains(target) {
            self.id = content.node.id
            self.content = content
        } else {
            return nil
        }
    }

    func onAction(_ action: ModalDialogAction) {
        content?.onAction(action)
        content = nil
    }

    func onAppear() {
        content?.onAppear()
    }

    func onDisappear() {
        content?.onDisappear()
    }
}
