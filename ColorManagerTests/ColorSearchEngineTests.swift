//
//  ColorSearchEngineTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Testing
@testable import ColorManager

@Suite("Color search engine")
struct ColorSearchEngineTests
{
    typealias Fixtures = TestFixtures
    let Groups = Fixtures.Database
    
    // MARK: Helpers
    
    func NameSearch(_ Text: String, _ CharSet: CharSets = .All) -> [String]
    {
        let Search = SearchRecord()
        Search.SearchType = .Name
        let Model = NameSearchModel()
        Model.NameSearch = Text
        Model.CharSet = CharSet
        Search.NameSearch = Model
        return ColorSearchEngine.Run(Search, in: Groups).map { $0.Record.Name }
    }
    
    func ValueSearch(_ Target: (Float, Float, Float),
                     Tolerance: Double,
                     Method: ColorDifferenceMethods = .CIE76) -> [ColorSearchResult]
    {
        let Search = SearchRecord()
        Search.SearchType = .Value
        let Model = ValueSearchModel()
        Model.SearchType = .Specified
        Model.Specified = Target
        Model.Tolerance = Tolerance
        Model.Method = Method
        Search.ValueSearch = Model
        return ColorSearchEngine.Run(Search, in: Groups)
    }
    
    // MARK: Gathering
    
    @Test func GathersEveryColorWithItsPath()
    {
        let Entries = ColorSearchEngine.AllEntries(in: Groups)
        #expect(Entries.count == 7)
        #expect(Entries.first { $0.Record.Name == "Blue" }?.PathComponents == ["Top", "Inner"])
        #expect(Entries.first { $0.Record.Name == "Nothing" }?.PathComponents == ["Top", "Coll"])
        #expect(Entries.first { $0.Record.Name == "Red" }?.Path == "Top")
        #expect(Entries.first { $0.Record.Name == "Blue" }?.Path == "Top > Inner")
    }
    
    @Test func EmptyDatabaseHasNoResults()
    {
        let Search = SearchRecord()
        Search.SearchType = .Name
        let Model = NameSearchModel()
        Model.NameSearch = "red"
        Search.NameSearch = Model
        #expect(ColorSearchEngine.Run(Search, in: []).isEmpty)
    }
    
    // MARK: Name search
    
    @Test func PlainTextIsASortedContainsSearch()
    {
        #expect(NameSearch("red") == ["Almost Red", "Dark Red", "Red"])
        #expect(NameSearch("RED") == ["Almost Red", "Dark Red", "Red"])
    }
    
    @Test func StarMatchesARunOfCharacters()
    {
        #expect(NameSearch("RED*") == ["Red"])
        #expect(NameSearch("*red") == ["Almost Red", "Dark Red", "Red"])
        #expect(NameSearch("D*d") == ["Dark Red"])
    }
    
    @Test func QuestionMarkMatchesOneCharacter()
    {
        #expect(NameSearch("B?ue") == ["Blue"])
        #expect(NameSearch("B?e") == [])
    }
    
    @Test func SearchIgnoresDiacriticsAndCase()
    {
        #expect(NameSearch("cafe") == ["Café"])
        #expect(NameSearch("CAFÉ") == ["Café"])
    }
    
    @Test func AlternativeNamesAreSearched()
    {
        #expect(NameSearch("maroon") == ["Dark Red"])
    }
    
    @Test func RegexCharactersAreLiteral()
    {
        #expect(NameSearch("a.c*(") == [])
        #expect(NameSearch("[") == [])
        #expect(NameSearch("(*") == [])
        #expect(NameSearch(".*") == [])
    }
    
    @Test func BlankSearchFindsNothing()
    {
        #expect(NameSearch("") == [])
        #expect(NameSearch("   ") == [])
        #expect(NameSearch("\n") == [])
    }
    
    @Test func CharacterSetsFilterByNonASCII()
    {
        #expect(NameSearch("c", .OnlyUTF8) == ["Café"])
        #expect(NameSearch("red", .OnlyUTF8) == [])
        #expect(NameSearch("red", .NonUTF8).count == 3)
        #expect(NameSearch("caf", .NonUTF8) == [])
    }
    
    // MARK: Value search by distance
    
