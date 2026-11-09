//
//  PaletteXMLWriterTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation
import Testing
@testable import ColorManager

@Suite("Palette XML writer")
struct PaletteXMLWriterTests
{
    /// Parse some XML text through the normal importer.
    func Import(_ Text: String) throws -> ImportedColorData
    {
        let URL = ImageTestSupport.TemporaryURL("Palette.xml")
        try Data(Text.utf8).write(to: URL)
        defer { try? FileManager.default.removeItem(at: URL) }
        return try ColorListIO.parseXMLFile(url: URL)
    }
    
    func Records(_ XML: String) throws -> [ColorRecord]
    {
        let Imported = try Import(XML)
        return try #require(Imported.colorGroups?.first?.Colors ?? Imported.fullColors?.ColorGroups?.first?.Colors)
    }
    
    @Test func WrittenPaletteLoadsBackWithTheSameColors() throws
    {
        let Source = try Records("""
            <Colors><ColorGroup Name="G">
            <Color Name="Red" Hex="ff0000"/>
            <Color Name="Sea &amp; Sky" Hex="0080ff"/>
            </ColorGroup></Colors>
            """)
        let Text = PaletteXMLWriter.XML(for: Source, name: "My Palette")
        let Imported = try Import(Text)
        #expect(Imported.importType == .fullStructure)
        let Group = try #require(Imported.fullColors?.ColorGroups?.first)
        #expect(Group.Name == "My Palette")
        #expect(Group.Colors?.map(\.Name) == ["Red", "Sea & Sky"])
        #expect(Group.Colors?.compactMap { $0.Hex?.HexValue.lowercased() } == ["ff0000", "0080ff"])
    }
    
    @Test func GroupNameComesFromTheFileName() throws
    {
        #expect(PaletteXMLWriter.GroupName(forFile: URL(fileURLWithPath: "/tmp/Sunset Colors.xml")) == "Sunset Colors")
    }
    
    @Test func NamesAreEscaped()
    {
        #expect(PaletteXMLWriter.Escaped("a&b<\"c\">") == "a&amp;b&lt;&quot;c&quot;&gt;")
        let Text = PaletteXMLWriter.XML(for: [], name: "A & B")
        #expect(XMLParser(data: Data(Text.utf8)).parse())
    }
    
    @Test func MergingAddsNewColorsAndSkipsDuplicates() throws
    {
        let Existing = PaletteXMLWriter.XML(for: try Records("""
            <Colors><ColorGroup Name="G"><Color Name="Red" Hex="ff0000"/></ColorGroup></Colors>
            """), name: "Mine")
        let Selected = try Records("""
            <Colors><ColorGroup Name="G">
            <Color Name="Red" Hex="ff0000"/><Color Name="Blue" Hex="0000ff"/>
            </ColorGroup></Colors>
            """)
        let Current = PaletteXMLWriter.AllColors(in: try Import(Existing))
        let Result = try PaletteXMLWriter.Merged(Selected, into: Existing, existing: Current)
        #expect(Result.Added == 1 && Result.Skipped == 1)
        let Merged = try Records(Result.Text)
        #expect(Merged.map(\.Name) == ["Red", "Blue"])
        // The rest of the file is untouched.
        #expect(Result.Text.hasPrefix(String(Existing.prefix(200))))
    }
    
    @Test func MergingNothingNewLeavesTheTextAlone() throws
    {
        let Existing = PaletteXMLWriter.XML(for: try Records("""
            <Colors><ColorGroup Name="G"><Color Name="Red" Hex="ff0000"/></ColorGroup></Colors>
            """), name: "Mine")
        let Current = PaletteXMLWriter.AllColors(in: try Import(Existing))
        let Result = try PaletteXMLWriter.Merged(Current, into: Existing, existing: Current)
        #expect(Result.Added == 0 && Result.Text == Existing)
    }
    
    @Test func MergingIntoAFileWithoutAGroupFails()
    {
        #expect(throws: PaletteXMLWriter.MergeError.self)
        {
            try PaletteXMLWriter.Merged([], into: "<Colors/>", existing: [])
        }
    }
}
