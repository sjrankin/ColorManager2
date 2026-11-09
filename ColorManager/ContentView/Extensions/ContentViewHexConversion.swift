//
//  ContentViewHexConversion.swift
//  ColorManager
//
//  Created by Stuart Rankin on 4/13/26.
//

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Color Extension for Hex Conversion

extension Color
{
    /// Initialize a Color from a hex string (for example `FF0000`, `#FF0000`, `0xFF0000`, or with a trailing alpha byte).
    /// Parsing is done by `Convert.ParseHex` so it accepts exactly the same formats as the rest of the app. Strings that
    /// aren't valid hex colors produce gray.
    init(hexString: String)
    {
        guard let Parsed = Convert.ParseHex(hexString) else
        {
            self = Color.gray
            return
        }
        self = Color(.sRGB,
                     red: Double(Parsed.red) / 255.0,
                     green: Double(Parsed.green) / 255.0,
                     blue: Double(Parsed.blue) / 255.0,
                     opacity: Double(Parsed.alpha) / 255.0)
    }
}

