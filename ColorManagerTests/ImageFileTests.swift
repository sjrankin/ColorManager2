//
//  ImageFileTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation
import Testing
@testable import ColorManager

@Suite("Image files")
struct ImageFileTests
{
    typealias Support = ImageTestSupport
    
    @Test func PNGRoundTripKeepsEveryPixel() throws
    {
        let Pixels = Support.PseudoRandomBytes(count: 5 * 3 * 4).enumerated().map { $0.offset % 4 == 3 ? UInt8(255) : $0.element }
        let Image = Support.MakeImage(width: 5, height: 3, pixels: Pixels)
        let Data = try ImageFile.PNGData(from: Image)
        #expect(Data.starts(with: [0x89, 0x50, 0x4E, 0x47]), "PNG signature")
        
        let URL = Support.TemporaryURL("Round.png")
        defer { try? FileManager.default.removeItem(at: URL) }
        try Data.write(to: URL)
        let Loaded = try ImageFile.Load(from: URL)
        #expect(Loaded.width == 5 && Loaded.height == 3)
        #expect(Support.Pixels(of: Loaded) == Pixels)
    }
    
    @Test func TransparencySurvivesPNG() throws
    {
        // Premultiplied (64, 0, 0) at alpha 128, and a fully transparent pixel.
        let Image = Support.MakeImage(width: 2, height: 1, pixels: [64, 0, 0, 128, 0, 0, 0, 0])
        let URL = Support.TemporaryURL("Alpha.png")
        defer { try? FileManager.default.removeItem(at: URL) }
        try ImageFile.PNGData(from: Image).write(to: URL)
        let Pixels = Support.Pixels(of: try ImageFile.Load(from: URL))
        #expect(Pixels[3] == 128)
        #expect(abs(Int(Pixels[0]) - 64) <= 1)
        #expect(Pixels[7] == 0)
    }
    
    @Test func NonImagesAreRejected() throws
    {
        let URL = Support.TemporaryURL("NotAnImage.png")
        defer { try? FileManager.default.removeItem(at: URL) }
        try "this is not an image".write(to: URL, atomically: true, encoding: .utf8)
        #expect(throws: ImageFile.ImageFileError.self) { try ImageFile.Load(from: URL) }
    }
    
    @Test func MissingFilesAreRejected()
    {
        let URL = Support.TemporaryURL("Missing.png")
        #expect(throws: ImageFile.ImageFileError.self) { try ImageFile.Load(from: URL) }
    }
    
    @Test func LargeImagesAreScaledDown() throws
    {
        let Image = Support.MakeOpaqueImage(width: 40, height: 20, colors: Array(repeating: (10, 20, 30), count: 800))
        let URL = Support.TemporaryURL("Big.png")
        defer { try? FileManager.default.removeItem(at: URL) }
        try ImageFile.PNGData(from: Image).write(to: URL)
        let Loaded = try ImageFile.Load(from: URL, maxDimension: 10)
        #expect(max(Loaded.width, Loaded.height) == 10)
        #expect(Loaded.width == 10 && Loaded.height == 5, "aspect ratio is kept")
        // Images that already fit are not changed in size.
        let Same = try ImageFile.Load(from: URL, maxDimension: 100)
        #expect(Same.width == 40 && Same.height == 20)
    }
}
