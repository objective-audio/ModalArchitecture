// swiftlint:disable file_length type_body_length

import XCTest
import SwiftUI
import Combine
@testable import ModalArchitecture

final class TickWaiterMock: TickWaiting {
    private var completion: (() -> Void)?

    func wait(_ completion: @escaping () -> Void) {
        self.completion = completion
    }

    func resume() -> Bool {
        if let completion {
            completion()
            self.completion = nil
            return true
        } else {
            return false
        }
    }
}

final class SleeperMock: Sleeping {
    private var completion: (() -> Void)?

    func sleep(for duration: Duration, completion: @escaping () -> Void) {
        self.completion = completion
    }

    func resume() -> Bool {
        if let completion {
            completion()
            self.completion = nil
            return true
        } else {
            return false
        }
    }
}

private enum ExpectedReserved {
    case add(ModalId)
    case none
    case ignore
}

private enum ExpectedReservedWithRemove {
    case add(ModalId)
    case remove
    case none
    case ignore
}

private enum ExpectedState {
    case appearing(reserved: ExpectedReserved)
    case appeared
    case childWaiting(id: ModalId)
    case childPresenting(id: ModalId, reserved: ExpectedReservedWithRemove)
    case childPresented(id: ModalId)
    case childDismissing(id: ModalId, reserved: ExpectedReserved)
    case disappearing
}

@MainActor
final class ModalNodeTests: XCTestCase {
    var waiter: TickWaiterMock!
    var sleeper: SleeperMock!

    override func setUp() {
        super.setUp()

        waiter = .init()
        sleeper = .init()
    }

    override func tearDown() {
        waiter = nil
        sleeper = nil

        super.tearDown()
    }

