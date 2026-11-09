//
//  ImageTestSupport.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import CoreGraphics
import Foundation
@testable import ColorManager

/// Helpers for making and inspecting small images in tests. Pixels are premultiplied RGBA in sRGB, row by row.
enum ImageTestSupport
{
    static var SRGB: CGColorSpace
    {
        return CGColorSpace(name: CGColorSpace.sRGB)!
    }
    
    /// Make an image from premultiplied RGBA bytes.
    static func MakeImage(width: Int, height: Int, pixels: [UInt8]) -> CGImage
    {
        precondition(pixels.count == width * height * 4)
        let Provider = CGDataProvider(data: Data(pixels) as CFData)!
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: SRGB, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: Provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }
    
    /// Make an opaque image from `(r, g, b)` byte triples.
    static func MakeOpaqueImage(width: Int, height: Int, colors: [(UInt8, UInt8, UInt8)]) -> CGImage
    {
        return MakeImage(width: width, height: height, pixels: colors.flatMap { [$0.0, $0.1, $0.2, 255] })
    }
    
    /// Read an image's pixels as premultiplied RGBA bytes in sRGB.
    static func Pixels(of Image: CGImage) -> [UInt8]
    {
        var Bytes = [UInt8](repeating: 0, count: Image.width * Image.height * 4)
        Bytes.withUnsafeMutableBytes
        {
            Buffer in
            let Context = CGContext(data: Buffer.baseAddress, width: Image.width, height: Image.height,
                                    bitsPerComponent: 8, bytesPerRow: Image.width * 4, space: SRGB,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            Context.draw(Image, in: CGRect(x: 0, y: 0, width: Image.width, height: Image.height))
        }
        return Bytes
    }
    
    /// A temporary file URL that does not exist yet.
    static func TemporaryURL(_ Name: String) -> URL
    {
        return FileManager.default.temporaryDirectory.appending(path: "ColorManagerTests-\(UUID().uuidString)-\(Name)")
    }
    
    /// A simple deterministic sequence of bytes, so tests are repeatable.
    static func PseudoRandomBytes(count: Int, seed: UInt64 = 12345) -> [UInt8]
    {
        var State = seed
        return (0..<count).map
        {
            _ in
            State = State &* 6364136223846793005 &+ 1442695040888963407
            return UInt8(truncatingIfNeeded: State >> 33)
        }
    }
}
