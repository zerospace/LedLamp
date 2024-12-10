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
        case invalidTemperature
    }
    
    var red: Double
    var green: Double
    var blue: Double
    var brightness: Double
    var mode: Mode
    var temperature: ColorTemperature
    
    var data: Data {
        var buffer = Data()
        buffer.append(UInt8(red))
        buffer.append(UInt8(green))
        buffer.append(UInt8(blue))
        buffer.append(UInt8(brightness))
        buffer.append(mode.rawValue)
        buffer.append(UInt8((temperature.rawValue >> 16) & 0xFF))
        buffer.append(UInt8((temperature.rawValue >> 8) & 0xFF))
        buffer.append(UInt8(temperature.rawValue & 0xFF))
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
        let brightness = data[offset]
        offset += 1
        guard let mode = LampState.Mode(rawValue: data[offset]) else { throw LampState.Error.invalidMode }
        offset += 1
        let temperature = Int(data[offset]) << 16 | Int(data[offset + 1]) << 8 | Int(data[offset + 2])
        guard let colorTemperature = ColorTemperature(rawValue: temperature) else { throw LampState.Error.invalidTemperature }
        return LampState(red: Double(red), green: Double(green), blue: Double(blue), brightness: Double(brightness), mode: mode, temperature: colorTemperature)
    }
}
