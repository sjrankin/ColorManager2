//
//  ColorSpaceUtilities.swift
//  ColorManager
//
//  Created by Stuart Rankin on 4/13/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension ColorListIO
{
    // MARK: - Color Space Parsing Utilities
    
    /// Create a HexRecord from a hex string
    /// - Parameter hexString: Hex color value, `RRGGBB` or `RRGGBBAA`, with or without a `#` or `0x` prefix.
    /// - Returns: HexRecord (digits upper-cased, prefix removed) if valid, nil otherwise
    /// - Note: Validation uses `Convert.ParseHex`, the same parser used everywhere else.
    static func createHexRecord(from hexString: String) -> HexRecord?
    {
        guard Convert.ParseHex(hexString) != nil else
        {
            return nil
        }
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#")
        {
            hex.removeFirst()
        }
        else if hex.lowercased().hasPrefix("0x")
        {
            hex.removeFirst(2)
        }
        return HexRecord(HexValue: hex.uppercased())
    }
    
    // MARK: - Color Space Conversion Utilities
    
    /// Convert RGB to Hex
    static func rgbToHex(r: Int, g: Int, b: Int) -> String?
    {
        guard (0...255).contains(r) && (0...255).contains(g) && (0...255).contains(b) else
        {
            return nil
        }
        return String(format: "%02X%02X%02X", r, g, b)
    }
    
    /// Convert CMYK (`0` - `100` each) to RGB (`0` - `255` each).
    static func cmykToRGB(c: Double, m: Double, y: Double, k: Double) -> (r: Int, g: Int, b: Int)?
    {
        guard (0...100).contains(c) && (0...100).contains(m) &&
                (0...100).contains(y) && (0...100).contains(k) else
        {
            return nil
        }
        let RGB = ColorSpaceMath.CMYKToRGB(C: c, M: m, Y: y, K: k)
        return (ColorSpaceMath.ToByte(RGB.r), ColorSpaceMath.ToByte(RGB.g), ColorSpaceMath.ToByte(RGB.b))
    }
    
    /// Convert HSL (hue `0` - `360`, saturation and lightness `0` - `100`) to RGB (`0` - `255` each).
    static func hslToRGB(h: Double, s: Double, l: Double) -> (r: Int, g: Int, b: Int)?
    {
        guard (0...360).contains(h) && (0...100).contains(s) && (0...100).contains(l) else
        {
            return nil
        }
        let RGB = ColorSpaceMath.HSLToRGB(H: h, S: s, L: l)
        return (ColorSpaceMath.ToByte(RGB.r), ColorSpaceMath.ToByte(RGB.g), ColorSpaceMath.ToByte(RGB.b))
    }
    
    /// Convert HSB (HSV) (hue `0` - `360`, saturation and brightness `0` - `100`) to RGB (`0` - `255` each).
    static func hsbToRGB(h: Double, s: Double, b: Double) -> (r: Int, g: Int, b: Int)?
    {
        guard (0...360).contains(h) && (0...100).contains(s) && (0...100).contains(b) else
        {
            return nil
        }
        let RGB = ColorSpaceMath.HSBToRGB(H: h, S: s, B: b)
        return (ColorSpaceMath.ToByte(RGB.r), ColorSpaceMath.ToByte(RGB.g), ColorSpaceMath.ToByte(RGB.b))
    }
    
    /// Convert CIE L*a*b* (D65) to sRGB (`0` - `255` each). Out-of-gamut colors are clamped.
    static func labToRGB(l: Double, a: Double, b: Double) -> (r: Int, g: Int, b: Int)?
    {
        guard (0...100).contains(l) && (-128...127).contains(a) && (-128...127).contains(b) else
        {
            return nil
        }
        let RGB = ColorSpaceMath.LabToRGB(L: l, A: a, B: b)
        return (ColorSpaceMath.ToByte(RGB.r), ColorSpaceMath.ToByte(RGB.g), ColorSpaceMath.ToByte(RGB.b))
    }
    
    /// Create an RGBRecord from integer values
    static func createRGBRecord(r: Int, g: Int, b: Int) -> RGBRecord?
    {
        guard (0...255).contains(r) && (0...255).contains(g) && (0...255).contains(b) else
        {
            return nil
        }
        return RGBRecord(r: r, g: g, b: b)
    }
    
    /// Create an HSLRecord from double values
    static func createHSLRecord(h: Double, s: Double, l: Double) -> HSLRecord?
    {
        guard (0...360).contains(h) && (0...100).contains(s) && (0...100).contains(l) else
        {
            return nil
        }
        return HSLRecord(h: h, s: s, l: l)
    }
    
    /// Create an HSBRecord from double values
    static func createHSBRecord(h: Double, s: Double, b: Double) -> HSBRecord?
    {
        guard (0...360).contains(h) && (0...100).contains(s) && (0...100).contains(b) else
        {
            return nil
        }
        return HSBRecord(h: h, s: s, b: b)
    }
    
    /// Create a CMYKRecord from double values (0-100)
    static func createCMYKRecord(c: Double, m: Double, y: Double, k: Double) -> CMYKRecord?
    {
        guard (0...100).contains(c) && (0...100).contains(m) &&
                (0...100).contains(y) && (0...100).contains(k) else
        {
            return nil
        }
        return CMYKRecord(c: c, y: y, m: m, k: k)
    }
    
    /// Create a LABRecord from double values
    static func createLABRecord(l: Double, a: Double, b: Double) -> LABRecord?
    {
        guard (0...100).contains(l) && (-128...127).contains(a) && (-128...127).contains(b) else
        {
            return nil
        }
        return LABRecord(l: l, a: a, b: b)
    }
}
