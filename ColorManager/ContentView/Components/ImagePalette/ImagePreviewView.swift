//
//  ImagePreviewView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

/// Shows the opened image, or the palettized result once there is one, with a way to switch between them.
struct ImagePreviewView: View
{
    let Source: CGImage?
    let Result: CGImage?
    /// The live camera frame. While this is non-`nil` it is shown in place of the still image.
    let Live: CGImage?
    @Binding var ShowOriginal: Bool
    let IsBusy: Bool
    /// True while a file is being dragged over the dialog (macOS).
    let IsDropTargeted: Bool
    
    var body: some View
    {
        VStack
        {
            if Live == nil && Result != nil
            {
                Picker("Show", selection: $ShowOriginal)
                {
                    Text("Palettized")
                        .tag(false)
                    Text("Original")
                        .tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 280)
            }
            ZStack
            {
                if let Shown = Live ?? (ShowOriginal ? Source : (Result ?? Source))
                {
                    Image(decorative: Shown, scale: 1.0)
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel(Live != nil ? "Live camera" : (ShowOriginal || Result == nil ? "Original image" : "Palettized image"))
                }
                else
                {
                    ContentUnavailableView
                    {
                        Label("No Image", systemImage: "photo")
                    }
                    description:
                    {
#if os(macOS)
                        Text("Open an image, or drop one here.")
#else
                        Text("Open an image.")
#endif
                    }
                }
                if IsBusy
                {
                    ProgressView("Palettizing…")
                        .padding()
                        .background(.regularMaterial, in: .rect(cornerRadius: 8))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay
            {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(IsDropTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                                  lineWidth: IsDropTargeted ? 3 : 1)
            }
        }
        .padding()
    }
}
