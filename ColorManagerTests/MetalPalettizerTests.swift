//
//  MetalPalettizerTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import ColorManager

/// These tests run the real Metal kernel on the machine's GPU.
@Suite("Metal palettizer")
struct MetalPalettizerTests
{
    typealias Support = ImageTestSupport
    typealias Color = (r: Float, g: Float, b: Float)
    
    /// Group bytes into `(r, g, b)` triples.
    func Triples(_ Bytes: [UInt8]) -> [(UInt8, UInt8, UInt8)]
    {
        var Result: [(UInt8, UInt8, UInt8)] = []
        for Index in 0..<(Bytes.count / 3)
        {
            Result.append((Bytes[Index * 3], Bytes[Index * 3 + 1], Bytes[Index * 3 + 2]))
        }
        return Result
    }
    
    /// What the kernel should produce for an opaque pixel: the nearest palette color by the kernel's weighted distance.
    func Expected(_ Pixel: (UInt8, UInt8, UInt8), _ Palette: [Color]) -> (UInt8, UInt8, UInt8)
    {
        func Distance(_ C: Color) -> Float
        {
            let Dr = Float(Pixel.0) / 255 - C.r, Dg = Float(Pixel.1) / 255 - C.g, Db = Float(Pixel.2) / 255 - C.b
            return 2 * Dr * Dr + 4 * Dg * Dg + 3 * Db * Db
        }
        let Best = Palette.min { Distance($0) < Distance($1) }!
        func Byte(_ V: Float) -> UInt8 { UInt8((V * 255).rounded()) }
        return (Byte(Best.r), Byte(Best.g), Byte(Best.b))
    }
    
    @Test func MapsClearCasesToTheNearestColor() async throws
    {
        let Palettizer = try #require(MetalPalettizer())
        let Image = Support.MakeOpaqueImage(width: 3, height: 1, colors: [(200, 30, 30), (30, 30, 200), (128, 0, 128)])
        let Palette: [Color] = [(1, 0, 0), (0, 0, 1)]
        let Result = try await Palettizer.palettize(image: Image, palette: Palette)
        #expect(Result.width == 3 && Result.height == 1)
        let Pixels = Support.Pixels(of: Result)
        #expect(Array(Pixels[0..<4]) == [255, 0, 0, 255])
        #expect(Array(Pixels[4..<8]) == [0, 0, 255, 255])
        // Purple (128, 0, 128) is closer to blue than red under the kernel's weighting.
        #expect(Array(Pixels[8..<12]) == [0, 0, 255, 255])
    }
    
    @Test func MatchesACPUReferenceOnManyPixels() async throws
    {
        let Palettizer = try #require(MetalPalettizer())
        let Width = 64, Height = 48
        let Bytes = Support.PseudoRandomBytes(count: Width * Height * 3)
        let Colors = Triples(Bytes)
        let Image = Support.MakeOpaqueImage(width: Width, height: Height, colors: Colors)
        let Palette: [Color] =
        [
            Color(r: 0, g: 0, b: 0), Color(r: 1, g: 1, b: 1), Color(r: 1, g: 0, b: 0),
            Color(r: 0, g: 0.6, b: 0.2), Color(r: 0.1, g: 0.2, b: 0.9), Color(r: 0.9, g: 0.8, b: 0.1),
        ]
        
        let Pixels = Support.Pixels(of: try await Palettizer.palettize(image: Image, palette: Palette))
        var Mismatches = 0
        for Index in 0..<(Width * Height)
        {
            let Want = Expected(Colors[Index], Palette)
            let Got = (Pixels[Index * 4], Pixels[Index * 4 + 1], Pixels[Index * 4 + 2])
            // The GPU may round a palette value like 0.9 (229.5 in bytes) either way, so allow one step per channel.
            let Close = abs(Int(Got.0) - Int(Want.0)) <= 1 && abs(Int(Got.1) - Int(Want.1)) <= 1
                && abs(Int(Got.2) - Int(Want.2)) <= 1
            if !Close || Pixels[Index * 4 + 3] != 255
            {
                Mismatches += 1
            }
        }
        #expect(Mismatches == 0, "\(Mismatches) of \(Width * Height) pixels differ from the CPU reference")
    }
    
