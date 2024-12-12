//
//  ContentView.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 30.11.2024.
//

import SwiftUI

struct ContentView: View {
    private let network = NetworkService()
    
    @State private var state: LampState = .init(red: 0.0, green: 0.0, blue: 0.0, brightness: 0.0, mode: .color, temperature: .tungsten100W)
    @State private var color: Color = .red
    
    var body: some View {
        GeometryReader { proxy in
            Form {
                Section(
                    header: HStack {
                        Spacer()
                        CircularColorPicker(color: $color).padding().frame(width: max(proxy.size.width / 2.0, 274.0))
                        Spacer()
                    }
                ) {
                    HStack {
                        Text("R")
                        Slider(value: $state.red, in: 0...255, step: 1)
                            .valueChanged(state.red) { newValue in
                                color = Color(red: Double(newValue) / 255, green: Double(state.green) / 255, blue: Double(state.blue) / 255)
                                network.command(.set, data: state.data)
                            }
                    }
                    
                    HStack {
                        Text("G")
                        Slider(value: $state.green, in: 0...255, step: 1)
                            .valueChanged(state.green) { newValue in
                                color = Color(red: Double(state.red) / 255, green: Double(newValue) / 255, blue: Double(state.blue) / 255)
                                network.command(.set, data: state.data)
                            }
                    }
                    
                    HStack {
                        Text("B")
                        Slider(value: $state.blue, in: 0...255, step: 1)
                            .valueChanged(state.blue) { newValue in
                                color = Color(red: Double(state.red) / 255, green: Double(state.green) / 255, blue: Double(newValue) / 255)
                                network.command(.set, data: state.data)
                            }
                    }
                }
                
                
                Section(header: Text("Brightness")) {
                    Slider(value: $state.brightness, in: 0...255, step: 1)
                        .valueChanged(state.brightness) { _ in
                            network.command(.set, data: state.data)
                        }
                }
                
                Section {
                    Picker("Mode", selection: $state.mode) {
                        ForEach(LampState.Mode.allCases, id: \.self) {
                            Text($0.name)
                        }
                    }
                    .valueChanged(state.mode) { _ in
                        network.command(.set, data: state.data)
                    }
                    
                    Picker("Color Temperature", selection: $state.temperature) {
                        ForEach(ColorTemperature.allCases, id: \.self) {
                            Text($0.name)
                        }
                    }
                    .valueChanged(state.temperature) { _ in
                        network.command(.set, data: state.data)
                    }
                }
                .pickerStyle(.menu)
            }
            .onAppear {
                network.search()
            }
            .onReceive(network.$state) { state in
                self.state = state
            }
            .valueChanged( color) { newValue in
                var red: CGFloat = 0.0
                var green: CGFloat = 0.0
                var blue: CGFloat = 0.0
                var alpha: CGFloat = 0.0
                UIColor(newValue).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                state.red = Double(red) * 255
                state.green = Double(green) * 255
                state.blue = Double(blue) * 255
            }
        }
    }
}
