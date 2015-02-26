/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

import Foundation
import XCTest


class VaultListener : NSObject, QredoVaultDelegate {
    
    var expecation: XCTestExpectation?
    var fulfillTimer: NSTimer?
    
    var receivedItemMetadata = Array<QredoVaultItemMetadata>()
    var receivedError: NSError?
    
    func qredoVault(client: QredoVault!, didReceiveVaultItemMetadata itemMetadata: QredoVaultItemMetadata!) {
        
        receivedItemMetadata.append(itemMetadata)
        
        if let timer = fulfillTimer {
            timer.invalidate()
        }
        if let theExpectation = expecation {
            let timer = NSTimer(timeInterval: 1,
                target: theExpectation,
                selector: Selector("fulfill"),
                userInfo: nil, repeats: false)
            fulfillTimer = timer
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
            })
        }
        
    }
    
    func qredoVault(client: QredoVault!, didFailWithError error: NSError!) {
        receivedError = error
        expecation?.fulfill()
    }
    
    func reset() {
        receivedItemMetadata.removeAll()
        receivedError = nil;
    }
    
}

class QredoVaultConsolidationTests: XCTestCase {
    
    var useMQTT = false
    var qredo: QredoClient!
    var systemItemsCount = 0
    var systemItemDescriptors : [QredoVaultItemDescriptor] = []


