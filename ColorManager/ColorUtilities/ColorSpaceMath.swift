//
//  ColorSpaceMath.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation

/// Pure numeric conversions between color spaces. This is the single source of truth for color space math; it has no
/// UI dependencies so it can be tested in isolation.
///
/// Conventions (the same as used by the color records):
/// - RGB channels are `Double` values in `0.0` ... `1.0` and are gamma-encoded sRGB.
/// - Hue is in degrees (`0` ... `360`).
/// - Saturation, brightness/value, lightness, and the CMYK channels are percentages (`0` ... `100`).
/// - XYZ and Lab are relative to the D65 white point with `Y` of white equal to `1.0`.
enum ColorSpaceMath
{
    // MARK: - Constants

    /// D65 reference white, derived from the sRGB matrix so that white round-trips exactly through XYZ and Lab.
    static let WhiteX = 0.9504559271
    static let WhiteY = 1.0
    static let WhiteZ = 1.0890577507

    // MARK: - sRGB gamma

    /// Remove the sRGB transfer function from a channel.
    static func Linearize(_ Value: Double) -> Double
    {
        return Value <= 0.04045 ? Value / 12.92 : pow((Value + 0.055) / 1.055, 2.4)
    }

    /// Apply the sRGB transfer function to a linear channel.
    static func Encode(_ Value: Double) -> Double
    {
        return Value <= 0.0031308 ? Value * 12.92 : 1.055 * pow(Value, 1.0 / 2.4) - 0.055
    }

    // MARK: - HSB / HSV

    /// Convert sRGB to HSB.
    static func RGBToHSB(R: Double, G: Double, B: Double) -> (h: Double, s: Double, b: Double)
    {
        let MaxValue = max(R, G, B)
        let MinValue = min(R, G, B)
        let Delta = MaxValue - MinValue
        let Saturation = MaxValue == 0 ? 0.0 : Delta / MaxValue
        return (Hue(R: R, G: G, B: B, Max: MaxValue, Delta: Delta), Saturation * 100.0, MaxValue * 100.0)
    }

    /// Convert HSB to sRGB.
    static func HSBToRGB(H: Double, S: Double, B: Double) -> (r: Double, g: Double, b: Double)
    {
        let Sat = S / 100.0
        let Bright = B / 100.0
        let Chroma = Bright * Sat
        return FromHueChroma(H: H, Chroma: Chroma, Offset: Bright - Chroma)
    }

    // MARK: - HSL

    /// Convert sRGB to HSL.
    static func RGBToHSL(R: Double, G: Double, B: Double) -> (h: Double, s: Double, l: Double)
    {
        let MaxValue = max(R, G, B)
        let MinValue = min(R, G, B)
        let Delta = MaxValue - MinValue
        let Lightness = (MaxValue + MinValue) / 2.0
        let Saturation = Delta == 0 ? 0.0 : Delta / (1.0 - abs(2.0 * Lightness - 1.0))
        return (Hue(R: R, G: G, B: B, Max: MaxValue, Delta: Delta), Saturation * 100.0, Lightness * 100.0)
    }

    /// Convert HSL to sRGB.
    static func HSLToRGB(H: Double, S: Double, L: Double) -> (r: Double, g: Double, b: Double)
    {
        let Sat = S / 100.0
        let Light = L / 100.0
        let Chroma = (1.0 - abs(2.0 * Light - 1.0)) * Sat
        return FromHueChroma(H: H, Chroma: Chroma, Offset: Light - Chroma / 2.0)
    }

    // MARK: - CMYK

    /// Convert sRGB to (naive, profile-less) CMYK.
    static func RGBToCMYK(R: Double, G: Double, B: Double) -> (c: Double, m: Double, y: Double, k: Double)
    {
        let K = 1.0 - max(R, G, B)
        if K >= 1.0
        {
            return (0, 0, 0, 100)
        }
        let Denominator = 1.0 - K
        return ((1.0 - R - K) / Denominator * 100.0,
                (1.0 - G - K) / Denominator * 100.0,
                (1.0 - B - K) / Denominator * 100.0,
                K * 100.0)
    }

