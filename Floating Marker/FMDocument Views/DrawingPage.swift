//
//  DrawingPage.swift
//  Floating Marker
//
//  Created by John Pratt on 1/10/21.
//

import Cocoa

// A container for
// the drawing layers and activePenLayer
class DrawingPage: NSView
{
    var drawingPageController : NCTDrawingPageController?
    
    var permanentAnchorPoint : NSPoint = .zero
    {
        didSet
        {
            if(drawingPageController?.inkAndLineSettingsManager != nil)
            {
                if(drawingPageController!.inkAndLineSettingsManager!.replicationModeIsOn)
                {
                    drawingPageController!.lineWorkInteractionEntity!.replicationConfigurationViewController?.updateGuidelines()
                }
            }
        }
    }

    override var isFlipped: Bool
    {
        return true;
    }

    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        activePenLayer.drawingPage = self;
        self.wantsLayer = true;
        self.layer?.backgroundColor = defaultBackgroundCGColor
        
        vanishingPointsAandBBezierPath.setLineDash([1,2,1,2], count: 4, phase: 0);

        loadSettings()
        makeBackgroundGridPattern()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder:decoder)
        self.wantsLayer = true;

        activePenLayer.drawingPage = self;
        
        vanishingPointsAandBBezierPath.setLineDash([1,2,1,2], count: 4, phase: 0);
        
        loadSettings()
        makeBackgroundGridPattern()
    }
    
    

    



    var drawingBoard : DrawingBoard?;
    
    var activePenLayer : ActivePenLayer = ActivePenLayer();
    var paperLayers : [PaperLayer] = [PaperLayer(),PaperLayer(),PaperLayer(),PaperLayer()];
    var currentPaperLayerIndex : Int = 0
    {
        didSet{
        
            if(paperLayers.isEmpty == false)
            {
                currentPaperLayerIndex.formClamp(to: 0...(paperLayers.count - 1))
                
                //drawingPageController?.layersPopUpButton?.selectItem(at: currentPaperLayerIndex);
                
                
                if(drawingPageController!.layersTableView!.numberOfRows < self.paperLayers.count)
                {
                    drawingPageController!.layersTableView!.reloadData()
                }
                
                if(drawingPageController!.layersTableView!.selectedRow != currentPaperLayerIndex)
                {
                    drawingPageController?.layersTableView?.selectRowIndexes(IndexSet.init(arrayLiteral: currentPaperLayerIndex), byExtendingSelection: false);
                }
                
               // if(currentPaperLayerIndex != oldValue)
               // {
               
                
                if(oldValue < paperLayers.count)
                {
                    // turns off carting and any live transformations:
                    if(paperLayers[oldValue].hasSelectedDrawables)
                    {
                        paperLayers[oldValue].clearOutSelections()
                    }
                }
               
                var durationFloat : CGFloat = 0.15;
                if(activePenLayer.inkAndLineSettingsManager != nil)
                {
                    if(activePenLayer.inkAndLineSettingsManager!.statusMessagesIsOn)
                    {
                        durationFloat = 0.70;
                    }
                }
                
                    currentPaperLayer.flashAllVisibleObjects(duration:durationFloat);
               // }
               
               drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "Layer Changed to\n\(currentPaperLayer.name)", duration: 0.50, messageLevel: 2);
               
            }
        }
    }
    
    var currentPaperLayer : PaperLayer
    {
        get
        {
            if(currentPaperLayerIndex > (paperLayers.count - 1))
            {
                fatalError("paperLayersIndex exceeded paperLayers count")
            }
        
            return paperLayers[currentPaperLayerIndex]
        }
    }

    func layerStepTowardBaseLayer()
    {
        if((currentPaperLayerIndex - 1) >= 0)
        {
            currentPaperLayerIndex -= 1;
        }
        
    }
    
    func layerStepAwayFromBaseLayer()
    {
        if((currentPaperLayerIndex + 1) < paperLayers.count)
        {
            currentPaperLayerIndex += 1;
        }
    }

    var defaultBackgroundCGColor : CGColor
    {
        get{ return defaultBackgroundColor.cgColor }
    }

    var defaultBackgroundColor = NSColor.init(white: 0.5, alpha: 1.0)
    {
        didSet{
                
            if(showGrid)
            {
                makeBackgroundGridPattern()
                self.layer?.backgroundColor = gridBackgroundPatternNSColor.cgColor
            }
            else
            {
                self.layer?.backgroundColor = defaultBackgroundColor.cgColor;
            }
            self.needsDisplay = true;
            
        }
    
    }

    var vanishingPoint1and2Y : CGFloat = 0
    {
        didSet{  vanishingPoint1and2Y = vanishingPoint1and2Y.clamped(to: 0...self.bounds.height) }
    }
    
    var vanishingPoint1X : CGFloat = 0
    {
        didSet{  vanishingPoint1X = vanishingPoint1X.clamped(to: 0...self.bounds.width) }
    }
    var vanishingPoint2X : CGFloat = 0
    {
        didSet{ vanishingPoint2X = vanishingPoint2X.clamped(to: 0...self.bounds.width) }
    }
    var vanishingPoint3 : NSPoint = .zero;
    var userPerspectivePoints : [NSPoint] = [];
    


    // called when drawing page's frame is
    // reset.
    func updateDrawingLayersAndActivePenLayer()
    {
        for (_, paperLayer) in self.paperLayers.enumerated()
        {
            paperLayer.frame = self.bounds;
        }
        
      
        activePenLayer.frame = self.bounds;
        
        if(self.subviews.isEmpty)
        {

            for (_, paperLayer) in self.paperLayers.enumerated()
            {
                self.addSubview(paperLayer)
            }
            
        
            self.addSubview(activePenLayer)
            
        }
        
    }
    
  
    /*
    func refreshLayersPopUpButton()
    {
        self.drawingPageController?.layersPopUpButton?.menu?.removeAllItems();
        
        for (index, paperLayer) in self.paperLayers.enumerated()
        {
            let menuItem = NSMenuItem.init(title: paperLayer.name, action: nil, keyEquivalent: "\(index + 1)");
            menuItem.tag = index;
            menuItem.representedObject = paperLayer;
            self.drawingPageController?.layersPopUpButton?.menu?.addItem(menuItem);
        }
    }*/

    func setupActivePenLayerForDrawing()
    {
        if let appDelegate = NSApp.delegate as? AppDelegate
        {
            activePenLayer.inputInteractionManager = appDelegate.inputInteractionManager
            activePenLayer.lineWorkInteractionEntity = appDelegate.lineWorkInteractionEntity
            activePenLayer.inkAndLineSettingsManager = appDelegate.inkAndLineSettingsManager
        }
    }

    var inCaptureDataState : Bool = false;
    override func draw(_ dirtyRect: NSRect)
    {
        if(inCaptureDataState)
        {
            self.defaultBackgroundColor.setFill()
            self.bounds.fill();
        }

    
    
        
    }
    
    
    
    // ---------------------------------------------
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: VANISHING POINT LINES
    let vanishingPointsAandBBezierPath : NSBezierPath = NSBezierPath();
    let vanishingPointsCursorVerticalLine : NSBezierPath = NSBezierPath();
    
    var horizonLineY : CGFloat = 40;
    var vanishingPointAx : CGFloat = -500;
    var vanishingPointA : NSPoint
    {
        get{ return NSPoint.init(x: vanishingPointAx, y: horizonLineY)}
    }
    
    var vanishingPointBx : CGFloat = 2000;
    var vanishingPointB : NSPoint
    {
        get{ return NSPoint.init(x: vanishingPointBx, y: horizonLineY)}
    }
    
    var vanishingPointC : NSPoint = .zero
    var vanishingPointsUser : [NSPoint] = []
    var stampedVanishingPointLines : [NSBezierPath] = [];
    
    var pointsForStampedVanishingPointLines : [NSPoint] = []
    
    func stampCurrentVanishingPointGuidelines(currentPointInActiveLayer : NSPoint)
    {
    
    
        var updateRectForVPStampLines = NSRect.zero;
    
        let stampForVpA = NSBezierPath();
        stampForVpA.move(to: CGPoint.init(x: self.vanishingPointAx, y: horizonLineY))
        stampForVpA.line(to: currentPointInActiveLayer)
    updateRectForVPStampLines = stampForVpA.bounds

        let stampForVpB = NSBezierPath();
        stampForVpB.move(to: CGPoint.init(x: self.vanishingPointBx, y: horizonLineY))
        stampForVpB.line(to: currentPointInActiveLayer)
    updateRectForVPStampLines = updateRectForVPStampLines.union(stampForVpB.bounds)
    
        stampForVpA.setLineDash([2,2], count: 2, phase: 0)
            stampForVpB.setLineDash([2,2], count: 2, phase: 0)

        stampedVanishingPointLines.append(stampForVpA)
        stampedVanishingPointLines.append(stampForVpB)
    
        let s = NSBezierPath();
        s.move(to: NSPoint.init(x: currentPointInActiveLayer.x, y: 0))
        s.line(to: NSPoint.init(x: currentPointInActiveLayer.x, y: currentPointInActiveLayer.y + 200))
        s.setLineDash([2,2], count: 2, phase: 0)
        updateRectForVPStampLines = updateRectForVPStampLines.union(s.bounds)
    stampedVanishingPointLines.append(s)
    
        pointsForStampedVanishingPointLines.append(currentPointInActiveLayer);
        
        activePenLayer.setNeedsDisplay(updateRectForVPStampLines);

    }
     var lastVPBUpdateRect : NSRect = .zero;
    
    func clearVanishingPointLines()
    {

        
        stampedVanishingPointLines.removeAll();
        pointsForStampedVanishingPointLines.removeAll();
    }
    
    
    
    var vanishingPointAAngleToCursor : CGFloat = .pi * 0.5;
    var vanishingPointBAngleToCursor : CGFloat = .pi * 1.5;
  
    func updateVPB(currentPointInActiveLayer : NSPoint)
    {
    
        
        vanishingPointsAandBBezierPath.removeAllPoints()
    
        // horizon line
        vanishingPointsAandBBezierPath.move(to: CGPoint.init(x: 0, y: horizonLineY))
        vanishingPointsAandBBezierPath.line(to: CGPoint.init(x: activePenLayer.bounds.width, y: horizonLineY))
    
        // vanishing point A
        vanishingPointsAandBBezierPath.move(to: CGPoint.init(x: self.vanishingPointAx, y: horizonLineY))
        vanishingPointsAandBBezierPath.line(to: currentPointInActiveLayer)
        
        vanishingPointAAngleToCursor = NSBezierPath.lineAngleRadiansFrom(point1: CGPoint.init(x: self.vanishingPointAx, y: horizonLineY), point2: currentPointInActiveLayer)
        
        
        // vanishing point B
        vanishingPointsAandBBezierPath.move(to: CGPoint.init(x: self.vanishingPointBx, y: horizonLineY))
        vanishingPointsAandBBezierPath.line(to: currentPointInActiveLayer)

        vanishingPointBAngleToCursor = NSBezierPath.lineAngleRadiansFrom(point1: CGPoint.init(x: self.vanishingPointBx, y: horizonLineY), point2: currentPointInActiveLayer)


        vanishingPointsCursorVerticalLine.removeAllPoints();
        vanishingPointsCursorVerticalLine.move(to: CGPoint.init(x: currentPointInActiveLayer.x, y: currentPointInActiveLayer.y - 100))
        vanishingPointsCursorVerticalLine.line(to: CGPoint.init(x: currentPointInActiveLayer.x, y: currentPointInActiveLayer.y + 100))
        vanishingPointsCursorVerticalLine.setLineDash([2,2], count: 2, phase: 0)


        let currentBounds = vanishingPointsAandBBezierPath.bounds.union(vanishingPointsCursorVerticalLine.bounds);
    
        if(lastVPBUpdateRect == .zero)
        {
            lastVPBUpdateRect = currentBounds.insetBy(dx: -10, dy: -10)
        }
        
        activePenLayer.setNeedsDisplay(currentBounds.insetBy(dx: -10, dy: -10).union(lastVPBUpdateRect))
        
        lastVPBUpdateRect = currentBounds;
    }
    
    func drawVanishingPointGuides()
    {
    
        guard let inkAndLineSettingsManager = (NSApp.delegate as? AppDelegate)?.inkAndLineSettingsManager else { return }
        
           //  MARK: draw vanishing point guides
        if(inkAndLineSettingsManager.vanishingPointGuides)
        {
        
            NSColor.white.setStroke();
            if(inkAndLineSettingsManager.vanishingPointCount == 2)
            {
                vanishingPointsAandBBezierPath.stroke()
            }
            
            NSColor.darkGray.setStroke();
            vanishingPointsCursorVerticalLine.stroke()
            
            NSColor.darkGray.setStroke();

            for s in stampedVanishingPointLines
            {
                s.stroke();
            }
        }
        
    }
    
    
    
    // ---------------------------------------------
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: GRIDS
    
    
    func drawGrid(dirtyRect: NSRect)
    {
    
         
    
    }
    
    var gridBackgroundPatternNSColor : NSColor = NSColor.white;

    var bgImg : NSImage?
    var bitmapRepresentation : NSBitmapImageRep?
    var bezierPathForPattern : NSBezierPath = NSBezierPath()

    func makeBackgroundGridPattern()
    {
        if(gridSnappingType == .squareDots)
        {
            
            let gridIntervalBaseSize = NSSize.init(width: gridSnappingEdgeLength, height: gridSnappingEdgeLength)
            let gridInterval4XSize = NSSize(width: gridSnappingEdgeLength * 4 , height: gridSnappingEdgeLength * 4 )
            
            // CLOSURE:
            bgImg = NSImage(size: gridInterval4XSize, flipped: false) { (rect) -> Bool in
                self.bgImg?.resizingMode = .tile;
                
                self.defaultBackgroundColor.setFill();
                let r = NSRect.init(origin: .zero, size: gridInterval4XSize)
                r.fill();
                
                
                let p = NSBezierPath();
                
                let radiusForDot : CGFloat = 0.25 * self.gridSnappingEdgeLength;
                
                self.gridColor.setFill()
                p.appendArc(withCenter: NSPoint.zero, radius: radiusForDot, startAngle: 0, endAngle: 360)
                p.fill();
                
                p.removeAllPoints()
                p.appendArc(withCenter: NSMakePoint(0, gridInterval4XSize.height), radius: radiusForDot, startAngle: 0, endAngle: 360)
                p.fill();
                
                p.removeAllPoints()
                p.appendArc(withCenter: NSMakePoint(gridInterval4XSize.width, 0), radius: radiusForDot, startAngle: 0, endAngle: 360)
                p.fill()
                
                p.removeAllPoints()
                p.appendArc(withCenter: NSMakePoint(gridInterval4XSize.width, gridInterval4XSize.height), radius: radiusForDot, startAngle: 0, endAngle: 360)
                p.fill()
                
                return true;
                
            }// END closure for  NSImage(size: gridInterval4XSize, flipped: false)
            
            // the size of the bitmapRepresentation is
            // the same, but the pixelsHigh and
            // pixelsWide is much larger.
            bitmapRepresentation = NSBitmapImageRep(data: (bgImg!.tiffRepresentation!))
            bitmapRepresentation?.size = gridIntervalBaseSize;
            bitmapRepresentation?.pixelsHigh = Int(ceil(gridInterval4XSize.height))
            bitmapRepresentation?.pixelsWide = Int(ceil(gridInterval4XSize.width))
            
            bgImg?.size = gridIntervalBaseSize;
            bgImg?.addRepresentation(bitmapRepresentation!)
            
        }
     
        else if(gridSnappingType == .squareEdges)
        {
            
            let gridIntervalBaseSize = NSSize.init(width: gridSnappingEdgeLength, height: gridSnappingEdgeLength)
            let gridInterval4XSize = NSSize(width: gridSnappingEdgeLength * 4 , height: gridSnappingEdgeLength * 4 )
            
            // CLOSURE:
            bgImg = NSImage(size: gridInterval4XSize, flipped: false) { (rect) -> Bool in
                self.bgImg?.resizingMode = .tile;
                
                self.defaultBackgroundColor.setFill();
                let r = NSRect.init(origin: .zero, size: gridInterval4XSize)
                r.fill();
                
                
                let p = NSBezierPath();
                
                let lineWidthForPath : CGFloat = 0.25 * self.gridSnappingEdgeLength;
                p.lineWidth = lineWidthForPath;
                self.gridColor.setStroke()
                
                p.appendRect(r)
                p.stroke()
                

                return true;
                
            }// END closure for  NSImage(size: gridInterval4XSize, flipped: false)
            
            // the size of the bitmapRepresentation is
            // the same, but the pixelsHigh and
            // pixelsWide is much larger.
            bitmapRepresentation = NSBitmapImageRep(data: (bgImg!.tiffRepresentation!))
            bitmapRepresentation?.size = gridIntervalBaseSize;
            bitmapRepresentation?.pixelsHigh = Int(ceil(gridInterval4XSize.height))
            bitmapRepresentation?.pixelsWide = Int(ceil(gridInterval4XSize.width))
            
            bgImg?.size = gridIntervalBaseSize;
            bgImg?.addRepresentation(bitmapRepresentation!)
            
        }
        else if((gridSnappingType == .square45DegEdges) || (gridSnappingType == .square45DegWithXYEdges))
        {
            
            let gridIntervalBaseSize = NSSize.init(width: gridSnappingEdgeLength, height: gridSnappingEdgeLength)
            let gridInterval4XSize = NSSize(width: gridSnappingEdgeLength * 4 , height: gridSnappingEdgeLength * 4 )
            
            // CLOSURE:
            bgImg = NSImage(size: gridInterval4XSize, flipped: false) { (rect) -> Bool in
                self.bgImg?.resizingMode = .tile;
                
                self.defaultBackgroundColor.setFill();
                let r = NSRect.init(origin: .zero, size: gridInterval4XSize)
                r.fill();
                
                
                let p = NSBezierPath();
                
                let lineWidthForPath : CGFloat = max(0.15 * self.gridSnappingEdgeLength,1.0);
                p.lineWidth = lineWidthForPath;
                self.gridColor.setStroke()
                p.move(to: r.bottomMiddle())
                p.line(to: r.middleRight())
                p.line(to: r.topMiddle())
                p.line(to: r.middleLeft())
                p.close();

                if(self.gridSnappingType == .square45DegWithXYEdges)
                {
                
                    p.move(to: r.middleLeft())
                    p.line(to: r.middleRight())
                    p.move(to: r.topMiddle())
                    p.line(to: r.bottomMiddle())
                    p.appendRect(r)
                }

                p.stroke()
                

                return true;
                
            }// END closure for  NSImage(size: gridInterval4XSize, flipped: false)
            
            // the size of the bitmapRepresentation is
            // the same, but the pixelsHigh and
            // pixelsWide is much larger.
            bitmapRepresentation = NSBitmapImageRep(data: (bgImg!.tiffRepresentation!))
            bitmapRepresentation?.size = gridIntervalBaseSize;
            bitmapRepresentation?.pixelsHigh = Int(ceil(gridInterval4XSize.height))
            bitmapRepresentation?.pixelsWide = Int(ceil(gridInterval4XSize.width))
            
            bgImg?.size = gridIntervalBaseSize;
            bgImg?.addRepresentation(bitmapRepresentation!)
            
        }
        
        else if((gridSnappingType == .triangleHorizontal) || (gridSnappingType == .triangleVertical))
        {
        
        
        
            let sideLengthOfPolygon = gridSnappingEdgeLength;
        
            let sideLengthOfPolygon4X = 4 * sideLengthOfPolygon;
        
//            let altitude : CGFloat =  0.5 * sqrt(3) * sideLengthOfPolygon;
//            var gridIntervalBaseSize = NSSize(width: sideLengthOfPolygon, height: 1 + altitude * 2)
//            var gridInterval4XSize = NSSize(width: sideLengthOfPolygon * 4, height: altitude * 2 * 4)

            self.bezierPathForPattern.removeAllPoints()
            self.bezierPathForPattern.lineWidth = 6.0;
            

            self.bezierPathForPattern.move(to: NSPoint.zero)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 60.0000, length: sideLengthOfPolygon4X)
            
            self.bezierPathForPattern.relativeMoveToByAngle(angle: 180.0000, length: sideLengthOfPolygon4X / 2.0000)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 0.0, length: sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeMoveToByAngle(angle: 180.0000, length: sideLengthOfPolygon4X / 2.0000)
            
            self.bezierPathForPattern.relativeLineToByAngle(angle: 120.0000, length: sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 0.0, length: sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 240.0000, length: sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 300.0000, length: sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 180.0000, length: sideLengthOfPolygon4X)
            
//            self.bezierPathForPattern.setLineDash([1,1], count: 2, phase: 0)
             
             // SUBTRACTING 2 REMOVES GAP BETWEEN PATTERN REPEATS:
             var bForSize = self.bezierPathForPattern.bounds
             bForSize.size.width -= 2;
            var gridInterval4XSize = bForSize.size//self.bezierPathForPattern.bounds.size
            var gridIntervalBaseSize = NSSize(width: (gridInterval4XSize.width / 4), height:  gridInterval4XSize.height / 4)
            
            if(gridSnappingType == .triangleHorizontal)
            {
                var affineXform = AffineTransform();
                
                affineXform.translate(x: bezierPathForPattern.bounds.height, y: 0)
                affineXform.rotate(byDegrees: 90);
                self.bezierPathForPattern.transform(using: affineXform)
                
                gridIntervalBaseSize = NSSize(width: gridIntervalBaseSize.height, height: gridIntervalBaseSize.width )
                gridInterval4XSize = NSSize(width: gridInterval4XSize.height, height: gridInterval4XSize.width)
            }
            
            // CLOSURE:
            bgImg = NSImage(size: gridInterval4XSize, flipped: false) { (rect) -> Bool in
                self.bgImg?.resizingMode = .tile;
                
   
                
                self.defaultBackgroundColor.setFill();
                self.bezierPathForPattern.bounds.insetBy(dx: -3, dy: -3).fill()
                
                self.gridColor.setStroke();
                self.bezierPathForPattern.stroke();
                
                return true;
                
            }// END closure for  NSImage(size: gridInterval4XSize, flipped: false)
            
            // the size of the bitmapRepresentation is
            // the same, but the pixelsHigh and
            // pixelsWide is much larger.
            bitmapRepresentation = NSBitmapImageRep(data: (bgImg!.tiffRepresentation!))
            bitmapRepresentation?.size = gridIntervalBaseSize
            bitmapRepresentation?.pixelsHigh = Int(ceil(gridInterval4XSize.height))
            bitmapRepresentation?.pixelsWide = Int(ceil(gridInterval4XSize.width))
            
            bgImg?.size = gridIntervalBaseSize;
            bgImg?.addRepresentation(bitmapRepresentation!)
            
        }
        else if(gridSnappingType == .hexagonHorizontal)
        {
            let sideLengthOfPolygon = gridSnappingEdgeLength;
        
            let sideLengthOfPolygon4X = 4 * sideLengthOfPolygon;
    
            let firstBumpRight = sideLengthOfPolygon4X * cos( deg2rad(60) )
        
    
            self.bezierPathForPattern.removeAllPoints()
            self.bezierPathForPattern.lineWidth = 6.0;
            
            // firstBumpRight starts at lower lefthand corner.
            self.bezierPathForPattern.move(to: NSPoint.zero)
            self.bezierPathForPattern.relativeMoveToByAngle(angle: 0.0, length: firstBumpRight + sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 180, length: sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 120.0000, length: sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 60.0000, length: sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 0.0000, length: sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 300.0000, length: sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 240.0000, length: sideLengthOfPolygon4X)
            
            self.bezierPathForPattern.relativeMoveToByAngle(angle: 60, length: sideLengthOfPolygon4X)
            self.bezierPathForPattern.relativeLineToByAngle(angle: 0.0000, length: sideLengthOfPolygon4X)
//            self.bezierPathForPattern.setLineDash([1,1], count: 2, phase: 0)
            

             // SUBTRACTING 2 REMOVES GAP BETWEEN PATTERN REPEATS:
             var bForSize = self.bezierPathForPattern.bounds
             bForSize.size.width -= 2;
            let gridInterval4XSize = bForSize.size//self.bezierPathForPattern.bounds.size
            let gridIntervalBaseSize = NSSize(width: (gridInterval4XSize.width / 4), height:  gridInterval4XSize.height / 4)
            
            /*
            if(gridSnappingType == .triangleHorizontal)
            {
                var affineXform = AffineTransform();
                
                affineXform.translate(x: bezierPathForPattern.bounds.height, y: 0)
                affineXform.rotate(byDegrees: 90);
                self.bezierPathForPattern.transform(using: affineXform)
                
                gridIntervalBaseSize = NSSize(width: gridIntervalBaseSize.height, height: gridIntervalBaseSize.width )
                gridInterval4XSize = NSSize(width: gridInterval4XSize.height, height: gridInterval4XSize.width)
            }*/
            
            // CLOSURE:
            bgImg = NSImage(size: gridInterval4XSize, flipped: false) { (rect) -> Bool in
                self.bgImg?.resizingMode = .tile;
                
   
                
                self.defaultBackgroundColor.setFill();
                self.bezierPathForPattern.bounds.insetBy(dx: -3, dy: -3).fill()
                
                self.gridColor.setStroke();
                self.bezierPathForPattern.stroke();
                
                return true;
                
            }// END closure for  NSImage(size: gridInterval4XSize, flipped: false)
            
            // the size of the bitmapRepresentation is
            // the same, but the pixelsHigh and
            // pixelsWide is much larger.
            bitmapRepresentation = NSBitmapImageRep(data: (bgImg!.tiffRepresentation!))
            bitmapRepresentation?.size = gridIntervalBaseSize
            bitmapRepresentation?.pixelsHigh = Int(ceil(gridInterval4XSize.height))
            bitmapRepresentation?.pixelsWide = Int(ceil(gridInterval4XSize.width))
            
            bgImg?.size = gridIntervalBaseSize;
            bgImg?.addRepresentation(bitmapRepresentation!)
        }
         else if(gridSnappingType == .hexagonVertical)
        {
            let sideLengthOfPolygon = gridSnappingEdgeLength;
        
            let sideLengthOfPolygon4X = 4 * sideLengthOfPolygon;
    
            let firstBumpUp = sideLengthOfPolygon4X * cos( deg2rad(60) )
        
    
            self.bezierPathForPattern.removeAllPoints()
            self.bezierPathForPattern.lineWidth = 6.0;
            
            
            self.bezierPathForPattern.move(to: NSPoint.zero)
        self.bezierPathForPattern.relativeMoveToByAngle(angle: 90.0000, length: firstBumpUp)
        self.bezierPathForPattern.relativeLineToByAngle(angle: 330.0000, length: sideLengthOfPolygon4X)
        self.bezierPathForPattern.relativeLineToByAngle(angle: 30.0000, length: sideLengthOfPolygon4X)
        self.bezierPathForPattern.relativeLineToByAngle(angle: 90.0000, length: sideLengthOfPolygon4X)
        self.bezierPathForPattern.relativeLineToByAngle(angle: 150.0000, length: sideLengthOfPolygon4X)
        self.bezierPathForPattern.relativeLineToByAngle(angle: 210.0000, length: sideLengthOfPolygon4X)
        self.bezierPathForPattern.relativeMoveToByAngle(angle: 30, length: sideLengthOfPolygon4X)
        self.bezierPathForPattern.relativeLineToByAngle(angle: 90.0000, length: sideLengthOfPolygon4X)
                    self.bezierPathForPattern.move(to: NSPoint.zero)
        self.bezierPathForPattern.relativeMoveToByAngle(angle: 90.0000, length: firstBumpUp)
        self.bezierPathForPattern.relativeLineToByAngle(angle: 90.0000, length: sideLengthOfPolygon4X)
        
//            self.bezierPathForPattern.setLineDash([1,1], count: 2, phase: 0)

             // SUBTRACTING 2 REMOVES GAP BETWEEN PATTERN REPEATS:
             let bForSize = self.bezierPathForPattern.bounds
            // bForSize.size.width -= 2;
            let gridInterval4XSize = bForSize.size//self.bezierPathForPattern.bounds.size
            let gridIntervalBaseSize = NSSize(width: (gridInterval4XSize.width / 4), height:  gridInterval4XSize.height / 4)
            
            /*
            if(gridSnappingType == .triangleHorizontal)
            {
                var affineXform = AffineTransform();
                
                affineXform.translate(x: bezierPathForPattern.bounds.height, y: 0)
                affineXform.rotate(byDegrees: 90);
                self.bezierPathForPattern.transform(using: affineXform)
                
                gridIntervalBaseSize = NSSize(width: gridIntervalBaseSize.height, height: gridIntervalBaseSize.width )
                gridInterval4XSize = NSSize(width: gridInterval4XSize.height, height: gridInterval4XSize.width)
            }*/
            
            // CLOSURE:
            bgImg = NSImage(size: gridInterval4XSize, flipped: false) { (rect) -> Bool in
                self.bgImg?.resizingMode = .tile;
                
   
                
                self.defaultBackgroundColor.setFill();
                self.bezierPathForPattern.bounds.insetBy(dx: -3, dy: -3).fill()
                
                self.gridColor.setStroke();
                self.bezierPathForPattern.stroke();
                
                return true;
                
            }// END closure for  NSImage(size: gridInterval4XSize, flipped: false)
            
            // the size of the bitmapRepresentation is
            // the same, but the pixelsHigh and
            // pixelsWide is much larger.
            bitmapRepresentation = NSBitmapImageRep(data: (bgImg!.tiffRepresentation!))
            bitmapRepresentation?.size = gridIntervalBaseSize
            bitmapRepresentation?.pixelsHigh = Int(ceil(gridInterval4XSize.height))
            bitmapRepresentation?.pixelsWide = Int(ceil(gridInterval4XSize.width))
            
            bgImg?.size = gridIntervalBaseSize;
            bgImg?.addRepresentation(bitmapRepresentation!)
        }
        
        gridBackgroundPatternNSColor = NSColor(patternImage: bgImg!)
        
        
    }// END makeBackgroundGridPattern()

    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: NCTGridSnappingType
    
    var showGrid : Bool = false
    {
        didSet
        {
            if(showGrid == true)
            {
                makeBackgroundGridPattern();
                self.layer?.backgroundColor = gridBackgroundPatternNSColor.cgColor

            }
            else
            {
                self.layer?.backgroundColor = defaultBackgroundCGColor;
            }
            
            self.needsDisplay = true;

        }
    
    }
    
    var isLoadingSettings : Bool = false;
    
    func updateGridBackground()
    {
        guard (isLoadingSettings == false) else {
            return
        }

        makeBackgroundGridPattern();

        if(showGrid == true)
        {
            self.layer?.backgroundColor = gridBackgroundPatternNSColor.cgColor
            self.needsDisplay = true;
        }
    }
    
    var gridColor : NSColor = NSColor.darkGray
    {
        didSet
        {
            updateGridBackground()
        }
    }
    
    var gridSnapping : Bool = false
    {
        didSet
        {
            
        }
    }
    
    var gridSnappingType : NCTGridSnappingType = .squareDots
    {
        didSet{
        
            updateGridBackground()
        
        }
    }


    var gridSnappingEdgeLength : CGFloat = 40.0
    {
        didSet
        {
            gridSnappingEdgeLength = gridSnappingEdgeLength.clamped(to: 2...400);
            updateGridBackground()

        }
        
    }
    
    // MARK: -
    // MARK:  Image Capture of Drawing Layer
    
    func imageDataFromCroppingRect(type:String, croppingRectangle:NSRect?, includeBackground:Bool) -> Data
    {
        print("imageDataFromCroppingRect: " + type);
    
        var data : Data = Data.init();
     
        // --------------------
        // inCaptureDataState is in the drawRect function of
        // this class, draws the background manually instead
        // of relying on CALayer bgcolor for PDF/EPS capture.
        // --------------------
        inCaptureDataState = true;
        activePenLayer.inCaptureDataState = true;
        if(type == "pdf")
        {
            
            data = self.dataWithPDF(inside: croppingRectangle ?? self.bounds)
            
            
        }
        else if(type == "eps")
        {
            data = self.dataWithEPS(inside: croppingRectangle ?? self.bounds)
        }
        else if(type == "svg")
        {
            
            print("imageDataFromCroppingRect: svg" );
            
            if(croppingRectangle == self.bounds)
            {
                print("export cropping rectangle == self.bounds");
            
                if let exportedSVGXMLDoc = drawingPageController?.fmDocument.exportedSVGDoc(includeBackground: includeBackground)
                {
                    data = exportedSVGXMLDoc.xmlData
                }
                
                print("(croppingRectangle == self.bounds) COUNT: " + String(data.count));
            
            }
            else
            {
                print("export cropping rectangle was != self.bounds");
            
                if let exportedSVGXMLDoc = drawingPageController?.fmDocument.exportCroppedSVG(includeBackground: includeBackground, croppingRectanglePx: croppingRectangle ?? self.bounds, croppingRectangleWithUnits: croppingRectangle ?? self.bounds, croppingRectangleUnits: "px")
                {
                    data = exportedSVGXMLDoc.xmlData
                }
                
                /*
                
                
                
                if let exportedSVGXMLDoc = drawingPageController?.fmDocument.exportCroppedSVG(includeBackground: includeBackground, croppingRectanglePx: croppingRectangle ?? self.bounds, croppingRectangleWithUnits: drawingPageController!.exportFrameWithUnitsNSRect, croppingRectangleUnits: drawingPageController!.exportFrameUnitsString)
                {
                    data = exportedSVGXMLDoc.xmlData
                }
                */
                
                print("(croppingRectangle != self.bounds) COUNT:" + String(data.count));
            }
        }
        
        
        inCaptureDataState = false;
        activePenLayer.inCaptureDataState = false;

        return data;
    
    }
    
    
    // MARK: -
    // ------------------------------
    // called from DrawingPage's init rather
    // than awakeFromNib because
    // awakeFromNib is not used in DrawingPage.
    // May be called by FMDocument in the future.
    func loadSettings()
    {
    
        // isLoadingSettings prevents
        // duplicate regeneration of the
        // background image, and a guard check is placed
        // inside updateGridBackground()
        isLoadingSettings = true;
        
        defaultBackgroundColor = NSColor.init(white: 0.5, alpha: 1.0).usingColorSpace(NSColorSpace.sRGB)!
        showGrid = false;
        gridSnappingEdgeLength = 40.0;
        gridSnappingType = .squareDots;
        gridColor = NSColor.init(calibratedWhite: 0.5, alpha: 1.0).usingColorSpace(NSColorSpace.sRGB)! //NSColor.darkGray;
        
        // Now update the grid background.
        isLoadingSettings = false;
        updateGridBackground();
    }
        
      // MARK: XML ELEMENT
    func drawingPageSettingsXMLElement() -> XMLElement
    {
        let drawingPageSettingsXMLElement = XMLElement.init(name: "fmkr:DrawingPageSettings")
        // DrawingPageSettings
        
            // MARK:  DrawingPageBackground
            // -- defaultBackgroundColor
            let drawingPageBackgroundXMLElement = XMLElement.init(name: "fmkr:DrawingPageBackground")
                drawingPageBackgroundXMLElement.setAttributesAs(["defaultBackgroundColor":defaultBackgroundColor.xmlRGBAttributeStringContent()])
            drawingPageSettingsXMLElement.addChild(drawingPageBackgroundXMLElement)
            
            
            // MARK: DrawingPageGrid
                // -- showGrid
                // -- gridType
                // -- gridColor
                // -- gridSnappingEdgeLength
        let drawingPageGridXMLElement = XMLElement.init(name: "fmkr:DrawingPageGrid")
                drawingPageGridXMLElement.setAttributesAs(["showGrid":"\(showGrid)","gridType":"\(self.gridSnappingType.rawValue)","gridColor":self.gridColor.xmlRGBAttributeStringContent(),"gridSnappingEdgeLength":"\(self.gridSnappingEdgeLength)"])
            drawingPageSettingsXMLElement.addChild(drawingPageGridXMLElement)
                
            //MARK:  DrawingPageSnapping
            
            //let drawingPageSnappingXMLElement = XMLElement.init(name: "fmkr:DrawingPageSnapping")
                // -- angleSnappingInterval
                // -- lengthSnappingDistance
                // -- activatedSnappingSettings
            //drawingPageSnappingXMLElement.setAttributesAs(["angleSnappingInterval" : "\(self.snapp)"])
          
          
        // MARK: CanvasSize

        let canvasSizeXMLElement = XMLElement.init(name: "fmkr:CanvasSize")
        canvasSizeXMLElement.setAttributesAs(["sizeForUnits" : NSStringFromSize(drawingPageController!.currentUnitsInNSSizeComputed), "units" : drawingPageController!.canvasUnitsString])
        drawingPageSettingsXMLElement.addChild(canvasSizeXMLElement)
        
         // MARK: ExportFrame
        let exportFrameXMLElement = XMLElement.init(name: "fmkr:ExportFrame")
        exportFrameXMLElement.setAttributesAs(["frameForUnits" : NSStringFromRect(drawingPageController!.exportFrame), "units" : drawingPageController!.exportFrameUnitsString])
        drawingPageSettingsXMLElement.addChild(exportFrameXMLElement)
        
        // MARK: PermanentAnchorPoint
        let permanentAnchorPointXMLElement =  XMLElement.init(name: "fmkr:PermanentAnchorPoint")
        permanentAnchorPointXMLElement.setAttributesAs(["pt" : NSStringFromPoint(permanentAnchorPoint)])
        drawingPageSettingsXMLElement.addChild(permanentAnchorPointXMLElement)
        

        return drawingPageSettingsXMLElement;
    }
        
    // MARK: XML ELEMENT
    func xmlElement() -> XMLElement
    {
        
        let drawingPageGNode = XMLElement.init(name: "g")
        drawingPageGNode.addAttribute(XMLNode.attribute(withName: "fmkr:groupType", stringValue: "DrawingPage") as! XMLNode)
        
            /*
        for paperLayer in paperLayers
        {
            for fmDrawable in paperLayer.arrayOfFMDrawables
            {
                if(paperLayerGNode.childCount == 0)
                {
                    paperLayerGNode.insertChildren(fmDrawable.xmlElements(), at: 0)
                }
                else
                {
                    paperLayerGNode.insertChildren(fmDrawable.xmlElements(), at: paperLayerGNode.childCount - 1)
                }
            }
            
        }*/
        
        return drawingPageGNode;
        
    }
} // END class
