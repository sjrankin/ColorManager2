//
//  PaletteChipView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

/// A small color view for one palette color, with a button to remove it from the palette.
struct PaletteChipView: View
{
    let Record: ColorRecord
    let OnRemove: () -> Void
    
    var body: some View
    {
        RoundedRectangle(cornerRadius: 4)
            .fill(ChipColor)
            .frame(width: 32, height: 32)
            .overlay(RoundedRectangle(cornerRadius: 4)
                .strokeBorder(.primary.opacity(0.25), lineWidth: 0.5))
            .overlay(alignment: .topTrailing)
            {
                Button("Remove \(Record.Name)", systemImage: "xmark.circle.fill", action: OnRemove)
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .gray)
                    .buttonStyle(.plain)
                    .background(.white, in: .circle)
                    .offset(x: 6, y: -6)
            }
            .padding(.top, 6)
            .padding(.trailing, 6)
            .help(Record.Name)
            .accessibilityLabel(Record.Name)
    }
    
    /// The record's color, or clear if it has none.
    private var ChipColor: Color
    {
        guard let RGB = ColorSearchEngine.RGBChannels(of: Record) else
        {
            return .clear
        }
        return Color(.sRGB, red: RGB.r, green: RGB.g, blue: RGB.b, opacity: 1.0)
    }
}
