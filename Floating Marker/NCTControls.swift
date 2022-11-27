//
//  NCTControls.swift
//  Floating Marker
//
//  Created by John Pratt on 1/13/21.
//

import Cocoa

enum NCTGridSnappingType : String
{
    case squareDots
    case squareEdges
    case square45DegEdges
    case square45DegWithXYEdges
    case triangleHorizontal
    case triangleVertical
    case hexagonHorizontal
    case hexagonVertical
    
}


// MARK: EXTENSIONS TO NSCONTROLS

extension NSControl
{

    func cgfloatValue() -> CGFloat {
    
        return CGFloat(self.doubleValue)
    }
    
    func setCGFloatValue(_ cgfloat : CGFloat)
    {
        self.doubleValue = Double(cgfloat);
    }
    
}

extension NSButton
{

    var boolFromState : Bool {
     
        get
        
        {
          return self.state.rawValue > 0 ? true : false;
        }
        
    }

}

extension NSControl
{
    func fadeInOut(durationInSec:CGFloat, removeFromSuperview: Bool)
    {
        guard self.layer != nil else
        {
            return;
        }
        
        CATransaction.begin();
        
        self.layer!.setValue(0.0, forKey: "opacity");
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.0;
        animation.toValue = 1.0;
        animation.autoreverses = true;
        animation.duration = CFTimeInterval(durationInSec);
        
        CATransaction.setCompletionBlock {
            if(removeFromSuperview)
            {
            self.removeFromSuperview()
            }
        }
        self.layer!.add(animation, forKey: "opacity");
        CATransaction.commit();
        
    }
    
    
    func flash(durationInSec:CGFloat, autoreverses:Bool)
    {
        guard self.layer != nil else
        {
            return;
        }
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.5
        animation.autoreverses = autoreverses;
        animation.duration = CFTimeInterval(durationInSec);
        
        self.layer!.add(animation, forKey: "opacity");
        
    }
}

@IBDesignable class NCTButton : NSControl
{

    @IBInspectable var buttonTitle : String = "button"

    var isInterfaceBuilder : Bool = false;
    override func prepareForInterfaceBuilder()
    {
       isInterfaceBuilder = true;
       
    }
    
    override func awakeFromNib() {
        isEnabled = true;
    }

    override var isEnabled: Bool
    {
        didSet
        {
            self.needsDisplay = true;
            
        }
    }

    // capsule, roundCorners
    @IBInspectable var style : String = "roundCorners"
    @IBInspectable var roundCornersStyleCornerRadius : CGFloat = 5.0;
    
    @IBInspectable var buttonBackgroundColor : NSColor = NSColor.init(calibratedWhite: 0.2, alpha: 1.0)//.black;
    @IBInspectable var buttonStrokeColor : NSColor = .darkGray;
    
    @IBInspectable var doStroke : Bool = true;
    
    @IBInspectable var titleTextColor : NSColor = NSColor.init(calibratedWhite: 0.9, alpha: 1.0);

   var mouseIsInside : Bool = false;
       var mouseIsDown : Bool = false;

     override func mouseEntered(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
        mouseIsInside = true;
        self.needsDisplay = true;
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseIsInside = false;
        self.needsDisplay = true;
    }
    
    override func mouseDown(with event: NSEvent)
    {
    
        if(isEnabled)
        {
            
            mouseIsDown = true
            self.needsDisplay = true;
        }
    }
    
    override func mouseUp(with event: NSEvent)
    {
    
        if(isEnabled)
        {
            mouseIsDown = false
            self.needsDisplay = true;
            self.sendAction(self.action, to: self.target);
        }
    }
    
