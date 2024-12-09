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
    
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var brightness: UInt8
    var mode: Mode
    var temperature: ColorTemperature
    
    var data: Data {
        var buffer = Data()
        buffer.append(red)
        buffer.append(green)
        buffer.append(blue)
        buffer.append(brightness)
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
        return LampState(red: red, green: green, blue: blue, brightness: brightness, mode: mode, temperature: colorTemperature)
    }
}
