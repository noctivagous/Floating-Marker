//
//  FMPanel.swift
//  Floating Marker
//
//  Created by John Pratt on 1/11/21.
//

import Cocoa

class FMExteriorPanelContentView : NSView
{
    @IBOutlet var appDelegate : AppDelegate?

    override func mouseEntered(with event: NSEvent)
    {
        appDelegate?.makeMainFMDocumentTheKeyWindow();
    }
    
    override func mouseExited(with event: NSEvent)
    {
        appDelegate?.makeMainFMDocumentTheKeyWindow();
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true;
    }
    
    var trackingArea = NSTrackingArea();
    override func viewDidMoveToWindow() {
        
        // for mouseMoved events
        self.window?.acceptsMouseMovedEvents = true
        
        
        // for mouseEntered and Exited events
        let options = NSTrackingArea.Options.mouseEnteredAndExited.rawValue |
            NSTrackingArea.Options.activeAlways.rawValue;
        
        trackingArea = NSTrackingArea(rect: self.bounds, options: NSTrackingArea.Options(rawValue: options), owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
    
    // for keydown
    override var acceptsFirstResponder: Bool { return true }
    
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited,.mouseMoved],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }


}

class FMPanel: NSPanel {


    override func awakeFromNib()
    {
    
        becomesKeyOnlyIfNeeded = true;
        
    }
}
