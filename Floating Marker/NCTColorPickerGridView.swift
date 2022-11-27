//
//  NCTColorPickerGridView.swift
//  colorListsDisplayWithTintAndShade
//
//  Created by John Pratt on 2/7/21.
//

import Cocoa

    
                    
class NCTColorPickerGridView: NSView
{

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true;
    }
    
    @IBOutlet var inkAndLineSettingsManager : InkAndLineSettingsManager?
    
    var hidesSelfAfterFirstColorSelection : Bool = false;
    
    var colorPickerOpacity : CGFloat = 1.0
    {
        didSet
        {
            opacitySlider?.setCGFloatValue(colorPickerOpacity * 10)
            regenerateImage()
            self.needsDisplay = true;
        }
    }
    @IBOutlet var opacitySlider : NCTSlider?
    @IBAction func changeOpacity(_ sender : NCTSlider)
    {
        colorPickerOpacity = sender.cgfloatValue() / 10;
        
        let color = inkAndLineSettingsManager!.colorBasedOnSelectedOrCurrentStroke.withAlphaComponent(self.colorPickerOpacity);
        
        inkAndLineSettingsManager?.updateColorWellBasedOnSelectionState(color: color)

    }
    
    // called from inkAndLineSettingsManager
    func updateSelectedColor()
    {
        colorPickerOpacity = inkAndLineSettingsManager?.colorBasedOnSelectedOrCurrentStroke.alphaComponent ?? 1.0;
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
    // self.postsBoundsChangedNotifications = true;
        
    // NotificationCenter.default.addObserver(self, selector: #selector(boundsDidChange(notification:)), name: NSView.boundsDidChangeNotification, object: self)
       
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder:decoder)
     
      
        //  self.postsBoundsChangedNotifications = true;
      
    }

    
    @objc func frameDidChange( notification : Notification?)
    {
        
        self.regenerateImage();
        
    }
  
    var imgToDisplay : NSImage?
  
    func regenerateImage()
    {
        
        
        imgToDisplay = NSImage.init(size: self.bounds.size, flipped: false) { (rect) -> Bool in
            
            NSColor.white.setFill()
            rect.fill();
            
            let horizontalCount : CGFloat = 64 // rect.width / 20;
            
            
            let rows : CGFloat = 6;
            let rowHeight :CGFloat = rect.height / rows;
            
            // black and white
            let grayscaleRectCount : CGFloat = 20;
            let grayscaleRectWidth = rect.width / grayscaleRectCount;
            
      
            // MARK: GRAYSCALE SQUARES
            for i : CGFloat in stride(from: 0, through: grayscaleRectCount, by: 1)
            {
                let colorForFill = NSColor.init(calibratedHue: 0, saturation: 0, brightness: 1.0 - i / grayscaleRectCount, alpha: 1.0);
                
                let rectToFill = NSIntegralRect(NSMakeRect(i * (rect.width / grayscaleRectCount),0,grayscaleRectWidth,rect.height / 6))
                
                colorForFill.setFill()
                rectToFill.fill();
            }
            
            
            
            for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
            {
                let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 0.5, brightness: 0.5, alpha: 1.0);
                
                let rectToFill = NSMakeRect(i * (rect.width / horizontalCount),rowHeight,horizontalCount, rowHeight)
                
                colorForFill.setFill()
                rectToFill.fill();
            }
            
            
            
            for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
            {
                let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 0.5, brightness: 0.25, alpha: 1.0);
                
                let rectToFill = NSMakeRect(i * (rect.width / horizontalCount),rowHeight,horizontalCount, rowHeight / 2)
                
                colorForFill.setFill()
                rectToFill.fill();
            }
            
            for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
            {
                let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 0.5, brightness: 0.75, alpha: 1.0);
                
                let rectToFill = NSMakeRect(i * (rect.width / horizontalCount),2 * rowHeight,horizontalCount, rowHeight)
                
                colorForFill.setFill()
                rectToFill.fill();
            }
            
            for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
            {
                let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 0.75, brightness: 1.0, alpha: 1.0);
                
                let rectToFill = NSMakeRect(i * (rect.width / horizontalCount),4 * rowHeight,horizontalCount, rowHeight)
                
                colorForFill.setFill()
                rectToFill.fill();
            }
            
            for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
            {
                let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 0.5, brightness: 1.0, alpha: 1.0);
                
                let rectToFill = NSMakeRect(i * (rect.width / horizontalCount),3 * rowHeight,horizontalCount, rowHeight)
                
                colorForFill.setFill()
                rectToFill.fill();
            }
            
            
            for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
            {
                let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 1.0, brightness: 1.0, alpha: 1.0);
                
                let rectToFill = NSMakeRect(i * (rect.width / horizontalCount),5 * rowHeight,horizontalCount, rowHeight)
                
                colorForFill.setFill()
                rectToFill.fill();
            }
            
        
            
            /*
             for i : CGFloat in stride(from: 0, to: horizontalCount, by: 1)
             {
             let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 1.0, brightness: 0.5, alpha: 1.0);
             
             let rectToFill = NSMakeRect(i * (rect.width / horizontalCount),rect.height * 2 / 3,horizontalCount,rect.height / 6)
             
             colorForFill.setFill()
             rectToFill.fill();
             }*/
             
               /*
            for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
            {
                for j : CGFloat in stride(from: 0, through: rect.height / rowHeight, by: 1)
                {
                    let rectToFill = NSMakeRect(i * rect.width / horizontalCount, j * rect.height / rowHeight, rect.width / horizontalCount, rowHeight)
                    NSColor.white.setFill()
                    rectToFill.frame();
                }
                
               
            }*/
            
            
            
            return true;
        }
        
        
    }
    
       
    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)
       
        if(imgToDisplay != nil)
        {
            imgToDisplay?.draw(in: self.bounds, from: self.bounds, operation: NSCompositingOperation.sourceOver, fraction: colorPickerOpacity)
        }
       
       /*
        NSColor.white.setFill()
        dirtyRect.fill();
        
        let horizontalCount : CGFloat = 64 // self.bounds.width / 20;
        
        
        let rows : CGFloat = 6;
        let rowHeight :CGFloat = self.bounds.height / rows;
        
        // black and white
        let grayscaleRectCount : CGFloat = 20;
        let grayscaleRectWidth = self.bounds.width / grayscaleRectCount;
        
        for i : CGFloat in stride(from: 0, through: grayscaleRectCount, by: 1)
        {
            let colorForFill = NSColor.init(calibratedHue: 0, saturation: 0, brightness: 1.0 - i / grayscaleRectCount, alpha: 1.0);
            
            let rectToFill = NSIntegralRect(NSMakeRect(i * (self.bounds.width / grayscaleRectCount),0,grayscaleRectWidth,self.bounds.height / 6))
            
            colorForFill.setFill()
            rectToFill.fill();
        }
        
        
        
        for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
        {
            let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 0.5, brightness: 0.5, alpha: 1.0);
            
            let rectToFill = NSMakeRect(i * (self.bounds.width / horizontalCount),rowHeight,horizontalCount, rowHeight)
            
            colorForFill.setFill()
            rectToFill.fill();
        }
        
        for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
        {
            let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 0.5, brightness: 0.25, alpha: 1.0);
            
            let rectToFill = NSMakeRect(i * (self.bounds.width / horizontalCount),rowHeight,horizontalCount, rowHeight / 2)
            
            colorForFill.setFill()
            rectToFill.fill();
        }
        
        for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
        {
            let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 0.5, brightness: 0.75, alpha: 1.0);
            
            let rectToFill = NSMakeRect(i * (self.bounds.width / horizontalCount),2 * rowHeight,horizontalCount, rowHeight)
            
            colorForFill.setFill()
            rectToFill.fill();
        }
        
        for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
        {
            let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 0.75, brightness: 1.0, alpha: 1.0);
            
            let rectToFill = NSMakeRect(i * (self.bounds.width / horizontalCount),4 * rowHeight,horizontalCount, rowHeight)
            
            colorForFill.setFill()
            rectToFill.fill();
        }
        
        for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
        {
            let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 0.5, brightness: 1.0, alpha: 1.0);
            
            let rectToFill = NSMakeRect(i * (self.bounds.width / horizontalCount),3 * rowHeight,horizontalCount, rowHeight)
            
            colorForFill.setFill()
            rectToFill.fill();
        }
        
        for i : CGFloat in stride(from: 0, through: horizontalCount, by: 1)
        {
            let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 1.0, brightness: 1.0, alpha: 1.0);
            
            let rectToFill = NSMakeRect(i * (self.bounds.width / horizontalCount),5 * rowHeight,horizontalCount, rowHeight)
            
            colorForFill.setFill()
            rectToFill.fill();
        }
        
        /*
         for i : CGFloat in stride(from: 0, to: horizontalCount, by: 1)
         {
         let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 0.5, brightness: 0.7, alpha: 1.0);
         
         let rectToFill = NSMakeRect(i * (self.bounds.width / horizontalCount),self.bounds.height / 5 / 6,horizontalCount,self.bounds.height / 6)
         
         colorForFill.setFill()
         rectToFill.fill();
         }*/
        
        /*
         for i : CGFloat in stride(from: 0, to: horizontalCount, by: 1)
         {
         let colorForFill = NSColor.init(calibratedHue: i / horizontalCount, saturation: 1.0, brightness: 0.5, alpha: 1.0);
         
         let rectToFill = NSMakeRect(i * (self.bounds.width / horizontalCount),self.bounds.height * 2 / 3,horizontalCount,self.bounds.height / 6)
         
         colorForFill.setFill()
         rectToFill.fill();
         }
         */
        
        
        
        
        */
        
        
    }// END draw
    
    
    var trackingArea = NSTrackingArea();
    override func viewDidMoveToWindow() {
        
        // for mouseMoved events
        self.window?.acceptsMouseMovedEvents = true
        
        
        // for mouseEntered and Exited events
        let options = NSTrackingArea.Options.mouseEnteredAndExited.rawValue |
            NSTrackingArea.Options.activeAlways.rawValue;
        
        trackingArea = NSTrackingArea(rect: self.bounds, options: NSTrackingArea.Options(rawValue: options), owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
        self.postsFrameChangedNotifications = true;
        
        NotificationCenter.default.addObserver(self, selector: #selector(frameDidChange(notification:)), name: NSView.frameDidChangeNotification, object: self)
        
        regenerateImage();
    }
    
    override func mouseDown(with event: NSEvent)
    {
    
        if let imgRep = NSBitmapImageRep.init(data: imgToDisplay!.tiffRepresentation!)
        {
        
            let mousePoint = self.convert(event.locationInWindow, from: nil)
            var color : NSColor = imgRep.colorAt(x:Int(mousePoint.x), y:Int(imgRep.size.height - mousePoint.y)) ?? NSColor.green;
            color = color.withAlphaComponent(self.colorPickerOpacity) ;
            inkAndLineSettingsManager?.updateColorWellBasedOnSelectionState(color: color)
            
            if(hidesSelfAfterFirstColorSelection)
            {
                self.window?.setIsVisible(false)
                
            }
            
        }
        
    }
    
    override func mouseDragged(with event: NSEvent)
    {
         if let imgRep = NSBitmapImageRep.init(data: imgToDisplay!.tiffRepresentation!)
        {
        
            let mousePoint = self.convert(event.locationInWindow, from: nil)
            var color : NSColor = imgRep.colorAt(x:Int(mousePoint.x), y:Int(imgRep.size.height - mousePoint.y)) ?? NSColor.green;
            color = color.withAlphaComponent(self.colorPickerOpacity) ;

            inkAndLineSettingsManager?.updateColorWellBasedOnSelectionState(color: color)
        }
        
    }
    
    override func mouseEntered(with event: NSEvent) {
            
            self.window?.makeFirstResponder(self)
            NSCursor.crosshair.set();
    }
    
    override func mouseExited(with event: NSEvent)
    {
        NSCursor.arrow.set();

        
    }
    
    
    override func mouseMoved(with event: NSEvent)
    {
        if(NSCursor.current != NSCursor.crosshair)
        {
         //   NSCursor.crosshair.set();
        }
    
    
    }
    
    func selectColorAtCursor()
    {
         let w : NSWindow = self.window!
            let p : NSPoint = w.mouseLocationOutsideOfEventStream
           
           
        guard NSPointInRect(p, self.frame) else {
            print("point was not inside color grid view")
            return
        }
            
            let eventPressure = 0.7111
            
            
            let event = NSEvent.mouseEvent(with: .leftMouseDown, location: p, modifierFlags: NSEvent.ModifierFlags.shift, timestamp: ProcessInfo().systemUptime, windowNumber: (self.window?.windowNumber)!, context: nil, eventNumber: 199, clickCount: 1, pressure: Float(eventPressure))
            
            self.mouseDown(with: event!)
    }
    
    override func keyDown(with event: NSEvent)
    {
      
        if(event.keyCode == 48) // TAB KEY
        {
       
            
        }
        
        if(event.keyCode == 40) // 'K' KEY
        {
        
        
        }
       
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


// SCRAP
//let crayonsColorList = NSColorList.init(named: "Crayons")!
    //    let count = CGFloat(crayonsColorList.allKeys.count)
     //   let b = self.bounds.width / count;
       // var counter : CGFloat = 0;
     /*   for key in crayonsColorList.allKeys
        {
//            print(key)
            let color = crayonsColorList.color(withKey: key) ?? NSColor.black;
            
            color.setFill()
            
            let rectToFill = NSMakeRect(counter * b,0,b,self.bounds.height / 3)
            rectToFill.fill();
            
            counter += 1;
        }
       */
