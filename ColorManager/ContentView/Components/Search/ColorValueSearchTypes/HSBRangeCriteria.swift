//
//  HSBRangeCriteria.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation

/// What the HSB range search editor edits: a center value and a plus-or-minus spread for each of hue, saturation, and
/// brightness. The defaults accept every color.
struct HSBRangeCriteria: Equatable
{
    /// Center hue in degrees (`0` - `360`).
    var Hue: Double = 0.0
    /// Hue spread in degrees, applied above and below `Hue`. `180` accepts every hue (including grays).
    var HueSpread: Double = 180.0
    /// Center saturation in percent.
    var Saturation: Double = 50.0
    /// Saturation spread in percent, applied above and below `Saturation`. `100` accepts every saturation.
    var SaturationSpread: Double = 100.0
    /// Center brightness in percent.
    var Brightness: Double = 50.0
    /// Brightness spread in percent, applied above and below `Brightness`. `100` accepts every brightness.
    var BrightnessSpread: Double = 100.0
}