    override func keyDown(with event: NSEvent)
    {
        
        if(isEnabled)
        {
            
            if(event.keyCode == tabKey)
            {
                self.sendAction(self.action, to: self.target);
            }
        }

    }
    
    
    override var acceptsFirstResponder: Bool { return true;}
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        
        return true
        
    }
    
    var trackingArea : NSTrackingArea = NSTrackingArea();
  
  
    override func draw(_ dirtyRect: NSRect) {
        
        if(mouseIsDown == true)
        {
            NSColor.lightGray.setFill();
        }
        else if(mouseIsInside == false)
        {
            buttonBackgroundColor.setFill();
        }
        else
        {
            NSColor.gray.setFill();
        }
        
        if(isEnabled == false)
        {
            NSColor.gray.withAlphaComponent(0.5).setFill()
        }
        
        let buttonPath = NSBezierPath();
        
        if(style == "roundCorners")
        {
               buttonPath.appendRoundedRect(self.bounds.insetBy(dx: 1, dy: 1), xRadius: roundCornersStyleCornerRadius, yRadius: roundCornersStyleCornerRadius)

        }
        else
        {
            buttonPath.appendRoundedRect(self.bounds.insetBy(dx: 1, dy: 1), xRadius: min(self.bounds.width,self.bounds.height) / 2, yRadius: min(self.bounds.width,self.bounds.height) / 2)

        }

        let grad = NSGradient.init(colors: [NSColor.clear,NSColor.init(calibratedWhite: 1.0, alpha: 0.2),NSColor.clear,NSColor.init(calibratedWhite: 0.1, alpha: 0.4)], atLocations: [0,0.0,0.8,0.9], colorSpace: NSColorSpace.deviceRGB)
 
        buttonPath.fill();

        if(isEnabled)
        {
            grad?.draw(in: buttonPath, angle: 90)
        }
        
        if(doStroke)
        {
            buttonStrokeColor.setStroke()
            buttonPath.stroke()
        }

        if((self.target == nil) && !isInterfaceBuilder)
        {
            NSColor.red.setStroke()
            buttonPath.stroke()
            
        }

        let fontSizeFactor : CGFloat = 0.65

        self.buttonTitle.drawStringInsideRectWithSFProFont(fontSize: fontSizeFactor * self.bounds.height, textAlignment: NSTextAlignment.center, fontForegroundColor: isEnabled ? titleTextColor : .lightGray, rect:
        NSMakeRect(0, 0, self.bounds.width, (fontSizeFactor * self.bounds.height) + 4).centerInRect(self.bounds))
        
        

        
    }
    
    override func updateTrackingAreas()
    {
        
        super.updateTrackingAreas()
        
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }

}

    @IBDesignable class NCTAngularCircularSlider: NSControl {

    override  func awakeFromNib() {
        
        self.wantsLayer = true;
        let shadow = NSShadow();
        shadow.shadowBlurRadius = 3;
        self.shadow = shadow;
        
        //self.layer?.backgroundColor = NSColor.red.cgColor
        self.layer?.cornerRadius = 0
        self.layer?.shadowOpacity = 1.0;
        
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(3, -3)
        self.layer?.shadowRadius = 2;
    }

    @IBInspectable var imageForLine : NSImage?;
    
    
    
    
    
    @IBInspectable var angledLineStrokeColor : NSColor = .black
    @IBInspectable var angledLineStrokeWidth : CGFloat = 5.0;
    
    @IBInspectable var circumferenceStrokeColor : NSColor = .darkGray
    @IBInspectable var circumferenceStrokeWidth : CGFloat = 3.0;
    
    var mouseIsInside : Bool = false;
    
    var trackingArea : NSTrackingArea = NSTrackingArea();
  
    var maxDegrees : CGFloat = 360;
    var minDegrees : CGFloat = 0;
  
    override var acceptsFirstResponder: Bool { return true;}
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        
        return true
        
    }
    
    override func viewDidMoveToWindow()
    {
        self.isContinuous = true;
        focusRingType = .none;
        
    }
    
    override func updateTrackingAreas()
    {
        
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.gray.setFill()
        
        //dirtyRect.fill()
        // MARK: CIRCLE OUTLINE AND INTERIOR
        let p = NSBezierPath()
        p.appendArc(withCenter: bounds.centroid(), radius: bounds.shortestLength() / 2 - 2, startAngle: CGFloat(self.minValue), endAngle: CGFloat(self.maxValue))
        p.close()
        
   
        p.lineWidth = circumferenceStrokeWidth;
        circumferenceStrokeColor.setStroke()
        p.fill()
        p.stroke()
        
        
       
        
        // MARK: RADIUS
    
        let angleInDegrees = doubleValue//mapy(n: self.doubleValue, start1: Double(self.minValue), stop1: Double(self.maxValue), start2: Double(0), stop2: Double(360))
        let angleInRadians = deg2rad(CGFloat(angleInDegrees))
        let point1 = bounds.centroid();
        
        let width = 0.5 * bounds.shortestLength() - 2.0;
        
        
        let point2 = NSMakePoint( point1.x + (width * cos(angleInRadians)), point1.y + (width * sin(angleInRadians)) )
       
        if(imageForLine != nil)
        {
            let ctx = NSGraphicsContext.current
        
        
            ctx?.saveGraphicsState()
            p.addClip()
            
            let xfm = RotationTransform(angleRadians: angleInRadians + (.pi / 2), centerPoint: point1)
            let nsxfm = NSAffineTransform.init(transform: xfm)
            nsxfm.concat();
        
            imageForLine?.draw(in: NSRect.init(origin: point1.offsetBy(x: 0, y: width / 2), size: CGSize.init(width: width, height: width)))
            NSColor.darkGray.setFill()
           
        
            ctx?.restoreGraphicsState()
            
        }
        
        angledLineStrokeColor.setStroke();
        let p2 = NSBezierPath();
        
        
        
        
        p2.lineWidth = angledLineStrokeWidth;
        p2.move(to: point1)
        p2.line(to: point2)
        
        p2.stroke();
        
        // MARK: MOUSE ENTERED OUTER RING
        if(mouseIsInside)
        {
        
            if((isDragging == false) && (mouseIsDown == false))
            {
                let extPnt = self.bounds.centroid().pointFromAngleAndLength(angleRadians: liveLineAngleRadians, length: (min(self.bounds.width,self.bounds.height) / 2) - 2.0)
                NSColor.green.setStroke();
                NSBezierPath.strokeLine(from: self.bounds.centroid(), to: extPnt)
            }
                /*
                 p.removeAllPoints();
                 p.appendArc(withCenter: bounds.centroid(), radius: bounds.longestLength() / 2 - 3, startAngle: CGFloat(self.minValue), endAngle: CGFloat(self.maxValue))
                 p.close()*/
                p.lineWidth = 1.5;//1.0;
                NSColor.green.setStroke()
                p.stroke()
            
        }
        
    }

    @IBInspectable var minValue : Double = 0;
    @IBInspectable var maxValue : Double = 360;
    
    
    
    override func mouseEntered(with event: NSEvent) {
        mouseIsInside = true;
        self.needsDisplay = true;
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseIsInside = false;
        self.needsDisplay = true;
        isDragging = false;
        mouseIsDown = false;
    }
    
    var liveLineAngleRadians : CGFloat = 0

    override func mouseMoved(with event: NSEvent)
    {
        let p = self.convert(event.locationInWindow, from: nil)
        
        var laDeg = NSBezierPath.lineAngleDegreesFrom(point1: self.bounds.centroid(), point2: p);
        
        let remainder = laDeg.truncatingRemainder(dividingBy: 5);
        if( remainder > 0)
        {
            laDeg -= remainder;
        }
        
        liveLineAngleRadians = deg2rad(laDeg)
    
        self.needsDisplay = true;
    }
    
    var isDragging: Bool = false
    var mouseIsDown: Bool = false
    
    override func mouseDown(with event: NSEvent) {
        let mouseWasUp = (mouseIsDown == false)
        mouseIsDown = true;
        if(mouseWasUp)
        {
                self.needsDisplay = true;
        
        }

          // dragging code from
        // https://github.com/hpbl/BezierCurve-ConvexHull/blob/12762b1a6cf2f0a3520d1fbf21a01350c2027abb/projeto1/projeto1/OpenGLView.swift
        let p = self.convert(event.locationInWindow, from: nil)
        
        var lineAngle = NSBezierPath.lineAngleDegreesFrom(point1: self.bounds.centroid(), point2: p)
        lineAngle.formClamp(to: CGFloat(minValue)...CGFloat(maxValue))
        doubleValue = Double(lineAngle)
//           doubleValue = mapy(n: Double(lineAngle), start1: Double(0.0), stop1: Double(360.0), start2: self.minValue, stop2: self.maxValue)
        
        
        if(self.isContinuous)
        {
            self.sendAction(self.action, to: self.target);
        }
        //loop control variables
        var keepOn: Bool = true
        
        let mouseDragOrUp : NSEvent.EventTypeMask = NSEvent.EventTypeMask(rawValue: UInt64(Int(NSEvent.EventTypeMask.leftMouseUp.union(.leftMouseDragged).rawValue)))
        
        while (keepOn) {
                
                let nextEvent : NSEvent = (self.window?.nextEvent(matching: mouseDragOrUp))!
                let mouseLocation: NSPoint = self.convert(nextEvent.locationInWindow, from: nil)
               // let isInsideWindow: Bool = self.isMousePoint(mouseLocation, in: self.bounds)
                
                switch (nextEvent.type) {
                    
                case NSEvent.EventType.leftMouseDragged:
                    isDragging = true
                    
                    lineAngle = NSBezierPath.lineAngleDegreesFrom(point1: self.bounds.centroid(), point2: mouseLocation)
                    lineAngle.formClamp(to: CGFloat(minValue)...CGFloat(maxValue))
                    
                    doubleValue = Double(lineAngle)
                    
                    if(self.isContinuous)
                    {
                        self.sendAction(self.action, to: self.target);
                    }
                   
                   // ----
                   // for live line:
                   // ---
                    var laDeg = lineAngle;
                    
                    let remainder = lineAngle.truncatingRemainder(dividingBy: 5);
                    if( remainder > 0)
                    {
                        laDeg -= remainder;
                    }
                    
                    liveLineAngleRadians = deg2rad(laDeg)
                    
                    
                    break
                    
                case NSEvent.EventType.leftMouseUp:
                   self.sendAction(self.action, to: self.target)
                    mouseIsDown = false
                    isDragging = false
                    keepOn = false
                    break
                    
                default:
                    // Ignoring any other type of event
                    break
                }
            }
        
    }


    override var isFlipped: Bool
    {
        return false
    }
    
}

// MARK: SUBCLASSES FOR NSCONTROLS

class NCTColorButton: NSButton {
    

    override func drawCell(_ cell: NSCell) {
        
    }
    
}


class NCTLabelTextField : NSTextField
{
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
             self.refusesFirstResponder = true;
        self.wantsLayer = true;
        let shadow = NSShadow();
        shadow.shadowBlurRadius = 3;
        self.shadow = shadow;
        
        //self.layer?.backgroundColor = NSColor.red.cgColor
        self.layer?.cornerRadius = 0
        self.layer?.shadowOpacity = 1.0;
        
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(3, 3)
        self.layer?.shadowRadius = 2;

        self.isSelectable = false;
        self.isEditable = false;
        
        self.focusRingType = .none
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    

}




@IBDesignable class NCTTextField : NSTextField, NSTextViewDelegate
{

    //@IBOutlet var matchingSlider : NCTSlider?

    var didEditDuringMouseEntered: Bool = false;

    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool
    {
    
        didEditDuringMouseEntered = true;
        
        if let nFormatter = self.formatter as? NumberFormatter
        {
            if let rStr = replacementString
            {
                if((nFormatter.minimum != nil) && (nFormatter.minimum != nil))
                {
                    if(rStr == "[")
                    {
                        self.decrement()
                        
                        return false;
                    }
                    else if(rStr == "]")
                    {
                        self.increment()
                        
                        return false;
                    }
                }
                
                // check if key pressed is backspace
                var isBackspace2 = false;
                if let char = rStr.cString(using: String.Encoding.utf8)
                {
                        let isBackSpace = strcmp(char, "\\b")
                        if (isBackSpace == -92)
                        {
                            
                            isBackspace2 = true;
                        }
                }
    
                //(Double(rStr) != nil)  ensures that it is a number
                // from https://stackoverflow.com/questions/26545166/how-to-check-is-a-string-or-number
                if((Double(rStr) != nil) || (rStr == ".") || (rStr == "\r") || isBackspace2)
                {
                
                
                   return true;
                }
                
                else
                {
                    
                    return false;
                }
                
                
            }
            
        
        }
        
        return true;
    }
    
