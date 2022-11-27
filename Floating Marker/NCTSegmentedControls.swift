//
//  NCTSegmentedControls.swift
//  Floating Marker
//
//  Created by John Pratt on 1/15/21.
//

import Cocoa


@IBDesignable class NCTSegmentedControl: NSControl
{
    @IBOutlet var segmentPropertyDelegate : PaletteSegmentedControlSegmentPropertyDelegate?
    @IBOutlet var keyEventDelegate : NCTKeyEventDelegate?
    @IBInspectable var fontPostScriptName : String = "SFProDisplay-Thin"
    @IBInspectable var fontColor : NSColor = .lightGray
    @IBInspectable var fontColorSelected : NSColor = .white
    @IBInspectable var shadowOffsetWidth : CGFloat = 1
    @IBInspectable var shadowOffsetHeight : CGFloat = -2
    @IBInspectable var shadowBlurRadius : CGFloat = 2;
    
    @IBInspectable var secondGradient : Bool = false;
    @IBInspectable var useGreenSelectionOutline : Bool = false;
    
    var selectedSegment = 0
    {
        didSet
        {
            selectedSegment.formClamp(to: 0...self.segmentLabels.count)
            self.segmentPropertyDelegate?.selectedSegmentDidChange(control: self, segmentIndex: selectedSegment)
          //   self.sendAction(self.action, to: self.target)

            self.needsDisplay = true;
        }
        
    }
    

    @IBInspectable var usesDefaultBackground : Bool = false;
    @IBInspectable var showDebug : Bool = false;
    //var highlightColor : NSColor = NSColor.green.blended(withFraction: <#T##CGFloat#>, of: <#T##NSColor#>)
    
    @IBInspectable var spacing : CGFloat = 8;
    
    // need a new data type: switch
    
    @IBInspectable var cellBackgroundColor : NSColor = NSColor.init(calibratedWhite: 0.3, alpha: 1.0);
    
    
    @IBInspectable var cellStrokeColor : NSColor = NSColor.black;
    @IBInspectable var cellCornerRadius : CGFloat = 3.0;
    @IBInspectable var cellFontFactorForHeight : CGFloat = 0.55;
    @IBInspectable var cellFontYOffset : CGFloat = 2.0;
    @IBInspectable var xRectInsetDelta : CGFloat = 0.0;

    // not a segmented control with selected, but instead a series of buttons
    // side by side:
    @IBInspectable var isSequenceOfMomentaryButtons : Bool = false;
    @IBInspectable var actsAsChooserAccessory : Bool = false;
    @IBInspectable var actsAsNonDiamondSequence : Bool = false;
    
    
    // Note that the documentation is incorrect for the integer value for NSTextAlignment.
    // Center is 2, not 1.
    @IBInspectable var textAlignmentInt : Int = NSTextAlignment.center.rawValue;
    
    @IBInspectable var segmentLabelsString : String = "~,1,2,3,4,5,6,7,8,9,0"
    @IBInspectable var segmentImagesString : String = ""
    var segmentImagesLabels : [String]
    {
        get{ return segmentImagesString.components(separatedBy: ",")}
    }
    

    @IBInspectable var segmentLabels : [String]
    {
        get
        {
            return segmentLabelsString.components(separatedBy: ",")
        }
        
        set
        {
            segmentLabelsString = newValue.joined(separator: ",")
            
            if(gridLayout)
            {
                if(selectedSegment > (columns))
                {
                    selectedSegment = (columns - 1)
                }
            }
        }
    }
    
    func setSegmentLabelAtIndex(label: String, index:Int)
    {
        guard (index <= (segmentLabels.count - 1)) else {
            return
        }

        var segLbls = segmentLabels;
        
        segLbls[index] = label;
        segmentLabels = segLbls;
        

    }

    var currentSegmentLabelString : String
    {
        get
        {
            if(selectedSegment < segmentLabels.count)
            {
                return segmentLabels[selectedSegment]
            }
            else
            {
                return ""
            }
        }
    }
 
    var segmentCount : Int
    {
        return self.segmentLabels.count;
    }
    
    
    var insetBounds : NSRect
    {
        get{
            return self.bounds.insetBy(dx: 2, dy: 2)
        
        }
    }

