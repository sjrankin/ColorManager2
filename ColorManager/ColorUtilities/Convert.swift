//
//  Convert.swift
//  ColorManager
//
//  Created by Stuart Rankin on 3/29/26.
//

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

class Convert
{
    // MARK: - Data to PlatformColor
    
    /// Convert passed color channel values to a `PlatformColor`.
    /// - Parameter R: The red channel in integer form. Valid range is `0` - `255`.
    /// - Parameter G: The green channel in integer form. Valid range is `0` - `255`.
    /// - Parameter G: The blue channel in integer form. Valid range is `0` - `255`.
    /// - Returns: Platform color based on the passed values.
    static func FromRGB(_ R: Int, _ G: Int, _ B: Int) -> PlatformColor
    {
        return FromRGB(R: Double(R) / 255.0, G: Double(G) / 255.0, B: Double(B) / 255.0)
    }
    
    static func FromRGB(R: Double, G: Double, B: Double) -> PlatformColor
    {
        #if os(macOS)
        return NSColor(red: R.ChannelClamped(),
                       green: G.ChannelClamped(),
                       blue: B.ChannelClamped(),
                       alpha: 1.0)
        #else
        return UIColor(red: R.ChannelClamped(),
                       green: G.ChannelClamped(),
                       blue: B.ChannelClamped(),
                       alpha: 1.0)
        #endif
    }
    
    /// Convert a hex string to a `PlatformColor`. See ``FromHexToChannels(_:)`` for accepted formats.
    /// - Returns: The color, or black if the string is not a valid hex color.
    static func FromHex(_ Hex: String) -> PlatformColor
    {
        let Channels = FromHexToChannels(Hex)
        return FromRGB(Channels.red, Channels.green, Channels.blue)
    }

    /// Parse a hex string into integer channels.
    ///
    /// Accepted formats (case-insensitive, surrounding whitespace ignored): `RRGGBB`, `0xRRGGBB`, `#RRGGBB`, and the
    /// same with a trailing alpha byte (`RRGGBBAA`), which is ignored.
    /// - Returns: The channels, or black if the string is not a valid hex color.
    static func FromHexToChannels(_ Hex: String) -> (red: Int, green: Int, blue: Int)
    {
        return ParseHexChannels(Hex) ?? (0, 0, 0)
    }
    
    /// Parse a hex string into integer channels. Accepts the same formats as ``FromHexToChannels(_:)``.
    /// - Returns: The channels, or `nil` if the string is not a valid hex color.
    static func ParseHexChannels(_ Hex: String) -> (red: Int, green: Int, blue: Int)?
    {
        guard let Parsed = ParseHex(Hex) else
        {
            return nil
        }
        return (Parsed.red, Parsed.green, Parsed.blue)
    }
    
    /// Parse a hex string into integer channels and alpha. This is the one hex parser for the whole app; everything that
    /// reads hex strings (including `Color(hexString:)`) goes through it.
    ///
    /// Accepted formats (case-insensitive, surrounding whitespace ignored): `RRGGBB`, `0xRRGGBB`, `#RRGGBB`, and the
    /// same with a trailing alpha byte (`RRGGBBAA`). Alpha is `255` when the string has none.
    /// - Returns: The channels and alpha (each `0` - `255`), or `nil` if the string is not a valid hex color.
    static func ParseHex(_ Hex: String) -> (red: Int, green: Int, blue: Int, alpha: Int)?
    {
        var Digits = Hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if Digits.hasPrefix("#")
        {
            Digits.removeFirst()
        }
        else if Digits.lowercased().hasPrefix("0x")
        {
            Digits.removeFirst(2)
        }
        // `Int(_:radix:)` accepts a leading `+` or `-`, so check for real hex digits first.
        guard Digits.count == 6 || Digits.count == 8,
              Digits.allSatisfy({ $0.isASCII && $0.isHexDigit }),
              let R = Int(Digits.prefix(2), radix: 16),
              let G = Int(Digits.dropFirst(2).prefix(2), radix: 16),
              let B = Int(Digits.dropFirst(4).prefix(2), radix: 16) else
        {
            return nil
        }
        var Alpha = 255
        if Digits.count == 8
        {
            guard let Parsed = Int(Digits.dropFirst(6).prefix(2), radix: 16) else
            {
                return nil
            }
            Alpha = Parsed
        }
        return (R, G, B, Alpha)
    }
    
