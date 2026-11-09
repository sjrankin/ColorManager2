//
//  ImagePalettizerModelTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation
import Testing
@testable import ColorManager

@Suite("Image palettizer model")
struct ImagePalettizerModelTests
{
    typealias Support = ImageTestSupport
    
    /// Write a small solid-color PNG and return its URL.
    func MakeFile(_ Name: String, color Color: (UInt8, UInt8, UInt8) = (200, 30, 30)) throws -> URL
    {
        let Image = Support.MakeOpaqueImage(width: 4, height: 2, colors: Array(repeating: Color, count: 8))
        let URL = Support.TemporaryURL(Name)
        try ImageFile.PNGData(from: Image).write(to: URL)
        return URL
    }
    
    @Test func StartsEmpty()
    {
        let Model = ImagePalettizerModel()
        #expect(Model.SourceImage == nil && Model.ResultImage == nil)
        #expect(!Model.IsBusy)
        #expect(Model.CanPalettize(colorCount: 3) == false)
        #expect(Model.ResultPNGData() == nil)
        #expect(Model.SuggestedResultName == "Palettized")
    }
    
    @Test func LoadingAnImageSetsItAndTheName() throws
    {
        let URL = try MakeFile("Photo.png")
        defer { try? FileManager.default.removeItem(at: URL) }
        let Model = ImagePalettizerModel()
        Model.LoadImage(from: URL)
        #expect(Model.SourceImage?.width == 4 && Model.SourceImage?.height == 2)
        #expect(Model.SourceName == URL.lastPathComponent)
        #expect(Model.ErrorMessage == nil)
        #expect(Model.CanPalettize(colorCount: 1))
        #expect(Model.CanPalettize(colorCount: 0) == false)
        #expect(Model.SuggestedResultName.hasSuffix(" palettized"))
        #expect(!Model.SuggestedResultName.contains(".png"))
    }
    
    @Test func FailingToLoadKeepsTheCurrentImageAndReportsAnError() throws
    {
        let Good = try MakeFile("Good.png")
        defer { try? FileManager.default.removeItem(at: Good) }
        let Model = ImagePalettizerModel()
        Model.LoadImage(from: Good)
        Model.LoadImage(from: Support.TemporaryURL("Missing.png"))
        #expect(Model.ErrorMessage != nil)
        #expect(Model.SourceImage != nil)
        #expect(Model.SourceName == Good.lastPathComponent)
    }
    
    @Test func PalettizingMakesAResult() async throws
    {
        let URL = try MakeFile("Red.png", color: (200, 30, 30))
        defer { try? FileManager.default.removeItem(at: URL) }
        let Model = ImagePalettizerModel()
        Model.LoadImage(from: URL)
        let IDs: Set<UUID> = [UUID(), UUID()]
        await Model.Palettize(colors: [(1, 0, 0), (0, 0, 1)], ids: IDs)
        try #require(Model.ErrorMessage == nil)
        let Result = try #require(Model.ResultImage)
        #expect(Result.width == 4 && Result.height == 2)
        #expect(Array(Support.Pixels(of: Result)[0..<4]) == [255, 0, 0, 255])
        #expect(Model.ShowOriginal == false)
        #expect(!Model.IsBusy)
        #expect(Model.ResultIsCurrent(for: IDs))
        #expect(!Model.ResultIsCurrent(for: [UUID()]), "a different palette makes the result out of date")
        #expect(!Model.ResultIsCurrent(for: []))
    }
    
    @Test func PalettizingWithoutColorsExplainsWhy() async throws
    {
        let URL = try MakeFile("Empty.png")
        defer { try? FileManager.default.removeItem(at: URL) }
        let Model = ImagePalettizerModel()
        Model.LoadImage(from: URL)
        await Model.Palettize(colors: [], ids: [])
        #expect(Model.ErrorMessage != nil)
        #expect(Model.ResultImage == nil)
    }
    
    @Test func PalettizingWithoutAnImageDoesNothing() async
    {
        let Model = ImagePalettizerModel()
        await Model.Palettize(colors: [(1, 0, 0)], ids: [UUID()])
        #expect(Model.ResultImage == nil)
        #expect(Model.ErrorMessage == nil)
    }
    
