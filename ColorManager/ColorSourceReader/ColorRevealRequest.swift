//
//  ColorRevealRequest.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation

/// A request, from anywhere in the app, for the main window to show a color: open its group and highlight it.
struct ColorRevealRequest: Equatable
{
    /// Distinguishes requests, so asking for the same color twice is still a new request.
    let Token = UUID()
    /// The color to reveal.
    let Record: ColorRecord
    /// Names of the groups and collections containing the color, outermost first.
    let Path: [String]
}