    /// Convert (naive, profile-less) CMYK to sRGB.
    static func CMYKToRGB(C: Double, M: Double, Y: Double, K: Double) -> (r: Double, g: Double, b: Double)
    {
        let Key = 1.0 - K / 100.0
        return ((1.0 - C / 100.0) * Key, (1.0 - M / 100.0) * Key, (1.0 - Y / 100.0) * Key)
    }

    // MARK: - XYZ

    /// Convert sRGB to CIE XYZ (D65).
    static func RGBToXYZ(R: Double, G: Double, B: Double) -> (x: Double, y: Double, z: Double)
    {
        let Rl = Linearize(R)
        let Gl = Linearize(G)
        let Bl = Linearize(B)
        return (0.4123907993 * Rl + 0.3575843394 * Gl + 0.1804807884 * Bl,
                0.2126390059 * Rl + 0.7151686788 * Gl + 0.0721923154 * Bl,
                0.0193308187 * Rl + 0.1191947798 * Gl + 0.9505321522 * Bl)
    }

    /// Convert CIE XYZ (D65) to sRGB. Results are clamped to `0.0` ... `1.0`.
    static func XYZToRGB(X: Double, Y: Double, Z: Double) -> (r: Double, g: Double, b: Double)
    {
        let Rl = 3.2409699419 * X - 1.5373831776 * Y - 0.4986107603 * Z
        let Gl = -0.9692436363 * X + 1.8759675015 * Y + 0.0415550574 * Z
        let Bl = 0.0556300797 * X - 0.2039769589 * Y + 1.0569715142 * Z
        return (Clamp(Encode(Clamp(Rl))), Clamp(Encode(Clamp(Gl))), Clamp(Encode(Clamp(Bl))))
    }

    // MARK: - Lab

    /// Convert CIE XYZ (D65) to CIE L*a*b*.
    static func XYZToLab(X: Double, Y: Double, Z: Double) -> (l: Double, a: Double, b: Double)
    {
        let Fx = LabF(X / WhiteX)
        let Fy = LabF(Y / WhiteY)
        let Fz = LabF(Z / WhiteZ)
        return (116.0 * Fy - 16.0, 500.0 * (Fx - Fy), 200.0 * (Fy - Fz))
    }

    /// Convert CIE L*a*b* to CIE XYZ (D65).
    static func LabToXYZ(L: Double, A: Double, B: Double) -> (x: Double, y: Double, z: Double)
    {
        let Fy = (L + 16.0) / 116.0
        let Fx = A / 500.0 + Fy
        let Fz = Fy - B / 200.0
        return (LabFInverse(Fx) * WhiteX, LabFInverse(Fy) * WhiteY, LabFInverse(Fz) * WhiteZ)
    }

    /// Convert sRGB to CIE L*a*b* (D65).
    static func RGBToLab(R: Double, G: Double, B: Double) -> (l: Double, a: Double, b: Double)
    {
        let XYZ = RGBToXYZ(R: R, G: G, B: B)
        return XYZToLab(X: XYZ.x, Y: XYZ.y, Z: XYZ.z)
    }

    /// Convert CIE L*a*b* (D65) to sRGB. Out-of-gamut colors are clamped.
    static func LabToRGB(L: Double, A: Double, B: Double) -> (r: Double, g: Double, b: Double)
    {
        let XYZ = LabToXYZ(L: L, A: A, B: B)
        return XYZToRGB(X: XYZ.x, Y: XYZ.y, Z: XYZ.z)
    }

    // MARK: - Color difference
    
