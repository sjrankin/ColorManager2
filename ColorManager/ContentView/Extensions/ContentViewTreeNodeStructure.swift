//
//  ContentViewTreeNodeStructure.swift
//  ColorManager
//
//  Created by Stuart Rankin on 4/13/26.
//

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Tree Node Components

/// Represents a group node in the tree structure
struct GroupTreeNode: View
{
    let group: ColorGroup
    let path: [String]
    let level: Int
    @Binding var expandedGroups: Set<String>
    @Binding var selectedGroupPath: [String]
    
     var pathString: String
    {
        path.joined(separator: ".")
    }
    
     var isExpanded: Bool
    {
        expandedGroups.contains(pathString)
    }
    
     var isSelected: Bool
    {
        selectedGroupPath == path
    }
    
     var colorCount: Int
    {
        group.Colors?.count ?? 0
    }
    
    var body: some View
    {
        VStack(alignment: .leading, spacing: 0)
        {
            // Group row
            HStack(spacing: 4)
            {
                // Indentation
                Color.clear
                    .frame(width: CGFloat(level * 16))
                
                // Disclosure triangle (if has children)
                if hasChildren
                {
                    Button(action: { toggleExpansion() })
                    {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                }
                else
                {
                    Color.clear
                        .frame(width: 16, height: 16)
                }
                
                // Folder icon
                Image(systemName: hasChildren ? "folder.fill" : "folder")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.system(size: 14))
                
                // Group name
                Text(group.Name)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .primary : .primary)
                
                Spacer()
                
                // Color count badge
                if colorCount > 0
                {
                    Text("\(colorCount)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 4)
            .padding(.trailing, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture
            {
                selectedGroupPath = path
            }
            
            // Nested groups (if expanded)
            if isExpanded
            {
                if let nestedGroups = group.Groups
                {
                    ForEach(nestedGroups, id: \.Name) { nestedGroup in
                        GroupTreeNode(
                            group: nestedGroup,
                            path: path + [nestedGroup.Name],
                            level: level + 1,
                            expandedGroups: $expandedGroups,
                            selectedGroupPath: $selectedGroupPath
                        )
                    }
                }
                
                // Collections
                if let collections = group.Collections
                {
                    ForEach(collections, id: \.Name) { collection in
                        CollectionTreeNode(
                            collection: collection,
                            path: path + [collection.Name],
                            level: level + 1,
                            expandedGroups: $expandedGroups,
                            selectedGroupPath: $selectedGroupPath
                        )
                    }
                }
            }
        }
    }
    
     var hasChildren: Bool
    {
        (group.Groups?.isEmpty == false) || (group.Collections?.isEmpty == false)
    }
    
     func toggleExpansion()
    {
        if isExpanded
        {
            expandedGroups.remove(pathString)
        }
        else
        {
            expandedGroups.insert(pathString)
        }
    }
}

/// Represents a collection node in the tree structure
struct CollectionTreeNode: View
{
    let collection: ColorCollection
    let path: [String]
    let level: Int
    @Binding var expandedGroups: Set<String>
    @Binding var selectedGroupPath: [String]
    
    private var pathString: String
    {
        path.joined(separator: ".")
    }
    
    private var isExpanded: Bool
    {
        expandedGroups.contains(pathString)
    }
    
    private var isSelected: Bool
    {
        selectedGroupPath == path
    }
    
    private var colorCount: Int
    {
        collection.Colors?.count ?? 0
    }
    
    var body: some View
    {
        VStack(alignment: .leading, spacing: 0)
        {
            // Collection row
            HStack(spacing: 4)
            {
                // Indentation
                Color.clear
                    .frame(width: CGFloat(level * 16))
                
                // Disclosure triangle (if has nested collections)
                if hasNestedCollections
                {
                    Button(action: { toggleExpansion() })
                    {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                }
                else
                {
                    Color.clear
                        .frame(width: 16, height: 16)
                }
                
                // Collection icon
                Image(systemName: "tray.fill")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.system(size: 12))
                
                // Collection name
                Text(collection.Name)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .primary : .primary)
                
                Spacer()
                
                // Color count badge
                if colorCount > 0
                {
                    Text("\(colorCount)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 4)
            .padding(.trailing, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture
            {
                selectedGroupPath = path
            }
            
            // Nested groups and collections (if expanded)
            if isExpanded
            {
                if let nestedGroups = collection.Groups
                {
                    ForEach(nestedGroups, id: \.Name) { nestedGroup in
                        GroupTreeNode(
                            group: nestedGroup,
                            path: path + [nestedGroup.Name],
                            level: level + 1,
                            expandedGroups: $expandedGroups,
                            selectedGroupPath: $selectedGroupPath
                        )
                    }
                }
                if let nestedCollections = collection.Collections
                {
                    ForEach(nestedCollections, id: \.Name) { nestedCollection in
                        CollectionTreeNode(
                            collection: nestedCollection,
                            path: path + [nestedCollection.Name],
                            level: level + 1,
                            expandedGroups: $expandedGroups,
                            selectedGroupPath: $selectedGroupPath
                        )
                    }
                }
            }
        }
    }

    var hasNestedCollections: Bool
    {
        (collection.Groups?.isEmpty == false) || (collection.Collections?.isEmpty == false)
    }
    
     func toggleExpansion()
    {
        if isExpanded
        {
            expandedGroups.remove(pathString)
        }
        else
        {
            expandedGroups.insert(pathString)
        }
    }
}

#Preview
{
    ContentView()
        .environmentObject(ColorList.shared)
        .environment(PaletteSelection())
        .environment(AppSettings())
        .environment(ImagePalettizerModel())
}

extension UUID
{
    static var empty: UUID
    {
        return UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
}

