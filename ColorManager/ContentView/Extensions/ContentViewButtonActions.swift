//
//  ContentViewButtonActions.swift
//  ColorManager
//
//  Created by Stuart Rankin on 4/13/26.
//

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Button Actions

extension ContentView
{
    func handleEdit()
    {
        // TODO: Implement edit functionality
    }
    
    func handleCamera()
    {
        ShowCameraMatchView.toggle()
    }
    
    func handleSearch()
    {
        ShowColorSearchView.toggle()
    }
    
    /// Open the image palettizer. On macOS it is a separate window, so colors can be selected in the main window while it
    /// is open; on iOS it is a sheet that lets the main window stay usable behind it.
    func handleImage()
    {
#if os(macOS)
        openWindow(id: "image-palettizer")
#else
        ShowImagePalettizer = true
#endif
    }
    
    /// Called once the palette file has been written. Rewrites it so the color group is named after the file the user chose.
    func FinishSavingPalette(to URL: URL)
    {
        let Text = PaletteXMLWriter.XML(for: Palette.Records, name: PaletteXMLWriter.GroupName(forFile: URL))
        do
        {
            try Data(Text.utf8).write(to: URL)
        }
        catch
        {
            PaletteMessage = error.localizedDescription
        }
    }
    
    /// Add the marked colors to an existing palette file and report what happened.
    func MergePalette(into URL: URL)
    {
        do
        {
            let Result = try PaletteXMLWriter.Merge(Palette.Records, intoFileAt: URL)
            var Message = "Added \(Result.Added) of \(Palette.Count) colors to \(URL.lastPathComponent)."
            if Result.Skipped > 0
            {
                Message += " \(Result.Skipped) already in the file."
            }
            PaletteMessage = Message
        }
        catch
        {
            PaletteMessage = error.localizedDescription
        }
    }
    
    func handleFilter()
    {
        // TODO: Implement filter functionality
    }
    
    func handleImport()
    {
        NSLog("🔵 Import button tapped")
        print("🔵 Import button tapped")
#if os(macOS)
        print("✓ Running on macOS")
#else
        print("⚠️ Not running on macOS - import won't work")
#endif
        
        ColorListIO.importColorList { result in
            handleImportResult(result)
        }
    }
    
    func handleExport()
    {
        // TODO: Implement export functionality
    }
    
    func ShowColorInfo()
    {
        ShowColorInfoPanel.toggle()
    }
    
    func clearSelection()
    {
        SelectedSwatch = UUID.empty
    }
}
