//
//  DrawingBoard.swift
//  Floating Marker
//
//  Created by John Pratt on 1/10/21.
//

import Cocoa

// A container for
// the drawing page.
// It is the documentView for the window's NSScrollView


// It encloses the drawingPage (layers), surrounds it with
// horizontal and vertical margins.

class DrawingBoard: NSView
{
    @IBOutlet var drawingDocument : FMDocument?
    
    override var isFlipped: Bool
    {
        return true;
    }
    


    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true;
        
        
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder:decoder)
        self.wantsLayer = true;
        
    }

    override func awakeFromNib() {
         self.wantsLayer = true;
        
    }

    var inputInteractionManager : InputInteractionManager?
    {
        get{
        
            if let appDelegate = NSApp.delegate as? AppDelegate
            {
                return appDelegate.inputInteractionManager
            }
        
            return nil;
        }
    }
    
    
    
    var drawingPage : DrawingPage?

    
    override func draw(_ dirtyRect: NSRect) {
        
        NSColor.black.setFill()
        dirtyRect.fill();
        
        
    }
    
}
