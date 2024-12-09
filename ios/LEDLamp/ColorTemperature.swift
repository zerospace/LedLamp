//
//  ColorTemperature.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 08.12.2024.
//

import Foundation

enum ColorTemperature: Int, CaseIterable {
    case candle = 0xFF9329
    case tungsten40W = 0xFFC58F
    case tungsten100W = 0xFFD6AA
    case halogen = 0xFFF1E0
    case carbonArc = 0xFFFAF4
    case highNoonSun = 0xFFFFFB
    case directSunlight = 0xFFFFFF
    case overcastSky = 0xC9E2FF
    case clearBlueSky = 0x409CFF
    case warmFluorescent = 0xFFF4E5
    case standardFluorescent = 0xF4FFFA
    case coolWhiteFluorescent = 0xD4EBFF
    case fullSpectrumFluorescent = 0xFFF4F2
    case growLightFluorescent = 0xFFEFF7
    case blackLightFluorescent = 0xA700FF
    case mercuryVapor = 0xD8F7FF
    case sodiumVapor = 0xFFD1B2
    case metalHalide = 0xF2FCFF
    case highPressureSodium = 0xFFB74C
    
    var name: String {
        switch self {
        case .candle: "Candle"
        case .tungsten40W: "Tungsten 40W"
        case .tungsten100W: "Tungsten 100W"
        case .halogen: "Halogen"
        case .carbonArc: "Carbon Arc"
        case .highNoonSun: "High Noon Sun"
        case .directSunlight: "Direct Sunlight"
        case .overcastSky: "Overcast Sky"
        case .clearBlueSky: "Clear Blue Sky"
        case .warmFluorescent: "Warm Fluorescent"
        case .standardFluorescent: "Standard Fluorescent"
        case .coolWhiteFluorescent: "Cool White Fluorescent"
        case .fullSpectrumFluorescent: "Full Spectrum Fluorescent"
        case .growLightFluorescent: "Grow Light Fluorescent"
        case .blackLightFluorescent: "Black Light Fluorescent"
        case .mercuryVapor: "Mercury Vapor"
        case .sodiumVapor: "Sodium Vapor"
        case .metalHalide: "Metal Halide"
        case .highPressureSodium: "High Pressure Sodium"
        }
    }
}