    func increment()
    {
        if let nFormatter = self.formatter as? NumberFormatter
        {
                self.doubleValue += numberFieldIncrement;
                self.doubleValue = self.doubleValue.clamped(to: nFormatter.minimum!.doubleValue...Double(nFormatter.maximum!.doubleValue))
                self.sendAction(self.action, to: self.target)
        }
        
    }
    
    func decrement()
    {
        if let nFormatter = self.formatter as? NumberFormatter
        {
                self.doubleValue -= numberFieldIncrement;
                self.doubleValue = self.doubleValue.clamped(to: nFormatter.minimum!.doubleValue...Double(nFormatter.maximum!.doubleValue))
                self.sendAction(self.action, to: self.target)
        }
    }
    
    func toMinimum()
    {
        if let nFormatter = self.formatter as? NumberFormatter
        {
                
                self.doubleValue = nFormatter.minimum!.doubleValue
                self.sendAction(self.action, to: self.target)
        }
    }

    func toMaximum()
    {
        if let nFormatter = self.formatter as? NumberFormatter
        {
                
                self.doubleValue = nFormatter.maximum!.doubleValue
                self.sendAction(self.action, to: self.target)
        }
    
    }

    func flash()
    {
    
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.5
        animation.autoreverses = true;
        animation.duration = 0.1;
        self.layer!.add(animation, forKey: "opacity");
        
    }

    // turns label bold when mouse enters slider
    @IBOutlet var matchingLabelTextField : NSTextField?;

    @IBInspectable var numberFieldIncrement : Double = 1.0;

    override var acceptsFirstResponder: Bool { return true;}
        
    /*
    override func becomeFirstResponder() -> Bool
    {
        if(!super.becomeFirstResponder())
        {
            return false;
        }

        NSDictionary * attributes = [NSDictionary dictionaryWithObjectsAndKeys :
                     [NSColor orangeColor], NSBackgroundColorAttributeName, nil];

        NSTextView * fieldEditor = (NSTextView *)[[self window] fieldEditor:YES forObject:self];
        [fieldEditor setSelectedTextAttributes:attributes];

        return true;

    }
    */

    
   
    var trackingArea : NSTrackingArea = NSTrackingArea();
    
    override var allowsVibrancy: Bool
    {
        
        return false;
    }
    
    
    override var isEnabled: Bool
    {
         didSet
         {
            if(self.layer == nil)
            {
                self.wantsLayer = true
            }
            
            if(isEnabled == true)
            {
                self.layer?.borderColor = NSColor.black.cgColor
                self.layer?.borderWidth = 3.0
                self.layer?.opacity = 1.0;
                
            }
            else
            {
                self.layer?.opacity = 0.5;
                self.layer?.borderColor = NSColor(calibratedWhite: 0.15, alpha: 1.0).cgColor
                self.layer?.borderWidth = 2.0
            }
        }
        
    }
    
    @IBInspectable var borderColor : NSColor = NSColor.init(calibratedWhite: 0.2, alpha: 1.0);
    @IBInspectable var borderColorEntered : NSColor = NSColor.green;
 
    var standardBackgroundColor = NSColor.clear//.init(calibratedWhite: 0.2, alpha: 1.0)
    var highlightBackgroundColor = NSColor.init(calibratedWhite: 0.0, alpha: 1.0)
    
    override func awakeFromNib() {
        
        self.wantsLayer = true
        self.focusRingType = .none;
        
        // to inform when there is no target
        if(self.target == nil)
        {
            borderColor = NSColor.red;
        }
        
        self.layer?.borderColor = borderColor.cgColor;
        self.layer?.borderWidth = 1.0
        self.layer?.cornerRadius = 0.0
        
        self.backgroundColor = standardBackgroundColor;
        self.textColor = NSColor.init(calibratedWhite: 0.8, alpha: 1.0)
        
        self.font = NSFont.init(name: "DINAlternate-Bold", size: self.frame.height - (self.frame.height * 0.35)) ?? NSFont.systemFont(ofSize: self.font?.pointSize ?? (self.frame.height - (self.frame.height * 0.35)))
     
        
            
        let shadow = NSShadow();
        shadow.shadowBlurRadius = 3;
        self.shadow = shadow;
        
        //self.layer?.backgroundColor = NSColor.red.cgColor
        self.layer?.cornerRadius = 0
        self.layer?.shadowOpacity = 1.0;
        
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(3, 3)
        self.layer?.shadowRadius = 2;
        

    }
    
    override func keyDown(with event: NSEvent)
    {
        super.keyDown(with: event)
    
        
    }
    
    var mouseIsInside : Bool = false;
    
    override func mouseEntered(with event: NSEvent)
    {
    
        mouseIsInside = true;
        self.layer?.borderColor = borderColorEntered.cgColor;
        self.backgroundColor = highlightBackgroundColor;
        
       // self.selectText(self);
       // self.currentEditor()?.selectedRange = NSMakeRange(0, self.stringValue.count);
        self.window!.makeKey();
        self.window!.makeFirstResponder(self);
        self.needsDisplay = true;
        
        
        
    }
    
    override func mouseExited(with event: NSEvent)
    {
        mouseIsInside = false;
        self.layer?.borderColor = borderColor.cgColor;
        self.backgroundColor = standardBackgroundColor;
        
        
        if(didEditDuringMouseEntered)
        {
            // https://www.mail-archive.com/search?l=cocoa-dev@lists.apple.com&q=subject:%22Re%5C%3A+Stop+edit+session+with+a+NSTextField%22&o=newest&f=1
            self.window!.perform(#selector(window!.makeFirstResponder(_:)), with: self.superview!, afterDelay: 0.0);
            //self.window!.makeFirstResponder(self.superview!);
            
        }
         
        self.needsDisplay = true;
        
        didEditDuringMouseEntered = false;
        
    }
    

    // from https://stackoverflow.com/questions/12079531/cant-change-the-mouse-cursor-of-a-nstextfield
    override func becomeFirstResponder() -> Bool {
       // addTrackingAreaIfNeeded()
        return super.becomeFirstResponder()
    }
    
    /*
    private func addTrackingAreaIfNeeded() {
        if trackingAreas.isEmpty {
            let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
            addTrackingArea(area)
        }
    }
    */
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        NSCursor.crosshair.set()
    }
    
                     
    let grad = NSGradient.init(colors: [NSColor.clear,NSColor.init(calibratedWhite: 1.0, alpha: 0.2),NSColor.clear,NSColor.init(calibratedWhite: 0.1, alpha: 0.4)], atLocations: [0,0.0,0.8,0.9], colorSpace: NSColorSpace.deviceRGB)
    
    override func draw(_ dirtyRect: NSRect) {
        
        
        NSGraphicsContext.current?.saveGraphicsState()
            self.standardBackgroundColor.setFill();
            dirtyRect.fill();
            
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 2.0
            shadow.shadowOffset = NSSize(width: 2, height: -2)
            shadow.shadowColor = NSColor.black
            shadow.set()
            
            let p = NSBezierPath();
            p.appendRect(self.bounds)
            grad?.draw(in: p, angle: 90)
            
            super.draw(dirtyRect)
        NSGraphicsContext.current?.restoreGraphicsState()
        
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

// from https://stackoverflow.com/questions/11775128/set-text-vertical-center-in-nstextfield
class CustomTextFieldCell: NSTextFieldCell {

    func adjustedFrame(toVerticallyCenterText rect: NSRect) -> NSRect {
        // super would normally draw text at the top of the cell
        var titleRect = super.titleRect(forBounds: rect)
        titleRect.origin.x -= 3;
        titleRect.size.width += 3;
        let minimumHeight = self.cellSize(forBounds: rect).height
        titleRect.origin.y += (-2 + (titleRect.height - minimumHeight) / 2)
        titleRect.size.height = minimumHeight

        return titleRect
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: adjustedFrame(toVerticallyCenterText: cellFrame), in: controlView)
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.draw(withFrame: cellFrame, in: controlView)
    }
}

// MARK: TITLEBAR VIEWS
class NCTTitleBarViewAcceptsFirstMouse : NSView
{
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

class NCTClickableNSBox : NSBox
{
    @IBOutlet var targetForMouseDown : AnyObject?

