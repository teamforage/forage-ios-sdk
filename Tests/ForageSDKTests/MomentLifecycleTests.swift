//
//  MomentLifecycleTests.swift
//  ForageSDKTests
//
//  © 2025 Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

/// Records every log, since a moment logs more than once.
private final class RecordingLogger: NoopLogger {
    struct Entry {
        let level: String
        let message: String
        let attributes: [String: Encodable]?
    }

    var entries: [Entry] = []

    required init(_ config: ForageLoggerConfig? = nil) {
        super.init(config)
    }

    override func notice(_ message: String, attributes: [String: Encodable]?) {
        entries.append(Entry(level: "notice", message: message, attributes: attributes))
    }

    override func info(_ message: String, attributes: [String: Encodable]?) {
        entries.append(Entry(level: "info", message: message, attributes: attributes))
    }

    override func error(_ message: String, error: Error?, attributes: [String: Encodable]?) {
        entries.append(Entry(level: "error", message: message, attributes: attributes))
    }

    func last(containing text: String) -> Entry? {
        entries.last { $0.message.contains(text) }
    }

    /// The attributes of the last metric with this `event_name`.
    func metric(_ eventName: String) -> [String: Encodable]? {
        entries.last { $0.attributes?["event_name"] as? String == eventName }?.attributes
    }
}

/// A clock tests move forward by hand.
private final class TestClock {
    var now = Date(timeIntervalSince1970: 0)

    func advance(milliseconds: Double) {
        now += milliseconds / 1000
    }
}

final class MomentLifecycleTests: XCTestCase {
    private let momentURL = URL(string: "https://custom-checkout.dev.joinforage.app/payment/collect-pin?paymentRef=abc")!
    private var logger: RecordingLogger!
    private var clock: TestClock!
    private var results: [Result<MomentResult, Error>] = []

    override func setUp() {
        super.setUp()
        ForageSDK.setup(ForageSDK.Config(merchantID: "mid/123", sessionToken: "dev_secretToken"))
        logger = RecordingLogger()
        ForageSDK.logger = logger
        ForageSDK.shared.isMomentOpen = false
        clock = TestClock()
        results = []
    }

    override func tearDown() {
        ForageSDK.shared.isMomentOpen = false
        ForageSDK.logger = nil
        super.tearDown()
    }

    private func makeViewController(loadDeadline: TimeInterval = 30) -> MomentViewController {
        let clock = clock!
        return MomentViewController(
            url: momentURL,
            merchantID: "mid/123",
            sessionToken: "dev_secretToken",
            environment: .dev,
            telemetry: MomentTelemetry(momentName: "payment_collect_pin", logger: logger, now: { clock.now }),
            loadDeadline: loadDeadline
        ) { [unowned self] result in
            results.append(result)
        }
    }

    /// Opens a moment through `ForageSDK` and returns its view controller, without presenting it.
    @discardableResult
    private func openMoment(
        _ moment: Moment = .paymentCollectPin(paymentRef: "abc"),
        completion: ((Result<MomentResult, Error>) -> Void)? = nil
    ) -> MomentViewController? {
        var presented: MomentViewController?
        ForageSDK.shared.openMoment(moment, completion: completion ?? { [unowned self] in results.append($0) }) {
            presented = $0
        }
        return presented
    }

    private func forageError(_ result: Result<MomentResult, Error>?) -> ForageError? {
        guard case let .failure(error) = result else { return nil }
        return error as? ForageError
    }

    // MARK: Outcomes

    func testSuccess_shouldComplete() throws {
        makeViewController().handle(.success)
        XCTAssertEqual(try results.first?.get(), .completed)
    }

    func testFailure_shouldFailWithThePagesError() {
        let error = ForageError.create(code: "ebt_error_55", httpStatusCode: 400, message: "Invalid PIN")
        makeViewController().handle(.failure(error))
        XCTAssertEqual(forageError(results.first), error)
    }

    func testClosed_shouldDismiss() throws {
        makeViewController().handle(.closed)
        XCTAssertEqual(try results.first?.get(), .dismissed)
    }

    func testSwipingTheSheetAway_shouldDismiss() throws {
        let viewController = makeViewController()
        viewController.presentationControllerDidDismiss(
            UIPresentationController(presentedViewController: viewController, presenting: nil)
        )
        XCTAssertEqual(try results.first?.get(), .dismissed)
    }

