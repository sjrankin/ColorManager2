//
//  ColorList.swift
//  ColorManager
//
//  Created by Stuart Rankin on 3/30/26.
//

import Foundation
import Combine

/// Central storage for imported color data
/// Thread-safe via @MainActor annotation
@MainActor class ColorList: ObservableObject
{
    // MARK: - Singleton
    
    /// Shared instance
    static let shared = ColorList()
    
    /// Private initializer for singleton
    private init() {}
    
    // MARK: - Published Properties
    
    /// Header/versioning information from imported file
    /// Will be nil for imports that don't include full structure
    @Published var header: VersionBlock? = nil
    
    /// All color groups from imported file
    @Published var colorGroups: [ColorGroup]? = nil
    
    /// Set to ask the main window to open a color's group and highlight it. The main window clears it once handled.
    @Published var RevealRequest: ColorRevealRequest? = nil
    
    /// Publisher that emits when color data changes
    let didChangePublisher = PassthroughSubject<Void, Never>()
    
    // MARK: - Metadata
    
    /// Last import date
    var lastImportDate: Date?
    
    /// Source file name of last import
    var sourceFileName: String?
    
    // MARK: - Public Methods
    
    /// Load color data from imported XML
    /// - Parameter data: The imported color data
    /// - Throws: ColorListError if data is invalid or doesn't contain groups
    func loadFromImportedData(_ data: ImportedColorData) throws
    {
        // Validate that we have group-based data
        switch data.importType
        {
            case .fullStructure:
                guard let fullColors = data.fullColors,
                      let groups = fullColors.ColorGroups,
                      !groups.isEmpty else
                {
                    throw ColorListError.noColorsDefined
                }
                
                // Replace existing data
                clear()
                
                // Load header and groups
                header = fullColors.Versioning
                colorGroups = groups
                
            case .groups:
                guard let groups = data.colorGroups,
                      !groups.isEmpty else
                {
                    throw ColorListError.noColorsDefined
                }
                
                // Replace existing data
                clear()
                
                // Load groups (no header for groups-only import)
                header = nil
                colorGroups = groups
                
            case .records:
                // Reject imports without groups
                throw ColorListError.unsupportedFormat
        }
        
        // Update metadata
        lastImportDate = Date()
        sourceFileName = data.sourceFileName
        
        // Notify subscribers
        didChangePublisher.send()
    }
    
    /// Clear all data
    func clear()
    {
        header = nil
        colorGroups = nil
        lastImportDate = nil
        sourceFileName = nil
    }
    
    /// Get total count of all colors recursively
    /// - Returns: Total number of colors across all groups
    func totalColorCount() -> Int
    {
        guard let groups = colorGroups else { return 0 }
        return groups.reduce(0) { $0 + countColorsInGroup($1) }
    }
    
    // MARK: - Private Helper Methods
    
    /// Recursively count all colors in a ColorGroup
    private func countColorsInGroup(_ group: ColorGroup) -> Int
    {
        var count = 0
        
        // Count direct colors
        if let colors = group.Colors
        {
            count += colors.count
        }
        
        // Count colors in nested groups
        if let nestedGroups = group.Groups
        {
            for nestedGroup in nestedGroups
            {
                count += countColorsInGroup(nestedGroup)
            }
        }
        
        // Count colors in collections
        if let collections = group.Collections
        {
            for collection in collections
            {
                count += countColorsInCollection(collection)
            }
        }
        
        return count
    }
    
    /// Recursively count all colors in a ColorCollection
    private func countColorsInCollection(_ collection: ColorCollection) -> Int
    {
        var count = 0
        
        // Count direct colors
        if let colors = collection.Colors
        {
            count += colors.count
        }
        
        // Count colors in nested collections
        if let nestedCollections = collection.Collections
        {
            for nestedCollection in nestedCollections
            {
                count += countColorsInCollection(nestedCollection)
            }
        }
        
        return count
    }
}
