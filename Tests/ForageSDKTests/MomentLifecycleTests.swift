//
//  MomentLifecycleTests.swift
//  ForageSDKTests
//
//  © 2025 Forage Technology Corporation. All rights reserved.
//

@_spi(Development) @testable import ForageSDK
import WebKit
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
    /// Where tests that load a page serve it from, so they never reach a real server
    private let testPageURL = URL(string: "https://moment.test/payment/collect-pin?paymentRef=abc")!
    private var logger: RecordingLogger!
    private var clock: TestClock!
    private var results: [Result<MomentResult, Error>] = []
    private var window: UIWindow?

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
        window?.isHidden = true
        window = nil
        ForageSDK.momentBaseURLOverride = nil
        ForageSDK.shared.isMomentOpen = false
        ForageSDK.logger = nil
        super.tearDown()
    }

    private func makeViewController(url: URL? = nil, loadDeadline: TimeInterval = 30) -> MomentViewController {
        let clock = clock!
        return MomentViewController(
            url: url ?? momentURL,
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

    // MARK: Web view

    /// A stand-in for the moment's page. It says hello, then runs `onInitialize` with the
    /// `config` the SDK sends back. `post(event)` sends the SDK an event.
    private func testPage(onInitialize: String) -> String {
        """
        <script>
          const post = (event) =>
            window.webkit.messageHandlers.\(MomentProtocol.messageHandlerName).postMessage(JSON.stringify(event));
          window.\(MomentProtocol.receiveFunctionName) = (message) => {
            const config = JSON.parse(message).payload;
            \(onInitialize)
          };
          post({ type: 'input_hello' });
        </script>
        """
    }

    /// Shows the view controller in a window and swaps its page for `html`, served from the
    /// view controller's URL.
    private func load(_ html: String, in viewController: MomentViewController) throws {
        show(viewController)
        let webView = try XCTUnwrap(viewController.view.subviews.lazy.compactMap { $0 as? WKWebView }.first)
        webView.loadHTMLString(html, baseURL: testPageURL)
    }

    /// Makes `viewController` the root of a visible window.
    private func show(_ viewController: UIViewController) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        self.window = window
    }

    private func waitForResult() {
        let settled = expectation(for: NSPredicate { [unowned self] _, _ in !results.isEmpty }, evaluatedWith: nil)
        wait(for: [settled], timeout: 10)
    }

    func testWebView_givenThePageSaysHello_shouldSendItTheMerchantAndSessionToken() throws {
        // the page echoes the config back in a failure, since that's an event that carries data
        try load(testPage(onInitialize: """
        post({
          type: 'submit_failure',
          payload: { code: 'echo', httpStatusCode: 400, message: config.merchantId + ' ' + config.sessionToken },
        });
        """), in: makeViewController(url: testPageURL))

        waitForResult()

        XCTAssertEqual(forageError(results.first)?.message, "mid/123 dev_secretToken")
    }

    func testWebView_givenThePageCompletes_shouldComplete() throws {
        try load(testPage(onInitialize: """
        post({ type: 'input_ready' });
        post({ type: 'submit_success' });
        """), in: makeViewController(url: testPageURL))

        waitForResult()

        XCTAssertEqual(try results.first?.get(), .completed)
        XCTAssertNotNil(logger.metric("moment_ready"))
    }

    func testHello_givenThePageIsNotOnTheMomentsOrigin_shouldNotSendTheSessionToken() {
        // the view never loaded, so there's no page on the moment's origin
        makeViewController().handle(.hello)

        XCTAssertEqual(logger.last(containing: "Didn't initialize moment")?.level, "error")
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: Presenting

    // Tests run without a host app, so UIKit never finishes a dismiss transition. Tests that need
    // a result swipe the sheet away instead, which reports right away.

    /// Swipes the moment's sheet away, like the customer would.
    private func swipeAway(_ moment: MomentViewController) throws {
        try moment.presentationControllerDidDismiss(XCTUnwrap(moment.presentationController))
    }

    func testSettle_givenThePresentedMoment_shouldDismissItBeforeReporting() throws {
        let presenter = UIViewController()
        show(presenter)
        let viewController = makeViewController(url: testPageURL)
        presenter.present(viewController, animated: false)

        viewController.handle(.closed)

        // the moment is torn down, but only reports to the merchant once the dismissal finishes
        XCTAssertNotNil(logger.metric("moment_outcome"))
        XCTAssertTrue(results.isEmpty)
    }

    /// Waits for `presenter` to present a moment and returns it.
    private func presentedMoment(on presenter: UIViewController) throws -> MomentViewController {
        let presented = expectation(for: NSPredicate { _, _ in presenter.presentedViewController is MomentViewController }, evaluatedWith: nil)
        wait(for: [presented], timeout: 10)
        return try XCTUnwrap(presenter.presentedViewController as? MomentViewController)
    }

    func testCreateMoment_shouldPresentTheMomentAsASheet() throws {
        ForageSDK.momentBaseURLOverride = testPageURL
        let presenter = UIViewController()
        show(presenter)

        ForageSDK.shared.createMoment(.paymentCollectPin(paymentRef: "abc"), presentingFrom: presenter) { [unowned self] in
            results.append($0)
        }
        let moment = try presentedMoment(on: presenter)
        XCTAssertEqual(moment.modalPresentationStyle, .pageSheet)
        XCTAssertTrue(moment.presentationController?.delegate === moment)

        try swipeAway(moment)

        XCTAssertEqual(try results.first?.get(), .dismissed)
        XCTAssertFalse(ForageSDK.shared.isMomentOpen)
    }

    func testCreateMoment_givenABackgroundThread_shouldPresentOnTheMainThread() throws {
        ForageSDK.momentBaseURLOverride = testPageURL
        let presenter = UIViewController()
        show(presenter)

        DispatchQueue.global().async {
            ForageSDK.shared.createMoment(.paymentCollectPin(paymentRef: "abc"), presentingFrom: presenter) { _ in }
        }

        try swipeAway(presentedMoment(on: presenter))
    }

    func testCreateMoment_givenAsync_shouldReturnTheResult() throws {
        ForageSDK.momentBaseURLOverride = testPageURL
        let presenter = UIViewController()
        show(presenter)

        Task {
            let result: Result<MomentResult, Error>
            do {
                result = try await .success(ForageSDK.shared.createMoment(.paymentCollectPin(paymentRef: "abc"), presentingFrom: presenter))
            } catch {
                result = .failure(error)
            }
            DispatchQueue.main.async { self.results.append(result) }
        }
        try swipeAway(presentedMoment(on: presenter))
        waitForResult()

        XCTAssertEqual(try results.first?.get(), .dismissed)
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