    func test_didAppearが呼ばれるとaddしたmodalが反映される() {
        let rootNode = makeRootNode()

        XCTAssertNil(rootNode.modal)

        let firstContent = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContent))))

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .appearing(reserved: .add(firstContent.id))))

        rootNode.didAppear()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContent.id)))

        XCTAssertTrue(waiter.resume())

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContent.id, reserved: .none)))
    }

    func test_addしてもdidAppearが呼ばれるまでにremoveしたらmodalはnilで待機() {
        let rootNode = makeRootNode()

        XCTAssertNil(rootNode.modal)

        let firstContent = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContent))))
        rootNode.remove()
        rootNode.didAppear()

        XCTAssertFalse(waiter.resume())

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .appeared))
    }

    func test_didAppear後には即座にaddできる() {
        let rootNode = makeRootNode()
        rootNode.didAppear()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .appeared))

        let firstContent = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContent))))

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContent.id)))

        XCTAssertTrue(waiter.resume())

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContent.id, reserved: .none)))
    }

    func test_didAppear後にaddしてもmodalに反映される前にremoveしたらmodalはnilで待機() {
        let rootNode = makeRootNode()
        rootNode.didAppear()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .appeared))

        let firstContent = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContent))))

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContent.id)))

        rootNode.remove()

        XCTAssertTrue(waiter.resume())

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .appeared))
    }

    func test_addした後のremoveは子のdidAppearが呼ばれると反映される() {
        let rootNode = makeRootNode()
        rootNode.didAppear()
        let firstContent = FirstContent(parentNode: rootNode)

        rootNode.add(.sheet(.init(.first(firstContent))))

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContent.id)))

        XCTAssertTrue(waiter.resume())

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContent.id, reserved: .none)))

        rootNode.remove()

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContent.id, reserved: .remove)))

        firstContent.node.didAppear()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContent.id, reserved: .none)))
    }

    func test_addした後のaddは子のdidAppearが呼ばれるとdismissされてからpresentされる() {
        let rootNode = makeRootNode()
        rootNode.didAppear()

        let firstContentA = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentA))))

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContentA.id)))

        XCTAssertTrue(waiter.resume())

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentA.id, reserved: .none)))

        let firstContentB = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentB))))

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentA.id, reserved: .add(firstContentB.id))))

        firstContentA.node.didAppear()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .add(firstContentB.id))))

        firstContentA.node.didDisappear()

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContentB.id)))

        XCTAssertTrue(waiter.resume())

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentB.id, reserved: .none)))
    }

    func test_addしてmodalが反映される前にaddしたら入れ替わる() {
        let rootNode = makeRootNode()
        rootNode.didAppear()

        let firstContentA = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentA))))

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContentA.id)))

        let firstContentB = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentB))))

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContentB.id)))

        XCTAssertTrue(waiter.resume())

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentB.id, reserved: .none)))

        firstContentB.node.didAppear()

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresented(id: firstContentB.id)))
    }

    func test_addされ子のdidAppearが呼ばれたら即座にremoveできる() {
        let rootNode = makeRootNode()
        rootNode.didAppear()
        let firstContent = FirstContent(parentNode: rootNode)
        let firstNode = firstContent.node

        rootNode.add(.sheet(.init(.first(firstContent))))

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContent.id)))

        XCTAssertTrue(waiter.resume())

        firstNode.didAppear()

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresented(id: firstContent.id)))

        rootNode.remove()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContent.id, reserved: .none)))

        firstNode.didDisappear()

        // 完全に子がdismissされたら解放される
        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .appeared))
    }

    func test_addされ子のdidAppearが呼ばれたら即座にaddできる() {
        let rootNode = makeRootNode()
        rootNode.didAppear()

        let firstContentA = FirstContent(parentNode: rootNode)
        let firstNodeA = firstContentA.node
        rootNode.add(.sheet(.init(.first(firstContentA))))

        XCTAssertTrue(waiter.resume())

        firstNodeA.didAppear()

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresented(id: firstContentA.id)))

        let firstContentB = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentB))))

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .add(firstContentB.id))))

        firstNodeA.didDisappear()

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContentB.id)))

        XCTAssertTrue(waiter.resume())

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentB.id, reserved: .none)))
    }

    func test_子がremoveされた後のaddは子のdidDisappearが呼ばれると反映される() {
        let rootNode = makeRootNode()
        rootNode.didAppear()

        let firstContentA = FirstContent(parentNode: rootNode)
        let firstNodeA = firstContentA.node
        rootNode.add(.sheet(.init(.first(firstContentA))))

        XCTAssertTrue(waiter.resume())

        firstNodeA.didAppear()
        rootNode.remove()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .none)))

        let firstContentB = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentB))))

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .add(firstContentB.id))))

        firstNodeA.didDisappear()

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContentB.id)))

        XCTAssertTrue(waiter.resume())

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentB.id, reserved: .none)))
    }

    func test_子のdismiss中にaddされてもremoveするとdidDisappearが呼ばれたらmodalはnilで待機() {
        let rootNode = makeRootNode()
        rootNode.didAppear()

        let firstContentA = FirstContent(parentNode: rootNode)
        let firstNodeA = firstContentA.node
        rootNode.add(.sheet(.init(.first(firstContentA))))

        XCTAssertTrue(waiter.resume())

        firstNodeA.didAppear()
        rootNode.remove()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .none)))

        let firstContentB = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentB))))

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .add(firstContentB.id))))

        rootNode.remove()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .none)))

        firstNodeA.didDisappear()

        XCTAssertTrue(isMatch(rootNode.state, .appeared))

        XCTAssertFalse(waiter.resume())

        XCTAssertNil(rootNode.modal)
    }

    func test_dialogの遷移_onAppearが呼ばれた後にonDisappearが呼ばれ閉じる() {
        let rootNode = makeRootNode()

        let dialogContent = DialogContent(
            parentNode: rootNode,
            value: .init(
                target: nil,
                title: "title",
                message: "message",
                actions: []
            ), sleeper: sleeper)
        rootNode.add(.alert(dialogContent))

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .appearing(reserved: .add(dialogContent.id))))

        rootNode.didAppear()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: dialogContent.id)))

        XCTAssertTrue(waiter.resume())

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: dialogContent.id, reserved: .none)))

        dialogContent.onAppear()

        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: dialogContent.id, reserved: .none)))

        XCTAssertTrue(sleeper.resume())

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresented(id: dialogContent.id)))

        dialogContent.onDisappear()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .appeared))
    }

    func test_dialogの遷移_onAppearの前にonDisappearが呼ばれても閉じられる() {
        let rootNode = makeRootNode()

        let dialogContent = DialogContent(
            parentNode: rootNode,
            value: .init(
                target: nil,
                title: "title",
                message: "message",
                actions: []
            ), sleeper: sleeper)
        rootNode.add(.alert(dialogContent))

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .appearing(reserved: .add(dialogContent.id))))

        rootNode.didAppear()

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: dialogContent.id)))

        XCTAssertTrue(waiter.resume())

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: dialogContent.id, reserved: .none)))

        dialogContent.onDisappear()

        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: dialogContent.id, reserved: .remove)))

        dialogContent.onAppear()

        XCTAssertNotNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: dialogContent.id, reserved: .remove)))

        XCTAssertTrue(sleeper.resume())

        XCTAssertNil(rootNode.modal)
        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: dialogContent.id, reserved: .none)))
    }

    func test_dialogの遷移_onActionが呼ばれonAppearを待たずに閉じる() {
        let rootNode = makeRootNode()

        var isHandlerCalled: Bool = false
        let handler: () -> Void = {
            isHandlerCalled = true
        }

        let dialogContent = DialogContent(
            parentNode: rootNode,
            value: .init(
                target: nil,
                title: "title",
                message: "message",
                actions: [.init(role: .none, buttonTitle: "", handler: handler)]
            ), sleeper: sleeper)
        let dialogNode = dialogContent.node

        rootNode.add(.alert(dialogContent))

        XCTAssertTrue(isMatch(dialogContent.node.state, .appearing(reserved: .none)))

        rootNode.didAppear()

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: dialogNode.id)))

        XCTAssertTrue(waiter.resume())

        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: dialogNode.id, reserved: .none)))

        dialogContent.onAction(dialogContent.value.actions[0])

        XCTAssertTrue(isHandlerCalled)
        XCTAssertTrue(isMatch(dialogContent.node.state, .disappearing))
    }

    func test_dialog_すでに閉じられていたらボタンのアクションは実行されない() {
        let rootNode = makeRootNode()

        var isHandlerCalled: Bool = false
        let handler: () -> Void = {
            isHandlerCalled = true
        }

        let dialogContent = DialogContent(
            parentNode: rootNode,
            value: .init(
                target: nil,
                title: "title",
                message: "message",
                actions: [.init(role: .none, buttonTitle: "", handler: handler)]
            ), sleeper: sleeper)

        rootNode.didAppear()
        rootNode.add(.alert(dialogContent))

        XCTAssertTrue(waiter.resume())

        dialogContent.onAppear()

        XCTAssertTrue(sleeper.resume())

        dialogContent.onDisappear()

        XCTAssertTrue(isMatch(dialogContent.node.state, .disappearing))

        dialogContent.onAction(dialogContent.value.actions[0])

        XCTAssertFalse(isHandlerCalled)
    }

    func test_appearedでremoveを呼んでも何も起きない() {
        let rootNode = makeRootNode()

        rootNode.didAppear()

        let firstContent = FirstContent(parentNode: rootNode)
        let firstNode = firstContent.node
        rootNode.add(.sheet(.init(.first(firstContent))))

        XCTAssertTrue(waiter.resume())

        firstNode.didAppear()

        XCTAssertTrue(isMatch(firstNode.state, .appeared))

        firstNode.remove()

        XCTAssertTrue(isMatch(firstNode.state, .appeared))
    }

    func test_disappearingでremoveを呼んでも何も起きない() {
        let rootNode = makeRootNode()

        rootNode.didAppear()

        let firstContent = FirstContent(parentNode: rootNode)
        let firstNode = firstContent.node
        rootNode.add(.sheet(.init(.first(firstContent))))

        XCTAssertTrue(waiter.resume())

        firstNode.didAppear()
        firstNode.didRemoveFromParent()

        XCTAssertTrue(isMatch(firstNode.state, .disappearing))

        firstNode.remove()

        XCTAssertTrue(isMatch(firstNode.state, .disappearing))
    }

    func test_appearingでremoveForを呼んで予約が削除される() {
        let rootNode = makeRootNode()

        let firstContentA = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentA))))

        XCTAssertTrue(isMatch(rootNode.state, .appearing(reserved: .add(firstContentA.id))))

        rootNode.remove(for: firstContentA.id)

        XCTAssertTrue(isMatch(rootNode.state, .appearing(reserved: .none)))
    }

    func test_childWaitingでremoveForを呼んで開くのを中断() {
        let rootNode = makeRootNode()

        rootNode.didAppear()

        let firstContentA = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentA))))

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContentA.id)))

        rootNode.remove(for: firstContentA.id)

        XCTAssertTrue(isMatch(rootNode.state, .appeared))
    }

    func test_childPresentingでremoveForを呼んで閉じる予約がされる() {
        let rootNode = makeRootNode()

        rootNode.didAppear()

        let firstContentA = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentA))))

        XCTAssertTrue(waiter.resume())

        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentA.id, reserved: .none)))

        rootNode.remove(for: firstContentA.id)

        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentA.id, reserved: .remove)))
    }

    func test_childPresentingでaddの予約をしremoveForを呼んで閉じる予約に変わる() {
        let rootNode = makeRootNode()

        rootNode.didAppear()

        let firstContentA = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentA))))

        XCTAssertTrue(waiter.resume())

        let firstContentB = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentB))))

        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentA.id, reserved: .add(firstContentB.id))))

        // 元々開こうとしていたidを指定しても変わらない
        rootNode.remove(for: firstContentA.id)
        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentA.id, reserved: .add(firstContentB.id))))

        rootNode.remove(for: firstContentB.id)

        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentA.id, reserved: .remove)))
    }

    func test_childPresentedでremoveForを呼んで閉じる() {
        let rootNode = makeRootNode()

        rootNode.didAppear()

        let firstContent = FirstContent(parentNode: rootNode)
        let firstNode = firstContent.node
        rootNode.add(.sheet(.init(.first(firstContent))))
        XCTAssertTrue(waiter.resume())
        firstNode.didAppear()

        XCTAssertTrue(isMatch(rootNode.state, .childPresented(id: firstContent.id)))

        rootNode.remove(for: firstContent.id)

        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContent.id, reserved: .none)))
    }

    func test_childDismissingでremoveForを呼んで予約されたものが削除される() {
        let rootNode = makeRootNode()

        rootNode.didAppear()

        let firstContentA = FirstContent(parentNode: rootNode)
        let firstNodeA = firstContentA.node
        rootNode.add(.sheet(.init(.first(firstContentA))))
        XCTAssertTrue(waiter.resume())
        firstNodeA.didAppear()
        rootNode.remove()
        let firstContentB = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentB))))

        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .add(firstContentB.id))))

        rootNode.remove(for: firstContentA.id)

        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .add(firstContentB.id))))

        rootNode.remove(for: firstContentB.id)

        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .none)))
    }

    func test_removeForを別のIdで呼んでも無視される() {
        let otherId = ModalId()

        let rootNode = makeRootNode()

        rootNode.didAppear()

        let firstContentA = FirstContent(parentNode: rootNode)
        let firstNodeA = firstContentA.node
        rootNode.add(.sheet(.init(.first(firstContentA))))

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContentA.id)))
        XCTAssertTrue(isMatch(firstNodeA.state, .appearing(reserved: .none)))

        rootNode.remove(for: otherId)

        XCTAssertTrue(isMatch(rootNode.state, .childWaiting(id: firstContentA.id)))
        XCTAssertTrue(isMatch(firstNodeA.state, .appearing(reserved: .none)))

        XCTAssertTrue(waiter.resume())

        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentA.id, reserved: .none)))

        rootNode.remove(for: otherId)

        XCTAssertTrue(isMatch(rootNode.state, .childPresenting(id: firstContentA.id, reserved: .none)))

        firstNodeA.didAppear()

        XCTAssertTrue(isMatch(rootNode.state, .childPresented(id: firstContentA.id)))

        rootNode.remove(for: otherId)

        XCTAssertTrue(isMatch(rootNode.state, .childPresented(id: firstContentA.id)))

        rootNode.remove()

        let firstContentB = FirstContent(parentNode: rootNode)
        rootNode.add(.sheet(.init(.first(firstContentB))))

        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .add(firstContentB.id))))
        XCTAssertTrue(isMatch(firstNodeA.state, .disappearing))

        rootNode.remove(for: firstContentA.id)
        rootNode.remove(for: otherId)

        XCTAssertTrue(isMatch(rootNode.state, .childDismissing(id: firstContentA.id, reserved: .add(firstContentB.id))))
        XCTAssertTrue(isMatch(firstNodeA.state, .disappearing))
    }
}

