//
//  MomentSecurity.swift
//  ForageSDK
//
//  © 2026 Forage Technology Corporation. All rights reserved.
//

import Foundation

/// Verifies the messages being received are from the known moment URL
enum MomentSecurity {
    private static func isMomentOrigin(scheme: String?, host: String?, port: Int?, momentURL: URL) -> Bool {
        // WKSecurityOrigin reports default ports as 0, and URL reports them as nil
        scheme == momentURL.scheme && host == momentURL.host && (port ?? 0) == (momentURL.port ?? 0)
    }

    /// Whether `url` is on the moment URL's origin.
    private static func isMomentOrigin(_ url: URL?, momentURL: URL) -> Bool {
        isMomentOrigin(scheme: url?.scheme, host: url?.host, port: url?.port, momentURL: momentURL)
    }

    static func shouldAcceptMessage(
        isMainFrame: Bool,
        scheme: String?,
        host: String?,
        port: Int?,
        momentURL: URL
    ) -> Bool {
        // check isMainFrame to ensure we only get moment events and don't get events from
        // other things embedded within the moment (like input-iframes)
        isMainFrame && isMomentOrigin(scheme: scheme, host: host, port: port, momentURL: momentURL)
    }

    /// Whether to allow a navigation.
    ///
    /// - Parameter targetsMainFrame: `nil` when the navigation opens a new window.
    static func shouldAllowNavigation(targetsMainFrame: Bool?, to url: URL?, momentURL: URL) -> Bool {
        switch targetsMainFrame {
        // the page can't open new windows
        case nil: return false
        // iframes in the page, like the PIN field's vault iframe, can load what they need
        case false: return true
        // the page itself can't navigate away from the moment's origin
        case true: return isMomentOrigin(url, momentURL: momentURL)
        }
    }

    /// Whether we can send the session token to the page that's loaded right now.
    ///
    /// `evaluateJavaScript` runs in whatever page the main frame has loaded when it's called.
    /// Navigation is already restricted to the moment's origin, but this makes sure the token
    /// can't leak if that ever regresses.
    static func canSendInitialize(currentURL: URL?, momentURL: URL) -> Bool {
        isMomentOrigin(currentURL, momentURL: momentURL)
    }
}
