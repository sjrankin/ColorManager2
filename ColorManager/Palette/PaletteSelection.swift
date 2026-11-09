//
//  PaletteSelection.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation

/// The colors the user has marked for use in a palette (for example by the image palettizer).
///
/// This is separate from the single highlighted swatch used by the info panel: any number of colors can be marked, and
/// the marks stay when the user moves between groups. Colors are identified by their record's `id`, and are kept in the
/// order they were marked.
@MainActor @Observable
final class PaletteSelection
{
    /// The marked colors, in the order they were marked.
    private(set) var Records: [ColorRecord] = []
    
    /// The `id`s of the marked colors, for fast lookup.
    private(set) var IDs: Set<UUID> = []
    
    /// How many colors are marked.
    var Count: Int
    {
        return Records.count
    }
    
    /// True if no colors are marked.
    var IsEmpty: Bool
    {
        return Records.isEmpty
    }
    
    /// Is the color marked?
    func Contains(_ Record: ColorRecord) -> Bool
    {
        return IDs.contains(Record.id)
    }
    
    /// Mark the color if it isn't marked, or unmark it if it is.
    /// - Returns: `true` if the color is marked afterward.
    @discardableResult
    func Toggle(_ Record: ColorRecord) -> Bool
    {
        if Contains(Record)
        {
            Remove([Record])
            return false
        }
        Add([Record])
        return true
    }
    
    /// Mark colors. Colors that are already marked keep their place.
    func Add(_ NewRecords: [ColorRecord])
    {
        for Record in NewRecords where !IDs.contains(Record.id)
        {
            IDs.insert(Record.id)
            Records.append(Record)
        }
    }
    
    /// Unmark colors. Colors that aren't marked are ignored.
    func Remove(_ OldRecords: [ColorRecord])
    {
        let Removing = Set(OldRecords.map(\.id))
        if Removing.isDisjoint(with: IDs)
        {
            return
        }
        IDs.subtract(Removing)
        Records.removeAll { Removing.contains($0.id) }
    }
    
    /// Unmark everything.
    func Clear()
    {
        Records.removeAll()
        IDs.removeAll()
    }
    
    /// The marked colors as sRGB channels (`0.0` - `1.0`), ready to be used as a palette. Colors that have no usable
    /// color value are left out.
    var PaletteColors: [(r: Float, g: Float, b: Float)]
    {
        return Records.compactMap
        {
            Record in
            guard let Channels = ColorSearchEngine.RGBChannels(of: Record) else
            {
                return nil
            }
            return (Float(Channels.r), Float(Channels.g), Float(Channels.b))
        }
    }
}
