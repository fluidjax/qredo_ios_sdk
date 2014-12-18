/*
*  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
*/

import UIKit
import Foundation
import Security
import XCTest

class KeychainArchiverTests: XCTestCase {
    
    var keychainArchiver: QredoKeychainArchiver!

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func createKeychainWithVaultId(vaultId: QredoQUID, bulkKeyString: NSString, autenticationKeyString: NSString) -> QredoKeychain {
        
        let operatorInfo = QredoOperatorInfo(
            name: "MyOperator",
            serviceUri: "http://example.com/",
            accountID: "1234567890",
            currentServiceAccess: NSSet(),
            nextServiceAccess: NSSet()
        )
        
        let bulkKeyData = bulkKeyString.dataUsingEncoding(NSUTF8StringEncoding)
        let autenticationKeyData = autenticationKeyString.dataUsingEncoding(NSUTF8StringEncoding)
        
        return QredoKeychain(
            operatorInfo: operatorInfo,
            vaultId: vaultId,
            authenticationKey: autenticationKeyData, bulkKey: bulkKeyData
        )
        
    }
    
    struct KeychainData {
        let vaultId = QredoQUID()
        let bulkKeyString = "my bulk key string"
        let authKeyString = "my auth key string"
    }
    
    func createkeyChainWithKeychainData(keychainData: KeychainData) -> QredoKeychain {
        return self.createKeychainWithVaultId(keychainData.vaultId,
            bulkKeyString: keychainData.bulkKeyString,
            autenticationKeyString: keychainData.authKeyString
        )
    }
    
    func compareKeychain(keychain: QredoKeychain, toKeychainData keychainData: KeychainData) {
        XCTAssertEqual(keychain.vaultId(), keychainData.vaultId, "")
        XCTAssertEqual(keychain.vaultKeys().encryptionKey, keychainData.bulkKeyString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, "")
        XCTAssertEqual(keychain.vaultKeys().authenticationKey , keychainData.authKeyString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, "")
    }

    func saveGarbageAsKeychainWithId(keychainIdentifier: String, noKeychainData: Bool = false) -> Bool {
        assert(false, "This method must be implemented in subclasses.")
    }
    
    func deleteGarbageAsKeychainWithId(keychainIdentifier: String) -> Bool {
        assert(false, "This method must be implemented in subclasses.")
    }
    
    func commonSave() {
        
        let keychainData = KeychainData()
        let keychainId = "myKeychain1"
        
        var error: NSError?
        let keychain = self.createkeyChainWithKeychainData(keychainData)
        
        let saveRes = self.keychainArchiver.saveQredoKeychain(keychain, withIdentifier: keychainId, error: &error)
        XCTAssert(saveRes, "")
        XCTAssertNil(error, "")
        
        let resultKeychain = self.keychainArchiver.loadQredoKeychainWithIdentifier(keychainId, error: &error)
        XCTAssertNotNil(resultKeychain, "")
        XCTAssertNil(error, "")
        self.compareKeychain(resultKeychain, toKeychainData: keychainData)
        
        self.keychainArchiver.saveQredoKeychain(nil, withIdentifier: keychainId, error: &error)
        
    }
    
    func commonOverwrite() {
        
        let keychainData = KeychainData()
        let keychainData2 = KeychainData(vaultId: QredoQUID(), bulkKeyString: "some other bulk key", authKeyString: "some other auth key")
        let keychainId = "myKeychain2"
        
        var error: NSError?
        
        
        let keychain = self.createkeyChainWithKeychainData(keychainData)
        
        let saveRes = self.keychainArchiver.saveQredoKeychain(keychain, withIdentifier: keychainId, error: &error)
        XCTAssert(saveRes, "")
        XCTAssertNil(error, "")
        
        let resultKeychain = self.keychainArchiver.loadQredoKeychainWithIdentifier(keychainId, error: &error)
        XCTAssertNotNil(resultKeychain, "")
        XCTAssertNil(error, "")
        self.compareKeychain(resultKeychain, toKeychainData: keychainData)
        
        let keychain2 = self.createkeyChainWithKeychainData(keychainData2)
        let saveRes2 = self.keychainArchiver.saveQredoKeychain(keychain2, withIdentifier: keychainId, error: &error)
        XCTAssert(saveRes, "")
        XCTAssertNil(error, "")
        
        let resultKeychain2 = self.keychainArchiver.loadQredoKeychainWithIdentifier(keychainId, error: &error)
        XCTAssertNotNil(resultKeychain2, "")
        XCTAssertNil(error, "")
        self.compareKeychain(resultKeychain2, toKeychainData: keychainData2)

        self.keychainArchiver.saveQredoKeychain(nil, withIdentifier: keychainId, error: &error)
        
    }
    
