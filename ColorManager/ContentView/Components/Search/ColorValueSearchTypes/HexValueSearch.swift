//
//  HexValueSearch.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

struct HexValueSearch: View
{
    @Binding var SearchColor: PlatformColor
    @State private var Red: String = "0"
    @State private var Green: String = "0"
    @State private var Blue: String = "0"
    
    var body: some View
    {
        VStack
        {
            Text("Hex")
                .font(.system(size: 36))
                .bold()
            Spacer()
            HStack
            {
                HStack
                {
                    HexChannelField(Title: "Red", Value: $Red)
                    {
                        SearchColor = SearchColor.Replace(Channel: .Red, With: $0)
                    }
                    HexChannelField(Title: "Green", Value: $Green)
                    {
                        SearchColor = SearchColor.Replace(Channel: .Green, With: $0)
                    }
                    HexChannelField(Title: "Blue", Value: $Blue)
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
        if Int(Field, radix: 16) != Value
        {
            Field = Value.hex
        }
    }
}

/// A labeled text field that accepts only hex digits (at most two, shown upper-case), and reports each valid edit as
/// an integer in `0` - `255`.
struct HexChannelField: View
{
    let Title: String
    @Binding var Value: String
    let OnChange: (Int) -> Void
    
    var body: some View
    {
        VStack(alignment: .leading)
        {
            Text(Title)
            TextField("", text: $Value)
                .frame(maxWidth: 64)
                .monospaced()
                .onChange(of: Value)
            {
                _, New in
                let Cleaned = String(New.filter { $0.isASCII && $0.isHexDigit }.uppercased().prefix(2))
                if Cleaned != New
                {
                    Value = Cleaned
                }
                if let Number = Int(Cleaned, radix: 16)
                {
                    OnChange(Number)
                }
            }
        }
    }
}
