//
//  ConvertTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Testing
@testable import ColorManager

@Suite("Convert and ColorListIO conversions")
struct ConvertTests
{
    // MARK: PlatformColor <-> channels
    
    /// Reading channels back from a color built from them must not drift (it used to truncate, so 51 could read as 50).
    @Test func ChannelsSurviveAPlatformColorRoundTrip()
    {
        var Failures: [Int] = []
        for Value in 0...255
        {
            let Color = Convert.FromRGB(Value, 255 - Value, Value)
            let Channels = Convert.IntChannels(From: Color)
            if Channels.red != Value || Channels.green != 255 - Value || Channels.blue != Value
            {
                Failures.append(Value)
            }
        }
        #expect(Failures.isEmpty, "Channel drift at values: \(Failures.prefix(20))")
    }
    
    @Test func OutOfRangeChannelsAreClamped()
    {
        let Channels = Convert.IntChannels(From: Convert.FromRGB(300, -5, 128))
        #expect(Channels.red == 255)
        #expect(Channels.green == 0)
    }
    
    @Test func ReplaceChangesOnlyOneChannel()
    {
        let Start = Convert.FromRGB(10, 20, 30)
        let Changed = Start.Replace(Channel: .Green, With: 200)
        let Channels = Convert.IntChannels(From: Changed)
        #expect(Channels.red == 10 && Channels.green == 200 && Channels.blue == 30)
        // Text that isn't an integer leaves the color alone.
        let Same = Convert.IntChannels(From: Start.Replace(Channel: .Red, With: "abc"))
        #expect(Same.red == 10)
        // Values are clamped.
        let Clamped = Convert.IntChannels(From: Start.Replace(Channel: .Blue, With: "999"))
        #expect(Clamped.blue == 255)
    }
    
    @Test func PlatformColorSpaceConversionsRoundTrip()
    {
        let Start = Convert.FromRGB(200, 100, 50)
        let HSB = Convert.HSBChannels(From: Start)
        let FromHSB = Convert.IntChannels(From: Convert.FromHSB(H: HSB.h, S: HSB.s, B: HSB.b))
        #expect(FromHSB.red == 200 && FromHSB.green == 100 && FromHSB.blue == 50)
        
        let HSL = Convert.HSLChannels(From: Start)
        let FromHSL = Convert.IntChannels(From: Convert.FromHSL(H: HSL.h, S: HSL.s, L: HSL.l))
        #expect(FromHSL.red == 200 && FromHSL.green == 100 && FromHSL.blue == 50)
        
        let CMYK = Convert.CMYKChannels(From: Start)
        let FromCMYK = Convert.IntChannels(From: Convert.FromCMYK(C: CMYK.c, M: CMYK.m, Y: CMYK.y, K: CMYK.k))
        #expect(FromCMYK.red == 200 && FromCMYK.green == 100 && FromCMYK.blue == 50)
        
        let XYZ = Convert.XYZChannels(From: Start)
        let FromXYZ = Convert.IntChannels(From: Convert.FromXYZ(X: XYZ.x, Y: XYZ.y, Z: XYZ.z))
        #expect(FromXYZ.red == 200 && FromXYZ.green == 100 && FromXYZ.blue == 50)
        
        let Lab = Convert.LabChannels(From: Start)
        let FromLab = Convert.IntChannels(From: Convert.FromLab(L: Lab.l, A: Lab.a, B: Lab.b))
        #expect(FromLab.red == 200 && FromLab.green == 100 && FromLab.blue == 50)
    }
    
    // MARK: ColorListIO conversions (color list import)
    
    @Test func CMYKToRGB()
    {
        #expect(ColorListIO.cmykToRGB(c: 0, m: 0, y: 0, k: 0)! == (255, 255, 255))
        #expect(ColorListIO.cmykToRGB(c: 0, m: 0, y: 0, k: 100)! == (0, 0, 0))
        #expect(ColorListIO.cmykToRGB(c: 0, m: 100, y: 100, k: 0)! == (255, 0, 0))
        #expect(ColorListIO.cmykToRGB(c: 0, m: 0, y: 0, k: 50)! == (128, 128, 128))
    }
    
    @Test func HSBToRGB()
    {
        #expect(ColorListIO.hsbToRGB(h: 0, s: 100, b: 100)! == (255, 0, 0))
        #expect(ColorListIO.hsbToRGB(h: 120, s: 100, b: 100)! == (0, 255, 0))
        #expect(ColorListIO.hsbToRGB(h: 240, s: 100, b: 100)! == (0, 0, 255))
        #expect(ColorListIO.hsbToRGB(h: 360, s: 100, b: 100)! == (255, 0, 0))
        #expect(ColorListIO.hsbToRGB(h: 0, s: 0, b: 20)! == (51, 51, 51))
    }
    
    @Test func HSLToRGB()
    {
        #expect(ColorListIO.hslToRGB(h: 120, s: 100, l: 50)! == (0, 255, 0))
        #expect(ColorListIO.hslToRGB(h: 0, s: 0, l: 100)! == (255, 255, 255))
        #expect(ColorListIO.hslToRGB(h: 0, s: 0, l: 0)! == (0, 0, 0))
        #expect(ColorListIO.hslToRGB(h: 30, s: 100, l: 50)! == (255, 128, 0))
    }
    
    @Test func LabToRGB()
    {
        #expect(ColorListIO.labToRGB(l: 100, a: 0, b: 0)! == (255, 255, 255))
        #expect(ColorListIO.labToRGB(l: 0, a: 0, b: 0)! == (0, 0, 0))
        let Red = ColorListIO.labToRGB(l: 53.2408, a: 80.0925, b: 67.2032)!
        #expect(Red.r == 255 && Red.g == 0 && Red.b == 0)
    }
    
    @Test func ConversionsRejectOutOfRangeInput()
    {
        #expect(ColorListIO.cmykToRGB(c: 101, m: 0, y: 0, k: 0) == nil)
        #expect(ColorListIO.hsbToRGB(h: 361, s: 0, b: 0) == nil)
        #expect(ColorListIO.hslToRGB(h: 0, s: -1, l: 0) == nil)
        #expect(ColorListIO.labToRGB(l: 101, a: 0, b: 0) == nil)
        #expect(ColorListIO.rgbToHex(r: 256, g: 0, b: 0) == nil)
    }
    
    @Test func RGBToHex()
    {
        #expect(ColorListIO.rgbToHex(r: 255, g: 128, b: 0) == "FF8000")
        #expect(ColorListIO.rgbToHex(r: 0, g: 0, b: 0) == "000000")
        #expect(ColorListIO.rgbToHex(r: 1, g: 2, b: 3) == "010203")
    }
}
