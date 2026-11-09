//
//  PaletteSelectionTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Testing
@testable import ColorManager

@Suite("Palette selection")
struct PaletteSelectionTests
{
    typealias Fixtures = TestFixtures
    
    let Red = Fixtures.Color("Red", Hex: "FF0000")
    let Green = Fixtures.Color("Green", RGB: (0, 255, 0))
    let Blue = Fixtures.Color("Blue", HSB: (240, 100, 100))
    let NoColor = Fixtures.Color("Nothing")
    
    @Test func StartsEmpty()
    {
        let Selection = PaletteSelection()
        #expect(Selection.IsEmpty)
        #expect(Selection.Count == 0)
        #expect(Selection.Records.isEmpty)
        #expect(Selection.PaletteColors.isEmpty)
    }
    
    @Test func ToggleMarksThenUnmarks()
    {
        let Selection = PaletteSelection()
        #expect(Selection.Toggle(Red) == true)
        #expect(Selection.Contains(Red))
        #expect(Selection.Count == 1)
        #expect(Selection.Toggle(Red) == false)
        #expect(!Selection.Contains(Red))
        #expect(Selection.IsEmpty)
    }
    
    @Test func ColorsKeepTheOrderTheyWereMarked()
    {
        let Selection = PaletteSelection()
        Selection.Add([Blue])
        Selection.Add([Red, Green])
        #expect(Selection.Records.map(\.Name) == ["Blue", "Red", "Green"])
    }
    
    @Test func AddingAMarkedColorAgainChangesNothing()
    {
        let Selection = PaletteSelection()
        Selection.Add([Red, Green])
        Selection.Add([Green, Red, Blue])
        #expect(Selection.Records.map(\.Name) == ["Red", "Green", "Blue"])
        #expect(Selection.Count == 3)
        #expect(Selection.IDs.count == 3)
    }
    
    @Test func RemoveUnmarksOnlyThoseColors()
    {
        let Selection = PaletteSelection()
        Selection.Add([Red, Green, Blue])
        Selection.Remove([Green, NoColor])
        #expect(Selection.Records.map(\.Name) == ["Red", "Blue"])
        #expect(!Selection.Contains(Green))
        #expect(Selection.Contains(Red) && Selection.Contains(Blue))
    }
    
    @Test func ClearUnmarksEverything()
    {
        let Selection = PaletteSelection()
        Selection.Add([Red, Green, Blue])
        Selection.Clear()
        #expect(Selection.IsEmpty)
        #expect(Selection.IDs.isEmpty)
        #expect(!Selection.Contains(Red))
        // It can be used again afterward.
        Selection.Add([Red])
        #expect(Selection.Count == 1)
    }
    
    @Test func ColorsAreIdentifiedByRecordNotByName()
    {
        // Two records with the same name and value are different colors in the list.
        let First = Fixtures.Color("Twin", Hex: "123456")
        let Second = Fixtures.Color("Twin", Hex: "123456")
        let Selection = PaletteSelection()
        Selection.Add([First])
        #expect(Selection.Contains(First))
        #expect(!Selection.Contains(Second))
        Selection.Add([Second])
        #expect(Selection.Count == 2)
    }
    
    @Test func PaletteColorsAreReadFromAnyColorSpace()
    {
        let Selection = PaletteSelection()
        Selection.Add([Red, Green, Blue])
        let Colors = Selection.PaletteColors
        #expect(Colors.count == 3)
        #expect(Colors[0] == (1, 0, 0))
        #expect(Colors[1] == (0, 1, 0))
        #expect(Colors[2] == (0, 0, 1))
    }
    
    @Test func PaletteColorsSkipRecordsWithoutAColor()
    {
        let Selection = PaletteSelection()
        Selection.Add([Red, NoColor, Blue])
        #expect(Selection.Count == 3)
        #expect(Selection.PaletteColors.count == 2)
    }
}