    /// Color difference (Delta E) between two sRGB colors. `0` means identical; about `1` is the smallest difference
    /// people can notice under good conditions.
    /// - Parameter Method: The formula to use. CIEDE2000 matches perception better; CIE76 is simpler and faster.
    static func DeltaE(From First: (r: Double, g: Double, b: Double),
                       To Second: (r: Double, g: Double, b: Double),
                       Method: ColorDifferenceMethods = .CIE76) -> Double
    {
        let A = RGBToLab(R: First.r, G: First.g, B: First.b)
        let B = RGBToLab(R: Second.r, G: Second.g, B: Second.b)
        switch Method
        {
            case .CIE76: return DeltaE76(A, B)
            case .CIEDE2000: return DeltaE2000(A, B)
        }
    }
    
    /// CIE76: the Euclidean distance in Lab.
    static func DeltaE76(_ First: (l: Double, a: Double, b: Double),
                         _ Second: (l: Double, a: Double, b: Double)) -> Double
    {
        return sqrt(pow(First.l - Second.l, 2.0) + pow(First.a - Second.a, 2.0) + pow(First.b - Second.b, 2.0))
    }
    
    /// CIEDE2000 (with `kL = kC = kH = 1`), following Sharma, Wu and Dalal, "The CIEDE2000 Color-Difference Formula:
    /// Implementation Notes, Supplementary Test Data, and Mathematical Observations".
    static func DeltaE2000(_ First: (l: Double, a: Double, b: Double),
                           _ Second: (l: Double, a: Double, b: Double)) -> Double
    {
        func Degrees(_ Radians: Double) -> Double { Radians * 180.0 / .pi }
        func Radians(_ Degrees: Double) -> Double { Degrees * .pi / 180.0 }
        
        let C1 = sqrt(First.a * First.a + First.b * First.b)
        let C2 = sqrt(Second.a * Second.a + Second.b * Second.b)
        let MeanC = (C1 + C2) / 2.0
        let MeanC7 = pow(MeanC, 7.0)
        let G = 0.5 * (1.0 - sqrt(MeanC7 / (MeanC7 + pow(25.0, 7.0))))
        
        let A1 = (1.0 + G) * First.a
        let A2 = (1.0 + G) * Second.a
        let CPrime1 = sqrt(A1 * A1 + First.b * First.b)
        let CPrime2 = sqrt(A2 * A2 + Second.b * Second.b)
        
        func HuePrime(_ B: Double, _ APrime: Double) -> Double
        {
            if B == 0 && APrime == 0
            {
                return 0
            }
            let Hue = Degrees(atan2(B, APrime))
            return Hue < 0 ? Hue + 360.0 : Hue
        }
        let HPrime1 = HuePrime(First.b, A1)
        let HPrime2 = HuePrime(Second.b, A2)
        
        let DeltaL = Second.l - First.l
        let DeltaC = CPrime2 - CPrime1
        let ChromaProduct = CPrime1 * CPrime2
        
        var DeltaHue = 0.0
        if ChromaProduct != 0
        {
            DeltaHue = HPrime2 - HPrime1
            if DeltaHue > 180.0
            {
                DeltaHue -= 360.0
            }
            else if DeltaHue < -180.0
            {
                DeltaHue += 360.0
            }
        }
        let DeltaH = 2.0 * sqrt(ChromaProduct) * sin(Radians(DeltaHue / 2.0))
        
        let MeanL = (First.l + Second.l) / 2.0
        let MeanCPrime = (CPrime1 + CPrime2) / 2.0
        
        var MeanH = HPrime1 + HPrime2
        if ChromaProduct != 0
        {
            if abs(HPrime1 - HPrime2) <= 180.0
            {
                MeanH = (HPrime1 + HPrime2) / 2.0
            }
            else if HPrime1 + HPrime2 < 360.0
            {
                MeanH = (HPrime1 + HPrime2 + 360.0) / 2.0
            }
            else
            {
                MeanH = (HPrime1 + HPrime2 - 360.0) / 2.0
            }
        }
        
        let T = 1.0 - 0.17 * cos(Radians(MeanH - 30.0)) + 0.24 * cos(Radians(2.0 * MeanH))
            + 0.32 * cos(Radians(3.0 * MeanH + 6.0)) - 0.20 * cos(Radians(4.0 * MeanH - 63.0))
        let DeltaTheta = 30.0 * exp(-pow((MeanH - 275.0) / 25.0, 2.0))
        let MeanCPrime7 = pow(MeanCPrime, 7.0)
        let RC = 2.0 * sqrt(MeanCPrime7 / (MeanCPrime7 + pow(25.0, 7.0)))
        let SL = 1.0 + (0.015 * pow(MeanL - 50.0, 2.0)) / sqrt(20.0 + pow(MeanL - 50.0, 2.0))
        let SC = 1.0 + 0.045 * MeanCPrime
        let SH = 1.0 + 0.015 * MeanCPrime * T
        let RT = -sin(Radians(2.0 * DeltaTheta)) * RC
        
        let TermL = DeltaL / SL
        let TermC = DeltaC / SC
        let TermH = DeltaH / SH
        return sqrt(TermL * TermL + TermC * TermC + TermH * TermH + RT * TermC * TermH)
    }
    
