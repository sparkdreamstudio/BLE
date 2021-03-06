//
//  Crypto.swift
//  Crypto
//
//  Created by 程巍巍 on 3/19/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//  
//  需在 Bridg_Header.h 中 #import <CommonCrypto/CommonCrypto.h>

import Foundation

class Crypto : NSObject {
    static func MD5(data data: NSData) -> String{
        let c_data = data.bytes
        var md: [UInt8] = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
        CC_MD5(c_data, CC_LONG(data.length), UnsafeMutablePointer<UInt8>(md))
        
        var ret: String = ""
        for index in 0 ..< Int(CC_MD5_DIGEST_LENGTH) {
            ret += String(format: "%.2X", md[index])
        }
        return ret
    }
    static func MD5(file file: String) ->String?{
        let inStream = NSInputStream(fileAtPath: file)
        if inStream == nil {return nil}
        
        inStream?.open()
        if inStream!.streamStatus != NSStreamStatus.Open {return nil}
        
        var hashObject: CC_MD5_CTX = CC_MD5state_st(A: 0, B: 0, C: 0, D: 0, Nl: 0, Nh: 0, data: (CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0),CC_LONG(0)), num: 0)
        CC_MD5_Init(&hashObject)
        
        var hasMoreData = true
        let buffer = UnsafeMutablePointer<UInt8>.alloc(4096)
        var readBytesCount = 0
        while hasMoreData {
            readBytesCount = inStream!.read(buffer, maxLength: 4096)
            if readBytesCount == -1 {break}
            if readBytesCount == 0 {hasMoreData = false; continue}
            CC_MD5_Update(&hashObject, buffer, CC_LONG(readBytesCount))
        }
        buffer.dealloc(4096)
        
        var md: [UInt8] = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
        CC_MD5_Final(UnsafeMutablePointer<UInt8>(md), &hashObject)
        
        var ret: String = ""
        for index in 0 ..< Int(CC_MD5_DIGEST_LENGTH) {
            ret += String(format: "%.2X", md[index])
        }
        return ret
    }
    
    static func Base64Encode(data data: NSData) -> String{
        let inStream = NSInputStream(data: data)
        inStream.open()
        let buffer = UnsafeMutablePointer<UInt8>.alloc(3)
        var bValue: Int = 0
        let ret: NSMutableString = NSMutableString()
        while inStream.read(buffer, maxLength: 3) == 3{
            bValue = (Int(buffer[0]) << 16) + (Int(buffer[1]) << 8) + Int(buffer[2])
            ret.appendString(base64_table[bValue >> 18])
            ret.appendString(base64_table[bValue >> 12 & 0b111111])
            ret.appendString(base64_table[bValue >> 6 & 0b111111])
            ret.appendString(base64_table[bValue & 0b111111])
        }
        let remainBitLen = data.length%3
        bValue = 0
        memset(buffer + remainBitLen, 0, 3 - remainBitLen)
        bValue = (Int(buffer[0]) << 16) | (Int(buffer[1]) << 8) | Int(buffer[2])
        for index in 0 ... remainBitLen {
            ret.appendString(base64_table[bValue >> (18 - index * 6) & 0b111111])
        }
        if remainBitLen != 0 { ret.appendString(remainBitLen == 1 ? "==" : "=")}
        inStream.close()
        buffer.dealloc(3)
        return ret as String
    }
    static func Base64Decode(data data: String) -> NSData{
        let inStream = NSInputStream(data: (data as NSString).dataUsingEncoding(NSUTF8StringEncoding)!)
        inStream.open()
        let buffer = UnsafeMutablePointer<UInt8>.alloc(4)
        var bValue: Int = 0
        let value: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.alloc(3)
        let ret: NSMutableData = NSMutableData()
        while inStream.read(buffer, maxLength: 4) == 4{
            bValue = de_base64_table[Int(buffer[0])] << 18 | de_base64_table[Int(buffer[1])] << 12 | de_base64_table[Int(buffer[2])] << 6 | de_base64_table[Int(buffer[3])]
            value[0] = UInt8(bValue >> 16)
            value[1] = UInt8(bValue >> 8 & 0xff)
            value[2] = UInt8(bValue & 0xff)
            ret.appendBytes(value, length: 3)
        }
        
        // 处理最后三位
        var additionalBitLen = 0
        for index in 0 ... 3 {
            if buffer[index] == 61 {    // "="
                buffer[index] = 0
                additionalBitLen++
            }
        }
        if additionalBitLen != 0 {
            bValue = de_base64_table[Int(buffer[0])] << 18 | de_base64_table[Int(buffer[1])] << 12 | de_base64_table[Int(buffer[2])] << 6 | de_base64_table[Int(buffer[3])]
            value[0] = UInt8(bValue >> 16)
            value[1] = UInt8(bValue >> 8 & 0xff)
            value[2] = UInt8(bValue & 0xff)
            
            ret.replaceBytesInRange(NSMakeRange(ret.length - 3, 3), withBytes: value, length: 3 - additionalBitLen)
        }
        inStream.close()
        value.dealloc(3)
        buffer.dealloc(4)
        return ret
    }
    
    // 对称加密
    let aes128 = 1
    enum SymmetricCryptType{
        case AES128
        case AES192
        case AES256
        case DES
        case DES3
        
        var keySize: Int64{
            return (self.rawValue & 0xFFFF0000) >> 16
        }
        var algorithm: CCAlgorithm{
            return CCAlgorithm(self.rawValue & 0xFFFF)
        }
        private var rawValue: Int64{
            switch self {
            case .AES128: return Int64(kCCKeySizeAES128) << 16 | Int64(kCCAlgorithmAES)
            case .AES192: return Int64(kCCKeySizeAES192) << 16 | Int64(kCCAlgorithmAES)
            case .AES256: return Int64(kCCKeySizeAES256) << 16 | Int64(kCCAlgorithmAES)
            case .DES: return Int64(kCCKeySizeDES) << 16 | Int64(kCCAlgorithmDES)
            case .DES3: return Int64(kCCKeySize3DES) << 16 | Int64(kCCAlgorithm3DES)
            }
        }
        
        private static let aes128: Int = kCCKeySizeAES128 << 16 | Int(kCCAlgorithmAES)
    }
    static func SymmetricEncrypt(data: NSData, withPassword password: String, type: SymmetricCryptType) ->NSData {
        _ = type.keySize
        return SymmetricCrypt(data: data, keyStr: password, keySize: Int(type.keySize), algorithm: type.algorithm, operation: CCOperation(kCCEncrypt))
    }
    static func SymmetricDecrypt(data: NSData, withPassword password: String, type: SymmetricCryptType) ->NSData {
        return SymmetricCrypt(data: data, keyStr: password, keySize: Int(type.keySize), algorithm: type.algorithm, operation: CCOperation(kCCDecrypt))
    }    
    // 非对称加密
    // 使用公钥加密
