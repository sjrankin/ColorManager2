//
//  HSBRangeRow.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

/// One row of the HSB range editor: a slider for the center value and one for the plus-or-minus spread.
struct HSBRangeRow: View
{
    let Title: String
    let Unit: String
    let Maximum: Double
    let MaximumSpread: Double
    @Binding var Value: Double
    @Binding var Spread: Double
    
    var body: some View
    {
        VStack(alignment: .leading)
        {
            HStack
            {
                Text(Title)
                    .bold()
                Spacer()
                Text("\(Value, format: .number.precision(.fractionLength(0)))\(Unit) ± \(Spread, format: .number.precision(.fractionLength(0)))\(Unit)")
                    .monospacedDigit()
            }
            HStack
            {
                Text("Value")
                    .frame(width: 48, alignment: .leading)
                Slider(value: $Value, in: 0...Maximum, step: 1)
            }
            HStack
            {
                Text("Spread")
                    .frame(width: 48, alignment: .leading)
                Slider(value: $Spread, in: 0...MaximumSpread, step: 1)
            }
        }
        .font(.footnote)
    }
}
