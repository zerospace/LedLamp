//
//  View+ValueChanged.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 12.12.2024.
//

import SwiftUI

extension View {
    @ViewBuilder func valueChanged<T: Equatable>(_ value: T, onChange: @escaping (T) -> Void) -> some View {
        if #available(iOS 17, *) {
            self.onChange(of: value) { _, new in
                onChange(new)
            }
        }
        else {
            self.onChange(of: value, perform: onChange)
        }
    }
}
