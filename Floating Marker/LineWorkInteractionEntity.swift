//
//  LineWorkInteractionEntity.swift
//  Floating Marker
//
//  Created by John Pratt on 1/10/21.
//

import Cocoa
import PencilKit


let maxLineInterpolationLocationMultiplier : CGFloat = 2.0;


/*
enum LineWorkEntityMode
{
    case bSpline
    case roundedCorner
    case hardCorner
    case hardCornerBowedLine
    case roundedCornerBowedLine
    case arcHardCorner
}*/


// MARK: LINE WORK ENTITY MODE
enum LineWorkEntityMode : String
{
    case idle// = "idle"
    case isInRectangleSelect// = "isInRectangleSelect"
    case isInLinearDrawing// = "isInLinearDrawing"
    case isInMultistateDrawing// = "isInMultistateDrawing"
    case isInNozzleMode//" = "isInNozzleMode"
    case isInInstantTextMode
    /*
    func inDrawingIfNot()
    {
        if(self == .idle)
        {
            self = .inDrawing
        }
    }*/
}

// MARK: NOZZLE MODE
// uses oval, chisel, or uniform cursor and brush tip
enum NozzleMode
{
    case plaster
    // case dotsScreen // dotsScreen substrate
    // case shapeLens // uses warp grid
    // case particleSystem
    // case metaballs
    // case shapeHose
}

// MARK: DOTS SCREEN MODE
enum DotsScreenMode // dotsScreen substrate
{
    case stackBlurShading // shading
    case convexHull // making shapes
}

// var dotsScreenSubstrateDictionary : <String,Any> = [ “distance” : 5, “offsetRows” : true,”,
// “dictionaryOfPoints” : [ “{0,0}” : [“diameter”: 3.0,”colorHSB”: [0.5,0.5,0,5] ] ] ]


// MARK: BOWEDINFO
struct BowedInfo {
    var isFacingA : Bool
    var normalHeight : CGFloat
    var normalHeightIsPercentageOfLineLength : Bool
    var lineInterpolationLocation : CGFloat
    var lineInterpolationLocationMultiplier : CGFloat
    var isArc: Bool
    var makeCornered : Bool
    var corneredAsHard : Bool //String = "none" // rounded, hard
    var lineInterpolationDualDistance : CGFloat
    
    
    init(isFacingA : Bool,normalHeight : CGFloat,normalHeightIsPercentageOfLineLength : Bool,lineInterpolationLocation : CGFloat,lineInterpolationLocationMultiplier : CGFloat,isArc: Bool,makeCornered : Bool, corneredAsHard:Bool, lineInterpolationDualDistance : CGFloat)
    {
        
        self.isFacingA = isFacingA
        self.normalHeight = normalHeight
        self.normalHeightIsPercentageOfLineLength = normalHeightIsPercentageOfLineLength
        self.lineInterpolationLocation = lineInterpolationLocation
        self.lineInterpolationLocationMultiplier = lineInterpolationLocationMultiplier
        self.isArc = isArc
        self.makeCornered = makeCornered
        self.corneredAsHard = corneredAsHard;
        self.lineInterpolationDualDistance = lineInterpolationDualDistance;
        
    }
    
    
    
    init(xmlElement : XMLElement)
    {
        
        // ---fmkr:FMSPBowedInfo
        // isFacingA="true"
        // normalHeight="10.0"
        // normalHeightIsPercentageOfLineLength="true"
        // lineInterpolation="0.5"
        // isArc="false"
    
        self.isFacingA = xmlElement.boolFromAttribute(attributeName: "isFacingA", defaultVal: true)
        
        self.normalHeight = xmlElement.cgFloatFromAttribute(attributeName: "normalHeight", defaultVal: 10);
        
        self.normalHeightIsPercentageOfLineLength = xmlElement.boolFromAttribute(attributeName: "normalHeightIsPercentageOfLineLength", defaultVal: true)
        
        self.lineInterpolationLocation =
            xmlElement.cgFloatFromAttribute(attributeName: "lineInterpolationLocation", defaultVal: 0.5).clamped(to: 0...1.0);
        
        self.lineInterpolationLocationMultiplier =
            xmlElement.cgFloatFromAttribute(attributeName: "lineInterpolationLocationMultiplier", defaultVal: 0.5).clamped(to: 1.0...maxLineInterpolationLocationMultiplier);
        
        self.isArc = xmlElement.boolFromAttribute(attributeName: "isArc", defaultVal: false)
        
        self.makeCornered = xmlElement.boolFromAttribute(attributeName: "makeCornered", defaultVal: false)
        self.corneredAsHard = xmlElement.boolFromAttribute(attributeName: "corneredAsHard", defaultVal: false)

        self.lineInterpolationDualDistance =    xmlElement.cgFloatFromAttribute(attributeName: "lineInterpolationDualDistance", defaultVal: 0).clamped(to: 0...1.0);

    }
    
    func xmlElement() -> XMLElement
    {
        let xmlElementToReturn = XMLElement.init(name: "fmkr:FMSPBowedInfo")
        
        xmlElementToReturn.setAttributesWith(
            
            [
            "isFacingA" : "\(isFacingA)",
             "normalHeight" : "\(normalHeight)",
             "normalHeightIsPercentageOfLineLength" : "\(normalHeightIsPercentageOfLineLength)",
             "lineInterpolationLocation" : "\(lineInterpolationLocation)",
             "lineInterpolationLocationMultiplier" : "\(lineInterpolationLocationMultiplier)",
             "isArc" : "\(isArc)",
             "makeCornered" : "\(makeCornered)",
             "corneredAsHard" : "\(corneredAsHard)",
             "lineInterpolationDualDistance" : "\(lineInterpolationDualDistance)"
            ]
            
        )
        
        return xmlElementToReturn;
        
    }
}

// MARK: LINE WORK INTERACTION ENTITY
class LineWorkInteractionEntity: NSWindowController
{
    @IBOutlet var appDelegate : AppDelegate?
    
    // MARK: OUTLETS FOR MANAGERS
    @IBOutlet var inkAndLineSettingsManager : InkAndLineSettingsManager?
    @IBOutlet var inputInteractionManager : InputInteractionManager?

    var currentMultistateDrawingEntity : DrawingEntity?

    // MARK: OUTLETS FOR DRAWING ENTITIES

    @IBOutlet var shapeInQuadDrawingEntity : ShapeInQuadDrawingEntity?
    @IBOutlet var rectangleDrawingEntity : RectangleDrawingEntity?
    @IBOutlet var ellipseDrawingEntity : EllipseDrawingEntity?


    // MARK: outlets for popover view controllers
    @IBOutlet var shapeKeysConfigPopoverViewController : ShapeKeysConfigPopoverViewController?
    @IBOutlet var uniformFillConfigPopoverViewController : UniformFillConfigPopoverViewController?
    @IBOutlet var noiseConfigurationViewController : NoiseConfigurationViewController?
    @IBOutlet var replicationConfigurationViewController : ReplicationConfigurationViewController?

    @IBOutlet var lineWorkEntityModeLabelForDebug : NSTextField?
    
    var isProcessingDeposit : Bool = false;
    
    var lineWorkEntityMode : LineWorkEntityMode = LineWorkEntityMode.idle
    {
        didSet
        {
            lineWorkEntityModeLabelForDebug?.stringValue = lineWorkEntityMode.rawValue;
        
            if((oldValue == .isInLinearDrawing) && (lineWorkEntityMode == .idle))
            {
                currentAlignmentPoint = NSMakePoint(-1, -1);
                
            }
        
            if((oldValue != .isInLinearDrawing) && (lineWorkEntityMode == .idle))
            {
                showBrushTipCursor = true
                
               
                DispatchQueue.main.async
                {
                    self.activePenLayer?.setupCursor()
                }
                
            }
            
            if((oldValue == .idle) && (lineWorkEntityMode != .isInLinearDrawing))
            {
                showBrushTipCursor = false
                
                DispatchQueue.main.async
                {
                    self.activePenLayer?.setupCursor()
                }
            }
            
            if(lineWorkEntityMode == .isInRectangleSelect)
            {
                if(thereIsCurrentPaperLayer)
                {
                    if(currentPaperLayer!.isCarting)
                    {
                        currentPaperLayer!.cart();
                    }
                }
            }
           
        
        }
    
    }
    
    var allCurrentFMDrawables : [FMDrawable]
    {
        
        return [self.currentFMStroke]//,currentMultistateDrawingEntity!.underlayPathForCurrentMode]
    }
    
    var currentlyDrawnObjectForLineWorkMode : FMDrawable?
    {
        get{
            switch lineWorkEntityMode {
            case .idle:
            return nil;
            case .isInLinearDrawing:
            return self.currentFMStroke
            case .isInMultistateDrawing:
            return currentMultistateDrawingEntity?.currentlyDrawnForState
            
            
            default:
                return nil;
            }
    
        }
        
    }
    
   
    
    
    
    var showBrushTipCursor : Bool = true
    {
        didSet
        {
            activePenLayer?.setNeedsDisplay(activePenLayer!.cursorBezierPath.extendedBezierPathBounds);

        
        }
    }

    
    var currentFMStroke : FMStroke = FMStroke();

    var currentFMDrawable : FMDrawable
    {
        get{
        
            return currentlyDrawnObjectForLineWorkMode ?? currentFMStroke;
        
        }
    
    }

    var currentDrawingPage : DrawingPage?
    {
        get
        {
            return inputInteractionManager?.currentInputDocument?.drawingPage;
        }
    }

    var activePenLayer : ActivePenLayer?
    {
        get{
            return inputInteractionManager?.currentInputDocument?.activePenLayer
        }
    }
    
    
    func redisplayPermanentAnchorPoint()
    {
        if(currentDrawingPage != nil)
        {
            let anchorRect = NSRect.init(origin: .zero, size: NSMakeSize(10, 10)).centerOnPoint(currentDrawingPage!.permanentAnchorPoint);
            currentDrawingPage!.activePenLayer.setNeedsDisplay(anchorRect);
        }
    }
    
    var showAnchorPoint : Bool = false
    {
        didSet
        {
           redisplayPermanentAnchorPoint();
        }
    
    }
    
    // MARK: RECTANGLE SELECT
    var rectangleSelectCornerPointA : NSPoint = .zero;
    var rectangleSelectCornerPointB : NSPoint = .zero;
    var rectangleSelectRect : NSRect = .zero;
    var rectangleSelectRectOld : NSRect = .zero;
    
    func rectangleSelect()
    {
        guard currentPaperLayer != nil else {
            if(lineWorkEntityMode != .idle)
            { escapeCurrentActivityKeyPress() }
            return;
        }
        
        
        if(lineWorkEntityMode == .isInRectangleSelect)
        {
            lineWorkEntityMode = .idle
            
            // --------
            // redisplay area where selection
            // rectangle was on activeLayer
            activePenLayer?.setNeedsDisplay(rectangleSelectRect.union(rectangleSelectRectOld));
        }
        else
        {
            escapeCurrentActivityKeyPress();
            
            lineWorkEntityMode = .isInRectangleSelect
            
            // --------
            // 1. establish first and second point
            // using mouse outside of stream:
            // rectangleSelectCornerPointA
            // rectangleSelectCornerPointB
            rectangleSelectCornerPointA = activePenLayer!.currentPoint;
            rectangleSelectCornerPointB = activePenLayer!.currentPoint;
            rectangleSelectRect = NSRect.init(origin: rectangleSelectCornerPointA, size: CGSize.init(width: 1, height: 1))
            rectangleSelectRectOld = NSRect.init(origin: rectangleSelectCornerPointA, size: CGSize.init(width: 1, height: 1))
             // mouseMoved in lineWorkInteractionEntity (sent by activePenLayer)
            // will now adjust rectangleSelectCornerPointB
            // and tell activePenLayer to redisplay rectangle's region.
            
            // redisplay area where selection
            // rectangle was on activeLayer
            
        }
        
        
    
    }
    
    // MARK: UPDATES TO STROKE AND BRUSH TIP
    /*
    Even though the values are
    derived when needed, if they
    are updated when drawing then
    the stroke won't update until
    the mouse is moved.
     */
    func updateAzimuth(_ azimuth : CGFloat)
    {
        activePenLayer?.reconstructCursorBezierPath();
        
        let oldRect = self.currentFMStroke.renderBounds();
        
        self.currentFMStroke.changeLastPointAzimuth(azimuth)
        
        activePenLayer?.setNeedsDisplay(self.currentFMStroke.renderBounds().union(oldRect));
    }
    
    func updateAltitude(_ altitude : CGFloat)
    {

    }
    


    func updateFMInk(_ fmInk : FMInk)
    {
    
        currentFMStroke.fmInk = fmInk
        
    }
    
    
    
    
    
    func updateBrushTipSize(width : CGFloat,height : CGFloat)
    {
        if(thereIsCurrentPaperLayerWithSelection)
        {
            
        }
        else
        {
            // if drawing, then update
            // the whole stroke or the
            // current point
            // according to settings in inkAndLineSettingsManager
            
            activePenLayer?.reconstructCursorBezierPath();
            
            let oldRect = self.currentFMStroke.renderBounds();
            
            if(inkAndLineSettingsManager!.appliesToEntireStroke == false)
            {
                self.currentFMStroke.changeLastPointBrushTipSize(width:width,height:height);
            }
            else
            {
                self.currentFMStroke.changeAllPointsBrushTipSize(width: width, height: height)
            }
            
            activePenLayer?.setNeedsDisplay(self.currentFMStroke.renderBounds().union(oldRect));
        }
    }
    
    
    // MARK: ALIGNMENT POINTS
    
