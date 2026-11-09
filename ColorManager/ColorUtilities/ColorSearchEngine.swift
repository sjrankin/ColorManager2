//
//  ColorSearchEngine.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation

/// Runs searches described by a `SearchRecord` against the color list.
enum ColorSearchEngine
{
    /// A color together with the path of groups and collections that contains it.
    struct Entry
    {
        let Record: ColorRecord
        /// The names of the groups and collections that contain the color, outermost first.
        let PathComponents: [String]
        
        /// `PathComponents` as text, for example `Web > Reds`.
        var Path: String
        {
            return PathComponents.joined(separator: " > ")
        }
    }
    
    // MARK: - Entry point
    
    /// Run the search described by `Search`.
    /// - Parameter Search: The search to run. Name and value searches are supported; other types return no results.
    /// - Parameter Groups: The color groups to search.
    /// - Returns: The matching colors. Name searches are sorted by name and value searches by closeness to the target.
    static func Run(_ Search: SearchRecord, in Groups: [ColorGroup]) -> [ColorSearchResult]
    {
        let Entries = AllEntries(in: Groups)
        switch Search.SearchType
        {
            case .Name:
                guard let Model = Search.NameSearch else
                {
                    return []
                }
                return ByName(Model, in: Entries)
                
            case .Value:
                guard let Model = Search.ValueSearch else
                {
                    return []
                }
                return ByValue(Model, in: Entries)
                
            case .NotDefined, .Match:
                return []
        }
    }
    
    // MARK: - Name search
    
    /// Find colors whose name (or alternative name) matches.
    static func ByName(_ Model: NameSearchModel, in Entries: [Entry]) -> [ColorSearchResult]
    {
        let Pattern = Model.NameSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        if Pattern.isEmpty
        {
            return []
        }
        let Matched = Entries.filter
        {
            AllowedByCharSet($0.Record.Name, Model.CharSet) && NamesMatch($0.Record, Pattern)
        }
        return Matched
            .map { ColorSearchResult(Record: $0.Record, PathComponents: $0.PathComponents, Distance: nil) }
            .sorted { $0.Record.Name.localizedStandardCompare($1.Record.Name) == .orderedAscending }
    }
    
    /// Does any name of the record match the pattern?
    static func NamesMatch(_ Record: ColorRecord, _ Pattern: String) -> Bool
    {
        var Names = [Record.Name]
        if let Alternative = Record.AlternativeName
        {
            Names.append(Alternative)
        }
        Names.append(contentsOf: Record.AlternativeNames ?? [])
        return Names.contains { Matches($0, Pattern) }
    }
    
