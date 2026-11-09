//
//  ImagePalettizeView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI
import UniformTypeIdentifiers

/// Dialog for recoloring an image with the palette of colors marked in the main window.
struct ImagePalettizeView: View
{
    @Environment(PaletteSelection.self) var Palette
    @Environment(ImagePalettizerModel.self) var Model
    @State private var IsImporting = false
    @State private var IsExporting = false
    @State private var IsDropTargeted = false
    @State private var ExportDocument = PNGDocument()
    /// Height of the palette pane; the user drags the divider above it to change this.
    @State private var PaletteHeight: Double = 90

    var body: some View
    {
        @Bindable var BoundModel = Model
        VStack(spacing: 0)
        {
            Text("Image Palette")
                .font(.title2)
                .padding()
            if let Name = Model.SourceName
            {
                Text(Name)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Divider()
            ImagePreviewView(Source: Model.SourceImage,
                             Result: Model.ResultImage,
                             Live: Model.LiveImage,
                             ShowOriginal: $BoundModel.ShowOriginal,
                             IsBusy: Model.IsBusy,
                             IsDropTargeted: IsDropTargeted)
            if Model.ResultImage != nil && !Model.ResultIsCurrent(for: Palette.IDs)
            {
                Text("The palette has changed since this image was palettized.")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
            PaneDividerView(Height: $PaletteHeight, Range: 70...500)
            PaletteStripView()
                .frame(height: PaletteHeight)
            Divider()
            if Model.IsCameraRunning
            {
                HStack
                {
                    Toggle("Palettize live", isOn: $BoundModel.PalettizeLive)
                    Spacer()
                    Button("Capture", systemImage: "camera.shutter.button")
                    {
                        Task { await Model.CaptureFrame() }
                    }
                    .help("Stop the camera and keep the current frame")
                }
                .padding([.horizontal, .top])
            }
            HStack
            {
                Button("Open Image…", systemImage: "photo")
                {
                    IsImporting = true
                }
                .disabled(Model.IsCameraRunning)
                Button(Model.IsCameraRunning ? "Stop Camera" : "Camera",
                       systemImage: Model.IsCameraRunning ? "video.slash" : "video")
                {
                    Task
                    {
                        if Model.IsCameraRunning
                        {
                            await Model.StopCamera()
                        }
                        else
                        {
                            await Model.StartCamera
                            {
                                (colors: Palette.PaletteColors, ids: Palette.IDs)
                            }
                        }
                    }
                }
                Spacer()
                Button("Palettize", systemImage: "paintpalette")
                {
                    Task
                    {
                        await Model.Palettize(colors: Palette.PaletteColors, ids: Palette.IDs)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!Model.CanPalettize(colorCount: Palette.Count))
                Button("Reset", systemImage: "arrow.uturn.backward")
                {
                    Model.ResetToOriginal()
                }
                .help("Discard the palettized image and go back to the original")
                .disabled(Model.ResultImage == nil || Model.IsBusy)
                Spacer()
                Button("Save Image…", systemImage: "square.and.arrow.down")
                {
                    if let Data = Model.ResultPNGData()
                    {
                        ExportDocument = PNGDocument(Contents: Data)
                        IsExporting = true
                    }
                }
                .disabled(Model.ResultImage == nil || Model.IsBusy)
            }
            .padding()
        }
        .frame(minWidth: 520, minHeight: 480)
        .onDisappear
        {
            Task { await Model.StopCamera() }
        }
        .fileImporter(isPresented: $IsImporting, allowedContentTypes: [.image])
        {
            Result in
            switch Result
            {
                case .success(let URL): Model.LoadImage(from: URL)
                case .failure(let Error): Model.ErrorMessage = Error.localizedDescription
            }
        }
        .fileExporter(isPresented: $IsExporting,
                      document: ExportDocument,
                      contentType: .png,
                      defaultFilename: Model.SuggestedResultName)
        {
            Result in
            if case .failure(let Error) = Result
            {
                Model.ErrorMessage = Error.localizedDescription
            }
        }
#if os(macOS)
        .dropDestination(for: URL.self)
        {
            URLs, _ in
            guard let First = URLs.first else
            {
                return false
            }
            Model.LoadImage(from: First)
            return true
        }
        isTargeted:
        {
            IsDropTargeted = $0
        }
#endif
        .alert("Image Palette", isPresented: Binding(get: { Model.ErrorMessage != nil },
                                                     set: { if !$0 { Model.ErrorMessage = nil } }))
        {
            Button("OK", role: .cancel) { }
        }
        message:
        {
            Text(Model.ErrorMessage ?? "")
        }
    }
}

#Preview
{
    ImagePalettizeView()
        .environment(PaletteSelection())
        .environment(ImagePalettizerModel())
}
