import Foundation
import SwiftUI

// swiftlint:disable unused_setter_value

@MainActor
final class RootPresenter: ObservableObject {
    @Published private var modal: Modal<RootContent>?

    private weak var content: RootContent?

    @Published var pickerSelected: Int = 0

    init(content: RootContent) {
        self.content = content

        content.node
            .modalPublisher
            .assign(to: &$modal)
    }
}

extension RootPresenter {
    var dialogA: TransitionDialog<RootContent>? {
        guard case .confirmationDialog(let content) = modal else {
            return nil
        }
        return .init(content: content, targets: [.dialogA])
    }

    var isDialogAPresented: Bool {
        get { dialogA != nil }
        set {}
    }

    var dialogB: TransitionDialog<RootContent>? {
        guard case .confirmationDialog(let content) = modal else {
            return nil
        }
        return .init(content: content, targets: [.dialogB])
    }

    var isDialogBPresented: Bool {
        get { dialogB != nil }
        set {}
    }

    var popoverA: TransitionPopover<RootContent>? {
        get { .init(modal: modal, targets: [.popoverA]) }
        set {}
    }

    var popoverB: TransitionPopover<RootContent>? {
        get { .init(modal: modal, targets: [.popoverB]) }
        set {}
    }

    func openFirstSheet() {
        content?.openFirstSheet()
    }

    func openFirstFullScreenCover() {
        content?.openFirstFullScreenCover()
    }

    func openAlert() {
        content?.openAlert()
    }

    func openDialogA() {
        content?.openDialogA()
    }

    func openDialogB() {
        content?.openDialogB()
    }

    func openFirstPopoverA() {
        content?.openPopoverA()
    }

    func openFirstPopoverB() {
        content?.openPopoverB()
    }

    func openFirstPopoverAfter2Sec() {
        content?.openPopoverAfter2Sec()
    }

    func openFirstSheetAfter2Sec() {
        content?.openSheetAfter2Sec()
    }

    func openSecondSheet() {
        content?.openSecondSheet()
    }
}