    var alignmentPoints : [NSPoint] = [];
    
    
    // NEGATIVE IS NO ALIGNMENTPOINT
    var currentAlignmentPoint : NSPoint = NSPoint.init(x: -1, y: -1)
    {
        didSet
        {
            if((currentAlignmentPoint.x >= 0) && (currentAlignmentPoint.y >= 0))
            {
                activePenLayer?.setNeedsDisplay(currentAlignmentPoint.squareForPointWithInradius(inradius: 8));
            }
            
            if((oldValue.x >= 0) && (oldValue.y >= 0))
            {
                activePenLayer?.setNeedsDisplay(oldValue.squareForPointWithInradius(inradius: 8));
            }
        }
    }

    
    func updateAlignmentPoints()
    {
        
    
    }

    
 
    var lastUpdateRect: NSRect = .zero;

    // MARK: MOUSE EVENTS
    override func mouseDown(with event: NSEvent)
    {
          

        
        if(self.lineWorkEntityMode != .isInLinearDrawing)
        {
            guard currentPointInActiveLayer != nil else {
                print("---> mouseDown: currentPointInActiveLayer is nil")
                return;
            }
            
            currentPaperLayer?.mouseDown(with: event)
            
            /*
             let p = currentPointInActiveLayer!
             
             var didSelect : Bool = false;
             for fmStroke in paperLayer!.arrayOfFMDrawables
             {
             
             if(NSPointInRect(p, fmStroke.renderBounds()))
             {
             
             for rBP in fmStroke.liveBezierPathArray
             {
             if(rBP.contains(p))
             {
             didSelect = true
             self.paperLayer?.selectedFMDrawables.append(fmStroke)
             fmStroke.isSelected.toggle();
             fmStroke.fmInk.color = NSColor.white
             
             paperLayer!.setNeedsDisplay(fmStroke.renderBounds())
             return;
             }
             }
             
             
             }
             
             }
             
             if(didSelect == false)
             {
             self.paperLayer?.selectedFMDrawables.removeAll();
             }
             */
            
            
        }
        
    }
    
    
    override func mouseUp(with event: NSEvent)
    {
        
        currentPaperLayer?.mouseUp(with: event)

    }
    
    override func mouseDragged(with event: NSEvent)
    {
            
        currentPaperLayer?.mouseDragged(with: event)

    }

    override func mouseMoved(with event: NSEvent)
    {
        if(inkAndLineSettingsManager!.gridSnapping)
        {
            
            self.currentGridPointHit(testPoint: activePenLayer!.convert(event.locationInWindow, from: nil))
        }
        
        // MARK: isInRectangleSelect
        
        if(self.lineWorkEntityMode == .isInRectangleSelect)
        {
            rectangleSelectRectOld = rectangleSelectRect;
            rectangleSelectCornerPointB = activePenLayer!.currentPoint;
            rectangleSelectRect = NSRect.init(origin: rectangleSelectCornerPointA, size: CGSize.init(width: rectangleSelectCornerPointB.x - rectangleSelectCornerPointA.x , height: rectangleSelectCornerPointB.y - rectangleSelectCornerPointA.y  ))
            
            // If rectangle is negative in width or height,
            // change rectangle.
            if(rectangleSelectRect.size.width < 0)
            {
                rectangleSelectRect.size.width = -1 * rectangleSelectRect.size.width
                rectangleSelectRect.origin.x = rectangleSelectRect.origin.x - rectangleSelectRect.size.width
            }
            
            if(rectangleSelectRect.size.height < 0)
            {
                rectangleSelectRect.size.height = -1 * rectangleSelectRect.size.height
                rectangleSelectRect.origin.y = rectangleSelectRect.origin.y - rectangleSelectRect.size.height
                
            }
            
            DispatchQueue.main.async
            {
                self.currentPaperLayer?.makeSelectedDrawablesFromRect(self.rectangleSelectRect)
            }
            
            
            activePenLayer?.setNeedsDisplay(rectangleSelectRect.union(rectangleSelectRectOld))
        }
        
        // MARK: isInLinearDrawing
        // IS IN LINEAR DRAWING
        if(self.lineWorkEntityMode == .isInLinearDrawing)
        {
            
            
            let oldRect = currentFMStroke.renderBounds()
            
            self.currentFMStroke.changeLastPointIfMoreThanOne(toPoint: self.currentPointInActiveLayer!)
            
            
            
            var rectForUpdate : NSRect = currentFMStroke.renderBounds().union(oldRect)
            
            if(inkAndLineSettingsManager!.showStrokeControlPoints)
            {
                rectForUpdate = rectForUpdate.union(currentFMStroke.controlPointsBoundsForBSpline())
            }
            
            
            self.activePenLayer!.setNeedsDisplay(rectForUpdate.union(self.lastUpdateRect))
            
            self.lastUpdateRect = rectForUpdate

            
        }// END if(self.lineWorkEntityMode == .isInLinearDrawing)
        
        
        
        
        if(self.lineWorkEntityMode == .isInMultistateDrawing)
        {
            
            currentMultistateDrawingEntity!.mouseMoved(with: event)
            
        }
        
        if(inkAndLineSettingsManager!.pointsSnapping && inkAndLineSettingsManager!.pathsSnapping)
        {
            
            DispatchQueue.main.async {
                
                
                
                
                let p = (self.activePenLayer?.currentPoint)!;
                self.currentPointHitTestOnPaperLayerInsideRect(testPoint: p, rect: (self.activePenLayer?.enclosingScrollView?.documentVisibleRect)!);
                if(self.currentPointHit.nsPoint == nil)
                {
                    self.currentPathHitTestOnPaperLayerInsideRect(testPoint: p, rect: (self.activePenLayer?.enclosingScrollView?.documentVisibleRect)!);
                }
            }
            
        }
        else if(inkAndLineSettingsManager!.pointsSnapping)
        {
            
            DispatchQueue.main.async {
                
                
                let p = (self.activePenLayer?.currentPoint)!;
                self.currentPointHitTestOnPaperLayerInsideRect(testPoint: p, rect: (self.activePenLayer?.enclosingScrollView?.documentVisibleRect)!);
                
            }
            
            //            self.lastUpdateRect = rectForUpdate
            //            self.activePenLayer!.setNeedsDisplay(rectForUpdate.union(self.lastUpdateRect))
            
        } // END if(inkAndLineSettingsManager!.pointsSnapping)
        else if(inkAndLineSettingsManager!.pathsSnapping)
        {
            
            DispatchQueue.main.async
            {
                
                
                let p = (self.activePenLayer?.currentPoint)!;
                
                self.currentPathHitTestOnPaperLayerInsideRect(testPoint: p, rect: (self.activePenLayer?.enclosingScrollView?.documentVisibleRect)!);
                
            }// END DispatchQueue.main.async
            
            //            self.lastUpdateRect = rectForUpdate
            //            self.activePenLayer!.setNeedsDisplay(rectForUpdate.union(self.lastUpdateRect))
            
        } // END if(inkAndLineSettingsManager!.pointsSnapping)
        else if(inkAndLineSettingsManager!.alignmentPointLinesSnapping)
        {
            
            DispatchQueue.main.async
            {
                
                
                let p = (self.activePenLayer?.currentPoint)!;
                self.currentAlignmentHitTestOnPaperLayerInsideRect(testPoint: p, rect: (self.activePenLayer?.enclosingScrollView?.documentVisibleRect)!);
                
            }// END DispatchQueue.main.async
            
        
        } // END if(inkAndLineSettingsManager!.alignmentPointLinesSnapping)
        
        if(inkAndLineSettingsManager!.vanishingPointGuides)
        {
            
            DispatchQueue.main.async {
                
                self.updateVPB()
                
            }
            
            
        }
        
        
        // MARK: CARTING, LIVE SCALING, LIVE ROTATION
        if(currentPaperLayer != nil)
        {
            
            if( currentPaperLayer!.shouldReceiveMouseMoved() )
            {
                currentPaperLayer!.mouseMoved(with: event)
            }
        }
        
        // MARK: mousemoved: replicationModeIsOn
        if(inkAndLineSettingsManager!.replicationModeIsOn)
        {
            
            
            
            DispatchQueue.main.async
            {
                topFilter: if((self.lineWorkEntityMode != .idle) && (self.lineWorkEntityMode != .isInRectangleSelect))
                {
                    if(self.lineWorkEntityMode == .isInLinearDrawing)
                    {
                        guard ((self.currentFMStroke.arrayOfFMStrokePoints.count > 1)) else
                        {
                            break topFilter;
                        }
                    }
                    
                    self.replicationConfigurationViewController!.makeReplicationDrawableLiveImage(self.currentFMDrawable)
                    
                    self.activePenLayer!.setNeedsDisplay(self.replicationConfigurationViewController!.calculatedRepetitionBoundsForReplicatedDrawableImg.unionProtectFromZeroRect(self.replicationConfigurationViewController!.calculatedRepetitionBoundsForReplicatedDrawableImgOld))
                    
                }
            }// END DispatchQueue.main.async
            
            
        }// END if(inkAndLineSettingsManager!.replicationModeIsOn)
    }
    
    
  
    func redisplayCurrentlyDrawnObjectForLineWorkMode()
    {
        self.redisplayCurrentFMDrawable();
    }
    
    func redisplayCurrentFMDrawable()
    {
        if(self.lineWorkEntityMode == .isInLinearDrawing)
        {
            let oldRect = currentFMStroke.renderBounds()
            
            self.currentFMStroke.changeLastPointIfMoreThanOne(toPoint: self.currentPointInActiveLayer!)
            
            
            var rectForUpdate : NSRect = currentFMStroke.renderBounds().union(oldRect)
            
            if(inkAndLineSettingsManager!.showStrokeControlPoints)
            {
                rectForUpdate = rectForUpdate.union(currentFMStroke.controlPointsBoundsForBSpline())
            }
            
            
            
            self.activePenLayer!.setNeedsDisplay(rectForUpdate.union(self.lastUpdateRect))
            
            self.lastUpdateRect = rectForUpdate
            
        }
        else if(self.lineWorkEntityMode == .isInMultistateDrawing)
        {
            self.activePenLayer!.setNeedsDisplay(            currentMultistateDrawingEntity!.underlayPathForCurrentMode.bounds)

        
        }
    }
    

    var thereIsCurrentPaperLayerWithNoSelection : Bool
    {
        get {
        
            if((currentPaperLayer != nil) && (currentPaperLayer!.hasSelectedDrawables == false))
            {
                return true
            }
        
            return false
        
        }
    }
    
    var thereIsCurrentPaperLayer : Bool
    {
        get {
        
            if(currentPaperLayer != nil)
            {
            
                return true
            }
        
            return false
        
        }
    }
    
    var thereIsCurrentPaperLayerWithSelection : Bool
    {
        get {
        
            if(currentPaperLayer != nil)
            {
            
                return currentPaperLayer!.hasSelectedDrawables
            }
        
            return false
        
        }
    }
  
    var thereIsCurrentPaperLayerWithSelectionAndModeIsIdle : Bool
    {
        get {
        
            if(currentPaperLayer != nil && (lineWorkEntityMode == .idle))
            {
            
                return currentPaperLayer!.hasSelectedDrawables
            }
        
            return false
        
        }
    }

    var currentPaperLayer : PaperLayer?
    {
        
        return inputInteractionManager?.currentInputDocument?.drawingPage.currentPaperLayer
    }