    override func mouseDown(with event: NSEvent)
    {
            
        
    }

}

@IBDesignable class NCTCheckbox :  NSButton
{
    @IBInspectable var borderColor : NSColor = NSColor.black;
    @IBInspectable var borderColorEntered : NSColor = NSColor.green;

    var mouseIsInside : Bool = false
    {
        didSet
        {
        
        }
    }

    @IBInspectable var titleColorStored : NSColor = .white
    {
        didSet
        {
            titleColor = titleColorStored
        }
    
    }
    
    @objc var titleColor : NSColor = .white
    {
        didSet{
        
            if let mutableAttributedTitle = attributedTitle.mutableCopy() as? NSMutableAttributedString {
        mutableAttributedTitle.addAttribute(.foregroundColor, value: titleColor, range: NSRange(location: 0, length: mutableAttributedTitle.length))
        attributedTitle = mutableAttributedTitle
            }
        
        }
    }

    @IBInspectable var titleHighlight : NSColor = .green
    





    override func mouseEntered(with event: NSEvent)
    {
        
        titleColor = titleHighlight;
        mouseIsInside = true;
        
       // self.layer?.backgroundColor = NSColor.black.cgColor
        
        self.needsDisplay = true;
    }
    
    override func mouseExited(with event: NSEvent)
    {
        
        titleColor = titleColorStored;
        mouseIsInside = false;
        
     //   self.layer?.backgroundColor = NSColor.clear.cgColor
        
        self.needsDisplay = true;
    }
    
    var trackingArea : NSTrackingArea = NSTrackingArea();
    
    
    override func updateTrackingAreas()
    {
        
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }

}

class NCTSkinnedCheckboxCell :  NSButtonCell
{
    @IBInspectable var checkboxOnBackgroundColor : NSColor =  NSColor(calibratedWhite: 0.1, alpha: 1.0) 
   
  @IBInspectable var checkboxOffBackgroundColor : NSColor =  NSColor(calibratedWhite: 0.3, alpha: 1.0)
  
   let grad = NSGradient.init(colors: [NSColor.clear,NSColor.init(calibratedWhite: 1.0, alpha: 0.2),NSColor.clear,NSColor.init(calibratedWhite: 0.1, alpha: 0.4)], atLocations: [0,0.0,0.8,0.9], colorSpace: NSColorSpace.deviceRGB)
  
    override var isEnabled: Bool
    {
         didSet
         {
            if(self.controlView!.layer == nil)
            {
                self.controlView!.wantsLayer = true
            }
            
            if(isEnabled == true)
            {
              //  self.controlView!.layer?.borderColor = NSColor.black.cgColor
               // self.controlView!.layer?.borderWidth = 3.0
                self.controlView!.layer?.opacity = 1.0
            }
            else
            {
                self.controlView!.layer?.opacity = 0.5;
                
            }
        }
        
    }
    
    override func awakeFromNib() {
//        self.controlTint = NSControlTint.clearControlTint;
        
    }
    

    
    /*
    // if modifying how text is displayed
    override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect
    {
        var titleAttributed = NSMutableAttributedString(attributedString: title)
    
        if let nctCheckboxButton = controlView as? NCTCheckbox
        {
        
        
        }

        return super.drawTitle(titleAttributed, withFrame: frame, in: controlView)

    }*/
    
    override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {

        var doHighlight = false;
        if let nctCheckboxButton = controlView as? NCTCheckbox
        {
            doHighlight = nctCheckboxButton.mouseIsInside;
        
        }


        let mini :CGFloat = 10;
        let med :CGFloat = 12;
        let regular :CGFloat = 16;

        var frameForOutline = frame;
        if(self.controlSize == NSControl.ControlSize.mini)
        {
            
        
            frameForOutline = NSMakeRect(0, 0, mini, mini)//.centerInRect(frameForOutline)
        }
        else if(self.controlSize == NSControl.ControlSize.small)
        {
            frameForOutline = NSMakeRect(0, 0, med, med)//.centerInRect(frameForOutline)
        }
        else if(self.controlSize == NSControl.ControlSize.regular)
        {
            frameForOutline = NSMakeRect(0, 0, regular, regular)//.centerInRect(frameForOutline)
        }
        else
        {
           frameForOutline = NSMakeRect(0, 0, regular, regular)//.centerInRect(frameForOutline)
        }

        let checkboxPath = NSBezierPath();
        checkboxPath.appendRoundedRect(frameForOutline, xRadius: 2.5, yRadius: 2.5);
        NSColor.black.setStroke();
        
        self.checkboxOffBackgroundColor.setFill()
        
        
        
        
        if(self.state == NSControl.StateValue.on)
        {
        
            self.checkboxOnBackgroundColor.setFill()
           
               
            //NSColor(calibratedWhite: 0.2, alpha: 1.0).blended(withFraction: 0.3, of: NSColor.green)?.setFill()
        }
        
        if(self.state == NSControl.StateValue.off)
        {
            //NSColor(calibratedWhite: 0.5, alpha: 1.0).blended(withFraction: 0.5, of: NSColor.red)?.setFill();
            
            //NSColor(calibratedWhite: 0.2, alpha: 1.0).blended(withFraction: 0.3, of: NSColor.red)?.setFill()
        }
        
        checkboxPath.fill();
        
        grad?.draw(in: checkboxPath, angle: 90);
        
        if(doHighlight)
        {
            NSColor.green.setStroke();
        }
        
        checkboxPath.stroke();
        
        if(self.state == NSControl.StateValue.on)
        {
            let factor = frameForOutline.width / regular;
            
            let frameAdjustedForCheck = frameForOutline.insetBy(dx: factor * 4.0, dy: factor * 4.0)
            checkboxPath.removeAllPoints();
            checkboxPath.move(to: NSMakePoint(NSMinX(frameAdjustedForCheck), NSMidY(frameAdjustedForCheck)) )
            checkboxPath.line(to: NSMakePoint(NSMidX(frameAdjustedForCheck) , NSMaxY(frameAdjustedForCheck) - 1 ) )
            checkboxPath.line(to: NSMakePoint(NSMaxX(frameAdjustedForCheck) , NSMinY(frameAdjustedForCheck) ) )
            checkboxPath.lineWidth = factor * 4;
            //NSColor(calibratedWhite: 0.8, alpha: 1.0).setStroke();
            NSColor(calibratedWhite: 0.8, alpha: 1.0).setStroke();
            checkboxPath.lineCapStyle = .round;
            checkboxPath.stroke();
            
        }
        else if(self.state == NSControl.StateValue.off)
        {
            
        }
        else if(self.state == NSControl.StateValue.mixed)
        {
            let frameAdjustedForCheck = frameForOutline.insetBy(dx: 2, dy: 2)
            checkboxPath.removeAllPoints();
            checkboxPath.move(to: NSMakePoint(NSMinX(frameAdjustedForCheck), NSMidY(frameAdjustedForCheck)) )
            checkboxPath.line(to: NSMakePoint(NSMaxX(frameAdjustedForCheck) , NSMidY(frameAdjustedForCheck) ) )
          
            checkboxPath.lineWidth = 2;
            NSColor.white.setStroke();
            checkboxPath.stroke();
        }
        
        
    }
    
}

/*
class NCTStepArrowButton : NCTButton
{
    override func draw(_ dirtyRect: NSRect)
    {
        
    }

}*/

@IBDesignable class NCTPanelBox1 : NSBox
{
    var labelForBox : NCTLabelTextField = NCTLabelTextField.init();

    @IBInspectable var isInUse : Bool = true;

    @IBInspectable var fontSize : CGFloat = 15;

