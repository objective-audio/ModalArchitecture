import Foundation
import QuartzCore

protocol TickWaiting {
    func wait(_ completion: @escaping () -> Void)
}

/// UIの定期実行のタイミングを待って処理を実行する
struct TickWaiter: TickWaiting {
    func wait(_ completion: @escaping () -> Void) {
        _ = TickStepper(completion)
    }
}

private final class TickStepper {
    private let completion: () -> Void
    private var ticks: Int = 0
    private var displayLink: CADisplayLink!

    fileprivate init(_ handler: @escaping () -> Void) {
        self.completion = handler

        displayLink = CADisplayLink(target: self,
                                    selector: #selector(step))
        displayLink.add(to: .current,
                        forMode: .common)
    }

    @objc private func step(displaylink: CADisplayLink) {
        ticks += 1
        if ticks >= 2 {
            displayLink.invalidate()
            completion()
        }
    }
}