private extension ModalNodeTests {
    func makeRootNode() -> ModalNode<RootContent> {
        ModalNode<RootContent>(
            parent: EmptyParentNode.shared,
            waiter: waiter
        )
    }

    func isMatch<Content: ModalContent>(_ state: ModalNodeState<Content>, _ expected: ExpectedState) -> Bool {
        switch (state, expected) {
        case (.appearing(let reservedModal), .appearing(let reserved)):
            return isMatch(reservedModal, reserved)
        case (.appeared, .appeared):
            return true
        case (.childWaiting(_, let reservedModal), .childWaiting(let id)):
            return reservedModal.childNode.id == id
        case (.childPresenting(let modal, let reserved), .childPresenting(let id, let expectedReserved)):
            return modal.childNode.id == id && isMatch(reserved, expectedReserved)
        case (.childPresented(let modal), .childPresented(let id)):
            return modal.childNode.id == id
        case (.childDismissing(let modal, let reservedModal), .childDismissing(let id, let expectedReserved)):
            return modal.childNode.id == id && isMatch(reservedModal, expectedReserved)
        case (.disappearing, .disappearing):
            return true
        default:
            return false
        }
    }

    func isMatch<Content: ModalContent>(
        _ reserved: ModalReserved<Content>,
        _ expected: ExpectedReservedWithRemove
    ) -> Bool {
        switch (reserved, expected) {
        case (.add(let modal), .add(let id)):
            return modal.childNode.id == id
        case (.remove, .remove):
            return true
        case (.none, .none):
            return true
        case (_, .ignore):
            return true
        default:
            return false
        }
    }

    func isMatch<Content: ModalContent>(_ modal: Modal<Content>?, _ expected: ExpectedReserved) -> Bool {
        switch expected {
        case .add(let id):
            guard modal?.childNode.id == id else { return false }
        case .none:
            guard modal == nil else { return false }
        case .ignore:
            break
        }
        return true
    }
}
