//
//  MetalPalettizer.swift
//  ColorManager
//
//  Created by Stuart Rankin on 4/17/26.
//

import Foundation
import Metal
import CoreGraphics

/// Recolors an image so every pixel uses the nearest color from a palette, doing the work on the GPU.
///
/// ```swift
/// guard let palettizer = MetalPalettizer() else { return }
/// let result = try await palettizer.palettize(image: someCGImage, palette: [(1, 0, 0), (0, 0, 1)])
/// ```
final class MetalPalettizer
{
    /// What can go wrong while palettizing.
    enum PalettizeError: LocalizedError
    {
        case emptyPalette
        case imageTooLarge(Int)
        case couldNotReadImage
        case couldNotCreateTexture
        case couldNotEncode
        case gpuFailed(String)
        case couldNotBuildImage
        
        var errorDescription: String?
        {
            switch self
            {
                case .emptyPalette: return "The palette has no colors."
                case .imageTooLarge(let Limit): return "The image is larger than \(Limit) pixels on a side, which the GPU can't process."
                case .couldNotReadImage: return "The image's pixels could not be read."
                case .couldNotCreateTexture: return "The GPU could not allocate memory for the image."
                case .couldNotEncode: return "The GPU work could not be set up."
                case .gpuFailed(let Message): return "The GPU reported an error: \(Message)"
                case .couldNotBuildImage: return "The recolored image could not be built."
            }
        }
    }
    
    /// The largest width or height a texture can have on every supported GPU.
    static let MaximumDimension = 16384
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLComputePipelineState
    
    // Mirror of the Metal struct — must match layout exactly
    struct PaletteColor
    {
        var r: Float
        var g: Float
        var b: Float
        var a: Float = 1.0 // padding
    }
    
    /// - Returns: `nil` if Metal isn't available or the kernel can't be loaded.
    init?()
    {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let queue = device.makeCommandQueue() else
        {
            return nil
        }
        
        self.device = device
        self.commandQueue = queue
        
        // Load the kernel from the default Metal library
        guard let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: "palettizeKernel") else
        {
            return nil
        }
        
        do
        {
            pipelineState = try device.makeComputePipelineState(function: function)
        }
        catch
        {
            print("Failed to create pipeline: \(error)")
            return nil
        }
    }
    
    /// Recolor an image using only the colors in a palette.
    ///
    /// The image is converted to sRGB first, so the palette colors (sRGB values from `0.0` to `1.0`) are compared with the
    /// image in the same color space. Transparency is preserved. The GPU work runs without blocking the caller.
    /// - Parameter image: The image to recolor.
    /// - Parameter palette: The allowed colors. Must not be empty.
    /// - Returns: A new image of the same size, in sRGB.
    func palettize(image: CGImage,
                   palette: [(r: Float, g: Float, b: Float)]) async throws -> CGImage
    {
        guard !palette.isEmpty else
        {
            throw PalettizeError.emptyPalette
        }
        let width = image.width
        let height = image.height
        guard width <= Self.MaximumDimension, height <= Self.MaximumDimension else
        {
            throw PalettizeError.imageTooLarge(Self.MaximumDimension)
        }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else
        {
            throw PalettizeError.couldNotReadImage
        }
        
        // --- Input texture ---
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                         width: width,
                                                                         height: height,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.shaderRead]
        guard let inTexture = device.makeTexture(descriptor: textureDescriptor) else
        {
            throw PalettizeError.couldNotCreateTexture
        }
        
        // Draw the image into a known pixel format (premultiplied RGBA, sRGB) and upload it.
        let bytesPerRow = width * 4
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)
        let drew: Bool = rawData.withUnsafeMutableBytes
        {
            Buffer in
            guard let ctx = CGContext(data: Buffer.baseAddress,
                                      width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else
            {
                return false
            }
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            inTexture.replace(region: MTLRegionMake2D(0, 0, width, height),
                              mipmapLevel: 0,
                              withBytes: Buffer.baseAddress!,
                              bytesPerRow: bytesPerRow)
            return true
        }
        guard drew else
        {
            throw PalettizeError.couldNotReadImage
        }
        
        // --- Output texture ---
        let outDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                     width: width,
                                                                     height: height,
                                                                     mipmapped: false)
        outDescriptor.usage = [.shaderWrite]
        // The CPU reads the result back. Shared storage works where the CPU and GPU share memory; GPUs with their own
        // memory (some Intel Macs) need managed storage and an explicit synchronize.
#if os(macOS)
        let needsSynchronize = !device.hasUnifiedMemory
        outDescriptor.storageMode = needsSynchronize ? .managed : .shared
#else
        outDescriptor.storageMode = .shared
#endif
        guard let outTexture = device.makeTexture(descriptor: outDescriptor) else
        {
            throw PalettizeError.couldNotCreateTexture
        }
        
        // --- Palette buffer ---
        var paletteData = palette.map { PaletteColor(r: $0.r, g: $0.g, b: $0.b) }
        var paletteCount = UInt32(palette.count)
        guard let paletteBuffer = device.makeBuffer(bytes: &paletteData,
                                                    length: MemoryLayout<PaletteColor>.stride * palette.count,
                                                    options: .storageModeShared) else
        {
            throw PalettizeError.couldNotCreateTexture
        }
        
        // --- Encode and dispatch ---
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else
        {
            throw PalettizeError.couldNotEncode
        }
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(inTexture, index: 0)
        encoder.setTexture(outTexture, index: 1)
        encoder.setBuffer(paletteBuffer, offset: 0, index: 0)
        encoder.setBytes(&paletteCount, length: MemoryLayout<UInt32>.size, index: 1)
        
        // Threadgroup sizing — use max threads the pipeline supports. Non-uniform dispatch handles edges, and the kernel
        // also checks bounds.
        let threadgroupSize = MTLSize(width: pipelineState.threadExecutionWidth,
                                      height: pipelineState.maxTotalThreadsPerThreadgroup / pipelineState.threadExecutionWidth,
                                      depth: 1)
        encoder.dispatchThreads(MTLSize(width: width, height: height, depth: 1), threadsPerThreadgroup: threadgroupSize)
        encoder.endEncoding()
        
#if os(macOS)
        if needsSynchronize, let blit = commandBuffer.makeBlitCommandEncoder()
        {
            blit.synchronize(resource: outTexture)
            blit.endEncoding()
        }
#endif
        
        // Wait for the GPU without blocking the calling thread.
        await withCheckedContinuation
        {
            (Continuation: CheckedContinuation<Void, Never>) in
            commandBuffer.addCompletedHandler
            {
                _ in
                Continuation.resume()
            }
            commandBuffer.commit()
        }
        if let error = commandBuffer.error
        {
            throw PalettizeError.gpuFailed(error.localizedDescription)
        }
        
        // --- Read back ---
        guard let result = cgImage(from: outTexture, width: width, height: height, colorSpace: colorSpace) else
        {
            throw PalettizeError.couldNotBuildImage
        }
        return result
    }
    
    private func cgImage(from texture: MTLTexture, width: Int, height: Int, colorSpace: CGColorSpace) -> CGImage?
    {
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        texture.getBytes(&pixels,
                         bytesPerRow: bytesPerRow,
                         from: MTLRegionMake2D(0, 0, width, height),
                         mipmapLevel: 0)
        
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else
        {
            return nil
        }
        return CGImage(width: width, height: height,
                       bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: bytesPerRow,
                       space: colorSpace,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider,
                       decode: nil, shouldInterpolate: false,
                       intent: .defaultIntent)
    }
}
