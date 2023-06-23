import SwiftUI

struct RootView: View {
    @ObservedObject var presenter: RootPresenter

    var body: some View {
        VStack(spacing: 8) {
            Spacer().layoutPriority(1)
            Group {
                Text("Root")
                    .font(.largeTitle)
                    .padding()
                Button {
                    presenter.openFirstSheet()
                } label: {
                    Text("Open Sheet")
                        .font(.title)
                }
                Button {
                    presenter.openFirstSheetAfter2Sec()
                } label: {
                    Text("Open Sheet After 2sec")
                        .font(.title)
                }
                Button {
                    presenter.openSecondSheet()
                } label: {
                    Text("Open Second Sheet")
                        .font(.title)
                }
                Button {
                    presenter.openFirstFullScreenCover()
                } label: {
                    Text("Open Full Screen Cover")
                        .font(.title)
                }
                Button {
                    presenter.openFirstPopoverA()
                } label: {
                    Text("Open Popover A")
                        .font(.title)
                }
                .popover(item: $presenter.popoverA) {
                    $0.childView()
                }
                Button {
                    presenter.openFirstPopoverB()
                } label: {
                    Text("Open Popover B")
                        .font(.title)
                }
                .popover(item: $presenter.popoverB) {
                    $0.childView()
                }
                Button {
                    presenter.openFirstPopoverAfter2Sec()
                } label: {
                    Text("Open Popover After 2sec")
                        .font(.title)
                }
            }
            Group {
                Button {
                    presenter.openAlert()
                } label: {
                    Text("Open Alert")
                        .font(.title)
                }
                Button {
                    presenter.openDialogA()
                } label: {
                    Text("Open Confirmation Dialog A")
                        .font(.title)
                }
                .confirmationDialog(
                    presenter.dialogA,
                    isPresented: $presenter.isDialogAPresented
                )
                Button {
                    presenter.openDialogB()
                } label: {
                    Text("Open Confirmation Dialog B")
                        .font(.title)
                }
                .confirmationDialog(
                    presenter.dialogB,
                    isPresented: $presenter.isDialogBPresented
                )
            }
            Spacer(minLength: 100).layoutPriority(0)
            Group {
                SwapView {
                    Menu("Menu") {
                        Button("One") {
                            print("Menu One Called")
                        }
                        Button("Two") {
                            print("Menu Two Called")
                        }
                    }
                    .font(.title)
                }
                SwapView {
                    Picker("Picker",
                           selection: $presenter.pickerSelected) {
                        Text("Zero").tag(0)
                        Text("One").tag(1)
                        Text("Two").tag(2)
                    }
                }
            }
            Spacer().layoutPriority(1)
        }
        .padding()
    }
}
