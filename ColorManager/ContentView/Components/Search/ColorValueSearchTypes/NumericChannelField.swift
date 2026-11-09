//
//  NumericChannelField.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

/// A labeled text field that accepts only digits, clamps to `0` - `Maximum`, and reports each valid edit.
///
/// The field owns only the text; the caller reads the text back when `OnChange` is called.
struct NumericChannelField: View
{
    let Title: String
    let Maximum: Int
    @Binding var Value: String
    let OnChange: () -> Void
    
    var body: some View
    {
        VStack(alignment: .leading)
        {
            Text(Title)
            TextField("", text: $Value)
                .frame(maxWidth: 64)
                .onChange(of: Value)
            {
                _, New in
                var Cleaned = New.filter { $0.isASCII && $0.isNumber }
                if let Number = Int(Cleaned), Number > Maximum
                {
                    Cleaned = "\(Maximum)"
                }
                if Cleaned != New
                {
                    Value = Cleaned
                }
                if !Cleaned.isEmpty
                {
                    OnChange()
                }
            }
        }
    }
}