    func testSettle_shouldOnlyReportTheFirstOutcome() throws {
        let viewController = makeViewController()
        viewController.handle(.success)
        viewController.handle(.closed)
        viewController.handle(.failure(CommonErrors.UNKNOWN_SERVER_ERROR))
        viewController.presentationControllerDidDismiss(
            UIPresentationController(presentedViewController: viewController, presenting: nil)
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(try results.first?.get(), .completed)
    }

    // MARK: Load deadline

    func testLoadDeadline_givenThePageNeverGetsReady_shouldFailWithTimeoutError() {
        let viewController = makeViewController(loadDeadline: 0.05)
        viewController.startLoadDeadline()

        let timedOut = expectation(description: "timed out")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { timedOut.fulfill() }
        wait(for: [timedOut], timeout: 1)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(forageError(results.first)?.code, "timeout_error")
        XCTAssertEqual(forageError(results.first)?.httpStatusCode, 504)
    }

    func testLoadDeadline_givenThePageGetsReady_shouldNotFail() {
        let viewController = makeViewController(loadDeadline: 0.05)
        viewController.startLoadDeadline()
        viewController.handle(.ready)

        let waited = expectation(description: "waited past the deadline")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { waited.fulfill() }
        wait(for: [waited], timeout: 1)

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: createMoment

    func testOpenMoment_givenAMomentIsAlreadyOpen_shouldFailWithUserError() throws {
        XCTAssertNotNil(openMoment())

        var second: Result<MomentResult, Error>?
        XCTAssertNil(openMoment(completion: { second = $0 }))

        XCTAssertEqual(forageError(second)?.code, "user_error")
        XCTAssertEqual(forageError(second)?.httpStatusCode, 400)
        XCTAssertTrue(ForageSDK.shared.isMomentOpen)
    }

    func testOpenMoment_afterTheMomentSettles_shouldAllowAnother() throws {
        let first = try XCTUnwrap(openMoment())
        first.handle(.closed)

        XCTAssertFalse(ForageSDK.shared.isMomentOpen)
        XCTAssertNotNil(openMoment())
    }

    func testOpenMoment_givenAnEmptyParam_shouldFailWithUserError() {
        XCTAssertNil(openMoment(.paymentCollectPin(paymentRef: "")))

        XCTAssertEqual(forageError(results.first)?.code, "user_error")
        XCTAssertEqual(forageError(results.first)?.httpStatusCode, 400)
        XCTAssertFalse(ForageSDK.shared.isMomentOpen)
    }

    // MARK: Telemetry

    func testTelemetry_givenTheMomentCompletes_shouldLogTimingAndOutcome() throws {
        let viewController = makeViewController()
        clock.advance(milliseconds: 1200)
        viewController.handle(.ready)
        clock.advance(milliseconds: 3000)
        viewController.handle(.success)

        XCTAssertEqual(logger.last(containing: "is ready")?.level, "notice")
        let ready = try XCTUnwrap(logger.metric("moment_ready"))
        XCTAssertEqual(ready["log_type"] as? String, "metric")
        XCTAssertEqual(ready["action"] as? String, "create_moment")
        XCTAssertEqual(ready["moment_name"] as? String, "payment_collect_pin")
        XCTAssertEqual(ready["response_time_ms"] as? Double, 1200)

        XCTAssertEqual(logger.last(containing: "completed")?.level, "notice")
        let outcome = try XCTUnwrap(logger.metric("moment_outcome"))
        XCTAssertEqual(outcome["log_type"] as? String, "metric")
        XCTAssertEqual(outcome["action"] as? String, "create_moment")
        XCTAssertEqual(outcome["moment_name"] as? String, "payment_collect_pin")
        XCTAssertEqual(outcome["event_outcome"] as? String, "success")
        XCTAssertEqual(outcome["response_time_ms"] as? Double, 4200)
        XCTAssertEqual(outcome["moment_reached_ready"] as? Bool, true)
        XCTAssertNil(outcome["forage_error_code"])
        XCTAssertNil(outcome["http_status"])
    }

    func testTelemetry_givenTheMomentIsDismissed_shouldLogANotice() throws {
        makeViewController().handle(.closed)

        XCTAssertEqual(logger.last(containing: "dismissed")?.level, "notice")
        let outcome = try XCTUnwrap(logger.metric("moment_outcome"))
        XCTAssertEqual(outcome["event_outcome"] as? String, "dismissed")
        XCTAssertEqual(outcome["moment_reached_ready"] as? Bool, false)
        XCTAssertNil(outcome["http_status"])
    }

    func testTelemetry_givenTheLoadDeadline_shouldLogAnErrorWithTimeoutError() throws {
        let viewController = makeViewController(loadDeadline: 0.05)
        viewController.startLoadDeadline()

        let timedOut = expectation(description: "timed out")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { timedOut.fulfill() }
        wait(for: [timedOut], timeout: 1)

        XCTAssertEqual(logger.last(containing: "failed")?.level, "error")
        let outcome = try XCTUnwrap(logger.metric("moment_outcome"))
        XCTAssertEqual(outcome["event_outcome"] as? String, "failure")
        XCTAssertEqual(outcome["forage_error_code"] as? String, "timeout_error")
        XCTAssertEqual(outcome["http_status"] as? Int, 504)
        XCTAssertEqual(outcome["moment_reached_ready"] as? Bool, false)
    }

    func testTelemetry_shouldOnlyLogTheFirstReady() {
        let viewController = makeViewController()
        viewController.handle(.ready)
        viewController.handle(.ready)

        XCTAssertEqual(logger.entries.filter { $0.message.contains("is ready") }.count, 1)
        XCTAssertEqual(logger.entries.filter { $0.attributes?["event_name"] as? String == "moment_ready" }.count, 1)
    }

    func testTelemetry_givenAUsageError_shouldLogTheFailure() throws {
        openMoment(.paymentCollectPin(paymentRef: ""))

        XCTAssertEqual(logger.last(containing: "failed")?.level, "error")
        let outcome = try XCTUnwrap(logger.metric("moment_outcome"))
        XCTAssertEqual(outcome["forage_error_code"] as? String, "user_error")
        XCTAssertEqual(outcome["http_status"] as? Int, 400)
    }

    func testTelemetry_shouldNeverLogTheSessionTokenOrParams() throws {
        let viewController = try XCTUnwrap(openMoment(.paymentCollectPin(paymentRef: "secretPaymentRef")))
        viewController.handle(.ready)
        viewController.handle(.failure(CommonErrors.UNKNOWN_SERVER_ERROR))

        XCTAssertFalse(logger.entries.isEmpty)
        for entry in logger.entries {
            let logged = entry.message + String(describing: entry.attributes ?? [:])
            XCTAssertFalse(logged.contains("dev_secretToken"), entry.message)
            XCTAssertFalse(logged.contains("secretPaymentRef"), entry.message)
        }
    }
}
