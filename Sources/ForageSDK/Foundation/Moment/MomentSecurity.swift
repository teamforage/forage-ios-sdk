//
//  MomentSecurity.swift
//  ForageSDK
//
//  © 2026 Forage Technology Corporation. All rights reserved.
//

import Foundation

/// The checks that keep anything other than the moment's own page from using the bridge.
///
/// The page doesn't check where messages come from, so these are what protect the moment.
/// On iOS 13 the script message handler is exposed to every frame on every origin, including
/// the PIN field's cross-origin vault iframe, so the message check is the only thing stopping
/// another frame from faking an event.
enum MomentSecurity {
    /// Whether an origin's parts match the moment URL's origin.
    static func isMomentOrigin(scheme: String?, host: String?, port: Int?, momentURL: URL) -> Bool {
        // WKSecurityOrigin reports default ports as 0, and URL reports them as nil
        scheme == momentURL.scheme && host == momentURL.host && (port ?? 0) == (momentURL.port ?? 0)
    }

    /// Whether `url` is on the moment URL's origin.
    static func isMomentOrigin(_ url: URL?, momentURL: URL) -> Bool {
        isMomentOrigin(scheme: url?.scheme, host: url?.host, port: url?.port, momentURL: momentURL)
    }

    /// Whether to accept a message from the page. Only the moment's main frame on its own origin
    /// can talk to us, not the iframes it embeds.
    static func shouldAcceptMessage(
        isMainFrame: Bool,
        scheme: String?,
        host: String?,
        port: Int?,
        momentURL: URL
    ) -> Bool {
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