    var rectWidth : CGFloat
    {
        get{
        
            let segCountCGFloat = CGFloat(segmentLabels.count);
            let subtracted = (segCountCGFloat * spacing) - spacing;
        
            return (self.insetBounds.width - subtracted) / segCountCGFloat;
        }
    }
    


    var fullRectWithSpacingWidth : CGFloat
    {
        get{
        
            return rectWidth + spacing;
        }
    }
    
    var onOffSwitchBool : Bool
    {
        get{ return selectedSegment == 0 ? true : false }
    }
    
    func setOnOffFromBool(bool:Bool)
    {
        selectedSegment = bool ? 0 : 1
    }
    
    
    // MARK: GRID LAYOUT
        // wraps segments into grid.
    @IBInspectable var gridLayout : Bool = false;
    @IBInspectable var rows : Int = 1;
    @IBInspectable var columns : Int = 1;
    

    var selectedSegment2D : (row: Int, column: Int)
    {
        get
        {
                let selectedRow = self.selectedSegment / self.rows
                let selectedColumn = self.selectedSegment / self.columns
                
                
                return (selectedColumn,selectedRow)
        }
    }
    
     //var rowsRestrict : Int = 1;
    // var columnsRestrict : Int = 1;

    var gridLayoutRectWidth : CGFloat
    {
        get{
            //  let rowCountCGFloat = CGFloat(rows);
            let columnCountCGFloat = CGFloat(columns);

            let subtractedSpacingMultiplied = (columnCountCGFloat * spacing) - spacing;
            
            return (self.insetBounds.width - subtractedSpacingMultiplied) / columnCountCGFloat;
        }
    }

    var gridLayoutRectHeight : CGFloat
    {
        get{
                   //     let colCountCGFloat = CGFloat(columns);
                        let rowCountCGFloat = CGFloat(rows);

            let subtracted = (rowCountCGFloat * spacing) - spacing;
            
            return (self.insetBounds.height - subtracted) / rowCountCGFloat;
        }
    }
    
    var mouseOverGridRow : Int = 0;
    var mouseOverGridColumn : Int = 0;
    
    
    
