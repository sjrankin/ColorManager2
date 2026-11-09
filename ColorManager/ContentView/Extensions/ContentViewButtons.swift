//
//  ContentViewButtons.swift
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

// MARK: - Toolbar Buttons

extension ContentView
{
    var editButton: some View
    {
        Button(action: { handleEdit() })
        {
#if os(macOS)
       Text("Edit")
#else
            Image(systemName: "pencil")
#endif
        }
        .help("Edit the selected color")
        .toolbarButtonStyle()
    }
    
    var cameraButton: some View
    {
        Button(action: { handleCamera() })
        {
#if os(macOS)
            Text("Camera")
#else
            Image(systemName: "camera")
#endif
        }
        .help("Use the system's camera to match a color")
        .toolbarButtonStyle(prominent: false)
    }
    
    var searchButton: some View
    {
        Button(action: { handleSearch() })
        {
#if os(macOS)
            Text("Search")
#else
            Image(systemName: "magnifyingglass")
#endif
        }
        .help("Search for colors")
        .toolbarButtonStyle(prominent: false)
    }
    
    var filterButton: some View
    {
        Button(action:
                {
            handleFilter()
        })
        {
#if os(macOS)
            Text("Filter")
#else
            Image(systemName: "line.3.horizontal.decrease.circle")
#endif
        }
        .help("Filter colors")
        .toolbarButtonStyle(prominent: false)
    }
    
    var importButton: some View
    {
        Button(action: { handleImport() })
        {
#if os(macOS)
            Text("Import")
#else
            Image(systemName: "square.and.arrow.down")
#endif
        }
        .help("Import colors from a file")
        .toolbarButtonStyle(prominent: false)
    }
    
    var exportButton: some View
    {
        Button(action: { handleExport() })
        {
#if os(macOS)
            Text("Export")
#else
            Image(systemName: "square.and.arrow.up")
#endif
        }
        .help("Export colors to a file")
        .toolbarButtonStyle(prominent: false)
    }
    
    var paletteButton: some View
    {
        Button(action: { handleExport() })
        {
#if os(macOS)
            Text("Palette")
#else
            Image(systemName: "paintpalette")
#endif
        }
        .help("Create a palette and apply it to an image")
        .toolbarButtonStyle(prominent: false)
    }
    
    /// Opens the image palettizer dialog.
    var imageButton: some View
    {
        Button(action: { handleImage() })
        {
#if os(macOS)
            Text("Image")
#else
            Image(systemName: "photo")
#endif
        }
        .help("Recolor an image using selected colors as a palette")
        .toolbarButtonStyle(prominent: false)
    }
    
    /// Turns palette selection mode on or off. While it is on, tapping a color marks or unmarks it for the palette.
    var selectColorsButton: some View
    {
        Button(action: { SelectingForPalette.toggle() })
        {
#if os(macOS)
            Text(SelectingForPalette ? "Done Selecting" : "Select Colors")
#else
            Image(systemName: SelectingForPalette ? "checkmark.circle.fill" : "checkmark.circle")
#endif
        }
        .help("Mark colors to use in a palette")
        .toolbarButtonStyle(prominent: SelectingForPalette)
        .tint(SelectingForPalette ? .accentColor : nil)
    }
    
    /// Marks every color currently shown.
    var selectAllColorsButton: some View
    {
        Button(action: { Palette.Add(getAllColors()) })
        {
#if os(macOS)
            Text("Select All")
#else
            Image(systemName: "checklist.checked")
#endif
        }
        .help("Mark every color shown")
        .toolbarButtonStyle(prominent: false)
    }
    
    /// Unmarks every marked color, in every group.
    var clearSelectedColorsButton: some View
    {
        Button(action: { Palette.Clear() })
        {
#if os(macOS)
            Text("Clear Selection")
#else
            Image(systemName: "xmark.circle")
#endif
        }
        .help("Unmark all selected colors")
        .toolbarButtonStyle(prominent: false)
        .disabled(Palette.IsEmpty)
    }
    
    /// The palette selection controls: the mode toggle, and (while selecting or when colors are marked) select-all,
    /// clear, and a count.
    @ViewBuilder var paletteSelectionControls: some View
    {
        selectColorsButton
        if SelectingForPalette || !Palette.IsEmpty
        {
            selectAllColorsButton
            clearSelectedColorsButton
            savePaletteButton
            mergePaletteButton
            Text("\(Palette.Count) selected")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
    
    /// Saves the marked colors as a color list file with a name the user chooses.
    var savePaletteButton: some View
    {
        Button("Save Palette…", systemImage: "square.and.arrow.down")
        {
            PaletteDocument = ColorListDocument(Contents: Data(PaletteXMLWriter.XML(for: Palette.Records, name: "Palette").utf8))
            ShowPaletteExporter = true
        }
        .help("Save the selected colors as a color list file")
        .disabled(Palette.IsEmpty)
    }
    
    /// Adds the marked colors to a palette file that already exists.
    var mergePaletteButton: some View
    {
        Button("Add to File…", systemImage: "text.badge.plus")
        {
            ShowPaletteMergePicker = true
        }
        .help("Add the selected colors to an existing color list file")
        .disabled(Palette.IsEmpty)
    }
    
    var createColorButton: some View
    {
        Button(action: { handleExport() })
        {
#if os(macOS)
            Text("Create")
#else
            Image(systemName: "asterisk.circle.fill")
#endif
        }
        .help("Create a color using English or math")
        .toolbarButtonStyle(prominent: false)
    }
    
    var ViewBy: some View
    {
        Picker("", selection: $ViewStyle)
        {
            Image(systemName: "square.grid.2x2")
                .tag(0)
            Image(systemName: "list.bullet")
                .tag(1)
        }
        .pickerStyle(.segmented)
    }
    
#if !os(macOS)
    var structureButton: some View
    {
        Button(action: { ShowStructureNavigator.toggle() })
        {
            Image(systemName: ShowStructureNavigator ? "sidebar.left" : "sidebar.left")
        }
        .help("Show color structure")
        .toolbarButtonStyle(prominent: ShowStructureNavigator)
    }
#endif

    var setupButton: some View
    {
        Button(action: { ShowSetup = true })
        {
#if os(macOS)
            Text("Setup")
#else
            Image(systemName: "gearshape")
#endif
        }
        .help("Change application settings")
        .toolbarButtonStyle(prominent: false)
    }

    var infoButton: some View
    {
        Button(action: { ShowColorInfo() })
        {
#if os(macOS)
            Text("Color Info")
#else
            Image(systemName: ShowColorInfoPanel ? "info.circle.fill" : "info.circle")
#endif
        }
        .help("Show color information")
        .toolbarButtonStyle(prominent: false)
        .tint(ShowColorInfoPanel ? .accentColor : nil)
    }
}
