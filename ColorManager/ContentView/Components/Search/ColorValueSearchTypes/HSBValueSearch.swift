//
//  HSBValueSearch.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

/// Edit a color by hue (`0` - `360` degrees), saturation (`0` - `100`), and brightness (`0` - `100`).
struct HSBValueSearch: View
{
    @Binding var SearchColor: PlatformColor
    @State private var Hue: String = "0"
    @State private var Saturation: String = "0"
    @State private var Brightness: String = "0"

    var body: some View
    {
        VStack
        {
            Text("HSB")
                .font(.system(size: 36))
                .bold()
            Spacer()
            HStack
            {
                HStack
                {
                    NumericChannelField(Title: "Hue", Maximum: 360, Value: $Hue, OnChange: FieldsChanged)
                    NumericChannelField(Title: "Saturation", Maximum: 100, Value: $Saturation, OnChange: FieldsChanged)
                    NumericChannelField(Title: "Brightness", Maximum: 100, Value: $Brightness, OnChange: FieldsChanged)
                }
                .padding()
                Spacer()
                SwatchColorView(TheColor: SearchColor.ToColor, SideLength: 80)
                    .padding()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay
        {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.secondary, lineWidth: 1)
        }
        .padding()
        // Keep the fields in sync when the caller changes `SearchColor`, and on first appearance.
        .onChange(of: SearchColor, initial: true)
        {
            SyncFields()
        }
    }

    /// The color described by the current field text. Empty or invalid fields count as `0`.
    private var ColorFromFields: PlatformColor
    {
        return Convert.FromHSB(H: Double(Hue) ?? 0, S: Double(Saturation) ?? 0, B: Double(Brightness) ?? 0)
    }

    /// Called whenever a field's text changes to a valid number.
    private func FieldsChanged()
    {
        SearchColor = ColorFromFields
    }

    /// Update the fields from `SearchColor`.
    ///
    /// Colors are stored as 8-bit RGB, so converting back to HSB is lossy (a gray has no hue, for example). If the fields
    /// already produce this color, they are left alone so the user's typing and hue aren't overwritten.
    private func SyncFields()
    {
        let Current = Convert.IntChannels(From: ColorFromFields)
        let Target = Convert.IntChannels(From: SearchColor)
        if Current == Target
        {
            return
        }
        let HSB = Convert.HSBChannels(From: SearchColor)
        Hue = "\(Int(HSB.h.rounded()) % 360)"
        Saturation = "\(Int(HSB.s.rounded()))"
        Brightness = "\(Int(HSB.b.rounded()))"
    }
}
