//
//  LastColorFileStore.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation

/// Keeps the app's own copy of the last color file the user loaded.
///
/// The app is sandboxed, so a file the user picked in an earlier run can't simply be opened again by its path. Keeping a
/// private copy in the app's own storage lets the app reload it at the next launch without any special permission, and
/// it keeps working if the original file is later moved or deleted.
struct LastColorFileStore
{
    /// The folder that holds the copy.
    let Directory: URL
    
    /// - Parameter Directory: Where to keep the copy. The default is a folder in the app's Application Support.
    init(Directory: URL = URL.applicationSupportDirectory.appending(path: "ColorManager", directoryHint: .isDirectory))
    {
        self.Directory = Directory
    }
    
    /// The location of the copy (which may not exist).
    var FileURL: URL
    {
        return Directory.appending(path: "LastColorFile.xml")
    }
    
    /// True if a copy has been saved.
    var Exists: Bool
    {
        return FileManager.default.fileExists(atPath: FileURL.path(percentEncoded: false))
    }
    
    /// Replace the stored copy with a copy of the file at `Source`.
    /// - Throws: If the source can't be read or the copy can't be written. The previous copy is left in place on failure.
    func Save(from Source: URL) throws
    {
        let Contents = try Data(contentsOf: Source)
        try FileManager.default.createDirectory(at: Directory, withIntermediateDirectories: true)
        try Contents.write(to: FileURL, options: .atomic)
    }
    
    /// Delete the stored copy, if there is one.
    func Remove()
    {
        try? FileManager.default.removeItem(at: FileURL)
    }
}
