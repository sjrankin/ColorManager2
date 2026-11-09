//
//  ColorNameSearchView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 4/17/26.
//

import SwiftUI

struct ColorNameSearchView: View
{
    @Binding var Searcher: SearchRecord?
    @State var SearchFor: String = ""
    @State var CharSet: Int = 0
    
    var body: some View
    {
        VStack
        {
            HStack
            {
                Spacer()
                Text("Color Name Search")
#if os(macOS)
                    .font(.largeTitle)
#else
                    .font(.title2)
#endif
                    .padding(2)
                Spacer()
            }
            Divider()
            Spacer()
            VStack
            {
                VStack
                {
                    HStack
                    {
                        Text("Search for")
                        TextField("", text: $SearchFor)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.15)))
                    }
                    .padding(.horizontal)
                    HStack
                    {
                        Text("Enter part of a color name. Use * for any run of characters and ? for any one character.")
                            .font(.footnote)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                Divider()
                HStack
                {
                    Text("Character sets")
                    Picker("", selection: $CharSet)
                    {
                        Text("All")
                            .tag(0)
                        Text("Only UTF8")
                            .tag(1)
                        Text("No UTF8")
                            .tag(2)
                    }
                    .pickerStyle(.segmented)
                    Spacer()
                }
                .padding(.horizontal)
                Spacer()
            }
        }
        // Publish the search whenever the input changes, and when this view appears.
        .onChange(of: SearchFor, initial: true)
        {
            PublishSearch()
        }
        .onChange(of: CharSet)
        {
            PublishSearch()
        }
    }
    
    /// Describe the current input as a name search for the caller.
    private func PublishSearch()
    {
        let Record = SearchRecord()
        Record.SearchType = .Name
        let Model = NameSearchModel()
        Model.NameSearch = SearchFor
        switch CharSet
        {
            case 1: Model.CharSet = .OnlyUTF8
            case 2: Model.CharSet = .NonUTF8
            default: Model.CharSet = .All
        }
        Record.NameSearch = Model
        Searcher = Record
    }
}

#Preview
{
    @Previewable @State var SearchHow: SearchRecord? = nil
    
    ColorNameSearchView(Searcher: $SearchHow)
}
