import Foundation

/// 処理を1回だけ実行するためのクラス
final class Once {
    private var isPerformed: Bool = false

    func perform(_ action: () -> Void) {
        if !isPerformed {
            isPerformed = true
            action()
        }
    }
}
