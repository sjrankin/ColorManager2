//
//  PaletteXMLWriter.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation

/// Writes a set of colors as a color list file, in the same XML format as the primary color list (a `Colors` element with a
/// `VersionBlock` and one `ColorGroup`), so it can be loaded back with the normal import.
enum PaletteXMLWriter
{
    /// The XML text for a palette.
    /// - Parameter Records: The colors, in the order they should be written.
    /// - Parameter Name: The name of the color group; usually the file's name.
    /// - Parameter Date: The date to record as the written date.
    static func XML(for Records: [ColorRecord], name Name: String, date Date: Date = Date()) -> String
    {
        let Formatter = DateFormatter()
        Formatter.locale = Locale(identifier: "en_US_POSIX")
        Formatter.dateFormat = "d-MMM-yyyy"
        let Today = Formatter.string(from: Date)
        
        var Lines: [String] = []
        Lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>")
        Lines.append("<Colors DefaultFont=\"Segoe UI\" EnableDebug=\"False\" AutoCapitalize=\"True\">")
        Lines.append("<VersionBlock Version=\"3\">")
        Lines.append("<FileVersion>")
        Lines.append("<Date>\(Today)</Date>")
        Lines.append("<Version>2.0</Version>")
        Lines.append("</FileVersion>")
        Lines.append("<DataVersion>")
        Lines.append("<Date>\(Today)</Date>")
        Lines.append("<Version>1.0</Version>")
        Lines.append("<ID>{\(UUID().uuidString.lowercased())}</ID>")
        Lines.append("</DataVersion>")
        Lines.append("<LegalBlock>")
        Lines.append("<Copyright>Palette saved from ColorManager</Copyright>")
        Lines.append("<Rights>Colors are as defined by their original sources.</Rights>")
        Lines.append("</LegalBlock>")
        Lines.append("<SaveData>")
        Lines.append("<Written Date=\"\(Today)\"/>")
        Lines.append("</SaveData>")
        Lines.append("</VersionBlock>")
        Lines.append("<ColorGroup Name=\"\(Escaped(Name))\" Id=\"\(UUID().uuidString.lowercased())\">")
        for Record in Records
        {
            Lines.append(ColorElement(for: Record))
        }
        Lines.append("</ColorGroup>")
        Lines.append("</Colors>")
        return Lines.joined(separator: "\n") + "\n"
    }
    
    /// The `<Color/>` element for a record.
    ///
    /// A record read from a file keeps its original element (so every color space, alternate name and tag survives), as long
    /// as that text is itself valid XML. Otherwise one is made from the record's name and color.
    static func ColorElement(for Record: ColorRecord) -> String
    {
        if let Original = Record.XMLDefinition, Original.hasPrefix("<Color"), IsValidXML(Original)
        {
            return Original
        }
        var Attributes = "Name=\"\(Escaped(Record.Name))\""
        if let RGB = ColorSearchEngine.RGBChannels(of: Record)
        {
            let Hex = ColorSpaceMath.ToByte(RGB.r).hex + ColorSpaceMath.ToByte(RGB.g).hex + ColorSpaceMath.ToByte(RGB.b).hex
            Attributes += " Hex=\"\(Hex.lowercased())\""
        }
        Attributes += " Id=\"\((Record.Id ?? UUID()).uuidString.lowercased())\""
        return "<Color \(Attributes)/>"
    }
    
    /// Escape text for use inside a double-quoted XML attribute.
    static func Escaped(_ Text: String) -> String
    {
        return Text.replacing("&", with: "&amp;")
            .replacing("<", with: "&lt;")
            .replacing(">", with: "&gt;")
            .replacing("\"", with: "&quot;")
    }
    
    private static func IsValidXML(_ Text: String) -> Bool
    {
        return XMLParser(data: Data(Text.utf8)).parse()
    }
    
    /// A group name for a file: the file's name without its extension.
    static func GroupName(forFile URL: URL) -> String
    {
        return URL.deletingPathExtension().lastPathComponent
    }
    
    // MARK: Merging
    
    enum MergeError: LocalizedError
    {
        case noColorGroup
        case cannotReadFile
        
        var errorDescription: String?
        {
            switch self
            {
                case .noColorGroup: return "That file has no color group to add the colors to."
                case .cannotReadFile: return "That file couldn't be read as text."
            }
        }
    }
    
    /// The outcome of a merge.
    struct MergeResult: Equatable
    {
        /// The updated file text.
        var Text: String
        var Added: Int
        /// Colors left out because the file already had a color with the same name and value.
        var Skipped: Int
    }
    
    /// Add colors to the end of the last color group in an existing color list's text. Everything else in the file is left
    /// exactly as it was.
    /// - Parameter Records: The colors to add.
    /// - Parameter Text: The existing file's text.
    /// - Parameter Existing: The colors already in the file, used to skip duplicates (same name and same color).
    static func Merged(_ Records: [ColorRecord], into Text: String, existing Existing: [ColorRecord]) throws -> MergeResult
    {
        guard let Closing = Text.ranges(of: "</ColorGroup>").last else
        {
            throw MergeError.noColorGroup
        }
        var Known = Set(Existing.map(Key))
        var Lines: [String] = []
        var Skipped = 0
        for Record in Records
        {
            if Known.insert(Key(Record)).inserted
            {
                Lines.append(ColorElement(for: Record))
            }
            else
            {
                Skipped += 1
            }
        }
        if Lines.isEmpty
        {
            return MergeResult(Text: Text, Added: 0, Skipped: Skipped)
        }
        var Result = Text
        Result.insert(contentsOf: Lines.joined(separator: "\n") + "\n", at: Closing.lowerBound)
        return MergeResult(Text: Result, Added: Lines.count, Skipped: Skipped)
    }
    
    /// Merge colors into the color list file at `URL`, rewriting it in place.
    static func Merge(_ Records: [ColorRecord], intoFileAt URL: URL) throws -> MergeResult
    {
        let Scoped = URL.startAccessingSecurityScopedResource()
        defer { if Scoped { URL.stopAccessingSecurityScopedResource() } }
        
        let Data = try Data(contentsOf: URL)
        guard let Text = String(data: Data, encoding: .utf8) else
        {
            throw MergeError.cannotReadFile
        }
        let Existing = try AllColors(in: ColorListIO.parseXMLFile(url: URL))
        let Result = try Merged(Records, into: Text, existing: Existing)
        if Result.Added > 0
        {
            try Foundation.Data(Result.Text.utf8).write(to: URL)
        }
        return Result
    }
    
    /// Every color in imported data, including colors in nested groups.
    static func AllColors(in Imported: ImportedColorData) -> [ColorRecord]
    {
        var Found: [ColorRecord] = Imported.colorRecords ?? []
        func Gather(_ Group: ColorGroup)
        {
            Found.append(contentsOf: Group.Colors ?? [])
            Group.Groups?.forEach(Gather)
        }
        (Imported.fullColors?.ColorGroups ?? Imported.colorGroups ?? []).forEach(Gather)
        return Found
    }
    
    /// Identity for duplicate checks: the name (ignoring case) and the 8-bit color.
    private static func Key(_ Record: ColorRecord) -> String
    {
        var Value = "none"
        if let RGB = ColorSearchEngine.RGBChannels(of: Record)
        {
            Value = "\(ColorSpaceMath.ToByte(RGB.r)),\(ColorSpaceMath.ToByte(RGB.g)),\(ColorSpaceMath.ToByte(RGB.b))"
        }
        return Record.Name.lowercased() + "|" + Value
    }
}
