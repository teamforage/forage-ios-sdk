//
//  ForagePaymentSheet.swift
//
//
//  Created by Danilo Joksimovic on 2023-12-07.
//

import FinixPaymentSheet
import UIKit

// TODO: swap with real application ID
let APPLICATION_ID = "APgPDQrLD52TYvqazjHJJchM"

public class ForagePaymentSheet: UIView, ForageElement {
    public var isComplete: Bool = false

    public var delegate: ForageTableDelegate?

    // MARK: Finix

    private var finixPaymentSDK: PaymentAction!
    public var finixPaymentSheet: PaymentInputController!

    private let merchantBranding: PaymentInputController.Branding = .init(
        image: nil,
        title: nil
    )

    private lazy var root: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var logger: ForageLogger = {
        let ddLogger = DatadogLogger(
            ForageLoggerConfig(
                prefix: "ForagePaymentSheet"
            )
        )
        return ddLogger
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    /// Loading a FinixPaymentSheet requires that the
    /// `PaymentInputController` (`finixPaymentSheet`) is a child of a `UIViewController`
    /// So we wait until the `ForagePaymentSheet` is "moved to a superview"
    override public func didMoveToSuperview() {
        if superview != nil {
            super.didMoveToSuperview()
            loadFinixPaymentSheet()
        }
    }

    private func loadFinixPaymentSheet() {
        DispatchQueue.main.async { [self] in
            guard let parentVC = parentViewController else {
                logger.critical("Tried to load ForagePaymentSheet, but the parent UIViewController was unset.", error: nil, attributes: nil)
                return
            }

            // Add Finix Payment Sheet to the parent
            // view controller
            parentVC.addChild(finixPaymentSheet)
            root.addSubview(finixPaymentSheet.view)
            finixPaymentSheet.view.frame = root.bounds

            root.fillSuperview()
            finixPaymentSheet.view.fillSuperview()

            // Notifies the child view controller that the
            // move to the parent view controller is finished,
            // completing the process of integrating the
            // finixPaymentSheet into the view hierarchy
            finixPaymentSheet.didMove(
                toParent: parentVC
            )

            logger.notice("Mounted ForagePaymentSheet", attributes: nil)
        }
    }

    private func forageStylingToFinixTheme() -> ColorTheme {
        var theme: ColorTheme = .default

        // TODO: implement rest of styling!
        theme.errorLabel = .systemRed

        return theme
    }

    private func initializeFinixSDK() {
        let environment = FinixAPIEndpoint.Sandbox
        let credentials = FinixCredentials(
            applicationId: APPLICATION_ID,
            environment: environment
        )
        finixPaymentSDK = .init(credentials: credentials)

        finixPaymentSDK.configuration = .init(
            title: "Tokenize an HSA/FSA card",
            branding: merchantBranding,
            buttonTitle: "Tokenize card"
        )

        finixPaymentSDK.delegate = self
    }

    private func commonInit() {
        addSubview(root)

        // We can initialize the Finix SDK here,
        // but the actual FinixPaymentSheet is mounted after
        // didMoveToSuperview is triggered.
        initializeFinixSDK()

        let finixTheme = forageStylingToFinixTheme()
        finixPaymentSheet = createFinixPaymentSheet(
            finixTheme: finixTheme
        )
    }

    // TODO: figure out the best way to set the size of the frame
    override public var intrinsicContentSize: CGSize {
        CGSize(width: frame.width, height: 450)
    }

    private func createFinixPaymentSheet(finixTheme: ColorTheme) -> PaymentInputController {
        let finixPaymentController = finixPaymentSDK.paymentSheet(
            style: .partial, /// Name, Card Number, Expiration Date, CVC and Zip Code
            theme: finixTheme,
            showCancelButton: true,
            showCancelItem: true,
            showCountry: false
        )
        finixPaymentController.delegate = self
        return finixPaymentController
    }
}

extension ForagePaymentSheet: PaymentActionDelegate {
    // display result
    public func didSucceed(paymentController: PaymentInputController, instrument: TokenResponse) {
        print("""
        Got a token response with:
                id: \(instrument.id)
                fingerprint: \(instrument.fingerprint)
                created: \(instrument.created)
                updated: \(instrument.updated)
                instrument: \(instrument.instrument)
                expires: \(instrument.expires)
                isoCurrency: \(instrument.isoCurrency)
        """)
    }

    public func didCancel(paymentController _: PaymentInputController) {
        print("cancel tapped")
    }

    public func didFail(paymentController: PaymentInputController, error: Error) {
        print("Failed to process with error: \(error)")

        if let error = error as? FinixError {
            print("FinixError with \(error.message), code: \(error.code)")
        }
    }
}
