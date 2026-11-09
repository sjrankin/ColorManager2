//
//  CMYKValueSearch.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

/// Edit a color by cyan, magenta, yellow, and key (black), each `0` - `100`.
///
/// This uses the simple, profile-less CMYK conversion, so results won't match a print profile.
struct CMYKValueSearch: View
{
    @Binding var SearchColor: PlatformColor
    @State private var Cyan: String = "0"
    @State private var Magenta: String = "0"
    @State private var Yellow: String = "0"
    @State private var Key: String = "0"
    
    var body: some View
    {
        VStack
        {
            Text("CMYK")
                .font(.system(size: 36))
                .bold()
            Spacer()
            HStack
            {
                HStack
                {
                    NumericChannelField(Title: "Cyan", Maximum: 100, Value: $Cyan, OnChange: FieldsChanged)
                    NumericChannelField(Title: "Magenta", Maximum: 100, Value: $Magenta, OnChange: FieldsChanged)
                    NumericChannelField(Title: "Yellow", Maximum: 100, Value: $Yellow, OnChange: FieldsChanged)
                    NumericChannelField(Title: "Key", Maximum: 100, Value: $Key, OnChange: FieldsChanged)
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
        return Convert.FromCMYK(C: Double(Cyan) ?? 0, M: Double(Magenta) ?? 0,
                                Y: Double(Yellow) ?? 0, K: Double(Key) ?? 0)
    }
    
    /// Called whenever a field's text changes to a valid number.
    private func FieldsChanged()
    {
        SearchColor = ColorFromFields
    }
    
    /// Update the fields from `SearchColor`.
    ///
    /// Colors are stored as 8-bit RGB, so converting back to CMYK is lossy (at full black, cyan, magenta and yellow are
    /// undefined, for example). If the fields already produce this color, they are left alone so the user's typing isn't
    /// overwritten.
    private func SyncFields()
    {
        let Current = Convert.IntChannels(From: ColorFromFields)
        let Target = Convert.IntChannels(From: SearchColor)
        if Current == Target
        {
            return
        }
        let CMYK = Convert.CMYKChannels(From: SearchColor)
        Cyan = "\(Int(CMYK.c.rounded()))"
        Magenta = "\(Int(CMYK.m.rounded()))"
        Yellow = "\(Int(CMYK.y.rounded()))"
        Key = "\(Int(CMYK.k.rounded()))"
    }
}