    @IBInspectable var fontPostScriptName : String = "SFCompactDisplay-Bold"
    @IBInspectable var fontColor : NSColor = NSColor.white;
    @IBInspectable var xFlippedOffset : CGFloat = 3;
    @IBInspectable var yFlippedOffset : CGFloat = 0;
    
    @objc @IBInspectable var labelText : NSString = "default"
    {
        didSet{
//           labelForBox.textColor = self.fontColor
        
//        labelForBox.font = NSFont.init(name: self.fontPostScriptName, size: self.fontSize) ?? NSFont.systemFont(ofSize: self.fontSize);
  labelForBox.textColor = self.fontColor
        
        labelForBox.font = NSFont.init(name: self.fontPostScriptName, size: self.fontSize) ?? NSFont.systemFont(ofSize: self.fontSize);
            labelForBox.setValue(labelText, forKey: "stringValue")
          var b = self.bounds;
        b.size.height = fontSize;
        

        
        labelForBox.setFrameSize(b.size)
        labelForBox.setFrameOrigin(self.bounds.topLeft().offsetBy(x: -0.5 * fontSize, y: b.size.height + 20))
        labelForBox.isBordered = false;
        labelForBox.backgroundColor = .clear;
        }
    }

    override var acceptsFirstResponder: Bool
    {
        return false;
    }

    // comes after the didSet of labelText
    override func awakeFromNib()
    {
        self.boxType = .custom;
        self.superview?.focusRingType = .none;
        self.focusRingType = .none
        self.wantsLayer = true;
        let shadow = NSShadow();
        shadow.shadowBlurRadius = 3;
        self.shadow = shadow;
        
        //self.layer?.backgroundColor = NSColor.red.cgColor
        self.layer?.cornerRadius = 0
        self.layer?.shadowOpacity = 1.0;
        
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(3, -3)
        self.layer?.shadowRadius = 2;
        
        labelForBox.textColor = self.fontColor
        
        labelForBox.font = NSFont.init(name: self.fontPostScriptName, size: self.fontSize) ?? NSFont.systemFont(ofSize: self.fontSize);

        labelForBox.setValue(labelText, forKey: "stringValue")

        labelForBox.isBordered = false;
        labelForBox.backgroundColor = .clear;
        
        var b = self.bounds;
        b.size.height = self.fontSize;
        labelForBox.setFrameSize(b.size)
        labelForBox.setFrameOrigin(self.bounds.topLeft().offsetBy(x: -5, y: b.size.height + 3))
        
        var b2Frame = labelForBox.frame.offsetBy(dx: 0, dy: -5);
        b2Frame.origin.x = 0;
        let b2 : NSBox = NSBox.init(frame: b2Frame)
        b2.boxType = .custom;
        b2.setFrameSize(NSSize.init(width: self.bounds.size.width, height: 1.0))
        b2.borderColor = .darkGray
        self.addSubview(b2)
        
    
        
        
        self.addSubview(labelForBox)
    }

    @IBInspectable var firstGradientColor : NSColor = NSColor.init(calibratedWhite: 1.0, alpha: 0.2)
    @IBInspectable var secondGradientColor : NSColor = NSColor.init(calibratedWhite: 0.1, alpha: 0.2)


    func setupGradient()
    {
        backgroundGradient = NSGradient.init(colors: [NSColor.clear, firstGradientColor,NSColor.clear, secondGradientColor ], atLocations: [0,0.0,0.8,0.9], colorSpace: NSColorSpace.deviceRGB)
    }
    

    var backgroundGradient : NSGradient?
  
    override func draw(_ dirtyRect: NSRect) {

      //  super.draw(dirtyRect)
        
        let p = NSBezierPath();
        p.appendRoundedRect(self.bounds, xRadius: self.cornerRadius, yRadius: self.cornerRadius)
        self.fillColor.setFill();
        self.borderColor.setStroke();
        p.lineWidth = self.borderWidth;
        p.fill()
      
        let b = NSMakeRect(0, self.bounds.height - 23, 300, 23)
        let bgC = fillColor.blended(withFraction: 0.5, of: NSColor.black) ?? .black
        bgC.setFill()
        b.fill()
        
        p.stroke();


      
        

//        self.drawPageBorder(with: self.bounds.size)
        
        /*
           NSGraphicsContext.current?.saveGraphicsState()
         //       self.standardBackgroundColor.setFill();
           //     dirtyRect.fill();
                
                let shadow = NSShadow()
                shadow.shadowBlurRadius = 2.0
                shadow.shadowOffset = NSSize(width: 2, height: -2)
                shadow.shadowColor = NSColor.black
                shadow.set()


             grad?.draw(in: self.bounds, angle: 90);
            
            
            NSGraphicsContext.current?.restoreGraphicsState()
            */
        
    }

}

class NCTColorButtonCell: NSButtonCell {
    
    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {
        NSColor.green.setFill()
        frame.fill()
    }

}



@IBDesignable class NCTColorWell : NSColorWell
{

    @IBOutlet var colorPickerPopover : NSPopover?;
    @IBOutlet var colorPickerView : ColorPickerView!;
    
    var trackingArea : NSTrackingArea = NSTrackingArea();
  
    @IBInspectable var borderColor : NSColor = NSColor.black;
    @IBInspectable var borderColorEntered : NSColor = NSColor.green;
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
        
    }
    
    override var acceptsFirstResponder: Bool { return true;}
    
    
    override func updateTrackingAreas()
    {
        
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
    
    
    
    override func mouseEntered(with event: NSEvent)
    {
        self.layer?.borderColor = borderColorEntered.cgColor;
    
        self.window!.makeKey();
        self.window!.makeFirstResponder(self);
        self.needsDisplay = true;

    }
    
    override func mouseExited(with event: NSEvent)
    {
        self.layer?.borderColor = borderColor.cgColor;
    }
    

    
    override func awakeFromNib()
    {
        self.wantsLayer = true
        self.layer?.borderColor = borderColor.cgColor;
        self.layer?.borderWidth = 3.0
        self.layer?.cornerRadius = 0.0
        
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.isBordered = false;
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.isBordered = false;
    }
    

    
    override func draw(_ dirtyRect: NSRect)
    {
        self.color.drawSwatch(in: self.bounds);
        
        
    }

    override func keyDown(with event: NSEvent)
    {
    
        if(event.keyCode == tabKey)
        {
            launchPopover(relativeToBounds: self.bounds, positioningView: self, preferredEdge: NSRectEdge.minY)
        }

    }
    
    func launchPopover(relativeToBounds : NSRect, positioningView: NSView, preferredEdge: NSRectEdge)
    {
        if colorPickerPopover != nil
        {
           colorPickerPopover!.close();

            colorPickerView.launchingColorWell = self;
           colorPickerView.colorWell.target = self.target;
           colorPickerView.colorWell.action = self.action
           colorPickerView.loadColor(self.color, sendAction:false)
           

            NotificationCenter.default.post(name: Notification.Name.init("NCTCloseAnyPopovers"), object: self)
            
            colorPickerPopover!.show(relativeTo: relativeToBounds, of: positioningView, preferredEdge: preferredEdge)
            
            NotificationCenter.default.post(name: Notification.Name.init("NCTCurrentlyShownPopover"), object: colorPickerPopover)
            
        }
        
    }
    
    // Used to prevent premature disappearance of
    // popover
    @IBInspectable var preferredEdgeInt : UInt = NSRectEdge.minY.rawValue
    /*
        case minX = 0

        case minY = 1

        case maxX = 2

        case maxY = 3
     */
    
    override func mouseDown(with event: NSEvent)
    {
        
        launchPopover(relativeToBounds: self.bounds, positioningView: self, preferredEdge: NSRectEdge.init(rawValue: preferredEdgeInt) ?? .minY)
        
    }
    

    
    
}

@IBDesignable class NCTPaintRepModeColorWell : NCTColorWell 
{


}

@IBDesignable class NCTSlider : NSSlider {
 
    // turns bold when mouse enters slider
    @IBOutlet var matchingLabelTextField : NCTTextField?;
 
