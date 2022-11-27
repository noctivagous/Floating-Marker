//
//  FMInteriorPanel.swift
//  Floating Marker
//
//  Created by John Pratt on 1/16/21.
//

import Cocoa


enum InteriorPanelLocation {
    case top
    case right
    case left
    case bottom
}

class FMLayersPanel : FMInteriorPanel
{

    override var canBecomeKey: Bool
    {
        return true
    }

   override func animationResizeTime(_ newFrame: NSRect) -> TimeInterval
    {
        return 0.06
    }
    
      // MARK: INIT
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
    
        
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
    
        //becomesKeyOnlyIfNeeded = true;
    
       }
    
     override func positionToWindowAccordingToConfiguration()
    {
        if let parentWindowFrame : NSRect = self.parent?.frame
        {
    
            
            self.setFrameTopLeftPoint(parentWindowFrame.topLeft().offsetBy(x: -1, y: self.parent!.titlebarHeight + 1))
            var f = self.frame;

            f.origin.x = self.parent!.frame.bottomRight().x - f.size.width - 15
            f.origin.y = self.parent!.frame.bottomRight().y + 15;

            self.setFrame(f, display: true)
            
         
        }
        
    }
    
}

class FMPaintFillModeTrayPanel : FMInteriorPanel
{


    override func animationResizeTime(_ newFrame: NSRect) -> TimeInterval
    {
        return 0.06
    }

    override var canBecomeKey: Bool
    {
        return true
    }

    /*
    override var canBecomeMain: Bool
    {
        return false;
    }
    */

      // MARK: INIT
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
    
        
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
        
        becomesKeyOnlyIfNeeded = true;

       }
    
  override func positionToWindowAccordingToConfiguration()
    {
        if let parentWindowFrame : NSRect = self.parent?.frame
        {
    
            self.setFrameTopLeftPoint(parentWindowFrame.topLeft().offsetBy(x: -1, y: self.parent!.titlebarHeight + 1))
            var f = self.frame;
            f.size.width = parentWindowFrame.width - 17;
            self.setFrame(f, display: true)
            
         
        }
        
    }

}

class FMInteriorPanel: NSPanel {
    // MARK: OUTLETS
    @IBOutlet var fmDocument: FMDocument?
    
   
   override func animationResizeTime(_ newFrame: NSRect) -> TimeInterval
    {
        return 0.08
    }
    
    // MARK: VARIABLES
    var baseSize : NSSize = NSSize.zero;
    
    var isCollapsed : Bool
    {
        didSet
        {
           if(isCollapsed == true)
           {
                self.setContentSize(NSSize.zero);
            
           }
           else
           {
                self.setContentSize(baseSize)
           }
                
        }
        
    }
    
    var location : InteriorPanelLocation = InteriorPanelLocation.bottom;
    var fixedWidthOrHeight : Bool = false;
    
    
    // MARK: INIT
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        
        
        baseSize = contentRect.size;
        isCollapsed = false;
        
        
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
        
        // Set the opaque value off,remove shadows and fill the window with clear (transparent)
       
       self.isOpaque = false
        self.hasShadow = false
        self.backgroundColor = NSColor.clear
        
        // Change the title bar appereance
     //   self.title = "My Custom Title"
   
       self.titleVisibility = .hidden
        
        self.titlebarAppearsTransparent = true
      }

     
    @objc func  documentWindowDidResize(notification : Notification)
    {
        positionToWindowAccordingToConfiguration();
    }

    @objc func  documentWindowDidEnterFullscreen(notification : Notification)
    {
        positionToWindowAccordingToConfiguration();
    }
    
    @objc func  documentWindowDidExitFullscreen(notification : Notification)
    {
        positionToWindowAccordingToConfiguration();
    }
    
    
    func setupObserver()
    {
    
        
//        NotificationCenter.default.removeObserver(self);
        
//        NotificationCenter.default.addObserver(self, selector: #selector(documentWindowDidResize(notification:)), name: NSWindow.didResizeNotification, object: self.fmDocument!.docFMWindow)
        
        
        
        
        /*
        NotificationCenter.default.addObserver(self.parent!, selector: #selector(self.documentWindowDidResize(notification:)), name: NSWindow.didResizeNotification, object: nil)
        */
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self);
    }


    // called by:
    // document acting as window delegate:windowDidEndLiveResize
    // document acting as window delegate: windowDidResize
    // self: NSWindow.didResizeNotification
    func positionToWindowAccordingToConfiguration()
    {
        if let parentWindowFrame : NSRect = self.parent?.frame
        {
            self.setFrameOrigin(parentWindowFrame.origin.offsetBy(x: 0, y: -15));
         }
        
    }
    
    
