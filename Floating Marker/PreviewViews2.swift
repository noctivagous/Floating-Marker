//
//  PreviewViews.swift
//  Graphite Glider Preview
//
//  Created by John Pratt on 7/5/20.
//  Copyright © 2020 Noctivagous, Inc. All rights reserved.
//

import Foundation


/*
class DrawableCharacteristicsPreview : NSView
{
    
    @IBOutlet var drawingEntityManager : DrawingEntityManager?
    @IBOutlet var panelsController : PanelsController?
    
    @IBOutlet var colorPickerPopover : NSPopover?;
    
    var drawableCharacteristics : DrawableCharacteristics = DrawableCharacteristics();
    var drawableForPreview : Drawable = Drawable()

    @IBInspectable var showsFill : Bool = true;
    @IBInspectable var showsStroke : Bool = true;
    
    @IBInspectable var mode : String = "fill-line-stroke-cap";  // "fill-line-stroke-cap" , "fill", "stroke"
    

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
        
    }
    

    override func mouseDown(with event: NSEvent) {
        
        if colorPickerPopover != nil
        {
        colorPickerPopover!.close();
       /* let contentView = colorPickerPopover.contentViewController?.view
        let window = contentView?.window
        window?.orderFront(nil)
     */
            
        panelsController?.originatingDCharactPreviewForColorPicker = self;
            
        NotificationCenter.default.post(name: Notification.Name.init("NCTCloseAnyPopovers"), object: self)
        colorPickerPopover!.show(relativeTo: self.bounds, of: self, preferredEdge: NSRectEdge.minY)
        NotificationCenter.default.post(name: Notification.Name.init("NCTCurrentlyShownPopover"), object: colorPickerPopover)
        
        }
        
    }
    
    
    override func draw(_ dirtyRect: NSRect)
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
                
                drawableCharacteristics = keyForSelf.drawableCharacteristics
            }
            else
            {
                
                if(panelsController!.layersManager.currentDrawingLayerHasSelectedDrawables)
                {
                    let selected : [Drawable] = panelsController!.layersManager.currentDrawingLayer.selectedDrawables;
                    
                    if(selected.isEmpty == false)
                    {
                        drawableCharacteristics = selected.first!.drawableCharacteristics();
                    }
                }
                
            }
        
        if(mode == "fill")
        {
            drawableCharacteristics.fillColor.drawSwatch(in: self.bounds)
            
            //drawableCharacteristics.drawShadingShapeDictionaryIn(rect: self.bounds);
 
            
            
            NSColor.black.setFill();
            self.bounds.frame(withWidth: 3, using: NSCompositingOperation.sourceOver)
            
        
            
        }
        else if(mode == "stroke")
        {
            drawableCharacteristics.strokeColor.drawSwatch(in: self.bounds)
            
            NSColor.black.setFill();
            self.bounds.frame(withWidth: 3, using: NSCompositingOperation.sourceOver)
        }
        else if(mode == "fill-line-stroke-cap")
        {
            drawableForPreview.applyDrawableCharacteristics(drawableCharacteristics)
        
        
            drawableForPreview.removeAllPoints();
        
            // leftmost, middle height
            let sP : NSPoint = NSMakePoint(NSMinX(self.bounds), NSMidY(self.bounds));
        
            drawableForPreview.move(to: sP);
        
            var mP : NSPoint = NSPoint.zero;
        
            // rightmost, middle height, with x minus some distance
            mP = NSMakePoint(NSMaxX(self.bounds) - (drawableForPreview.lineWidth * 2 + 3), NSMidY(self.bounds));
        
            if(drawableForPreview.lineWidth < 2)
            {
               // mP.x -= 5
            }
        
        
            //drawableForPreview.lineWidth = dCharact.lineWidth;
            //        drawableForPreview.lineCapStyle = dCharact.lineCapStyle;
            //      drawableForPreview.lineJoinStyle = dCharact.lineJoinStyle;
            drawableForPreview.line(to: mP );
            
            // 100 points below the bottom of the bounds
            drawableForPreview.line(to: NSMakePoint(mP.x, NSMinY(self.bounds) - 100) );
        
            mP.x = -100;
            drawableForPreview.line(to: mP )
            drawableForPreview.close();
            
            //let firstRect = drawableForPreview.bounds;
            
            mP = NSMakePoint(NSMaxX(self.bounds) - (drawableForPreview.lineWidth), NSMidY(self.bounds));
            if(drawableForPreview.lineWidth < 2)
            {
             //   mP.x -= 3
            }
            drawableForPreview.move(to: mP );
        
            mP.y = NSMinY(self.bounds);
            drawableForPreview.line(to: mP );
        
        
        
            // fill
        
        
        
        
            if(self.showsFill)
            {
                /*
                drawableCharacteristics.fillColor.setFill();
                drawableForPreview.fill();
                */
                
             //   if(drawableCharacteristics.usesFill)
           //     {
                    drawableCharacteristics.fillColor.drawSwatch(in:
                    NSMakeRect(0, 0, NSMaxX(self.bounds) - (drawableForPreview.lineWidth * 2 + 3), NSMidY(self.bounds))
                    )
               // }
               
               
               
                /*
                if(drawableCharacteristics.actsAsShadingShapeDictionary.isEmpty == false)
                {
                    drawableCharacteristics.drawShadingShapeDictionaryIn(rect:firstRect);
                    
                }*/
            }
            
        
            if(self.showsStroke)
            {
                drawableCharacteristics.strokeColor.setStroke();
                drawableForPreview.stroke();
            }
        
            
            if(drawableCharacteristics.usesFill == false)
            {
                drawableCharacteristics.fillColor.grayscaleVersionInvertedNoAlpha.setStroke();
                //NSColor.white.setStroke();
                
                var noStrokeBounds = bounds;
                noStrokeBounds.size.width = 50;
                noStrokeBounds.size.height /= 2;
                
                let noStrokePath = NSBezierPath();
                noStrokePath.move(to: noStrokeBounds.topLeft())
                noStrokePath.line(to: noStrokeBounds.bottomRight())
                
                noStrokePath.lineWidth = 2;
                noStrokePath.stroke();
                  
              
              /*
                NSBezierPath.strokeLine(from: NSMakePoint(bounds.minX, bounds.midY), to: NSMakePoint(bounds.maxX - (drawableForPreview.lineWidth * 2 + 3), bounds.minY))
                */
                
            }
            
            
            /*
            if(drawableCharacteristics.usesStroke == false)
            {
            
                NSColor.white.setStroke();
                NSBezierPath.strokeLine(from: NSMakePoint(NSMaxX(self.bounds) - (drawableForPreview.lineWidth), NSMidY(self.bounds)), to:
                NSMakePoint(NSMaxX(self.bounds) - (drawableForPreview.lineWidth), 0)
                );
                
            }*/
            
            if(drawableCharacteristics.hasLineShape)
            {
                let paragraphStyleLS = NSMutableParagraphStyle()
                paragraphStyleLS.alignment = .left
                
                
                
                let fontSize3 : CGFloat = 0.4 * NSHeight(frame);
                
                var b = self.bounds
                    b.size.height = fontSize3;
                
                var fontColor : NSColor = NSColor(calibratedWhite: 0.35, alpha: 0.8);
                
                if(panelsController!.layersManager.currentDrawingLayerHasSelectedDrawables)
                {
                    fontColor = NSColor(calibratedWhite: 0.25, alpha: 0.8)
                }
                
                let attrsLS = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: fontSize3, weight: NSFont.Weight.regular), NSAttributedString.Key.paragraphStyle: paragraphStyleLS,
                               NSAttributedString.Key.foregroundColor :  fontColor]
                
                let lineShapeString : String = "Line Shape"
                
              //  NSGraphicsContext.saveGraphicsState()
                
                    // for placing this block after drawing:
                    // NSGraphicsContext.current!.compositingOperation = NSCompositingOperation.destinationOver
                
                   // NSGraphicsContext.current!.compositingOperation = NSCompositingOperation.colorBurn
                
                     NSGraphicsContext.current?.saveGraphicsState()
            
            let a = NSShadow()
            a.shadowBlurRadius = 1.0
            a.shadowOffset = NSSize(width: 2, height: -2)
            a.shadowColor = NSColor.white
        
            a.set()
                
                    lineShapeString.draw(in: b, withAttributes: attrsLS)
            NSGraphicsContext.current?.restoreGraphicsState();
            
               // NSGraphicsContext.restoreGraphicsState();
            }
            // draw number
    
        }
    
                
        
    }
    
    override func viewDidMoveToWindow() {
        
        
       
        
    }

    override func awakeFromNib() {
        
        
    }
    
}
*/
/*
class DashPreview : NSView
{
    @IBOutlet var dashPopover : NSPopover?;
  //  @IBOutlet var drawingEntityManager : DrawingEntityManager?
   // @IBOutlet var panelsController : PanelsController?
    
    @IBInspectable var borderColor : NSColor = NSColor.black;
    @IBInspectable var borderColorEntered : NSColor = NSColor.green;
 
 
    var d : DrawableCharacteristics = DrawableCharacteristics();
    var dashSetting : LineDash!;
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        dashSetting = d.lineDash();
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
            
            dashSetting.display(inRect: self.bounds, isHorizontal: true, strokeColor: d.strokeColor, backgroundColor: NSColor.gray)
        }
        
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
*/