    override func draw(_ dirtyRect: NSRect)
    {
        
        //        NSColor.white.setStroke()
        //        self.bounds.frame(withWidth: 1, using: NSCompositingOperation.sourceOver);
        
        // MARK: is grid layout
        if(gridLayout)
        {
            if(showDebug)
            {         NSColor.red.setFill()
                bounds.frame()
                
                NSColor.green.setFill()
                insetBounds.frame()
          
                
            }
            
            var counter : Int = 0;
            for row in 0..<rows
            {
                
                for column in 0..<columns
                {
                   // let x = (CGFloat(c) * spacing) + (CGFloat(c) * gridLayoutRectWidth) + insetBounds.minX;
                    //let y = (CGFloat(r) * spacing) + (CGFloat(r) * gridLayoutRectHeight) + insetBounds.minY;
                    
                    let x = (CGFloat(column) * spacing) + CGFloat(column) * gridLayoutRectWidth + insetBounds.minX;
          
                    let y = (CGFloat(row) * spacing) + CGFloat(row) * gridLayoutRectHeight + insetBounds.minY;
          
          
                    let rect = NSMakeRect(x, y, gridLayoutRectWidth, gridLayoutRectHeight)
                    
                    
                    
                    
                    if((segmentPropertyDelegate == nil)  || (self.usesDefaultBackground) )
                    {
                        
                        cellBackgroundColor.setFill()
                        cellStrokeColor.setStroke();
                        
                        let isSelectedSegment = ((selectedSegment == counter) && (isSequenceOfMomentaryButtons == false) && (actsAsNonDiamondSequence == false));
                        
                        if(isSelectedSegment)
                        {
                            
                            cellBackgroundColor.blended(withFraction: 0.4, of: NSColor.white)?.setFill()
                        }
                        
                        if(actsAsChooserAccessory)
                        {
                            let r = rect.insetBy(dx: 1, dy: 0)

                            if(isSelectedSegment)
                            {
                                NSColor.black.setFill()
                                r.fill()
                                
                                cellBackgroundColor.setFill()
                                let p = NSBezierPath();
                                p.move(to: r.bottomLeft())
                                p.line(to: r.bottomRight())
                                p.line(to: r.topMiddle())
                                p.close()
                                
                                NSColor.green.setFill();

                                p.fill();
                                
                                if(useGreenSelectionOutline)
                                {
                                    NSColor.green.setFill();
                                    p.fill();

                                    r.frame();
                                }
                                counter += 1
                                continue;
                            }
                            else
                            {
                                NSColor.black.setFill()
                                r.fill();
                                counter += 1
                                continue;
                            }
                                
                        }
                        
                        
                        if(mouseIsInside)
                        {
                            if((column == mouseOverGridColumn) && (row == mouseOverGridRow))
                            {
                          //      cellBackgroundColor.blended(withFraction: 0.2, of: NSColor.white)?.setFill()
                                
                                NSColor.green.blended(withFraction: 0.5, of: NSColor.white)?.setStroke();
                                //cellStrokeHighlightColor.setStroke();
                            }
                        }
                        
                        let p = NSBezierPath();
                        if(isSequenceOfMomentaryButtons == false)
                        {
                            p.appendRoundedRect(rect, xRadius: cellCornerRadius, yRadius: cellCornerRadius)
                        }
                        else
                        {
                            p.move(to: rect.middleLeft())
                            p.line(to: rect.topMiddle())
                            p.line(to: rect.middleRight())
                            p.line(to: rect.bottomMiddle())
                            p.close();
                        }
                        p.fill();
                        
                       
                        
                        p.stroke();
                        
                       let grad = NSGradient.init(colors: [NSColor.clear,NSColor.init(calibratedWhite: 1.0, alpha: 0.2),NSColor.clear,NSColor.init(calibratedWhite: 0.1, alpha: 0.4)], atLocations: [0,0.0,0.8,0.9], colorSpace:
                        NSColorSpace.sRGB)
                        grad?.draw(in: p, angle: isFlipped ? 90 : 270 )
                        
                        if(secondGradient)
                        {
                            let grad2 = NSGradient.init(colors: [NSColor.init(calibratedWhite: 0.1, alpha: 0.4),NSColor.clear,NSColor.clear,NSColor.init(calibratedWhite: 0.1, alpha: 0.4)], atLocations: [0.0,0.1,0.9,1.0], colorSpace:
                        NSColorSpace.sRGB)
                            grad2?.draw(in: p, angle: isFlipped ? 0 : 180 )
                        
                        
                        }
                        
                        
                        
                        /*
                        guard counter < (segmentLabels.count) else {
                            return
                        }*/
                        
                        let label = segmentLabels[counter];
                        
                        let labelRectHeight = (rect.height > 12) ? (3 + rect.height * cellFontFactorForHeight) : rect.height
                        
                        var labelRect = NSRect(x: 0, y: 0, width: rect.width - 3, height: labelRectHeight ).centerOnPoint(rect.centroid())
                        
                        if(textAlignmentInt == 0)
                        {
                        
                            labelRect = labelRect.insetBy(dx: (0.5 * labelRect.height) - xRectInsetDelta, dy: 0)
                        }
                        else if(textAlignmentInt == 2)
                        {
                           labelRect = labelRect.insetBy(dx: (0.5 * labelRect.height) - xRectInsetDelta, dy: 0)
                        }
                        
//                        print(NSTextAlignment.init(rawValue: textAlignmentInt).debugDescription)
                        
                       // let txtAlignment = NSTextAlignment.init(rawValue: 1)
                        
                        
                        let txtAlignment = NSTextAlignment(rawValue: textAlignmentInt)
                        
                         NSGraphicsContext.current?.saveGraphicsState()
                let shadowForSlotNumber = NSShadow()
                shadowForSlotNumber.shadowBlurRadius = self.shadowBlurRadius
                shadowForSlotNumber.shadowOffset = NSSize(width: shadowOffsetWidth, height: shadowOffsetHeight)
                shadowForSlotNumber.shadowColor = NSColor.darkGray
                
                shadowForSlotNumber.set()
                
                
                        if(self.segmentImagesString.isEmpty == false)
                        {
                            let sImagesLabels = segmentImagesLabels;
                            if(sImagesLabels.count == self.segmentLabels.count)
                            {
                                let imageName = sImagesLabels[counter]
                                if let img = NSImage.init(named: imageName)
                                {
                                    img.draw(in: labelRect.insetBy(dx: 1, dy: 1))
                                
                                }
                            
                            }
                        
                        }
                      
                    // MARK: draw label
                    
                    label.drawStringInsideRectWithPostScriptFont(postScriptName: self.fontPostScriptName, fontSize: rect.height * cellFontFactorForHeight, textAlignment: txtAlignment ?? .left, fontForegroundColor: ((isSelectedSegment) ? fontColorSelected : fontColor), rect: labelRect.offsetBy(dx:0, dy:cellFontYOffset));
                
                
                     

                
                        NSGraphicsContext.current?.restoreGraphicsState()
                        
                      
                        
                         if(showDebug)
                        {
                        NSColor.white.setFill()
                        rect.frame()
                        }
                        
                        if(useGreenSelectionOutline)
                        {
                            if(isSelectedSegment)
                            {
                            NSColor.green.setStroke()
                            p.stroke();
                            }
                        }
                        
                    }
                    
                    if(segmentPropertyDelegate != nil)
                    {
                        if(counter < segmentLabels.count)
                        {
                            let label = segmentLabels[counter];
                            
                            segmentPropertyDelegate?.drawPaletteSegmentPropertyBackgroundInsideRect(control:self, rect:rect, segmentIndex: counter, segmentLabel:label,  isSelected: (counter == selectedSegment), isHighlighted: mouseIsInside)
                            
                            
                            segmentPropertyDelegate?.drawPaletteSegmentPropertyInsideRect(control:self, rect:rect, segmentIndex: counter, segmentLabel:label,  isSelected: (counter == selectedSegment), isHighlighted: mouseIsInside)
                        }
                        
                    }
                    
                    
                    
                    
                    /*
                     debug area
                     // let s = "\(counter) (\(r),\(c))"
                     // s.drawStringInsideRectWithMenlo(fontSize: 10, textAlignment: .left, fontForegroundColor: .white, rect: rect);
                     
                     // counter is the index for the array
                     let s = "\(counter)"
                     s.drawStringInsideRectWithMenlo(fontSize: 0.5 * rect.height, textAlignment: .left, fontForegroundColor: .white, rect: rect.insetBy(dx: 3, dy: 3));
                     */
                    
                    
                    
                    
                    
                    counter += 1;
                    
                    
                }
                
            }
            
            if(self.mouseIsInside)
            {
                if(isSequenceOfMomentaryButtons == false)
                {
                    NSColor.green.setStroke()
                    let p = NSBezierPath();
                    p.appendRoundedRect(self.mouseOverRect, xRadius: cellCornerRadius, yRadius: cellCornerRadius)
                    p.stroke()
                }
                
            }
            
            if(self.showDebug)
            {
                NSColor.blue.setFill()
                mMGLRect.fill()
            }
            


        }
        // MARK: is not grid layout
        else
        {
            
            

            for (segIndex, segmentLabel) in segmentLabels.enumerated()
            {
                let segIndexCGFloat = CGFloat(segIndex);
                
                
                let xVal = segIndexCGFloat * fullRectWithSpacingWidth;
                
                let currentRect : NSRect = NSMakeRect(xVal + insetBounds.origin.x, insetBounds.origin.y, rectWidth, insetBounds.size.height)
                
                
                
                segmentPropertyDelegate?.drawPaletteSegmentPropertyInsideRect(control:self, rect:currentRect, segmentIndex: segIndex, segmentLabel:segmentLabel,  isSelected: (segIndex == selectedSegment), isHighlighted: mouseIsInside)
                
                
                
                
                NSColor.darkGray.setStroke()
                
                let p2 = NSBezierPath();
                p2.lineWidth = 1
                if(segIndex == 0)
                {
                    p2.appendRect(currentRect)
                    
                }
                else
                {
                    p2.appendRoundedRect(currentRect, xRadius: 4, yRadius: 4)
                }
                p2.stroke()
                
                
                if(showDebug)
                {
                    NSColor.blue.setFill()
                    currentRect.frame()
                }
                
            }// END FOR LOOP
            
            
            
            
            NSColor.green.setStroke()
            
            let p = NSBezierPath();
            
            if(self.selectedSegment == 0)
            {
                p.appendRect(rectForSelectedSegment)
                
            }
            else
            {
                p.appendRoundedRect(self.rectForSelectedSegment, xRadius: 3, yRadius: 3)
            }
            p.stroke()
            
            
            
            if(self.mouseIsInside)
            {
                NSColor.green.setStroke()
                
                
                let p = NSBezierPath();
                if(self.mouseOverSegment == 0)
                {
                    p.appendRect(mouseOverRect)
                    
                }
                else
                {
                    p.appendRoundedRect(self.mouseOverRect, xRadius: 3, yRadius: 3)
                }
                p.stroke()
                
                
            }
            
        }
        
        if(segmentPropertyDelegate != nil)
        {
            segmentPropertyDelegate?.drawOnTopOfSegmentedControl(control: self, bounds: self.bounds)
        }
        
    }// END draw:
    
