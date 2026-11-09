//
//  SwatchColorView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 3/22/26.
//

import SwiftUI

struct SwatchColorView: View
{
    // These are plain inputs, not `@State`, so the view updates when the caller passes new values.
    var TheColor: Color = Color.yellow
    var SideLength: CGFloat = 64.0
    
    var body: some View
    {
        VStack
        {
            HStack
            {
                Rectangle()
                    .fill(TheColor)
                    .border(.black)
            }
        }
        .frame(width: SideLength, height: SideLength)
    }
}

#Preview
{
    SwatchColorView(TheColor: .green,
                SideLength: 84)
}
