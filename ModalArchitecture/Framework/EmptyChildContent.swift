import SwiftUI

/// モーダルを表示しない階層で定義するための空の子のContent
final class EmptyChildContent: ModalChildContent {
    var node: ModalChildNode { fatalError() }
    var target: EmptyTarget? { nil }
    func makeChildView() -> AnyView { fatalError() }
}