    @Test func NearRedFindsRedAndAlmostRed()
    {
        let Results = ValueSearch((1, 0, 0), Tolerance: 5)
        #expect(Results.map { $0.Record.Name } == ["Red", "Almost Red"])
        #expect(Results[0].Distance! < 1e-9)
        #expect(Results[0].Distance! < Results[1].Distance!)
    }
    
    @Test func ToleranceZeroIsExact()
    {
        #expect(ValueSearch((1, 0, 0), Tolerance: 0).map { $0.Record.Name } == ["Red"])
    }
    
    @Test func RecordsAreReadFromWhicheverColorSpaceTheyHave()
    {
        // "Blue" has only an HSB definition.
        #expect(ValueSearch((0, 0, 1), Tolerance: 1).map { $0.Record.Name } == ["Blue"])
    }
    
    @Test func RecordsWithoutColorAreSkipped()
    {
        let Everything = ValueSearch((0.5, 0.5, 0.5), Tolerance: 1000)
        #expect(Everything.count == 6)
        #expect(!Everything.contains { $0.Record.Name == "Nothing" })
    }
    
    @Test func ResultsGetCloserAsToleranceShrinks()
    {
        let Wide = ValueSearch((1, 0, 0), Tolerance: 100).count
        let Narrow = ValueSearch((1, 0, 0), Tolerance: 10).count
        #expect(Narrow <= Wide)
    }
    
    @Test func SearchUsesTheChosenMethod()
    {
        for Method in ColorDifferenceMethods.allCases
        {
            let Results = ValueSearch((1, 0, 0), Tolerance: 1000, Method: Method)
            let AlmostRed = Results.first { $0.Record.Name == "Almost Red" }
            let Expected = ColorSpaceMath.DeltaE(From: (1, 0, 0), To: (250.0 / 255, 5.0 / 255, 5.0 / 255), Method: Method)
            #expect(AlmostRed != nil)
            #expect(abs((AlmostRed?.Distance ?? -1) - Expected) < 1e-6, "\(Method)")
        }
        let Simple = ValueSearch((1, 0, 0), Tolerance: 1000, Method: .CIE76).first { $0.Record.Name == "Dark Red" }
        let Better = ValueSearch((1, 0, 0), Tolerance: 1000, Method: .CIEDE2000).first { $0.Record.Name == "Dark Red" }
        #expect(Simple?.Distance != Better?.Distance)
    }
    
    @Test func ToleranceAppliesToTheChosenMethod()
    {
        // Find a tolerance that includes Dark Red under one method but not the other.
        let Cie76 = ValueSearch((1, 0, 0), Tolerance: 1000, Method: .CIE76).first { $0.Record.Name == "Dark Red" }!.Distance!
        let Ciede = ValueSearch((1, 0, 0), Tolerance: 1000, Method: .CIEDE2000).first { $0.Record.Name == "Dark Red" }!.Distance!
        let Between = (Cie76 + Ciede) / 2
        let Lower = min(Cie76, Ciede)
        let Upper = max(Cie76, Ciede)
        #expect(Lower < Between && Between < Upper)
        let In76 = ValueSearch((1, 0, 0), Tolerance: Between, Method: .CIE76).contains { $0.Record.Name == "Dark Red" }
        let InDE = ValueSearch((1, 0, 0), Tolerance: Between, Method: .CIEDE2000).contains { $0.Record.Name == "Dark Red" }
        #expect(In76 == (Cie76 <= Between))
        #expect(InDE == (Ciede <= Between))
        #expect(In76 != InDE)
    }
    
    // MARK: Other search types
    
    @Test func UnsupportedSearchTypesFindNothing()
    {
        #expect(ColorSearchEngine.Run(SearchRecord(), in: Groups).isEmpty)
        let Match = SearchRecord()
        Match.SearchType = .Match
        #expect(ColorSearchEngine.Run(Match, in: Groups).isEmpty)
        let HueName = SearchRecord()
        HueName.SearchType = .Value
        let Model = ValueSearchModel()
        Model.SearchType = .HueName
        HueName.ValueSearch = Model
        #expect(ColorSearchEngine.Run(HueName, in: Groups).isEmpty)
    }
}
