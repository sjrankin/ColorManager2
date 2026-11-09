//
//  AppSettingsTests.swift
//  ColorManagerTests
//
//  Created by Stuart Rankin on 11/9/26.
//

import Foundation
import Testing
@testable import ColorManager

/// A throwaway place to keep settings and the stored file, removed when the test ends.
@MainActor
final class SettingsSandbox
{
    let SuiteName = "ColorManagerTests.\(UUID().uuidString)"
    let Folder = FileManager.default.temporaryDirectory.appending(path: "ColorManagerTests-\(UUID().uuidString)",
                                                                  directoryHint: .isDirectory)
    
    var Defaults: UserDefaults
    {
        return UserDefaults(suiteName: SuiteName)!
    }
    
    var Store: LastColorFileStore
    {
        return LastColorFileStore(Directory: Folder.appending(path: "Stored", directoryHint: .isDirectory))
    }
    
    /// Settings as the app would create them at launch. Call again to simulate a new launch.
    func Launch() -> AppSettings
    {
        return AppSettings(Defaults: Defaults, Store: Store)
    }
    
    /// Write a small file and return its URL.
    func MakeFile(_ Name: String, Contents: String) throws -> URL
    {
        try FileManager.default.createDirectory(at: Folder, withIntermediateDirectories: true)
        let URL = Folder.appending(path: Name)
        try Contents.write(to: URL, atomically: true, encoding: .utf8)
        return URL
    }
    
    func Cleanup()
    {
        UserDefaults(suiteName: SuiteName)?.removePersistentDomain(forName: SuiteName)
        try? FileManager.default.removeItem(at: Folder)
    }
}

@Suite("Application settings")
struct AppSettingsTests
{
    @Test func DefaultsAreOff()
    {
        let Sandbox = SettingsSandbox()
        defer { Sandbox.Cleanup() }
        let Settings = Sandbox.Launch()
        #expect(Settings.LoadLastFileAtStartup == false)
        #expect(Settings.LastFileName == nil)
        #expect(Settings.HasLastFile == false)
        #expect(Settings.LastFileURL == nil)
    }
    
    @Test func StartupOptionIsKeptAcrossLaunches()
    {
        let Sandbox = SettingsSandbox()
        defer { Sandbox.Cleanup() }
        Sandbox.Launch().LoadLastFileAtStartup = true
        #expect(Sandbox.Launch().LoadLastFileAtStartup == true)
        Sandbox.Launch().LoadLastFileAtStartup = false
        #expect(Sandbox.Launch().LoadLastFileAtStartup == false)
    }
    
    @Test func RememberedFileIsKeptAcrossLaunches() throws
    {
        let Sandbox = SettingsSandbox()
        defer { Sandbox.Cleanup() }
        let Source = try Sandbox.MakeFile("Mine.xml", Contents: "<Colors/>")
        #expect(Sandbox.Launch().RememberLastFile(from: Source))
        
        let Next = Sandbox.Launch()
        #expect(Next.HasLastFile)
        #expect(Next.LastFileName == "Mine.xml")
        let Stored = try #require(Next.LastFileURL)
        #expect(try String(contentsOf: Stored, encoding: .utf8) == "<Colors/>")
    }
    
    @Test func RememberedCopySurvivesTheOriginalBeingDeleted() throws
    {
        let Sandbox = SettingsSandbox()
        defer { Sandbox.Cleanup() }
        let Source = try Sandbox.MakeFile("Original.xml", Contents: "<Colors/>")
        let Settings = Sandbox.Launch()
        Settings.RememberLastFile(from: Source)
        try FileManager.default.removeItem(at: Source)
        #expect(Settings.HasLastFile)
        let Stored = try #require(Settings.LastFileURL)
        #expect(try String(contentsOf: Stored, encoding: .utf8) == "<Colors/>")
    }
    
    @Test func CustomNameIsUsedForDisplay() throws
    {
        let Sandbox = SettingsSandbox()
        defer { Sandbox.Cleanup() }
        let Source = try Sandbox.MakeFile("Source.xml", Contents: "<Colors/>")
        let Settings = Sandbox.Launch()
        Settings.RememberLastFile(from: Source, name: "Pretty Name.xml")
        #expect(Settings.LastFileName == "Pretty Name.xml")
    }
    
