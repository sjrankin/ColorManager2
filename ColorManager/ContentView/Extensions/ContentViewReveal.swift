//
//  ContentViewReveal.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Revealing a color

extension ContentView
{
    /// Open the group that holds the requested color, highlight the color, and scroll it into view.
    func Reveal(_ Request: ColorRevealRequest)
    {
        // Open every group on the way down so the structure tree shows the selection.
        var Prefix: [String] = []
        for Name in Request.Path
        {
            Prefix.append(Name)
            expandedGroups.insert(Prefix.joined(separator: "."))
        }
        
        if selectedGroupPath == Request.Path
        {
            // The group is already showing, so no group-change will arrive; select now.
            Select(Request.Record)
        }
        else
        {
            // Changing the group clears the selection (see `GroupPathChanged`), so select once that has happened.
            PendingReveal = Request.Record
            selectedGroupPath = Request.Path
        }
        BringToFront()
        // The request is handled; clear it so it is not applied again.
        colorList.RevealRequest = nil
    }
    
    /// Called when the selected group changes. Clears the selection, unless the change is part of a reveal.
    func GroupPathChanged()
    {
        if let Record = PendingReveal
        {
            PendingReveal = nil
            Select(Record)
        }
        else
        {
            SelectedSwatch = UUID.empty
            SelectedColorRecord = nil
        }
    }
    
    /// Select a color and ask the lists to scroll to it.
    func Select(_ Record: ColorRecord)
    {
        SelectedSwatch = Record.id
        SelectedColorRecord = Record
        ScrollTarget = Record.id
    }
    
    /// Scroll to the target once the new group's colors have been laid out, then clear the target.
    func ScrollToTarget(_ Target: UUID?, using Proxy: ScrollViewProxy)
    {
        guard let Target else
        {
            return
        }
        Task
        {
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation
            {
                Proxy.scrollTo(Target, anchor: .center)
            }
            ScrollTarget = nil
        }
    }
    
    /// Bring the main window forward (macOS), since the request usually comes from the separate search window.
    func BringToFront()
    {
#if os(macOS)
        NSApp.activate()
        if let Window = NSApp.windows.first(where: { $0.title != "Color Searcher" && $0.canBecomeMain })
        {
            if Window.isMiniaturized
            {
                Window.deminiaturize(nil)
            }
            Window.makeKeyAndOrderFront(nil)
        }
#endif
    }
}
