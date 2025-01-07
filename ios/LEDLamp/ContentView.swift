//
//  ContentView.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 30.11.2024.
//

import SwiftUI

struct ContentView: View {
    private let network = NetworkService()
    
    @State private var state: LampState = .init(red: 0.0, green: 0.0, blue: 0.0, mode: .color)
    @State private var color: Color = .red
    
    var body: some View {
        Form {
            Section(
                header: HStack {
                    Spacer()
                    CircularColorPicker(color: $color, onDragEnded: {
                        network.command(.set, data: state.data)
                    })
                    .padding().frame(width: 350.0)
                    Spacer()
                }
            ) {
                HStack {
                    Text("R")
                    Slider(value: $state.red, in: 0...255, step: 1) { editing in
                        if !editing {
                            network.command(.set, data: state.data)
                        }
                    }
                    .valueChanged(state.red) { newValue in
                        color = Color(red: Double(newValue) / 255, green: Double(state.green) / 255, blue: Double(state.blue) / 255)
                    }
                }
                
                HStack {
                    Text("G")
                    Slider(value: $state.green, in: 0...255, step: 1) { editing in
                        if !editing {
                            network.command(.set, data: state.data)
                        }
                    }
                    .valueChanged(state.red) { newValue in
                        color = Color(red: Double(newValue) / 255, green: Double(state.green) / 255, blue: Double(state.blue) / 255)
                    }
                }
                
                HStack {
                    Text("B")
                    Slider(value: $state.blue, in: 0...255, step: 1) { editing in
                        if !editing {
                            network.command(.set, data: state.data)
                        }
                    }
                    .valueChanged(state.red) { newValue in
                        color = Color(red: Double(newValue) / 255, green: Double(state.green) / 255, blue: Double(state.blue) / 255)
                    }
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
