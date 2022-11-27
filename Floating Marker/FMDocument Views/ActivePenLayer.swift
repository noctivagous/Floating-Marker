//
//  ActivePenLayer.swift
//  Floating Marker
//
//  Created by John Pratt on 1/10/21.
//

import Cocoa
import PencilKit
class ActivePenLayer: NSView
{
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
        reconstructCursorBezierPath()
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
        
    }
    
    var drawingPage : DrawingPage?
    
    var cursorBezierPath : NSBezierPath = NSBezierPath();
    
    func mousePointInLayerOutsideOfEventStream() -> NSPoint
    {
        guard self.window != nil else {
            return .zero;
        }
    
        let pointInWindow = self.window!.mouseLocationOutsideOfEventStream
        
        return self.convert(pointInWindow, from: nil)
        
    }
    
    func adjustCurrentPointDuringScroll()
    {
        
        currentPoint = mousePointInLayerOutsideOfEventStream();

    }
    
    var currentPoint : NSPoint = .zero
    {
        didSet{
            
            if(lineWorkInteractionEntity?.lineWorkEntityMode == .isInLinearDrawing)
            {
                if(inkAndLineSettingsManager!.fmInk.brushTip.isUniform)
                {
                  self.reconstructCursorBezierPath()
                }
                else
                {
                    self.translateCursorBezierPath()
                }
            }
            else
            {
            
                DispatchQueue.main.async
                {
                    self.translateCursorBezierPath()
                }
            }
            
        }
        
    }
    

    var cursorUpdateRect : NSRect = NSRect.zero
    func translateCursorBezierPath()
    {
        if(cursorBezierPath.isEmpty)
        {
            reconstructCursorBezierPath()
        }
        else
        {
        let cBounds = cursorBezierPath.bounds
     


        var a = AffineTransform();
        a.translate(x: currentPoint.x - cBounds.centroid().x, y: currentPoint.y - cBounds.centroid().y)
        cursorBezierPath.transform(using: a)
        
        let eB = cursorBezierPath.extendedBezierPathBounds;
        self.setNeedsDisplay(eB.unionProtectFromZeroRect(cursorUpdateRect).insetBy(dx: -5, dy: -5))
        
        cursorUpdateRect = cursorBezierPath.extendedBezierPathBounds.insetBy(dx: -5, dy: -5)
        
        }
    }
    
    func redrawCursorBezierPath()
    {
        self.setNeedsDisplay(cursorUpdateRect)
    }

    func reconstructCursorBezierPath()
    {
        guard inkAndLineSettingsManager != nil else {
            return
        }

        let heightFactor : CGFloat =  inkAndLineSettingsManager!.heightFactor
        
        
        
        if(inkAndLineSettingsManager!.fmInk.brushTip.isUniform)
        {
        
            if(cursorBezierPath.isEmpty == false)
            {
                let oldRect = cursorBezierPath.extendedBezierPathBounds.insetBy(dx: -5.0, dy: -5.0)
                cursorBezierPath.removeAllPoints();
                
                /*
                 // FOR
                 // ADJUSTING A SQUARE BRUSH TIP THAT ALIGNS WITH PATH ANGLE:
                 var angle : CGFloat = 0;
                 
                 if(lineWorkInteractionEntity!.lineWorkEntityMode == .isInLinearDrawing)
                 {
                 angle = NSBezierPath.lineAngleDegreesFrom(point1: lineWorkInteractionEntity!.currentFMStroke.liveSecondToLastPenPoint, point2: lineWorkInteractionEntity!.currentFMStroke.liveLastPenPoint)
                 print("---")
                 print("\(lineWorkInteractionEntity!.currentFMStroke.lastPoint()) \(lineWorkInteractionEntity!.currentFMStroke.penultimatePoint())")
                 
                 }*/
                
                let p = NSBezierPath.init();
                let r = NSMakeRect(0, 0, inkAndLineSettingsManager!.currentBrushTipWidth, inkAndLineSettingsManager!.currentBrushTipWidth).centerOnPoint(currentPoint);
                p.appendOval(in: r)
                cursorBezierPath.append(p)
                
                // FOR ADJUSTING A SQUARE BRUSH TIP THAT ALIGNS WITH PATH ANGLE:
                // p.appendRect(r)
                // cursorBezierPath.appendPathRotatedAboutCenterPoint(path:p , angleDegrees: 360 - angle , centerPoint: currentPoint)
                cursorUpdateRect = cursorBezierPath.extendedBezierPathBounds;
                self.setNeedsDisplay(cursorUpdateRect.union(oldRect))
                
                
                return;
            }
            else
            {
                let p = NSBezierPath()
                
                let r = NSMakeRect(0, 0, inkAndLineSettingsManager!.currentBrushTipWidth, inkAndLineSettingsManager!.currentBrushTipWidth).centerOnPoint(currentPoint);
                
                p.appendOval(in: r)
                
                cursorBezierPath.append(p)
                
                let eB = cursorBezierPath.extendedBezierPathBounds;
                self.setNeedsDisplay(cursorUpdateRect.unionProtectFromZeroRect(eB.insetBy(dx: -5, dy: -5)))
            
                cursorUpdateRect = eB.insetBy(dx: -5, dy: -5)

            }
            
        }
        
        
        if(cursorBezierPath.isEmpty == false)
        {
            let oldRect = cursorBezierPath.extendedBezierPathBounds
            cursorBezierPath.removeAllPoints();
            let p = NSBezierPath()
            
            if(inkAndLineSettingsManager!.fmInk.brushTip == .ellipse)
            {
                p.appendOval(in: NSMakeRect(0, 0, inkAndLineSettingsManager!.currentBrushTipWidth, heightFactor * inkAndLineSettingsManager!.currentBrushTipWidth ).centerOnPoint(currentPoint))
                
            }
            else
            {
                p.appendRect(NSMakeRect(0, 0, inkAndLineSettingsManager!.currentBrushTipWidth, heightFactor * inkAndLineSettingsManager!.currentBrushTipWidth ).centerOnPoint(currentPoint))
            }
            
            cursorBezierPath.appendPathRotatedAboutCenterPoint(path:p , angleDegrees: rad2deg(inkAndLineSettingsManager?.azimuthRadians ?? 0)  , centerPoint: currentPoint)
            
            //cursorBezierPath.appendRotatedOvalAtCenterPoint(angleDegrees: inkAndLineSettingsManager?.azimuthDegrees ?? 0, centerPoint: currentPoint, width: inkAndLineSettingsManager?.currentBrushTipWidth ?? 30, height: heightFactor * (inkAndLineSettingsManager?.currentBrushTipWidth ?? 30))
            
           
             let eB = cursorBezierPath.extendedBezierPathBounds;
            self.setNeedsDisplay(cursorUpdateRect.union(eB.unionProtectFromZeroRect(oldRect).insetBy(dx: -5, dy: -5)))
            
            cursorUpdateRect = eB.unionProtectFromZeroRect(oldRect).insetBy(dx: -5, dy: -5)


        }
        else
        {
        
            cursorBezierPath.removeAllPoints();
           
            let p = NSBezierPath()
            
            if(inkAndLineSettingsManager!.fmInk.brushTip == .ellipse)
            {
                p.appendOval(in: NSMakeRect(0, 0, inkAndLineSettingsManager!.currentBrushTipWidth, heightFactor * inkAndLineSettingsManager!.currentBrushTipWidth ).centerOnPoint(currentPoint))
                
            }
            else
            {
                p.appendRect(NSMakeRect(0, 0, inkAndLineSettingsManager!.currentBrushTipWidth, heightFactor * inkAndLineSettingsManager!.currentBrushTipWidth ).centerOnPoint(currentPoint))
            }
            
            cursorBezierPath.appendPathRotatedAboutCenterPoint(path:p , angleDegrees: rad2deg(inkAndLineSettingsManager?.azimuthRadians ?? 0)  , centerPoint: currentPoint)
            
            
            cursorUpdateRect = cursorBezierPath.extendedBezierPathBounds
            
            self.setNeedsDisplay(cursorUpdateRect)
            
            

        }
        
        
        
    }
    
   
    
    
    func setCurrentInputDocumentToSelf()
    {
        if(self.window!.isMainWindow == false)
        {
            self.window?.becomeMain();
        }
    
    }
    
    var inputInteractionManager : InputInteractionManager?

    var inkAndLineSettingsManager : InkAndLineSettingsManager?
    var lineWorkInteractionEntity : LineWorkInteractionEntity?


    override func flagsChanged(with event: NSEvent) {
  
        inputInteractionManager?.flagsChangedFromActiveLayer(event: event);
        
    }
    

    override func keyDown(with event: NSEvent)
    {
        setCurrentInputDocumentToSelf()
        
        inputInteractionManager?.keyDown(with: event)
        
    }
    
    override func keyUp(with event: NSEvent)
    {
        setCurrentInputDocumentToSelf()
        
        inputInteractionManager?.keyUp(with: event)
        
    }
 
    override func mouseMoved(with event: NSEvent)
    {
       
        currentPoint = self.convert(event.locationInWindow, from: nil);

        inputInteractionManager?.mouseMoved(with: event)
        
        /*
        
        if((self.window! == NSApp.mainWindow) && (self.window!.firstResponder !== self))
        {
            self.window!.makeKey()
            self.window!.makeFirstResponder(self)
            self.resetCursorRects();
        }
        */
        
//        setCurrentInputDocumentToSelf()
        
        
        
    }
    
    override func mouseDown(with event: NSEvent)
    {
        
    
        setCurrentInputDocumentToSelf()
        // ----
        // inputInteractionManager --> lineWorkInteractionEntity -->
        // ----
        inputInteractionManager!.mouseDown(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        setCurrentInputDocumentToSelf()
        inputInteractionManager?.mouseUp(with: event)
    }
    
    override func mouseEntered(with event: NSEvent) {
        
        currentPoint = self.convert(event.locationInWindow, from: nil);
        
        if(self.window! == NSApp.mainWindow)
        {
            self.window!.makeKey()
            self.window!.makeFirstResponder(self)
//            self.resetCursorRects();
        }
  
        self.reconstructCursorBezierPath();
        
        
        inputInteractionManager?.mouseEntered(with: event)
    }
    
    override func mouseExited(with event: NSEvent)
    {
        inputInteractionManager?.mouseExited(with: event)
    }
    
    override func mouseDragged(with event: NSEvent)
    {
        inputInteractionManager?.mouseDragged(with: event)
    }
 
    var inCaptureDataState : Bool = false;
    override func draw(_ dirtyRect: NSRect)
    {
        
        if( !inCaptureDataState )
        {
            
            if(self.window != nil)
            {
                if(self.window!.isMainWindow)
                {
                    lineWorkInteractionEntity!.drawForActivePenLayer(self)
                    

                }
                
            
            }
            
            lineWorkInteractionEntity!.drawForActivePenLayerGuidelines()

            self.drawExportFrameIfVisible()
            
        }
        
    }
    
    func drawExportFrameIfVisible()
    {
    
        if(drawingPage!.drawingPageController!.exportFrameIsVisible)
        {
            let exportFrame = drawingPage!.drawingPageController!.exportFrame
            
            NSColor.black.withAlphaComponent(0.8).setFill();

         //   if( NSContainsRect(self.bounds, exportFrame) )
         //   {
                
                // LEFT
                if(exportFrame.minX > 0)
                {
                    var r1 : NSRect = .zero;
                    r1.origin.x = 0;
                    r1.size.width = exportFrame.minX;
                    r1.size.height = self.bounds.height;
                    r1.fill(using: NSCompositingOperation.sourceOver)
                }

                // RIGHT
                if(exportFrame.minY > 0)
                {
                
                    var r2 : NSRect = .zero;
                    r2.origin.x = 0;
                    r2.origin.y = 0;
                    r2.size.width = bounds.width;
                    r2.size.height =  exportFrame.minY;
                    r2.fill(using: NSCompositingOperation.sourceOver)
                }

                // BOTTOM
                if(exportFrame.maxX < self.bounds.maxX)
                {
                      
                    var r3 : NSRect = .zero;
                    r3.origin.x = exportFrame.maxX;
                    r3.origin.y = 0;
                    r3.size.width = self.bounds.width - exportFrame.width;
                    r3.size.height =  self.bounds.height
                    r3.fill(using: NSCompositingOperation.sourceOver)
                }
                
                
                if(exportFrame.maxY < self.bounds.maxY)
                {
                    var r4 : NSRect = .zero;
                    r4.origin.x = 0;
                    r4.origin.y = exportFrame.maxY;
                    r4.size.width = self.bounds.width
                    r4.size.height = self.bounds.height - exportFrame.height;
                    r4.fill(using: NSCompositingOperation.sourceOver)
          
                }
                
            //}
            //else if(NSContainsRect(self.bounds, exportFrame) == false)
            //{
                NSColor.white.setFill()
                exportFrame.insetBy(dx: -3, dy: -3).frame(withWidth: 3.0, using: NSCompositingOperation.difference)
            //}
            
        }
    }

    override var isFlipped: Bool
    {
        return true
    }

    override func cursorUpdate(with event: NSEvent)
    {
        self.setupCursor()
    }
    
    override func viewDidMoveToWindow() {
        
        // for mouseMoved events
        self.window?.acceptsMouseMovedEvents = true
        
        
        // for mouseEntered and Exited events

        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeInActiveApp, .mouseEnteredAndExited,.cursorUpdate],
                                      owner: self, userInfo: nil)
                                      
        
        self.addTrackingArea(trackingArea)
        
        
    }
    
    // for keydown
    override var acceptsFirstResponder: Bool { return true }
    
    var trackingArea : NSTrackingArea = NSTrackingArea();
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeInActiveApp, .mouseEnteredAndExited],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
    
    
    
    
    var activePenLayerCursor : NSCursor?;
    
    // ------
    // also called by
    // inputInteractionManager's mouseEntered(with event: NSEvent)
    // calls resetCursorRects() at the end
    // ------
    func setupCursor()
    {
        let squareForCursorBounds = NSRect.init(origin: .zero, size: CGSize.init(width: 30, height: 30))
        let hotspotPoint = squareForCursorBounds.centroid()
        // Make the cursor image
        let img = NSImage(size: squareForCursorBounds.size)
        img.usesEPSOnResolutionMismatch = true
        img.lockFocus()
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.imageInterpolation = NSImageInterpolation.high;
   
     
        let p = NSBezierPath();
     
        var strokeColor : NSColor?
        if(lineWorkInteractionEntity!.lineWorkEntityMode == .isInRectangleSelect)
        {
            strokeColor = .purple
            p.lineWidth = 4.0;
        }
        else if(inkAndLineSettingsManager!.shadingShapesModeIsOn)
        {
            strokeColor = NSColor.init(red: 0.39, green: 0.64, blue: 0.98, alpha: 1.0)
            p.lineWidth = 4.0;
        }
        else if((inkAndLineSettingsManager!.combinatoricsModeIsOn) || (inkAndLineSettingsManager!.unionWithLastDrawnShapeForDrawing))
        {
            strokeColor = NSColor.orange.blended(withFraction: 0.2, of: .black);
            p.lineWidth = 4.0;
            
        }
        else
        {
            strokeColor = NSColor.white
        }
        
        
        if(lineWorkInteractionEntity!.lineWorkEntityMode == .isInRectangleSelect)
        {
            p.appendRect(squareForCursorBounds.insetBy(dx: 2, dy: 2))
        
        }
        
        if(drawingPage!.currentPaperLayer.isCarting)
        {
            
         
            if let cartingSFImg = NSImage.init(named: "carting_symbol_small")
            {
                cartingSFImg.draw(in: squareForCursorBounds)
                
            }
            if((inkAndLineSettingsManager!.combinatoricsModeIsOn) || (inkAndLineSettingsManager!.unionWithLastDrawnShapeForDrawing))
            {
                
                
                let p = NSBezierPath();
                p.move(to: squareForCursorBounds.topMiddle())
                p.line(to: squareForCursorBounds.middleRight())
                p.line(to: squareForCursorBounds.bottomMiddle())
                p.line(to: squareForCursorBounds.middleLeft())
                p.close();
                NSColor.orange.withAlphaComponent(0.5).setFill()
                p.fill()
                
        
            }
        }
        else if(inkAndLineSettingsManager!.fmInk.brushTip.isUniform)
        {
            if(inkAndLineSettingsManager!.fmInk.brushTip == .uniform)
            {
                p.appendOval(in: squareForCursorBounds.insetBy(dx: 4, dy: 4));
            }
            else if(inkAndLineSettingsManager!.fmInk.brushTip == .uniformPath)
            {
                
                if let pencilTipImg = NSImage.init(systemSymbolName: "pencil.tip", accessibilityDescription: nil)
                {
                    NSGraphicsContext.current?.saveGraphicsState();
                    
                    
                    let shadow = NSShadow()
                    shadow.shadowBlurRadius = 3.0
                    shadow.shadowOffset = NSSize(width: 0, height: 0)
                    shadow.shadowColor = strokeColor
                    shadow.set()
                    let rectForImg = squareForCursorBounds.insetBy(dx: 3, dy: 0).offsetBy(dx: 0, dy: -14.0);
                    pencilTipImg.draw(in: rectForImg, from: .zero, operation: NSCompositingOperation.sourceOver, fraction: 0.8)
                    
                    NSGraphicsContext.current?.restoreGraphicsState()
                    
                    
                    
                }
            }
        }
        else
        {
            let secondPoint = hotspotPoint.pointFromAngleAndLength(angleRadians: inkAndLineSettingsManager?.azimuthRadians ?? 0, length: squareForCursorBounds.width / 2);
            
            let thirdPoint = hotspotPoint.pointFromAngleAndLength(angleRadians: .pi + (inkAndLineSettingsManager?.azimuthRadians ?? .pi), length: squareForCursorBounds.width / 2);
            
            let fourthPoint  = hotspotPoint.pointFromAngleAndLength(angleRadians: (0.5 * .pi) + (inkAndLineSettingsManager?.azimuthRadians ?? 0.5 * .pi ), length: squareForCursorBounds.width / 3);
            
            let fifthPoint   = hotspotPoint.pointFromAngleAndLength(angleRadians: (1.5 * .pi) + (inkAndLineSettingsManager?.azimuthRadians ?? 1.5 * .pi ), length: squareForCursorBounds.width / 5);
            
            
            p.lineWidth = 1.0
            
            p.move(to: hotspotPoint)
            
            p.line(to: secondPoint)
            p.move(to: hotspotPoint)
            
            p.line(to: thirdPoint)
            p.move(to: fourthPoint)
            p.line(to: fifthPoint)
            
        }
        
        /*
        if(((inkAndLineSettingsManager!.combinatoricsModeIsOn) || (inkAndLineSettingsManager!.unionWithLastDrawnShapeForDrawing)))
        {
            NSGraphicsContext.current?.saveGraphicsState();
            
            
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 3.0
            shadow.shadowOffset = NSSize(width: 0, height: 0)
            shadow.shadowColor = strokeColor
            shadow.set()
            
            p.lineWidth = 2.0;
            var imgString = "unionKbImg";
            if(inkAndLineSettingsManager!.combinatoricsMode == .intersection)
            {
                imgString = "intersectionKbImg"
            }
            else if(inkAndLineSettingsManager!.combinatoricsMode == .subtraction)
            {
                imgString = "subtractionKbImg"
            }
            
            let img = NSImage.init(imageLiteralResourceName: imgString)
            
            img.draw(in: squareForCursorBounds, from: .zero, operation: NSCompositingOperation.sourceOver, fraction: 0.5)
            
            NSGraphicsContext.current?.restoreGraphicsState()
            
            
            
        }*/
        
        
        var xfm = AffineTransform.init(translationByX: 1, byY: 1);
        p.transform(using: xfm)
        NSColor.black.setStroke();
        
        if(inkAndLineSettingsManager!.shadingShapesModeIsOn || ((inkAndLineSettingsManager!.combinatoricsModeIsOn) || (inkAndLineSettingsManager!.unionWithLastDrawnShapeForDrawing)))
        {
            p.lineWidth = 4.0;
            
       
            
        }
        
        
    
        
        p.stroke()
        
       
        
        xfm = AffineTransform.init(translationByX:-1, byY: -1);
        p.transform(using: xfm)

        
   
        strokeColor?.setStroke();
        
        p.stroke()
        
             
        if(inkAndLineSettingsManager!.shadingShapesModeIsOn)
        {
            let s = "ss"
            s.drawStringInsideRectWithMenlo(fontSize: 13, textAlignment: .center, fontForegroundColor: .white.withAlphaComponent(0.8), rect: squareForCursorBounds)
        }
        
        
        // END LOCK FOCUS
        NSGraphicsContext.restoreGraphicsState();
        img.unlockFocus()
        
        activePenLayerCursor = NSCursor(image: img, hotSpot: hotspotPoint)
        
        self.resetCursorRects();
        
    }
    
    override func resetCursorRects() {
        /// Invalidates all cursor rectangles set up using addCursorRect(_:cursor:).
        discardCursorRects()
        
        /// change text cursor icon to the pointingHand one
        addCursorRect(bounds, cursor: activePenLayerCursor ?? NSCursor.crosshair)
        
    }
    
}
