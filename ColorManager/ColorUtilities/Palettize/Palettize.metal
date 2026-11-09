//
//  Palettize.metal
//  ColorManager
//
//  Created by Stuart Rankin on 4/17/26.
//

#include <metal_stdlib>
using namespace metal;

struct PaletteColor
{
    float r;
    float g;
    float b;
    float a; // padding to 16 bytes for alignment
};

/// Replace every pixel with the nearest color in the palette.
///
/// Textures hold premultiplied alpha (as Core Graphics produces), so the color is un-premultiplied before it is compared
/// with the palette and the chosen palette color is premultiplied again when written. The pixel's alpha is preserved.
/// The palette must contain at least one color.
kernel void palettizeKernel(texture2d<float, access::read>  inTexture  [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            constant PaletteColor* palette [[buffer(0)]],
                            constant uint& paletteCount [[buffer(1)]],
                            uint2 gid [[thread_position_in_grid]])
{
    // Bounds check
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) return;
    
    float4 pixel = inTexture.read(gid);
    float3 color = pixel.a > 0.0 ? pixel.rgb / pixel.a : pixel.rgb;
    
    float bestDist = INFINITY;
    float3 bestColor = float3(palette[0].r, palette[0].g, palette[0].b);
    
    for (uint i = 0; i < paletteCount; i++)
    {
        float3 c = float3(palette[i].r, palette[i].g, palette[i].b);
        
        // Weighted RGB distance, a cheap approximation of perceived difference.
        float dr = color.r - c.r;
        float dg = color.g - c.g;
        float db = color.b - c.b;
        float dist = 2.0 * dr * dr + 4.0 * dg * dg + 3.0 * db * db;
        
        if (dist < bestDist)
        {
            bestDist = dist;
            bestColor = c;
        }
    }
    
    outTexture.write(float4(bestColor * pixel.a, pixel.a), gid);
}
