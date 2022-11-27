//
//  BooleanPathsView.swift
//  SwiftVectorBooleanMac
//
//  Created by John Pratt on 12/29/18.
//  Copyright © 2018 Noctivagous, Inc. All rights reserved.
//

import Cocoa


class BooleanPathsView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.blue.setFill()
        dirtyRect.fill()
   
        NSColor.white.set()
        
        let rectangle = NSBezierPath(rect: NSMakeRect(20, 80, 300, 300))
        let circle = NSBezierPath(ovalIn: NSMakeRect(90, 40, 300, 300))

       
      
     
       // rectangle.stroke()
       // circle.stroke()
      
        
        let pathUnion = circle.fb_difference(rectangle)
        
        pathUnion.fill()
        NSColor.red.setStroke()
        pathUnion.stroke()
    }
    
}
