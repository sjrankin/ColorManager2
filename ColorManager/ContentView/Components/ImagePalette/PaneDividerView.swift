//
//  PaneDividerView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

/// A horizontal divider the user can drag up and down to resize the pane below it.
///
/// Dragging up makes the pane below taller; dragging down makes it shorter. The height stays within `Range`.
struct PaneDividerView: View
{
    /// Height of the pane below the divider.
    @Binding var Height: Double
    let Range: ClosedRange<Double>
    /// The height when the drag began.
    @State private var StartHeight: Double?

    var body: some View
    {
        Rectangle()
            .fill(.clear)
            .frame(height: 12)
            .overlay
            {
                Divider()
                Capsule()
                    .fill(.secondary.opacity(0.6))
                    .frame(width: 36, height: 4)
            }
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged
                {
                    Value in
                    let Start = StartHeight ?? Height
                    StartHeight = Start
                    Height = min(max(Start - Value.translation.height, Range.lowerBound), Range.upperBound)
                }
                    .onEnded
                {
                    _ in
                    StartHeight = nil
                })
#if os(macOS)
            .onHover
        {
            Inside in
            if Inside
            {
                NSCursor.resizeUpDown.push()
            }
            else
            {
                NSCursor.pop()
            }
        }
#endif
            .accessibilityLabel("Resize palette")
            .accessibilityAdjustableAction
        {
            Direction in
            switch Direction
            {
                case .increment: Height = min(Height + 20, Range.upperBound)
                case .decrement: Height = max(Height - 20, Range.lowerBound)
                @unknown default: break
            }
        }
    }
}
