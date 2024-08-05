//
//  Colors.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 10.05.23.
//

import Foundation
import SwiftUI
import UIKit


struct CustomColor {
    static let pinpoint_orange = Color("pinpoint_orange")
    static let cgPinpoint_orange = UIColor(pinpoint_orange).cgColor
    static let uiPinpoint_orange = UIColor(pinpoint_orange)
    
    static let pinpoint_background = Color("pinpoint_background")
    
    static let pinpoint_gray = Color("pinpoint_gray")
    static let cgPinpointGray = UIColor(pinpoint_gray).cgColor
    static let uiPinpointGray = UIColor(pinpoint_gray)
    
    static let pinpoint_backgroundC = CGColor(red: 244, green: 245, blue: 244, alpha: 255)
    static let ppOrange = Color(hex: "#ff8b00")
    static let ppMint = Color(hex: "#6c337f")
  
}


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
