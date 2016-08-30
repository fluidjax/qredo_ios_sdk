/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoConversationPrivate.h"

@interface HighwatermarksTests : QredoXCTestCase

@end

@implementation HighwatermarksTests

- (void)testConversationHWMComparison {

    {
        const uint8_t a1_bytes[] = {0};
        const uint8_t b1_bytes[] = {0};
        XCTAssertFalse([[[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:a1_bytes length:sizeof(a1_bytes)]] isLaterThan:
                        [[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:b1_bytes length:sizeof(b1_bytes)]]]);
    }


    {
        const uint8_t a1_bytes[] = {0};
        const uint8_t b1_bytes[] = {1};
        XCTAssertFalse([[[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:a1_bytes length:sizeof(a1_bytes)]] isLaterThan:
                        [[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:b1_bytes length:sizeof(b1_bytes)]]]);
    }

    {
        const uint8_t a1_bytes[] = {};
        const uint8_t b1_bytes[] = {0};
        XCTAssertFalse([[[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:a1_bytes length:sizeof(a1_bytes)]] isLaterThan:
                        [[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:b1_bytes length:sizeof(b1_bytes)]]]);
    }

    {
        const uint8_t a1_bytes[] = {0};
        const uint8_t b1_bytes[] = {};
        XCTAssertFalse([[[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:a1_bytes length:sizeof(a1_bytes)]] isLaterThan:
                        [[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:b1_bytes length:sizeof(b1_bytes)]]]);
    }

    {
        const uint8_t a1_bytes[] = {1};
        const uint8_t b1_bytes[] = {0};
        XCTAssertTrue([[[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:a1_bytes length:sizeof(a1_bytes)]] isLaterThan:
                       [[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:b1_bytes length:sizeof(b1_bytes)]]]);
    }


    {
        const uint8_t a1_bytes[] = {0, 0, 0, 0, 1};
        const uint8_t b1_bytes[] = {0};
        XCTAssertTrue([[[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:a1_bytes length:sizeof(a1_bytes)]] isLaterThan:
                       [[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:b1_bytes length:sizeof(b1_bytes)]]]);
    }


    {
        const uint8_t a1_bytes[] = {0, 0, 0, 0, 1};
        const uint8_t b1_bytes[] = {0, 0, 0, 0, 0, 0};
        XCTAssertTrue([[[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:a1_bytes length:sizeof(a1_bytes)]] isLaterThan:
                       [[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:b1_bytes length:sizeof(b1_bytes)]]]);
    }


    {
        const uint8_t a1_bytes[] = {0, 2, 0, 0, 1};
        const uint8_t b1_bytes[] = {0, 0, 1, 0, 0, 1};
        XCTAssertTrue([[[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:a1_bytes length:sizeof(a1_bytes)]] isLaterThan:
                       [[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:b1_bytes length:sizeof(b1_bytes)]]]);
    }


    {
        const uint8_t a1_bytes[] = {0, 0, 0, 3};
        const uint8_t b1_bytes[] = {0, 0, 0, 3};
        XCTAssertFalse([[[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:a1_bytes length:sizeof(a1_bytes)]] isLaterThan:
                       [[QredoConversationHighWatermark alloc] initWithSequenceValue:[NSData dataWithBytes:b1_bytes length:sizeof(b1_bytes)]]]);
    }

}

@end
