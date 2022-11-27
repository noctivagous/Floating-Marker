//
//  ColorPickerView.swift
//  NCTColorPicker
//
//  Created by John Pratt on 1/25/19.
//  Copyright © 2019 Noctivagous, Inc. All rights reserved.
//

import Cocoa

class ColorPickerView: NSView {
    @IBOutlet var highlightedColorsArrayView : PickedColorsArrayView?
    @IBOutlet var pickedColorsArrayView : PickedColorsArrayView?
    @IBOutlet var colorSetsPopUpButton : NSPopUpButton!
    @IBOutlet var colorWell : NSColorWell!
    var launchingColorWell : NSColorWell?
    
    @IBOutlet var opacityTextField : NSTextField?
    @IBOutlet var opacitySlider : NSSlider!
    
    @IBOutlet var brightnessTextField : NSTextField?
    @IBOutlet var brightnessSlider : NSSlider!
    
    
    @IBInspectable var selectionModeUsesPickedViews : Bool = true;
    
    var trackingArea : NSTrackingArea!
    var pickerCenterPoint : NSPoint = NSPoint.zero
    var pickerRadiusComputed : CGFloat {
        get
        {
            return (min(self.bounds.width,self.bounds.height) / 2.0) - 4.0;
        }
    }
    
    var pickerStrokeThickness : Int = 6
    var pickerSectorAngle : CGFloat = 15.0
    var pickerSpacingBetweenRings : CGFloat = 0
    var pickerIinteriorOffsetCount : Int = 0
    var mouseLocation : NSPoint = NSPoint.zero
    var truncatedRadius : CGFloat
    {
        get{
            return CGFloat(numberOfSegmentsPerRadius) * CGFloat(pickerStrokeThickness);
        }
        
    }
    
    var angleInDegrees : CGFloat = 0.0
    var angleClockwiseRadians : CGFloat = 0.0
    var pickerInteriorOffsetCount : Int = 0
    
    var numberOfSegmentsPerRadius : Int {
        
        get
        {
        return Int(pickerRadiusComputed / CGFloat(pickerStrokeThickness));
        }
    }
    
    var numberOfSectors : Int {
        
        get
        {
            return Int(360.0 / pickerSectorAngle);
        }
    }
    
    
    var colorPickerAlpha : CGFloat = 1.0
    {
        didSet{

            // clamp the value to range of 0 through 1
          // colorPickerAlpha = colorPickerAlpha.clamped(to: 0...1)


          //  opacityTextField?.doubleValue = Double(colorPickerBrightness)
          //  opacitySlider.doubleValue = Double(colorPickerBrightness);

           // reloadViewsForColorUpdate();

        }
    }
    var colorPickerBrightness : CGFloat = 1.0
    {
        didSet{

            // clamp the value to range of 0 through 1
         //colorPickerBrightness = colorPickerBrightness.clamped(to: 0...1)

         //   brightnessTextField?.doubleValue = Double(colorPickerAlpha)
         //   brightnessSlider.doubleValue = Double(colorPickerAlpha)

       // reloadViewsForColorUpdate();
                
        }
    }
    
    var colorValue : String = "color"
    
    
    var storedOpacityForSegmentedControl : CGFloat = 0.5;
   
    var dictionaryOfColorSets =
        [   "single_color" : [0],
            "complementary" : [0,180],
            "split_complementary" : [0,200,170],
            "triads" : [0, 240,120,],
            "analogous" : [20,0,350],
            "mutual_complements" : [0,210,180,150],
            "near_complements" : [0,170],
            "double_complements" : [15,0,200,180]
        ]
    
    var highlightedColorsArray : [NSColor] = []
    var highlightedColorAnglesArray : [Int] = []
    var highlightedColorAnglesSegment : CGFloat = 0.0
    var highlightedColorAnglesRadius : CGFloat = 0.0
    
    var pickedColorsArray : [NSColor] = []
    var pickedColorAnglesArray : [Int] = []
    var pickedColorAnglesSegment : CGFloat = 0.0
    var pickedColorAnglesRadius : CGFloat = 0.0
    
    var colorSet = "single_color"
    
    var numberOfColorsInColorSet : Int = 1
  