    @Test func OutputUsesOnlyPaletteColors() async throws
    {
        let Palettizer = try #require(MetalPalettizer())
        let Bytes = Support.PseudoRandomBytes(count: 32 * 32 * 3, seed: 99)
        let Colors = Triples(Bytes)
        let Image = Support.MakeOpaqueImage(width: 32, height: 32, colors: Colors)
        let Palette: [Color] = [Color(r: 1, g: 0, b: 0), Color(r: 0, g: 1, b: 0), Color(r: 0, g: 0, b: 1)]
        let Pixels = Support.Pixels(of: try await Palettizer.palettize(image: Image, palette: Palette))
        let Allowed: Set<[UInt8]> = [[255, 0, 0, 255], [0, 255, 0, 255], [0, 0, 255, 255]]
        for Index in 0..<(32 * 32)
        {
            #expect(Allowed.contains(Array(Pixels[Index * 4..<Index * 4 + 4])))
        }
    }
    
    @Test func SingleColorPaletteFillsTheImage() async throws
    {
        let Palettizer = try #require(MetalPalettizer())
        let Image = Support.MakeOpaqueImage(width: 2, height: 2, colors: [(1, 2, 3), (250, 250, 250), (0, 0, 0), (99, 5, 200)])
        let Pixels = Support.Pixels(of: try await Palettizer.palettize(image: Image, palette: [(0, 1, 0)]))
        for Index in 0..<4
        {
            #expect(Array(Pixels[Index * 4..<Index * 4 + 4]) == [0, 255, 0, 255])
        }
    }
    
    @Test func TransparencyIsPreserved() async throws
    {
        let Palettizer = try #require(MetalPalettizer())
        // Red at 50% alpha (premultiplied 128, 0, 0, 128), blue at 25% alpha (0, 0, 64, 64), and fully transparent.
        let Image = Support.MakeImage(width: 3, height: 1, pixels: [128, 0, 0, 128, 0, 0, 64, 64, 0, 0, 0, 0])
        let Palette: [Color] = [(1, 0, 0), (0, 0, 1)]
        let Pixels = Support.Pixels(of: try await Palettizer.palettize(image: Image, palette: Palette))
        // The color is chosen from the un-premultiplied value, so these stay red and blue, and the output is premultiplied.
        #expect(Pixels[3] == 128)
        #expect(abs(Int(Pixels[0]) - 128) <= 1 && Pixels[1] == 0 && Pixels[2] == 0)
        #expect(Pixels[7] == 64)
        #expect(Pixels[4] == 0 && Pixels[5] == 0 && abs(Int(Pixels[6]) - 64) <= 1)
        #expect(Array(Pixels[8..<12]) == [0, 0, 0, 0])
    }
    
    @Test func EmptyPaletteIsAnError() async throws
    {
        let Palettizer = try #require(MetalPalettizer())
        let Image = Support.MakeOpaqueImage(width: 1, height: 1, colors: [(1, 2, 3)])
        await #expect(throws: MetalPalettizer.PalettizeError.self)
        {
            _ = try await Palettizer.palettize(image: Image, palette: [])
        }
    }
    
    @Test func ImagesNotInSRGBAreConverted() async throws
    {
        let Palettizer = try #require(MetalPalettizer())
        // A pure sRGB-red pixel stored in Display P3 must still be matched as red.
        let P3 = CGColorSpace(name: CGColorSpace.displayP3)!
        var Bytes: [UInt8] = [0, 0, 0, 255]
        let Context = CGContext(data: &Bytes, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: P3,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        // Fill with sRGB red converted into the context's color space.
        Context.setFillColor(CGColor(colorSpace: Support.SRGB, components: [1, 0, 0, 1])!)
        Context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let Image = Context.makeImage()!
        let Palette: [Color] = [(1, 0, 0), (0, 1, 0)]
        let Pixels = Support.Pixels(of: try await Palettizer.palettize(image: Image, palette: Palette))
        #expect(Array(Pixels[0..<4]) == [255, 0, 0, 255])
    }
}
