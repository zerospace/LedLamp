//
//  LampState.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 08.12.2024.
//

import Foundation

struct LampState {
    enum Mode: UInt8, CaseIterable {
        case color, rainbow
        
        var name: String {
            switch self {
            case .color: "💡 Color"
            case .rainbow: "🌈 Rainbow"
            }
        }
    }
    
    enum Error: LocalizedError {
        case invalidMode
    }
    
    var red: Double
    var green: Double
    var blue: Double
    var mode: Mode
    
    var data: Data {
        var buffer = Data()
        buffer.append(UInt8(red))
        buffer.append(UInt8(green))
        buffer.append(UInt8(blue))
        buffer.append(mode.rawValue)
        return buffer
    }
    
    static func deserialize(_ data: Data) throws -> LampState {
        var offset = 0
        let red = data[offset]
        offset += 1
        let green = data[offset]
        offset += 1
        let blue = data[offset]
        offset += 1
        guard let mode = LampState.Mode(rawValue: data[offset]) else { throw LampState.Error.invalidMode }
        return LampState(red: Double(red), green: Double(green), blue: Double(blue), mode: mode)
    }
}