      var currentNCTDrawingPageController : NCTDrawingPageController?
    {
        
        return inputInteractionManager?.currentInputDocument?.drawingPageController
    }

    
    
var currentPointInActiveLayer : CGPoint?
{
    get{
        
        var currentPoint = self.inputInteractionManager?.currentInputDocument?.activePenLayer.currentPoint;
        
        guard (currentPoint != nil) else {
            print("currentPoint was nil for activeLayer")
            return CGPoint.zero;
        }
        
        if(inkAndLineSettingsManager!.gridSnapping)
        {
            self.currentGridPointHit(testPoint: currentPoint!)
            currentPoint = nearestGridPoint(pointForHitTest: currentPoint!)
        }
        
    
        if(self.lineWorkEntityMode != .idle)
        {
        
           
            if((currentFMStroke.arrayOfFMStrokePoints.count > 1) || ((self.lineWorkEntityMode == .isInMultistateDrawing) && (currentMultistateDrawingEntity!.pointsArrayForCurrentMode.count > 1) ))
            {
               
                
                
                if(inkAndLineSettingsManager!.angleSnapping || inkAndLineSettingsManager!.lengthSnapping || (inkAndLineSettingsManager!.vanishingPointGuides && inkAndLineSettingsManager!.vanishingPointLinesSnapping))
                {
                    
                    var penultimateCGPoint : NSPoint = .zero;
                    
                    if(self.lineWorkEntityMode == .isInLinearDrawing)
                    {
                        penultimateCGPoint = currentFMStroke.penultimateFMStrokePoint()!.cgPoint()
                    }
                    else
                    {
                        penultimateCGPoint = currentMultistateDrawingEntity!.pointsArrayForCurrentMode[currentMultistateDrawingEntity!.pointsArrayForCurrentMode.count - 2];
                    }
                    
                    var lineLength : CGFloat = NSPoint.distanceBetween(penultimateCGPoint, currentPoint!)
                    var angleInRadians : CGFloat = NSBezierPath.lineAngleRadiansFrom(point1: penultimateCGPoint, point2: currentPoint!)
                    
                    
                    
                    if let currDrawingPage = self.currentDrawingPage
                    {
                        
                        if(inkAndLineSettingsManager!.vanishingPointGuides && inkAndLineSettingsManager!.vanishingPointLinesSnapping)
                        {
                            
                            
                            
                            
                            
                            
                            
                            if(inkAndLineSettingsManager!.vanishingPointCount == 2)
                            {
                                
                                let angleInDegrees = NSBezierPath.lineAngleDegreesFrom(point1: penultimateCGPoint, point2: currentPoint!)
                                
                                let anglePadding = inkAndLineSettingsManager!.vanishingPointLinesSnappingAngleRange
                                /// --- right angles
                                if(  ( angleInDegrees >= (90 - anglePadding) ) && ( angleInDegrees <= (90 + anglePadding)
                                ) )
                                {
                                    
                                    angleInRadians = 0.5 * .pi;
                                }
                                
                                else if(  ( angleInDegrees >= (270 - anglePadding) ) && ( angleInDegrees <= (270 + anglePadding)
                                ) )
                                {
                                    
                                    angleInRadians = 1.5 * .pi;
                                }
                                
                                
                                let angleInRadiansVanishingPointA = NSBezierPath.lineAngleRadiansFrom(point1: penultimateCGPoint, point2: currDrawingPage.vanishingPointA)
                                let angleInRadiansVanishingPointB = NSBezierPath.lineAngleRadiansFrom(point1: penultimateCGPoint, point2: currDrawingPage.vanishingPointB)
                                let angleInRadiansVanishingPointAConvertedToDegrees = rad2deg(angleInRadiansVanishingPointA);
                                let angleInRadiansVanishingPointBConvertedToDegrees = rad2deg(angleInRadiansVanishingPointB);
                                
                                
                                if(( angleInRadiansVanishingPointAConvertedToDegrees >= (angleInDegrees - anglePadding) ) && ( angleInRadiansVanishingPointAConvertedToDegrees <= (angleInDegrees + anglePadding)))
                                {
                                    
                                    angleInRadians = angleInRadiansVanishingPointA
                                    
                                }
                                
                                if(( angleInRadiansVanishingPointAConvertedToDegrees - 180 >= (angleInDegrees - anglePadding) ) && ( angleInRadiansVanishingPointAConvertedToDegrees - 180 <= (angleInDegrees + anglePadding)))
                                {
                                    
                                    angleInRadians = angleInRadiansVanishingPointA + .pi
                                    
                                }
                                
                                if(( angleInRadiansVanishingPointBConvertedToDegrees >= (angleInDegrees - anglePadding) ) && ( angleInRadiansVanishingPointBConvertedToDegrees <= (angleInDegrees + anglePadding)))
                                {
                                    angleInRadians = angleInRadiansVanishingPointB
                                }
                                
                                if(( angleInRadiansVanishingPointBConvertedToDegrees - 180 >= (angleInDegrees - anglePadding) ) && ( angleInRadiansVanishingPointBConvertedToDegrees - 180 <= (angleInDegrees + anglePadding)))
                                {
                                    angleInRadians = angleInRadiansVanishingPointB + .pi;
                                }
                                
                            }
                            
                        }
                        
                    }//  END if let currDrawingPage = self.currentDrawingPage
                    
                    if(inkAndLineSettingsManager!.lengthSnapping == true)
                    {
                        let lengthDistance = inkAndLineSettingsManager!.lengthSnappingInterval;
                        
                        if(lengthDistance > 0)
                        {
                            let roundedLength = round(lineLength);
                            let roundedLengthDistance = round(lengthDistance);
                            let lengthMod = ( Int(roundedLength) % Int(roundedLengthDistance));
                            lineLength = roundedLength - CGFloat(lengthMod);
                        }
                    }
                    
                    
                    if(inkAndLineSettingsManager!.angleSnapping == true)
                    {
                        
                        
                        let angleInDegrees = NSBezierPath.lineAngleDegreesFrom(point1: penultimateCGPoint, point2: currentPoint!)
                        
                        let angleSpacing = inkAndLineSettingsManager!.angleSnappingInterval
                        
                        let roundedAngle : Int = Int( round(angleInDegrees) );
                        
                        let roundedAngleMod : Int = ( roundedAngle % Int(angleSpacing));
                        
                        let angleSnappingLockAngle = CGFloat(roundedAngle - roundedAngleMod);
                        
                        angleInRadians = angleSnappingLockAngle * (3.14159265 / 180 );
                        
                        
                        
                    } // END if(inkAndLineSettingsManager!.angleSnapping == true)
                    
                    
                    let firstPoint = penultimateCGPoint
                    var newSecondPoint = NSPoint.zero;
                    newSecondPoint.x = firstPoint.x + (lineLength * cos(angleInRadians));
                    newSecondPoint.y =  firstPoint.y + (lineLength * sin(angleInRadians));
                    currentPoint = newSecondPoint;
                    
                }
                
                
                
                if(lineWorkEntityMode == .isInLinearDrawing)
                {
                    
                    if(inkAndLineSettingsManager!.alignmentPointLinesSnapping == true)
                    {
                            //if( currentFMStroke.firstFMStrokePoint() )
                        currentAlignmentPoint = NSMakePoint(-1, -1)
                        if(currentFMStroke.fmInk.brushTip.isUniform)
                        {
                            if(currentFMStroke.firstPoint().distanceFrom(point2: currentPoint!) > 10)
                            {
                                if(currentPoint!.sitsOnXOfPoint(currentFMStroke.firstPoint(), padding: 3))
                                {
                                    currentAlignmentPoint = currentFMStroke.firstPoint()
                                    currentPoint!.x = currentFMStroke.firstPoint().x
                                }
                                
                                if(currentPoint!.sitsOnYOfPoint(currentFMStroke.firstPoint(), padding: 3))
                                {
                                    currentAlignmentPoint = currentFMStroke.firstPoint()
                                    
                                    currentPoint!.y = currentFMStroke.firstPoint().y
                                }
                            }
                        }
                        
                    } // END if(inkAndLineSettingsManager!.alignmentPointLinesSnapping == true)
                    
                }
                

                
                
            }// END if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        }// END if(self.lineWorkEntityMode != .idle)
        
        
        if(inkAndLineSettingsManager!.pointsSnapping == true)
        {
            if(currentPointHit.nsPoint != nil)
            {
                
                currentPoint = currentPointHit.nsPoint!
                
                
            }
            
        }// END if(inkAndLineSettingsManager!.pointsSnapping == true)
        
        if(inkAndLineSettingsManager!.pathsSnapping == true)
        {
            if(currentPointHit.nsPoint != nil)
            {
                
                currentPoint = currentPointHit.nsPoint!
                
                
            }
            
        }// END if(inkAndLineSettingsManager!.pointsSnapping == true)
               
        
        
        return currentPoint
    } // END get
}// END var
    
    
    
    
   
    func stampCurrentVanishingPointGuidelines()
    {
        guard inkAndLineSettingsManager!.vanishingPointGuides else
        {
            return;
        }
        
        guard let currDrawingPage = currentDrawingPage else
        {
            return;
        }
        
        guard let currPtAL = self.currentPointInActiveLayer else
        {
            
            return
        }
        currDrawingPage.stampCurrentVanishingPointGuidelines(currentPointInActiveLayer: currPtAL)
    
    
        
    }
    
    func updateVPB()
    {
      guard inkAndLineSettingsManager!.vanishingPointGuides else {
            return;
        }
        
          guard let currDrawingPage = currentDrawingPage else {
            return;
        }
        
        
        guard  let currentPtInActiveLayer = self.currentPointInActiveLayer else {
            return
        }
        
        currDrawingPage.updateVPB(currentPointInActiveLayer: currentPtInActiveLayer)
        
        
        
    }
    
    func clearVanishingPointLines()
    {
        if(currentDrawingPage != nil)
        {
            currentDrawingPage!.clearVanishingPointLines();
        }
        
    }

    var currentPointHit : (nsPoint: NSPoint?,pkStrokePoint:PKStrokePoint?,pkStrokePath:PKStrokePath?) = (nil,nil,nil);
    var currentPointHitPath : NSBezierPath?
    
    var lastUpdateRectForCurrentPointHitPath = NSRect.zero;
    
    func currentPointHitTestOnPaperLayerInsideRect(testPoint:NSPoint, rect:NSRect)
    {
    
        guard rect.contains(testPoint) else {
            currentPointHit.nsPoint = nil;
            currentPointHit.pkStrokePoint = nil;
            currentPointHit.pkStrokePath = nil;
            
            return;
        }
        
        //--------------
        // first check if the first
        // point of the path is hit
        if(lineWorkEntityMode == .isInLinearDrawing)
        {
            if(currentFMStroke.arrayOfFMStrokePoints.count > 3)
            {
                
                let pk = currentFMStroke.pkStrokePathAcc()
                
                let firstPoint = pk.interpolatedPoint(at: 0 )
                //let interpPoint = pk.interpolatedPoint(at: CGFloat(pk.endIndex - 1) )
                
                let r = NSMakeRect(0, 0, 5, 5).centerOnPoint(firstPoint.location)
                
                
                if(r.contains(testPoint))
                {
                    
                    currentPointHit.nsPoint = firstPoint.location
                    currentPointHit.pkStrokePoint = firstPoint
                    // currentPointHit.pkStrokePath =
                    
                    currentPointHitPath = NSBezierPath();
                    let r = NSRect.init(x: 0, y: 0, width: 10, height: 10).centerOnPoint(currentPointHit.nsPoint!);
                    currentPointHitPath?.appendRect( r)
                    currentPointHitPath?.appendRect( r.insetBy(dx: -5, dy: -5))


                    let updateRectFromBounds = currentPointHitPath!.bounds.insetBy(dx: -5, dy: -5);
                    if(lastUpdateRectForCurrentPointHitPath == .zero)
                    {
                        lastUpdateRectForCurrentPointHitPath = updateRectFromBounds
                    }
                    self.activePenLayer?.setNeedsDisplay(updateRectFromBounds.union(lastUpdateRectForCurrentPointHitPath))
                    lastUpdateRectForCurrentPointHitPath = updateRectFromBounds
                    
                    return;
                    
                }
                
            }
            
            
        }
        
        // test the strokes in the paperLayer
        for fmDrawable in currentPaperLayer!.orderingArray
        {
            let rB = fmDrawable.renderBounds();
         
            if( rect.intersects(rB) || rect.contains(rB) )
            {
                if(NSPointInRect(testPoint, fmDrawable.renderBounds()))
                {
                
                    let result = fmDrawable.pointHitTest(point: testPoint)
                    if(result.didHit)
                    {
                        currentPointHit.nsPoint = result.cgPoint;
                        currentPointHit.pkStrokePoint = result.pkStrokePoint;
                        // currentPointHit.pkStrokePath =
                        
                        
                        currentPointHitPath = NSBezierPath();
                        let r = NSRect.init(x: 0, y: 0, width: 10, height: 10).centerOnPoint(currentPointHit.nsPoint!);
                        currentPointHitPath?.appendRect( r)
                        currentPointHitPath?.appendRect( r.insetBy(dx: -5, dy: -5))

                        let updateRectFromBounds = currentPointHitPath!.bounds.insetBy(dx: -5, dy: -5);
                        if(lastUpdateRectForCurrentPointHitPath == .zero)
                        {
                            lastUpdateRectForCurrentPointHitPath = updateRectFromBounds
                        }
                        self.activePenLayer?.setNeedsDisplay(updateRectFromBounds.union(lastUpdateRectForCurrentPointHitPath))
                        lastUpdateRectForCurrentPointHitPath = updateRectFromBounds

                        return;
                    }
                }
            }
            
        }
   
        currentPointHit.nsPoint = nil;
        currentPointHit.pkStrokePoint = nil;
        currentPointHit.pkStrokePath = nil;
        // clear out area of old path
        if(currentPointHitPath != nil)
        {
            let oldRect = currentPointHitPath!.bounds.insetBy(dx: -8, dy: -8)
            currentPointHitPath = nil;
            self.activePenLayer?.setNeedsDisplay(oldRect)
            
        }
        
    }

    func currentGridPointHit(testPoint:NSPoint)
    {
        let gridPoint = nearestGridPoint(pointForHitTest: testPoint)
        
        currentPointHit.nsPoint = gridPoint;
        currentPointHit.pkStrokePoint = nil;
        // currentPointHit.pkStrokePath =
        currentPointHitPath = NSBezierPath();
        currentPointHitPath?.appendRect( NSRect.init(x: 0, y: 0, width: 10, height: 10).centerOnPoint(currentPointHit.nsPoint!) )
        currentPointHitPath?.appendRect( NSRect.init(x: 0, y: 0, width: 20, height: 20).centerOnPoint(currentPointHit.nsPoint!) )
        currentPointHitPath?.move(to: currentPointHit.nsPoint!.offsetBy(x: 10, y: 0))
        currentPointHitPath?.line(to: currentPointHit.nsPoint!.offsetBy(x: -10, y: 0))
        currentPointHitPath?.move(to: currentPointHit.nsPoint!.offsetBy(x: 0, y: 10))
        currentPointHitPath?.line(to: currentPointHit.nsPoint!.offsetBy(x: 0, y: -10))


        let updateRectFromBounds = currentPointHitPath!.bounds.insetBy(dx: -8, dy: -8);
        if(lastUpdateRectForCurrentPointHitPath == .zero)
        {
            lastUpdateRectForCurrentPointHitPath = updateRectFromBounds
        }
        self.activePenLayer?.setNeedsDisplay(updateRectFromBounds.union(lastUpdateRectForCurrentPointHitPath))
        lastUpdateRectForCurrentPointHitPath = updateRectFromBounds
    }
    
    func currentAlignmentHitTestOnPaperLayerInsideRect(testPoint:NSPoint, rect:NSRect)
    {
        
    }
    
    
    func currentPathHitTestOnPaperLayerInsideRect(testPoint:NSPoint, rect:NSRect)
    {
        for fmDrawable in currentPaperLayer!.orderingArray
        {
        
            if(rect.intersects(fmDrawable.renderBounds()))
            {
                if(NSPointInRect(testPoint, fmDrawable.renderBounds()))
                {
                
                    if(fmDrawable.isEmpty == false)
                    {
                            
                            // at this point, check to see if there is a hit
                            // on any of the path segments of the drawable
                            var positionFloat : CGFloat = 0.0;
                            var hitSegment : Int32 = 0;
                            
                            // use Omni util's segmentHit for NSBezierPath
                            // to check if a segment was hit
                            hitSegment = Int32(fmDrawable.segmentHit(by: testPoint, position: &positionFloat, padding: 5))
                            
                        if(hitSegment > 0)
                        {
                        
                            
                            
                            var bPPosition : OABezierPathPosition! = OABezierPathPosition()
                            
                            bPPosition.segment = NSBezierPathSegmentIndex(hitSegment);
                            bPPosition.parameter = Double(positionFloat);
                            
                            currentPointHit.nsPoint = fmDrawable.getPointFor(bPPosition)
                            
                            currentPointHit.pkStrokePoint = PKStrokePoint.init(location: currentPointHit.nsPoint!, timeOffset: 0, size: .zero, opacity: 1.0, force: 1.0, azimuth: 1, altitude: 1);
                        
                            
                            
                            currentPointHitPath = NSBezierPath();
                            currentPointHitPath?.appendOval(in: NSRect.init(x: 0, y: 0, width: 10, height: 10).centerOnPoint(currentPointHit.nsPoint!) )
                            currentPointHitPath?.appendOval(in: NSRect.init(x: 0, y: 0, width: 20, height: 20).centerOnPoint(currentPointHit.nsPoint!) )
                            
                            let updateRectFromBounds = currentPointHitPath!.bounds.insetBy(dx: -8, dy: -8);
                            if(lastUpdateRectForCurrentPointHitPath == .zero)
                            {
                                lastUpdateRectForCurrentPointHitPath = updateRectFromBounds
                            }
                            self.activePenLayer?.setNeedsDisplay(updateRectFromBounds.union(lastUpdateRectForCurrentPointHitPath))
                            lastUpdateRectForCurrentPointHitPath = updateRectFromBounds
                            
                            return;
                        }
                    }
                
                    /*
                    let result = fmDrawable.pathHitTest(point: testPoint)
                    if(result.didHit)
                    {
                        currentPointHit.nsPoint = result.cgPoint;
                        currentPointHit.pkStrokePoint = result.pkStrokePoint;
                        // currentPointHit.pkStrokePath =
                        
                        currentPointHitPath = NSBezierPath();
                        currentPointHitPath?.appendOval(in: NSRect.init(x: 0, y: 0, width: 10, height: 10).centerOnPoint(currentPointHit.nsPoint!) )
                        currentPointHitPath?.appendOval(in: NSRect.init(x: 0, y: 0, width: 20, height: 20).centerOnPoint(currentPointHit.nsPoint!) )
                        
                           let updateRectFromBounds = currentPointHitPath!.bounds.insetBy(dx: -8, dy: -8);
                        if(lastUpdateRectForCurrentPointHitPath == .zero)
                        {
                            lastUpdateRectForCurrentPointHitPath = updateRectFromBounds
                        }
                        self.activePenLayer?.setNeedsDisplay(updateRectFromBounds.union(lastUpdateRectForCurrentPointHitPath))
                        lastUpdateRectForCurrentPointHitPath = updateRectFromBounds

                        return;
                    }
                    */
                    
                }
            }
        }
        
        

        
        currentPointHit.nsPoint = nil;
        currentPointHit.pkStrokePoint = nil;
        currentPointHit.pkStrokePath = nil;
        lastUpdateRectForCurrentPointHitPath = .zero;
        if(currentPointHitPath != nil)
        {
            let oldRect = currentPointHitPath!.bounds.insetBy(dx: -8, dy: -8)
            currentPointHitPath = nil;
            self.activePenLayer?.setNeedsDisplay(oldRect)
            
        }
        
    }
    
    


  

    //  MARK: ----FMSTROKE KEY PRESSES

    func bSplineKeyPress()
    {
    
        if(lineWorkEntityMode == .isInMultistateDrawing)
        {
            escapeCurrentActivityKeyPress();
        }
    
        guard currentPointInActiveLayer != nil else {
            return
        }
    
        // before depositing a new bSpline point,
        // change the last point (the moving mouse point)
        // to .bSpline.
        if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        {
            ifLastPointIsArcByThreeP2ThenAddFMSPt(fmStrokePointType: FMStrokePointType.bSpline)
            /*
            if(  currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType == FMStrokePointType.roundedCornerBowedLine)
            {
            
            }*/
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = FMStrokePointType.bSpline
        }

        currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.bSpline, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
        
               
        // if only one point is added when the count is zero, then when the
        // mouse moves there won't be a point to change as the last point.
        if(self.lineWorkEntityMode == .idle)
        {
            self.lineWorkEntityMode = .isInLinearDrawing
            addExtraPoint()
        }
        
    
    }

    func roundedBSplineCornerKeyPress()
    {
    
        if(lineWorkEntityMode == .isInMultistateDrawing)
        {
            escapeCurrentActivityKeyPress();
        }

        guard currentPointInActiveLayer != nil else
        {
            return
        }
        
        // before depositing a new bSpline point,
        // change the last point (the moving mouse point)
        // to .roundedCorner instead of bSpline, which is what
        // it currently always is for the last point.
      
        if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        {
            ifLastPointIsArcByThreeP2ThenAddFMSPt(fmStrokePointType:FMStrokePointType.roundedCorner)
        
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = FMStrokePointType.roundedCorner
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].roundedCornerSegmentLength = inkAndLineSettingsManager!.cornerRounding;
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].cornerRoundingType = inkAndLineSettingsManager!.cornerRoundingType

        }
        
        currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.roundedCorner, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
        
        if(self.lineWorkEntityMode == .idle)
        {
            self.lineWorkEntityMode = .isInLinearDrawing
            addExtraPoint()
        }
        
    }
    
    // MARK: ARC BY THREE POINTS
    
    func ifLastPointIsArcByThreeP2ThenAddFMSPt(fmStrokePointType:FMStrokePointType)
    {
        if(currentFMStroke.arrayOfFMStrokePoints.count > 2)
        {
            if(currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType == .arcByThreeP2)
            {
            currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: fmStrokePointType, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: 0, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor);
            
//                return true
            }
        }
        
//        return false
    
    }
    
    func arcByThreePointsKeyPress()
    {
        if(lineWorkEntityMode == .isInMultistateDrawing)
        {
            escapeCurrentActivityKeyPress();
        }
        
        guard currentPointInActiveLayer != nil else {
            return
        }
        

        
        if(currentFMStroke.arrayOfFMStrokePoints.count == 0)
        {
            currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.hardCorner, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: 0, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor);
            
               currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.arcByThreeP1, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: 0, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
        }
        else if(currentFMStroke.arrayOfFMStrokePoints.count == 1)
        {
            currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.arcByThreeP1, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: 0, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
            
        }
        // before depositing a new bSpline point,
        // change the last point (the moving mouse point)
        // to .hardCorner instead of bSpline, which is what
        // it currently always is for the last point.
        else if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        {
        // if the current last point is not arcByThreeP1
            
            
            if(currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType == FMStrokePointType.arcByThreeP1)
            {
             currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.arcByThreeP2, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: 0, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
            }
            else
            if(currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType != FMStrokePointType.arcByThreeP2)
            {
            
             currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.hardCorner, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: 0, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor);
            currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.arcByThreeP1, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: 0, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
            
           // currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = FMStrokePointType.arcByThreeP1;
            
            /*
            currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.arcByThreeP2, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: 0, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)*/
            
            /*
                currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.arcByThreeP2, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: 0, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
                */
            }
            
            else if(currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType == FMStrokePointType.arcByThreeP2)
            {
                currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.hardCorner, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: 0, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor);
                
                currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.arcByThreeP1, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: 0, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
                
            }
            
        }
        
        if(self.lineWorkEntityMode == .idle)
        {
            self.lineWorkEntityMode = .isInLinearDrawing
            
            
        }
        
    }
    
    // MARK: BOWED KEY PRESSES
    func hardBSplineCornerBowedLineKeyPress()
    {
        
        if(lineWorkEntityMode == .isInMultistateDrawing)
        {
            escapeCurrentActivityKeyPress();
        }
        
        guard currentPointInActiveLayer != nil else {
            return
        }
        
     
        
        let bowedInfo =
        inkAndLineSettingsManager!.bowedInfoAssembledWithFacingA(facingA:true)
            
        // before depositing a new bSpline point,
        // change the last point (the moving mouse point)
        // to .hardCornerBowedLine instead of bSpline, which is what
        // it currently always is for the last point.
        if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        {
        
            ifLastPointIsArcByThreeP2ThenAddFMSPt(fmStrokePointType: .hardCorner)
        
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = FMStrokePointType.hardCornerBowedLine
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].bowedInfo = bowedInfo;
        }
    
      if(currentFMStroke.arrayOfFMStrokePoints.count == 0)
        {
               currentFMStroke.addBowedFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.hardCornerBowedLine, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, bowedInfo: bowedInfo)
      
        }
        else
        {
      currentFMStroke.addBowedFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.hardCornerBowedLine, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, bowedInfo: bowedInfo)
      
      }
      
        if(self.lineWorkEntityMode == .idle)
        {
            self.lineWorkEntityMode = .isInLinearDrawing
            addExtraPoint()
        }
    }
    
    
    func roundedBSplineCornerBowedLineKeyPress()
    {
        if(lineWorkEntityMode == .isInMultistateDrawing)
        {
            escapeCurrentActivityKeyPress();
        }
    
        guard currentPointInActiveLayer != nil else
        {
            return
        }
        
               let bowedInfo = inkAndLineSettingsManager!.bowedInfoAssembledWithFacingA(facingA: true)
            
        // before depositing a new bSpline point,
        // change the last point (the moving mouse point)
        // to .roundedCornerBowedLine instead of bSpline, which is what
        // it currently always is for the last point.
        if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        {
            ifLastPointIsArcByThreeP2ThenAddFMSPt(fmStrokePointType: FMStrokePointType.roundedCorner)
        
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = FMStrokePointType.roundedCornerBowedLine
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].bowedInfo = bowedInfo;
             currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].roundedCornerSegmentLength = inkAndLineSettingsManager!.cornerRounding;
             currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].cornerRoundingType = inkAndLineSettingsManager!.cornerRoundingType
        }

        if(currentFMStroke.arrayOfFMStrokePoints.count == 0)
        {
               currentFMStroke.addBowedFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.roundedCornerBowedLine, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, bowedInfo: bowedInfo)
      
        }
        else
        {
      currentFMStroke.addBowedFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.roundedCornerBowedLine, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, bowedInfo: bowedInfo)
      
     // currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.bSpline, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize)
    }
        
   
        if(self.lineWorkEntityMode == .idle)
        {
            self.lineWorkEntityMode = .isInLinearDrawing
            addExtraPoint()
        }
    
    }
    
    func roundedBSplineCornerBowedLineFacingBKeyPress()
    {
        if(lineWorkEntityMode == .isInMultistateDrawing)
        {
            escapeCurrentActivityKeyPress();
        }
        
        guard currentPointInActiveLayer != nil else {
            return
        }
        
              let bowedInfo = inkAndLineSettingsManager!.bowedInfoAssembledWithFacingA(facingA: false)
            
        // before depositing a new bSpline point,
        // change the last point (the moving mouse point)
        // to .roundedCornerBowedLine instead of bSpline, which is what
        // it currently always is for the last point.
        if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        {
            ifLastPointIsArcByThreeP2ThenAddFMSPt(fmStrokePointType: .roundedCorner)
            
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = FMStrokePointType.roundedCornerBowedLine
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].bowedInfo = bowedInfo;
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].roundedCornerSegmentLength = inkAndLineSettingsManager!.cornerRounding;
             currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].cornerRoundingType = inkAndLineSettingsManager!.cornerRoundingType

        }

        if(currentFMStroke.arrayOfFMStrokePoints.count == 0)
        {
               currentFMStroke.addBowedFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.roundedCornerBowedLine, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, bowedInfo: bowedInfo)
      
        }
        else
        {
      currentFMStroke.addBowedFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.roundedCornerBowedLine, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, bowedInfo: bowedInfo)
      
     // currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.bSpline, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize)
    }
        
   
        if(self.lineWorkEntityMode == .idle)
        {
            self.lineWorkEntityMode = .isInLinearDrawing
            addExtraPoint()
        }
    

    }
    

    func hardBSplineCornerBowedLineFacingBKeyPress()
    {
    
        if(lineWorkEntityMode == .isInMultistateDrawing)
        {
            escapeCurrentActivityKeyPress();
        }
        
        guard currentPointInActiveLayer != nil else
        {
            return
        }
        
        let bowedInfo = inkAndLineSettingsManager!.bowedInfoAssembledWithFacingA(facingA: false)
    
    
        // before depositing a new bSpline point,
        // change the last point (the moving mouse point)
        // to .hardCornerBowedLine instead of bSpline, which is what
        // it currently always is for the last point.
        if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        {
            ifLastPointIsArcByThreeP2ThenAddFMSPt(fmStrokePointType: .hardCorner)
        
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = FMStrokePointType.hardCornerBowedLine
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].bowedInfo = bowedInfo;
        }
    
      if(currentFMStroke.arrayOfFMStrokePoints.count == 0)
        {
               currentFMStroke.addBowedFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.hardCornerBowedLine, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, bowedInfo: bowedInfo)
      
        }
        else
        {
      currentFMStroke.addBowedFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.hardCornerBowedLine, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, bowedInfo: bowedInfo)
      
      }
      
        if(self.lineWorkEntityMode == .idle)
        {
            self.lineWorkEntityMode = .isInLinearDrawing
            addExtraPoint()
        }
    }

    func escapeCurrentActivityKeyPress()
    {
        if(thereIsCurrentPaperLayerWithSelection)
        {
            currentPaperLayer?.clearOutSelections()
            
        }
        
        if(lineWorkEntityMode == .isInLinearDrawing)
        {
            lineWorkEntityMode = .idle
            let oldRect = currentFMStroke.renderBounds()
            currentFMStroke.arrayOfFMStrokePoints.removeAll();
            currentFMStroke.pkStrokePathCached = nil;
            self.activePenLayer?.setNeedsDisplay(oldRect)
        
            
        }
        if(lineWorkEntityMode == .isInMultistateDrawing)
        {
            lineWorkEntityMode = .idle
            currentMultistateDrawingEntity?.resetDrawingEntity()
        }
    
        if(lineWorkEntityMode == .isInRectangleSelect)
        {
            rectangleSelect();
        }
        
        
        if(inkAndLineSettingsManager!.replicationModeIsOn)
        {
            activePenLayer?.setNeedsDisplay(replicationConfigurationViewController!.calculatedRepetitionBoundsForReplicatedDrawableImg.unionProtectFromZeroRect(replicationConfigurationViewController!.calculatedRepetitionBoundsForReplicatedDrawableImgOld));
            replicationConfigurationViewController!.replicationDrawableLiveUnitOfReplicImage = nil;
            
        }
    
    }
    
    
    
    func makeNewCurrentFMStroke()
    {
    
    }
    
    // MARK: RAW DEPOSITS ONTO CURRENT PAPERLAYER
    func rawFMDrawableDepositOntoCurrentPaperLayer(fmDrawableToDeposit: FMDrawable, undoMessage:String)
    {
            self.inputInteractionManager?.currentInputDocument?.drawingPage.currentPaperLayer.addFMDrawable(fmDrawableToDeposit, doBackgroundThread : true)
            let oldPkStrokeRect = fmDrawableToDeposit.renderBounds()
            self.activePenLayer?.setNeedsDisplay(oldPkStrokeRect)
    }
    
    func rawFMStrokeDepositOntoCurrentPaperLayer(fmStrokeToDeposit: FMStroke,isCurrentFMStroke:Bool, undoMessage:String)
    {
        if(isCurrentFMStroke)
        {
            self.inputInteractionManager?.currentInputDocument?.drawingPage.currentPaperLayer.addFMDrawable(self.currentFMStroke, doBackgroundThread : true)
            let oldPkStrokeRect = self.currentFMStroke.renderBounds()
            self.currentFMStroke = FMStroke()
            syncCurrentFMDrawableToInkSettings()
            self.activePenLayer?.setNeedsDisplay(oldPkStrokeRect)
            self.lineWorkEntityMode = .idle
        }
        else
        {
            self.inputInteractionManager?.currentInputDocument?.drawingPage.currentPaperLayer.addFMDrawable(fmStrokeToDeposit, doBackgroundThread : true)
            let oldPkStrokeRect = fmStrokeToDeposit.renderBounds()
            self.activePenLayer?.setNeedsDisplay(oldPkStrokeRect)
        }
    }

    func endKeyPress()
    {
        guard (lineWorkEntityMode != .idle) else
        {
            return
        }
        
        if(lineWorkEntityMode == .isInLinearDrawing)
        {
            
            
            if(self.inkAndLineSettingsManager!.vanishingPointGuides)
            {
                self.stampCurrentVanishingPointGuidelines();
            }
            
            self.lineWorkEntityMode = .idle;
            
            var oldPkStrokeRect = self.currentFMStroke.renderBounds()
            if(self.inkAndLineSettingsManager!.showStrokeControlPoints)
            {
                oldPkStrokeRect = oldPkStrokeRect.union(self.currentFMStroke.controlPointsBoundsForBSpline())
            }
            
            if(self.inkAndLineSettingsManager!.replicationModeIsOn)
            {
                oldPkStrokeRect = oldPkStrokeRect.union(self.replicationConfigurationViewController!.calculatedRepetitionBoundsForReplicatedDrawableImg)
            }
            
            
            addDrawableToCurrentLayer(self.currentFMStroke, doBackgroundThread : true)
            
            
            self.currentFMStroke = FMStroke.init()
            syncCurrentFMDrawableToInkSettings()
            
            if(self.inkAndLineSettingsManager!.fmInk.brushTip.isUniform)
            {
                self.activePenLayer?.reconstructCursorBezierPath()
            }
            
            self.activePenLayer?.setNeedsDisplay(oldPkStrokeRect)
        }
        
        
        
        if(lineWorkEntityMode == .isInMultistateDrawing)
        {
            currentMultistateDrawingEntity?.end();
            
        
        }
        
    }
    
    func addDrawableToCurrentLayer(_ drawable : FMDrawable, doBackgroundThread: Bool)
    {
        guard let currPaperLayer = currentPaperLayer else { return  }
        
        if(currPaperLayer.isHidden)
        {
            currPaperLayer.isHidden.toggle()
        }



        // UNION WITH LAST DRAWN SHAPE
        if(inkAndLineSettingsManager!.unionWithLastDrawnShapeForDrawing)
        {
        
            if(currPaperLayer.orderingArray.isEmpty == false)
            {
                let lastDrawn = currPaperLayer.orderingArray.last!;
                if(drawable.renderBounds().intersects(lastDrawn.renderBounds()))
                {
                    if let s = drawable as? FMStroke
                    {
                        // process before doing anything
                        currPaperLayer.doProcessingOfFMStroke(fmStroke: s, doBackgroundThread: false)
                    }
                    
                    if(pathsIntersect(path1: lastDrawn, path2: drawable))
                    {
                        currPaperLayer.addDrawableByUnion(drawable, toLastDrawnOnly:true)
                        return;
                    }
                }
            }
            
            // fallthrough without return:
            currPaperLayer.addFMDrawable(drawable, doBackgroundThread: true)

            
        }
        else if(inkAndLineSettingsManager!.combinatoricsModeIsOn == false)
        {
            if(inkAndLineSettingsManager!.shadingShapesModeIsOn)
            {
                currPaperLayer.addDrawableAsShadingShape(drawable)
                return;
            }
            else
            {
               isProcessingDeposit = true;
                currPaperLayer.addFMDrawable(drawable, doBackgroundThread: true)
            }
        }
        else
        {
            if(inkAndLineSettingsManager!.combinatoricsModeIsOn)
            {
                
                switch inkAndLineSettingsManager!.combinatoricsMode
                {
                case .intersection:
                    currPaperLayer.addDrawableByIntersection(drawable)
                case .union:
                    currPaperLayer.addDrawableByUnion(drawable, toLastDrawnOnly:false)
                case .subtraction:
                    currPaperLayer.addDrawableBySubtraction(drawable)
                }
            }
            
        }
        
    }
    
    
    func syncCurrentFMDrawableToInkSettings()
    {
        /*
        if var d = self.currentlyDrawnObjectForLineWorkMode
        {
           
        }*/
        
        for d in allCurrentFMDrawables
        {
            var e = d;
            self.inkAndLineSettingsManager!.aggregatedSetting.applyToDrawable(fmDrawable: &e)
            
            self.currentFMStroke.fmInk = self.inkAndLineSettingsManager!.fmInk;
            self.currentFMStroke.fmInk.paintFillMode = self.inkAndLineSettingsManager!.paintFillModeCurrent;
            self.currentFMStroke.lineWidth = self.inkAndLineSettingsManager!.bezierPathStrokeWidthCurrent;
        }
        
        
    }
    
    func hardBSplineCornerKeyPress()
    {
    
        if(lineWorkEntityMode == .isInMultistateDrawing)
        {
            escapeCurrentActivityKeyPress();
        }
        
        guard currentPointInActiveLayer != nil else
        {
            return
        }
        
        if(inkAndLineSettingsManager!.vanishingPointGuides)
        {
            stampCurrentVanishingPointGuidelines();
        }
        
        // before depositing a new bSpline point,
        // change the last point (the moving mouse point)
        // to .hardCorner instead of bSpline, which is what
        // it currently always is for the last point.
        if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        {
            
            ifLastPointIsArcByThreeP2ThenAddFMSPt(fmStrokePointType: .hardCorner)
            
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = FMStrokePointType.hardCorner
        }
        
        currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.bSpline, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
        
        if(self.lineWorkEntityMode == .idle)
        {
            self.lineWorkEntityMode = .isInLinearDrawing
            addExtraPoint()
        }
        
    }
    
    func addExtraPoint()
    {
        //if(currentFMStroke.arrayOfFMStrokePoints.count == 1)
        //{
                currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.bSpline, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
                
                redisplayCurrentFMDrawable();
                
        //}
        
    }
    
    
    
    
  
    func stampSelectedObjects()
    {
        currentDrawingPage?.currentPaperLayer.stamp(onTop: true, forceRegularStamping: false)
    
    }

    func stampCurrentLine()
    {
        
        guard lineWorkEntityMode != .isInMultistateDrawing else {
            return;
        }
        
        if(lineWorkEntityMode == .idle)
        {
            if(inkAndLineSettingsManager!.vanishingPointGuides)
            {
                stampCurrentVanishingPointGuidelines();
            }
        }
        
        if(lineWorkEntityMode == .isInLinearDrawing)
        {
            if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
            {
                let stampLineFMStroke = FMStroke();
                stampLineFMStroke.fmInk = currentFMStroke.fmInk;
                
                if(currentFMStroke.arrayOfFMStrokePoints.count > 3)
                {
                
                }
                
                stampLineFMStroke.arrayOfFMStrokePoints.append(currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 2])
                stampLineFMStroke.arrayOfFMStrokePoints.append(currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1])
                
                if((currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType == .hardCornerBowedLine) || (currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType == .roundedCornerBowedLine))
                {
                   stampLineFMStroke.arrayOfFMStrokePoints.append(currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1])
                currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = .bSpline
                }
                
                rawFMStrokeDepositOntoCurrentPaperLayer(fmStrokeToDeposit: stampLineFMStroke, isCurrentFMStroke: false, undoMessage:"Stamp Stroke");
                
            
            }
        
        
        
        }
       

        
     
     
    }


    func moveLineIntoShapeKeyPress()
    {
        
        guard lineWorkEntityMode != .idle else {
            return;
        }
        
        guard currentPointInActiveLayer != nil else {
            return
        }
        
        if(self.lineWorkEntityMode == .isInLinearDrawing)
        {
            if(currentFMStroke.arrayOfFMStrokePoints.count > 3)
            {
                
                
                redisplayCurrentFMDrawable();
                
                currentFMStroke.changeLastPointIfMoreThanOne(toPoint: currentFMStroke.firstFMStrokePoint()!.cgPoint())
                
                if(currentFMStroke.fmInk.brushTip == .ellipse)
                {
                    
                    currentFMStroke.makeFMStrokeEllipseLiveVersionExtended(distance: inkAndLineSettingsManager!.distanceForOvalAndChiselLiveInterpolation)
                    
                }
                else if(currentFMStroke.fmInk.brushTip == .rectangle)
                {
                    currentFMStroke.makeFMStrokeRectangleLive(distanceForInterpolation: inkAndLineSettingsManager!.distanceForOvalAndChiselLiveInterpolation);
                }
                else if(currentFMStroke.fmInk.brushTip.isUniform)
                {
                    currentFMStroke.closeUniformBezier = true;
                    
                    currentFMStroke.makeUniformTipBezierPathForLive();
                }
                
                // addDrawableToCurrentLayer(self.currentFMStroke, doBackgroundThread : true)
                
                endKeyPress()
            }
            
            
        }
        
    }


    // MARK: Complete Current Line into Shape

    
    func completeCurrentLineIntoShapeKeyPress()
    {
    
        guard lineWorkEntityMode != .idle else {
            return;
        }
    
          guard currentPointInActiveLayer != nil else {
            return
        }
        
        if(self.lineWorkEntityMode == .isInLinearDrawing)
        {
            if(currentFMStroke.arrayOfFMStrokePoints.count > 2)
            {
                
                
                redisplayCurrentFMDrawable();

                if(inkAndLineSettingsManager!.makeAllShapeCompletionsHardCorner)
                {
                    hardBSplineCornerKeyPress();
                    hardBSplineCornerKeyPress();
                }
                else
                {
                    // ----- if the last deposited point was
                    // a rounded corner of either kind (bowed or regular),
                    // then move the first point by 10 pt along its angle,
                    // then deposit the next rounded point at its
                    // original location.  Then, make a hard corner
                    // point at the first point's location.
                    // -----
                    
                    if((currentFMStroke.lastFMStrokePoint()!.fmStrokePointType == .roundedCornerBowedLine))
                    {
                        
                        /*
                         // ---
                         // do hard corner if line interpolation is not set at mid point.
                         // ---
                         if(currentFMStroke.lastFMStrokePoint()!.bowedInfo.lineInterpolation > 0.5){
                         hardBSplineCornerKeyPress();
                         }
                         else
                         {
                         
                         */
                         
                        if(currentFMStroke.lastFMStrokePoint()!.bowedInfo.isFacingA)
                        {
                            //roundedBSplineCornerBowedLineKeyPress()
                            roundedBSplineCornerBowedLineKeyPress()
                        }
                        else
                        {
                            // roundedBSplineCornerBowedLineFacingBKeyPress()
                            roundedBSplineCornerBowedLineFacingBKeyPress()
                        }
                        
                        if(currentFMStroke.pkStrokePathCached != nil)
                        {
                            currentFMStroke.changeLastPointIfMoreThanOne(toPoint: currentFMStroke.firstFMStrokePoint()!.cgPoint())
                            
                            let p1 = currentFMStroke.pkStrokePathCached!.interpolatedPoint(at: 0).location
                            
                            let p2 = currentFMStroke.pkStrokePathCached!.interpolatedPoint(at: 0.1).location
                            
                            let dist = p1.distanceFrom(point2: currentFMStroke.arrayOfFMStrokePoints[1].cgPoint())
                             
                              // does not move bowed lines at the moment.
                            let typesWhereStraightLineCanBeMovedLikeRoundedCorner : [FMStrokePointType] = [.bSpline,.hardCorner,.roundedCorner]
                            
                            let isArcLastPt = currentFMStroke.lastFMStrokePoint()!.bowedInfo.isArc;
                            
                            if(isArcLastPt)
                            {
                                
                                currentFMStroke.changeLastPointIfMoreThanOne(toPoint: currentFMStroke.firstFMStrokePoint()!.cgPoint())
                            }
                            else if( typesWhereStraightLineCanBeMovedLikeRoundedCorner.contains(currentFMStroke.firstFMStrokePoint()!.fmStrokePointType))
                            {
                                let laDeg = NSBezierPath.lineAngleRadiansFrom(point1: p1, point2: p2)
                                //print(laDeg)
                                let a = p1.pointFromAngleAndLength(angleRadians:laDeg, length:dist / 2)
                                currentFMStroke.changeFirstPointIfMoreThanOne(toPoint: a)
                                
                                // ---------
                                // forces roundedBSpline corner point to have length 5.
                                // change this when hard corner accepts larger lengths.
                                // ---------
                                currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].roundedCornerSegmentLength = 10;

                                roundedBSplineCornerKeyPress();
                                currentFMStroke.changeLastPointIfMoreThanOne(toPoint: currentFMStroke.firstFMStrokePoint()!.cgPoint())
                            }
                            else
                            {
                                let laDeg = NSBezierPath.lineAngleRadiansFrom(point1: p1, point2: p2)
                                //print(laDeg)
                                let a = p1.pointFromAngleAndLength(angleRadians:laDeg, length:20);//dist / 2)
                                currentFMStroke.changeFirstPointIfMoreThanOne(toPoint: a)
                                
                                roundedBSplineCornerKeyPress();

                                // ---------
                                // forces roundedBSpline corner point to have length 5.
                                // change this when hard corner accepts larger lengths.
                                // ---------
                                currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].roundedCornerSegmentLength = 10;

                                currentFMStroke.changeLastPointIfMoreThanOne(toPoint: currentFMStroke.firstFMStrokePoint()!.cgPoint())
                                
                            }
                        }
                    }
                    else if( currentFMStroke.lastFMStrokePoint()!.fmStrokePointType == .hardCornerBowedLine)
                    {
                        if(currentFMStroke.lastFMStrokePoint()!.bowedInfo.isFacingA)
                        {
                            // hardBSplineCornerBowedLineKeyPress()
                            hardBSplineCornerBowedLineKeyPress()
                        }
                        else
                        {
                            // hardBSplineCornerBowedLineFacingBKeyPress()
                            hardBSplineCornerBowedLineFacingBKeyPress()
                        }
                        
                    }
                    else if( currentFMStroke.lastFMStrokePoint()!.fmStrokePointType == .roundedCorner)
                    {
                        
                        if(currentFMStroke.pkStrokePathCached != nil)
                        {
                            // custom code compared to other
                            // fmStrokePointTypes
                            roundedBSplineCornerKeyPress();
                            currentFMStroke.changeLastPointIfMoreThanOne(toPoint: currentFMStroke.firstFMStrokePoint()!.cgPoint())
                            let p1 = currentFMStroke.pkStrokePathCached!.interpolatedPoint(at: 0).location
                            
                            let p2 = currentFMStroke.pkStrokePathCached!.interpolatedPoint(at: 0.1).location
                            
                            let dist = p1.distanceFrom(point2: currentFMStroke.arrayOfFMStrokePoints[1].cgPoint())
                            
                            // does not move bowed lines at the moment.
                            let typesWhereStraightLineCanBeMoved : [FMStrokePointType] = [.bSpline,.hardCorner,.roundedCorner]
                            
                            if(typesWhereStraightLineCanBeMoved.contains(currentFMStroke.firstFMStrokePoint()!.fmStrokePointType))
                            {
                                let laDeg = NSBezierPath.lineAngleRadiansFrom(point1: p1, point2: p2)
                                //print(laDeg)
                                let a = p1.pointFromAngleAndLength(angleRadians:laDeg, length:dist / 2)
                                currentFMStroke.changeFirstPointIfMoreThanOne(toPoint: a)
                                
                                roundedBSplineCornerKeyPress();
                                currentFMStroke.changeLastPointIfMoreThanOne(toPoint: currentFMStroke.firstFMStrokePoint()!.cgPoint())
                            }
                            
                        }
                        
                        
                    }
                    else if( currentFMStroke.lastFMStrokePoint()!.fmStrokePointType == .bSpline)
                    {
                        hardBSplineCornerKeyPress();
                        hardBSplineCornerKeyPress();
                    }
                    else
                    {
                        hardBSplineCornerKeyPress();
                        hardBSplineCornerKeyPress();
                    }
                    
                    // ---
                    // roundedCorner moves its own last point. it
                    // has custom code above compared to other
                    // fmStrokeTypes.
                    // ---
                    if( (currentFMStroke.lastFMStrokePoint()!.fmStrokePointType != .roundedCorner)
                    && (currentFMStroke.lastFMStrokePoint()!.fmStrokePointType != .roundedCornerBowedLine))
                    {
                        currentFMStroke.changeLastPointIfMoreThanOne(toPoint: currentFMStroke.firstFMStrokePoint()!.cgPoint())
                    }
                }
                
                
                if(currentFMStroke.fmInk.brushTip == .ellipse)
                {
                    
                    currentFMStroke.makeFMStrokeEllipseLiveVersionExtended(distance: inkAndLineSettingsManager!.distanceForOvalAndChiselLiveInterpolation)
                    
                }
                else if(currentFMStroke.fmInk.brushTip == .rectangle)
                {
                    currentFMStroke.makeFMStrokeRectangleLive(distanceForInterpolation: inkAndLineSettingsManager!.distanceForOvalAndChiselLiveInterpolation);
                }
                else if(currentFMStroke.fmInk.brushTip.isUniform)
                {
                    currentFMStroke.closeUniformBezier = true;

                    currentFMStroke.makeUniformTipBezierPathForLive();
                }
                
                // addDrawableToCurrentLayer(self.currentFMStroke, doBackgroundThread : true)

                endKeyPress()
                // rawFMStrokeDepositOntoCurrentPaperLayer(fmStrokeToDeposit: currentFMStroke, isCurrentFMStroke: true, undoMessage:"Stroke")
                
                
            }
        }
        
        /*
        // before depositing a new bSpline point,
        // change the last point (the moving mouse point)
        // to .hardCorner instead of bSpline, which is what
        // it currently always is for the last point.
        if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        {
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = FMStrokePointType.hardCorner
        }
        
        currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.bSpline, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
        
            let firstFMStrokePt = (currentFMStroke.firstFMStrokePoint()?.cgPoint())!
        
            let a = currentFMStroke;
    
        endKeyPress()

        a.addFMStrokePoint(xIn: firstFMStrokePt.x, yIn: firstFMStrokePt.y, fmStrokePointTypeIn: FMStrokePointType.bSpline, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)

/*
        if(self.lineWorkEntityMode == .idle)
        {
            self.lineWorkEntityMode = .isInLinearDrawing
            addExtraPoint()
        }
  */
        
        
        return
    */
    /*
        if(self.lineWorkEntityMode == .isInLinearDrawing)
        {
            if(currentFMStroke.arrayOfFMStrokePoints.count > 2)
            {
        
            
            let fP = currentFMStroke.firstFMStrokePoint()?.cgPoint()
                       let lP = currentFMStroke.lastFMStrokePoint()?.cgPoint()

                   let fmS = FMStroke.init()
                   fmS.fmInk = inkAndLineSettingsManager!.fmInk;
                   fmS.fmInk.color = NSColor.white.withAlphaComponent(0.5);
      
        fmS.addFMStrokePoint(xIn: fP!.x, yIn: fP!.y, fmStrokePointTypeIn: FMStrokePointType.hardCorner, azimuthIn: currentFMStroke.lastFMStrokePoint()!.azimuth, altitudeIn: 0, brushSizeIn: currentFMStroke.lastFMStrokePoint()!.brushSize, heightFactor: 0.1)

 fmS.addFMStrokePoint(xIn: lP!.x, yIn: lP!.y, fmStrokePointTypeIn: FMStrokePointType.hardCorner, azimuthIn: currentFMStroke.lastFMStrokePoint()!.azimuth, altitudeIn: 0, brushSizeIn: currentFMStroke.lastFMStrokePoint()!.brushSize, heightFactor: 0.1)
                        
                        
        if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        {
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = FMStrokePointType.hardCorner
        }
        
        currentFMStroke.addFMStrokePoint(xIn: fP!.x, yIn: fP!.y, fmStrokePointTypeIn: currentFMStroke.lastFMStrokePoint()!.fmStrokePointType, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)

      currentFMStroke.addFMStrokePoint(xIn: lP!.x, yIn: lP!.y, fmStrokePointTypeIn: FMStrokePointType.hardCorner, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
      
    let a = currentFMStroke;
    
    endKeyPress();

  inputInteractionManager!.currentInputDocument!.drawingPage.currentPaperLayer.addFMStroke(fmS)
   a.arrayOfFMStrokePoints.append(contentsOf: fmS.arrayOfFMStrokePoints)
 
    activePenLayer?.setNeedsDisplay(a.renderBounds())
  

 // inputInteractionManager!.currentInputDocument!.drawingPage.paperLayer.arrayOfFMDrawables.removeLast();
 
 
    return;
    */
        /*
        
        
                    // before depositing a new bSpline point,
        // change the last point (the moving mouse point)
        // to .hardCorner instead of bSpline, which is what
        // it currently always is for the last point.
        if(currentFMStroke.arrayOfFMStrokePoints.count > 1)
        {
            currentFMStroke.arrayOfFMStrokePoints[currentFMStroke.arrayOfFMStrokePoints.count - 1].fmStrokePointType = FMStrokePointType.hardCorner
        }
        
        currentFMStroke.addFMStrokePoint(xIn: fP!.x, yIn: fP!.y, fmStrokePointTypeIn: FMStrokePointType.bSpline, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
        
        if(currentFMStroke.lastFMStrokePoint()!.cgPoint() != fP!)
        {
            fatalError("\(fP!)")
        }
        else
        {
         
        }
        
        addExtraPoint()
        
        endKeyPress()
        
        
        
                if let currentPenultimatepoint = currentFMStroke.penultimateFMStrokePoint()
                {
                    if(currentPenultimatepoint.fmStrokePointType == FMStrokePointType.hardCornerBowedLine)
                    {
                        currentFMStroke.moveLastPointLocationToSameAsFirst()
                    }
                    else if(currentPenultimatepoint.fmStrokePointType == FMStrokePointType.roundedCornerBowedLine)
                    {
                        currentFMStroke.moveLastPointLocationToSameAsFirst()

                    }
                    else if(currentPenultimatepoint.fmStrokePointType == FMStrokePointType.roundedCorner)
                    {
                        
                    }
                    else if(currentPenultimatepoint.fmStrokePointType == FMStrokePointType.hardCorner)
                    {
                        currentFMStroke.moveLastPointLocationToSameAsFirst()
                    }
                    else if(currentPenultimatepoint.fmStrokePointType == FMStrokePointType.bSpline)
                    {
                        currentFMStroke.moveLastPointLocationToSameAsFirst()
                    }
                    
                    self.endKeyPress();
                }
            }
            else
            {
                self.endKeyPress();
            }
        }
        
        */
    }
    
    func dabKeyPress()
    {
    
        if(lineWorkEntityMode == .isInMultistateDrawing)
        {
            escapeCurrentActivityKeyPress();
        }
    
        guard currentPointInActiveLayer != nil else {
            return
        }

        guard inkAndLineSettingsManager!.fmInk.brushTip != .uniform else {
            return
        }
        
        currentFMStroke.addFMStrokePoint(xIn: currentPointInActiveLayer!.x, yIn: currentPointInActiveLayer!.y, fmStrokePointTypeIn: FMStrokePointType.bSpline, azimuthIn: inkAndLineSettingsManager!.azimuthRadians, altitudeIn: inkAndLineSettingsManager!.altitudeRadians, brushSizeIn: inkAndLineSettingsManager!.currentBrushTipWidthAsCGSize, heightFactor: inkAndLineSettingsManager!.heightFactor)
        


          
        // if only one point is added when the count is zero, then when the
        // mouse moves there won't be a point to change as the last point.
        if(self.lineWorkEntityMode == .idle)
        {
            self.lineWorkEntityMode = .isInLinearDrawing
            addExtraPoint()
        }
    
       

        let oldPkStrokeRect = self.currentFMStroke.renderBounds()



        //self.currentFMStroke.isFinished = true
       addDrawableToCurrentLayer(self.currentFMStroke, doBackgroundThread : true)
        
        
        self.currentFMStroke = FMStroke.init()
        syncCurrentFMDrawableToInkSettings()
        self.activePenLayer?.setNeedsDisplay(oldPkStrokeRect)
        self.lineWorkEntityMode = .idle
        
    }
    
    // MARK: SHAPE IN BOUNDS KEYS
    
    func ellipseByTwoAxesKeyPress()
    {

        if(lineWorkEntityMode == .isInLinearDrawing)
        {
            escapeCurrentActivityKeyPress();
        }
    
       if((lineWorkEntityMode == .isInMultistateDrawing) && (currentMultistateDrawingEntity != ellipseDrawingEntity))
        {
            escapeCurrentActivityKeyPress();
        }
        
        guard currentPointInActiveLayer != nil else {
            return
        }
        
        if(self.lineWorkEntityMode == .idle)
        {
            self.lineWorkEntityMode = .isInMultistateDrawing
            ellipseDrawingEntity?.resetDrawingEntity();

            self.currentMultistateDrawingEntity = ellipseDrawingEntity
            ellipseDrawingEntity?.ellipseDrawingEntityMode = .byTwoAxes;
            ellipseDrawingEntity?.ellipseByTwoAxes();
            
        }
          else if((lineWorkEntityMode == .isInMultistateDrawing) && (currentMultistateDrawingEntity == ellipseDrawingEntity) && (ellipseDrawingEntity!.ellipseDrawingEntityMode == .byTwoAxes))
        {
            
            ellipseDrawingEntity?.ellipseByTwoAxes();

        }
        
         ellipseDrawingEntity?.advanceWorkflow()
    }
    
    func rectangleByTwoLinesKeyPress()
    {
    
        if(lineWorkEntityMode == .isInLinearDrawing)
        {
            escapeCurrentActivityKeyPress();
        }

        if((lineWorkEntityMode == .isInMultistateDrawing) && (currentMultistateDrawingEntity != rectangleDrawingEntity))
        {
            escapeCurrentActivityKeyPress();
        }

        guard currentPointInActiveLayer != nil else {
            return
        }
        
        
        if((self.lineWorkEntityMode == .idle) || (rectangleDrawingEntity!.rectangleDrawingEntityMode != .byTwoLines))
        {
            self.lineWorkEntityMode = .isInMultistateDrawing
            rectangleDrawingEntity?.resetDrawingEntity();
            self.currentMultistateDrawingEntity = rectangleDrawingEntity
            rectangleDrawingEntity?.rectangleDrawingEntityMode = .byTwoLines;
            rectangleDrawingEntity?.rectangleByTwoLines();
            
            
        }
        else if((lineWorkEntityMode == .isInMultistateDrawing) && (currentMultistateDrawingEntity == rectangleDrawingEntity) && (rectangleDrawingEntity!.rectangleDrawingEntityMode == .byTwoLines))
        {
            
            rectangleDrawingEntity?.rectangleByTwoLines();
            
        }

        


        
    }
    
    func shapeInQuadKeyPress()
    {
        if(lineWorkEntityMode == .isInLinearDrawing)
        {
            escapeCurrentActivityKeyPress();
        }

        if((lineWorkEntityMode == .isInMultistateDrawing) && (currentMultistateDrawingEntity != shapeInQuadDrawingEntity))
        {
            escapeCurrentActivityKeyPress();
        }

        guard currentPointInActiveLayer != nil else {
            return
        }

        if((self.lineWorkEntityMode == .idle) || (shapeInQuadDrawingEntity!.shapeInQuadDrawingEntityMode != .shapeInQuad))
        {
            self.lineWorkEntityMode = .isInMultistateDrawing
            rectangleDrawingEntity?.resetDrawingEntity();
            self.currentMultistateDrawingEntity = shapeInQuadDrawingEntity
            shapeInQuadDrawingEntity?.shapeInQuadDrawingEntityMode = .shapeInQuad;
            shapeInQuadDrawingEntity?.shapeInQuad()
            
            
        }
        else if((lineWorkEntityMode == .isInMultistateDrawing) && (currentMultistateDrawingEntity == shapeInQuadDrawingEntity) && (shapeInQuadDrawingEntity!.shapeInQuadDrawingEntityMode == .shapeInQuad))
        {
            
            shapeInQuadDrawingEntity?.shapeInQuad()
            
        }
        
    }
    
    
    func vanishingPointKeyPress()
    {


    }
    
    func selectKeyPress()
    {
        if(self.lineWorkEntityMode != .idle)
        {
            endKeyPress()
            
        }
        
        self.currentPaperLayer?.selectAtCursor()
        
        
    
    }

    func cartKeyPress()
    {
        
        if(self.lineWorkEntityMode != .idle)
        {
            endKeyPress()
            
        }
        
        self.currentPaperLayer?.cart()

    
    }
    
    // MARK: SELECTION EVENTS
    
    func currentLayerDidSelectObjects()
    {
        if(thereIsCurrentPaperLayerWithSelection)
        {
            inkAndLineSettingsManager!.updateColorWellBasedOnSelectionStateForCallbacks(color: currentPaperLayer!.selectedDrawables.first!.fmInk.mainColor)
            
            
            inkAndLineSettingsManager!.updateBezierPathStrokeWidthBasedOnSelectionStateForCallbacks(bezierPathStrokeWidthCGFloat: currentPaperLayer!.selectedDrawables.first!.lineWidth)
            
            
            //currentNCTDrawingPageController!.selectedObjectsLabel.stringValue = "selected: \(currentPaperLayer!.selectedDrawables.count)"
            //currentNCTDrawingPageController!.selectedObjectsLabel.isHidden = false
            
            inkAndLineSettingsManager!.updateRepresentationModeBasedOnSelectionStateForCallbacks(representationMode: currentPaperLayer!.selectedDrawables.first!.fmInk.representationMode)
            
            inkAndLineSettingsManager!.updateBezierPathStrokeWidthControls();
            inkAndLineSettingsManager!.updatePullPushRelToPaletteVisibility()
        }
        /*else if(thereIsCurrentPaperLayerWithSelection == false)
        {
            inkAndLineSettingsManager!.updateRepresentationModeBasedOnSelectionStateForCallbacks(representationMode: currentPaperLayer!.selectedDrawables.first!.fmInk.representationMode)

        }*/
        
        inkAndLineSettingsManager!.updateCombinatoricsKeysVisibility()
        
    
    }
    
    func currentLayerDidDeselectASingleObject()
    {
        //currentNCTDrawingPageController!.selectedObjectsLabel.stringValue = "selected: \(currentPaperLayer!.selectedDrawables.count)"
     
        if(self.thereIsCurrentPaperLayerWithSelection)
        {
            inkAndLineSettingsManager!.updateColorWellBasedOnSelectionStateForCallbacks(color: currentPaperLayer!.selectedDrawables.first!.fmInk.mainColor)
            inkAndLineSettingsManager!.updateRepresentationModeBasedOnSelectionStateForCallbacks(representationMode: currentPaperLayer!.selectedDrawables.first!.fmInk.representationMode)
       
        }
        else
        {
            inkAndLineSettingsManager!.updateColorWellBasedOnSelectionStateForCallbacks(color: inkAndLineSettingsManager!.currentStrokeColor)
        
            inkAndLineSettingsManager!.updateRepresentationModeSegmCont()

        }
    
        inkAndLineSettingsManager!.updateBezierPathStrokeWidthControls()
        
        inkAndLineSettingsManager!.updateCombinatoricsKeysVisibility()
        inkAndLineSettingsManager!.updatePullPushRelToPaletteVisibility()
        
    }
    
    
    func currentLayerDidDeselectAllObjects()
    {
        inkAndLineSettingsManager!.updateColorWellBasedOnSelectionStateForCallbacks(color: inkAndLineSettingsManager!.currentStrokeColor)
        
        inkAndLineSettingsManager!.updateRepresentationModeSegmCont()
        
        inkAndLineSettingsManager!.updateBezierPathStrokeWidthControls()
       // currentNCTDrawingPageController!.selectedObjectsLabel.isHidden = true;
        
        inkAndLineSettingsManager!.updateCombinatoricsKeysVisibility()
        inkAndLineSettingsManager!.updatePullPushRelToPaletteVisibility()
    }
    
    func currentLayerDidStartCarting()
    {
        if(currentPaperLayer != nil)
        {
            
        }
            
    }

    func currentLayerDidEndCarting()
    {
         if(currentPaperLayer != nil)
        {
            
        }
           
    }

    // MARK: PATH OPERATIONS


    func joinSelectedPaths()
    {
        if(thereIsCurrentPaperLayerWithSelection)
        {
            currentPaperLayer!.joinSelectedPaths();
        }
    }
    
    func separateSubpaths()
    {
        if(thereIsCurrentPaperLayerWithSelection)
        {
            currentPaperLayer!.separateSubpaths();
        }
    }
    
    
    func replicateSelectedToggleKeyPress()
    {
        
        if(thereIsCurrentPaperLayerWithSelection)
        {
            
            let s = currentPaperLayer!.selectedDrawables
            currentPaperLayer!.clearOutSelections();
            
            currentPaperLayer!.replicateDrawablesAndAddToLayer(drawables: s)
            //currentPaperLayer!.separateSubpaths();
        }
    }
    
    // MARK: LOADED OBJECT KEY PRESS
    
    func loadedObjectKeyPress()
    {
        if(thereIsCurrentPaperLayerWithSelection)
        {
            if let objToLoad = currentPaperLayer!.selectedDrawables.first!.copy() as? FMStroke
            {
                if(objToLoad.isFinished == false)
                {
                    return;
                }
                
                // -------------------------
                // Convert fill and other settings
                // over to regular FMDrawable shape.
                // -------------------------
                // inkAndLineSettingsManager!.loadedObject = objToLoad.fmDrawableVersionOfStroke()
                
                inkAndLineSettingsManager!.loadedObject = objToLoad;
                
                return
            }
            
            if let objToLoad = currentPaperLayer!.selectedDrawables.first!.copy() as? FMDrawable
            {
                inkAndLineSettingsManager!.loadedObject = objToLoad;
            }
            
        }
    }

    // MARK: DRAWING DELETION KEY PRESSES
    
    func deleteLastStrokeKeyPress()
    {
    
        if(inputInteractionManager!.currentInputDocument!.drawingPage.currentPaperLayer.orderingArray.isEmpty == false)
        {
        let oldRect = inputInteractionManager!.currentInputDocument!.drawingPage.currentPaperLayer.orderingArray.last!.renderBounds()
        
        inputInteractionManager!.currentInputDocument!.drawingPage.currentPaperLayer.orderingArray.removeLast()
        
        inputInteractionManager?.currentInputDocument?.drawingPage.currentPaperLayer.setNeedsDisplay(oldRect)
        }
        
        
        if(inputInteractionManager!.currentInputDocument!.updateSVGPreviewLiveIsOn)
        {
            inputInteractionManager!.currentInputDocument!.updateSVGPreviewLive();
        }
        
    }
    
    func deleteAllStrokesKeyPress()
    {
        
    
    
        if(currentPaperLayer != nil)
        {
            currentPaperLayer!.clearOutSelections();
            currentPaperLayer!.removeArrayOfDrawables(currentPaperLayer!.orderingArray)
            currentPaperLayer!.needsDisplay = true;
        }
        
        /*
        inputInteractionManager!.currentInputDocument!.drawingPage.currentPaperLayer.orderingArray.removeAll();
        inputInteractionManager!.currentInputDocument!.drawingPage.currentPaperLayer.needsDisplay = true;
        */
        
        if(inputInteractionManager!.currentInputDocument!.updateSVGPreviewLiveIsOn)
        {
            inputInteractionManager!.currentInputDocument!.updateSVGPreviewLive();
        }
        
    }
    
    func eraseLastLivePointKeyPress()
    {
        if(self.lineWorkEntityMode == .isInLinearDrawing)
        {
            if(currentFMStroke.arrayOfFMStrokePoints.count > 2)
            {
                let oldRect = currentFMStroke.renderBounds()
                
                currentFMStroke.arrayOfFMStrokePoints.remove(at: currentFMStroke.arrayOfFMStrokePoints.count - 2)
                
                currentFMStroke.regeneratePkStrokePathCached();
                redisplayCurrentFMDrawable();
                
                 activePenLayer?.setNeedsDisplay(oldRect)
            
            }
            else
            {
                escapeCurrentActivityKeyPress();
            }
        
        }
    
    }

    func moveSelectionAnchorPointKeyPress()
    {
        guard currentDrawingPage != nil else {
            return
        }
        
        // change to internal point of
        // selected object.
        currentDrawingPage!.permanentAnchorPoint = currentPointInActiveLayer!;
        redisplayPermanentAnchorPoint();
    
    }
    
    func movePermanentAnchorPointKeyPress()
    {
        guard currentDrawingPage != nil else
        {
            return
        }
        
        currentDrawingPage!.permanentAnchorPoint = currentPointInActiveLayer!;
       
        redisplayPermanentAnchorPoint();
        
    }
    
    
    func exportFrameToggleKeyPress()
    {
        guard currentDrawingPage != nil else {
            return
        }
    
        currentDrawingPage?.drawingPageController?.exportFrameIsVisible.toggle()
    
    }
   
   
    func adjustExportFrameCornerKeyPress()
    {
    
        guard currentDrawingPage != nil else {
            return
        }

        guard currentPointInActiveLayer != nil else {
            return
        }
      
        //currentDrawingPage?.drawingPageController?.changeNearestExportFrameCornerTo(point:)

      
    }
    
    func adjustExportFrameCenterKeyPress()
    {
        
        guard currentDrawingPage != nil else {
            return
        }
        guard currentPointInActiveLayer != nil else {
            return
        }
        currentDrawingPage?.drawingPageController?.changeExportFrameCenterPointTo(point:self.currentPointInActiveLayer!)

    }

    // MARK: MultistateEntity
    func multistateEntityEnded()
    {
        self.lineWorkEntityMode = .idle
    
    }

    // MARK: DRAW FOR ACTIVEPENLAYER
 
    var showControlBoundsUsingBezier : Bool = false;
 
    var replicationDrawable : FMDrawable?


  //  var replicatorLayer : CAReplicatorLayer = CAReplicatorLayer()
 
    func drawForActivePenLayerGuidelines()
    {
        currentDrawingPage?.drawVanishingPointGuides()
        
        // MARK: replicationModeIsOn drawReplicationGuides()
        if(inkAndLineSettingsManager!.replicationModeIsOn)
        {
            replicationConfigurationViewController!.drawReplicationGuides()
        }
        
        
    }
    
    func drawForActivePenLayer(_ activePenLayer: ActivePenLayer)
    {
     
        
        
        if((showAnchorPoint) && (currentDrawingPage != nil))
        {
            let anchorRect = NSRect.init(origin: .zero, size: NSMakeSize(10, 10)).centerOnPoint(currentDrawingPage!.permanentAnchorPoint);
                NSColor.purple.setFill();
                anchorRect.frame(withWidth: 1, using: NSCompositingOperation.sourceOver)
    
        }
        
        if(self.lineWorkEntityMode == .isInRectangleSelect)
        {
        
            let grad = NSGradient.init(colors:
            [
            NSColor.init(calibratedWhite: 1.0, alpha: 0.2),
            NSColor.clear, NSColor.clear,
            NSColor.init(calibratedWhite: 1.0, alpha: 0.2)
            ],
            atLocations: [0.0,0.4,0.6,1.0], colorSpace: NSColorSpace.deviceRGB)
            
            grad?.draw(in: rectangleSelectRect, angle: 0)
            grad?.draw(in: rectangleSelectRect, angle: 90)
            
            NSColor.purple.setFill();
            rectangleSelectRect.frame(withWidth: 2, using: NSCompositingOperation.sourceOver)
        
        }
        
        if(self.lineWorkEntityMode == .isInLinearDrawing)
        {
            
            currentFMStroke.display()
            
            if(currentFMStroke.fmInk.brushTip.isUniform)
            {
                
                if(inkAndLineSettingsManager!.replicationModeIsOn)
                {
                 //   replicationDrawable?.perform(#selector(replicationDrawable!.display2))
                }
            }
            else
            {
                
                //let f = FMDrawable();
                //f.fmInk = currentFMStroke.fmInk
                
                // f.append(currentFMStroke.uniformTipBezierPath(distanceForInterpolation: 10))
                // print(f)
                
                if(inkAndLineSettingsManager!.replicationModeIsOn)
                {
                
                //    replicationDrawable?.perform(#selector(replicationDrawable!.display2))
                }
                
            }
            
            /*
            if let replicationImgDrawable = replicationConfigurationViewController!.makeReplicationDrawable(currentFMStroke, isLive: true) as? FMImageDrawable
            {
                replicationImgDrawable.display();
            }
            */
            
           
            
            if(inkAndLineSettingsManager!.showStrokeControlPoints)
            {
                currentFMStroke.displayControlPoints();
            }
        }
        else if(self.lineWorkEntityMode == .isInMultistateDrawing)
        {
            currentMultistateDrawingEntity?.drawForActivePenLayer();
        }
        
        
        
        
        // MARK: replicationModeIsOn drawReplicationLiveImage()
        if(inkAndLineSettingsManager!.replicationModeIsOn)
        {
            if((self.isProcessingDeposit == true) || ((self.lineWorkEntityMode != .idle) && (self.lineWorkEntityMode != .isInRectangleSelect) &&
            (currentDrawingPage != nil)) )
            {
                    replicationConfigurationViewController!.drawReplicationLiveImage();
            }
        }
        
        
        if(inkAndLineSettingsManager!.alignmentPointLinesSnapping)
        {
            // negative means there is no alignment point
            if((currentAlignmentPoint.x >= 0) && (currentAlignmentPoint.y >= 0))
            {
                
                NSColor.blue.setFill()
                currentAlignmentPoint.fillSquareAtPoint(sideLength: 10, color: NSColor.blue)
                
                /*
                 if let documentVisibleRect = activePenLayer.enclosingScrollView?.contentView.documentVisibleRect
                 {
                 documentVisibleRect.insetBy(dx: 20, dy: 20).frame()
                 documentVisibleRect.insetBy(dx: 15, dy: 15).frame()
                 documentVisibleRect.insetBy(dx: 10, dy: 10).frame()
                 
                 }
                 */
                
            }
        }
        
            
            
            
        
        if(inkAndLineSettingsManager!.pointsSnapping || inkAndLineSettingsManager!.pathsSnapping || inkAndLineSettingsManager!.gridSnapping)
        {
            if(currentPointHit.nsPoint != nil)
            {
                NSGraphicsContext.current?.saveGraphicsState();
                
                  
                let shadow = NSShadow()
                shadow.shadowBlurRadius = 3.0
                shadow.shadowOffset = NSSize(width: 0, height: 0)
                shadow.shadowColor = NSColor.white
                shadow.set()
            
                NSColor.black.setStroke();
                currentPointHitPath?.stroke();
            
                NSGraphicsContext.current?.restoreGraphicsState();
            }
        
        }
        
        
        if(showBrushTipCursor)
        {
            if(inkAndLineSettingsManager!.fmInk.isUniformPathThatIsFillOnly == false)
            {
                if(activePenLayer.cursorBezierPath.isEmpty == false)
                {
                    
                    inkAndLineSettingsManager!.fmInk.mainColor.withAlphaComponent(0.5).setFill();
                    
                    activePenLayer.cursorBezierPath.fill();
                    
                    NSColor.blue.setStroke()
                    activePenLayer.cursorBezierPath.stroke();
                }
            }
        }

        
        /*
        for stroke in pkDrawingForLiveLine.strokes
        {
            let path = stroke.path
         
         //   for pkPoint in path.interpolatedPoints(by: PKStrokePath.InterpolatedSlice.Stride.parametricStep(stepSizeA))
         
            for pkPoint in path.interpolatedPoints(by: .distance(1))
            {
                let location = pkPoint.location//.unflipInsideBounds(boundsForUnflipping: activePenLayer.bounds)
               // let r = NSRect.init(origin: location, size: CGSize.init(width: 1.25 * pkPoint.size.width, height: 1.15 *  0.35 * pkPoint.size.width )).unflipInsideBounds(boundsForUnflipping: self.bounds))
                
                //.centerOnPoint(pkPoint.location
                
                stroke.ink.color.setFill();
                
               // r.fill();
                let p = NSBezierPath();
               // p.appendRotatedOvalAtCenterPoint(angleDegrees: -rad2deg(pkPoint.azimuth), centerPoint: location, width:  1.25 * pkPoint.size.width, height:  1.25 *  0.35 * pkPoint.size.width)
                
                let r2 = NSMakeRect(location.x,location.y, pkPoint.size.width,  0.35 * pkPoint.size.width).centerOnPoint(location)
                
                let rp = NSBezierPath()
                rp.appendRect(r2)
                
                p.appendPathRotatedAboutCenterPoint(path: rp, angleDegrees: rad2deg(pkPoint.azimuth), centerPoint: location)
                
                p.fill();
                
                
                
                //print(point)
            }
            
        }
        */
        
        /*
    
        pkDrawingImageForLiveLine.draw(in: activePenLayer.bounds)
        
     //   NSColor.brown.setFill();
      //  activePenLayer.bounds.fill()
    
    
        if(showControlBoundsUsingBezier)
        {
            /*
             NSColor.black.setStroke()
             
             for fmStroke in arrayOfFMDrawables
             {
             fmStroke.displayCachedBezierPath()
             }
             */
            if(currentFMStroke.arrayOfFMStrokePoints.isEmpty == false)
            {
                NSColor.blue.setStroke();
                currentFMStroke.bezierPathCached.lineWidth = 2;
                currentFMStroke.bezierPathCached.stroke()
                //currentFMStroke.displayCachedBezierPath()
            }
            
        }*/

        
    }
    
    
    func loadSettings()
    {
        
    }
    
    override func awakeFromNib() {
        loadSettings();
    }
 
 // MARK: GRID
 
