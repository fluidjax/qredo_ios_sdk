//
//  QredoVaultConsolidationTests.swift
//  QredoSDK_nopods
//
//  Created by Gabriel Radu on 21/11/2014.
//
//

import Foundation
import XCTest

class QredoVaultConsolidationTests: XCTestCase {
    
    var serviceURL: NSString!

    override func setUp() {
        super.setUp()
        serviceURL = QREDO_HTTP_SERVICE_URL;

    }
    
    func testConsolidation() {
        
        var expectation: XCTestExpectation!
        
        
        let qredo = QredoClient(
            serviceURL: NSURL(string: serviceURL),
            options: [QredoClientOptionVaultID: QredoQUID()])
        let vault = qredo.defaultVault()
        
        
        let item1 = QredoVaultItem(
            metadata: QredoVaultItemMetadata(
                dataType: "blob",
                accessLevel: 0,
                summaryValues: [:]),
            value: NSData.qtu_dataWithRandomBytesOfLength(1024))
        
        var firstPutItemDescriptor: QredoVaultItemDescriptor?
        expectation = expectationWithDescription("first put")
        vault.putItem(item1, completionHandler: { (itemDescriptor, error) -> Void in
            XCTAssertNil(error, "we must not get an error from first put")
            XCTAssertNotNil(itemDescriptor, "we must get a descriptor from first put")
            firstPutItemDescriptor = itemDescriptor
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
        
        XCTAssertEqual(firstEnumerateResults.count, 1, "after first put we must only have on item in the vault")
        
        
        let item1Updated = QredoVaultItem(
            metadata: firstEnumerateResults.first,
            value: NSData.qtu_dataWithRandomBytesOfLength(1024))
        
        expectation = expectationWithDescription("second put, update first item")
        vault.putItem(item1Updated, completionHandler: { (itemDescriptor, error) -> Void in
            XCTAssertNil(error, "we must not get an error from first put")
            XCTAssertNotNil(itemDescriptor, "we must get a descriptor from first put")
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
        
        XCTAssertEqual(afterUpdateEnumerateResults.count, 1, "after update put we must only have on item in the vault")
        
        
        let item2 = QredoVaultItem(
            metadata: QredoVaultItemMetadata(
                dataType: "blob",
                accessLevel: 0,
                summaryValues: [:]),
            value: NSData.qtu_dataWithRandomBytesOfLength(1024))
        
        var thirdPutItemDescriptor: QredoVaultItemDescriptor?
        expectation = expectationWithDescription("third put, puting a new item")
        vault.putItem(item2, completionHandler: { (itemDescriptor, error) -> Void in
            XCTAssertNil(error, "we must not get an error from first put")
            XCTAssertNotNil(itemDescriptor, "we must get a descriptor from first put")
            thirdPutItemDescriptor = itemDescriptor
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
        
        XCTAssertEqual(afterSecondPutEnumerateResults.count, 2, "after update put we must only have two items in the vault")
        
    }
    

}
