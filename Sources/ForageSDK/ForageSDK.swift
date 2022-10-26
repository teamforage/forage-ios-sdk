//
//  ForageSDK.swift
//  ForageSDK
//
//  Created by Symphony on 18/10/22.
//

protocol ForageSDKService: AnyObject {
    func refreshAuthentication(for bearerToken: String)
}

public class ForageSDK: ForageSDKService {
    
    // MARK: Properties
    
    static let shared = ForageSDK()
    private static var config: Config?
    internal var merchantID: String = ""
    internal var bearerToken: String = ""
    
    public struct Config {
        let merchantID: String
        let bearerToken: String
        
        public init(merchantID: String, bearerToken: String) {
            self.merchantID = merchantID
            self.bearerToken = bearerToken
        }
    }
    
    public class func setup(_ config: Config) {
        ForageSDK.config = config
    }
    
    private init() {
        guard let config = ForageSDK.config else {
            assertionFailure("ForageSDK missing Config setup")
            return
        }
        
        merchantID = config.merchantID
        bearerToken = config.bearerToken
    }
    
    func refreshAuthentication(for bearerToken: String) {
        self.bearerToken = bearerToken
    }
}
