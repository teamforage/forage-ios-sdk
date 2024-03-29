/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Datadog (https://www.datadoghq.com/).
* Copyright 2019-Present Datadog, Inc.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface __fork_dd_private_ObjcExceptionHandler : NSObject

- (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error
    NS_SWIFT_NAME(rethrowToSwift(tryBlock:));

@end

NS_ASSUME_NONNULL_END
