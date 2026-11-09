//
//  SearchResultsView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

/// Lists the colors found by a search.
struct SearchResultsView: View
{
    @Environment(\.dismiss) var Dismiss
    let Results: [ColorSearchResult]
    /// For value searches by color distance, the formula that produced each result's `Distance`.
    var Method: ColorDifferenceMethods? = nil
    /// Called when the user double-clicks a result (macOS) to show that color in the main window.
    var OnReveal: ((ColorSearchResult) -> Void)? = nil
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Search Results")
                .font(.title2)
                .padding()
            Text("^[\(Results.count) color](inflect: true) found")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let Method
            {
                Text("Δ is \(Method.rawValue) color difference")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
#if os(macOS)
            if OnReveal != nil
            {
                Text("Double-click a color to show it in the main window")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
#endif
            Spacer()
                .frame(height: 8)
            Divider()
            if Results.isEmpty
            {
                Spacer()
                Text("No matching colors")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            else
            {
                List(Results)
                {
                    Result in
                    SearchResultRow(Result: Result)
#if os(macOS)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2)
                        {
                            OnReveal?(Result)
                        }
#endif
                }
                .listStyle(.plain)
            }
            Divider()
            Button("Done")
            {
                Dismiss()
            }
            .padding()
        }
        .frame(minWidth: 380, minHeight: 360)
    }
}

/// One row of search results: swatch, name, path, and (for value searches) how far the color is from the target.
struct SearchResultRow: View
{
    let Result: ColorSearchResult
    
    var body: some View
    {
        HStack
        {
            RoundedRectangle(cornerRadius: 4)
                .fill(SwatchColor)
                .frame(width: 36, height: 36)
                .overlay(RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(.primary.opacity(0.15), lineWidth: 0.5))
            VStack(alignment: .leading)
            {
                Text(Result.Record.Name)
                Text(Result.Path)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let Distance = Result.Distance
            {
                Text("Δ \(Distance, format: .number.precision(.fractionLength(1)))")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    /// The record's color, or clear if it has none.
    private var SwatchColor: Color
    {
        guard let RGB = ColorSearchEngine.RGBChannels(of: Result.Record) else
        {
            return .clear
        }
        return Color(.sRGB, red: RGB.r, green: RGB.g, blue: RGB.b, opacity: 1.0)
    }
}
