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
    
    @State private var state: LampState = .init(red: 0.0, green: 0.0, blue: 0.0, brightness: 0.0, mode: .color, temperature: .tungsten100W)
    @State private var color: Color = .red
    
    var body: some View {
        Form {
            Section(header: CircularColorPicker(color: $color).padding()) {
                HStack {
                    Text("R")
                    Slider(value: $state.red, in: 0...255, step: 1)
                        .onChange(of: state.red) { oldValue, newValue in
                            color = Color(red: Double(newValue) / 255, green: Double(state.green) / 255, blue: Double(state.blue) / 255)
                            network.command(.set, data: state.data)
                        }
                }
                
                HStack {
                    Text("G")
                    Slider(value: $state.green, in: 0...255, step: 1)
                        .onChange(of: state.green) { oldValue, newValue in
                            color = Color(red: Double(state.red) / 255, green: Double(newValue) / 255, blue: Double(state.blue) / 255)
                            network.command(.set, data: state.data)
                        }
                }
                
                HStack {
                    Text("B")
                    Slider(value: $state.blue, in: 0...255, step: 1)
                        .onChange(of: state.blue) { oldValue, newValue in
                            color = Color(red: Double(state.red) / 255, green: Double(state.green) / 255, blue: Double(newValue) / 255)
                            network.command(.set, data: state.data)
                        }
                }
            }
            
            
            Section(header: Text("Brightness")) {
                Slider(value: $state.brightness, in: 0...255, step: 1)
                    .onChange(of: state.brightness) { oldValue, newValue in
                        network.command(.set, data: state.data)
                    }
            }
            
            Section {
                Picker("Mode", selection: $state.mode) {
                    ForEach(LampState.Mode.allCases, id: \.self) {
                        Text($0.name)
                    }
                }
                .onChange(of: state.mode) { oldValue, newValue in
                    network.command(.set, data: state.data)
                }
                
                Picker("Color Temperature", selection: $state.temperature) {
                    ForEach(ColorTemperature.allCases, id: \.self) {
                        Text($0.name)
                    }
                }
                .onChange(of: state.temperature) { oldValue, newValue in
                    network.command(.set, data: state.data)
                }
            }
        }
        .onAppear {
            network.search()
        }
        .onReceive(network.$state) { state in
            self.state = state
        }
        .onChange(of: color) { oldValue, newValue in
            let resolvedColor = newValue.resolve(in: environment)
            state.red = Double(resolvedColor.red) * 255
            state.green = Double(resolvedColor.green) * 255
            state.blue = Double(resolvedColor.blue) * 255
        }
    }
}
