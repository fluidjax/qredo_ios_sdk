import Foundation
import XCTest

class QredoVaultDescriptorTests: XCTestCase {
    var client : QredoClient! = nil
    var useMQTT = false
    var itemDescriptor : QredoVaultItemDescriptor? = nil

    let initialSummaryValues = ["key 1" : "value 1"]

    override func setUp() {
        super.setUp()

        let createExpectation = self.expectationWithDescription("create client")
        QredoClient.authorizeWithConversationTypes([], vaultDataTypes: ["com.qredo.test"],
            options: QredoClientOptions(MQTT: useMQTT, resetData: true),
            completionHandler: {client, error in
                self.client = client
                createExpectation.fulfill()
        })
        waitForExpectationsWithTimeout(qtu_defaultTimeout, handler: nil)

        let vault = client.defaultVault()

        let metadata = QredoVaultItemMetadata(dataType: "com.qredo.test", accessLevel: 0, summaryValues: initialSummaryValues)

        let vaultItem = QredoVaultItem(metadata: metadata, value: "hello".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true))

        let putItemExpectation = self.expectationWithDescription("put item")
        vault.putItem(vaultItem, completionHandler: { descriptor, error in
            XCTAssertNil(error, "failed to put item")
            XCTAssertNotNil(descriptor, "descriptor should not be nil")

            self.itemDescriptor = descriptor
            putItemExpectation.fulfill()
        })

        waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    func verifyMetadata(itemMetadata : QredoVaultItemMetadata!) {
        XCTAssertNotNil(itemMetadata, "metadata should not be nil")

        if let actualMetadata = itemMetadata {
            XCTAssertTrue(actualMetadata.summaryValues.contains(self.initialSummaryValues), "lost summaryValues")

            XCTAssertNotNil(actualMetadata.descriptor, "Descriptor should not be nil")

            if let _ = actualMetadata.descriptor {
                XCTAssertTrue(itemMetadata.descriptor.isEqual(self.itemDescriptor!), "Desriptor should be the same")
            }
        }
    }

    func testGetItemMetadata() {
        let vault = client.defaultVault()

        let getItemMetadataExpectation = self.expectationWithDescription("get item metadata")


        vault.getItemMetadataWithDescriptor(itemDescriptor, completionHandler: { (itemMetadata : QredoVaultItemMetadata!, error) -> Void in
            XCTAssertNil(error, "failed to get item metadata")

            self.verifyMetadata(itemMetadata)
            getItemMetadataExpectation.fulfill()
        })

        waitForExpectationsWithTimeout(2.0, handler: nil)
    }


    func testGetItem() {
        let vault = client.defaultVault()

        let getItemMetadataExpectation = self.expectationWithDescription("get item metadata")


        vault.getItemWithDescriptor(itemDescriptor, completionHandler: { (item : QredoVaultItem!, error) -> Void in
            XCTAssertNil(error, "failed to get item metadata")
            XCTAssertNotNil(item, "metadata should not be nil")

            if let actualItem = item {
                let itemMetadata = actualItem.metadata
                self.verifyMetadata(itemMetadata)
            }

            getItemMetadataExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(2.0, handler: nil)
    }


    func testEnumaration() {
        let vault = client.defaultVault()

        var found = false
        var finishEnumerationExpectation = self.expectationWithDescription("finished enumeration")

        vault.enumerateVaultItemsUsingBlock({ (itemMetadata : QredoVaultItemMetadata!, stop : UnsafeMutablePointer<ObjCBool>) -> Void in

            if let actualDescriptor = itemMetadata.descriptor {
                if actualDescriptor == self.itemDescriptor {
                    print("found")
                    found = true
                }
            }

        }, completionHandler: { error in
            XCTAssertNil(error, "failed")

            finishEnumerationExpectation.fulfill()
        })

        waitForExpectationsWithTimeout(5.0) { error in
            finishEnumerationExpectation = nil
        }

        XCTAssertTrue(found, "didn't find item through enumeration")
    }

}
