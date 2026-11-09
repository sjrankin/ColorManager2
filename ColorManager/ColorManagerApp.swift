//
//  ColorManagerApp.swift
//  ColorManager
//
//  Created by Stuart Rankin on 3/20/26.
//

import SwiftUI

@main
struct ColorManagerApp: App {
    @StateObject private var colorList = ColorList.shared
    /// The colors marked for use in a palette.
    @State private var paletteSelection = PaletteSelection()
    /// The image palettizer's image and result. Kept here so they survive closing and reopening its window.
    @State private var imageModel = ImagePalettizerModel()
    /// The user's settings, saved between runs.
    @State private var settings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(colorList)
                .environment(paletteSelection)
                .environment(settings)
                .environment(imageModel)
                .task {
                    loadStartupColors()
                }
        }

#if os(macOS)
        Window("Color Searcher", id: "color-searcher") {
            ColorSearchView()
                .environmentObject(colorList)
        }
        .defaultSize(width: 700, height: 520)
        .restorationBehavior(.disabled)
        
        // Separate from the main window so colors can be selected there while this stays open.
        Window("Image Palette", id: "image-palettizer") {
            ImagePalettizeView()
                .environment(paletteSelection)
                .environment(imageModel)
        }
        .defaultSize(width: 640, height: 720)
        .restorationBehavior(.disabled)
#endif
    }
    
    /// Load the colors to show at startup: the last color file the user loaded if they asked for that (and it can still
    /// be read), otherwise the built-in colors.
    private func loadStartupColors() {
        if settings.LoadLastFileAtStartup, let url = settings.LastFileURL {
            do {
                var importedData = try ColorListIO.parseXMLFile(url: url)
                // The data came from the app's private copy; show the name of the file the user originally loaded.
                importedData.sourceFileName = settings.LastFileName
                try colorList.loadFromImportedData(importedData)
                print("Loaded the last color file at startup: \(settings.LastFileName ?? url.lastPathComponent)")
                return
            } catch {
                print("Could not load the last color file (\(error.localizedDescription)); using the built-in colors.")
            }
        }
        loadInitialBaseColors()
    }
    
    /// Load the InitialBaseColors.xml file at app startup
    private func loadInitialBaseColors() {
        // Debug: Print all resources in bundle
        if let resourcePath = Bundle.main.resourcePath {
            print("Bundle resource path: \(resourcePath)")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                print("Bundle contents: \(contents)")
                let xmlFiles = contents.filter { $0.hasSuffix(".xml") }
                print("XML files found: \(xmlFiles)")
            }
        }
        
        guard let url = Bundle.main.url(forResource: "InitialBaseColors", withExtension: "xml") else {
            print("Error: InitialBaseColors.xml not found in bundle")
            
            // Try alternative search methods
            if let url = Bundle.main.url(forResource: "InitialBaseColors", withExtension: "xml", subdirectory: nil) {
                print("Found in alternative search: \(url)")
                loadFromURL(url)
                return
            }
            
            // Try with different case
            if let url = Bundle.main.url(forResource: "initialbasecolors", withExtension: "xml") {
                print("Found with lowercase: \(url)")
                loadFromURL(url)
                return
            }
            
            return
        }
        
        loadFromURL(url)
    }
    
    /// Load colors from a specific URL
    private func loadFromURL(_ url: URL) {
        do {
            let importedData = try ColorListIO.parseXMLFile(url: url)
            
            // Load the data into ColorList on the main thread
            Task { @MainActor in
                try? colorList.loadFromImportedData(importedData)
                print("Successfully loaded InitialBaseColors.xml from: \(url.lastPathComponent)")
                print("Total colors loaded: \(colorList.totalColorCount())")
            }
        } catch let error as ColorListError {
            print("Error loading InitialBaseColors.xml: \(error.localizedDescription)")
        } catch {
            print("Unexpected error loading InitialBaseColors.xml: \(error.localizedDescription)")
        }
    }
}