    override func setUp() {
        super.setUp()

        let createExpectation = self.expectationWithDescription("create client")
        QredoClient.authorizeWithConversationTypes([], vaultDataTypes: ["com.qredo.test"],
            options: QredoClientOptions(MQTT: useMQTT, resetData: true),
            completionHandler: {client, error in
                self.qredo = client
                createExpectation.fulfill()
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        let systemItemsExpectation = expectationWithDescription("system vault items")
        let vault = qredo.defaultVault()
        systemItemsCount = 0
        systemItemDescriptors = []
        vault.enumerateVaultItemsUsingBlock({ (metadata, stop) -> Void in
            self.systemItemsCount++
            self.systemItemDescriptors.append(metadata.descriptor)
        }, completionHandler: { (error) -> Void in
            systemItemsExpectation.fulfill()
        })

        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
    }
    
    func testConsolidation() {
        var expectation: XCTestExpectation!

        let vault = qredo.defaultVault()
        
        
        let item1 = QredoVaultItem(
            metadata: QredoVaultItemMetadata(
                dataType: "blob",
                accessLevel: 0,
                summaryValues: [:]),
            value: NSData.qtu_dataWithRandomBytesOfLength(1024))
        
        var firstPutItemDescriptor: QredoVaultItemDescriptor?
        expectation = expectationWithDescription("first put")
        vault.putItem(item1, completionHandler: { (itemMetadata, error) -> Void in
            XCTAssertNil(error, "must not get an error from first put")
            XCTAssertNotNil(itemMetadata, "we must get a metadata from first put")
            firstPutItemDescriptor = itemMetadata.descriptor
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
        
        
        
        var firstEnumerateResults = Array<QredoVaultItemMetadata>()
        expectation = expectationWithDescription("first enumerate")
        vault.enumerateVaultItemsUsingBlock({ (metadata, stop) -> Void in
            firstEnumerateResults.append(metadata)
        }, completionHandler: { (error) -> Void in
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
        
        XCTAssertEqual(firstEnumerateResults.count, systemItemsCount + 1, "after first put, the vault must only have one item")
        
        
        let item1Updated = QredoVaultItem(
            metadata: firstEnumerateResults.first,
            value: NSData.qtu_dataWithRandomBytesOfLength(1024))
        
        expectation = expectationWithDescription("second put, update first item")
        vault.putItem(item1Updated, completionHandler: { (itemDescriptor, error) -> Void in
            XCTAssertNil(error, "must not get an error from first put")
            XCTAssertNotNil(itemDescriptor, "must get a descriptor from first put")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        
        var afterUpdateEnumerateResults = Array<QredoVaultItemMetadata>()
        expectation = expectationWithDescription("first enumerate")
        vault.enumerateVaultItemsUsingBlock({ (metadata, stop) -> Void in
            afterUpdateEnumerateResults.append(metadata)
            }, completionHandler: { (error) -> Void in
                expectation.fulfill()
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
        
        XCTAssertEqual(afterUpdateEnumerateResults.count, systemItemsCount + 1, "after update put, the vault must only have one item")
        
        
        let item2 = QredoVaultItem(
            metadata: QredoVaultItemMetadata(
                dataType: "blob",
                accessLevel: 0,
                summaryValues: [:]),
            value: NSData.qtu_dataWithRandomBytesOfLength(1024))
        
        var thirdPutItemDescriptor: QredoVaultItemDescriptor?
        expectation = expectationWithDescription("third put, puting a new item")
        vault.putItem(item2, completionHandler: { (itemMetadata, error) -> Void in
            XCTAssertNil(error, "must not get an error from first put")
            XCTAssertNotNil(itemMetadata, "must get a metadata from first put")
            thirdPutItemDescriptor = itemMetadata.descriptor
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
        
        
        var afterSecondPutEnumerateResults = Array<QredoVaultItemMetadata>()
        expectation = expectationWithDescription("first enumerate")
        vault.enumerateVaultItemsUsingBlock({ (metadata, stop) -> Void in
            afterSecondPutEnumerateResults.append(metadata)
            }, completionHandler: { (error) -> Void in
                expectation.fulfill()
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
        
        XCTAssertEqual(afterSecondPutEnumerateResults.count, systemItemsCount + 2, "after update put, the vault must only have two items")
        
    }
    
    func testNotConsolidatedEnumeration() {
        var expectation: XCTestExpectation!

        let vault = qredo.defaultVault()
        
        let listener = VaultListener()
        vault.delegate = listener
        
        vault.startListening()
        
        
        let item1 = QredoVaultItem(
            metadata: QredoVaultItemMetadata(
                dataType: "blob",
                accessLevel: 0,
                summaryValues: [:]),
            value: NSData.qtu_dataWithRandomBytesOfLength(1024))
        
        expectation = expectationWithDescription("a new put")
        listener.expecation = expectation
        vault.putItem(item1, completionHandler: { (itemDescriptor, error) -> Void in
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
        
        XCTAssertEqual(listener.receivedItemMetadata.count, systemItemsCount + 1, "after one put the listner must only be notified of one item")
        
        listener.reset()
        
        
        let item1Updated = QredoVaultItem(
            metadata: listener.receivedItemMetadata.first,
            value: NSData.qtu_dataWithRandomBytesOfLength(1024))
        
        expectation = expectationWithDescription("an update put, update first item")
        listener.expecation = expectation
        vault.putItem(item1Updated, completionHandler: { (itemDescriptor, error) -> Void in
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
        
        XCTAssertEqual(listener.receivedItemMetadata.count, 1, "after one update put the listner must only be notified of one item")
        
        listener.reset()

        
        let item2 = QredoVaultItem(
            metadata: QredoVaultItemMetadata(
                dataType: "blob",
                accessLevel: 0,
                summaryValues: [:]),
            value: NSData.qtu_dataWithRandomBytesOfLength(1024))
        
        expectation = expectationWithDescription("a new put, puting a new item; (second time)")
        listener.expecation = expectation
        vault.putItem(item2, completionHandler: { (itemDescriptor, error) -> Void in
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
        
        XCTAssertEqual(listener.receivedItemMetadata.count, 1, "after one new put the listner must only be notified of one item")
        
        listener.reset()

        
        expectation = expectationWithDescription("an update put, update the second item twice")
        listener.expecation = expectation
        let item2Updated = QredoVaultItem(
            metadata: listener.receivedItemMetadata.first,
            value: NSData.qtu_dataWithRandomBytesOfLength(1024))
        
        vault.putItem(item1Updated, completionHandler: { (itemDescriptor, error) -> Void in
        })
        let item2UpdatedAgain = QredoVaultItem(
            metadata: listener.receivedItemMetadata.first,
            value: NSData.qtu_dataWithRandomBytesOfLength(1024))
        
        vault.putItem(item2UpdatedAgain, completionHandler: { (itemDescriptor, error) -> Void in
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)
        
        XCTAssertEqual(listener.receivedItemMetadata.count, 2, "after two update puts the listner must only be notified of two items")

        listener.reset()

    }

}
