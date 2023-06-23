import SwiftUI

/// AlertやConfirmation DialogのViewで扱うための値
struct ModalDialog<Target: ModalTarget> {
    let target: Target?
    let title: String?
    let message: String
    let actions: [ModalDialogAction]
}

struct ModalDialogAction: Identifiable {
    let id: ModalId = .init()
    let role: ButtonRole?
    let buttonTitle: String
    let handler: (() -> Void)?

    static func makeOkAction() -> ModalDialogAction {
        .init(role: nil, buttonTitle: "OK", handler: nil)
    }
}
