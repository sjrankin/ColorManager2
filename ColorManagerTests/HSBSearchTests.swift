//
//  HSBSearchTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Testing
@testable import ColorManager

@Suite("HSB range search")
struct HSBSearchTests
{
    typealias Fixtures = TestFixtures
    
    /// A database of colors with known hue, saturation, and brightness (all given as HSB records).
    let Groups =
    [
        Fixtures.Group("Colors", Colors:
        [
            Fixtures.Color("Red", HSB: (0, 100, 100)),
            Fixtures.Color("Rose", HSB: (350, 80, 90)),
            Fixtures.Color("Orange", HSB: (30, 100, 100)),
            Fixtures.Color("Green", HSB: (120, 100, 100)),
            Fixtures.Color("Pale Green", HSB: (120, 20, 100)),
            Fixtures.Color("Dark Green", HSB: (120, 100, 30)),
            Fixtures.Color("Blue", HSB: (240, 100, 100)),
            Fixtures.Color("Gray", HSB: (0, 0, 50)),
            Fixtures.Color("White", HSB: (0, 0, 100)),
            Fixtures.Color("Black", HSB: (0, 0, 0)),
        ])
    ]
    
    /// Run an HSB range search. Spreads are the plus-or-minus amounts, as the UI shows them.
    func Search(Hue: Double = 0, HueSpread: Double = 180,
                Saturation: Double = 50, SaturationSpread: Double = 100,
                Brightness: Double = 50, BrightnessSpread: Double = 100) -> [String]
    {
        let Record = SearchRecord()
        Record.SearchType = .Value
        let Model = ValueSearchModel()
        Model.SearchType = .HSBRange
        Model.HueValue = Hue
        Model.HueRange = HueSpread * 2
        Model.Saturation = Saturation
        Model.SaturationRange = SaturationSpread * 2
        Model.Brightness = Brightness
        Model.BrightnessRange = BrightnessSpread * 2
        Record.ValueSearch = Model
        return ColorSearchEngine.Run(Record, in: Groups).map { $0.Record.Name }
    }
    
    @Test func DefaultsAcceptEveryColor()
    {
        #expect(Search().count == 10)
    }
    
    @Test func ResultsAreSortedByName()
    {
        let Names = Search()
        #expect(Names == Names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }
    
    @Test func HueRangeSelectsAFamily()
    {
        #expect(Search(Hue: 120, HueSpread: 10) == ["Dark Green", "Green", "Pale Green"])
        #expect(Search(Hue: 240, HueSpread: 10) == ["Blue"])
    }
    
    @Test func HueRangeWrapsAroundZero()
    {
        // 350 and 0 are 10 degrees apart on the hue circle.
        #expect(Search(Hue: 355, HueSpread: 10) == ["Red", "Rose"])
        // Rose is 15 degrees from 5 (going the short way, through 0), Red is 5.
        #expect(Search(Hue: 5, HueSpread: 10) == ["Red"])
        #expect(Search(Hue: 5, HueSpread: 15.5) == ["Red", "Rose"])
        // Just inside the edge matches; just outside does not. (Hues that went through RGB can differ by a rounding
        // error, so the edge itself is not tested.)
        #expect(Search(Hue: 0, HueSpread: 10.5) == ["Red", "Rose"])
        #expect(Search(Hue: 0, HueSpread: 9.5) == ["Red"])
    }
    
    @Test func NarrowHueRangeExcludesGraysAndBlack()
    {
        let Names = Search(Hue: 0, HueSpread: 179)
        #expect(!Names.contains("Gray"))
        #expect(!Names.contains("White"))
        #expect(!Names.contains("Black"))
        // Even a hue range centered on a gray's stored hue of 0 does not match it.
        #expect(!Search(Hue: 0, HueSpread: 1).contains("Gray"))
    }
    
    @Test func FullHueRangeIncludesGrays()
    {
        let Names = Search(Hue: 0, HueSpread: 180)
        #expect(Names.contains("Gray") && Names.contains("White") && Names.contains("Black"))
    }
    
    @Test func SaturationRangeSeparatesVividFromPale()
    {
        #expect(Search(Hue: 120, HueSpread: 10, Saturation: 20, SaturationSpread: 10) == ["Pale Green"])
        #expect(Search(Hue: 120, HueSpread: 10, Saturation: 100, SaturationSpread: 10) == ["Dark Green", "Green"])
    }
    
    @Test func BrightnessRangeSeparatesDarkFromLight()
    {
        #expect(Search(Hue: 120, HueSpread: 10, Brightness: 30, BrightnessSpread: 10) == ["Dark Green"])
        #expect(Search(Hue: 120, HueSpread: 10, Brightness: 100, BrightnessSpread: 10) == ["Green", "Pale Green"])
    }
    
    @Test func GraysCanBeFoundWithoutAHueConstraint()
    {
        #expect(Search(Saturation: 0, SaturationSpread: 5) == ["Black", "Gray", "White"])
        #expect(Search(Saturation: 0, SaturationSpread: 5, Brightness: 50, BrightnessSpread: 5) == ["Gray"])
    }
    
    @Test func AllThreeRangesMustMatch()
    {
        let Names = Search(Hue: 0, HueSpread: 15, Saturation: 100, SaturationSpread: 5, Brightness: 100, BrightnessSpread: 5)
        #expect(Names == ["Red"])
    }
    
    @Test func RangesInDifferentColorSpacesAgree()
    {
        // The same orange defined as hex and as HSB must both be found by one HSB range search.
        let Groups =
        [
            Fixtures.Group("Mixed", Colors:
            [
                Fixtures.Color("Orange Hex", Hex: "FF8000"),
                Fixtures.Color("Orange RGB", RGB: (255, 128, 0)),
                Fixtures.Color("Orange HSB", HSB: (30.12, 100, 100)),
            ])
        ]
        let Record = SearchRecord()
        Record.SearchType = .Value
        let Model = ValueSearchModel()
        Model.SearchType = .HSBRange
        Model.HueValue = 30
        Model.HueRange = 4
        Model.Saturation = 100
        Model.SaturationRange = 4
        Model.Brightness = 100
        Model.BrightnessRange = 4
        Record.ValueSearch = Model
        let Names = ColorSearchEngine.Run(Record, in: Groups).map { $0.Record.Name }
        #expect(Set(Names) == ["Orange HSB", "Orange Hex", "Orange RGB"])
    }
    
    @Test func SearchResultsCarryNoDistance()
    {
        let Record = SearchRecord()
        Record.SearchType = .Value
        let Model = ValueSearchModel()
        Model.SearchType = .HSBRange
        Model.HueRange = 360
        Model.SaturationRange = 200
        Model.BrightnessRange = 200
        Record.ValueSearch = Model
        let Results = ColorSearchEngine.Run(Record, in: Groups)
        #expect(!Results.isEmpty)
        #expect(Results.allSatisfy { $0.Distance == nil })
    }
}
