import Foundation

/// モーダルの変更を一時的に予約して保持する
enum ModalReserved<Content: ModalContent> {
    case add(Modal<Content>)
    case remove
    case none
}

@MainActor
extension ModalReserved {
    var isNone: Bool {
        switch self {
        case .none:
            return true
        case .add, .remove:
            return false
        }
    }

    func isChild(for id: ModalId) -> Bool {
        switch self {
        case .add(let modal):
            return modal.childNode.id == id
        case .remove, .none:
            return false
        }
    }
}