    override func viewDidMoveToWindow() {
        
        // for mouseMoved events
        self.window?.acceptsMouseMovedEvents = true
        
        
        // for mouseEntered and Exited events
        let options = NSTrackingArea.Options.mouseEnteredAndExited.rawValue |
            NSTrackingArea.Options.activeAlways.rawValue;
        
        trackingArea = NSTrackingArea(rect: bounds, options: NSTrackingArea.Options(rawValue: options), owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
    
   
    override func updateTrackingAreas()
    {
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited,.mouseMoved,],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
    
    override func mouseEntered(with event: NSEvent)
    {
    
        self.window!.makeKey()
        self.window!.makeFirstResponder(self)
        self.needsDisplay = true;

    }
    
    override func keyDown(with event: NSEvent)
    {
        if(event.keyCode == tabKey)
        {
            
             let point : NSPoint = self.window!.mouseLocationOutsideOfEventStream
            
             let mouseDownEvent : NSEvent = NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: NSEvent.ModifierFlags(rawValue: 0), timestamp: ProcessInfo().systemUptime, windowNumber: self.window!.windowNumber, context: nil, eventNumber: 200, clickCount: 1, pressure: 1.0)!
                    
            self.mouseDown(with: mouseDownEvent)
              
        
        }
        else if(event.keyCode == leftBracketKey)
        {
            self.decrementBrightness();
        
        }
        else if(event.keyCode == rightBracketKey)
        {
            self.incrementBrightness();
        }
        
    }
    


    // for keydown and mousedown
    override var acceptsFirstResponder: Bool { return true }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
        
    }
    
