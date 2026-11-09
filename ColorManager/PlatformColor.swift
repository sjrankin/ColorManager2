//
//  PlatformColor.swift
//  ColorManager
//
//  Created by Stuart Rankin on 3/29/26.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// OS agnostic color definitions.
#if os(macOS)
public typealias PlatformColor = NSColor
public typealias PlatformImage = NSImage
#else
public typealias PlatformColor = UIColor
public typealias PlatformImage = UIImage
#endif

extension PlatformColor
{
     enum ColorChannels
    {
        case Red
        case Green
        case Blue
    }
    
    /// Replace one channel using a string value. Returns the color unchanged if the string is not an integer.
    func Replace(Channel: ColorChannels, With: String) -> PlatformColor
    {
        guard let Valid = Int(With) else
        {
            return self
        }
        return Replace(Channel: Channel, With: Valid)
    }

    #if os(macOS)
    func Replace(Channel: ColorChannels, With Value: Int) -> PlatformColor
    {
        var Channels = Convert.IntChannels(From: self)
        switch Channel
        {
            case .Red:
                Channels.red = Value.ChannelClamped()
                
            case .Green:
                Channels.green = Value.ChannelClamped()
                
            case .Blue:
                Channels.blue = Value.ChannelClamped()
        }
        return Convert.FromRGB(Channels.red, Channels.green, Channels.blue)
    }
    #else
    func Replace(Channel: ColorChannels, With Value: Int) -> PlatformColor
    {
        var Channels = Convert.IntChannels(From: self)
        switch Channel
        {
            case .Red:
                Channels.red = Value.ChannelClamped()
                
            case .Green:
                Channels.green = Value.ChannelClamped()
                
            case .Blue:
                Channels.blue = Value.ChannelClamped()
        }
        return Convert.FromRGB(Channels.red, Channels.green, Channels.blue)
    }
    #endif
}
