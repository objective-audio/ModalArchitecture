import Foundation
import Combine
import SwiftUI

// swiftlint:disable unused_setter_value

/// TransitionViewに必要なデータを提供する
@MainActor
final class TransitionPresenter<Content: ModalContent>: ObservableObject {
    @Published private var modal: Modal<Content>?

    private weak var content: Content?

    private(set) lazy var baseView: Content.BaseView? = {
        return content?.makeBaseView()
    }()

    init(content: Content) {
        self.content = content

        content.node
            .modalPublisher
            .assign(to: &$modal)
    }

    var sheetId: ModalId? {
        get {
            guard case .sheet(let content) = modal else {
                return nil
            }
            return content.node.id
        }
        set {}
    }

    var fullScreenCoverId: ModalId? {
        get {
            guard case .fullScreenCover(let content) = modal else {
                return nil
            }
            return content.node.id
        }
        set {}
    }

    var alert: TransitionDialog<Content>? {
        guard case .alert(let content) = modal else {
            return nil
        }
        return .init(content: content)
    }

    var alertTitle: String {
        return alert?.title ?? ""
    }

    var isAlertPresented: Bool {
        get { alert != nil }
        set {}
    }

    func didAppear() {
        content?.node.didAppear()
    }

    func didDisappear() {
        content?.node.didDisappear()
    }

    func sheetChildView(_ childId: ModalId) -> AnyView {
        guard case .sheet(let childContent) = modal,
              childContent.node.id == childId else {
            print("Child Sheet Missing. \(self.self)")
            return AnyView(EmptyView())
        }

        return childContent.makeChildView()
    }

    func fullScreenCoverChildView(_ childId: ModalId) -> AnyView {
        guard case .fullScreenCover(let childContent) = modal,
              childContent.node.id == childId else {
            print("Child FullScreenCover Missing. \(self.self)")
            return AnyView(EmptyView())
        }

        return childContent.makeChildView()
    }
}