     override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true;
    }
        
    var mouseIsInside : Bool = false;
    
    @IBInspectable var makeWindowKeyOnMouseEntered : Bool = false;
    override func mouseEntered(with event: NSEvent)
    {
        mouseIsInside = true;
        
        if(makeWindowKeyOnMouseEntered)
        {
            self.window!.makeKey();
        }
        
        self.window!.makeFirstResponder(self);
        self.needsDisplay = true;
        
    }
    
    override func mouseExited(with event: NSEvent)
    {
        mouseIsInside = false;
        self.needsDisplay = true;
    }
    
    var mouseOverSegment : CGFloat = 0;
    var mouseOverRect : NSRect = .zero;
    
    func rectForSegment(_ segment : Int) -> NSRect
    {
        return NSMakeRect(insetBounds.origin.x + (CGFloat(segment) * fullRectWithSpacingWidth), insetBounds.origin.y, rectWidth, insetBounds.height);
    }
    
    var rectForSelectedSegment : NSRect
    {
        get{ return self.rectForSegment(self.selectedSegment)}
    }
    
    
    var mMGLRect : NSRect = .zero;
    
    override func mouseMoved(with event: NSEvent)
    {
        guard self.window != nil else {
            print("self.window in NCTSegmentedControl is nil")
            return;
        }
   
        guard event.window == self.window else {
            return
        }
   
        let pointInControlView = self.convert(event.locationInWindow, from: nil);

        
        if(gridLayout)
        {
            
            /*
            guard (NSPointInRect(pointInControlView, insetBounds.insetBy(dx: 5, dy: 5))) else {
                return;
            }*/
            
            
            
            var column = floor(min((insetBounds.origin.x + pointInControlView.x),insetBounds.maxX - spacing) / (gridLayoutRectWidth + max(insetBounds.origin.x,spacing)))
            var row = floor(min((insetBounds.origin.y + pointInControlView.y),insetBounds.maxY - spacing) / (gridLayoutRectHeight + max(insetBounds.origin.y,spacing)))

            row.formClamp(to: 0...CGFloat(rows - 1))
            column.formClamp(to: 0...CGFloat(columns - 1))

            let x2 = (CGFloat(column) * spacing) + CGFloat(column) * gridLayoutRectWidth + insetBounds.minX;
            let y2 = (CGFloat(row) * spacing) + CGFloat(row) * gridLayoutRectHeight + insetBounds.minY;
                
            if(self.showDebug)
            {
                mMGLRect = NSMakeRect(x2, y2, gridLayoutRectWidth, gridLayoutRectHeight)
            }
            

            //  Swift.print("\(row),\(column)")
            
            
            mouseOverGridRow = Int(row);
            mouseOverGridColumn = Int(column);
            
            
            let x = (CGFloat(column) * spacing) + CGFloat(column) * gridLayoutRectWidth + insetBounds.minX;
            let y = (CGFloat(row) * spacing) + CGFloat(row) * gridLayoutRectHeight + insetBounds.minY;
                
            mouseOverRect = NSMakeRect(x, y, gridLayoutRectWidth, gridLayoutRectHeight)
            
            
            // 2d to 1d
            let oneDimensionalArrayIndex = column * CGFloat(rows) + row;
            mouseOverSegment = oneDimensionalArrayIndex
            
            
            
        }
        else
        {
            mouseOverSegment = floor(
            
            min((insetBounds.origin.x + pointInControlView.x),insetBounds.maxX - spacing) / fullRectWithSpacingWidth
            
            );
            
            
            mouseOverRect = NSMakeRect(insetBounds.origin.x + (mouseOverSegment * fullRectWithSpacingWidth), insetBounds.origin.y, rectWidth, insetBounds.height);
        }
        
        self.needsDisplay = true;
   
        
    }
    /*
    override func mouseMoved(with event: NSEvent)
    {
   
        var pointInControlView = self.convert(event.locationInWindow, from: nil);
        
        if(gridLayout)
        {
            
            
            guard (NSPointInRect(pointInControlView, insetBounds)) else {
                return;
            }
            
            
            /*
            let mappedX = CGFloat(mapy(n: pointInControlView.x.double(), start1: bounds.minX.double(), stop1: bounds.maxX.double(), start2: insetBounds.minX.double(), stop2: insetBounds.maxX.double()))
            
            let mappedY = CGFloat(mapy(n: pointInControlView.y.double(), start1: bounds.minY.double(), stop1: bounds.maxY.double(), start2: insetBounds.minY.double(), stop2: insetBounds.maxY.double()))
            */

            let widthDividedByColumnCount = insetBounds.width / CGFloat(columns)
            let heightDividedByRowCount = insetBounds.height / CGFloat(rows)
            
            let numberOfSpacersAcrossWidth = columns - 1
            let numberOfSpacersAcrossHeight = rows - 1
            
            pointInControlView.x -= insetBounds.origin.x
            pointInControlView.y -= insetBounds.origin.y
            
            let column = floor(pointInControlView.x / widthDividedByColumnCount)
            let row = floor(pointInControlView.y / heightDividedByRowCount)
            
