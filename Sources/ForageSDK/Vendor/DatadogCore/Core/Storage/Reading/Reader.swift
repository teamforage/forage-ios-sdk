/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation


internal struct Batch {
    /// Data blocks in the batch.
    let dataBlocks: [DataBlock]
    /// File from which `data` was read.
    let file: ReadableFile
}

extension Batch {
    /// Events contained in the batch.
    var events: [Event] {
        let generator = EventGenerator(dataBlocks: dataBlocks)
        return generator.map { $0 }
    }
}

/// A type, reading batched data.
internal protocol Reader {
    func readNextBatch() -> Batch?
    func markBatchAsRead(_ batch: Batch, reason: BatchDeletedMetric.RemovalReason)
}
