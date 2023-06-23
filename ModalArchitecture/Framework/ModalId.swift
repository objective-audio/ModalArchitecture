/// モーダルの管理で使うID
/// アプリ起動中にユニークであることが保証できれば良いのでclassをIDとしている
final class ModalId {}

extension ModalId: Hashable {
    static func == (lhs: ModalId, rhs: ModalId) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension ModalId: Identifiable {}
