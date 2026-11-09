//
//  ImageFile.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Reading images from files and writing them as PNG.
enum ImageFile
{
    /// What can go wrong reading or writing an image.
    enum ImageFileError: LocalizedError
    {
        case notAnImage(String)
        case couldNotEncode
        
        var errorDescription: String?
        {
            switch self
            {
                case .notAnImage(let Name): return "\"\(Name)\" could not be opened as an image."
                case .couldNotEncode: return "The image could not be converted to PNG."
            }
        }
    }
    
    /// Images with a side longer than this are scaled down when loaded, to keep memory use reasonable.
    static let MaximumDimension = 8192
    
    /// Read an image from a file.
    ///
    /// The image's orientation (for example from a camera's rotation flag) is applied, so the result looks the way it
    /// does in other apps. Images larger than `maxDimension` on a side are scaled down to fit.
    /// - Parameter URL: The file. Security-scoped URLs (from a file picker) are handled.
    /// - Throws: `ImageFileError.notAnImage` if the file can't be read as an image.
    static func Load(from URL: URL, maxDimension: Int = MaximumDimension) throws -> CGImage
    {
        let IsScoped = URL.startAccessingSecurityScopedResource()
        defer
        {
            if IsScoped
            {
                URL.stopAccessingSecurityScopedResource()
            }
        }
        guard let Source = CGImageSourceCreateWithURL(URL as CFURL, nil),
              CGImageSourceGetCount(Source) > 0 else
        {
            throw ImageFileError.notAnImage(URL.lastPathComponent)
        }
        
        // Ask for the image at its own size (or `maxDimension` if larger), with orientation applied.
        var LongSide = maxDimension
        if let Properties = CGImageSourceCopyPropertiesAtIndex(Source, 0, nil) as? [CFString: Any],
           let Width = Properties[kCGImagePropertyPixelWidth] as? Int,
           let Height = Properties[kCGImagePropertyPixelHeight] as? Int
        {
            LongSide = min(max(Width, Height), maxDimension)
        }
        let Options: [CFString: Any] =
        [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: LongSide,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let Image = CGImageSourceCreateThumbnailAtIndex(Source, 0, Options as CFDictionary) else
        {
            throw ImageFileError.notAnImage(URL.lastPathComponent)
        }
        return Image
    }
    
    /// The image encoded as PNG data.
    /// - Throws: `ImageFileError.couldNotEncode` if encoding fails.
    static func PNGData(from Image: CGImage) throws -> Data
    {
        let Output = NSMutableData()
        guard let Destination = CGImageDestinationCreateWithData(Output, UTType.png.identifier as CFString, 1, nil) else
        {
            throw ImageFileError.couldNotEncode
        }
        CGImageDestinationAddImage(Destination, Image, nil)
        guard CGImageDestinationFinalize(Destination) else
        {
            throw ImageFileError.couldNotEncode
        }
        return Output as Data
    }
}