    // MARK: - Helpers

    /// Convert a `0.0` ... `1.0` channel to a rounded `0` ... `255` integer.
    static func ToByte(_ Value: Double) -> Int
    {
        return Int((Clamp(Value) * 255.0).rounded())
    }

    /// Convert a rounded `0` ... `255` integer to a `0.0` ... `1.0` channel.
    static func FromByte(_ Value: Int) -> Double
    {
        return Double(min(max(Value, 0), 255)) / 255.0
    }

    private static func Clamp(_ Value: Double) -> Double
    {
        return min(max(Value, 0.0), 1.0)
    }

    /// Hue in degrees for an RGB triple.
    private static func Hue(R: Double, G: Double, B: Double, Max: Double, Delta: Double) -> Double
    {
        if Delta == 0
        {
            return 0
        }
        var Result: Double
        if Max == R
        {
            Result = (G - B) / Delta
        }
        else if Max == G
        {
            Result = (B - R) / Delta + 2.0
        }
        else
        {
            Result = (R - G) / Delta + 4.0
        }
        Result *= 60.0
        if Result < 0
        {
            Result += 360.0
        }
        return Result
    }

    /// Shared back end for HSB and HSL to RGB.
    private static func FromHueChroma(H: Double, Chroma: Double, Offset: Double) -> (r: Double, g: Double, b: Double)
    {
        var Hue = H.truncatingRemainder(dividingBy: 360.0)
        if Hue < 0
        {
            Hue += 360.0
        }
        let Section = Hue / 60.0
        let X = Chroma * (1.0 - abs(Section.truncatingRemainder(dividingBy: 2.0) - 1.0))
        var Triple: (Double, Double, Double)
        switch Int(Section)
        {
            case 0: Triple = (Chroma, X, 0)
            case 1: Triple = (X, Chroma, 0)
            case 2: Triple = (0, Chroma, X)
            case 3: Triple = (0, X, Chroma)
            case 4: Triple = (X, 0, Chroma)
            default: Triple = (Chroma, 0, X)
        }
        return (Triple.0 + Offset, Triple.1 + Offset, Triple.2 + Offset)
    }

    private static let LabDelta = 6.0 / 29.0

    private static func LabF(_ T: Double) -> Double
    {
        return T > pow(LabDelta, 3) ? cbrt(T) : T / (3.0 * LabDelta * LabDelta) + 4.0 / 29.0
    }

    private static func LabFInverse(_ T: Double) -> Double
    {
        return T > LabDelta ? T * T * T : 3.0 * LabDelta * LabDelta * (T - 4.0 / 29.0)
    }
}
