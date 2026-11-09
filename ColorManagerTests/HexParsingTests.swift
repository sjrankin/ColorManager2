//
//  HexParsingTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI
import Testing
@testable import ColorManager

@Suite("Hex parsing")
struct HexParsingTests
{
    // MARK: Convert.ParseHex
    
    @Test("Accepted formats", arguments: [
        "FF8000", "ff8000", "#FF8000", "#ff8000", "0xFF8000", "0Xff8000", "  FF8000\n", "FF8000FF",
    ])
    func AcceptsFormats(_ Text: String)
    {
        let Parsed = Convert.ParseHex(Text)
        #expect(Parsed?.red == 255)
        #expect(Parsed?.green == 128)
        #expect(Parsed?.blue == 0)
        #expect(Parsed?.alpha == 255)
    }
    
    @Test func ReadsAlpha()
    {
        #expect(Convert.ParseHex("FF800080")?.alpha == 128)
        #expect(Convert.ParseHex("#00000000")?.alpha == 0)
    }
    
    @Test("Rejected input", arguments: [
        "", "#", "0x", "FF80", "FF80001", "FF800000F", "GG0000", "+F8000", "-F8000", "FF 000", "ＦＦ8000", "FF8000ZZ",
    ])
    func RejectsBadInput(_ Text: String)
    {
        #expect(Convert.ParseHex(Text) == nil)
        #expect(Convert.ParseHexChannels(Text) == nil)
    }
    
    @Test func InvalidHexConvertsToBlack()
    {
        let Channels = Convert.FromHexToChannels("nonsense")
        #expect(Channels.red == 0 && Channels.green == 0 && Channels.blue == 0)
    }
    
    // MARK: Agreement between all hex readers
    
    /// The channels `Color(hexString:)` produces, as bytes.
    private func ColorChannels(_ Text: String) -> (Int, Int, Int, Int)
    {
        let Resolved = Color(hexString: Text).resolve(in: EnvironmentValues())
        func Byte(_ Value: Float) -> Int { Int((Double(Value) * 255.0).rounded()) }
        return (Byte(Resolved.red), Byte(Resolved.green), Byte(Resolved.blue), Byte(Resolved.opacity))
    }
    
    @Test("Color(hexString:) agrees with Convert", arguments: [
        "FF8000", "#FF8000", "0xFF8000", "ff8000", "336699", "FF800080", "000000", "FFFFFF",
    ])
    func ColorInitAgreesWithConvert(_ Text: String)
    {
        let Expected = Convert.ParseHex(Text)
        let Actual = ColorChannels(Text)
        #expect(Expected != nil)
        #expect(Actual.0 == Expected?.red)
        #expect(Actual.1 == Expected?.green)
        #expect(Actual.2 == Expected?.blue)
        #expect(Actual.3 == Expected?.alpha)
    }
    
    @Test("Color(hexString:) falls back to gray exactly when Convert rejects the text", arguments: [
        "", "FF80", "GG0000", "+F8000",
    ])
    func ColorInitFallsBackToGray(_ Text: String)
    {
        #expect(Convert.ParseHex(Text) == nil)
        let Gray = Color.gray.resolve(in: EnvironmentValues())
        let Actual = Color(hexString: Text).resolve(in: EnvironmentValues())
        #expect(abs(Actual.red - Gray.red) < 0.001)
        #expect(abs(Actual.green - Gray.green) < 0.001)
    }
    
    @Test("createHexRecord agrees with Convert", arguments: [
        "FF8000", "#ff8000", "0xFF8000", "FF800080", "GG0000", "+F8000", "FF80", "",
    ])
    func HexRecordAgreesWithConvert(_ Text: String)
    {
        let Record = ColorListIO.createHexRecord(from: Text)
        #expect((Record != nil) == (Convert.ParseHex(Text) != nil))
        if let Record
        {
            // Stored without a prefix, upper case, and readable by the same parser.
            #expect(!Record.HexValue.hasPrefix("#") && !Record.HexValue.lowercased().hasPrefix("0x"))
            #expect(Record.HexValue == Record.HexValue.uppercased())
            #expect(Convert.ParseHex(Record.HexValue)?.red == Convert.ParseHex(Text)?.red)
        }
    }
    
    @Test func HexRecordChannelsAreNotBlack()
    {
        // `rgbToHex` produces `RRGGBB`; the record's channels used to decode that as black.
        let Hex = ColorListIO.rgbToHex(r: 255, g: 128, b: 0)
        #expect(Hex == "FF8000")
        let Record = ColorListIO.createHexRecord(from: Hex ?? "")
        #expect(Record?.Channels.red == 255)
        #expect(Record?.Channels.green == 128)
        #expect(Record?.Channels.blue == 0)
    }
    
    // MARK: Writing hex
    
    @Test func HexChannelsFormatsUpperCase()
    {
        let Color = Convert.FromRGB(255, 128, 10)
        #expect(Convert.HexChannels(From: Color) == "0xFF800A")
        #expect(Convert.HexChannels(From: Color, AddPrefix: false) == "FF800A")
    }
    
    @Test func HexStringRoundTrips()
    {
        for Value in [0, 1, 15, 16, 51, 127, 128, 200, 254, 255]
        {
            let Text = Convert.HexChannels(From: Convert.FromRGB(Value, Value, Value), AddPrefix: false)
            let Channels = Convert.FromHexToChannels(Text)
            #expect(Channels.red == Value && Channels.green == Value && Channels.blue == Value, "value \(Value) -> \(Text)")
        }
    }
}
