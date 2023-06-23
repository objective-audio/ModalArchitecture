import SwiftUI

extension View {
    /// モーダル表示の遷移が終わったタイミングを取得する
    func didAppear(_ action: @escaping () -> Void) -> some View {
        ZStack {
            DidAppearView(action: action)
            self
        }
    }
}

/// ViewControllerをラップしてviewDidAppearのタイミングを取得できるようにしたView
struct DidAppearView: UIViewControllerRepresentable {
    let action: () -> Void

    func makeUIViewController(context: Context) -> DidAppearViewController {
        let viewController = DidAppearViewController()
        viewController.action = action
        return viewController
    }

    func updateUIViewController(_ uiViewController: DidAppearViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator {}
}

final class DidAppearViewController: UIViewController {
    var action: (() -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 最初の1回だけ実行する
        action?()
        action = nil
    }
}
