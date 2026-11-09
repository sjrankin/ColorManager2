//
//  ColorListIO.swift
//  ColorManager
//
//  Created by Stuart Rankin on 3/29/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Imported Color Data Structure

/// Container for imported color data from XML files
struct ImportedColorData
{
    /// Full Colors structure if complete XML found
    let fullColors: Colors?
    /// Color groups if found
    let colorGroups: [ColorGroup]?
    /// Individual color records if found
    let colorRecords: [ColorRecord]?
    /// Type of import performed
    let importType: ImportType
    /// Source file name
    var sourceFileName: String?
    /// The file the data was read from, if it came from a file.
    var sourceURL: URL? = nil
}

/// Type of XML structure that was imported
enum ImportType
{
    case fullStructure   // Complete Colors object with versioning
    case groups          // One or more ColorGroups
    case records         // Individual ColorRecords
}

// MARK: - Error Handling

/// Errors that can occur during color list import/export
enum ColorListError: LocalizedError
{
    case invalidXMLStructure
    case unsupportedFormat
    case invalidColorValues(String)
    case fileAccessDenied
    case parsingFailed(String)
    case noColorsDefined
    case invalidHexValue(String)
    case missingRequiredAttribute(String)
    
    var errorDescription: String?
    {
        switch self
        {
            case .invalidXMLStructure:
                return "The XML file structure is invalid or unrecognized."
            case .unsupportedFormat:
                return "This XML format is not supported."
            case .invalidColorValues(let details):
                return "Invalid color values: \(details)"
            case .fileAccessDenied:
                return "Unable to access the selected file."
            case .parsingFailed(let reason):
                return "Failed to parse XML: \(reason)"
            case .noColorsDefined:
                return "No colors were found in the file."
            case .invalidHexValue(let hex):
                return "Invalid hex color value: \(hex)"
            case .missingRequiredAttribute(let attr):
                return "Missing required attribute: \(attr)"
        }
    }
}

// MARK: - Main ColorListIO Class

/// Handles importing and exporting color lists from/to XML files
class ColorListIO
{
    /// Import a color list from an XML file using a file picker dialog
    /// - Parameter completion: Called with Result containing ImportedColorData or ColorListError
    static func importColorList(completion: @escaping (Result<ImportedColorData, ColorListError>) -> Void)
    {
#if os(macOS)
        importColorListMacOS(completion: completion)
#else
        // For iOS, this should be called from a SwiftUI view using .fileImporter
        // See importColorListSwiftUI() for SwiftUI integration
        completion(.failure(.unsupportedFormat))
#endif
    }
    
#if os(macOS)
    /// macOS-specific file picker using NSOpenPanel
    private static func importColorListMacOS(completion: @escaping (Result<ImportedColorData, ColorListError>) -> Void)
    {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.xml]
        panel.message = "Select a color list XML file to import"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else
            {
                completion(.failure(.fileAccessDenied))
                return
            }
            
            do
            {
                let importedData = try parseXMLFile(url: url)
                completion(.success(importedData))
            }
            catch let error as ColorListError
            {
                completion(.failure(error))
            }
            catch
            {
                completion(.failure(.parsingFailed(error.localizedDescription)))
            }
        }
    }
#endif
    
    /// Parse an XML file from a given URL
    /// - Parameter url: URL to the XML file
    /// - Returns: ImportedColorData structure
    /// - Throws: ColorListError if parsing fails
    static func parseXMLFile(url: URL) throws -> ImportedColorData
    {
        // Try to read the file data with explicit UTF-8 encoding
        guard let data = try? Data(contentsOf: url) else
        {
            throw ColorListError.fileAccessDenied
        }
        
        // Log file encoding info
        if let xmlString = String(data: data, encoding: .utf8) {
            print("📄 XML file size: \(data.count) bytes, \(xmlString.count) characters")
            print("📄 Contains non-ASCII: \(xmlString.contains(where: { !$0.isASCII }))")
        } else {
            print("⚠️ Warning: Could not read file as UTF-8")
        }
        
        let parser = XMLParser(data: data)
        let delegate = ColorListXMLParser()
        parser.delegate = delegate
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false
        parser.shouldResolveExternalEntities = false
        
        guard parser.parse() else
        {
            if let error = delegate.parsingError
            {
                throw error
            }
            throw ColorListError.parsingFailed("Unknown parsing error")
        }
        
        // Determine what was parsed and return appropriate structure
        if let fullColors = delegate.parsedColors
        {
            return ImportedColorData(
                fullColors: fullColors,
                colorGroups: nil,
                colorRecords: nil,
                importType: .fullStructure,
                sourceFileName: url.lastPathComponent,
                sourceURL: url
            )
        }
        else if !delegate.parsedColorGroups.isEmpty
        {
            return ImportedColorData(
                fullColors: nil,
                colorGroups: delegate.parsedColorGroups,
                colorRecords: nil,
                importType: .groups,
                sourceFileName: url.lastPathComponent,
                sourceURL: url
            )
        }
        else if !delegate.parsedColorRecords.isEmpty
        {
            return ImportedColorData(
                fullColors: nil,
                colorGroups: nil,
                colorRecords: delegate.parsedColorRecords,
                importType: .records,
                sourceFileName: url.lastPathComponent,
                sourceURL: url
            )
        }
        else
        {
            throw ColorListError.noColorsDefined
        }
    }
    
    
    
    // MARK: - Default Version Block Creation
    
    /// Create a default version block for imported colors
    static func createDefaultVersionBlock() -> VersionBlock
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        
        return VersionBlock(FileVersion: FileVersionBlock(Date: currentDate,
                                                          Version: "1.0"),
                            DataVersion: DataVersionBlock(DataDate: currentDate,
                                                          Version: "1.0",
                                                          DataID: UUID()),
                            LegalText: LegalTextBlock(Copyright: "Imported",
                                                      Rights: "Unknown"),
                            SaveData: DataVersionBlock(DataDate: currentDate,
                                                       Version: "1.0",
                                                       DataID: UUID()))
    }
}