    @IBInspectable var borderColor : NSColor = NSColor.black;
    @IBInspectable var borderColorEntered : NSColor = NSColor.green;
 
    @objc dynamic var sliderTitle : String = ""
    
    var mouseIsInside : Bool = false;
    
    var trackingArea : NSTrackingArea = NSTrackingArea();
  
    
    
  
    override var acceptsFirstResponder: Bool { return true;}
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        
        return true
        
    }
    
    override func viewDidMoveToWindow()
    {
        self.cell = self.cell?.copy() as? NCTSliderCell
        
        focusRingType = .none;
        
    }
    
    override func updateTrackingAreas()
    {
        
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
    
    
    
    
    /*
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // draw rotated string here
        //
        
        
    }
    */
    override func mouseEntered(with event: NSEvent)
    {
    
        mouseIsInside = true;
        updateHighlightKnobPoint();
        
        borderColor = borderColorEntered;
        
      //  self.layer?.backgroundColor = NSColor.black.cgColor
        
        self.window!.makeKey();
        self.window!.makeFirstResponder(self);
        
        
        self.needsDisplay = true;

        
    }

    override func mouseExited(with event: NSEvent)
    {
        mouseIsInside = false;
        borderColor = NSColor.black;
        
     //   self.layer?.backgroundColor = NSColor.clear.cgColor
        
        self.needsDisplay = true;
    }
    
    
    
    override func mouseMoved(with event: NSEvent)
    {
        if(mouseIsInside)
        {
            updateHighlightKnobPoint()
            self.needsDisplay = true;
        }

    }
    
    var highlightKnobPoint : NSPoint = .zero;
    
    func updateHighlightKnobPoint()
    {
        
        highlightKnobPoint = self.convert(self.window!.mouseLocationOutsideOfEventStream, from: nil)
    
    }
    
    
    override func keyDown(with event: NSEvent)
    {
        // set to minimum of slider
        if(event.characters!.contains("-"))
        {
        
        
              self.doubleValue = self.minValue;
              self.sendAction(self.action, to: self.target)
          
        
        }
        // set to maximum of slider
        else if(event.characters!.contains("="))
        {
        

                self.doubleValue = self.maxValue;
                self.sendAction(self.action, to: self.target)

        
        }
        // decrement slider
        else if(event.characters!.contains("["))
        {
        
            if(self.sliderType == .linear)
            {
                
//                let numericRangeOfSlider = abs(self.maxValue - self.minValue)
                
                // decrement amount is
                // height or width (length) of slider
//                let lengthOfSlider = self.isVertical ? self.frame.height : self.frame.width;
                // divided by 2
//                let pxTravel = lengthOfSlider / 2;
                
                //let valueTravel = numericRangeOfSlider /
                
                //self.doubleValue = () ? : self.minValue
//                self.sendAction(self.action, to: self.target)
            }
           
        
        }
        // increment slider
        else if(event.characters!.contains("]"))
        {
        
            if(self.sliderType == .linear)
            {


            }
            
        }
        else if(event.keyCode == tabKey)
        {
            let point : NSPoint = self.window!.mouseLocationOutsideOfEventStream
            
             let mouseDownEvent : NSEvent = NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: NSEvent.ModifierFlags(rawValue: 0), timestamp: ProcessInfo().systemUptime, windowNumber: self.window!.windowNumber, context: nil, eventNumber: 200, clickCount: 1, pressure: 1.0)!
                    
            self.mouseDown(with: mouseDownEvent)
                    
        
        }

    }

    var isDragging: Bool = false
    override func mouseDown(with event: NSEvent)
    {
    
            if(self.sliderType == .circular)
            {
           
           // from
           // https://github.com/hpbl/BezierCurve-ConvexHull/blob/12762b1a6cf2f0a3520d1fbf21a01350c2027abb/projeto1/projeto1/OpenGLView.swift
            let p = self.convert(event.locationInWindow, from: nil)
         
           var lineAngle = 360 - NSBezierPath.lineAngleDegreesFrom(point1: self.bounds.centroid(), point2: p)
          
           doubleValue = mapy(n: Double(lineAngle), start1: 0, stop1: 360, start2: self.minValue, stop2: self.maxValue)
                    
                    
           //loop control variables
            var keepOn: Bool = true
         
            
            let mouseDragOrUp : NSEvent.EventTypeMask = NSEvent.EventTypeMask(rawValue: UInt64(Int(NSEvent.EventTypeMask.leftMouseUp.union(.leftMouseDragged).rawValue)))
         

            while (keepOn) {
                
                let nextEvent : NSEvent = (self.window?.nextEvent(matching: mouseDragOrUp))!
                let mouseLocation: NSPoint = self.convert(nextEvent.locationInWindow, from: nil)
               // let isInsideWindow: Bool = self.isMousePoint(mouseLocation, in: self.bounds)
                
                switch (nextEvent.type) {
                    
                case NSEvent.EventType.leftMouseDragged:
                    isDragging = true
                    
                    lineAngle = 360 - NSBezierPath.lineAngleDegreesFrom(point1: self.bounds.centroid(), point2: mouseLocation)

                    
                    doubleValue = mapy(n: Double(lineAngle), start1: 0, stop1: 360, start2: self.minValue, stop2: self.maxValue)
                    
                    if(self.isContinuous)
                    {
                        self.sendAction(self.action, to: self.target);
                    }
                    
                    break
                    
                case NSEvent.EventType.leftMouseUp:
                   self.sendAction(self.action, to: self.target)
                    
                    isDragging = false
                    keepOn = false
                    break
                    
                default:
                    // Ignoring any other type of event
                    break
                }
            }
            return

        }// END if(self.sliderType == .circular)
        
        else
        {
        
            super.mouseDown(with: event);
            
        }

    }
    
  
    /*
    override class func awakeFromNib()
    {
        // to inform when there is no target
        
        /*if(self.target == nil)
        {
            borderColor = NSColor.red;
        }*/
    }*/

  
    // 0 : none
    // 1 : incline
    // 2 : gradient from both sides
    // 3 : fill
    @IBInspectable var sliderBackgroundType : Int = 0;

    @IBInspectable var sliderBackgroundModeFillColor : NSColor = .gray;
    @IBInspectable var sliderBackgroundModeStrokeColor : NSColor = .lightGray;
    @IBInspectable var useSliderBackgroundModeStrokeColor : Bool = true;
    @IBInspectable var strokeTheSliderFrameRect : Bool = false;
    
}