    @Test func RememberingANewFileReplacesTheOldOne() throws
    {
        let Sandbox = SettingsSandbox()
        defer { Sandbox.Cleanup() }
        let First = try Sandbox.MakeFile("First.xml", Contents: "first")
        let Second = try Sandbox.MakeFile("Second.xml", Contents: "second")
        let Settings = Sandbox.Launch()
        Settings.RememberLastFile(from: First)
        Settings.RememberLastFile(from: Second)
        #expect(Settings.LastFileName == "Second.xml")
        let Stored = try #require(Settings.LastFileURL)
        #expect(try String(contentsOf: Stored, encoding: .utf8) == "second")
    }
    
    @Test func FailingToRememberKeepsThePreviousFile() throws
    {
        let Sandbox = SettingsSandbox()
        defer { Sandbox.Cleanup() }
        let Good = try Sandbox.MakeFile("Good.xml", Contents: "good")
        let Settings = Sandbox.Launch()
        Settings.RememberLastFile(from: Good)
        let Missing = Sandbox.Folder.appending(path: "DoesNotExist.xml")
        #expect(Settings.RememberLastFile(from: Missing) == false)
        #expect(Settings.LastFileName == "Good.xml")
        let Stored = try #require(Settings.LastFileURL)
        #expect(try String(contentsOf: Stored, encoding: .utf8) == "good")
    }
    
    @Test func ForgettingRemovesTheFileAndTheName() throws
    {
        let Sandbox = SettingsSandbox()
        defer { Sandbox.Cleanup() }
        let Source = try Sandbox.MakeFile("Source.xml", Contents: "<Colors/>")
        let Settings = Sandbox.Launch()
        Settings.RememberLastFile(from: Source)
        let Stored = try #require(Settings.LastFileURL)
        Settings.ForgetLastFile()
        #expect(Settings.HasLastFile == false)
        #expect(Settings.LastFileName == nil)
        #expect(!FileManager.default.fileExists(atPath: Stored.path(percentEncoded: false)))
        // Still forgotten at the next launch.
        #expect(Sandbox.Launch().LastFileName == nil)
    }
    
    @Test func AMissingCopyMeansThereIsNoLastFile() throws
    {
        let Sandbox = SettingsSandbox()
        defer { Sandbox.Cleanup() }
        let Source = try Sandbox.MakeFile("Source.xml", Contents: "<Colors/>")
        let Settings = Sandbox.Launch()
        Settings.RememberLastFile(from: Source)
        Sandbox.Store.Remove()
        #expect(Settings.HasLastFile == false)
        #expect(Settings.LastFileURL == nil)
    }
    
    @Test func ForgettingDoesNotChangeTheStartupOption() throws
    {
        let Sandbox = SettingsSandbox()
        defer { Sandbox.Cleanup() }
        let Source = try Sandbox.MakeFile("Source.xml", Contents: "<Colors/>")
        let Settings = Sandbox.Launch()
        Settings.LoadLastFileAtStartup = true
        Settings.RememberLastFile(from: Source)
        Settings.ForgetLastFile()
        #expect(Sandbox.Launch().LoadLastFileAtStartup == true)
    }
    
    // MARK: End to end
    
    /// The startup path: a real color file is remembered, then read back from the stored copy, and gives the same colors.
    @Test func StoredCopyLoadsLikeTheOriginal() throws
    {
        let Sandbox = SettingsSandbox()
        defer { Sandbox.Cleanup() }
        let Original = try #require(Bundle.main.url(forResource: "InitialBaseColors", withExtension: "xml"))
        let Settings = Sandbox.Launch()
        #expect(Settings.RememberLastFile(from: Original))
        
        let FromOriginal = try ColorListIO.parseXMLFile(url: Original)
        let Stored = try #require(Sandbox.Launch().LastFileURL)
        let FromCopy = try ColorListIO.parseXMLFile(url: Stored)
        #expect(FromCopy.importType == FromOriginal.importType)
        #expect(FromCopy.colorGroups?.count == FromOriginal.colorGroups?.count)
        #expect(FromCopy.fullColors?.ColorGroups?.count == FromOriginal.fullColors?.ColorGroups?.count)
        let OriginalCount = ColorSearchEngine.AllEntries(in: FromOriginal.fullColors?.ColorGroups ?? FromOriginal.colorGroups ?? []).count
        let CopyCount = ColorSearchEngine.AllEntries(in: FromCopy.fullColors?.ColorGroups ?? FromCopy.colorGroups ?? []).count
        #expect(OriginalCount > 0)
        #expect(CopyCount == OriginalCount)
        #expect(FromCopy.sourceURL == Stored)
    }
}
