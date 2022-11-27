//
//  KeyboardButton.swift
//  SVDraw
//
//  Created by John Pratt on 12/4/18.
//  Copyright © 2018 Noctivagous, Inc. All rights reserved.
//

import Cocoa

@IBDesignable


// ensures that flagsChanged is captured
// when the popover appears above a keyboardButton
class KeyboardButtonPopoverView : NSView{
    @IBOutlet var appDelegate : AppDelegate!

    override func flagsChanged(with event: NSEvent) {
        appDelegate.flagsChangedFromActiveLayer(event: event)
    }
    

}

class KeyboardButton: NSView {
    
    
    
    var backgroundPath : NSBezierPath = NSBezierPath()
    var backgroundGradientPath : NSBezierPath = NSBezierPath()

     var outlineStrokeColor : NSColor = .black;
    var outlineWidthFactor : CGFloat = 2.5;
    
    @IBInspectable var fontForegroundColor : NSColor = .black;

    
    var appDelegate : AppDelegate?

    @IBInspectable var usesPopover : Bool = true;
    @IBInspectable @objc dynamic  var buttonBackgroundColor : NSColor = .gray
    @IBInspectable @objc dynamic  var buttonText : String = "default";

    // drawingEntity switches to mode of buttonName, if it has more than one mode
    @IBInspectable @objc dynamic  var buttonName : String = String();

    @IBInspectable  var keyCode : Int = -1;
    var currentFlagsAndKeyCode : String = "";
    
    @IBInspectable  var configurationViewName : String = String();
    @IBInspectable  var line1Text : String = String();
    @IBInspectable  var line2Text : String = String();
    
    // for capslock key
    @IBInspectable  var isCapsLockKey : Bool = false;
    
    // if toggle, then draw horizontal strip at top
    // resembling sliding switch.
    @IBInspectable  var isToggle : Bool = false;
    
    @IBInspectable  var keyDescription : [String : String] = [:]
    
    
//    var backgroundDrawable : Drawable!
    
    @IBInspectable  var buttonDescription : String = "default description";
    
    
    var trackingArea : NSTrackingArea = NSTrackingArea()
    
    var showButtonHighlighted : Bool = false
    var showButtonDown : Bool = false
    
    var isDrawingButton : Bool = false;
    
//    @IBInspectable var isTransitive : Bool = false

    @objc dynamic var allowsKeyRepeats : Bool = false
    
    var buttonBackgroundImage : NSImage?
    @IBInspectable var drawsBackgroundImage : Bool = false;

    

    //var buttonDownNotification : Notification?
    //var buttonUpNotification : Notification?
    
    
    
    
    /*
    var fBackgroundColor : NSColor = NSColor();
    var usesOutlineStroke : Bool = false;
    var outlineStrokeColor : NSColor = NSColor();
    */
    

    
    override init(frame: NSRect) {
    
        super.init(frame: frame)
     
        setupButtonPath()
    }
     
