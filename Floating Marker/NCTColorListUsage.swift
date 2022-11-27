//
//  NCTColorListUsage.swift
//  Floating Marker
//
//  Created by John Pratt on 1/16/21.
//

import Cocoa

extension NSColor
{
    class func grayFromZeroToTen(num:Int) -> NSColor
    {
        let numClamped = num.clamped(to: 0...10)
        let grayFloat = CGFloat(numClamped) / 10
        return NSColor.init(white: grayFloat, alpha: 1.0)
    
    }

    class func crayonsColor(crayonName : String) -> NSColor?
    {
        return NSColorList.init(named: "Crayons")?.color(withKey: crayonName)
    }

}