func nearestGridPoint(pointForHitTest:NSPoint) -> NSPoint
{
    var nearestGridPointToReturn = pointForHitTest;
    
    if(
    (inkAndLineSettingsManager!.gridSnappingType == .squareDots) ||
    (inkAndLineSettingsManager!.gridSnappingType == .squareEdges) ||
    (inkAndLineSettingsManager!.gridSnappingType == .square45DegWithXYEdges))
    {
        // ------------------------
        // for .square45DegWithXYEdges,
        // will halve the gridSnappingEdgeLength
        // ------------------------
        
        let gridInterval = (inkAndLineSettingsManager!.gridSnappingType != .square45DegWithXYEdges) ? inkAndLineSettingsManager!.gridSnappingEdgeLength : (inkAndLineSettingsManager!.gridSnappingEdgeLength / 2)
        
        
        let xModuloed = pointForHitTest.x.truncatingRemainder(dividingBy: gridInterval);
        let yModuloed = pointForHitTest.y.truncatingRemainder(dividingBy: gridInterval);
        
        nearestGridPointToReturn = NSMakePoint(pointForHitTest.x - xModuloed, pointForHitTest.y - yModuloed);
        
        if( (xModuloed > 0) && (xModuloed > (gridInterval / 2.0) ))
        {
            nearestGridPointToReturn.x = pointForHitTest.x - xModuloed + gridInterval;
        }
        
        if( (yModuloed > 0) && (yModuloed > (gridInterval / 2.0) ))
        {
            nearestGridPointToReturn.y = pointForHitTest.y - yModuloed + gridInterval;
        }
    }
    else if(inkAndLineSettingsManager!.gridSnappingType == .triangleHorizontal)
    {
        guard currentDrawingPage!.bgImg != nil else {
            return nearestGridPointToReturn
        }
    
        let triangleEdgeLength = currentDrawingPage!.bgImg!.size.height
   
        let altitudeOfEquilateralTriangle = currentDrawingPage!.bgImg!.size.width / 2;
        let xModuloed = pointForHitTest.x.truncatingRemainder(dividingBy: altitudeOfEquilateralTriangle );
        
        var columnIndex = (round((pointForHitTest.x - xModuloed) / altitudeOfEquilateralTriangle))
        
        
        if(xModuloed >= (0.5 * altitudeOfEquilateralTriangle))
        {
            columnIndex += 1;
        }
        
        
        let yModuloed : CGFloat = pointForHitTest.y.truncatingRemainder(dividingBy: triangleEdgeLength);
        var rowIndex = (round((pointForHitTest.y - yModuloed) / triangleEdgeLength))
      
        if(yModuloed >= (0.5 * triangleEdgeLength))
        {
            rowIndex += 1;
        }

        nearestGridPointToReturn = NSMakePoint(columnIndex * altitudeOfEquilateralTriangle, rowIndex * triangleEdgeLength)
        
        if(Int(columnIndex).isOdd)
        {
            
          nearestGridPointToReturn.y = (pointForHitTest.y - (pointForHitTest.y.truncatingRemainder(dividingBy: triangleEdgeLength))) + (triangleEdgeLength / 2)
        }

  
        
    }
    else if(inkAndLineSettingsManager!.gridSnappingType == .triangleVertical)
    {
        guard currentDrawingPage!.bgImg != nil else {
            return nearestGridPointToReturn
        }
    
        let triangleEdgeLength = currentDrawingPage!.bgImg!.size.width
   
        let altitudeOfEquilateralTriangle = currentDrawingPage!.bgImg!.size.height / 2;
       
        let yModuloed : CGFloat = pointForHitTest.y.truncatingRemainder(dividingBy: altitudeOfEquilateralTriangle);
        
        var rowIndex = (round((pointForHitTest.y - yModuloed) / altitudeOfEquilateralTriangle))
      
        // IF IT is in the middle or a little bit over,
        // move to the next row.
        if(yModuloed >= (0.5 * altitudeOfEquilateralTriangle))
        {
            rowIndex += 1;
        }
       
        let xModuloed = pointForHitTest.x.truncatingRemainder(dividingBy: triangleEdgeLength );
        
        var columnIndex = (round((pointForHitTest.x - xModuloed) / triangleEdgeLength))
       
       
        if(Int(rowIndex).isOdd)
        {
            //nearestGridPointToReturn.x -= 0.5 * triangleEdgeLength;
            columnIndex += 0.5;
        }
        else
        {
            
            // IF IT is in the middle or a little bit over,
            // move to the next row.
            if(xModuloed >= (0.5 * triangleEdgeLength))
            {
                columnIndex += 1;
            }
            
        }
        
        
     
        

        //print("\(rowIndex) \(columnIndex)")
        nearestGridPointToReturn = NSMakePoint(columnIndex * triangleEdgeLength, rowIndex * altitudeOfEquilateralTriangle)
        
        
        
            //nearestGridPointToReturn.x = (pointForHitTest.x - (pointForHitTest.x.truncatingRemainder(dividingBy: altitudeOfEquilateralTriangle))) + (altitudeOfEquilateralTriangle / 2)
            
            // nearestGridPointToReturn.y = (pointForHitTest.y - (pointForHitTest.y.truncatingRemainder(dividingBy: altitudeOfEquilateralTriangle))) + (altitudeOfEquilateralTriangle / 2)
        
  
        
    }

    return nearestGridPointToReturn
    
}
 
 // MARK: TESTING
 
 @IBAction func generateLines(_ sender: NSControl)
 {
 
//    print(activePenLayer!.bounds.height)
    for i : CGFloat in stride(from: 0.0, to: activePenLayer!.bounds.height, by: 1.0)
    {
        let fmS = FMStroke.init()
    
        let randomX = CGFloat.random(in: 0...activePenLayer!.bounds.width)

        fmS.addFMStrokePoint(xIn: randomX, yIn: i, fmStrokePointTypeIn: FMStrokePointType.hardCorner, azimuthIn: rad2deg(45), altitudeIn: 0, brushSizeIn: CGSize.init(width: 2, height: 5), heightFactor: 0.1)

        fmS.addFMStrokePoint(xIn: randomX + 200, yIn: i, fmStrokePointTypeIn: FMStrokePointType.hardCorner, azimuthIn: rad2deg(45), altitudeIn: 0, brushSizeIn: CGSize.init(width: 2, height: 5), heightFactor: 0.1)

        fmS.addFMStrokePoint(xIn: randomX + 200, yIn: i + 200, fmStrokePointTypeIn: FMStrokePointType.hardCorner, azimuthIn: rad2deg(45), altitudeIn: 0, brushSizeIn: CGSize.init(width: 2, height: 5), heightFactor: 0.1)

        fmS.addFMStrokePoint(xIn: randomX - 200.0, yIn: i + 200, fmStrokePointTypeIn: FMStrokePointType.hardCorner, azimuthIn: rad2deg(45), altitudeIn: 0, brushSizeIn: CGSize.init(width: 2, height: 5), heightFactor: 0.1)




        addDrawableToCurrentLayer(fmS, doBackgroundThread : true)
        
    }
 
 }
 
    
}// END class


