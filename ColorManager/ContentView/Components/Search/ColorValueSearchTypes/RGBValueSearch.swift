//
//  ColorValueSearchTypes.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

struct RGBValueSearch: View
{
    @Binding var SearchColor: PlatformColor
    @State private var Red: String = "0"
    @State private var Green: String = "0"
    @State private var Blue: String = "0"
    
    var body: some View
    {
        VStack
        {
            Text("RGB")
                .font(.system(size: 36))
                .bold()
            Spacer()
            HStack
            {
                HStack
                {
                    RGBChannelField(Title: "Red", Value: $Red)
                    {
                        SearchColor = SearchColor.Replace(Channel: .Red, With: $0)
                    }
                    RGBChannelField(Title: "Green", Value: $Green)
                    {
                        SearchColor = SearchColor.Replace(Channel: .Green, With: $0)
                    }
                    RGBChannelField(Title: "Blue", Value: $Blue)
                    {
                        SearchColor = SearchColor.Replace(Channel: .Blue, With: $0)
                    }
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
            let Channels = Convert.IntChannels(From: SearchColor)
            SyncField(&Red, to: Channels.red)
            SyncField(&Green, to: Channels.green)
            SyncField(&Blue, to: Channels.blue)
        }
    }
    
    /// Update a field's text only if it doesn't already represent `Value`, so typing isn't disturbed.
    private func SyncField(_ Field: inout String, to Value: Int)
    {
        if Int(Field) != Value
        {
            Field = "\(Value)"
        }
    }
}

/// A labeled text field that accepts only digits, clamps to `0` - `255`, and reports each valid edit.
struct RGBChannelField: View
{
    let Title: String
    @Binding var Value: String
    let OnChange: (String) -> Void
    
    var body: some View
    {
        VStack(alignment: .leading)
        {
            Text(Title)
            TextField("", text: $Value)
                .frame(maxWidth: 64)
                .onChange(of: Value)
                {
                    _, New in
                    var Cleaned = New.filter { $0.isASCII && $0.isNumber }
                    if let Number = Int(Cleaned), Number > 255
                    {
                        Cleaned = "255"
                    }
                    if Cleaned != New
                    {
                        Value = Cleaned
                    }
                    OnChange(Cleaned)
                }
        }
    }
}
