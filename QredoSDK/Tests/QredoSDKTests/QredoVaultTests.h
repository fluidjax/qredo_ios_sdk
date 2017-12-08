/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoXCTestCase.h"

@interface QredoVaultTests :QredoXCTestCase


-(void)testPersistanceVaultId;
-(void)testPutItem;
-(void)testPutItemMultiple;
-(void)testGettingItems;
-(void)testEnumeration;
-(void)testEnumerationReturnsCreatedItem;
-(void)testEnumerationAbortsOnStop;

-(void)testListener;
-(void)testMultipleListeners;
-(void)testRemovingListenerDurringNotification;
-(void)testMultipleRemovingListenerDurringNotification;
-(void)testRemovingNotObservingListener;

-(void)testVaultItemMetadataAndMutableMetadata;
-(void)testGettingItemsFromCache;

@end
