//
//  ColorValueSearchView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 4/17/26.
//

import SwiftUI

struct ColorValueSearchView: View
{
    @Binding var Searcher: SearchRecord?
    @State var SearchTarget: PlatformColor = .white
    /// Largest color difference (Delta E) from `SearchTarget` that still counts as a match.
    @State var Tolerance: Double = 10.0
    /// How the difference between colors is measured.
    @State var Method: ColorDifferenceMethods = .CIE76
    /// Whether to search by nearness to a color or by hue, saturation, and brightness ranges.
    @State var SearchMode: ValueSearchModes = .NearestColor
    @State var HSBCriteria = HSBRangeCriteria()
    @State var SelectedColorSpace = SearchColorSpaces.RGB.rawValue
    
    var body: some View
    {
        VStack
        {
            Text("Color Value Search")
            Picker("Match by", selection: $SearchMode)
            {
                ForEach(ValueSearchModes.allCases)
                {
                    Mode in
                    Text(Mode.rawValue)
                        .tag(Mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            Spacer()
            if SearchMode == .HSBRanges
            {
                HSBRangeSearch(Criteria: $HSBCriteria)
                Spacer()
            }
            else
            {
                switch(SelectedColorSpace)
                {
                    case SearchColorSpaces.RGB.rawValue:
                        RGBValueSearch(SearchColor: $SearchTarget)
                    case SearchColorSpaces.Hex.rawValue:
                        HexValueSearch(SearchColor: $SearchTarget)
                    case SearchColorSpaces.HSB.rawValue:
                        HSBValueSearch(SearchColor: $SearchTarget)
                    case SearchColorSpaces.CMYK.rawValue:
                        CMYKValueSearch(SearchColor: $SearchTarget)
                    default:
                        RGBValueSearch(SearchColor: $SearchTarget)
                }
                Spacer()
                HStack
                {
                    Text("Tolerance")
                    Slider(value: $Tolerance, in: 0...50, step: 1)
                    Text(Tolerance, format: .number.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .frame(minWidth: 28, alignment: .trailing)
                }
                .padding(.horizontal)
                HStack
                {
                    Text("Difference")
                    Picker("Difference", selection: $Method)
                    {
                        ForEach(ColorDifferenceMethods.allCases)
                        {
                            Choice in
                            Text(Choice.rawValue)
                                .tag(Choice)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .padding(.horizontal)
                Picker("Color spaces",
                       selection: $SelectedColorSpace,
                       content:
                        {
                    ForEach(SearchColorSpaces.allCases)
                    {
                        SpaceName in
                        Text(SpaceName.rawValue)
                            .tag(SpaceName.rawValue)
                    }
                })
                .pickerStyle(.segmented)
                .padding(.bottom)
            }
        }
        // Publish the search whenever any input changes, and when this view appears.
        .onChange(of: SearchTarget, initial: true)
        {
            PublishSearch()
        }
        .onChange(of: Tolerance)
        {
            PublishSearch()
        }
        .onChange(of: Method)
        {
            PublishSearch()
        }
        .onChange(of: SearchMode)
        {
            PublishSearch()
        }
        .onChange(of: HSBCriteria)
        {
            PublishSearch()
        }
    }
    
    /// Describe the current input as a value search for the caller.
    private func PublishSearch()
    {
        let Record = SearchRecord()
        Record.SearchType = .Value
        let Model = ValueSearchModel()
        switch SearchMode
        {
            case .NearestColor:
                let Channels = Convert.DoubleChannels(From: SearchTarget)
                Model.SearchType = .Specified
                Model.Specified = (Float(Channels.red), Float(Channels.green), Float(Channels.blue))
                Model.Tolerance = Tolerance
                Model.Method = Method
                
            case .HSBRanges:
                Model.SearchType = .HSBRange
                Model.HueValue = HSBCriteria.Hue
                Model.HueRange = HSBCriteria.HueSpread * 2.0
                Model.Saturation = HSBCriteria.Saturation
                Model.SaturationRange = HSBCriteria.SaturationSpread * 2.0
                Model.Brightness = HSBCriteria.Brightness
                Model.BrightnessRange = HSBCriteria.BrightnessSpread * 2.0
        }
        Record.ValueSearch = Model
        Searcher = Record
    }
}

/// How a color value search chooses matches.
enum ValueSearchModes: String, CaseIterable, Identifiable
{
    var id: String
    {
        rawValue
    }
    /// Colors close to a specific color.
    case NearestColor = "Nearest color"
    /// Colors whose hue, saturation, and brightness fall within ranges.
    case HSBRanges = "HSB ranges"
}

enum SearchColorSpaces: String, CaseIterable, Identifiable
{
    var id: String
    {
        rawValue
    }
    case RGB = "RGB"
    case Hex = "Hex"
    case HSB = "HSB"
    case CMYK = "CMYK"
}

#Preview
{
    @Previewable @State var SearchHow: SearchRecord? = nil
    
    ColorValueSearchView(Searcher: $SearchHow)
}
