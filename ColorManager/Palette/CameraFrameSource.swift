//
//  CameraFrameSource.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import AVFoundation
import CoreImage

/// Frames from the system's default video camera.
nonisolated final class CameraFrameSource: NSObject, VideoFrameSource, AVCaptureVideoDataOutputSampleBufferDelegate,
                                           @unchecked Sendable
{
    enum CameraError: LocalizedError
    {
        case accessDenied
        case noCamera
        case cannotUseCamera
        
        var errorDescription: String?
        {
            switch self
            {
                case .accessDenied: return "Camera access was denied. Allow it for ColorManager in System Settings > Privacy & Security > Camera."
                case .noCamera: return "No camera was found."
                case .cannotUseCamera: return "The camera couldn't be set up."
            }
        }
    }
    
    private let Session = AVCaptureSession()
    private let SessionQueue = DispatchQueue(label: "ColorManager.Camera.Session")
    /// Sample buffers are delivered here. `Continuation` is only touched on this queue.
    private let FrameQueue = DispatchQueue(label: "ColorManager.Camera.Frames")
    private let Context = CIContext(options: [.outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any])
    private var Continuation: AsyncStream<CGImage>.Continuation?
    
    func Start() async throws -> AsyncStream<CGImage>
    {
        guard await Authorized() else
        {
            throw CameraError.accessDenied
        }
        guard let Device = AVCaptureDevice.default(for: .video) else
        {
            throw CameraError.noCamera
        }
        let Input = try AVCaptureDeviceInput(device: Device)
        let Output = AVCaptureVideoDataOutput()
        Output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        Output.alwaysDiscardsLateVideoFrames = true
        Output.setSampleBufferDelegate(self, queue: FrameQueue)
        
        Session.beginConfiguration()
        if Session.canSetSessionPreset(.medium)
        {
            // Palettizing every frame is much cheaper at modest resolution.
            Session.sessionPreset = .medium
        }
        guard Session.canAddInput(Input), Session.canAddOutput(Output) else
        {
            Session.commitConfiguration()
            throw CameraError.cannotUseCamera
        }
        Session.addInput(Input)
        Session.addOutput(Output)
#if os(iOS)
        if let Connection = Output.connection(with: .video), Connection.isVideoRotationAngleSupported(90)
        {
            Connection.videoRotationAngle = 90 // Portrait.
        }
#endif
        Session.commitConfiguration()
        
        let Stream = AsyncStream<CGImage>(bufferingPolicy: .bufferingNewest(1))
        {
            Continuation in
            FrameQueue.sync { self.Continuation = Continuation }
        }
        await withCheckedContinuation
        {
            (Done: CheckedContinuation<Void, Never>) in
            SessionQueue.async
            {
                self.Session.startRunning()
                Done.resume()
            }
        }
        return Stream
    }
    
    func Stop() async
    {
        await withCheckedContinuation
        {
            (Done: CheckedContinuation<Void, Never>) in
            SessionQueue.async
            {
                self.Session.stopRunning()
                for Input in self.Session.inputs { self.Session.removeInput(Input) }
                for Output in self.Session.outputs { self.Session.removeOutput(Output) }
                self.FrameQueue.async
                {
                    self.Continuation?.finish()
                    self.Continuation = nil
                    Done.resume()
                }
            }
        }
    }
    
    private func Authorized() async -> Bool
    {
        switch AVCaptureDevice.authorizationStatus(for: .video)
        {
            case .authorized: return true
            case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
            default: return false
        }
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        guard let Buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else
        {
            return
        }
        let Image = CIImage(cvPixelBuffer: Buffer)
        guard let Frame = Context.createCGImage(Image, from: Image.extent) else
        {
            return
        }
        Continuation?.yield(Frame)
    }
}
