//
//  AppSettings.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation

/// The user's application settings. Values are saved to `UserDefaults` as they change, so they are still in place the
/// next time the app starts.
@MainActor @Observable
final class AppSettings
{
    // MARK: Keys
    
    /// `UserDefaults` keys, exposed so tests can inspect what was saved.
    enum Keys
    {
        static let LoadLastFileAtStartup = "Settings.LoadLastFileAtStartup"
        static let LastFileName = "Settings.LastFileName"
    }
    
    // MARK: Settings
    
    /// If true, the app loads the last color file the user loaded when it starts, instead of the built-in colors.
    var LoadLastFileAtStartup: Bool
    {
        didSet
        {
            Defaults.set(LoadLastFileAtStartup, forKey: Keys.LoadLastFileAtStartup)
        }
    }
    
    /// The name of the file the stored copy came from (for display), or `nil` if no file has been remembered.
    private(set) var LastFileName: String?
    {
        didSet
        {
            Defaults.set(LastFileName, forKey: Keys.LastFileName)
        }
    }
    
    // MARK: Storage
    
    @ObservationIgnored private let Defaults: UserDefaults
    @ObservationIgnored private let Store: LastColorFileStore
    
    /// - Parameter Defaults: Where settings are saved. Tests pass a throwaway suite.
    /// - Parameter Store: Where the copy of the last file is kept. Tests pass a temporary folder.
    init(Defaults: UserDefaults = .standard, Store: LastColorFileStore = LastColorFileStore())
    {
        self.Defaults = Defaults
        self.Store = Store
        self.LoadLastFileAtStartup = Defaults.bool(forKey: Keys.LoadLastFileAtStartup)
        self.LastFileName = Defaults.string(forKey: Keys.LastFileName)
    }
    
    // MARK: Last loaded file
    
    /// True if there is a remembered file that can still be loaded.
    var HasLastFile: Bool
    {
        return LastFileName != nil && Store.Exists
    }
    
    /// The remembered copy of the last loaded file, or `nil` if there isn't one.
    var LastFileURL: URL?
    {
        return HasLastFile ? Store.FileURL : nil
    }
    
    /// Remember a color file that was just loaded successfully, so it can be loaded again at startup.
    /// - Parameter Source: The file that was loaded.
    /// - Parameter Name: A name to show for it. Defaults to the source's file name.
    /// - Returns: `true` if the file was remembered. On failure the previously remembered file is kept.
    @discardableResult
    func RememberLastFile(from Source: URL, name Name: String? = nil) -> Bool
    {
        do
        {
            try Store.Save(from: Source)
            LastFileName = Name ?? Source.lastPathComponent
            return true
        }
        catch
        {
            print("Could not remember the last color file: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Forget the remembered file and delete the stored copy.
    func ForgetLastFile()
    {
        Store.Remove()
        LastFileName = nil
    }
}
