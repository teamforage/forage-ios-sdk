//
//  MetricsProtocols.swift
//  
//
//  Created by Danilo Joksimovic on 2023-08-28.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

internal protocol PerformanceMeasurer {
    func start()
    func end()
    func logResult()
}

internal protocol NetworkMonitor: PerformanceMeasurer {
    func setPath(_ httpPath: String) -> NetworkMonitor
    func setMethod(_ httpMethod: HttpMethod) -> NetworkMonitor
    func setHttpStatusCode(_ httpStatusCode: Int?) -> NetworkMonitor
}
