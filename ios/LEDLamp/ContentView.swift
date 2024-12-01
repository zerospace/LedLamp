//
//  ContentView.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 30.11.2024.
//

import SwiftUI

struct ContentView: View {
    private let network = NetworkService()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Send") {
                network.command(.info, data: Data("test message".utf8))
            }
        }
        .padding()
        .onAppear {
            network.search()
        }
    }
}
