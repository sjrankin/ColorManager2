//
//  ImagePalettizerModel.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation
import CoreGraphics

/// The state of the image palettizer dialog: the image that was opened, and the image recolored with a palette.
@MainActor @Observable
final class ImagePalettizerModel
{
    /// The image the user opened, or `nil` if none has been opened.
    private(set) var SourceImage: CGImage?
    
    /// The name of the file `SourceImage` came from.
    private(set) var SourceName: String?
    
    /// The recolored image, or `nil` if the image hasn't been palettized.
    private(set) var ResultImage: CGImage?
    
    /// The `id`s of the palette colors used to make `ResultImage`.
    private(set) var ResultPaletteIDs: Set<UUID> = []
    
    /// True while the GPU is working.
    private(set) var IsBusy: Bool = false
    
    /// A message describing the last failure, to show to the user. Set to `nil` to dismiss it.
    var ErrorMessage: String?
    
    /// While `true` the dialog shows the original even if a result exists.
    var ShowOriginal: Bool = false
    
    // MARK: Live camera
    
    /// The palette to use for the next live frame: its colors, and their `id`s.
    typealias PaletteProvider = @MainActor () -> (colors: [(r: Float, g: Float, b: Float)], ids: Set<UUID>)
    
    /// True while the camera is running.
    private(set) var IsCameraRunning: Bool = false
    
    /// The newest live frame to show: palettized if `PalettizeLive` is on and the palette isn't empty, else the raw frame.
    private(set) var LiveImage: CGImage?
    
    /// When `true`, live frames are palettized.
    var PalettizeLive: Bool = true
    
    /// The raw frame that `LiveResult` was made from, kept so a captured still has a matching original.
    @ObservationIgnored private var LiveRaw: CGImage?
    @ObservationIgnored private var LiveResult: CGImage?
    @ObservationIgnored private var LiveResultIDs: Set<UUID> = []
    @ObservationIgnored private var FrameSource: (any VideoFrameSource)?
    @ObservationIgnored private var CameraTask: Task<Void, Never>?
    
    /// Makes the frame source the camera uses. Replaced in tests.
    @ObservationIgnored var MakeFrameSource: () -> any VideoFrameSource = { CameraFrameSource() }
    
    @ObservationIgnored private var Palettizer: MetalPalettizer?
    
    // MARK: Opening
    
    /// Open an image file. Any earlier result is discarded. On failure, `ErrorMessage` is set and the current image is
    /// kept.
    func LoadImage(from URL: URL)
    {
        do
        {
            SourceImage = try ImageFile.Load(from: URL)
            SourceName = URL.lastPathComponent
            ResultImage = nil
            ResultPaletteIDs = []
            ShowOriginal = false
            ErrorMessage = nil
        }
        catch
        {
            ErrorMessage = error.localizedDescription
        }
    }
    
    // MARK: Palettizing
    
    /// True if there is an image, and `Colors` could be used to recolor it.
    func CanPalettize(colorCount Count: Int) -> Bool
    {
        return SourceImage != nil && Count > 0 && !IsBusy && !IsCameraRunning
    }
    
    /// Recolor the opened image so it uses only the palette's colors. The result replaces any earlier one.
    /// - Parameter Colors: The palette, as sRGB channels (`0.0` - `1.0`).
    /// - Parameter IDs: The `id`s of the palette's colors, remembered so the dialog can tell when the palette has changed
    ///   since the result was made.
    func Palettize(colors Colors: [(r: Float, g: Float, b: Float)], ids IDs: Set<UUID>) async
    {
        guard !IsBusy, let Image = SourceImage else
        {
            return
        }
        guard !Colors.isEmpty else
        {
            ErrorMessage = "Select at least one color for the palette first."
            return
        }
        guard let Palettizer = EnsurePalettizer() else
        {
            ErrorMessage = "This device can't run the GPU image processing the palettizer needs."
            return
        }
        
        IsBusy = true
        defer { IsBusy = false }
        do
        {
            ResultImage = try await Palettizer.palettize(image: Image, palette: Colors)
            ResultPaletteIDs = IDs
            ShowOriginal = false
            ErrorMessage = nil
        }
        catch
        {
            ErrorMessage = error.localizedDescription
        }
    }
    
