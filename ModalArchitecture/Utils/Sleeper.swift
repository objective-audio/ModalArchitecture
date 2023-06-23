import Foundation

protocol Sleeping {
    func sleep(for duration: Duration,
               completion: @escaping () -> Void)
}

/// 時間を指定して処理を遅延させる
struct Sleeper: Sleeping {
    func sleep(for duration: Duration,
               completion: @escaping () -> Void) {
        Task {
            try? await Task.sleep(for: duration)
            assert(!Thread.isMainThread)
            await MainActor.run {
                assert(Thread.isMainThread)
                completion()
            }
        }
    }
}
