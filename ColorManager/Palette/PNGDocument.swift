//
//  PNGDocument.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI
import UniformTypeIdentifiers

/// PNG data to be written to a file chosen with `.fileExporter`.
struct PNGDocument: FileDocument
{
    nonisolated static var readableContentTypes: [UTType]
    {
        return [.png]
    }
    
    /// The encoded PNG file.
    var Contents: Data
    
    init(Contents: Data = Data())
    {
        self.Contents = Contents
    }
    
    nonisolated init(configuration: ReadConfiguration) throws
    {
        self.Contents = configuration.file.regularFileContents ?? Data()
    }
    
    nonisolated func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
    {
        return FileWrapper(regularFileWithContents: Contents)
    }
}
