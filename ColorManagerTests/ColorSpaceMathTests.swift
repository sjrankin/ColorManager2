//
//  ColorSpaceMathTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Testing
@testable import ColorManager

@Suite("Color space math")
struct ColorSpaceMathTests
{
    typealias Math = ColorSpaceMath
    
    // MARK: Known values
    
    @Test func RedInLab()
    {
        let Lab = Math.RGBToLab(R: 1, G: 0, B: 0)
        #expect(abs(Lab.l - 53.2408) < 0.01)
        #expect(abs(Lab.a - 80.0925) < 0.02)
        #expect(abs(Lab.b - 67.2032) < 0.02)
    }
    
    @Test func WhiteIsLabWhite()
    {
        let Lab = Math.RGBToLab(R: 1, G: 1, B: 1)
        #expect(abs(Lab.l - 100) < 1e-6)
        #expect(abs(Lab.a) < 1e-6)
        #expect(abs(Lab.b) < 1e-6)
    }
    
    @Test func RedInXYZ()
    {
        let XYZ = Math.RGBToXYZ(R: 1, G: 0, B: 0)
        #expect(abs(XYZ.x - 0.4124) < 1e-3)
        #expect(abs(XYZ.y - 0.2126) < 1e-3)
        #expect(abs(XYZ.z - 0.0193) < 1e-3)
    }
    
    @Test func OrangeInHSL()
    {
        let HSL = Math.RGBToHSL(R: 1, G: 128.0 / 255.0, B: 0)
        #expect(abs(HSL.h - 30.1176) < 0.01)
        #expect(abs(HSL.s - 100) < 1e-9)
        #expect(abs(HSL.l - 50) < 1e-9)
    }
    
    @Test func SlateInHSB()
    {
        let HSB = Math.RGBToHSB(R: 0.2, G: 0.4, B: 0.6)
        #expect(abs(HSB.h - 210) < 1e-9)
        #expect(abs(HSB.s - 66.6667) < 1e-3)
        #expect(abs(HSB.b - 60) < 1e-9)
    }
    
    @Test func CMYKOfPrimaries()
    {
        let Black = Math.RGBToCMYK(R: 0, G: 0, B: 0)
        #expect(Black.c == 0 && Black.m == 0 && Black.y == 0 && Black.k == 100)
        let Red = Math.RGBToCMYK(R: 1, G: 0, B: 0)
        #expect(abs(Red.c) < 1e-9)
        #expect(abs(Red.m - 100) < 1e-9)
        #expect(abs(Red.y - 100) < 1e-9)
        #expect(abs(Red.k) < 1e-9)
    }
    
    // MARK: Hue handling
    
    @Test func HueWrapsAround()
    {
        let At0 = Math.HSBToRGB(H: 0, S: 100, B: 100)
        let At360 = Math.HSBToRGB(H: 360, S: 100, B: 100)
        let AtMinus360 = Math.HSBToRGB(H: -360, S: 100, B: 100)
        #expect(At0 == At360)
        #expect(At0 == AtMinus360)
        #expect(Math.HSBToRGB(H: -120, S: 100, B: 100) == Math.HSBToRGB(H: 240, S: 100, B: 100))
    }
    
    @Test func GrayHasNoHueOrSaturation()
    {
        let HSB = Math.RGBToHSB(R: 0.5, G: 0.5, B: 0.5)
        #expect(HSB.h == 0 && HSB.s == 0)
        let HSL = Math.RGBToHSL(R: 0.5, G: 0.5, B: 0.5)
        #expect(HSL.h == 0 && HSL.s == 0)
    }
    
    // MARK: Gamma and bytes
    
    @Test func GammaRoundTrips()
    {
        for Step in 0...100
        {
            let Value = Double(Step) / 100.0
            #expect(abs(Math.Encode(Math.Linearize(Value)) - Value) < 1e-12)
        }
    }
    
    @Test func BytesRoundAndClamp()
    {
        #expect(Math.ToByte(0.5) == 128)
        #expect(Math.ToByte(-1) == 0)
        #expect(Math.ToByte(2) == 255)
        #expect(Math.FromByte(255) == 1.0)
        #expect(Math.FromByte(-5) == 0.0)
        #expect(Math.FromByte(300) == 1.0)
        // Every byte survives a trip through a Double.
        for Value in 0...255
        {
            #expect(Math.ToByte(Math.FromByte(Value)) == Value)
        }
    }
    
    // MARK: Round trips
    
    /// Colors sampled across the 8-bit cube, including the extremes.
    static let Samples: [Int] = Array(stride(from: 0, through: 255, by: 15)) + [1, 2, 254, 255]
    
    /// Converting to a space and back must give the same 8-bit color. (The old conversions truncated instead of
    /// rounding and failed this for about half of all colors.)
    @Test func RoundTripsReturnTheSameBytes()
    {
        var Failures: [String] = []
        for R in Self.Samples
        {
            for G in Self.Samples
            {
                for B in Self.Samples
                {
                    let Red = Math.FromByte(R), Green = Math.FromByte(G), Blue = Math.FromByte(B)
                    func Check(_ Result: (r: Double, g: Double, b: Double), _ Space: String)
                    {
                        if (Math.ToByte(Result.r), Math.ToByte(Result.g), Math.ToByte(Result.b)) != (R, G, B)
                        {
                            Failures.append("\(Space) \(R),\(G),\(B)")
                        }
                    }
                    let HSB = Math.RGBToHSB(R: Red, G: Green, B: Blue)
                    Check(Math.HSBToRGB(H: HSB.h, S: HSB.s, B: HSB.b), "HSB")
                    let HSL = Math.RGBToHSL(R: Red, G: Green, B: Blue)
                    Check(Math.HSLToRGB(H: HSL.h, S: HSL.s, L: HSL.l), "HSL")
                    let CMYK = Math.RGBToCMYK(R: Red, G: Green, B: Blue)
                    Check(Math.CMYKToRGB(C: CMYK.c, M: CMYK.m, Y: CMYK.y, K: CMYK.k), "CMYK")
                    let XYZ = Math.RGBToXYZ(R: Red, G: Green, B: Blue)
                    Check(Math.XYZToRGB(X: XYZ.x, Y: XYZ.y, Z: XYZ.z), "XYZ")
                    let Lab = Math.RGBToLab(R: Red, G: Green, B: Blue)
                    Check(Math.LabToRGB(L: Lab.l, A: Lab.a, B: Lab.b), "Lab")
                }
            }
        }
        #expect(Failures.isEmpty, "Round trip failures: \(Failures.prefix(10))")
    }
    
    @Test func OutOfGamutLabIsClamped()
    {
        let RGB = Math.LabToRGB(L: 50, A: 127, B: -127)
        for Channel in [RGB.r, RGB.g, RGB.b]
        {
            #expect(Channel >= 0 && Channel <= 1)
        }
    }
}
