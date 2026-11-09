//
//  SearchRecord.swift
//  ColorManager
//
//  Created by Stuart Rankin on 4/17/26.
//

import Foundation

class SearchRecord
{
    var SearchType: SearchTypes = .NotDefined
    var NameSearch: NameSearchModel? = nil
    var ValueSearch: ValueSearchModel? = nil
}

class NameSearchModel
{
    var NameSearch: String = ""
    var CharSet = CharSets.All
}

class ValueSearchModel
{
    var SearchType: ValueSearchTypes = .Specified
    var HueName: String = "" //red(reddish), green, etc
    var HueValue: Double = 0.0 //Hue value
    var HueRange: Double = 0.0 // range (1/2 higher, 1/2 lower) for hue searching
    var Saturation: Double = 0.0
    var SaturationRange: Double = 0.0
    // Used by `.HSBRange`. Hue is in degrees (`0` - `360`); saturation and brightness are percentages (`0` - `100`).
    // Each range is the total width around its value (half above, half below). A hue range of `360` or more, or a
    // saturation or brightness range of `200` or more, accepts everything.
    var Brightness: Double = 0.0
    var BrightnessRange: Double = 0.0
    // Used by .Value and .Match
    var Specified: (red: Float, green: Float, blue: Float)? = nil
    var SpecifiedRange: (red: Float, green: Float, blue: Float) = (0.0, 0.0, 0.0)
    /// Used by `.Specified` searches: the largest CIE76 color difference (Delta E) from `Specified` that still matches.
    var Tolerance: Double = 10.0
    /// Used by `.Specified` searches: the formula used to measure color difference.
    var Method: ColorDifferenceMethods = .CIE76
}

enum ValueSearchTypes
{
    case HueName
    case HueValue
    case Saturation
    case Specified
    /// Match colors whose hue, saturation, and brightness fall within ranges. Uses `HueValue`/`HueRange`,
    /// `Saturation`/`SaturationRange`, and `Brightness`/`BrightnessRange`. (`HueName` is not used.)
    case HSBRange
}

enum CharSets
{
    case All
    case NonUTF8
    case OnlyUTF8
}

/// General search types.
enum SearchTypes
{
    /// Default
    case NotDefined
    /// Search by color name, group name, etc.
    case Name
    /// Search by color value, including hue range, etc.
    case Value
    /// Search colors by exact color (from image or camera).
    case Match
}
