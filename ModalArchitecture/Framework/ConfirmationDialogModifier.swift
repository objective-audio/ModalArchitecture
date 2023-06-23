import SwiftUI

@MainActor
extension View {
    func confirmationDialog<Content: ModalContent>(
        _ dialog: TransitionDialog<Content>?,
        isPresented: Binding<Bool>
    ) -> some View {
        confirmationDialog(
            dialog?.title ?? "",
            isPresented: isPresented,
            titleVisibility: (dialog?.title != nil) ? .visible : .hidden,
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
