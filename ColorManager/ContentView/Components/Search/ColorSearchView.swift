//
//  ColorSearchView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 4/15/26.
//

import Foundation

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ColorSearchView: View
{
    @Environment(\.dismiss) var Dismiss
    @EnvironmentObject var colorList: ColorList
    @State var SelectedOption: Int = 0
    @State var SearchMethod: SearchRecord? = nil
    @State var SearchResults: [ColorSearchResult] = []
    @State var ShowResults: Bool = false
    /// The difference method behind the results' distances, if the last search measured distance.
    @State var ResultsMethod: ColorDifferenceMethods? = nil
    
    /// The search can run only if the input of the selected option has produced a search of the matching type.
    var CanSearch: Bool
    {
        guard let Method = SearchMethod else
        {
            return false
        }
        switch SelectedOption
        {
            case 0:
                return Method.SearchType == .Name &&
                !(Method.NameSearch?.NameSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            case 1:
                return Method.SearchType == .Value && Method.ValueSearch != nil
            default:
                return false
        }
    }
    
    /// Ask the main window to open the result's group and highlight the color.
    func Reveal(_ Result: ColorSearchResult)
    {
        colorList.RevealRequest = ColorRevealRequest(Record: Result.Record, Path: Result.PathComponents)
    }
    
    /// Run the current search against the loaded colors and show the results.
    func RunSearch()
    {
        guard let Method = SearchMethod else
        {
            return
        }
        SearchResults = ColorSearchEngine.Run(Method, in: colorList.colorGroups ?? [])
        ResultsMethod = Method.ValueSearch?.SearchType == .Specified ? Method.ValueSearch?.Method : nil
        ShowResults = true
    }

    var body: some View
    {
#if os(macOS)
        VStack(spacing: 0)
        {
            HStack
            {
                Spacer()
                Text("Color Searcher")
                    .font(.title)
                Spacer()
            }
            .padding()
            Divider()
            HStack(spacing: 0)
            {
                ColorSearchOptionView(Option: $SelectedOption)
                    .frame(width: 140)
                    .background(Color.secondary.opacity(0.08))
                Divider()
                Group
                {
                    switch SelectedOption
                    {
                        case 0:
                            ColorNameSearchView(Searcher: $SearchMethod)
                            
                        case 1:
                            ColorValueSearchView(Searcher: $SearchMethod)
                            
                        case 2:
                            ColorCameraSearchView(Searcher: $SearchMethod)
                        
                        default:
                            NoOptionView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
            Divider()
            HStack
            {
                Spacer()
                Button("Search")
                {
                    RunSearch()
                }
                .disabled(!CanSearch)
                Spacer()
                Button("Cancel")
                {
                    self.Dismiss()
                }
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $ShowResults)
        {
            SearchResultsView(Results: SearchResults, Method: ResultsMethod, OnReveal: Reveal)
        }
#else
        VStack(spacing: 0)
        {
            // Title
            Text("Color Searcher")
                .font(.title2.bold())
                .padding(.top, 16)
                .padding(.bottom, 8)

            Divider()

            // Option picker replaces sidebar on compact screens
            Picker("", selection: $SelectedOption)
            {
                Text("Name").tag(0)
                Text("Color").tag(1)
                Text("Camera").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Detail content
            Group
            {
                switch SelectedOption
                {
                    case 0:
                        ColorNameSearchView(Searcher: $SearchMethod)
                    
                    case 1:
                        ColorValueSearchView(Searcher: $SearchMethod)
                    
                    case 2:
                        ColorCameraSearchView(Searcher: $SearchMethod)
                    
                    default:
                        NoOptionView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack
            {
                Spacer()
                Button("Search")
                {
                    RunSearch()
                }
                .disabled(!CanSearch)
                Spacer()
                Button("Cancel")
                {
                    self.Dismiss()
                }
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .sheet(isPresented: $ShowResults)
        {
            SearchResultsView(Results: SearchResults, Method: ResultsMethod, OnReveal: Reveal)
        }
#endif
    }
}

struct NoOptionView: View
{
    var body: some View
    {
        VStack
        {
            Spacer()
            HStack
            {
                Spacer()
                Text("No search option set")
                Spacer()
            }
            Spacer()
        }
    }
}

struct ColorSearchOptionView: View
{
    @Binding var Option: Int

    private let options: [(label: String, value: Int)] =
    [
        ("Name",  0),
        ("Color", 1),
        ("Camera", 2)
    ]

    var body: some View
    {
        VStack(spacing: 0)
        {
            ForEach(options, id: \.value)
            { option in
                HStack
                {
                    Text(option.label)
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Option == option.value ? Color.accentColor.opacity(0.12) : Color.clear)
                .contentShape(Rectangle())
                .onTapGesture
                {
                    Option = option.value
                }
                Divider()
            }
            Spacer()
        }
    }
}
