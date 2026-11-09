//
//  PaletteStripView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

/// The scratch palette: the colors marked in the main window, shown as small color views that can be removed.
struct PaletteStripView: View
{
    @Environment(PaletteSelection.self) var Palette
    
    var body: some View
    {
        VStack(alignment: .leading)
        {
            HStack
            {
                Text("Palette")
                    .font(.headline)
                Text("^[\(Palette.Count) color](inflect: true)")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Remove All", systemImage: "trash")
                {
                    Palette.Clear()
                }
                .disabled(Palette.IsEmpty)
            }
            if Palette.IsEmpty
            {
                Text("Click Select Colors in the main window, then click the colors to use.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            else
            {
                // Wraps onto as many rows as the pane's height allows and scrolls vertically beyond that.
                ScrollView(.vertical)
                {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), alignment: .leading)], alignment: .leading)
                    {
                        ForEach(Palette.Records)
                        {
                            Record in
                            PaletteChipView(Record: Record)
                            {
                                Palette.Remove([Record])
                            }
                        }
                    }
                }
                .scrollIndicators(.visible)
            }
        }
        .padding()
    }
}
