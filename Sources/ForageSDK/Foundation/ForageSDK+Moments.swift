//
//  ForageSDK+Moments.swift
//  ForageSDK
//
//  © 2026 Forage Technology Corporation. All rights reserved.
//

import UIKit

enum MomentErrors {
    static let MOMENT_ALREADY_OPEN = ForageError.create(
        code: "user_error",
        httpStatusCode: 400,
        message: "A moment is already open. Wait for it to finish before opening another."
    )
    static let INVALID_MOMENT_PARAMS = ForageError.create(
        code: "user_error",
        httpStatusCode: 400,
        message: "Invalid moment params provided. Every param must be a non-empty string."
    )
}

extension ForageSDK {
    /// Only for Forage's development of moments: replaces the origin that moments open on, e.g.
    /// `http://localhost:3000`. Not public API. Only `dev` and `local` session tokens use it, so
    /// it's ignored everywhere else.
    @_spi(Development) public static var momentBaseURLOverride: URL?

    /// Opens a moment, a Forage-hosted page that completes one task with the customer, and
    /// reports how it ended.
    ///
    /// The moment is presented as a sheet over `viewController`. It uses the merchant ID and
    /// session token from ``ForageSDK/setup(_:)``.
    ///
    /// - Parameters:
    ///   - moment: The moment to open, e.g. `.paymentCollectPin(paymentRef:)`.
    ///   - viewController: The view controller to present the moment from.
    ///   - completion: Called on the main thread with ``MomentResult/completed`` or
    ///   ``MomentResult/dismissed``, or a `ForageError` if the moment failed.
    public func createMoment(
        _ moment: Moment,
        presentingFrom viewController: UIViewController,
        completion: @escaping (Result<MomentResult, Error>) -> Void
    ) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.createMoment(moment, presentingFrom: viewController, completion: completion)
            }
            return
        }

        openMoment(moment, completion: completion) { momentViewController in
            viewController.present(momentViewController, animated: true)
        }
    }

    /// Opens a moment on the main thread. `present` shows its view controller, so tests can
    /// open moments without a window.
    func openMoment(
        _ moment: Moment,
        loadDeadline: TimeInterval = MomentProtocol.loadDeadline,
        completion: @escaping (Result<MomentResult, Error>) -> Void,
        present: (MomentViewController) -> Void
    ) {
        _ = ForageSDK.logger?
            .setPrefix("createMoment")
            .addContext(ForageLogContext(merchantRef: merchantID))
            .notice("Called createMoment for \(moment.name)", attributes: nil)

        let telemetry = MomentTelemetry(momentName: moment.name)
        let fail = { (error: ForageError) in
            telemetry.settled(.failure(error))
            completion(.failure(error))
        }

        guard !isMomentOpen else {
            fail(MomentErrors.MOMENT_ALREADY_OPEN)
            return
        }

        guard moment.params.values.allSatisfy({ !$0.isEmpty }) else {
            fail(MomentErrors.INVALID_MOMENT_PARAMS)
            return
        }

        guard let url = momentURL(
            for: moment,
            environment: environment,
            baseURLOverride: ForageSDK.momentBaseURLOverride
        ) else {
            fail(CommonErrors.UNKNOWN_SERVER_ERROR)
            return
        }

        isMomentOpen = true
        let momentViewController = MomentViewController(
            url: url,
            merchantID: merchantID,
            sessionToken: sessionToken,
            environment: environment,
            telemetry: telemetry,
            loadDeadline: loadDeadline
        ) { [weak self] result in
            self?.isMomentOpen = false
            completion(result)
        }
        momentViewController.modalPresentationStyle = .pageSheet
        momentViewController.presentationController?.delegate = momentViewController

        present(momentViewController)
    }

    /// Opens a moment, a Forage-hosted page that completes one task with the customer, and
    /// returns how it ended. Throws a `ForageError` if the moment failed.
    ///
    /// See ``ForageSDK/createMoment(_:presentingFrom:completion:)``.
    public func createMoment(
        _ moment: Moment,
        presentingFrom viewController: UIViewController
    ) async throws -> MomentResult {
        try await awaitResult { completion in
            self.createMoment(moment, presentingFrom: viewController, completion: completion)
        }
    }
}
