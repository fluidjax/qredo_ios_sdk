import Foundation
import XCTest

class QredoVaultDescriptorTests: XCTestCase {
    let client = QredoClient(serviceURL: NSURL(string: QREDO_HTTP_SERVICE_URL), options:["QredoClientOptionVaultID" : QredoQUID()])
    var itemDescriptor : QredoVaultItemDescriptor? = nil

    let initialSummaryValues = ["key 1" : "value 1"]

    override func setUp() {
        super.setUp()

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

        XCTAssertTrue(itemMetadata.summaryValues.contains(self.initialSummaryValues), "lost summaryValues")

        XCTAssertNotNil(itemMetadata.descriptor, "Descriptor should not be nil")

        if let actualDescriptor = itemMetadata.descriptor {
            XCTAssertTrue(itemMetadata.descriptor.isEqual(self.itemDescriptor!), "Desriptor should be the same")
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

            let itemMetadata = item.metadata
            self.verifyMetadata(itemMetadata)

            getItemMetadataExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(2.0, handler: nil)
    }


    func testEnumaration() {
        let vault = client.defaultVault()

        var found = false
        let finishEnumerationExpectation = self.expectationWithDescription("finished enumeration")

        vault.enumerateVaultItemsUsingBlock({ (itemMetadata : QredoVaultItemMetadata!, stop : UnsafeMutablePointer<ObjCBool>) -> Void in

            if let actualDescriptor = itemMetadata.descriptor {
                if actualDescriptor == self.itemDescriptor {
                    found = true
                }
            }

        }, completionHandler: { error in
            XCTAssertNil(error, "failed")

            finishEnumerationExpectation.fulfill()
        })

        waitForExpectationsWithTimeout(5.0, handler: nil)

        XCTAssertTrue(found, "didn't find item through enumeration")
    }

}
