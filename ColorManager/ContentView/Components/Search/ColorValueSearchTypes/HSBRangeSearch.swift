//
//  HSBRangeSearch.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

/// Edit ranges of hue, saturation, and brightness to search for. Colors match when all three are within range.
struct HSBRangeSearch: View
{
    @Binding var Criteria: HSBRangeCriteria
    
    var body: some View
    {
        HStack(alignment: .top)
        {
            VStack
            {
                HSBRangeRow(Title: "Hue", Unit: "°", Maximum: 360, MaximumSpread: 180,
                            Value: $Criteria.Hue, Spread: $Criteria.HueSpread)
                HSBRangeRow(Title: "Saturation", Unit: "%", Maximum: 100, MaximumSpread: 100,
                            Value: $Criteria.Saturation, Spread: $Criteria.SaturationSpread)
                HSBRangeRow(Title: "Brightness", Unit: "%", Maximum: 100, MaximumSpread: 100,
                            Value: $Criteria.Brightness, Spread: $Criteria.BrightnessSpread)
            }
            .padding()
            // A swatch of the center of the range.
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hue: Criteria.Hue / 360.0,
                            saturation: Criteria.Saturation / 100.0,
                            brightness: Criteria.Brightness / 100.0))
                .frame(width: 64, height: 64)
                .overlay(RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(.primary.opacity(0.3), lineWidth: 1))
                .padding()
        }
        .frame(maxWidth: .infinity)
        .overlay
        {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.secondary, lineWidth: 1)
        }
        .padding()
    }
}