    /// Match text against a search pattern.
    ///
    /// Without wildcards, this is a case- and diacritic-insensitive "contains". If the pattern has `*` (any run of
    /// characters) or `?` (any one character), the whole name must match the pattern.
    static func Matches(_ Text: String, _ Pattern: String) -> Bool
    {
        if Pattern.contains("*") || Pattern.contains("?")
        {
            // Escaping first means the user's text can never form an invalid regular expression.
            let Regex = NSRegularExpression.escapedPattern(for: Pattern)
                .replacing("\\*", with: ".*")
                .replacing("\\?", with: ".")
            return Text.range(of: "^\(Regex)$",
                              options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
        }
        return Text.localizedStandardContains(Pattern)
    }
    
    /// "Only UTF8" means names with at least one non-ASCII character; "No UTF8" means ASCII-only names.
    static func AllowedByCharSet(_ Name: String, _ CharSet: CharSets) -> Bool
    {
        switch CharSet
        {
            case .All: return true
            case .OnlyUTF8: return !Name.allSatisfy(\.isASCII)
            case .NonUTF8: return Name.allSatisfy(\.isASCII)
        }
    }
    
    // MARK: - Value search
    
    /// Run a value search of whatever kind the model describes.
    static func ByValue(_ Model: ValueSearchModel, in Entries: [Entry]) -> [ColorSearchResult]
    {
        switch Model.SearchType
        {
            case .Specified: return ByDistance(Model, in: Entries)
            case .HSBRange: return ByHSB(Model, in: Entries)
            case .HueName, .HueValue, .Saturation: return []
        }
    }
    
    /// Find colors within the model's tolerance of the specified color (measured with the model's method), closest first.
    static func ByDistance(_ Model: ValueSearchModel, in Entries: [Entry]) -> [ColorSearchResult]
    {
        guard let Target = Model.Specified else
        {
            return []
        }
        let TargetRGB = (r: Double(Target.red), g: Double(Target.green), b: Double(Target.blue))
        var Results: [ColorSearchResult] = []
        for Item in Entries
        {
            guard let Channels = RGBChannels(of: Item.Record) else
            {
                continue
            }
            let Difference = ColorSpaceMath.DeltaE(From: TargetRGB, To: Channels, Method: Model.Method)
            if Difference <= Model.Tolerance
            {
                Results.append(ColorSearchResult(Record: Item.Record, PathComponents: Item.PathComponents, Distance: Difference))
            }
        }
        return Results.sorted
        {
            ($0.Distance ?? 0) < ($1.Distance ?? 0)
        }
    }
    
    // MARK: - HSB range search
    
    /// Find colors whose hue, saturation, and brightness are all within the model's ranges, sorted by name.
    static func ByHSB(_ Model: ValueSearchModel, in Entries: [Entry]) -> [ColorSearchResult]
    {
        var Results: [ColorSearchResult] = []
        for Item in Entries
        {
            guard let Channels = RGBChannels(of: Item.Record) else
            {
                continue
            }
            let HSB = ColorSpaceMath.RGBToHSB(R: Channels.r, G: Channels.g, B: Channels.b)
            if InRange(HSB, Model)
            {
                Results.append(ColorSearchResult(Record: Item.Record, PathComponents: Item.PathComponents, Distance: nil))
            }
        }
        return Results.sorted { $0.Record.Name.localizedStandardCompare($1.Record.Name) == .orderedAscending }
    }
    
    /// Is the color (hue in degrees, saturation and brightness in percent) within all three of the model's ranges?
    ///
    /// A hue range narrower than a full circle never matches grays and blacks, since they have no hue.
    static func InRange(_ HSB: (h: Double, s: Double, b: Double), _ Model: ValueSearchModel) -> Bool
    {
        if Model.HueRange < 360.0
        {
            let IsGray = HSB.s < 1.0 || HSB.b <= 0.0
            if IsGray
            {
                return false
            }
            let Difference = abs(HSB.h - Model.HueValue).truncatingRemainder(dividingBy: 360.0)
            if min(Difference, 360.0 - Difference) > Model.HueRange / 2.0
            {
                return false
            }
        }
        return abs(HSB.s - Model.Saturation) <= Model.SaturationRange / 2.0 &&
               abs(HSB.b - Model.Brightness) <= Model.BrightnessRange / 2.0
    }
    
    /// The record's color as sRGB channels (`0.0` - `1.0`), taken from the first color space the record defines, in the
    /// order `Hex`, `RGB`, `HSL`, `HSB`, `CMYK`, `LAB`.
    /// - Returns: `nil` if the record has no usable color.
    static func RGBChannels(of Record: ColorRecord) -> (r: Double, g: Double, b: Double)?
    {
        if let Hex = Record.Hex, let Channels = Convert.ParseHexChannels(Hex.HexValue)
        {
            return (ColorSpaceMath.FromByte(Channels.red), ColorSpaceMath.FromByte(Channels.green),
                    ColorSpaceMath.FromByte(Channels.blue))
        }
        if let RGB = Record.RGB
        {
            return (ColorSpaceMath.FromByte(RGB.r), ColorSpaceMath.FromByte(RGB.g), ColorSpaceMath.FromByte(RGB.b))
        }
        if let HSL = Record.HSL
        {
            return ColorSpaceMath.HSLToRGB(H: HSL.h, S: HSL.s, L: HSL.l)
        }
        if let HSB = Record.HSB
        {
            return ColorSpaceMath.HSBToRGB(H: HSB.h, S: HSB.s, B: HSB.b)
        }
        if let CMYK = Record.CMYK
        {
            return ColorSpaceMath.CMYKToRGB(C: CMYK.c, M: CMYK.m, Y: CMYK.y, K: CMYK.k)
        }
        if let LAB = Record.LAB
        {
            return ColorSpaceMath.LabToRGB(L: LAB.l, A: LAB.a, B: LAB.b)
        }
        return nil
    }
    
    // MARK: - Gathering colors
    
    /// Every color in the groups, including those in nested groups and collections, with its path.
    static func AllEntries(in Groups: [ColorGroup]) -> [Entry]
    {
        var Entries: [Entry] = []
        for Group in Groups
        {
            Gather(Group, Parent: [], into: &Entries)
        }
        return Entries
    }
    
    private static func Gather(_ Group: ColorGroup, Parent: [String], into Entries: inout [Entry])
    {
        let Path = Parent + [Group.Name]
        for Record in Group.Colors ?? []
        {
            Entries.append(Entry(Record: Record, PathComponents: Path))
        }
        for Child in Group.Groups ?? []
        {
            Gather(Child, Parent: Path, into: &Entries)
        }
        for Collection in Group.Collections ?? []
        {
            Gather(Collection, Parent: Path, into: &Entries)
        }
    }
    
    private static func Gather(_ Collection: ColorCollection, Parent: [String], into Entries: inout [Entry])
    {
        let Path = Parent + [Collection.Name]
        for Record in Collection.Colors ?? []
        {
            Entries.append(Entry(Record: Record, PathComponents: Path))
        }
        for Child in Collection.Groups ?? []
        {
            Gather(Child, Parent: Path, into: &Entries)
        }
        for Child in Collection.Collections ?? []
        {
            Gather(Child, Parent: Path, into: &Entries)
        }
    }
}
