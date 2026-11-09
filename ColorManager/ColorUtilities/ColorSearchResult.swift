//
//  ColorSearchResult.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation

/// One color found by a search.
struct ColorSearchResult: Identifiable
{
    let id = UUID()
    /// The matching color.
    let Record: ColorRecord
    /// The names of the groups and collections that contain the color, outermost first.
    let PathComponents: [String]
    /// `PathComponents` as text, for example `Web > Reds`.
    var Path: String
    {
        return PathComponents.joined(separator: " > ")
    }
    /// For value searches, the color difference (Delta E) from the searched color. `nil` for name searches.
    let Distance: Double?
}