     //initWithCode to init view from xib or storyboard
     required init?(coder aDecoder: NSCoder) {
     super.init(coder: aDecoder)
    

        setupButtonPath()
    
    }
    

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
        
    }
    
    
    
    func setupButtonPath()
    {

        backgroundPath.appendRoundedRect( self.bounds.insetBy(dx: 1.0, dy: 1.0), xRadius: 2.5, yRadius: 2.5)
        backgroundGradientPath.appendRoundedRect( self.bounds.insetBy(dx: 2.0, dy: 2.0), xRadius: 2.5, yRadius: 2.5)

    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        backgroundPath.removeAllPoints();
        
        let radius = 0.0957575 * self.bounds.size.height;
        
        /*
        if(isDrawingButton == false)
        {*/
            backgroundPath.appendRoundedRect( self.bounds.insetBy(dx: 1.0, dy: 1.0), xRadius: radius, yRadius: radius)
        /*}
        else
        {
        
           backgroundPath.appendRect(self.bounds.insetBy(dx: 1.0, dy: 1.0))
        }*/

        
        //NSColor.black.setFill()
    
        NSGraphicsContext.current?.saveGraphicsState()
        
            outlineStrokeColor.setStroke()
            
            if(showButtonHighlighted)
            {
                if(showButtonDown)
                {
                    let v:NSColor = buttonBackgroundColor.shadow(withLevel: 0.7)!
                    
                    v.setFill()
                    
                }
                else
                {
                let v:NSColor = buttonBackgroundColor.shadow(withLevel: 0.6)!
                v.setFill()
                    
                    
            
                    
                }
            }
            else
            {
                buttonBackgroundColor.setFill()
            
            }
            
            backgroundPath.fill()

            
            backgroundPath.lineWidth = outlineWidthFactor * 1 / 33.0 * NSHeight(self.bounds);
                
                /*
            if(isDrawingButton)
            {
                
                
            }
            else
            {
                backgroundPath.lineWidth = 1 / 33.0 * NSHeight(self.bounds);
            }*/
        
            
           // NSGraphicsContext.saveGraphicsState()
//            let ctx = NSGraphicsContext.current?.cgContext
           // ctx?.setBlendMode(CGBlendMode.lighten)
            
            let grad = NSGradient.init(colors: [NSColor.clear,NSColor.init(calibratedWhite: 0.7, alpha: 0.2),NSColor.clear], atLocations: [0,0.0,1.0], colorSpace:
             NSColorSpace.sRGB)
             grad?.draw(in: backgroundGradientPath, angle: 270)
             grad?.draw(in: backgroundGradientPath, angle: 0)
             grad?.draw(in: backgroundGradientPath, angle: 90)
        
            //NSGraphicsContext.restoreGraphicsState()
            
            
            backgroundPath.addClip()
       
        
        if(drawsBackgroundImage)
        {
            if(buttonBackgroundImage != nil)
            {
                let boundsInset = self.bounds.insetBy(dx: 0 /*0.1 * bounds.height*/, dy: 0);
                // boundsInset.origin.y -= 0.25 * boundsInset.height
                
                var imageSize = buttonBackgroundImage!.size;
                let widerThanTall = (imageSize.width >= imageSize.height) ? true : false;
                
                if(widerThanTall)
                {
                    imageSize.height = (boundsInset.width / imageSize.width) * imageSize.height
                    imageSize.width = boundsInset.width
                    
                }
                else
                {
                    imageSize.width = (boundsInset.height / imageSize.height) * imageSize.width
                    imageSize.height = boundsInset.height
                    
                }
                
                let imageRect = NSRect(origin: bounds.origin, size: imageSize).insetBy(dx: -0.15 * bounds.width, dy: -0.15 * bounds.height)
                
                // buttonBackgroundImage?.size = boundsInset.size
                //  buttonBackgroundImage?.draw(at: .zero, from: imageRect.centerInRect(boundsInset), operation: NSCompositingOperation.sourceOver, fraction: 0.5)
                
                buttonBackgroundImage?.draw(in: imageRect.centerInRect(boundsInset) );
                
                //  NSColor.black.setFill()
                //  imageRect.frame()
                //buttonBackgroundImage?.draw(in: self.bounds, from: self.bounds.insetBy(dx: 10, dy: <#T##CGFloat#>), operation: NSCompositingOperation.sourceOver, fraction: 1.0)
                //buttonBackgroundImage?.draw(in: self.bounds)
            }
            
        }
        
         if(self.isDrawingButton)
        {
            let dBP = NSBezierPath();
            let b = self.bounds//.insetBy(dx: 0.1 * self.bounds.width, dy: 0.1 * self.bounds.height)
            dBP.move(to: b.middleLeft())
            dBP.line(to: b.bottomRight())
            dBP.line(to: b.topRight())
            
            /*dBP.line(to: b.bottomMiddle().midpoint(pointB: b.bottomRight()))
            dBP.line(to: b.middleRight())
            dBP.line(to: b.middleRight().midpoint(pointB: b.topRight()))
            dBP.line(to: b.topMiddle().midpoint(pointB: b.topRight()))
            dBP.line(to: b.middleLeft())//.midpoint(pointB: b.topLeft()))
            dBP.line(to: b.bottomLeft().midpoint(pointB: b.middleLeft()))
           */
           dBP.close()
            
            
//            dBP.appendR/oundedRect( , xRadius: radius, yRadius: radius)
            let a = self.buttonBackgroundColor.blended(withFraction: 0.5, of: NSColor.black)?.withAlphaComponent(0.5)
            a?.setFill()
            dBP.fill()
            let b2 = a?.blended(withFraction: 0.5, of: NSColor.black)?.withAlphaComponent(0.5);
            b2?.setStroke()
            dBP.lineWidth = 2
            dBP.stroke()
            
        }
        
        
        
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineHeightMultiple = 0.75;
            
            var fontSizeFactor : CGFloat =  8.0 / 33.0;
            if(NSHeight(self.bounds) > 50)
            {
                fontSizeFactor = 7.5 / 33.0 // 7.0 / 33.0;
            }
        
            let fontSize : CGFloat = fontSizeFactor * NSHeight(self.bounds);
            
            /*
             let shadowForButtonKeyName2 = NSShadow()
                shadowForButtonKeyName2.shadowBlurRadius = 1.0
                shadowForButtonKeyName2.shadowOffset = NSSize(width: 1, height: -1)
                shadowForButtonKeyName2.shadowColor = NSColor.black
            */
 
            let attrs = [NSAttributedString.Key.font: NSFont(name: "DINAlternate-Bold", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize), NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor : fontForegroundColor
            /*, NSAttributedString.Key.shadow : shadowForButtonKeyName2*/]
            
            buttonText.draw(with: self.bounds.insetBy(dx: 1.0 / 33.0 * NSWidth(self.bounds), dy: 4.0 / 33.0 * NSHeight(self.bounds)).offsetBy(dx: 1, dy: 0), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        
        outlineStrokeColor.setStroke();
        

        backgroundPath.stroke()
        
       
        
            if(showButtonHighlighted)
            {
                paragraphStyle.alignment = .right
                paragraphStyle.lineHeightMultiple = 1.0;

                var fontSizeFactor2 : CGFloat = 20.0 / 33.0;
                if(buttonName.count > 1)
                {
                    fontSizeFactor2 = 10.0 / 33.0;
                }
                
                let fontSize2 : CGFloat = fontSizeFactor2 * NSHeight(self.bounds);
                
                
                
                
                let shadowForButtonKeyName = NSShadow()
                shadowForButtonKeyName.shadowBlurRadius = 5.0
                shadowForButtonKeyName.shadowOffset = NSSize(width: 2, height: -3)
                shadowForButtonKeyName.shadowColor = NSColor.black
 
                
                let attrs2 = [NSAttributedString.Key.font: NSFont(name: "DINAlternate-Bold", size: fontSize2) ?? NSFont.systemFont(ofSize: fontSize2), NSAttributedString.Key.paragraphStyle: paragraphStyle,
                             NSAttributedString.Key.foregroundColor : NSColor.white
                ,NSAttributedString.Key.shadow : shadowForButtonKeyName]
                
                //NSGraphicsContext.current?.compositingOperation = NSCompositingOperation.xor;
                buttonName.draw(with: self.bounds.insetBy(dx: 0, dy: 2.0 / 33.0 * NSHeight(self.bounds)).offsetBy(dx: -3, dy: -0.1 * self.bounds.height), options: .usesLineFragmentOrigin, attributes: attrs2, context: nil)
                
                
                
            }
            else
            {
                paragraphStyle.lineHeightMultiple = 1.0;
                paragraphStyle.alignment = .right
                
                
              var fontSizeFactor2 : CGFloat = 10.0 / 33.0;
                if(buttonName.count > 1)
                {
                    fontSizeFactor2 = 10.0 / 33.0;
                }
                
                let fontSize2 : CGFloat = fontSizeFactor2 * NSHeight(self.bounds);
                
                
         
                
                let shadowForButtonKeyName = NSShadow()
                shadowForButtonKeyName.shadowBlurRadius = 5.0
                shadowForButtonKeyName.shadowOffset = NSSize(width: 0, height: 0)
                shadowForButtonKeyName.shadowColor = NSColor.white
 
                
                let attrs2 = [NSAttributedString.Key.font: NSFont(name: "DINAlternate-Bold", size: fontSize2) ?? NSFont.systemFont(ofSize: fontSize2), NSAttributedString.Key.paragraphStyle: paragraphStyle,
                             NSAttributedString.Key.foregroundColor : NSColor.white.withAlphaComponent(0.5)
                ,NSAttributedString.Key.shadow : shadowForButtonKeyName
                /*,
                             NSAttributedString.Key.strokeWidth : 1.0,.strokeColor : NSColor.white*/] as [NSAttributedString.Key : Any]
                
                //NSGraphicsContext.current?.compositingOperation = NSCompositingOperation.xor;
                var bRect = self.bounds
                bRect.size.height = fontSize2;
                bRect = bRect.offsetBy(dx: -0.2 * fontSize2, dy: 0.1 * self.bounds.height);
//                .insetBy(dx: 0, dy: 2.0 / 33.0 * NSHeight(self.bounds)).offsetBy(dx: 0, dy: -0.1 * self.bounds.height)
                
                buttonName.draw(with: bRect, options: .usesLineFragmentOrigin, attributes: attrs2, context: nil)
            }
            
      
        
        NSGraphicsContext.current?.restoreGraphicsState()
        
        
    }
    

    
    override func mouseEntered(with event: NSEvent) {
      //  self.window?.isFloatingPanel.set(true)
 
            self.showButtonHighlighted = true
            self.needsDisplay = true
        
//            self.layer?.shadowOffset = NSMakeSize(1, -1)
    }
    
    
    override func mouseExited(with event: NSEvent) {
 
         if(self.isCapsLockKey)
        {
            if(NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.capsLock) == false)
            {
                self.showButtonHighlighted = false
                self.needsDisplay = true
            }
            
        }
        else
        {
            self.showButtonHighlighted = false
            self.needsDisplay = true
        }
        
//        self.layer?.shadowOffset = NSMakeSize(2, -2)
    
    }
    
    override func flagsChanged(with event: NSEvent)
    {
    
        appDelegate?.inputInteractionManager?.flagsChangedFromActiveLayer(event: event);
            
        
    }
    override func mouseDown(with event: NSEvent) {
        
        self.showButtonDown = true;
        self.needsDisplay = true;
        
        if(self.usesPopover)
        {
            if(appDelegate == nil)
            {
            
            }
            appDelegate?.showPopoverForKeyboardButton(keyboardButton: self);
        }
        
      //  let buttonDownNotification  =
       //     Notification(name: NSNotification.Name(rawValue: "ButtonDown"), object: self, userInfo: ["ButtonDown":self.buttonName]) as NSNotification
        
        //routes to same statemachine as keyboard.
       // NotificationCenter.default.post(buttonDownNotification as Notification)
   
    }
    
    override func mouseUp(with event: NSEvent) {
        self.needsDisplay = true
        self.showButtonDown = false
        
        let buttonUpNotification =
            Notification(name: NSNotification.Name(rawValue: "ButtonUp"), object: self, userInfo: ["ButtonUp":self.buttonName]) as NSNotification
        
        //routes to same statemachine as keyboard.
         NotificationCenter.default.post(buttonUpNotification as Notification)
        
    }
    
    
    override func awakeFromNib() {
        
        // post notification to NSApp delegate about
        // self for keyboardmappingsmanager
        let buttonInfoNotification =
            Notification(name: NSNotification.Name(rawValue: "ButtonIdentificationNotification"), object: self, userInfo: ["buttonName":self.buttonName]) as NSNotification
        
        //routes to same statemachine as keyboard.
        NotificationCenter.default.post(buttonInfoNotification as Notification)
        
        
     
    }
    
    
    override func viewDidMoveToWindow() {
        
        
        self.wantsLayer = true
        self.superview?.wantsLayer = true
   
        self.shadow = NSShadow()
        //self.layer?.backgroundColor = NSColor.red.cgColor
        self.layer?.cornerRadius = 3
        self.layer?.shadowOpacity = 1.0
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(2, -2)
        self.layer?.shadowRadius = 0;
        
        


       
        
    }
    
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
  
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
            owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
    
    
    
}


