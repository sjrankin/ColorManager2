//
//  TestFixtures.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation
@testable import ColorManager

/// Builders for small color databases used by the search tests.
enum TestFixtures
{
    /// Make a color record. Only the color spaces passed are defined.
    static func Color(_ Name: String,
                      Hex: String? = nil,
                      RGB: (Int, Int, Int)? = nil,
                      HSB: (Double, Double, Double)? = nil,
                      AlternativeNames: [String]? = nil) -> ColorRecord
    {
        return ColorRecord(Id: nil, Name: Name, AlternativeNames: AlternativeNames, AlternativeName: nil,
                           Canonical: nil, Tags: nil, Language: nil,
                           Hex: Hex.map { HexRecord(HexValue: $0) },
                           RGB: RGB.map { RGBRecord(r: $0.0, g: $0.1, b: $0.2) },
                           HSL: nil,
                           HSB: HSB.map { HSBRecord(h: $0.0, s: $0.1, b: $0.2) },
                           CMYK: nil, LAB: nil, Variant: nil, Replaces: nil, XMLDefinition: nil)
    }
    
    static func Group(_ Name: String,
                      Colors: [ColorRecord] = [],
                      Groups: [ColorGroup] = [],
                      Collections: [ColorCollection] = []) -> ColorGroup
    {
        return ColorGroup(Id: nil, Name: Name, ShortName: nil, ClassName: nil, Alias: nil, Source: nil, Legal: nil,
                          TestGroup: nil, Notes: nil, Colors: Colors, Groups: Groups, Collections: Collections)
    }
    
    static func Collection(_ Name: String, Colors: [ColorRecord] = []) -> ColorCollection
    {
        return ColorCollection(Id: nil, Name: Name, Source: nil, Notes: nil, ClassName: nil, Colors: Colors,
                               Font: nil, Groups: nil, Collections: nil)
    }
    
    // MARK: Shared colors
    
    static let Red = Color("Red", Hex: "FF0000")
    static let DarkRed = Color("Dark Red", Hex: "8B0000", AlternativeNames: ["Maroonish"])
    static let AlmostRed = Color("Almost Red", RGB: (250, 5, 5))
    static let Blue = Color("Blue", HSB: (240, 100, 100))
    static let Cafe = Color("Café", Hex: "6F4E37")
    static let Gray = Color("Gray", Hex: "808080")
    static let NoColor = Color("Nothing")
    
    /// A database with nested groups and a collection:
    ///
    /// - Top: Red, Dark Red, Almost Red, Gray
    ///   - Inner: Blue, Café
    ///   - Coll (collection): Nothing (no color)
    static var Database: [ColorGroup]
    {
        let Inner = Group("Inner", Colors: [Blue, Cafe])
        let Coll = Collection("Coll", Colors: [NoColor])
        return [Group("Top", Colors: [Red, DarkRed, AlmostRed, Gray], Groups: [Inner], Collections: [Coll])]
    }
}