    /// The GPU palettizer, created on first use. `nil` if the device has no usable GPU.
    private func EnsurePalettizer() -> MetalPalettizer?
    {
        if Palettizer == nil
        {
            Palettizer = MetalPalettizer()
        }
        return Palettizer
    }
    
    // MARK: Camera
    
    /// Start the camera. Each frame is shown live, palettized with whatever palette `Palette` returns at that moment, so
    /// changing the palette takes effect immediately. On failure, `ErrorMessage` is set.
    func StartCamera(palette Palette: @escaping PaletteProvider) async
    {
        guard !IsCameraRunning else
        {
            return
        }
        let Source = MakeFrameSource()
        do
        {
            let Stream = try await Source.Start()
            FrameSource = Source
            IsCameraRunning = true
            ErrorMessage = nil
            CameraTask = Task
            {
                await ProcessFrames(Stream, palette: Palette)
            }
        }
        catch
        {
            ErrorMessage = error.localizedDescription
        }
    }
    
    /// Stop the camera and clear the live image.
    func StopCamera() async
    {
        guard IsCameraRunning else
        {
            return
        }
        IsCameraRunning = false
        CameraTask?.cancel()
        CameraTask = nil
        let Source = FrameSource
        FrameSource = nil
        LiveImage = nil
        LiveRaw = nil
        LiveResult = nil
        await Source?.Stop()
    }
    
    /// Stop the camera and keep the current frame as the opened image, with its palettized version as the result so it
    /// can be saved.
    func CaptureFrame() async
    {
        guard IsCameraRunning, let Raw = LiveRaw else
        {
            return
        }
        let Result = LiveResult
        let IDs = LiveResultIDs
        await StopCamera()
        SourceImage = Raw
        SourceName = "Camera"
        ResultImage = Result
        ResultPaletteIDs = Result == nil ? [] : IDs
        ShowOriginal = false
        ErrorMessage = nil
    }
    
    private func ProcessFrames(_ Stream: AsyncStream<CGImage>, palette Palette: PaletteProvider) async
    {
        for await Frame in Stream
        {
            let Current = Palette()
            var Shown = Frame
            var Result: CGImage?
            if PalettizeLive && !Current.colors.isEmpty
            {
                guard let Palettizer = EnsurePalettizer() else
                {
                    ErrorMessage = "This device can't run the GPU image processing the palettizer needs."
                    break
                }
                do
                {
                    Result = try await Palettizer.palettize(image: Frame, palette: Current.colors)
                }
                catch
                {
                    ErrorMessage = error.localizedDescription
                    break
                }
                Shown = Result ?? Frame
            }
            // The camera may have been stopped while the GPU was working.
            guard IsCameraRunning else
            {
                return
            }
            LiveRaw = Frame
            LiveResult = Result
            LiveResultIDs = Current.ids
            LiveImage = Shown
        }
        // The loop ends early only on an error; stop the camera so the UI matches.
        await StopCamera()
    }
    
    /// Discard the palettized result so the opened image is shown as it was. The opened image itself is untouched, so
    /// palettizing again starts from the original.
    func ResetToOriginal()
    {
        guard !IsBusy else
        {
            return
        }
        ResultImage = nil
        ResultPaletteIDs = []
        ShowOriginal = false
        ErrorMessage = nil
    }
    
    /// True if there is a result and it was made with exactly these palette colors.
    func ResultIsCurrent(for IDs: Set<UUID>) -> Bool
    {
        return ResultImage != nil && ResultPaletteIDs == IDs
    }
    
    // MARK: Saving
    
    /// The recolored image as PNG data, or `nil` if there is no result (or it couldn't be encoded, which sets
    /// `ErrorMessage`).
    func ResultPNGData() -> Data?
    {
        guard let Image = ResultImage else
        {
            return nil
        }
        do
        {
            return try ImageFile.PNGData(from: Image)
        }
        catch
        {
            ErrorMessage = error.localizedDescription
            return nil
        }
    }
    
    /// A file name suggestion for saving the result, based on the source name.
    var SuggestedResultName: String
    {
        guard let SourceName else
        {
            return "Palettized"
        }
        let Base = (SourceName as NSString).deletingPathExtension
        return "\(Base) palettized"
    }
}
