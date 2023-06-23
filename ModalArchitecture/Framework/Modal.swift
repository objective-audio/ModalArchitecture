import Foundation

/// モーダルで表示する種類。子で表示するContentを保持する
enum Modal<Content: ModalContent> {
    case sheet(Content.ChildContent)
    case fullScreenCover(Content.ChildContent)
    case popover(Content.ChildContent)
    case alert(DialogContent<Content>)
    case confirmationDialog(DialogContent<Content>)
}

@MainActor
extension Modal {
    var childNode: ModalChildNode {
        switch self {
        case .sheet(let content), .fullScreenCover(let content), .popover(let content):
            return content.node
        case .alert(let content), .confirmationDialog(let content):
            return content.node
        }
    }
}
