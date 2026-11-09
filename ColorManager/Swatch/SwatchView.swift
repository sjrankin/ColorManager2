//
//  SwatchView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 3/22/26.
//

import SwiftUI

struct SwatchView: View
{
    var ColorID: UUID
    @Binding var SelectedID: UUID
    var SwatchColor: Color = .red
    var SwatchColorName: String = "Test Name That Is Too Long"
    var SwatchColorValue: String = "0x000000"
    var SwatchWidth: CGFloat = 96
    var SwatchHeaderHeight: CGFloat = 48
    var ShowShadow: Bool = true
    var CanTap: Bool = true
    /// True if the color is marked for the palette; draws a checkmark badge.
    var IsMarked: Bool = false
    var onTap: (() -> Void)? = nil
    let CornerRadius: CGFloat = 2.0
    @State private var ShadowColor: Color = .black.opacity(0.4)
    @State private var BorderColor: Color = .black
    @State private var BorderThickness: CGFloat = 1.0
    @State private var SwatchHeaderBackground: Color = .gray.opacity(0.15)
    @State private var ShadowRadius: CGFloat = 2.0
    @State private var ShadowXOffset: CGFloat = 2.0
    @State private var ShadowYOffset: CGFloat = 2.0

    var body: some View
    {
        VStack
        {
            SwatchHeader(ColorName: SwatchColorName,
                         ColorValue: SwatchColorValue,
                         SwatchWidth: SwatchWidth,
                         HeaderHeight: SwatchHeaderHeight,
                         BackgroundColor: $SwatchHeaderBackground)
            .padding(.bottom, -8)
            SwatchColorView(TheColor: SwatchColor,
                            SideLength: SwatchWidth)
        }
        .frame(width: SwatchWidth)
        .background(.white)
        .border(BorderColor)
        .cornerRadius(CornerRadius)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius)
            .stroke(BorderColor, lineWidth: BorderThickness))
        .overlay(alignment: .topTrailing)
        {
            if IsMarked
            {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.accentColor)
                    .background(.white, in: .circle)
                    .padding(4)
                    .accessibilityLabel("Selected for palette")
            }
        }
        .compositingGroup()
        .shadow(color: ShadowColor,
                radius: ShadowRadius,
                x: ShadowXOffset,
                y: ShadowYOffset)
        .onTapGesture
        {
            SelectedID = ColorID
            onTap?()
        }
        .onAppear
        {
            // A swatch created while already selected (for example after a group change) must look selected.
            ApplySelection(SelectedID == ColorID)
        }
        .onChange(of: SelectedID)
        {
            _, New in
            ApplySelection(New == ColorID)
        }
    }
    
    /// Set the swatch's border, shadow, and header to match whether it is selected.
    private func ApplySelection(_ IsSelected: Bool)
    {
        if IsSelected
        {
            SwatchHeaderBackground = .white
            BorderThickness = 2.0
            #if os(macOS)
            BorderColor = Color(nsColor: NSColor.controlAccentColor)
            #else
            BorderColor = Color(UIColor.tintColor)
            #endif
            ShadowColor = SwatchColor
            ShadowRadius = 4.0
            ShadowXOffset = 0.0
            ShadowYOffset = 0.0
        }
        else
        {
            SwatchHeaderBackground = .gray.opacity(0.15)
            BorderThickness = 1.0
            BorderColor = .black
            ShadowColor = .black.opacity(0.4)
            ShadowRadius = 2.0
            ShadowXOffset = 2.0
            ShadowYOffset = 2.0
        }
    }
}

#Preview
{
    @Previewable @State var SwatchID: UUID = UUID()
    @Previewable @State var colorID: UUID = UUID()
    SwatchView(ColorID: colorID,
               SelectedID: $SwatchID,
               SwatchColor: .indigo,
               SwatchWidth: 86)
}
