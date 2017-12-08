/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoRendezvous.h"
#import "QredoRendezvousPrivate.h"
#import "QredoPrivate.h"


@interface QredoRendezvousTests :QredoXCTestCase

-(void)testCreateRendezvousAndGetResponses;
-(void)testCreateAndFetchAnonymousRendezvous;
-(void)testCreateDuplicateAndFetchAnonymousRendezvous;
-(void)testActivateExpiredRendezvous;
-(void)testActivateExpiredRendezvousAndFetchFromNewRef;


@end