class SuperShapePreview: NSView
{
    var radius :CGFloat = 100.0;
    
    var n1 :CGFloat = 0.5; // 0.5 is the minimum for usefulness
    var n2 :CGFloat = 0.5;
    var n3 :CGFloat = 0.5;
    var m :CGFloat = 1;
    var a :CGFloat = 1;
    var b :CGFloat = 1;
    

    
    override func draw(_ dirtyRect: NSRect)
    {
      //  NSColor.white.setFill()
      //  dirtyRect.fill()
        
        
        var total :CGFloat = 300.0;
        
        if(m > 10)
        {
            total = CGFloat((m / 10.0) * total)
        }
        
        let increment : CGFloat = (CGFloat.pi * 2) / total;
        
        let v = NSBezierPath()
        
        var firstPoint : CGPoint = CGPoint.zero
        
        for angle in stride(from: 0, to: (CGFloat.pi * 2), by: increment) {
            
            let r = supershape(angle);
            let x = radius * r * cos(angle);
            let y = radius * r * sin(angle);
            
            // NSColor.gray.setFill()
            // let f = NSMakeRect( CGFloat(x + 140.0), CGFloat(y + 200.0) , CGFloat(2.0), CGFloat(2.0))
            //  f.fill()
            
            if(angle == 0)
            {
                firstPoint = NSMakePoint(x,y)
                v.move(to: firstPoint)
            }
            else if((angle + increment) > (CGFloat.pi * 2))
            {
                v.line(to: firstPoint)
            }
            else
            {
                v.line(to: NSMakePoint(x,y))
            }
            
            
        }
        
        v.close()
        
        let xform = AffineTransform(translationByX: self.bounds.midX, byY: self.bounds.midY)
        v.transform(using: xform)
        
        
        NSColor.white.setStroke();
        v.stroke()
       // v.fill()
        
        
        
        NSBezierPath.strokeLine(from: NSMakePoint(self.bounds.midX, self.bounds.midY), to: NSMakePoint(self.bounds.midX + radius, self.bounds.midY))
        
        
    }
    
    
    func supershape(_ theta:CGFloat) -> CGFloat {
        
        var part1 :CGFloat = (1 / a) * cos(theta * m / 4);
        part1 = abs(part1);
        part1 = pow(part1, n2);
        
        var part2 :CGFloat = (1 / b) * sin(theta * m / 4);
        part2 = abs(part2);
        part2 = pow(part2, n3);
        
        let part3 :CGFloat = pow(part1 + part2, 1 / n1);
        
        if (part3 == 0) {
            return 0;
        }
        
        return (1 / part3);
        
    }

}




