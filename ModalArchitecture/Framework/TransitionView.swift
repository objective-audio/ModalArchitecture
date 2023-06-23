import SwiftUI

/// モーダルの階層の中で、表示する対象が画面全体の種類のモーダル遷移を行うView
struct TransitionView<Content: ModalContent>: View {
    @ObservedObject var presenter: TransitionPresenter<Content>

    var body: some View {
        presenter.baseView
        .didAppear {
            presenter.didAppear()
        }
        .onDisappear {
            presenter.didDisappear()
        }
        .sheet(
            item: $presenter.sheetId,
            content: { sheetId in
                presenter.sheetChildView(sheetId)
            })
        .fullScreenCover(
            item: $presenter.fullScreenCoverId,
            content: { fullScreenCoverId in
                presenter.fullScreenCoverChildView(fullScreenCoverId)
            })
        .alert(
            presenter.alert,
            isPresented: $presenter.isAlertPresented
        )
    }
}
