import SwiftUI

struct FirstView: View {
    @ObservedObject var presenter: FirstPresenter

    private var buttonTextColor: Color? {
        if presenter.isFullScreen {
            return Color.white
        } else {
            return nil
        }
    }

    var body: some View {
        ZStack {
            if presenter.isFullScreen {
                Color.teal
                    .edgesIgnoringSafeArea(.all)
            }
            VStack(spacing: 8) {
                Spacer().layoutPriority(1)
                Group {
                    Text("First")
                        .font(.largeTitle)
                        .foregroundColor(buttonTextColor)
                        .padding()
                    Button {
                        presenter.openSecondSheet()
                    } label: {
                        Text("Open Sheet")
                            .font(.title)
                            .foregroundColor(buttonTextColor)
                    }
                    Button {
                        presenter.openSecondEndSheet()
                    } label: {
                        Text("Open End Sheet")
                            .font(.title)
                            .foregroundColor(buttonTextColor)
                    }
                    Button {
                        presenter.openPopover()
                    } label: {
                        Text("Open Popover")
                            .font(.title)
                            .foregroundColor(buttonTextColor)
                    }
                    .popover(item: $presenter.popover) {
                        $0.childView()
                    }
                    Button {
                        presenter.openAlert()
                    } label: {
                        Text("Open Alert and Auto Close")
                            .font(.title)
                            .foregroundColor(buttonTextColor)
                    }
                    Button {
                        presenter.reopenFirstSheet()
                    } label: {
                        Text("Reopen First Sheet")
                            .font(.title)
                            .foregroundColor(buttonTextColor)
                    }
                    Button {
                        presenter.reopenFirstFullScreen()
                    } label: {
                        Text("Reopen First FullScreen")
                            .font(.title)
                            .foregroundColor(buttonTextColor)
                    }
                    Button {
                        presenter.close()
                    } label: {
                        Text("Close")
                            .font(.title)
                            .foregroundColor(buttonTextColor)
                    }
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
                        .foregroundColor(buttonTextColor)
                    }
                    Button {
                        presenter.closeAfter2Sec()
                    } label: {
                        Text("Close After 2sec")
                            .font(.title)
                            .foregroundColor(buttonTextColor)
                    }
                }
                Spacer().layoutPriority(1)
            }
            .padding()
        }
    }
}