    // MARK: - PlatformColor to Channels
    
    static func IntChannels(From color: PlatformColor) -> (red: Int, green: Int, blue: Int)
    {
        #if os(macOS)
        guard let cscolor = color.usingColorSpace(.sRGB) else
        {
            print("\(#function): Error convering NSColor to RGB.")
            return (red: 0, green: 0, blue: 0)
        }
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        cscolor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red: ColorSpaceMath.ToByte(red), green: ColorSpaceMath.ToByte(green), blue: ColorSpaceMath.ToByte(blue))
        #else
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        {
            return (red: ColorSpaceMath.ToByte(red), green: ColorSpaceMath.ToByte(green), blue: ColorSpaceMath.ToByte(blue))
        }
        print("\(#function): Error converting UIColor to RGB.")
        return (red: 0, green: 0, blue: 0)
        #endif
    }
    
    static func DoubleChannels(From color: PlatformColor) -> (red: Double, green: Double, blue: Double)
    {
#if os(macOS)
        guard let cscolor = color.usingColorSpace(.sRGB) else
        {
            print("\(#function): Error convering NSColor to RGB.")
            return (red: 0, green: 0, blue: 0)
        }
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        cscolor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red: red, green: green, blue: blue)
#else
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        {
            return  (red: red, green: green, blue: blue)
        }
        print("\(#function): Error converting UIColor to RGB.")
        return (red: 0.0, green: 0.0, blue: 0.0)
#endif
    }
    
    /// Given the passed `PlatformColor` return it's hex value as a string.
    /// - Parameter From: The `PlatformColor` whose hex value will be returned.
    /// - Parameter AddPrefix: If `true`, "`0x`" will prefix the string. If `false`, there will be no added prefix.
    /// - Returns: The hex values of the channels of the passed `PlatformColor`.
    /// - Note: Hex channel values use upper-case alphanumerics.
    static func HexChannels(From color: PlatformColor, AddPrefix: Bool = true) -> String
    {
        let Channels = Convert.IntChannels(From: color)
        let RedHex = Channels.red.hex
        let GreenHex = Channels.green.hex
        let BlueHex = Channels.blue.hex
        return "\(AddPrefix ? "0x" : "")\(RedHex)\(GreenHex)\(BlueHex)"
    }

    // MARK: - PlatformColor to other color spaces

    /// Hue (degrees, `0` - `360`), saturation (`0` - `100`), and brightness (`0` - `100`) of a color.
    static func HSBChannels(From color: PlatformColor) -> (h: Double, s: Double, b: Double)
    {
        let RGB = DoubleChannels(From: color)
        return ColorSpaceMath.RGBToHSB(R: RGB.red, G: RGB.green, B: RGB.blue)
    }

    /// Hue (degrees, `0` - `360`), saturation (`0` - `100`), and lightness (`0` - `100`) of a color.
    static func HSLChannels(From color: PlatformColor) -> (h: Double, s: Double, l: Double)
    {
        let RGB = DoubleChannels(From: color)
        return ColorSpaceMath.RGBToHSL(R: RGB.red, G: RGB.green, B: RGB.blue)
    }

    /// Cyan, magenta, yellow, and key (black) of a color, each `0` - `100`. This is the simple, profile-less conversion.
    static func CMYKChannels(From color: PlatformColor) -> (c: Double, m: Double, y: Double, k: Double)
    {
        let RGB = DoubleChannels(From: color)
        return ColorSpaceMath.RGBToCMYK(R: RGB.red, G: RGB.green, B: RGB.blue)
    }

    /// CIE XYZ (D65, `Y` of white is `1.0`) of a color.
    static func XYZChannels(From color: PlatformColor) -> (x: Double, y: Double, z: Double)
    {
        let RGB = DoubleChannels(From: color)
        return ColorSpaceMath.RGBToXYZ(R: RGB.red, G: RGB.green, B: RGB.blue)
    }

    /// CIE L*a*b* (D65) of a color.
    static func LabChannels(From color: PlatformColor) -> (l: Double, a: Double, b: Double)
    {
        let RGB = DoubleChannels(From: color)
        return ColorSpaceMath.RGBToLab(R: RGB.red, G: RGB.green, B: RGB.blue)
    }

    // MARK: - Other color spaces to PlatformColor

    /// Create a color from hue (degrees), saturation (`0` - `100`), and brightness (`0` - `100`).
    static func FromHSB(H: Double, S: Double, B: Double) -> PlatformColor
    {
        let RGB = ColorSpaceMath.HSBToRGB(H: H, S: S.Clamped(0, 100), B: B.Clamped(0, 100))
        return FromRGB(R: RGB.r, G: RGB.g, B: RGB.b)
    }

    /// Create a color from hue (degrees), saturation (`0` - `100`), and lightness (`0` - `100`).
    static func FromHSL(H: Double, S: Double, L: Double) -> PlatformColor
    {
        let RGB = ColorSpaceMath.HSLToRGB(H: H, S: S.Clamped(0, 100), L: L.Clamped(0, 100))
        return FromRGB(R: RGB.r, G: RGB.g, B: RGB.b)
    }

    /// Create a color from cyan, magenta, yellow, and key (black), each `0` - `100`.
    static func FromCMYK(C: Double, M: Double, Y: Double, K: Double) -> PlatformColor
    {
        let RGB = ColorSpaceMath.CMYKToRGB(C: C.Clamped(0, 100), M: M.Clamped(0, 100),
                                           Y: Y.Clamped(0, 100), K: K.Clamped(0, 100))
        return FromRGB(R: RGB.r, G: RGB.g, B: RGB.b)
    }

    /// Create a color from CIE XYZ (D65, `Y` of white is `1.0`). Out-of-gamut colors are clamped.
    static func FromXYZ(X: Double, Y: Double, Z: Double) -> PlatformColor
    {
        let RGB = ColorSpaceMath.XYZToRGB(X: X, Y: Y, Z: Z)
        return FromRGB(R: RGB.r, G: RGB.g, B: RGB.b)
    }

    /// Create a color from CIE L*a*b* (D65). Out-of-gamut colors are clamped.
    static func FromLab(L: Double, A: Double, B: Double) -> PlatformColor
    {
        let RGB = ColorSpaceMath.LabToRGB(L: L, A: A, B: B)
        return FromRGB(R: RGB.r, G: RGB.g, B: RGB.b)
    }
}

