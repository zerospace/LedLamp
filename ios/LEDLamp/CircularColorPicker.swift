//
//  ColorWheel.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 09.12.2024.
//

import SwiftUI

struct ColorWheel: View {
    private func mask(rect: CGRect) -> Path {
        var shape = Circle().path(in: rect)
        shape.addPath(Circle().path(in: rect.insetBy(dx: 30, dy: 30)))
        return shape
    }
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: size/2, y: size/2)
            let radius = center.x
            
            Canvas { context, _ in
                for angle in stride(from: 0.0, to: 360.0, by: 1) {
                    let color = Color(hue: angle / 360.0, saturation: 1.0, brightness: 1.0)
                    let path = Path { path in
                        path.move(to: center)
                        path.addArc(center: center, radius: radius, startAngle: .degrees(Double(angle)), endAngle: .degrees(Double(angle + 1.5)), clockwise: false)
                        path.closeSubpath()
                    }
                    
                    context.fill(path, with: .color(color))
                }
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .mask {
            GeometryReader { proxy in
                mask(rect: CGRect(origin: .zero, size: proxy.size))
                    .fill(style: FillStyle(eoFill: true))
            }
        }
    }
}

struct CircularColorPicker: View {
    @Binding var color: Color
    var onDragEnded: () -> Void
    @State private var location: CGPoint = .zero
    
    @State private var hue: CGFloat = 0.0
    @State private var saturation: CGFloat = 0.0
    @State private var brightness: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let innerRadius = center.x
            
            ZStack {
                ColorWheel()
                    .overlay {
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .position(x: center.x + (innerRadius - 15.0) * cos(hue * 2 * .pi), y: center.y + (innerRadius - 15.0) * sin(hue * 2 * .pi))
                            .gesture(DragGesture().onChanged({ value in
                                let dx = value.location.x - center.x
                                let dy = value.location.y - center.y
                                let angle = atan2(dy, dx)
                                hue = (angle < 0 ? angle + 2 * .pi : angle) / (2 * .pi)
                                color = Color(hue: hue, saturation: saturation, brightness: brightness)
                            }).onEnded({ _ in
                                onDragEnded()
                            }))
                    }
                
                LinearGradient(
                    gradient: Gradient(colors: [Color(hue: hue, saturation: 0.0, brightness: 1.0), Color(hue: hue, saturation: 1.0, brightness: 1.0)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: size * 0.5, height: size * 0.5)
                .overlay {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom)
                }
                .overlay {
                    GeometryReader { proxy in
                        Circle()
                            .stroke(Color.gray, lineWidth: 2.0)
                            .frame(width: 20.0, height: 20.0)
                            .position(x: proxy.size.width * saturation, y: proxy.size.height * (1 - brightness))
                            .gesture(DragGesture().onChanged({ value in
                                let x = max(0, min(value.location.x, proxy.size.width))
                                let y = max(0, min(value.location.y, proxy.size.height))
                                saturation = x / proxy.size.width
                                brightness = 1 - (y / proxy.size.height)
                                color = Color(hue: hue, saturation: saturation, brightness: brightness)
                            }).onEnded({ _ in
                                onDragEnded()
                            }))
                    }
                }
                
            }
            .onAppear {
                UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
            }
            .valueChanged(color) { newValue in
                UIColor(newValue).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
