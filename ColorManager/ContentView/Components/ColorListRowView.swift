//
//  ColorListRowView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 4/15/26.
//

import Foundation
import SwiftUI

/// A single row in the color list view, showing a swatch, name, and hex value.
struct ColorListRowView: View
{
    let ColorRecord: ColorRecord
    let SwatchColor: Color
    let HexValue: String
    let IsSelected: Bool
    /// True if the color is marked for the palette.
    var IsMarked: Bool = false
    /// True while palette selection mode is on; shows a checkbox for every row.
    var ShowCheckbox: Bool = false
    let OnTap: () -> Void

    var body: some View
    {
        VStack(spacing: 0)
        {
            HStack(spacing: 10)
            {
                if ShowCheckbox || IsMarked
                {
                    Image(systemName: IsMarked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(IsMarked ? Color.accentColor : Color.secondary)
                        .accessibilityLabel(IsMarked ? "Selected for palette" : "Not selected for palette")
                }
                RoundedRectangle(cornerRadius: 4)
                    .fill(SwatchColor)
                    .frame(width: 36, height: 36)
                    .overlay(RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5))
                Text(ColorRecord.Name)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                Text(HexValue)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(IsSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture
            {
                OnTap()
            }

            Divider()
                .padding(.leading, 54)
        }
    }
}
