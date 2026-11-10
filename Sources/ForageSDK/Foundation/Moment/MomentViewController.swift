//
//  MomentViewController.swift
//  ForageSDK
//
//  © 2026 Forage Technology Corporation. All rights reserved.
//

import UIKit
import WebKit

/// Hosts a moment's page in a `WKWebView` and runs the moments protocol with it.
///
/// Settles on the page's first terminal event, the load deadline, or the sheet going away,
/// whether the customer swipes it away or it's dismissed in code.
final class MomentViewController: UIViewController {
    private let url: URL
    private let merchantID: String
    private let sessionToken: String
    private let environment: Environment
    private let loadDeadlineInterval: TimeInterval
    private var onSettle: ((Result<MomentResult, Error>) -> Void)?

    private var webView: WKWebView?
    private var loadDeadline: Timer?
    private var settledResult: Result<MomentResult, Error>?
    private var telemetry: MomentTelemetry

    /// - Parameters:
    ///   - loadDeadline: How long the page has to send `input_ready`. Only exposed for testing.
    ///   - telemetry: Starts timing the moment when it's created.
    init(
        url: URL,
        merchantID: String,
        sessionToken: String,
        environment: Environment,
        telemetry: MomentTelemetry,
        loadDeadline: TimeInterval = MomentProtocol.loadDeadline,
        onSettle: @escaping (Result<MomentResult, Error>) -> Void
    ) {
        self.url = url
        self.merchantID = merchantID
        self.sessionToken = sessionToken
        self.environment = environment
        self.telemetry = telemetry
        loadDeadlineInterval = loadDeadline
        self.onSettle = onSettle
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // ensures we always settle a moment no matter how it goes away
    deinit {
        if settledResult == nil {
            telemetry.settled(.success(.dismissed))
        }
        onSettle?(settledResult ?? .success(.dismissed))
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let configuration = WKWebViewConfiguration()
        // the handler is wrapped so the content controller doesn't retain this view controller
        configuration.userContentController.add(
            WeakScriptMessageHandler(self),
            name: MomentProtocol.messageHandlerName
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        #if DEBUG
        // lets Safari's Web Inspector debug the moment's page in debug builds
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        self.webView = webView

        startLoadDeadline()
        webView.load(URLRequest(url: url))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || presentingViewController?.isBeingDismissed == true {
            settle(.success(.dismissed), dismiss: false)
        }
    }

    /// Fails the moment if the page doesn't send `input_ready` in time.
    func startLoadDeadline() {
        loadDeadline = Timer.scheduledTimer(withTimeInterval: loadDeadlineInterval, repeats: false) { [weak self] _ in
            self?.settle(.failure(MomentProtocol.loadTimeoutError), dismiss: true)
        }
    }

    // MARK: Protocol

    func handleEvent(_ event: MomentEvent) {
        switch event {
        case .hello:
            sendInitialize()
        case .ready:
            loadDeadline?.invalidate()
            loadDeadline = nil
            telemetry.ready()
        case .success:
            settle(.success(.completed), dismiss: true)
        case let .failure(error):
            settle(.failure(error), dismiss: true)
        case .closed:
            settle(.success(.dismissed), dismiss: true)
        }
    }

    private func sendInitialize() {
        guard MomentSecurity.canSendInitialize(currentURL: webView?.url, momentURL: url) else {
            ForageSDK.logger?.error("Didn't initialize moment because the page isn't on the moment's origin", error: nil, attributes: nil)
            return
        }

        guard let script = momentInitializeScript(
            merchantID: merchantID,
            sessionToken: sessionToken,
            environment: environment
        ) else {
            settle(.failure(CommonErrors.UNKNOWN_SERVER_ERROR), dismiss: true)
            return
        }

        webView?.evaluateJavaScript(script) { _, error in
            if let error = error {
                ForageSDK.logger?.error("Failed to initialize moment", error: error, attributes: nil)
            }
        }
    }

    /// Tears the moment down and reports how it ended.
    ///
    /// - Parameter dismiss: Whether to dismiss the sheet. It's `false` when the sheet is already going away.
    private func settle(_ result: Result<MomentResult, Error>, dismiss: Bool) {
        guard settledResult == nil else { return }
        settledResult = result

        loadDeadline?.invalidate()
        loadDeadline = nil
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: MomentProtocol.messageHandlerName)
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        telemetry.settled(result)

        if dismiss, presentingViewController != nil {
            // if the dismissal never finishes, deinit reports instead
            self.dismiss(animated: true) { [weak self] in self?.reportMomentResult(result) }
        } else {
            reportMomentResult(result)
        }
    }

    private func reportMomentResult(_ result: Result<MomentResult, Error>) {
        let onSettle = onSettle
        self.onSettle = nil
        onSettle?(result)
    }
}

// MARK: - WKScriptMessageHandler

extension MomentViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Make sure we're receiving events from where we expect
        let origin = message.frameInfo.securityOrigin
        guard MomentSecurity.shouldAcceptMessage(
            isMainFrame: message.frameInfo.isMainFrame,
            scheme: origin.protocol,
            host: origin.host,
            port: origin.port,
            momentURL: url
        ) else { return }

        guard let event = MomentEvent(body: message.body) else { return }
        handleEvent(event)
    }
}

// MARK: - WKNavigationDelegate

extension MomentViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // Don't let people navigate away from the moment's URL
        // (we should revisit this when/if we add links to any moment page)
        let isAllowed = MomentSecurity.shouldAllowNavigation(
            targetsMainFrame: navigationAction.targetFrame?.isMainFrame,
            to: navigationAction.request.url,
            momentURL: url
        )
        decisionHandler(isAllowed ? .allow : .cancel)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension MomentViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        settle(.success(.dismissed), dismiss: false)
    }
}

/// `WKUserContentController` (which comes from our initialization of a `WKWebViewConfiguration` we use to
/// show the moment page) holds onto its handlers strongly, so just registering the view controller directly would create
/// a memory leak. We use this wrapper instead so we can hold the view controller weakly and just pass messages
/// to it if it still exists.
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var handler: WKScriptMessageHandler?

    init(_ handler: WKScriptMessageHandler) {
        self.handler = handler
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handler?.userContentController(userContentController, didReceive: message)
    }
}
