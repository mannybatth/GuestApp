//
//  YikesEngineTests.swift
//  YikesEngineTests
//
//  Created by Roger on 1/20/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import XCTest
import CryptoSwift

class YikesEngineTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let pl_random:[UInt8] = [0xCA, 0xFE, 0xBA, 0xBE]
        //                let iv = generateRandomBytes(length: 16)
        let iv:[UInt8] =
           [0x00, 0x00,
            0x00, 0x0F, 0xF1, 0xCE,
            0xCA, 0xFE, 0xD0, 0x0D,
            0xC0, 0xFF, 0xEE, 0xFA,
            0xCE, 0x11]
        
        XCTAssert(pl_random.count == 4, "pl_random is not 4 bytes long")
        XCTAssert(iv.count == 16, "iv is not 16 bytes long")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testDecryptionAES_CFB() {
        
        let encrpytedHexString = "fb70fa719cff8c3f69be0890d3eea271a565227448f08a573524106f0fa7fe171f9038917cf725791a9997de3c0b063dc784a08f2d754998912ea78e56b1b1c1"
        let keyHexString = "76656e692c766964692c76696369213b"
        let ivHexString = "6861696c6a756c697573636165736172"
        
        guard let encrypted = encrpytedHexString.dataFromHexadecimalString()?.convertToBytes(),
            let key = keyHexString.dataFromHexadecimalString()?.convertToBytes(),
            let iv  = ivHexString.dataFromHexadecimalString()?.convertToBytes() else {
                return
        }
        
        do {
            let decryptedBytes: [UInt8] = try AES(key: key, iv: iv, blockMode: .CFB).decrypt(encrypted, padding: nil)
            let data = NSData(bytes: decryptedBytes)
            
            print("\nencrypted: '\(encrpytedHexString)'")
            print("key: '\(keyHexString)'")
            print("iv: '\(ivHexString)'\n")
            print("Decryption: AES_CFB RESULT: \(data.hexadecimalString())\n")
            
        } catch AES.Error.BlockSizeExceeded {
            // block size exceeded
        } catch {
            // some error
        }
    }
    
    func testEncryptionAES_CFB() {
        
        let inputHexString = "87cf9fb0df7b54bde6e65b9d9557247d05ebf716dc4f37f4ee143f57fc10e2d92b50087ca9a09cb018f3516a3c57bb6080d0d04ccac6c5df14a1e6097d05de6a"
        let keyHexString = "76656e692c766964692c76696369213b"
        let ivHexString = "6861696c6a756c697573636165736172"
        
        guard let input = inputHexString.dataFromHexadecimalString()?.convertToBytes(),
            let key = keyHexString.dataFromHexadecimalString()?.convertToBytes(),
            let iv  = ivHexString.dataFromHexadecimalString()?.convertToBytes() else {
                return
        }
        
        do {
            let encryptedBytes: [UInt8] = try AES(key: key, iv: iv, blockMode: .CFB).encrypt(input, padding: nil)
            let data = NSData(bytes: encryptedBytes)
            
            print("\ninput: '\(inputHexString)'")
            print("key: '\(keyHexString)'")
            print("iv: '\(ivHexString)'\n")
            print("Encryption: AES_CFB RESULT: \(data.hexadecimalString())\n")
            
        } catch AES.Error.BlockSizeExceeded {
            // block size exceeded
        } catch {
            // some error
        }
    }
    
}

extension NSData {
    
    func hexadecimalString() -> String {
        var string = ""
        var byte: UInt8 = 0
        
        for i in 0 ..< length {
            getBytes(&byte, range: NSMakeRange(i, 1))
            string += String(format: "%02x", byte)
        }
        
        return string
    }
    
    func convertToBytes() -> [UInt8] {
        
        let count = self.length / sizeof(UInt8)
        var bytes = [UInt8](count: count, repeatedValue: 0)
        self.getBytes(&bytes, length:count * sizeof(UInt8))
        return bytes
    }
}

extension String {
    
    /// Create NSData from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a NSData object. Note, if the string has any spaces, those are removed. Also if the string started with a '<' or ended with a '>', those are removed, too. This does no validation of the string to ensure it's a valid hexadecimal string
    ///
    /// The use of `strtoul` inspired by Martin R at http://stackoverflow.com/a/26284562/1271826
    ///
    /// - returns: NSData represented by this hexadecimal string. Returns nil if string contains characters outside the 0-9 and a-f range.
    
    func dataFromHexadecimalString() -> NSData? {
        let trimmedString = self.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<> ")).stringByReplacingOccurrencesOfString(" ", withString: "")
        
        // make sure the cleaned up string consists solely of hex digits, and that we have even number of them
        
        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .CaseInsensitive)
        
        let found = regex.firstMatchInString(trimmedString, options: [], range: NSMakeRange(0, trimmedString.characters.count))
        if found == nil || found?.range.location == NSNotFound || trimmedString.characters.count % 2 != 0 {
            return nil
        }
        
        // everything ok, so now let's build NSData
        
        let data = NSMutableData(capacity: trimmedString.characters.count / 2)
        
        for var index = trimmedString.startIndex; index < trimmedString.endIndex; index = index.successor().successor() {
            let byteString = trimmedString.substringWithRange(Range<String.Index>(start: index, end: index.successor().successor()))
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data?.appendBytes([num] as [UInt8], length: 1)
        }
        
        return data
    }
}


