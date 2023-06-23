import SwiftUI

/// Menuなどを強制的に閉じるためのView
struct SwapView<Content: View>: View {
    @ObservedObject private var swapper: Swapper = .shared
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if swapper.flag {
            content()
        } else {
            content()
        }
    }
}

final class Swapper: ObservableObject {
    static let shared: Swapper = .init()

    @Published private(set) var flag: Bool = false

    func swap() {
        flag.toggle()
    }
}
