//
//  ContentView.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 30.11.2024.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.self) var environment
    
    private let network = NetworkService()
    
    @State private var red: Double = 0.0
    @State private var green: Double = 0.0
    @State private var blue: Double = 0.0
    @State private var brightness: Double = 0.0
    @State private var color: Color = .white
    
    @State private var isSliderEditinig = false
    
    @State private var mode: LampState.Mode = .color
    @State private var temperature: ColorTemperature = .tungsten100W
    
    var body: some View {
        Form {
            Section(header:
                HStack {
                    Spacer()
//                    Circle()
//                        .fill(.red)
//                        .stroke(.black)
//                        .frame(width: 128.0)
                CircularColorPicker(color: $color).padding()
                    Spacer()
                }
            ) {
                HStack {
                    Text("R")
                    Slider(value: $red, in: 0...255, step: 1) { editing in
                        isSliderEditinig = editing
                        if !editing {
                            network.state.red = UInt8(red)
                            network.command(.set, data: network.state.data)
                        }
                    }
                    .onChange(of: red) { oldValue, newValue in
                        color = Color(red: Double(newValue) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
                    }
                }
                
                HStack {
                    Text("G")
                    Slider(value: $green, in: 0...255, step: 1) { editing in
                        isSliderEditinig = editing
                        if !editing {
                            network.state.green = UInt8(green)
                            network.command(.set, data: network.state.data)
                        }
                    }
                    .onChange(of: green) { oldValue, newValue in
                        color = Color(red: Double(red) / 255, green: Double(newValue) / 255, blue: Double(blue) / 255)
                    }
                }
                
                HStack {
                    Text("B")
                    Slider(value: $blue, in: 0...255, step: 1) { editing in
                        isSliderEditinig = editing
                        if !editing {
                            network.state.blue = UInt8(blue)
                            network.command(.set, data: network.state.data)
                        }
                    }
                    .onChange(of: blue) { oldValue, newValue in
                        color = Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(newValue) / 255)
                    }
                }
            }
            
            
            Section(header: Text("Brightness")) {
                Slider(value: $brightness, in: 0...255, step: 1) { _ in
                    network.state.brightness = UInt8(brightness)
                    network.command(.set, data: network.state.data)
                }
            }
            
            Section {
                Picker("Mode", selection: $mode) {
                    ForEach(LampState.Mode.allCases, id: \.self) {
                        Text($0.name)
                    }
                }
                
                Picker("Color Temperature", selection: $temperature) {
                    ForEach(ColorTemperature.allCases, id: \.self) {
                        Text($0.name)
                    }
                }
            }
        }
        .onAppear {
            network.search()
        }
        .onReceive(network.$state) { state in
            red = Double(state.red)
            green = Double(state.green)
            blue = Double(state.blue)
            brightness = Double(state.brightness)
        }
        .onChange(of: color) { oldValue, newValue in
//            if !isSliderEditinig {
                let resolvedColor = newValue.resolve(in: environment)
                red = Double(resolvedColor.red) * 255
                network.state.red = UInt8(red)
                green = Double(resolvedColor.green) * 255
                network.state.green = UInt8(green)
                blue = Double(resolvedColor.blue) * 255
                network.state.blue = UInt8(blue)
//            }
        }
    }
}