// MARK: - Color-Related Extensions

/// Color-related `Int` extensions.
extension Int
{
    /// Clamp the instance `Int` to a valid integer channel value (`0` through `255`).
    func ChannelClamped() -> Int
    {
        return self.Clamped(0, 255)
    }
    
    /// Clamp the instance `Int` to the passed minimum and maximum values.
    func Clamped(_ minValue: Int, _ maxValue: Int) -> Int
    {
        if minValue > maxValue
        {
            print("\(#function): minValue (\(minValue)) > maxValue (\(maxValue)).")
            return self
        }
        if self > maxValue
        {
            return maxValue
        }
        if self < minValue
        {
            return minValue
        }
        return self
    }
}

/// Color-related `Double` extensions.
extension Double
{
    /// Clamp the instance `Double` to a valid double channel value (`0.0` through `1.0`).
    func ChannelClamped() -> Double
    {
        return self.Clamped(0.0, 1.0)
    }
    
    /// Clamp the instance `Double` to the passed minimum and maximum values.
    /// - Parameter minValue: Lowest valid value.
    /// - Parameter maxValue: Greatest valid value.
    /// - Returns:
    func Clamped(_ minValue: Double, _ maxValue: Double) -> Double
    {
        if minValue > maxValue
        {
            print("\(#function): minValue (\(minValue)) > maxValue (\(maxValue)).")
            return self
        }
        if self > maxValue
        {
            return maxValue
        }
        if self < minValue
        {
            return minValue
        }
        return self
    }
}

/// Integer exentions.
extension BinaryInteger
{
    /// Return the instance value as a hex string. Use intended for color channel conversions so assumes (but does not
    /// require) the instance to be in the range `0` to `255`. Adds leading `0`s.
    var hex: String
    {
        String(format: "%02X", Int(self))
    }
}