    override func mouseMoved(with event: NSEvent)
    {
        mouseLocation = self.convert(event.locationInWindow, from: nil)
                   
        NSCursor.crosshair.set()

        let width = mouseLocation.x - pickerCenterPoint.x;
        let height = mouseLocation.y - pickerCenterPoint.y;
        
        angleClockwiseRadians = atan2(height, width);
        if(angleClockwiseRadians < 0)
        {
            angleClockwiseRadians += (2.0 * .pi);
        }
        angleInDegrees = angleClockwiseRadians * (180.0 / .pi);
        
        // print(angleInDegrees)
        
        self.needsDisplay = true
        // self.setNeedsDisplay(NSRect(origin: pickerCenterPoint, size: CGSize(width: width, height: height)))
        
        if(self.selectionModeUsesPickedViews == true)
        {
            self.highlightedColorsArrayView?.needsDisplay = true
        }
    }
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        
        selectColorUnderMouse()
      
    }
    
    func selectColorUnderMouse()
    {
        self.pickedColorsArray.removeAll()
        self.pickedColorAnglesArray.removeAll()
        self.pickedColorsArray.append(contentsOf: highlightedColorsArray)
        self.pickedColorAnglesArray.append(contentsOf: highlightedColorAnglesArray)
        
        self.pickedColorAnglesSegment = self.highlightedColorAnglesSegment;
        self.pickedColorAnglesRadius = self.highlightedColorAnglesRadius;
        
        if(self.selectionModeUsesPickedViews == true)
        {
            pickedColorsArrayView?.needsDisplay = true
        }
        self.updateColorWellWithHighlightedColor()
        
        self.needsDisplay = true
        
    }
    
    func colorWellChangeFromColorPanel(_ sender: NSColorWell)
    {
       // print("colorWellChangeFromColorPanel")
        if(sender.color != pickedColorsArray.first!)
        {
            self.loadColor(sender.color, sendAction:true)
        }
        else
        {
         //   print("colorWellChangeFromColorPanel------- same as first")
        }
    }
    
    
    func loadColor(_ color: NSColor, sendAction:Bool)
    {
      //  print("load color")
          self.needsDisplay = true
        
        let colorToLoad = color.usingColorSpace(NSColorSpace.sRGB)!
        
        self.pickedColorsArray.removeAll()
        self.pickedColorAnglesArray.removeAll()
        self.highlightedColorsArray.removeAll()
        self.highlightedColorAnglesArray.removeAll()
        
        self.highlightedColorsArray.append(colorToLoad)
        self.pickedColorsArray.append(colorToLoad)
        
        let hue = colorToLoad.hueComponent
        let saturation = colorToLoad.saturationComponent
        
        let sector = hue * CGFloat(numberOfSectors) * pickerSectorAngle
        
        // numberOfSegmentsPerRadius = Int(radius / CGFloat(strokeThickness))
        // truncatedRadius = CGFloat(numberOfSegmentsPerRadius) * CGFloat(strokeThickness)
        // let radius = liveRadius - fmod(liveRadius, CGFloat(pickerStrokeThickness))
      //  let segment = Int(radius) / pickerStrokeThickness
       // highlightedColorAnglesSegment = CGFloat(segment)
        
        self.pickedColorAnglesArray.append(Int(sector))
        self.pickedColorAnglesRadius = (saturation * self.truncatedRadius) - fmod(saturation * self.truncatedRadius, CGFloat(pickerStrokeThickness))
        
        //print("\(saturation) pickedColorAnglesRadius:\(self.pickedColorAnglesRadius) truncatedRadius: \(self.truncatedRadius) pickerStrokeThickness:\(pickerStrokeThickness)")
      
        self.pickedColorAnglesSegment = saturation * CGFloat(numberOfSegmentsPerRadius - pickerInteriorOffsetCount)
        


        
        
        self.colorPickerBrightness = colorToLoad.brightnessComponent
        self.colorPickerAlpha = colorToLoad.alphaComponent
        
        colorPickerAlpha = colorToLoad.alphaComponent;
        opacitySlider.floatValue = Float(colorToLoad.alphaComponent);
        opacityTextField?.floatValue = Float(colorToLoad.alphaComponent);
        
        colorPickerBrightness = colorToLoad.brightnessComponent
        brightnessSlider.floatValue = Float(colorToLoad.brightnessComponent)
        brightnessTextField?.floatValue = Float(colorToLoad.brightnessComponent)
        
        
        
        self.reloadViewsForColorUpdate(sendAction:sendAction);
        
        
        self.needsDisplay = true
        
        if(self.selectionModeUsesPickedViews == true)
        {
            pickedColorsArrayView?.needsDisplay = true
            highlightedColorsArrayView?.needsDisplay = true
        }
        
         
        
    }
    

    
    
    func updateColorWellWithHighlightedColor()
    {
        launchingColorWell?.color = highlightedColorsArray.first!;
        colorWell.color = highlightedColorsArray.first!
        colorWell.sendAction(colorWell.action, to: colorWell.target)
    }
    
    func updateColorWellWithSelectedColor()
    {
        if(pickedColorsArray.isEmpty == false)
        {
            launchingColorWell?.color = highlightedColorsArray.first!;
            colorWell.color = pickedColorsArray.first!
            colorWell.sendAction(colorWell.action, to: colorWell.target)
        }
        
    }
    
    

    
    func drawLineFromCenter()
    {
        // debug:
        // NSBezierPath.strokeLine(from: pickerCenterPoint, to: mouseLocation)
        
        let liveRadius = self.distanceBetween(a: pickerCenterPoint, b: mouseLocation)
        
        let radius = liveRadius - fmod(liveRadius, CGFloat(pickerStrokeThickness))
        
        
        
        
        let pickerSectorAngleInRadians = pickerSectorAngle *  .pi / 180
        
        
        let startAngleRadians = angleClockwiseRadians  - fmod(angleClockwiseRadians, pickerSectorAngleInRadians)
        
        // print("\(radius) \(startAngle)")
        /*
         let p = NSBezierPath()
         p.appendArc(withCenter: pickerCenterPoint, radius: radius, startAngle: startAngle, endAngle: startAngle + pickerSectorAngle)
         
         p.stroke()
         */
        
        
        let context : CGContext! = NSGraphicsContext.current!.cgContext
        
        
        if(liveRadius < (truncatedRadius + CGFloat(pickerStrokeThickness)))
        {
            
            let segment = Int(radius) / pickerStrokeThickness
            
            highlightedColorAnglesSegment = CGFloat(segment)
            highlightedColorAnglesRadius = radius
            
            highlightedColorsArray.removeAll()
            highlightedColorAnglesArray.removeAll()
            
            
            for angleOnWheel in dictionaryOfColorSets[colorSet] ?? [0]
            {
                
                
                let angleOnWheelAdjusted = angleOnWheel - (angleOnWheel % Int(pickerSectorAngle))
                
                highlightedColorAnglesArray.append(angleOnWheelAdjusted + Int((startAngleRadians  *  180 / .pi)))
                
                let annulusSegmentOutline: CGMutablePath = CGMutablePath()
                
                let startAngleRadiansForAngle = ( CGFloat(angleOnWheelAdjusted) * .pi / 180) + startAngleRadians
                
                annulusSegmentOutline.addArc(center: pickerCenterPoint, radius: CGFloat(radius), startAngle: startAngleRadiansForAngle,
                                             endAngle: startAngleRadiansForAngle + pickerSectorAngleInRadians, clockwise: false)
                
                let arcPathStroked = annulusSegmentOutline.copy(strokingWithWidth: CGFloat(pickerStrokeThickness), lineCap: CGLineCap.butt, lineJoin: CGLineJoin.bevel, miterLimit: 0.0)
                
                context.addPath(arcPathStroked)
                
                
                let saturation = (( CGFloat(segment) /
                    ( CGFloat(numberOfSegmentsPerRadius - pickerInteriorOffsetCount))))
                
                var sector =  (startAngleRadians  *  180 / .pi) + CGFloat(angleOnWheelAdjusted)
                
                if(sector > 360)
                {
                    sector = sector - 360
                }
                
                
                let hue = CGFloat(sector) / pickerSectorAngle / CGFloat(numberOfSectors)
                
                //  print("\(pickerSectorAngle) \((CGFloat(angleOnWheel) + pickerSectorAngle))")
                
                var fillColor : NSColor!
                
                if(colorValue == "grayscale")
                {
                    fillColor = NSColor.init(white: (saturation / 2) + (colorPickerBrightness / 2), alpha: colorPickerAlpha)
                }
                else
                {
                    fillColor = NSColor.init(calibratedHue:
                        hue,
                                             saturation: saturation,
                                             brightness: colorPickerBrightness,
                                             alpha: colorPickerAlpha)
                }
                
                highlightedColorsArray.append(fillColor)
                
                context.setFillColor(fillColor.cgColor)
                context.setStrokeColor(NSColor.white.cgColor)
                context.setLineWidth(2.0)
                context.drawPath(using: CGPathDrawingMode.fillStroke)
                
            }
            
            if(radius == 0)
            {
                let r = NSMakeRect(0, 0, 10, 10).centerOnPoint(pickerCenterPoint)
                let p = NSBezierPath();
                p.appendOval(in: r)
                NSColor.black.setStroke()
                p.appendOval(in: r.offsetBy(dx: 1, dy: 1))
                p.stroke()
                p.removeAllPoints();
                NSColor.white.setStroke();
                p.stroke();
                
                
            }
            
        }
        
        pickedColorsArray.removeAll()
        
        for angleOnWheelAdjusted in pickedColorAnglesArray
        {
            
            
            // let angleOnWheelAdjusted = angleOnWheel - (angleOnWheel % Int(pickerSectorAngle))
            
            //highlightedColorAnglesArray.append(angleOnWheelAdjusted)
            
            let annulusSegmentOutline: CGMutablePath = CGMutablePath()
            
            let startAngleRadiansForAngle = ( CGFloat(angleOnWheelAdjusted) * .pi / 180)
            
            annulusSegmentOutline.addArc(center: pickerCenterPoint, radius: CGFloat(pickedColorAnglesRadius), startAngle: startAngleRadiansForAngle,
                                         endAngle: startAngleRadiansForAngle + pickerSectorAngleInRadians, clockwise: false)
            
            let arcPathStroked = annulusSegmentOutline.copy(strokingWithWidth: CGFloat(pickerStrokeThickness), lineCap: CGLineCap.butt, lineJoin: CGLineJoin.bevel, miterLimit: 0.0)
            
            context.addPath(arcPathStroked)
            
            //let seg = pickedColorAnglesRadius / CGFloat(pickerStrokeThickness)
            
            let saturation = (( CGFloat(pickedColorAnglesSegment) /
                ( CGFloat(numberOfSegmentsPerRadius - pickerInteriorOffsetCount))))
            
            
            var sector = CGFloat(angleOnWheelAdjusted)
            
            if(sector > 360)
            {
                sector = sector - 360
            }
            
            
            let hue = CGFloat(sector) / pickerSectorAngle / CGFloat(numberOfSectors)
            
            
            // let fillColor = pickedColorsArray
            
            var fillColor : NSColor!
            
            if(colorValue == "grayscale")
            {
                fillColor = NSColor.init(white: (saturation / 2) + (colorPickerBrightness / 2), alpha: colorPickerAlpha)
            }
            else
            {
                fillColor = NSColor(calibratedHue: hue, saturation: saturation, brightness:
                    colorPickerBrightness, alpha: colorPickerAlpha)
                
            }
            
            pickedColorsArray.append(fillColor)
            
            context.setFillColor(fillColor.cgColor)
            context.setStrokeColor(NSColor.black.cgColor)
            context.setLineWidth(2.0)
            context.drawPath(using: CGPathDrawingMode.fillStroke)
            
            if(pickedColorAnglesRadius == 0)
            {
                let r = NSMakeRect(0, 0, 10, 10).centerOnPoint(pickerCenterPoint)
                let p = NSBezierPath();
                NSColor.white.setStroke()
                p.appendOval(in: r.offsetBy(dx: 1, dy: 1))
                p.stroke()
                p.removeAllPoints();
                NSColor.black.setStroke();
                p.stroke();
            }
            
        }
        
        
    }
    
    
    func distanceBetween( a : NSPoint, b : NSPoint ) -> CGFloat
    {
        return hypot(a.x - b.x, a.y - b.y);
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
//        NSColor.white.set()
//       dirtyRect.frame()
        
       
        drawAnnulusSegmentColorWheel(centerPoint: NSPoint(x: self.bounds.midX, y: self.bounds.midX),
                                     radius: self.pickerRadiusComputed, strokeThickness: 6, angleDeg: 15, spacingBetweenRings: 0, interiorOffsetCount:0)
        
        
//        NSColor.black.set()
        
        drawLineFromCenter()
        
        
       
    }
    
    
    func drawAnnulusSegmentColorWheel(centerPoint: NSPoint, radius:CGFloat, strokeThickness:Int, angleDeg:CGFloat, spacingBetweenRings:CGFloat, interiorOffsetCount:Int)
    {
        
        pickerCenterPoint = centerPoint
      //  pickerRadiusComputed = radius - CGFloat(strokeThickness)
       // pickerStrokeThickness = strokeThickness
        pickerSectorAngle = angleDeg
        pickerSpacingBetweenRings = spacingBetweenRings
        pickerIinteriorOffsetCount = interiorOffsetCount
        
        
        let context : CGContext! = NSGraphicsContext.current!.cgContext
        
        //let startOffset : CGFloat = CGFloat(interiorOffsetCount) * strokeThickness
        
        
        
        for sector in 0..<Int(numberOfSectors)
        {
            
            var startAngle : CGFloat = CGFloat(sector) * angleDeg
            let endAngle = startAngle + angleDeg
            
            //print("\(sector) \(startAngle) \(endAngle)")
            
            // overlaps to cover up gaps between sectors
            var angleForEndAngle = endAngle
            
            if(self.colorPickerAlpha == 1.0)
            {
                
                if(endAngle < (360 - angleDeg))
                {
                    angleForEndAngle = angleForEndAngle + 2
                    //    angleForEndAngle = angleForEndAngle + 5
                }
                else
                {
                    angleForEndAngle = angleForEndAngle + 1.5
                    startAngle = startAngle - 1.0
                }
            }
            else
            {
                //    angleForEndAngle = angleForEndAngle
                // startAngle = startAngle
                angleForEndAngle = angleForEndAngle - 0.25
                startAngle = startAngle - 0.25
                
            }
            
            for segment in stride(from: interiorOffsetCount, through: numberOfSegmentsPerRadius, by: 1)
            {
                // print(segment * strokeThickness)
                
                let radiusForSegment = (segment * strokeThickness)
                var thicknessForSegment = CGFloat(strokeThickness) - spacingBetweenRings
                
                
                
                if(self.colorPickerAlpha == 1.0)
                {
                    thicknessForSegment += 1.0
                    
                    // overlaps to cover up gaps between sectors
                    // when angle is small on last segment
                    if(segment == (interiorOffsetCount) && (endAngle >= (360 - angleDeg)))
                    {
                        
                        //    angleForEndAngle = angleForEndAngle - 0.5
                        //     print("first segment")
                    }
                }
                else
                {
                    //    thicknessForSegment += 0.5
                }
                
                let arcPath: CGMutablePath = CGMutablePath()
                //arcPath.move(to: c)
                
                var lineCap = CGLineCap.butt
                
                if(segment == (interiorOffsetCount) && (colorPickerAlpha == 1.0))
                {
                    lineCap = CGLineCap.square
                    thicknessForSegment += 2.0
                    
                }
                
                arcPath.addArc(center: pickerCenterPoint, radius: CGFloat(radiusForSegment), startAngle: startAngle *  .pi / 180,
                               endAngle: (angleForEndAngle) *  .pi / 180 , clockwise: false)
                
                let arcPathStroked = arcPath.copy(strokingWithWidth: thicknessForSegment, lineCap: lineCap, lineJoin: CGLineJoin.bevel, miterLimit: 0.0)
                
                
                let saturation = (( CGFloat(segment) /
                    ( CGFloat(numberOfSegmentsPerRadius - interiorOffsetCount))))
                
                
                
                let hue = CGFloat(sector) / CGFloat(numberOfSectors)
                
                
                //context.setStrokeColor(CGColor.black)
                var fillColor : NSColor!
                
                if(colorValue == "grayscale")
                {
                    fillColor = NSColor.init(white: (saturation / 2) + (colorPickerBrightness / 2), alpha: colorPickerAlpha)
                }
                else
                {
                    fillColor = NSColor.init(calibratedHue:
                        hue,
                                             saturation: saturation,
                                             brightness: colorPickerBrightness,
                                             alpha: colorPickerAlpha)
                }
                
                
                context.setFillColor(fillColor.cgColor)
                
                context.addPath(arcPathStroked)
                
                context.fillPath()
                
                
                
            }
            
            
            
            
            
        }
        
        // MARK: THE OUTLINE OF THE COLORWHEEL
        let circleOutline: CGMutablePath = CGMutablePath()
        
        circleOutline.addArc(center: centerPoint, radius:
            CGFloat((numberOfSegmentsPerRadius - interiorOffsetCount)) * CGFloat(strokeThickness) - (CGFloat(strokeThickness) / 2) + CGFloat(strokeThickness)
            
            , startAngle: 0,
              endAngle: 2 *  .pi , clockwise: false)
        
        
        context.addPath(circleOutline)
        context.setLineWidth(0.5)
        context.setStrokeColor(NSColor.gray.cgColor)
        
        context.strokePath()
        
    }
    
   
    
    @IBAction func makeOpacityZero(_ sender : NSControl)
    {
        let colorWellFake = NSColorWell(frame: NSRect.zero)
        colorWellFake.takeColorFrom(colorWell)
        colorWellFake.color = colorWellFake.color.withAlphaComponent(0.0)
        colorWell.takeColorFrom(colorWellFake)
        colorWell.sendAction(colorWell.action, to: colorWell.target)
        
    }
    
    @IBAction func toggleOpacity(_ sender : NSSegmentedControl)
    {
        if(sender.selectedSegment == 1) // off
        {
            
            let colorWellFake = NSColorWell(frame: NSRect.zero)
            colorWellFake.takeColorFrom(colorWell)
            storedOpacityForSegmentedControl = colorWellFake.color.alphaComponent
            colorWellFake.color = colorWellFake.color.withAlphaComponent(0.0)
            colorWell.takeColorFrom(colorWellFake)
            colorWell.sendAction(colorWell.action, to: colorWell.target)
            
        }
        else
        {
            let colorWellFake = NSColorWell(frame: NSRect.zero)
            colorWellFake.takeColorFrom(colorWell)
            colorWellFake.color = colorWellFake.color.withAlphaComponent(storedOpacityForSegmentedControl)
            colorWell.takeColorFrom(colorWellFake)
            colorWell.sendAction(colorWell.action, to: colorWell.target)
     
        }
        
    }

    func reloadViewsForColorUpdate(sendAction:Bool)
    {
        self.needsDisplay = true
        pickedColorsArrayView?.needsDisplay = true
        
        if(sendAction)
        {
            self.updateColorWellWithSelectedColor()
        }
    }
    
    
     @IBAction func changeOpacity(_ sender : NSControl)
    {
        let newOpacity : CGFloat = sender.cgfloatValue()
        colorPickerAlpha = newOpacity.clamped(to: 0...1)

        opacitySlider.doubleValue = colorPickerAlpha.double()
        opacityTextField?.doubleValue = colorPickerAlpha.double();
        
        self.needsDisplay = true;
        reloadViewsForColorUpdate(sendAction: true)
    }
    
    @IBAction func changeBrightness(_ sender : NSControl?)
    {
        let newBrightness : CGFloat = sender?.cgfloatValue() ?? 0
        self.colorPickerBrightness = newBrightness.clamped(to: 0...1)
        
        brightnessTextField?.doubleValue = self.colorPickerBrightness.double();
        brightnessSlider.doubleValue = self.colorPickerBrightness.double();
        
        self.needsDisplay = true;
        reloadViewsForColorUpdate(sendAction: true)
    }
    
    func incrementBrightness()
    {
        let newBrightness : CGFloat = (colorPickerBrightness + 0.05)
        colorPickerBrightness = newBrightness.clamped(to: 0...1)
        
        brightnessTextField?.doubleValue = self.colorPickerBrightness.double();
        self.changeBrightness(brightnessTextField)
        
        
    }

    func decrementBrightness()
    {
        let newBrightness : CGFloat = (colorPickerBrightness - 0.05)
        colorPickerBrightness = newBrightness.clamped(to: 0...1)
        brightnessTextField?.doubleValue = self.colorPickerBrightness.double();
        self.changeBrightness(brightnessTextField)
    }
    
    
    func drawSelectedColorsInColorsArrayView(rect: NSRect)
    {
        
        
        let widthForSwatch = rect.size.width / CGFloat(pickedColorsArray.count)
        
        for i in 0..<pickedColorsArray.count
        {
            
            pickedColorsArray[i].drawSwatch(in: NSRect(origin: CGPoint(x: CGFloat(i) * widthForSwatch, y: 0), size: CGSize(width: widthForSwatch, height: rect.size.height)))
            
        }
        
    }
    
    func drawHighlightedColorsInColorsArrayView(rect: NSRect)
    {
        
        let widthForSwatch = rect.size.width / CGFloat(highlightedColorsArray.count)
        
        for i in 0..<highlightedColorsArray.count
        {
            
            highlightedColorsArray[i].drawSwatch(in: NSRect(origin: CGPoint(x: CGFloat(i) * widthForSwatch, y: 0), size: CGSize(width: widthForSwatch, height: rect.size.height)))
            
        }
        
    }
    
    
    @IBAction func changeColorSet(_ sender : NSPopUpButton)
    {
        colorSet = sender.selectedItem!.title.lowercased().replacingOccurrences(of: " ", with: "_")
        //      print(sender.selectedItem!.title.lowercased().replacingOccurrences(of: " ", with: "_"))
    }
    
    
    var storedGrayscaleColor : NSColor = NSColor.gray;
    var storedRegularColor : NSColor = NSColor.green;
    
    @IBAction func changeColorValue(_ sender : NSSegmentedControl)
    {
        /*
          if(colorValue == "grayscale")
        {
            if(oldColorValue == "color")
            {
                storedRegularColor = self.colorWell.color
                if(storedGrayscaleColor == nil)
                {
                    storedGrayscaleColor = self.colorWell.color.grayscaleVersion
                }
                loadColor(storedGrayscaleColor!, sendAction: true)

                
            }
        }
        else
        {
            if(oldColorValue == "grayscale")
            {
                storedGrayscaleColor = self.colorWell.color;
                
                if(storedRegularColor == nil)
                {
                    storedRegularColor = NSColor.black;
                }
                loadColor(storedRegularColor!, sendAction: true)

            }
        }
         */
        colorValue = sender.label(forSegment: sender.selectedSegment)!.lowercased()
        
        if(colorValue == "grayscale")
        {
            storedRegularColor = self.colorWell.color
            loadColor(storedGrayscaleColor, sendAction: true)
        }
        else
        {
            storedGrayscaleColor = self.colorWell.color;
            loadColor(storedRegularColor, sendAction: true)
        }
        
        
        self.needsDisplay = true
        
        if(self.selectionModeUsesPickedViews == true)
        {
            highlightedColorsArrayView?.needsDisplay = true
            pickedColorsArrayView?.needsDisplay = true
        }
        
        //selectColorUnderMouse();
        
    }
    
}


