//
//  ColorDifferenceMethods.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation

/// Ways of measuring how different two colors look (Delta E).
enum ColorDifferenceMethods: String, CaseIterable, Identifiable
{
    var id: String
    {
        rawValue
    }
    
    /// Euclidean distance in Lab. Fast and simple but overstates differences in saturated colors.
    case CIE76 = "CIE76"
    /// The CIEDE2000 formula, which matches perceived differences much better, especially for saturated colors and blues.
    case CIEDE2000 = "CIEDE2000"
}