class CircleFramePreview: NSControl {
    
    @IBOutlet var configurationWindowManager : ConfigurationWindowManager?


    var circleDrawableForPreview : CircularlyContainedDrawable = CircularlyContainedDrawable();

    // for keydown and mousedown
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
        
    }
    
    
    // MARK: ---  POPOVER
    @IBInspectable @objc dynamic var showsPopoverOnMouseDown : Bool = false
    
    
    @IBInspectable var strokeColor : NSColor = NSColor.white;
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
       
       
        //       c.transform(using: AffineTransform(translationByX: frame.size.width / 2, byY: frame.size.height / 2))
    }
    
    required init?(coder decoder: NSCoder)
    {
        super.init(coder:decoder)
        
       
    }
    
    func remakePreviewDrawableUsingBoundsRectInsetBy10Percent()
    {
        let b = self.bounds;
        
        //let inset = min(self.bounds.width, self.bounds.height);
        
        let b2 = b.insetBy(dx: 0.15 * (self.bounds.width), dy: 0.15 * self.bounds.height);
    
        circleDrawableForPreview.setPointsForRadius(origin: NSMakePoint(b2.midX, b2.midY), circumference: NSMakePoint(b2.maxX, b2.midY));
        
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        
            /*
        
        strokeColor.setStroke();
        c.stroke();
        
        NSColor.orange.setStroke();
        NSBezierPath.strokeLine(from: c.centerOrigin, to: c.circleCircumferencePoint)
        */
        
        if(configurationWindowManager != nil)
        {
        

            self.circleDrawableForPreview.display();
            self.circleDrawableForPreview.radiusDisplay();
        
            
        }
        
        
    }
    
    
    
    override func mouseDown(with event: NSEvent) {

        if(showsPopoverOnMouseDown)
        {
            if(configurationWindowManager != nil)
            {
               configurationWindowManager?.openCircleFramePopover(self)
                //circleFramePopover!.show(relativeTo: self.bounds, of: self, preferredEdge: NSRectEdge.minY);
            }


        }

    }
    
    
    override func awakeFromNib() {
        
        /*
        c.circleOrigin = NSMakePoint(NSMidX(bounds), NSMidY(bounds));
        c.circleCircumferencePoint = NSMakePoint(NSMidX(bounds) + (bounds.size.width / 2.5), NSMidY(bounds));
        c.setPointsForRadius(origin: c.circleOrigin, circumference: c.circleCircumferencePoint);
        c.strokeColor = NSColor.white;
        */
        
    }
    
}