//    static func RSAEncrypt(data: NSData, publicKey: NSData) ->NSData{
//        let secKey: SecKeyRef = RSAPublicKey(data: publicKey)
//        let dataLength = data.length
//        
//        // Notice 这里有三个数据长度的变量：blockSize chiperTextLength plaintextLength
//        // When PKCS1 padding is performed, the maximum length of data that can be encrypted is the value returned by SecKeyGetBlockSize() - 11. (SecKey.h)
//        let blockSize            = Int(SecKeyGetBlockSize(secKey)-11)
//        let blockCount           = Int(ceil(CDouble(dataLength/Int(blockSize))) + 1)
//        
//        var chiperTextLength: Int = 0
//        // 缓存待加密的数据块
//        let plainText: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.alloc(blockSize * sizeof(UInt8))
//        var plainTextLength      = blockSize;
//        // 缓存加密后的数据
//        let chiperText: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.alloc(plainTextLength * sizeof(UInt8))
//        
//        let encryptedData = NSMutableData()
//        
//        for (var i = 0; i < blockCount; i++){
//            plainTextLength  = min(blockSize, dataLength - i*blockSize)
//            data.getBytes(plainText, range: NSMakeRange(i * blockSize, plainTextLength))
//            let status: OSStatus = SecKeyEncrypt(secKey,
//                SecPadding.PKCS1,
//                plainText, plainTextLength,
//                chiperText, &chiperTextLength
//            )
//            if status == noErr {
//                encryptedData.appendBytes(chiperText, length: Int(chiperTextLength))
//            }else{
//                i = blockCount
//            }
//        }
//        chiperText.dealloc(blockSize * sizeof(UInt8))
//        plainText.dealloc(plainTextLength * sizeof(UInt8))
//        return encryptedData
//    }
//    // 使用私钥解密
//    static func RSADecrypt(data: NSData, privateKey: NSData, password: String) ->NSData{
//        let dataLength = data.length
//        let secKey: SecKeyRef = RSAPrivateKey(data: privateKey, password: password)
//        
//        // Notice 这里有三个数据长度的变量：blockSize chiperTextLength plaintextLength
//        let blockSize        = Int(SecKeyGetBlockSize(secKey))
//        let blockCount       = Int(ceil(CDouble(dataLength/Int(blockSize)))+1)
//        
//        var chiperTextLength: Int = 0
//        // 缓存待加密的数据块
//        let plainText: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.alloc(blockSize * sizeof(UInt8))
//        var plainTextLength      = blockSize;
//        // 缓存解密后的数据
//        let chiperText: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.alloc(plainTextLength * sizeof(UInt8))
//        
//        let decryptedData = NSMutableData()
//        
//        for (var i = 0; i < blockCount; i++) {
//            plainTextLength = min(blockSize, dataLength - i * blockSize);
//            data.getBytes(plainText, range: NSMakeRange(i * blockSize, plainTextLength))
//            let status: OSStatus = SecKeyDecrypt(secKey,
//                SecPadding.PKCS1,
//                plainText, plainTextLength,
//                chiperText, &chiperTextLength);
//            if status == noErr {
//                decryptedData.appendBytes(chiperText, length: Int(chiperTextLength))
//            }else{
//                i = blockCount
//            }
//        }
//        chiperText.dealloc(blockSize * sizeof(UInt8))
//        plainText.dealloc(plainTextLength * sizeof(UInt8))
//        return decryptedData
//    }
}