    func commonDelete() {
        
        let keychainData = KeychainData()
        let keychainId = "myKeychain3"
        
        var error: NSError?
        let keychain = self.createkeyChainWithKeychainData(keychainData)
        
        let saveRes = self.keychainArchiver.saveQredoKeychain(keychain, withIdentifier: keychainId, error: &error)
        XCTAssert(saveRes, "")
        XCTAssertNil(error, "")
        
        let resultKeychain = self.keychainArchiver.loadQredoKeychainWithIdentifier(keychainId, error: &error)
        XCTAssertNotNil(resultKeychain, "")
        XCTAssertNil(error, "")
        self.compareKeychain(resultKeychain, toKeychainData: keychainData)
        
        self.keychainArchiver.saveQredoKeychain(nil, withIdentifier: keychainId, error: &error)
        
        let resultKeychain2 = self.keychainArchiver.loadQredoKeychainWithIdentifier(keychainId, error: &error)
        XCTAssertNil(resultKeychain2, "")
        XCTAssertNotNil(error, "")
        XCTAssertEqual(error!.domain, QredoErrorDomain, "")
        XCTAssertEqual(QredoErrorCode(rawValue: error!.code)!, QredoErrorCode.KeychainCouldNotBeFound, "")
        
    }
    
    func commonLoadError() {
        
        let keychainData = KeychainData()
        let keychainId = "myKeychain4"
        
        var error: NSError?
        let keychain = self.createkeyChainWithKeychainData(keychainData)
        
        let saveRes = self.saveGarbageAsKeychainWithId(keychainId)
        
        let resultKeychain = self.keychainArchiver.loadQredoKeychainWithIdentifier(keychainId, error: &error)
        XCTAssertNil(resultKeychain, "")
        XCTAssertNotNil(error, "")
        XCTAssertEqual(error!.domain, QredoErrorDomain, "")
        XCTAssertEqual(QredoErrorCode(rawValue: error!.code)!, QredoErrorCode.KeychainCouldNotBeRetrieved, "")
        
        self.deleteGarbageAsKeychainWithId(keychainId)

    }
    
    func commonLoadErrorNoData() {
        
        let keychainData = KeychainData()
        let keychainId = "myKeychain4"
        
        var error: NSError?
        let keychain = self.createkeyChainWithKeychainData(keychainData)
        
        let saveRes = self.saveGarbageAsKeychainWithId(keychainId, noKeychainData: true)
        
        let resultKeychain = self.keychainArchiver.loadQredoKeychainWithIdentifier(keychainId, error: &error)
        XCTAssertNil(resultKeychain, "")
        XCTAssertNotNil(error, "")
        XCTAssertEqual(error!.domain, QredoErrorDomain, "")
        XCTAssertEqual(QredoErrorCode(rawValue: error!.code)!, QredoErrorCode.KeychainCouldNotBeRetrieved, "")
        
        self.deleteGarbageAsKeychainWithId(keychainId)
        
    }
}



class KeychainArchiverForApplekeychainTests: KeychainArchiverTests {

    override func setUp() {
        super.setUp()
        keychainArchiver = QredoKeychainArchiverForAppleKeychain()
    }
    
    override func saveGarbageAsKeychainWithId(keychainIdentifier: String, noKeychainData: Bool = false) -> Bool {
        
        var dictionary = NSMutableDictionary()
        dictionary[kSecClass as NSString] = kSecClassGenericPassword as NSString
        dictionary[kSecAttrService as NSString] = "CurrentService"
        dictionary[kSecAttrAccount as NSString] = keychainIdentifier as NSString
        if noKeychainData != false {
            dictionary[kSecValueData as NSString] = "test".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        }
        
        let sanityCheck = SecItemAdd(dictionary as CFDictionaryRef, nil)
        if sanityCheck != noErr {
            return false
        }
        
        return true
        
    }
    
    override func deleteGarbageAsKeychainWithId(keychainIdentifier: String) -> Bool {
        
        var dictionary = NSMutableDictionary()
        dictionary[kSecClass as NSString] = kSecClassGenericPassword as NSString
        dictionary[kSecAttrService as NSString] = "CurrentService"
        dictionary[kSecAttrAccount as NSString] = keychainIdentifier as NSString
        
        let sanityCheck = SecItemDelete(dictionary as CFDictionaryRef)
        if sanityCheck != noErr {
            return false
        }
        
        return true
        
    }
    
    func testSave() {
        self.commonSave()
    }
    
    func testOverwritte() {
        self.commonOverwrite()
    }
    
    func testDelete() {
        self.commonDelete()
    }
    
    func testLooadError() {
        self.commonLoadError()
    }
    
    func testLoadErrorNoData() {
        self.commonLoadErrorNoData()
    }
}