class NCTSliderCell : NSSliderCell
{
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        if let nctSlider = controlView as? NCTSlider
        {
            
            if((nctSlider.sliderBackgroundType == 1) && (nctSlider.isVertical == false))
            {
            
                let rect = nctSlider.bounds.insetBy(dx: nctSlider.allowsTickMarkValuesOnly ? 3 : 8, dy: 0)
                let inclPath = NSBezierPath();
                inclPath.move(to: rect.topLeft())
                inclPath.line(to: rect.topRight())
                inclPath.line(to: rect.bottomRight())
                inclPath.close()
                nctSlider.sliderBackgroundModeFillColor.setFill()
                
                //inclPath.fill()
                
                 let grad = NSGradient.init(colors: [
                NSColor.white,
                nctSlider.sliderBackgroundModeFillColor.withAlphaComponent(0.8),
                
                ], atLocations: [0,1.0], colorSpace:
                        NSColorSpace.sRGB)
                        grad?.draw(in: inclPath, angle: 0)
                
                if(nctSlider.useSliderBackgroundModeStrokeColor)
                {
                    if(nctSlider.strokeTheSliderFrameRect)
                    {
                    nctSlider.sliderBackgroundModeStrokeColor.withAlphaComponent(0.5).setFill()
                    rect.frame()
                    }
                    nctSlider.sliderBackgroundModeStrokeColor.setStroke()

                    inclPath.stroke();
                    
                }
            }
            else  if((nctSlider.sliderBackgroundType == 2) && (nctSlider.isVertical == false))
            {
                let rect = nctSlider.bounds.insetBy(dx: nctSlider.allowsTickMarkValuesOnly ? 3 : 8, dy: 0)
                
                let p = NSBezierPath()
                p.appendRect(rect)
                let grad = NSGradient.init(colors: [
                nctSlider.sliderBackgroundModeFillColor.withAlphaComponent(0.8),
                nctSlider.sliderBackgroundModeFillColor.withAlphaComponent(0.8),
                NSColor.white.withAlphaComponent(0.8),
                nctSlider.sliderBackgroundModeFillColor.withAlphaComponent(0.8),
                nctSlider.sliderBackgroundModeFillColor.withAlphaComponent(0.8),
                
                ], atLocations: [0,0.15,0.5,0.85,1.0], colorSpace:
                        NSColorSpace.sRGB)
                        grad?.draw(in: p, angle: 0)//nctSlider.isFlipped ? 0 : 270 )
                 if(nctSlider.useSliderBackgroundModeStrokeColor)
                {
                    /*
                    nctSlider.sliderBackgroundModeStrokeColor.withAlphaComponent(0.5).setFill()
                    rect.frame()*/
                    if(nctSlider.strokeTheSliderFrameRect)
                    {
                    nctSlider.sliderBackgroundModeStrokeColor.setStroke()

                    p.stroke();
                    }
                    
                }
                
            }
            if(nctSlider.sliderBackgroundType == 3)
            {
                nctSlider.sliderBackgroundModeFillColor.setFill()
                nctSlider.bounds.fill()
            }
        }
        super.draw(withFrame: cellFrame, in: controlView)
    }
    
    override func drawBar(inside rect: NSRect, flipped: Bool)
    {
      //  super.drawBar(inside: rect, flipped: flipped)
        
        var doHighlight = false;
        let nctSlider = controlView as! NCTSlider
        

            doHighlight = nctSlider.mouseIsInside;
       
        
        let rect2 = isVertical ? rect : rect.insetBy(dx: nctSlider.allowsTickMarkValuesOnly ? 2 : 8, dy: 0)
            
        if let slider = self.controlView as?  NCTSlider
        {
        
                let barPath = NSBezierPath();
                barPath.lineWidth = 1;
            
                if(self.sliderType == .linear)
                {
                    NSColor.black.setFill();
                    
                    if(doHighlight == false)
                    {
                        NSColor.gray.setStroke();
                    }
                    else
                    {
                        NSColor.green.setStroke();
                    }
                    
                    
                    if(slider.isVertical)
                    {
                    
                        barPath.appendRoundedRect(rect2, xRadius: rect2.width / 3.0, yRadius: rect2.width / 3.0)
                        
                        barPath.fill();
                        barPath.stroke();
                        
                        if(slider.mouseIsInside)
                        {
                            let highlightKnobPath = NSBezierPath();
                            highlightKnobPath.move(to: NSMakePoint(0, slider.highlightKnobPoint.y))
                            highlightKnobPath.line(to: NSMakePoint(slider.frame.width,slider.highlightKnobPoint.y)	)
                            NSColor.green.setStroke()
                            highlightKnobPath.stroke();
                        }
                        
                    }
                    else
                    {
                        
                        barPath.appendRoundedRect(rect2, xRadius: rect2.height / 3.0, yRadius: rect2.height / 3.0)
                        
                        barPath.fill();
                        barPath.stroke();
                        
                        if(slider.mouseIsInside)
                        {
                            let highlightKnobPath = NSBezierPath();
                            highlightKnobPath.move(to: NSMakePoint(slider.highlightKnobPoint.x, 0))
                            highlightKnobPath.line(to: NSMakePoint(slider.highlightKnobPoint.x, slider.frame.height))
                            NSColor.green.setStroke()
                            highlightKnobPath.stroke();
                        }
                        
                    }
                
                }
                
                
        }
        
        
    }
    
    
    override func drawKnob(_ knobRect: NSRect)
    {
        
        
        
        if let slider = self.controlView as?  NSSlider
        {
            if(self.sliderType == .linear)
            {
                // temporary
                //super.drawKnob(knobRect);
                
                let knobPath = NSBezierPath();
                
                
                if(slider.isVertical)
                {
                knobPath.appendRoundedRect(knobRect.insetBy(dx: 0, dy: knobRect.height / 3), xRadius: knobRect.height / 3.0, yRadius: knobRect.height / 3.0)
                
                
                }
                else
                {
                    knobPath.appendRoundedRect(knobRect.insetBy(dx: knobRect.width / 3.0, dy: 0), xRadius: knobRect.width / 3.0, yRadius: knobRect.width / 3.0)
                
                 
                }
                    NSColor.black.setFill();
                    knobPath.fill();
                    NSColor.lightGray.setStroke()
                    knobPath.stroke();
            }
            
            if(self.sliderType == .circular)
            {
                // temporary:
                //super.drawKnob(knobRect);
                
                let angleInDegrees = 360 - mapy(n: self.doubleValue, start1: self.minValue, stop1: self.maxValue, start2: 0, stop2: 360)
                let angleInRadians = deg2rad(CGFloat(angleInDegrees))
               
                
                
                
                let point1 = slider.bounds.centroid();
                
                let width = 0.5 * slider.bounds.width - 2.0;
                
    
                let point2 = NSMakePoint( point1.x + (width * cos(angleInRadians)), point1.y + (width * sin(angleInRadians)) )

                if let nctSlider = self.controlView as? NCTSlider
                {
                    let circleOutlinePath = NSBezierPath();
                    circleOutlinePath.lineWidth = 2;
                    circleOutlinePath.appendArc(withCenter: point1, radius: width, startAngle: 0, endAngle: 360)
                    nctSlider.borderColor.setStroke();
                    NSColor.darkGray.setFill();
                    circleOutlinePath.fill();
                    circleOutlinePath.stroke();
                    
                }
                
                NSColor.green.setStroke();
                let p = NSBezierPath();
                p.lineWidth = 2;
                p.move(to: point1)
                p.line(to: point2)
                
                p.stroke();
                

                
            }
            
        }
        
    }
    
}

class NCTLabelAsButton : NSTextField
{

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        self.sendAction(self.action, to: self.target);

    }
    
    override func mouseEntered(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
    }

    override func mouseExited(with event: NSEvent) {
//        self.window?.makeFirstResponder(self)
    }
    
    override func viewDidMoveToWindow() {
        
        // for mouseMoved events
        //self.window?.acceptsMouseMovedEvents = true
        
        
        // for mouseEntered and Exited events
        let options = NSTrackingArea.Options.mouseEnteredAndExited.rawValue |
            NSTrackingArea.Options.activeAlways.rawValue;
        
        trackingArea = NSTrackingArea(rect: bounds, options: NSTrackingArea.Options(rawValue: options), owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
    
    // for keydown
    override var acceptsFirstResponder: Bool { return true }
    
    var trackingArea = NSTrackingArea();
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited,.mouseMoved],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }

}


// MARK: -
// MARK: LINE DASH
extension NSBezierPath
{

 func lineDash() -> LineDash
    {
        var lineDash = LineDash(count: 0, pattern: Array.init(repeating: 0, count: 16), phase: 0)
        
        self.getLineDash(&lineDash.pattern, count: &lineDash.count, phase: &lineDash.phase)

        if(lineDash.count < lineDash.pattern.count)
        {
            lineDash.pattern = lineDash.pattern.dropLast(lineDash.pattern.count - lineDash.count)
        }
        
        
        return lineDash
        
    }
    
}

class LineDashPopUpButton : NSPopUpButton
{

    let s = "DASHING"
    
    override func draw(_ dirtyRect: NSRect)
    {
    
        if let menuItemView = self.selectedItem?.view as? LineDashMenuItemView
        {
            let p = NSBezierPath()
            p.appendRoundedRect(self.bounds, xRadius: 5, yRadius: 5)
            NSGraphicsContext.saveGraphicsState()
            p.addClip()
            menuItemView.drawLineDashForPopUpButton(dirtyRect)
            
            
            s.drawStringInsideRectWithSystemFont(fontSize: 10.0, textAlignment: .left, fontForegroundColor: .white, rect: self.bounds.insetBy(dx: 4, dy: 4))
            
            NSGraphicsContext.restoreGraphicsState()
            
            p.lineWidth = 2.0;
            NSColor.lightGray.setStroke();
            p.stroke()
            
        }
        else
        {
            super.draw(dirtyRect)
        }
    }

