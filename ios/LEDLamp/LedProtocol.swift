//
//  LedProtocol.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 01.12.2024.
//

import Foundation
import Network

final class LedProtocol: NWProtocolFramerImplementation {
    static let serviceName = "_lamp._tcp"
    private let frameName = "LED"
    
    enum Command: UInt8 {
        case invalid = 0x00
        case info = 0xAA
    }
    
    enum MessageType: UInt8 {
        case invalid = 0x00
        case command = 0x01
        case response = 0x02
    }
    
    struct Message: Identifiable {
        let id = UUID()
        let type: MessageType
        let command: Command
        let data: Data?
    }
    
    static let definition = NWProtocolFramer.Definition(implementation: LedProtocol.self)
    static var label: String { return "LEDLamp" }
    
    required init(framer: NWProtocolFramer.Instance) { }
    
    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { .ready }
    func wakeup(framer: NWProtocolFramer.Instance) { }
    func stop(framer: NWProtocolFramer.Instance) -> Bool { true }
    func cleanup(framer: NWProtocolFramer.Instance) { }
    
    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            var packageHeader: LedProtocolHeader? = nil
            var packageBody: Data? = nil
            var checksum: UInt16 = 0
            let headerSize = LedProtocolHeader.encodedSize
            let package = framer.parseInput(minimumIncompleteLength: 0, maximumLength: 65547) { buffer, isComplete in
                guard let buffer = buffer else { return 0 }
                print(Data(buffer).hexDescription)
                if Data(buffer.prefix(3)) == frameName.data(using: .utf8) {
                    packageHeader = LedProtocolHeader(buffer)
                    if let header = packageHeader {
                        packageBody = Data(count: Int(header.length))
                        packageBody?.withUnsafeMutableBytes { ptr in
                            ptr.copyMemory(from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: headerSize), count: Int(header.length)))
                        }
                        
                        withUnsafeMutableBytes(of: &checksum) { ptr in
                            ptr.copyMemory(from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: headerSize + Int(header.length)), count: MemoryLayout<UInt16>.size))
                        }
                        
                        return headerSize + Int(header.length) + MemoryLayout<UInt16>.size
                    }
                }
                return 0
            }
            
            guard package, let header = packageHeader, checksum > 0 else { return 0 }
            
            var response = header.encodedData
            if let body = packageBody {
                response.append(body)
            }
                
            let crc = Array(response).crc16.bigEndian
            if crc != checksum {
                return 0
            }
            
            let message = NWProtocolFramer.Message(header: header, data: packageBody)
            if !framer.deliverInputNoCopy(length: 0, message: message, isComplete: true) {
                return 0
            }
        }
    }
    
    func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        let start = frameName.data(using: .utf8)!
        let header = message.header.encodedData
        let body = message.data
        
        var request = header
        if let data = body {
            request.append(data)
        }
        
        var crc = Array(request).crc16.bigEndian
        let crcData = Data(bytes: &crc, count: MemoryLayout<UInt16>.size)
        request.append(crcData)
        request.insert(contentsOf: start, at: 0)
        
        framer.writeOutput(data: request)
    }
}

extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "0x%02x ", $1)}
    }
}

extension NWProtocolFramer.Message  {
    convenience init(header: LedProtocolHeader, data: Data?) {
        self.init(definition: LedProtocol.definition)
        self["Header"] = header
        self["Data"] = data
    }
    
    var header: LedProtocolHeader {
        if let header = self["Header"] as? LedProtocolHeader {
            return header
        }
        return try! LedProtocolHeader(function: .invalid, type: .invalid, dataLength: 0)
    }
    var data: Data? { self["Data"] as? Data }
}

struct LedProtocolHeader: Hashable {
    let function: LedProtocol.Command
    let messageType: LedProtocol.MessageType
    let length: UInt8
    
    enum Error: LocalizedError {
        case bigData
        
        var errorDescription: String? { "Message size is too big." }
    }
    
    init(_ buffer: UnsafeMutableRawBufferPointer) {
        var tmpFunc: UInt8 = 0
        var tmpMsgType: UInt8 = 0
        var tmpLen: UInt8 = 0
        
        let uint8_size = MemoryLayout<UInt8>.size
        
        withUnsafeMutableBytes(of: &tmpMsgType) { ptr in
            ptr.copyMemory(from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: 3), count: uint8_size))
        }
        
        withUnsafeMutableBytes(of: &tmpFunc) { ptr in
            ptr.copyMemory(from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: uint8_size + 3), count: uint8_size))
        }
        
        withUnsafeMutableBytes(of: &tmpLen) { ptr in
            ptr.copyMemory(from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: uint8_size + uint8_size + 3), count: uint8_size))
        }
        
        self.function = LedProtocol.Command(rawValue: tmpFunc.bigEndian) ?? .invalid
        self.messageType = LedProtocol.MessageType(rawValue: tmpMsgType) ?? .invalid
        self.length = tmpLen
    }
    
    init(function: LedProtocol.Command, type: LedProtocol.MessageType, dataLength: Int) throws {
        self.function = function
        self.messageType = type
        guard dataLength <= UInt8.max else { throw LedProtocolHeader.Error.bigData }
        self.length = UInt8(dataLength)
    }
    
    var encodedData: Data {
        var tempType = messageType.rawValue
        var tempFunc = function.rawValue
        var tempLength = length
        
        var data = Data(bytes: &tempType, count: MemoryLayout<UInt8>.size)
        data.append(Data(bytes: &tempFunc, count: MemoryLayout<UInt8>.size))
        data.append(Data(bytes: &tempLength, count: MemoryLayout<UInt8>.size))
        
        return data
    }
    
    static var encodedSize: Int {
        return MemoryLayout<UInt8>.size + MemoryLayout<UInt8>.size + MemoryLayout<UInt8>.size + 3
    }
}

// CRC-CCITT (0xFFFF)
extension Array where Element == UInt8 {
    var crc16: UInt16 {
        let polynomial: UInt16 = 0x1021
        var crc: UInt16 = 0xFFFF
        
        for byte in self {
            for i in 0..<8 {
                let bit = (byte >> (7 - i) & 1) == 1
                let c15 = ((crc >> 15) & 1) == 1
                crc <<= 1
                if c15 != bit {
                    crc ^= polynomial
                }
            }
            crc &= 0xFFFF
        }
        return crc
    }
}
