//
//  ContentViewImportHandling.swift
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

// MARK: - Import Handling

extension ContentView
{
    func handleImportResult(_ result: Result<ImportedColorData, ColorListError>)
    {
        NSLog("🟢 Import callback received")
        print("🟢 Import callback received")
        
        switch result
        {
            case .success(let importedData):
                handleImportSuccess(importedData)
                
            case .failure(let error):
                handleImportFailure(error)
        }
    }
    
    func handleImportSuccess(_ importedData: ImportedColorData)
    {
        NSLog("🟡 Import succeeded")
        print("🟡 Import succeeded, type: \(importedData.importType)")
        
        Task { @MainActor in
            print("🟠 Starting Task on MainActor")
            do
            {
                print("🔴 About to load data into ColorList")
                try ColorList.shared.loadFromImportedData(importedData)
                logImportSuccess(importedData)
                // Remember the file (only now that it has loaded) so it can be reloaded at the next launch.
                if let Source = importedData.sourceURL
                {
                    Settings.RememberLastFile(from: Source, name: importedData.sourceFileName)
                }
            }
            catch
            {
                NSLog("❌ Failed to load: %@", error.localizedDescription)
                print("❌ Failed to load data into ColorList: \(error.localizedDescription)")
            }
        }
    }
    
    func handleImportFailure(_ error: ColorListError)
    {
        NSLog("❌ Import failed: %@", error.localizedDescription)
        print("❌ Import failed: \(error.localizedDescription)")
    }
    
    func logImportSuccess(_ importedData: ImportedColorData)
    {
        let totalColors = ColorList.shared.totalColorCount()
        NSLog("✅ Successfully loaded %d colors", totalColors)
        print("✅ Successfully loaded \(totalColors) colors from \(importedData.sourceFileName ?? "unknown file")")
        
        switch importedData.importType
        {
            case .fullStructure:
                if let groups = ColorList.shared.colorGroups
                {
                    print("📊 Loaded full structure with \(groups.count) top-level groups")
                }
            case .groups:
                if let groups = ColorList.shared.colorGroups
                {
                    print("📊 Loaded \(groups.count) color groups")
                }
            case .records:
                print("⚠️ Warning: Individual records import attempted but rejected")
        }
    }
}