//            let row = floor( mappedY / ceil(gridLayoutRectHeight + spacing) )
//            let column = floor( mappedX / ceil(gridLayoutRectWidth + spacing) )
            
            
            //var row = floor(min((insetBounds.origin.x + pointInControlView.x),insetBounds.maxX - spacing) / (gridLayoutRectWidth + max(insetBounds.origin.x,spacing)))
            //var column = floor(min((insetBounds.origin.y + pointInControlView.y),insetBounds.maxY - spacing) / (gridLayoutRectHeight + max(insetBounds.origin.y,spacing)))
            

            let x2RectOriginDebug = row * CGFloat(gridLayoutRectWidth)// mappedX.truncatingRemainder(dividingBy: CGFloat(gridLayoutRectWidth + spacing))
            let y2RectOriginDebug = column * CGFloat(gridLayoutRectWidth) // mappedY.truncatingRemainder(dividingBy: CGFloat(gridLayoutRectHeight + spacing))

            var gridCellX :CGFloat = 0;
            var gridCellY :CGFloat = 0;
            var gridCellWidth : CGFloat = 0;
            
            if(column == 0)
            {
                gridCellWidth = widthDividedByColumnCount - (0.5 * spacing)
                gridCellX = insetBounds.minX
            }
            else if(column == (CGFloat(columns) - 1))
            {
                gridCellWidth = widthDividedByColumnCount - (0.5 * spacing)
                gridCellX = insetBounds.maxX - gridCellWidth
            }
            else
            {
            
            }

           // let x2 = (CGFloat(row) * spacing) + CGFloat(row) * (gridLayoutRectWidth + spacing);
           // let y2 = (CGFloat(column) * spacing) + CGFloat(column) * (gridLayoutRectHeight + spacing);
                
            if(self.showDebug)
            {
                
                mMGLRect = NSMakeRect(x2RectOriginDebug, y2RectOriginDebug, gridLayoutRectWidth, gridLayoutRectHeight)
            }
            