extension Crypto {
    private static func SymmetricCrypt(data data: NSData, keyStr: String, keySize: Int, algorithm: CCAlgorithm, operation: CCOperation) ->NSData{
        let keyLength = ((keyStr as NSString).length/keySize+1)*keySize+1
        var key = [CChar](count: keyLength, repeatedValue: 0)
        
        keyStr.getCString(&key, maxLength: keyLength, encoding: NSUTF8StringEncoding)
        
        let dataLength = data.length
        let bufferSize = dataLength + kCCBlockSizeAES128
        let buffer = UnsafeMutablePointer<Void>.alloc(Int(bufferSize))
        
        var retLen = 0
        
        let status: CCCryptorStatus = CCCrypt(
            operation, algorithm,
            CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode),
            UnsafePointer<Void>(key), keySize,
            nil,
            data.bytes, dataLength,
            buffer, bufferSize,
            &retLen
        )
        
        var result: NSData!
        if Int(status) == kCCSuccess{
            result = NSData(bytesNoCopy: buffer, length: retLen)
        }
        
        return result
    }
    
//    private static func RSAPrivateKey(data data: NSData, password: String) ->SecKey{
//        var options = [kSecImportExportPassphrase]
//        var items: Unmanaged<CFArray>?
//        var status = SecPKCS12Import(data, options, &items)
//        var nItems: NSArray = items!.takeRetainedValue()
//        var privateKey: Unmanaged<SecKey>?
//        if status == noErr && items != nil && nItems.count > 0 {
//            var identities: NSDictionary = nItems.objectAtIndex(0) as! NSDictionary
//            var identity = identities.objectForKey(kSecImportItemIdentity) as! SecIdentity
//            status = SecIdentityCopyPrivateKey(identity, &privateKey)
//            if status != noErr {privateKey = nil}
//        }
//        assert(privateKey != nil, "Crypto error : RSA privateKey key load faild.")
//        return privateKey!.takeRetainedValue()
//    }
//    
//    private static func RSAPublicKey(data data: NSData) ->SecKey{
//        let certification: SecCertificate = SecCertificateCreateWithData(kCFAllocatorDefault, data)!
//        let policy: SecPolicy = SecPolicyCreateBasicX509()
//        var utrust: Unmanaged<SecTrust>?
//        var status: OSStatus =  SecTrustCreateWithCertificates(certification, policy, &utrust);
//        let trust: SecTrust = utrust!.takeRetainedValue()
//        let trustResult = UnsafeMutablePointer<SecTrustResultType>()
//        if status == noErr { status = SecTrustEvaluate(trust, trustResult) }
//        
//        let publicKey: SecKey? = status == noErr ? SecTrustCopyPublicKey(trust) : nil
//        
//        assert(publicKey != nil, "Crypto error : RSA public key load faild.")
//        return publicKey!
//    }
}

extension Crypto {
    private static let base64_table = [
        "A", "B", "C", "D", "E", "F", "G", "H",
        "I", "J", "K", "L", "M", "N", "O", "P",
        "Q", "R", "S", "T", "U", "V", "W", "X",
        "Y", "Z", "a", "b", "c", "d", "e", "f",
        "g", "h", "i", "j", "k", "l", "m", "n",
        "o", "p", "q", "r", "s", "t", "u", "v",
        "w", "x", "y", "z", "0", "1", "2", "3",
        "4", "5", "6", "7", "8", "9", "+", "/"
    ]
    private static let de_base64_table = [
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x3E,0x00,0x00,0x00,0x3F,
        0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,
        0x0F,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x00,0x00,0x00,0x00,0x00,
        0x00,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F,0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,
        0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F,0x30,0x31,0x32,0x33,0x00,0x00,0x00,0x00,0x00
    ]
}


