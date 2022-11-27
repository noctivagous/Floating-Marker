//
//  PreviewViews.swift
//  Floating Marker
//
//  Created by John Pratt on 5/27/21.
//

import Foundation
import Quartz

class DashPreview : NSView
{
    @IBOutlet var dashPopover : NSPopover?;
  //  @IBOutlet var drawingEntityManager : DrawingEntityManager?
   // @IBOutlet var panelsController : PanelsController?
    
    @IBInspectable var borderColor : NSColor = NSColor.black;
    @IBInspectable var borderColorEntered : NSColor = NSColor.green;
 
 
    var d : FMDrawableAggregratedSettings = FMDrawableAggregratedSettings.init(fmDrawable: FMDrawable())
    var dashSetting : LineDash = LineDash.init(count: 2, pattern: [1,1], phase: 0);
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        dashSetting = d.lineDash()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder:decoder)
        dashSetting = d.lineDash();
    }
 
    var trackingArea : NSTrackingArea = NSTrackingArea();
    
    override var acceptsFirstResponder: Bool { return true;}
 
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
        
    }
    
    override func mouseEntered(with event: NSEvent) {
    
        self.layer?.borderColor = borderColorEntered.cgColor;
        
        self.window!.makeKey();
        self.window!.makeFirstResponder(self);
        self.needsDisplay = true;
    
    }
    
    override func mouseExited(with event: NSEvent)
    {
        self.layer?.borderColor = borderColor.cgColor;

    }
    
        
    override func keyDown(with event: NSEvent)
    {
        if(event.keyCode == 48)
        {

             let point : NSPoint = self.window!.mouseLocationOutsideOfEventStream
            
             let mouseDownEvent : NSEvent = NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: NSEvent.ModifierFlags(rawValue: 0), timestamp: ProcessInfo().systemUptime, windowNumber: self.window!.windowNumber, context: nil, eventNumber: 200, clickCount: 1, pressure: 1.0)!
                    
            self.mouseDown(with: mouseDownEvent)
        
        }
   }
    
    override func mouseDown(with event: NSEvent) {
        
        
        if dashPopover != nil
        {
            dashPopover!.close();
            /* let contentView = colorPickerPopover.contentViewController?.view
             let window = contentView?.window
             window?.orderFront(nil)
             */
            
         //   panelsController?.originatingDCharactPreviewForColorPicker = self;
            
            NotificationCenter.default.post(name: Notification.Name.init("NCTCloseAnyPopovers"), object: self)
            dashPopover!.show(relativeTo: self.bounds, of: self, preferredEdge: NSRectEdge.minY)
            NotificationCenter.default.post(name: Notification.Name.init("NCTCurrentlyShownPopover"), object: dashPopover)
        }
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        /*
        if(panelsController != nil)
        {
        
            if(panelsController!.panelsAreInPaletteKeysState)
            {
                var keyForSelf : PaletteKeySetting;
                
                if(drawingEntityManager != nil)
                {
                    keyForSelf = drawingEntityManager!.currentPaletteKey;
                }
                else
                {
                    keyForSelf = (panelsController?.drawingEntityManager.currentPaletteKey)!;
                }
                
                dashSetting = keyForSelf.drawableCharacteristics.lineDash()
            }
            else
            {
                
                if(panelsController!.layersManager.currentDrawingLayerHasSelectedDrawables)
                {
                    let selected : [Drawable] = panelsController!.layersManager.currentDrawingLayer.selectedDrawables;
                    
                    if(selected.isEmpty == false)
                    {
                        dashSetting = selected.first!.drawableCharacteristics().lineDash();
                    }
                }
                
            }
            */
        
        dashSetting.display(inRect: self.bounds, isHorizontal: true, strokeColor: d.fmInk.mainColor, backgroundColor: NSColor.gray)
        //}
        
        NSColor.black.setFill();
        self.bounds.frame(withWidth: 3, using: NSCompositingOperation.sourceOver)
        
    }
    
    override func viewDidMoveToWindow() {

        self.wantsLayer = true
        self.layer?.borderColor = borderColor.cgColor;
        self.layer?.borderWidth = 2.0
        self.layer?.cornerRadius = 0.0
        
        self.focusRingType = .none;
        
    
    }
    
    override func updateTrackingAreas()
    {
        
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        

        
    }
    
}
