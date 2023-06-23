import SwiftUI

@MainActor
extension View {
    func alert<Content: ModalContent>(
        _ dialog: TransitionDialog<Content>?,
        isPresented: Binding<Bool>
    ) -> some View {
        alert(
            dialog?.title ?? "",
            isPresented: isPresented,
            presenting: dialog,
            actions: { dialog in
                ForEach(dialog.actions) { action in
                    Button(role: action.role) {
                        dialog.onAction(action)
                    } label: {
                        Text(action.buttonTitle)
                    }
                }
            },
            message: { dialog in
                Text("\(dialog.message)")
                    .onAppear { dialog.onAppear() }
                    .onDisappear { dialog.onDisappear() }
            }
        )
    }
}