class PickedColorsArrayView: NSView, NSDraggingSource {
    
    @IBOutlet var colorPickerView : ColorPickerView!
    @IBInspectable var arrayViewType : String = "selectedColors"  // or "highlightedColors"
    
    var mouseDownEvent : NSEvent?
    var pressed : Bool = false
    var downPoint : NSPoint = NSPoint.zero
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        if(self.arrayViewType == "selectedColors")
        {
            if(colorPickerView.pickedColorsArray.isEmpty)
            {
                NSColor.black.set()
                self.bounds.insetBy(dx: 1, dy: 1).frame(withWidth: 1, using: NSCompositingOperation.copy)
            }
            
            colorPickerView.drawSelectedColorsInColorsArrayView(rect: self.bounds)
            
            NSColor.black.setStroke();
            NSBezierPath.defaultLineWidth = 2.0;
            NSBezierPath.stroke(  self.bounds.insetBy(dx: 3, dy: 3)  )
            
            
        }
        else if(self.arrayViewType == "highlightedColors")
        {
            if(colorPickerView.highlightedColorsArray.isEmpty)
            {
                NSColor.black.set()
                self.bounds.insetBy(dx: 1, dy: 1).frame(withWidth: 1, using: NSCompositingOperation.copy)
            }
            colorPickerView.drawHighlightedColorsInColorsArrayView(rect: self.bounds)
            
            //  NSColor.white.set()
            // self.bounds.insetBy(dx: 1, dy: 1).frame(withWidth: 2, using: NSCompositingOperation.copy)
            
        }
        
    }
    
    
    
    
    override func mouseDown(with event: NSEvent) {
        
        mouseDownEvent = event
        downPoint = self.convert(event.locationInWindow, from: nil)
        
        if(self.arrayViewType == "selectedColors")
        {
            pressed = self.bounds.contains(self.convert(event.locationInWindow, from: nil))
            
            
        }
        
    }
    
    override func mouseDragged(with event: NSEvent)
    {
        let downPoint = mouseDownEvent!.locationInWindow
        
        pressed = false
        
        let numberOfColors = colorPickerView.pickedColorsArray.count
        
        let swatchWidth = self.bounds.width / CGFloat(numberOfColors)
        let swatchHeight = self.bounds.height
        
        let swatchSize = CGSize(width: swatchWidth, height: swatchHeight)
        
        let downPointConv = convert(downPoint, from: nil)
        
        let pixPositionForSwatch = downPointConv.x - fmod(downPointConv.x, swatchWidth)
        let positionForSwatch = Int(pixPositionForSwatch / swatchWidth)
        
        let colorHit = colorPickerView.pickedColorsArray[positionForSwatch]
        
        if(self.arrayViewType == "selectedColors")
        {
            let image = NSImage(size: self.bounds.size, flipped: false, drawingHandler: { (imageBounds) -> Bool in
                
                
                colorHit.set()
                NSBezierPath.stroke(imageBounds.insetBy(dx: 2, dy: 2))
                NSBezierPath.fill(imageBounds)
                //                    self.colorPickerView.drawSelectedColorsInColorsArrayView(rect: imageBounds)
                
                return true
            })
            
            
            
            let draggingItem = NSDraggingItem(pasteboardWriter: colorHit)
            let draggingFrameOrigin = convert(downPoint, from: nil)
            
            draggingItem.draggingFrame = NSRect(origin: draggingFrameOrigin, size: swatchSize)
            
            draggingItem.imageComponentsProvider = {
                
                
                let component = NSDraggingImageComponent(key: NSDraggingItem.ImageComponentKey.icon)
                component.contents = image
                component.frame = NSRect(origin: NSPoint(), size: swatchSize)
                return [component]
                
                
            }
            
            let draggingSession = beginDraggingSession(with: [draggingItem], event: mouseDownEvent!, source: self)
            
            draggingSession.animatesToStartingPositionsOnCancelOrFail = true
            
            //print(draggingSession.draggingLocation)
            
        }
    }
    
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        
        return NSDragOperation.generic
        
    }
    
    
}



