//
//  VideoFrameSource.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import CoreGraphics

/// Something that produces a stream of video frames, such as a camera. Abstracted so the model can be tested without
/// camera hardware.
nonisolated protocol VideoFrameSource: AnyObject, Sendable
{
    /// Start producing frames. Throws if the source can't be used (no permission, no camera).
    ///
    /// The stream keeps only the newest unread frame, so a slow consumer skips frames instead of falling behind.
    func Start() async throws -> AsyncStream<CGImage>
    
    /// Stop producing frames and finish the stream.
    func Stop() async
}
