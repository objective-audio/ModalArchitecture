import SwiftUI

struct EndView<ParentContent: ModalContent>: View {
    @ObservedObject var presenter: EndPresenter<ParentContent>

    var body: some View {
        VStack(spacing: 8) {
            Text(presenter.title)
                .font(.largeTitle)
                .padding()
            Button {
                presenter.close()
            } label: {
                Text("Close")
                    .font(.title)
            }
            Button {
                presenter.closeAll()
            } label: {
                Text("Close All")
                    .font(.title)
            }
        }
        .padding()
    }
}
