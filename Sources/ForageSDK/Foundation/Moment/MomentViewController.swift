//
//  MomentViewController.swift
//  ForageSDK
//
//  © 2025 Forage Technology Corporation. All rights reserved.
//

import UIKit
import WebKit

/// Hosts a moment's page in a `WKWebView` and runs the moments protocol with it.
///
/// It settles exactly once: on the page's first terminal event, the load deadline, or the
/// customer swiping the sheet away. Teardown happens before `onSettle` is called.
final class MomentViewController: UIViewController {
    private let url: URL
    private let merchantID: String
    private let sessionToken: String
    private let environment: Environment
    private let loadDeadlineInterval: TimeInterval
    private let onSettle: (Result<MomentResult, Error>) -> Void

    private var webView: WKWebView?
    private var loadDeadline: Timer?
    private var isSettled = false
    private var telemetry: MomentTelemetry

    /// - Parameters:
    ///   - loadDeadline: How long the page has to send `input_ready`. Only tests change it.
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
        // TODO: verify the PIN field's cross-origin vault iframe works with WKWebView's
        // third-party storage rules (ITP), since it's embedded in the moment's page.

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        #if DEBUG
        // lets Safari's Web Inspector debug the moment's page in debug builds, like the
        // Android SDK does for debuggable apps
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

    /// Fails the moment if the page doesn't send `input_ready` in time.
    func startLoadDeadline() {
        loadDeadline = Timer.scheduledTimer(withTimeInterval: loadDeadlineInterval, repeats: false) { [weak self] _ in
            self?.settle(.failure(MomentProtocol.loadTimeoutError), dismiss: true)
        }
    }

    // MARK: Protocol

    /// Handles an event from the page, once it's passed the security checks.
    func handle(_ event: MomentEvent) {
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
            // the load deadline ends the moment if the page never gets initialized
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
                // the load deadline ends the moment if the page never gets initialized
                ForageSDK.logger?.error("Failed to initialize moment", error: error, attributes: nil)
            }
        }
    }

    /// Tears the moment down and reports how it ended. Only the first call does anything.
    ///
    /// - Parameter dismiss: Whether to dismiss the sheet. It's `false` when the customer already swiped it away.
    private func settle(_ result: Result<MomentResult, Error>, dismiss: Bool) {
        guard !isSettled else { return }
        isSettled = true

        loadDeadline?.invalidate()
        loadDeadline = nil
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: MomentProtocol.messageHandlerName)
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        telemetry.settled(result)

        if dismiss, presentingViewController != nil {
            self.dismiss(animated: true) { [onSettle] in onSettle(result) }
        } else {
            onSettle(result)
        }
    }
}

// MARK: - WKScriptMessageHandler

extension MomentViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let origin = message.frameInfo.securityOrigin
        guard MomentSecurity.shouldAcceptMessage(
            isMainFrame: message.frameInfo.isMainFrame,
            scheme: origin.protocol,
            host: origin.host,
            port: origin.port,
            momentURL: url
        ) else { return }

        guard let event = MomentEvent(body: message.body) else { return }
        handle(event)
    }
}

// MARK: - WKNavigationDelegate

extension MomentViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
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

/// Forwards script messages without retaining the handler, since `WKUserContentController`
/// holds its handlers strongly.
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var handler: WKScriptMessageHandler?

    init(_ handler: WKScriptMessageHandler) {
        self.handler = handler
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handler?.userContentController(userContentController, didReceive: message)
    }
}
