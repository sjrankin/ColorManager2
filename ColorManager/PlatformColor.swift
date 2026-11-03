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
