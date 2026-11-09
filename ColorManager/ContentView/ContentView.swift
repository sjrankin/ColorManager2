//
//  ContentView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 3/20/26.
//

import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ContentView: View
{
    @EnvironmentObject var colorList: ColorList
    /// The colors marked for use in a palette.
    @Environment(PaletteSelection.self) var Palette
    /// The user's application settings.
    @Environment(AppSettings.self) var Settings
    /// Whether the Setup dialog is showing.
    @State var ShowSetup: Bool = false
    @State var ShowPaletteExporter: Bool = false
    @State var ShowPaletteMergePicker: Bool = false
    @State var PaletteDocument = ColorListDocument()
    @State var PaletteMessage: String?
    /// Whether the image palettizer sheet is showing (iOS; on macOS it is a separate window).
    @State var ShowImagePalettizer: Bool = false
    /// While true, tapping a color marks or unmarks it for the palette.
    @State var SelectingForPalette: Bool = false
    
    @State var ShowEditor: Bool = false
    @State var SearchColor: Bool = false
    @State var ShowCameraMatchView: Bool = false
    @State var SelectedSwatch: UUID = UUID.empty
    @State var selectedGroupPath: [String] = [] // Track selected group hierarchy
    @State var expandedGroups: Set<String> = [] // Track expanded groups
    @State var ShowColorInfoPanel: Bool = false
    @State var ShowColorSearchView: Bool = false
#if !os(macOS)
    @State var ShowStructureNavigator: Bool = false
#endif
    @AppStorage("ViewStyle") var ViewStyle: Int = 0
    @State var SelectedColorRecord: ColorRecord? = nil
    /// A color to select once the group it lives in has finished being selected (see `GroupPathChanged`).
    @State var PendingReveal: ColorRecord? = nil
    /// A color the lists should scroll to.
    @State var ScrollTarget: UUID? = nil
    
#if os(macOS)
    let GroupSpacer: Double = 16
#else
    let GroupSpacer: Double = 0.0
#endif
    
    #if os(macOS)
    @State var PaletteBackground: Color = Color(nsColor: NSColor.controlBackgroundColor)
    #else
    @State var PaletteBackground: Color = Color(UIColor.systemGray5)
    #endif
    
    // Use flexible columns that maintain consistent spacing
    let PaletteColumns =
    [
        GridItem(.adaptive(minimum: 90, maximum: 120), spacing: 8)
    ]
    
    var SwatchSize: CGFloat = 90

#if os(macOS)
    @Environment(\.openWindow) var openWindow
#endif

    var body: some View
    {
        VStack(spacing: 0)
        {
            toolbarView
            Divider()
            colorGridView
        }
        .onReceive(colorList.didChangePublisher)
        {
            // Newly loaded colors are different records, so earlier marks no longer refer to anything.
            Palette.Clear()
        }
        .onChange(of: colorList.RevealRequest)
        {
            _, Request in
            if let Request
            {
                Reveal(Request)
            }
        }
#if os(macOS)
        .onChange(of: ShowColorSearchView)
        { _, newValue in
            if newValue
            {
                openWindow(id: "color-searcher")
                ShowColorSearchView = false
            }
        }
#else
        .sheet(isPresented: $ShowColorSearchView)
        {
            ColorSearchView()
        }
#endif
#if !os(macOS)
        .sheet(isPresented: $ShowImagePalettizer)
        {
            // Allow the main window to be used while the sheet is half-height, so colors can be selected for the palette.
            ImagePalettizeView()
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
#endif
        .sheet(isPresented: $ShowSetup)
        {
            SetupView()
        }
        .fileExporter(isPresented: $ShowPaletteExporter,
                      document: PaletteDocument,
                      contentType: .xml,
                      defaultFilename: "Palette")
        {
            Result in
            switch Result
            {
                case .success(let URL): FinishSavingPalette(to: URL)
                case .failure(let Error): PaletteMessage = Error.localizedDescription
            }
        }
        .fileImporter(isPresented: $ShowPaletteMergePicker, allowedContentTypes: [.xml])
        {
            Result in
            switch Result
            {
                case .success(let URL): MergePalette(into: URL)
                case .failure(let Error): PaletteMessage = Error.localizedDescription
            }
        }
        .alert("Palette", isPresented: Binding(get: { PaletteMessage != nil },
                                                    set: { if !$0 { PaletteMessage = nil } }))
        {
            Button("OK", role: .cancel) { }
        }
        message:
        {
            Text(PaletteMessage ?? "")
        }
        .sheet(isPresented: $ShowCameraMatchView)
        {
            ColorCameraSearchView(Searcher: .constant(nil))
        }
    }
}

enum ViewStyles: Int
{
    case Swatches = 0
    case List = 1
    
    static func Is(_ Raw: Int) -> ViewStyles
    {
        guard let Converted = ViewStyles(rawValue: Raw) else { return .Swatches }
        return Converted
    }
}
