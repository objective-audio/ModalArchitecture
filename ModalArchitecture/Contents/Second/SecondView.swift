import SwiftUI

struct SecondView: View {
    @ObservedObject var presenter: SecondPresenter

    var body: some View {
        VStack(spacing: 8) {
            Text("Second")
                .font(.largeTitle)
                .padding()
            Button {
                presenter.reopenSecondSheet()
            } label: {
                Text("Reopen Second Sheet")
                    .font(.title)
            }
            Button {
                presenter.openFirstPopoverA()
            } label: {
                Text("Open First Popover")
                    .font(.title)
            }
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
