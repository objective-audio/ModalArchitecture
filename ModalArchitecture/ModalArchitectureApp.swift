import SwiftUI

let isTesting = NSClassFromString("XCTestCase") != nil

@main
struct ModalArchitectureApp: App {
    var body: some Scene {
        WindowGroup {
            if !isTesting {
                TransitionView<RootContent>(
                    presenter: .init(content: RootContent.shared)
                )
            } else {
                EmptyView()
            }
        }
    }
}