    override func drawCell(_ cell: NSCell) {
        
    }
    
    

}

class LineDashMenuItemView : NSView
{
    var lineDash : LineDash = LineDash.init(count: 0, pattern: [], phase: 0)
    
    var isCustomMode : Bool = false;

    func makeCustomMode()
    {
        isCustomMode = true;
        
        var frameForTextField = self.bounds;
        frameForTextField.size.width = 40;
        frameForTextField.origin.x = 41;
        
        let textField = NCTTextField.init(frame: frameForTextField)
        textField.target = self;
        textField.action = #selector(changeCustomLineDash(_:))
        self.addSubview(textField);
    
        textField.stringValue = lineDash.patternStringRepresentation();
        textField.backgroundColor = .white
        textField.focusRingType = .none;
    }
    
    @objc func changeCustomLineDash(_ sender : AnyObject?)
    {
    
    }
    
    init(lineDash:LineDash)
    {
        super.init(frame: .zero);
    
        self.lineDash = lineDash;
    
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect)
    {
        

        lineDash.display(inRect: self.bounds, isHorizontal: true, strokeColor: NSColor.white, backgroundColor: self.enclosingMenuItem!.isHighlighted ? .gray : .black);
        
        if(isCustomMode == false)
        {
            lineDash.patternStringRepresentation().drawStringInsideRectWithMenlo(fontSize: 10, textAlignment: .left, fontForegroundColor: .white, rect: self.frame)
        }
        else
        {
            let s = "custom:"
            s.drawStringInsideRectWithMenlo(fontSize: 10, textAlignment: .left, fontForegroundColor: .white, rect: self.frame)
        }
        
        
 
        
        
        
    }
    
    func drawLineDashForPopUpButton(_ dirtyRect:NSRect)
    {
        let g = NSGradient.init(colors: [NSColor.gray,NSColor.black,NSColor.darkGray,NSColor.black], atLocations: [0.0,0.50,0.85,1.0], colorSpace: NSColorSpace.sRGB)
        
        g?.draw(in: self.bounds, angle: 90.0)
    
        lineDash.display(inRect: self.bounds, isHorizontal: true, strokeColor: NSColor.white, backgroundColor: .clear);

       
        let trianglePulldownPath : NSBezierPath = NSBezierPath.init();
        
        let fourthOfHeight : CGFloat = 0.25 * self.bounds.size.height
        
        trianglePulldownPath.move(to: NSMakePoint(self.bounds.width - 7, fourthOfHeight * 1.5))
        trianglePulldownPath.line(to: NSMakePoint(self.bounds.width - 12, fourthOfHeight * 2.25 ))
        trianglePulldownPath.line(to: NSMakePoint(self.bounds.width - 17, fourthOfHeight * 1.5))
        
        trianglePulldownPath.lineWidth = 3.0;
        NSColor.white.setStroke();
        trianglePulldownPath.stroke();
        
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true;
    }
    
    /*
    var trackingArea = NSTrackingArea();
    override func viewDidMoveToWindow() {
        
        // for mouseMoved events
        self.window?.acceptsMouseMovedEvents = true
        
        
        // for mouseEntered and Exited events
        let options = NSTrackingArea.Options.mouseEnteredAndExited.rawValue |
            NSTrackingArea.Options.activeAlways.rawValue;
        
        trackingArea = NSTrackingArea(rect: self.bounds, options: NSTrackingArea.Options(rawValue: options), owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }*/
    
    
    override func mouseDown(with event: NSEvent)
    {
        
    }
 
    override func mouseUp(with event: NSEvent)
    {
        if let menu = self.enclosingMenuItem?.menu
        {
            menu.cancelTracking();
            menu.performActionForItem(at: menu.index(of: self.enclosingMenuItem!))
        }
    }

    
    override func mouseEntered(with event: NSEvent)
    {
        
    }
    
    override func mouseExited(with event: NSEvent) {
        
    }
    
    // for keydown
    override var acceptsFirstResponder: Bool { return true }
    
    /*
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited,.mouseMoved],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
    */
    
}



struct LineDash : Equatable {
    var count : Int = 0
    var pattern : [CGFloat] = Array(repeatElement(0.0, count: 10))
    var phase : CGFloat = 0.0
    
    func patternSVGStringRepresentation() ->String
    {
        if(pattern.isEmpty)
        {
            return ""
        }
        
        var s = ""
        
        for p in pattern
        {
            s.append("\(Int(p)),")
        }
        
        s = String(s.dropLast())
        
        return s;
        
    }
    
    func patternStringRepresentation() ->String
    {
        if(pattern.isEmpty)
        {
            return "no dash"
        }
    
        let patternI : [ Int] = pattern.map { Int($0)}
        
        var s = "\(patternI)"
        s = String(s.dropFirst())
        s = String(s.dropLast())
        s = s.replacingOccurrences(of: ", ", with: "-")
        return s
    }
    
    init(dashArray:[CGFloat])
    {
        self.count = dashArray.count
        if(count == 0)
        {
            pattern = [];
            phase = 0;
        }
        else
        {
            count = dashArray.count;
            pattern = dashArray;
            phase = 0;
        }
    
    
    }

    
    init(count:Int,pattern:[CGFloat],phase:CGFloat) {
        self.count = count;
        self.pattern = pattern;
        self.phase = phase;
    }
    
    func lineDashMenuItemView() -> LineDashMenuItemView
    {
        return LineDashMenuItemView.init(lineDash: self);
    
    }
    
    func applyLineDashToBezierPath( path : inout NSBezierPath)
    {
        path.setLineDash(self.pattern, count: self.count, phase: self.phase)
    }
    
    func display(inRect:NSRect, isHorizontal:Bool, strokeColor: NSColor, backgroundColor: NSColor)
    {
        var p : NSBezierPath = NSBezierPath();
        
        
        backgroundColor.setFill()
        inRect.fill();
        
        strokeColor.setStroke()

        p.move(to: NSPoint(x: NSMinX(inRect), y: NSMidY(inRect)))
        p.line(to: NSPoint(x: NSMaxX(inRect), y: NSMidY(inRect)));
        
        self.applyLineDashToBezierPath(path: &p)

        
        p.stroke()
        
    }
    
}

class NCTClickableBox : NSBox
{
    @IBOutlet var targetForAction : AnyObject?
    @IBInspectable var selectorString : NSString = "";
    
    override func mouseDown(with event: NSEvent)
    {
        if((targetForAction != nil) && (selectorString != ""))
        {
            if (targetForAction!.responds(to: NSSelectorFromString(selectorString as String) ))
            {
                targetForAction?.performSelector(inBackground: NSSelectorFromString(selectorString as String), with: self)
            }
        }
    
    }
    
    
}

class NCTSwitch : NSButton
{
    var rightMargin  : CGFloat = 0;
    
    override func draw(_ dirtyRect: NSRect)
    {
        var b = self.bounds.insetBy(dx: 2, dy: 2);
        
        b.size.width -= rightMargin;
        
        NSColor.darkGray.setFill()
        b.fill();
        
        
        var buttonR = b;
        buttonR.size.width = b.width / 2;
        buttonR = buttonR.insetBy(dx: 0, dy: 1);

        if(self.state == .on)
        {
            buttonR.origin.x = buttonR.size.width + 2
            NSColor.green.setFill()
        }
        else if(self.state == .off)
        {
            buttonR.origin.x = 2
            NSColor.red.setFill()
        }
        
        
        buttonR.fill();
        
        
        NSColor.lightGray.setFill()
        b.frame();
    }
    
    

}

/*
class NCTDataTableRow : NSObject
{

}

class NCTDataTableView: NSView
{
    var rows : AnyObject
    var selectedIndex : Int = 0;

    func reloadData()
    {
    
        self.needsDisplay = true;
    }

    override func awakeFromNib() {
        reloadData()
    }


}*/
