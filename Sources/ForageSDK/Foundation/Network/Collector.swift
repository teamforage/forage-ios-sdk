//
//  File.swift
//  
//
//  Created by Danny Leiser on 3/8/23.
//

import Foundation
import VGSCollectSDK

public protocol VaultCollector {
    func setCustomHeaders(headers: [String: String])
    func sendData(
        path: String,
        extraData: [String: Any],
        completion: @escaping (VGSResponse) -> Void)
    
}

struct VGSCollectConfig {
    let id: String
    let environment: VGSCollectSDK.Environment
}

struct BasisTheoryConfig {
    let publicKey: String
    let proxyKey: String
}

// Wrapper class for VGSCollect
class VGSCollectWrapper: VaultCollector {
    
    private let vgsCollect: VGSCollect
    
    init(config: VGSCollectConfig) {
        self.vgsCollect = VGSCollect(id: config.id, environment: config.environment)
    }
    
    func setCustomHeaders(headers: [String: String]) {
            vgsCollect.customHeaders = headers
        }
    
    func sendData(path: String, extraData: [String: Any], completion: @escaping (VGSResponse) -> Void) {
        vgsCollect.sendData(path: path, extraData: extraData, completion: completion)
    }
}

// Wrapper class for BasisTheory
class BasisTheoryWrapper: VaultCollector {
    var customHeaders: [String: String] = [:]
        
        func setCustomHeaders(headers: [String: String]) {
            self.customHeaders = headers
        }
    
    func sendData(path: String, extraData: [String : Any], completion: @escaping (VGSCollectSDK.VGSResponse) -> Void) {
        return
    }
    
    
    private let basisTheoryConfig: BasisTheoryConfig
    
    init(config: BasisTheoryConfig) {
        self.basisTheoryConfig = config
    }

}



//
//internal class Collector {
//    /**
//     VGS VaultId
//     */
//    private enum VaultId: String {
//        case sandbox = "tntagcot4b1"
//        case cert = "tntpnht7psv"
//        case prod = "tntbcrncmgi"
//        case staging = "tnteykuh975"
//        case dev = "tntlqkidhc6"
//    }
//
//    public static func CreateVGS() -> VGSCollect {
//        return VGSCollect(id: vaultID(ForageSDK.shared.environment).rawValue, environment: environmentVGS(ForageSDK.shared.environment))
//    }
//
//    private static func vaultID(_ environment: EnvironmentTarget) -> VaultId {
//        switch environment {
//        case .sandbox: return .sandbox
//        case .cert: return .cert
//        case .prod: return .prod
//        case .staging: return .staging
//        case .dev: return .dev
//        }
//    }
//
//    private static func environmentVGS(_ environment: EnvironmentTarget) -> VGSCollectSDK.Environment {
//        switch environment {
//        case .cert, .sandbox, .staging, .dev: return .sandbox
//        case .prod: return .live
//        }
//    }
//
//    /**
//     BT public Keys
//     */
//    private enum PublicKey: String {
//        case sandbox = "tntagcot4b1"
//        case cert = "tntpnht7psv"
//        case prod = "tntbcrncmgi"
//        case staging = "tnteykuh975"
//        case dev = "tntlqkidhc6"
//    }
//
//    private static func publicKey(_ environment: EnvironmentTarget) -> PublicKey {
//        switch environment {
//        case .sandbox: return .sandbox
//        case .cert: return .cert
//        case .prod: return .prod
//        case .staging: return .staging
//        case .dev: return .dev
//        }
//    }
//
//    private static func proxyKey(_ environment: EnvironmentTarget) -> ProxyKey {
//            switch environment {
//            case .sandbox: return .sandbox
//            case .cert: return .cert
//            case .prod: return .prod
//            case .staging: return .staging
//            case .dev: return .dev
//            }
//        }
//
//    /**
//         BT proxy Keys
//         */
//        private enum ProxyKey: String {
//            case sandbox = "sandbox-proxy-key"
//            case cert = "cert-proxy-key"
//            case prod = "prod-proxy-key"
//            case staging = "staging-proxy-key"
//            case dev = "dev-proxy-key"
//        }
////
////    public static func CreateBasisTheory() -> {
////        return BasisTheoryConfig(publicKey: publicKey(ForageSDK.shared.environment).rawValue,
////                                         proxyKey: proxyKey(ForageSDK.shared.environment).rawValue)
////    }
//
//
//}
//
//struct BasisTheoryConfig {
//    let publicKey: String
//    let proxyKey: String
//}

class CollectorFactory {
        /**
         VGS VaultId
         */
        private enum VaultId: String {
            case sandbox = "tntagcot4b1"
            case cert = "tntpnht7psv"
            case prod = "tntbcrncmgi"
            case staging = "tnteykuh975"
            case dev = "tntlqkidhc6"
        }
    
        public static func CreateVGS() -> VGSCollect {
            return VGSCollect(id: vaultID(ForageSDK.shared.environment).rawValue, environment: environmentVGS(ForageSDK.shared.environment))
        }
    
        private static func vaultID(_ environment: EnvironmentTarget) -> VaultId {
            switch environment {
            case .sandbox: return .sandbox
            case .cert: return .cert
            case .prod: return .prod
            case .staging: return .staging
            case .dev: return .dev
            }
        }
    
        private static func environmentVGS(_ environment: EnvironmentTarget) -> VGSCollectSDK.Environment {
            switch environment {
            case .cert, .sandbox, .staging, .dev: return .sandbox
            case .prod: return .live
            }
        }
    
        /**
         BT public Keys
         */
        private enum PublicKey: String {
            case sandbox = "tntagcot4b1"
            case cert = "tntpnht7psv"
            case prod = "tntbcrncmgi"
            case staging = "tnteykuh975"
            case dev = "tntlqkidhc6"
        }
    
        private static func publicKey(_ environment: EnvironmentTarget) -> PublicKey {
            switch environment {
            case .sandbox: return .sandbox
            case .cert: return .cert
            case .prod: return .prod
            case .staging: return .staging
            case .dev: return .dev
            }
        }
    
        private static func proxyKey(_ environment: EnvironmentTarget) -> ProxyKey {
                switch environment {
                case .sandbox: return .sandbox
                case .cert: return .cert
                case .prod: return .prod
                case .staging: return .staging
                case .dev: return .dev
                }
            }
    
    /**
         BT proxy Keys
     */
    private enum ProxyKey: String {
        case sandbox = "sandbox-proxy-key"
        case cert = "cert-proxy-key"
        case prod = "prod-proxy-key"
        case staging = "staging-proxy-key"
        case dev = "dev-proxy-key"
    }

    static func createVGS(environment: EnvironmentTarget) -> VGSCollectWrapper {
        let id = vaultID(environment).rawValue
        let environmentVGS = environmentVGS(environment)
        let config = VGSCollectConfig(id: id, environment: environmentVGS)
        return VGSCollectWrapper(config: config)
    }

    static func createBasisTheory(environment: EnvironmentTarget) -> BasisTheoryWrapper {
        let publicKey = proxyKey(environment).rawValue
        let proxyKey = proxyKey(environment).rawValue
        let config = BasisTheoryConfig(publicKey: publicKey, proxyKey: proxyKey)
        return BasisTheoryWrapper(config: config)
    }

}