    @Test func OpeningANewImageDiscardsTheResult() async throws
    {
        let First = try MakeFile("First.png")
        let Second = try MakeFile("Second.png", color: (0, 0, 255))
        defer { try? FileManager.default.removeItem(at: First); try? FileManager.default.removeItem(at: Second) }
        let Model = ImagePalettizerModel()
        Model.LoadImage(from: First)
        await Model.Palettize(colors: [(1, 0, 0)], ids: [UUID()])
        #expect(Model.ResultImage != nil)
        Model.LoadImage(from: Second)
        #expect(Model.ResultImage == nil)
        #expect(Model.ResultPNGData() == nil)
        #expect(Model.SourceName == Second.lastPathComponent)
    }
    
    @Test func ResettingGoesBackToTheOriginal() async throws
    {
        let URL = try MakeFile("Reset.png", color: (200, 30, 30))
        defer { try? FileManager.default.removeItem(at: URL) }
        let Model = ImagePalettizerModel()
        Model.LoadImage(from: URL)
        let Original = try #require(Model.SourceImage)
        await Model.Palettize(colors: [(0, 0, 1)], ids: [UUID()])
        #expect(Model.ResultImage != nil)
        Model.ShowOriginal = true
        
        Model.ResetToOriginal()
        #expect(Model.ResultImage == nil)
        #expect(Model.ResultPNGData() == nil, "nothing left to save")
        #expect(Model.ShowOriginal == false)
        #expect(!Model.ResultIsCurrent(for: []))
        // The opened image is untouched, and the file name is kept.
        #expect(Model.SourceImage === Original)
        #expect(Model.SourceName == URL.lastPathComponent)
        #expect(Support.Pixels(of: try #require(Model.SourceImage))[0..<3] == [200, 30, 30])
        
        // Palettizing again starts from the original, not from the earlier result.
        await Model.Palettize(colors: [(1, 0, 0)], ids: [UUID()])
        #expect(Array(Support.Pixels(of: try #require(Model.ResultImage))[0..<4]) == [255, 0, 0, 255])
    }
    
    @Test func ResettingWithNothingToResetIsHarmless()
    {
        let Model = ImagePalettizerModel()
        Model.ResetToOriginal()
        #expect(Model.ResultImage == nil && Model.SourceImage == nil)
    }
    
    @Test func TheResultCanBeSavedAsPNG() async throws
    {
        let URL = try MakeFile("Save.png", color: (30, 200, 30))
        defer { try? FileManager.default.removeItem(at: URL) }
        let Model = ImagePalettizerModel()
        Model.LoadImage(from: URL)
        await Model.Palettize(colors: [(0, 1, 0), (1, 0, 0)], ids: [UUID()])
        let Data = try #require(Model.ResultPNGData())
        let Saved = Support.TemporaryURL("Saved.png")
        defer { try? FileManager.default.removeItem(at: Saved) }
        try Data.write(to: Saved)
        let Loaded = try ImageFile.Load(from: Saved)
        #expect(Array(Support.Pixels(of: Loaded)[0..<4]) == [0, 255, 0, 255])
    }
    
    @Test func EndToEndWithMarkedColors() async throws
    {
        // Mark colors the way the main window does, then palettize with them.
        let Selection = PaletteSelection()
        Selection.Add([TestFixtures.Red, TestFixtures.Color("Navy", Hex: "000080")])
        let URL = try MakeFile("Marks.png", color: (20, 20, 150))
        defer { try? FileManager.default.removeItem(at: URL) }
        let Model = ImagePalettizerModel()
        Model.LoadImage(from: URL)
        await Model.Palettize(colors: Selection.PaletteColors, ids: Selection.IDs)
        let Result = try #require(Model.ResultImage)
        #expect(Array(Support.Pixels(of: Result)[0..<4]) == [0, 0, 128, 255])
        #expect(Model.ResultIsCurrent(for: Selection.IDs))
        // Removing a color from the palette makes the result out of date.
        Selection.Remove([TestFixtures.Red])
        #expect(!Model.ResultIsCurrent(for: Selection.IDs))
    }
}
