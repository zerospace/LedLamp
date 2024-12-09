//
//  ColorWheel.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 09.12.2024.
//

import SwiftUI

struct ColorWheel: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size / 2
            Circle()
                .fill(
                    AngularGradient(gradient: Gradient(colors: Array(0...255).map({ Color(hue: Double($0) / 255, saturation: 1, brightness: 1) })), center: .center)
                )
                .overlay {
                    Circle()
                        .fill(RadialGradient(gradient: Gradient(colors: [.white, .white.opacity(0.000001)]), center: .center, startRadius: 0, endRadius: radius))
                }
        }
    }
}

struct CircularColorPicker: View {
    @Binding var color: Color
    @State private var location: CGPoint = .zero
    @State private var radius: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let innerRadius = center.x
            
            ZStack {
                ColorWheel()
                    .frame(width: size, height: size)
                
                Circle()
                    .fill(color)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .position(location == .zero ? center : location)
                    .gesture(DragGesture().onChanged({ value in
                        location = constraintDrag(to: value.location, center: center, radius: innerRadius)
                        color = getColor(at: value.location, in: center, radius: innerRadius)
                    }))
            }
            .onAppear {
                location = center
                radius = innerRadius
            }
            .onChange(of: color) { oldValue, newValue in
                location = getLocation(from: newValue, in: center, radius: innerRadius)
                color = newValue
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func constraintDrag(to location: CGPoint, center: CGPoint, radius: CGFloat) -> CGPoint {
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx*dx + dy*dy)
        
        if distance > radius {
            let angle = atan2(dy, dx)
            let constrainedX = center.x + radius * cos(angle)
            let constrainedY = center.y + radius * sin(angle)
            return CGPoint(x: constrainedX, y: constrainedY)
        }
        return location
    }
    
    private func getColor(at location: CGPoint, in center: CGPoint, radius: CGFloat) -> Color {
        let dx = center.x - location.x
        let dy = center.y - location.y
        let distance = sqrt(dx*dx + dy*dy)
        let hue = (atan2(dy, dx) + .pi) / (2 * .pi)
        let saturation = min(distance / radius, 1.0)
        return Color(hue: hue, saturation: saturation, brightness: 1)
    }
    
    private func getLocation(from color: Color, in center: CGPoint, radius: CGFloat) -> CGPoint {
        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
        let angle = Double(hue) * 360.0
        let distance = Double(saturation) * radius
        let x = center.x + distance * cos(angle * .pi / 180.0)
        let y = center.y + distance * sin(angle * .pi / 180.0)
        return CGPoint(x: x, y: y)
    }
}