/*
    func positionToWindowAccordingToConfiguration()
    {
        
        if let parentWindowFrame : NSRect = self.parent?.frame
        {
        var selfFrame  : NSRect = self.frame
        
        
    
        let titlebarHeightConditional : CGFloat = self.parent!.titlebarHeight
        
     
        
        
        
        // check for child windows
        // inside parent window
        // and if their bottom or top of frame
        // is placed at bottom or top of window,
        // find top most position
        
        
        if(location == InteriorPanelLocation.bottom)
        {
            // y offset
            // iterate through panelsController.bottomInteriorPanels
            // and add height until reaching self
            
            var offsetYIterated : CGFloat = 0;
            
            for interiorPanel in panelsController.bottomInteriorPanels
            {
                if((interiorPanel != self) && (interiorPanel.isVisible))
                {
                    offsetYIterated = offsetYIterated + interiorPanel.frame.size.height
                }
                else
                {
                    break;
                }
            }
            
            
            let yOffset = 1.0 + panelsController.horizontalScroller.frame.size.height;
            let xOffset = -1.0 - panelsController.verticalScroller.frame.size.width;
           
            selfFrame.size.width = parentWindowFrame.size.width + xOffset;
            
            selfFrame.origin.x = parentWindowFrame.origin.x
            selfFrame.origin.y = parentWindowFrame.origin.y + yOffset + offsetYIterated;
            
            
            
            
        }
        else if(location == InteriorPanelLocation.top)
        {
            // y offset
            // iterate through panelsController.topInteriorPanels
            // and add height until reaching self
            var offsetYIterated : CGFloat = 0;
            
            for interiorPanel in panelsController.topInteriorPanels
            {
                if((interiorPanel != self) && (interiorPanel.isVisible))
                {
                    offsetYIterated = offsetYIterated + interiorPanel.frame.size.height
                    
                    if(self.parent!.styleMask.contains(NSWindow.StyleMask.fullScreen))
                    {
                        
                        //offsetYIterated = offsetYIterated - titlebarHeightConditional
                        
                        
                        
                    }
                    
                }
                else
                {
                    break;
                }
            }
            
            
            if(self.parent!.styleMask.contains(NSWindow.StyleMask.fullScreen))
            {
                
             //   titlebarHeightConditional = -60
                
            }
            
            let yOffset :CGFloat = -3.0 - titlebarHeightConditional;
            
         
            
            let xOffset :CGFloat = -1.0 - panelsController.verticalScroller.frame.size.width;
            
            selfFrame.origin.x = parentWindowFrame.origin.x
            selfFrame.origin.y = yOffset + parentWindowFrame.maxY - selfFrame.size.height - offsetYIterated;
            
            selfFrame.size.width = parentWindowFrame.size.width + xOffset;
    
            
        }
        else if(location == InteriorPanelLocation.left)
        {
            // y offset
            // iterate through panelsController.topInteriorPanels
            // and add height until reaching self
            var offsetMaxYIterated : CGFloat = 0;
            var offsetMinYIterated : CGFloat = 0;
            
            for interiorPanel in panelsController.topInteriorPanels
            {
                offsetMaxYIterated = offsetMaxYIterated + interiorPanel.frame.size.height
                
            }
            
            for interiorPanel in panelsController.bottomInteriorPanels
            {
                offsetMinYIterated = offsetMinYIterated + interiorPanel.frame.size.height
                
            }
            
            
            if(fixedWidthOrHeight == false)
            {
                let yOffset : CGFloat = CGFloat(3.0) - titlebarHeightConditional - offsetMinYIterated - offsetMaxYIterated - NSHeight(panelsController.horizontalScroller.frame);
                
                
                selfFrame.origin.x = parentWindowFrame.origin.x;
                selfFrame.origin.y = parentWindowFrame.origin.y  + panelsController.horizontalScroller.frame.size.height + offsetMinYIterated;

                selfFrame.size.height = parentWindowFrame.size.height + yOffset// - offsetMaxYIterated;
            }
            else
            {
                selfFrame.origin.x = parentWindowFrame.origin.x;
                
                //let yOffset :CGFloat = -3.0 - titlebarHeightConditional - offsetMinYIterated - offsetMaxYIterated - panelsController.horizontalScroller.frame.size.height;
                
                selfFrame.origin.y = -5 + NSMaxY(parentWindowFrame) - selfFrame.size.height - titlebarHeightConditional - offsetMaxYIterated - 3.0
                
              
                if(selfFrame.origin.y < ( parentWindowFrame.origin.y + offsetMinYIterated + titlebarHeightConditional))
                {
                    let yOffset :CGFloat = 3.0 - titlebarHeightConditional - offsetMinYIterated - offsetMaxYIterated - panelsController.horizontalScroller.frame.size.height;
                    
                    
                    selfFrame.origin.x = parentWindowFrame.origin.x;
                    selfFrame.origin.y = parentWindowFrame.origin.y  + panelsController.horizontalScroller.frame.size.height + offsetMinYIterated;
                    
                    selfFrame.size.height = parentWindowFrame.size.height + yOffset// - offsetMaxYIterated;
                }
 
                
                
                //parentWindowFrame.origin.y + parentWindowFrame.size.height - titlebarHeightConditional - offsetMaxYIterated
                
                //selfFrame.size.height = parentWindowFrame.size.height + yOffset// - offsetMaxYIterated;
                
            }
            
        }

        
        self.setFrame(selfFrame, display: true)
        
    }
        else
        {
            print(self.title)
            fatalError();
        }
    
    } // end positionAccordingToWindowConfig
  */
}



extension NSWindow {
    var titlebarHeight: CGFloat {
        let contentHeight = contentRect(forFrameRect: frame).height
        return frame.height - contentHeight
    }
}
