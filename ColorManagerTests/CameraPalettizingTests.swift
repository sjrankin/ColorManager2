//
//  CameraPalettizingTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation
import CoreGraphics
import Testing
@testable import ColorManager

/// A frame source that yields frames the test supplies, standing in for the camera.
nonisolated final class FakeFrameSource: VideoFrameSource, @unchecked Sendable
{
    private var Continuation: AsyncStream<CGImage>.Continuation?
    var Failure: Error?
    private(set) var Stopped = false
    
    func Start() async throws -> AsyncStream<CGImage>
    {
        if let Failure
        {
            throw Failure
        }
        return AsyncStream(bufferingPolicy: .bufferingNewest(1))
        {
            self.Continuation = $0
        }
    }
    
    func Stop() async
    {
        Stopped = true
        Continuation?.finish()
    }
    
    func Send(_ Frame: CGImage)
    {
        Continuation?.yield(Frame)
    }
}

@Suite("Camera palettizing")
struct CameraPalettizingTests
{
    typealias Support = ImageTestSupport
    
    func Frame(_ Color: (UInt8, UInt8, UInt8)) -> CGImage
    {
        return Support.MakeOpaqueImage(width: 4, height: 2, colors: Array(repeating: Color, count: 8))
    }
    
    /// Wait (briefly) until `Condition` is true.
    func WaitFor(_ Condition: () -> Bool) async -> Bool
    {
        for _ in 0..<200
        {
            if Condition()
            {
                return true
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return Condition()
    }
    
    @Test func LiveFramesArePalettized() async
    {
        let Source = FakeFrameSource()
        let Model = ImagePalettizerModel()
        Model.MakeFrameSource = { Source }
        let IDs: Set<UUID> = [UUID()]
        await Model.StartCamera { (colors: [(r: 0, g: 0, b: 1)], ids: IDs) }
        #expect(Model.IsCameraRunning)
        Source.Send(Frame((220, 30, 30)))
        #expect(await WaitFor { Model.LiveImage != nil })
        // The only palette color is blue, so the red frame comes out blue.
        let Pixels = Support.Pixels(of: Model.LiveImage!)
        #expect(Pixels[0] < 10 && Pixels[2] > 245)
        await Model.StopCamera()
    }
    
    @Test func WithAnEmptyPaletteTheRawFrameIsShown() async
    {
        let Source = FakeFrameSource()
        let Model = ImagePalettizerModel()
        Model.MakeFrameSource = { Source }
        await Model.StartCamera { (colors: [], ids: []) }
        Source.Send(Frame((220, 30, 30)))
        #expect(await WaitFor { Model.LiveImage != nil })
        #expect(Support.Pixels(of: Model.LiveImage!)[0] > 200)
        await Model.StopCamera()
    }
    
    @Test func StoppingClearsTheLiveImageAndStopsTheSource() async
    {
        let Source = FakeFrameSource()
        let Model = ImagePalettizerModel()
        Model.MakeFrameSource = { Source }
        await Model.StartCamera { (colors: [], ids: []) }
        Source.Send(Frame((1, 2, 3)))
        _ = await WaitFor { Model.LiveImage != nil }
        await Model.StopCamera()
        #expect(!Model.IsCameraRunning)
        #expect(Model.LiveImage == nil)
        #expect(Source.Stopped)
    }
    
    @Test func CapturingKeepsTheFrameAndItsPalettizedVersion() async
    {
        let Source = FakeFrameSource()
        let Model = ImagePalettizerModel()
        Model.MakeFrameSource = { Source }
        let IDs: Set<UUID> = [UUID()]
        await Model.StartCamera { (colors: [(r: 0, g: 1, b: 0)], ids: IDs) }
        Source.Send(Frame((220, 30, 30)))
        _ = await WaitFor { Model.LiveImage != nil }
        await Model.CaptureFrame()
        #expect(!Model.IsCameraRunning)
        #expect(Model.SourceImage != nil && Model.ResultImage != nil)
        #expect(Model.ResultIsCurrent(for: IDs))
        #expect(Model.ResultPNGData() != nil)
        #expect(Model.SourceName == "Camera")
    }
    
    @Test func AFailingCameraReportsAnErrorAndDoesNotRun() async
    {
        let Source = FakeFrameSource()
        Source.Failure = CameraFrameSource.CameraError.accessDenied
        let Model = ImagePalettizerModel()
        Model.MakeFrameSource = { Source }
        await Model.StartCamera { (colors: [], ids: []) }
        #expect(!Model.IsCameraRunning)
        #expect(Model.ErrorMessage != nil)
    }
}
