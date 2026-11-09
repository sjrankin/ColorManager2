//
//  ColorDifferenceTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Testing
@testable import ColorManager

@Suite("Color difference (Delta E)")
struct ColorDifferenceTests
{
    typealias Math = ColorSpaceMath
    typealias Lab = (l: Double, a: Double, b: Double)
    
    /// A published CIEDE2000 test pair and its expected result.
    struct Pair: CustomTestStringConvertible
    {
        let First: Lab
        let Second: Lab
        let Expected: Double
        
        var testDescription: String
        {
            return "\(First) vs \(Second)"
        }
    }
    
    /// Pairs from Sharma, Wu and Dalal, "The CIEDE2000 Color-Difference Formula: Implementation Notes, Supplementary
    /// Test Data, and Mathematical Observations" (2005), Table 1.
    nonisolated static let SharmaPairs: [Pair] =
    [
        Pair(First: (50, 2.6772, -79.7751), Second: (50, 0, -82.7485), Expected: 2.0425),
        Pair(First: (50, 3.1571, -77.2803), Second: (50, 0, -82.7485), Expected: 2.8615),
        Pair(First: (50, 2.8361, -74.0200), Second: (50, 0, -82.7485), Expected: 3.4412),
        Pair(First: (50, -1.3802, -84.2814), Second: (50, 0, -82.7485), Expected: 1.0000),
        Pair(First: (50, 0, 0), Second: (50, -1, 2), Expected: 2.3669),
        Pair(First: (50, 2.49, -0.001), Second: (50, -2.49, 0.0009), Expected: 7.1792),
        Pair(First: (50, 2.5, 0), Second: (50, 0, -2.5), Expected: 4.3065),
        Pair(First: (60.2574, -34.0099, 36.2677), Second: (60.4626, -34.1751, 39.4387), Expected: 1.2644),
        Pair(First: (2.0776, 0.0795, -1.1350), Second: (0.9033, -0.0636, -0.5514), Expected: 0.9082),
        Pair(First: (50, 2.5, 0), Second: (73, 25, -18), Expected: 27.1492),
    ]
    
    @Test("CIEDE2000 matches published data", arguments: SharmaPairs)
    func Ciede2000MatchesPublishedData(_ Case: Pair)
    {
        let Difference = Math.DeltaE2000(Case.First, Case.Second)
        #expect(abs(Difference - Case.Expected) < 5e-4)
        // The formula is symmetric.
        #expect(abs(Math.DeltaE2000(Case.Second, Case.First) - Difference) < 1e-9)
    }
    
    @Test func Cie76IsTheLabDistance()
    {
        #expect(abs(Math.DeltaE76((50, 0, 0), (50, 3, 4)) - 5.0) < 1e-12)
        #expect(Math.DeltaE76((20, 10, 10), (20, 10, 10)) == 0)
    }
    
    @Test(arguments: ColorDifferenceMethods.allCases)
    func IdenticalColorsDifferByZero(_ Method: ColorDifferenceMethods)
    {
        let Color = (r: 0.2, g: 0.5, b: 0.8)
        #expect(Math.DeltaE(From: Color, To: Color, Method: Method) < 1e-9)
    }
    
    @Test(arguments: ColorDifferenceMethods.allCases)
    func BlackAndWhiteAreFarApart(_ Method: ColorDifferenceMethods)
    {
        let Difference = Math.DeltaE(From: (0, 0, 0), To: (1, 1, 1), Method: Method)
        #expect(Difference > 90)
    }
    
    @Test func MethodsDisagreeOnSaturatedBlues()
    {
        // CIE76 overstates differences between saturated blues; CIEDE2000 corrects for that.
        let First = (r: 0.0, g: 0.0, b: 1.0)
        let Second = (r: 0.1, g: 0.0, b: 0.9)
        let Simple = Math.DeltaE(From: First, To: Second, Method: .CIE76)
        let Better = Math.DeltaE(From: First, To: Second, Method: .CIEDE2000)
        #expect(Simple > 0 && Better > 0)
        #expect(Better < Simple)
    }
    
    @Test func DefaultMethodIsCie76()
    {
        let First = (r: 1.0, g: 0.0, b: 0.0)
        let Second = (r: 0.9, g: 0.1, b: 0.0)
        #expect(Math.DeltaE(From: First, To: Second) == Math.DeltaE(From: First, To: Second, Method: .CIE76))
    }
}