//            Swift.print("\(row),\(column)")
            
            
            mouseOverGridRow = Int(row);
            mouseOverGridColumn = Int(column);
            
            
            let x = (CGFloat(row) * spacing) + CGFloat(row) * gridLayoutRectWidth + insetBounds.minX;
            let y = (CGFloat(column) * spacing) + CGFloat(column) * gridLayoutRectHeight + insetBounds.minY;
                
            mouseOverRect = NSMakeRect(x, y, gridLayoutRectWidth, gridLayoutRectHeight)
            
            
            
            let oneDimensionalArrayIndex = column * CGFloat(columns) + row;
            mouseOverSegment = oneDimensionalArrayIndex
            
            
            
        }
        else
        {
            mouseOverSegment = floor(
            
            min((insetBounds.origin.x + pointInControlView.x),insetBounds.maxX - spacing) / fullRectWithSpacingWidth
            
            );
            
            
            mouseOverRect = NSMakeRect(insetBounds.origin.x + (mouseOverSegment * fullRectWithSpacingWidth), insetBounds.origin.y, rectWidth, insetBounds.height);
        }
        
        self.needsDisplay = true;
   
        
    }
    */
    
    override func keyDown(with event: NSEvent)
    {
   
    
        switch Int(event.keyCode) {
   
        case tabKey:
          let point : NSPoint = self.window!.mouseLocationOutsideOfEventStream
            
             let mouseDownEvent : NSEvent = NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: NSEvent.ModifierFlags(rawValue: 0), timestamp: ProcessInfo().systemUptime, windowNumber: self.window!.windowNumber, context: nil, eventNumber: 200, clickCount: 1, pressure: 1.0)!
                    
            self.mouseDown(with: mouseDownEvent)
            /*
        case tildeKey:
            selectSegmentAndSendAction(0)
        case oneKey:
            selectSegmentAndSendAction(1)
        case twoKey:
            selectSegmentAndSendAction(2)
        case threeKey:
            selectSegmentAndSendAction(3)
            
            case fourKey:
            selectSegmentAndSendAction(4)
            
            case fiveKey:
            selectSegmentAndSendAction(5)
            
            case sixKey:
            selectSegmentAndSendAction(6)
            
            case sevenKey:
            selectSegmentAndSendAction(7)
            case eightKey:
            selectSegmentAndSendAction(8)
            case nineKey:
            selectSegmentAndSendAction(9)
            case zeroKey:
            selectSegmentAndSendAction(10)*/
        default:
            
            if(keyEventDelegate != nil)
            {
                keyEventDelegate?.keyDown(with: event)
                return
            }
            break;
        }


    }
    
    override func mouseDown(with event: NSEvent)
    {
        if(isSequenceOfMomentaryButtons)
        {

            guard Int(mouseOverSegment) < segmentLabels.count else {
                return;
            }
            
            let mouseOverSegmentLabelString = self.segmentLabels[Int(mouseOverSegment)]
            self.stringValue = mouseOverSegmentLabelString
            
            if let doubleValueForSelf = Double(mouseOverSegmentLabelString)
            {
                self.doubleValue = doubleValueForSelf;
            }
            
            self.sendAction(self.action, to: self.target)
            
            
        }
        else
        {
            selectSegmentAndSendAction(Int(mouseOverSegment))
        }
    }
    
    func selectSegmentAndSendAction( _ segment : Int)
    {
        self.setSelectedSegmentIndex(segment)
        self.sendAction(self.action, to: self.target)
    }
    
    func setSelectedSegmentIndex(_ index : Int)
    {
        self.selectedSegment = index;
    }
        
    var trackingArea : NSTrackingArea = NSTrackingArea();
    
    override func updateTrackingAreas()
    {
        
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        

        
    }
    
    @IBInspectable var flippedCustom : Bool = false;
    
    override var isFlipped: Bool
    {
        return flippedCustom;
    }
    
    override func awakeFromNib() {
         self.wantsLayer = true;
        /*
        let shadow = NSShadow();
        shadow.shadowBlurRadius = 3;
        self.shadow = shadow;
        
        //self.layer?.backgroundColor = NSColor.red.cgColor
        self.layer?.cornerRadius = 0
        self.layer?.shadowOpacity = 0.8;
        
        self.layer?.shadowColor = NSColor.darkGray.cgColor
        self.layer?.shadowOffset = NSMakeSize(2, -2)
        self.layer?.shadowRadius = 2;
        */
    }
    

}// END

@objc protocol PaletteSegmentedControlSegmentPropertyDelegate {
    func drawPaletteSegmentPropertyInsideRect( control: NCTSegmentedControl, rect : NSRect, segmentIndex : Int, segmentLabel: String, isSelected: Bool, isHighlighted: Bool)
    
    func drawPaletteSegmentPropertyBackgroundInsideRect(control: NCTSegmentedControl, rect : NSRect, segmentIndex : Int, segmentLabel: String, isSelected: Bool, isHighlighted: Bool)
    
    func drawOnTopOfSegmentedControl(control: NCTSegmentedControl, bounds: NSRect)
   
        
func selectedSegmentDidChange(control: NSControl, segmentIndex: Int)
}

@objc protocol NCTKeyEventDelegate {
    func keyDown(with event: NSEvent)
    
}
