//
//  FMStroke.swift
//  Floating Marker
//
//  Created by John Pratt on 1/19/21.
//

import Cocoa
import PencilKit
import Accelerate
import GameplayKit.GKNoise
// MARK: FORMAT FOR POINTS


// FMBrushTip uses string instead of Int
// so that the XML will have
// a string in the attribute of the tag.
enum FMBrushTip : String
{
    case ellipse
//    Ellipse at 1.0 heightFactor uses regular strokePath from Quartz with lineCap and lineJoin set to round
    case rectangle
    case uniform
    case uniformPath
    
    
//    case uniformRails = "uniformRails"

//    case flatPen = 3

    init?(intRaw:Int) {
        var rawString = ""
        switch intRaw
        {
        case 0:
            rawString = "ellipse"
        case 1:
            rawString = "rectangle"
        case 2:
            rawString = "uniform"
        case 3:
            rawString = "uniformPath"
        default:
            rawString = "ellipse"
        }
        self.init(rawValue: rawString)
    }
    
    var isUniform : Bool
    {
        return ((self == .uniform) || (self == .uniformPath))
    }
  
    
    func rawIntValue() -> Int
    {
        
        switch self {
        case .ellipse:
            return 0;
        case .rectangle:
            return 1;
        case .uniform:
            return 2;
        case .uniformPath:
            return 3;
        }
    }
}


class FMStroke : FMDrawable
{

    
    /*
    deinit {
        print("FMStroke object about to be deallocated")
    }*/
    
    override init() {
        super.init()
    }

      override  var pasteboardTypeUTIForDrawableClass : NSPasteboard.PasteboardType
    { return NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmstroke") }
    
    // NOTE: "Swift 4 does not allow its subclasses to inherit its superclass initializers"
    // So all subclasses must implement an override of this method.
    override init(baseXMLElement: XMLElement, svgPath: String)
    {
       
       super.init()
       baseFMDrawableClassInitStep(baseXMLElement: baseXMLElement, svgPath: svgPath)
       secondaryStepForInit(baseXMLElement: baseXMLElement, svgPath: svgPath)
   
       
    }
    
    override func secondaryStepForInit(baseXMLElement: XMLElement, svgPath: String)
    {
         do{
            
            let fmStrokeNodesArray = try baseXMLElement.nodes(forXPath: "fmkr:FMStroke")
            if(fmStrokeNodesArray.isEmpty == false)
            {
                
                
                
                let fmStrokePoints = try fmStrokeNodesArray.first!.nodes(forXPath: "fmkr:FMStrokePoint")
                
                if(fmStrokePoints.isEmpty == false)
                {
                    for fmStrokePtNode in fmStrokePoints
                    {
                        if let fmStrokePtXML = fmStrokePtNode as? XMLElement
                        {
                            let fmStrokePoint = FMStrokePoint.init(xmlElement: fmStrokePtXML, parentFMStroke: self);
                            self.arrayOfFMStrokePoints.append(fmStrokePoint)
                            
                        }
                    }
                }
                
                self.isFinished = true
                
                
            }
        }
        catch
        {
            
       }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
 

    
    override func transform(using transform: AffineTransform) {
        super.transform(using: transform)
        
        for i in 0..<arrayOfFMStrokePoints.count
        {
            let p = arrayOfFMStrokePoints[i].cgPoint()
           let transformedPoint = transform.transform(p);
           arrayOfFMStrokePoints[i].setFromCGPoint(transformedPoint)
            
        }
        
        pkStrokePathCached = nil;
        liveBezierPathArray.removeAll();
        
    }
    
    func rotateBrushTips(degrees: CGFloat)
    {
        for i in 0..<arrayOfFMStrokePoints.count
        {
            arrayOfFMStrokePoints[i].azimuth = arrayOfFMStrokePoints[i].azimuth - deg2rad(degrees)
            pkStrokePathCached = nil;
            liveBezierPathArray.removeAll();
            
        }
        
        if(shadingShapesArray != nil)
        {
            if(shadingShapesArray!.isEmpty == false)
            {
                for shadingShape in shadingShapesArray!
                {
                    if let stroke = shadingShape as? FMStroke
                    {
                        for i in 0..<stroke.arrayOfFMStrokePoints.count
                        {
                            
                            stroke.arrayOfFMStrokePoints[i].azimuth = stroke.arrayOfFMStrokePoints[i].azimuth - deg2rad(degrees)
                            stroke.pkStrokePathCached = nil;
                            stroke.liveBezierPathArray.removeAll();
                            
                        }
                        
                    }
                    
                }
                
            }
        }
        
    }
    
    var accessoryFMStrokes : [FMStroke]?
    var accessoryFMStrokesRatios : [CGFloat]?
    



    var vectorFactor : CGFloat = 0.195
    var realtimeVectorFactor : CGFloat = 0.3
    var simplificationTolerance : CGFloat = 0.3;

  
    var isFinished : Bool = false
    var needsReprocessing : Bool = false
    
    func setToIsFinished()
    {
        isFinished = true;
    }
    
    /*
    override var isEmpty : Bool
    { get{ return self.arrayOfFMStrokePoints.isEmpty}
    
    }*/


    var isFillFMStroke : Bool = false;


    var bezierPathCached : NSBezierPath = NSBezierPath();
    
    func regeneratePkStrokePathCached()
    {
            pkStrokePathCached = pkStrokePathAcc();

    }
    
    func addFMStrokePoint(xIn:CGFloat,yIn:CGFloat,fmStrokePointTypeIn:FMStrokePointType,azimuthIn:CGFloat,altitudeIn:CGFloat,
    brushSizeIn:CGSize, heightFactor: CGFloat /*, bowedTuple: (Bool,CGFloat)*/)
    {
        
        let fmP = FMStrokePoint.init(xIn: xIn, yIn: yIn, fmStrokePointTypeIn: fmStrokePointTypeIn, azimuthIn: azimuthIn, altitudeIn: altitudeIn, brushSizeIn: brushSizeIn, parentFMStroke: self)
        
        arrayOfFMStrokePoints.append(fmP)
        
        pkStrokePathCached = pkStrokePathAcc();
        
        
        // ACCESSORY FMSTROKES ARE DRAWN NEXT TO THE STROKE
        if((accessoryFMStrokesRatios != nil) && (accessoryFMStrokes != nil))
        {
            if(accessoryFMStrokesRatios!.count > accessoryFMStrokes!.count)
            {
            /*
//                var currentDistanceFromEdgeOfBrush = 0;
                for (index,_ /*ratio*/) in accessoryFMStrokesRatios!.enumerated()
                {
                  for fmStrokePoint in accessoryFMStrokes![index].arrayOfFMStrokePoints
                  {
                    // odd is spacer, even is accessoryFMStroke
                    if(index.isOdd)
                    {
//                        currentDistanceFromEdgeOfBrush += ratio * (self.)
                    }
                    else
                    {
                        
                    }
                  
                  }
                    
                }*/
            }
        
        }
        
    }
    
    func addBowedFMStrokePoint(xIn:CGFloat,yIn:CGFloat,fmStrokePointTypeIn:FMStrokePointType,azimuthIn:CGFloat,altitudeIn:CGFloat,
                          brushSizeIn:CGSize, bowedInfo: BowedInfo )
    {
        let fmP = FMStrokePoint.init(xIn: xIn, yIn: yIn, fmStrokePointTypeIn: fmStrokePointTypeIn, azimuthIn: azimuthIn, altitudeIn: altitudeIn, brushSizeIn: brushSizeIn, parentFMStroke: self, bowedInfo: bowedInfo)
        
        arrayOfFMStrokePoints.append(fmP)
        
        pkStrokePathCached = pkStrokePathAcc();
    }
    
    var arrayOfFMStrokePoints : [FMStrokePoint] = [];

    var arrayOfFMStrokePointsDeepCopy : Array<FMStrokePoint>
    {
        get
        {
            var arrayOfFMStrokePointsCopied : Array<FMStrokePoint> = [];
            
            for (_, fmStrokePoint) in arrayOfFMStrokePoints.enumerated()
            {
                arrayOfFMStrokePointsCopied.append(fmStrokePoint)
            }
            
            return arrayOfFMStrokePointsCopied;
        }
    
    }

    func displayCachedBezierPath()
    {
        if(arrayOfFMStrokePoints.isEmpty == false)
        {
            bezierPathCached.lineWidth = 1.0//self.arrayOfFMStrokePoints.first!.brushSize.width
            fmInk.mainColor.setStroke();
            bezierPathCached.stroke();
        }
    }
    
    
    func changeFirstPointIfMoreThanOne(toPoint:NSPoint)
    {
        if(arrayOfFMStrokePoints.count >= 1)
        {
            arrayOfFMStrokePoints[0].setFromCGPoint(toPoint)

            pkStrokePathCached = pkStrokePathAcc();
        }
        
    }
    
    func changeLastPointIfMoreThanOne(toPoint:NSPoint)
    {
        if(arrayOfFMStrokePoints.count > 1)
        {
            arrayOfFMStrokePoints[arrayOfFMStrokePoints.count - 1].setFromCGPoint(toPoint)

            pkStrokePathCached = pkStrokePathAcc();
        }
        
    }
    
    func changeLastPointAzimuth(_ azimuthRadians:CGFloat)
    {
        if(arrayOfFMStrokePoints.count > 1)
        {
            arrayOfFMStrokePoints[arrayOfFMStrokePoints.count - 1].azimuth = azimuthRadians;
            
            pkStrokePathCached = pkStrokePathAcc();
        }
    }
    
    func changeLastPointBrushTipSize( width: CGFloat, height: CGFloat)
    {
        if(arrayOfFMStrokePoints.count > 1)
        {
            arrayOfFMStrokePoints[arrayOfFMStrokePoints.count - 1].brushSize = CGSize.init(width: width, height:  height/*arrayOfFMStrokePoints[arrayOfFMStrokePoints.count - 1].brushSize.height*/)

            pkStrokePathCached = pkStrokePathAcc();
        }
    }
    
    func changeAllPointsBrushTipSize( width: CGFloat, height: CGFloat)
    {
        for i in 0..<arrayOfFMStrokePoints.count
        {
            arrayOfFMStrokePoints[i].brushSize = CGSize.init(width: width, height:  height);
        }
    
        pkStrokePathCached = pkStrokePathAcc();

    }
    
    func moveLastPointLocationToSameAsFirst()
    {
        if(arrayOfFMStrokePoints.count > 1)
        {
            arrayOfFMStrokePoints[arrayOfFMStrokePoints.count - 1].setFromCGPoint(arrayOfFMStrokePoints[0].cgPoint())
            
        }
        
        pkStrokePathCached = pkStrokePathAcc();
    }
    
    

    
    /*
    func pkStrokePoints() -> [PKStrokePoint]
    {
        var pkPtArray : [PKStrokePoint] = [];
        
        if(arrayOfFMStrokePoints.isEmpty)
        {
        
        }
        
        self.arrayOfFMStrokePoints.forEach { (fmPoint) in
        
            if(fmPoint.fmStrokePointType == .bSpline)
            {
                let pkStkPt = PKStrokePoint.init(location: fmPoint.cgPoint(), timeOffset: 0.1, size: fmPoint.brushSize, opacity: 1.0, force: 1.0, azimuth: fmPoint.azimuth, altitude: fmPoint.altitude)
                pkPtArray.append(pkStkPt)
            }
            else if (fmPoint.fmStrokePointType == .roundedCorner)
            {
                var count = 0;
                repeat{
                let pkStkPt = PKStrokePoint.init(location: fmPoint.cgPoint(), timeOffset: 0.1, size: fmPoint.brushSize, opacity: 1.0, force: 1.0, azimuth: fmPoint.azimuth, altitude: fmPoint.altitude)
                pkPtArray.append(pkStkPt)
                count += 1
                } while count < 2
            }
            else if (fmPoint.fmStrokePointType == .hardCorner)
            {
                var count = 0;
                repeat{
                let pkStkPt = PKStrokePoint.init(location: fmPoint.cgPoint(), timeOffset: 0.1, size: fmPoint.brushSize, opacity: 1.0, force: 1.0, azimuth: fmPoint.azimuth, altitude: fmPoint.altitude)
                pkPtArray.append(pkStkPt)
                count += 1
                } while count < 3
            }
        }
        
        return pkPtArray
    }
    */
    
    var pkStrokePathCached : PKStrokePath?
    
    
   
    
    
    func displayUniformBrushTipLive()
    {
        guard (self.arrayOfFMStrokePoints.isEmpty == false) else {
            return
        }
        
        
        self.makeUniformTipBezierPathForLive()
        
        
        standardRepresentationModeDisplay(path: self)
        
         
        // if there is only one line, then
        // there is no fill to show.
        if(
        (self.fmInk.representationMode != .inkColorIsStrokeOnly)
        && (self.fmInk.brushTip == .uniformPath)
        && (self.arrayOfFMStrokePoints.count <= 2)
        )
        {
            let savedLineWidth = self.lineWidth
            self.lineWidth = 2.0;
            NSColor.black.setStroke();
            self.stroke();
            self.lineWidth = 1.0;
            fmInk.mainColor.setStroke();
            self.stroke();
            self.lineWidth = savedLineWidth;
        }
        
        
        /*
        
        if(fmInk.representationMode == .inkColorIsFillOnly)
        {
         
              fmInk.mainColor.set();
              self.fill();
         
        }
        
        
        if(fmInk.representationMode == .inkColorIsStrokeWithSeparateFill)
        {
            if(fmInk.secondColor != nil)
            {
                fmInk.secondColor?.set();
                self.fill();
            }
            else
            {
                fmInk.mainColor.set();
                self.fill();
            }
            
            fmInk.mainColor.setStroke();
            self.stroke();
        }
        
        if(fmInk.representationMode == .inkColorIsStrokeOnly)
        {
            
            fmInk.mainColor.setStroke();
            self.stroke();
            
        }*/
        
       
        
        
    }
    
    func displayUniformBrushTipFinished()
    {
        guard (self.isEmpty == false) else {
            print("displayUniformBrushTipFinished self.isEmpty")
            return
        }
        
        standardRepresentationModeDisplay(path: self)
        
       // displayAllBezierPathPoints()
        
        
        
        /*
        
        if(fmInk.representationMode == .inkColorIsFillOnly)
        {
            
                fmInk.mainColor.set();
                self.fill();
            
        }
        
        
        if(fmInk.representationMode == .inkColorIsStrokeWithSeparateFill)
        {
            if(fmInk.secondColor != nil)
            {
                fmInk.secondColor?.set();
                self.fill();
            }
            else
            {
                fmInk.mainColor.set();
                self.fill();
            }
            
            fmInk.mainColor.setStroke();
            self.stroke();
        }
        
        if(fmInk.representationMode == .inkColorIsStrokeOnly)
        {
            
            fmInk.mainColor.setStroke();
            self.stroke();
            
        }
        
        */
        
        
    }
      
 
    func makeFMStrokeLive2(distanceForInterpolation:CGFloat, tip:FMBrushTip)
    {
        guard (self.arrayOfFMStrokePoints.isEmpty == false) else {
            return
        }

        liveBezierPathArray.removeAll();
        
        let pkStrokePath = self.pkStrokePathCached ?? self.pkStrokePathAcc()
        
  
        
        let interpolatedStrokePathPoints = pkStrokePath.interpolatedPoints(by: PKStrokePath.InterpolatedSlice.Stride.distance(distanceForInterpolation))
        
        var modifiedInterpolatedStrokePathPoints : [PKStrokePoint] = []
        
        var aCounter = 0
        var lastPKIn : PKStrokePoint!
        for interpPKStPoint in interpolatedStrokePathPoints
        {
           
            if(aCounter == 0)
            {
                aCounter += 1;
                
                lastPKIn = interpPKStPoint
                modifiedInterpolatedStrokePathPoints.append(interpPKStPoint)
                continue
            }
            
            // MARK: interpolate points for gaps between this brush shape and the last point
            let d = (NSPoint.distanceBetween(lastPKIn.location, interpPKStPoint.location)) + 1;
            
            if((NSPoint.distanceBetween(lastPKIn.location, interpPKStPoint.location)) > distanceForInterpolation)
            {
                for r in stride(from: 1, to: d, by: distanceForInterpolation / 4.0)
                {
                    
                    let interpolatedPoint = (
                    vDSP.linearInterpolate([interpPKStPoint.location.x.double(),interpPKStPoint.location.y.double()],[lastPKIn.location.x.double(),lastPKIn.location.y.double()], 
                    using: Double(r / d))
                    )
                    
                    let interpolatedNSPoint = NSPoint(x: CGFloat(interpolatedPoint[0]), y: CGFloat(interpolatedPoint[1]))
                    
                    let pkStrokePtToAppend = PKStrokePoint.init(location: interpolatedNSPoint, timeOffset: 0, size: lastPKIn.size, opacity: lastPKIn.opacity, force: lastPKIn.force, azimuth: lastPKIn.azimuth, altitude: lastPKIn.altitude)
                    modifiedInterpolatedStrokePathPoints.append(pkStrokePtToAppend)
                    
                    
                } // END for r in stride(from: 1, to: d, by:
                
                
            }
            
            modifiedInterpolatedStrokePathPoints.append(interpPKStPoint)
            lastPKIn = interpPKStPoint

        }
        
        
        var counter : Int = 0;
        var lastPKPoint : PKStrokePoint!
        
        convexHullPath.removeAllPoints()
       
        for pkPoint in modifiedInterpolatedStrokePathPoints
        {
            if counter == 0
            {
                lastPKPoint = pkPoint
                counter += 1
            
                continue
            }
            
            // LAST BRUSH TIP AND POINT
            let lastBrushTipUntransformedRect = NSMakeRect(0, 0, lastPKPoint.size.width - 1 , lastPKPoint.size.height - 1
            ).centerOnPoint(lastPKPoint.location)
            
            let lastNctRotatedRect : NCTRotatedRect = lastBrushTipUntransformedRect.rotatedAroundPoint(point: lastPKPoint.location, degrees: rad2deg(lastPKPoint.azimuth))
            
            // CURRENT BRUSH TIP AND POINT
            let brushTipUntransformedRect = NSMakeRect(0, 0, pkPoint.size.width , pkPoint.size.height
            ).centerOnPoint(pkPoint.location)
            
            let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: pkPoint.location, degrees: rad2deg(pkPoint.azimuth))
            
            
            
            
            // MARK: ------ hull approach
          
            
                let p = NSBezierPath();
                var arrayOfDots : [[Double]] = [];
                
               var degreeStep : CGFloat = 20
               if (((pkPoint.size.height / pkPoint.size.width) < 10) && (pkPoint.size.width > 80) )
               {
                degreeStep = 10;
               }
                
                if(tip == .ellipse)
                {
                    arrayOfDots.append(contentsOf: lastNctRotatedRect.perimeterEllipsePointsForConvexHull(degreeStep:degreeStep))
                
                    arrayOfDots.append(contentsOf: nctRotatedRect.perimeterEllipsePointsForConvexHull(degreeStep:degreeStep))
                }
                else
                {
                arrayOfDots.append(contentsOf: lastNctRotatedRect.perimenterRectanglePointsForConvexHull() )
                
                arrayOfDots.append(contentsOf: nctRotatedRect.perimenterRectanglePointsForConvexHull() )
                }
                
                let h = Hull(concavity: Double(distanceForInterpolation + max(lastBrushTipUntransformedRect.height, lastBrushTipUntransformedRect.width) + max(brushTipUntransformedRect.height, brushTipUntransformedRect.width) ))
                if let hull = h.hull(arrayOfDots, nil) as? [[Double]]
                {
                    let hullCount = hull.count;
                    
                    for i in 0..<hullCount
                    {
                        
                        let lineToPoint = NSMakePoint(CGFloat(hull[i][0]), CGFloat(hull[i][1]))
                        
                        p.moveToIfEmptyOrLine(to: lineToPoint)
                    }
                    
                    
                    p.close();
                    
                   // NSColor.white.setStroke()
                   // p.stroke()
                    
                    arrayOfDots.removeAll()
                   
                    p.lineWidth = self.lineWidth
                    
                    liveBezierPathArray.append(p)
              
                }
    
                
       
            // LOOP ADVANCEMENT
            lastPKPoint = pkPoint
            counter += 1
            
           
            if(counter == 2)
            {
            //    break
            }
            
        } //END         for pkPoint in pkStrokePath.interpolatedPoints(by: .distance(distanceForInterpolation))


        convexHullPath.removeAllPoints();
        
        
    }
    
    var liveBezierPathArray : [NSBezierPath] = [];
    
    func makeFMStrokeRectangleLive(distanceForInterpolation:CGFloat)
    {
    
        guard (self.arrayOfFMStrokePoints.isEmpty == false) else {
            return
        }
    
        // point arrays
        var stripAPointArray : [NSPoint] = [];
        var stripBPointArray : [NSPoint] = [];
        var mainStripPointArray1 : [NSPoint] = [];
        var mainStripPointArray2 : [NSPoint] = [];
//        var mainStripPointArray3 : [NSPoint] = [];
        
        // currently operated on bezier paths
        var currentlyOperatedOnBezierPathStripA : NSBezierPath = NSBezierPath();
        var currentlyOperatedOnBezierPathStripB : NSBezierPath = NSBezierPath();
        var currentlyOperatedOnBezierPathMainStrip1 : NSBezierPath = NSBezierPath();
        var currentlyOperatedOnBezierPathMainStrip2 : NSBezierPath = NSBezierPath();
//       var currentlyOperatedOnBezierPathMainStrip3 : NSBezierPath = NSBezierPath();

        
        // bezier path arrays
        var bezierPathArrayStripA : [NSBezierPath] = [];
        var bezierPathArrayStripB : [NSBezierPath] = [];
        var bezierPathArrayMainStrip1 : [NSBezierPath] = [];
        var bezierPathArrayMainStrip2 : [NSBezierPath] = [];
//        var bezierPathArrayMainStrip3 : [NSBezierPath] = [];

        
        let pkStrokePath = self.pkStrokePathCached ?? self.pkStrokePathAcc()

            let bPath = NSBezierPath();
            bPath.windingRule = .evenOdd
            bPath.lineJoinStyle = .round
            bPath.lineWidth = 1.0;
        var lastPoints : (strokePoint: NSPoint, pointA: NSPoint, pointB: NSPoint) = (.zero,.zero,.zero);
        var lastQuadrant : Int = 0;
//        var lastAngle : Int = 0;
        var counter = 0;
        var lastNctRotatedRect : NCTRotatedRect?
        


        bezierPathArrayStripA.append(currentlyOperatedOnBezierPathStripA);
        bezierPathArrayStripB.append(currentlyOperatedOnBezierPathStripB)
        bezierPathArrayMainStrip1.append(currentlyOperatedOnBezierPathMainStrip1);
        bezierPathArrayMainStrip2.append(currentlyOperatedOnBezierPathMainStrip2);

        var didAppendBrushTip = false;
        
        var bezierTipStampArray : [NSBezierPath] = [];
        
       // var distanceForInterpolation : CGFloat = 10;
        
        var distanceForInterpolationToUse = distanceForInterpolation
        if(self.arrayOfFMStrokePoints.first!.brushSize.width < 7)
        {
                distanceForInterpolationToUse = 10;
        }
        
        for pkPoint in pkStrokePath.interpolatedPoints(by: .distance(distanceForInterpolationToUse))
        {
        
            //          pkPoint.location.fillSquare3x3AtPoint(color: NSColor.white)
        
            let brushTipUntransformedRect = NSMakeRect(0, 0, pkPoint.size.width , pkPoint.size.height
            )
            let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: pkPoint.location, degrees: rad2deg(pkPoint.azimuth))
           
            
                 /*
                    if(counter == 0)
                    {
                    
                        currentlyOperatedOnBezierPathMainStrip3.move(to: nctRotatedRect.bottomRight)
                       
                        currentlyOperatedOnBezierPathMainStrip3.line(to: nctRotatedRect.bottomLeft)
                        
                    }
                    else if(counter == 1)
                    {
                        currentlyOperatedOnBezierPathMainStrip3.line(to: nctRotatedRect.bottomLeft)
                        currentlyOperatedOnBezierPathMainStrip3.line(to: nctRotatedRect.bottomRight)
                                        
                    }
                    else if(counter % 2 == 0)
                    {
                        currentlyOperatedOnBezierPathMainStrip3.move(to: nctRotatedRect.bottomRight)
                        currentlyOperatedOnBezierPathMainStrip3.line(to: nctRotatedRect.bottomLeft)
                    
                    }
                    else // odd
                    {
                        currentlyOperatedOnBezierPathMainStrip3.line(to: nctRotatedRect.bottomLeft)
                        currentlyOperatedOnBezierPathMainStrip3.line(to: nctRotatedRect.bottomRight)
                    }*/
                    
            /*
            // ---DEBUG
            NSColor.darkGray.setStroke()

            nctRotatedRect.stroke();
            
            nctRotatedRect.bottomRight.fillSquare3x3AtPoint(color: NSColor.red) // top right
            nctRotatedRect.bottomLeft.fillSquare3x3AtPoint(color: NSColor.green) // top left
         
            nctRotatedRect.topRight.fillSquare3x3AtPoint(color: NSColor.blue) // bottom right
            nctRotatedRect.topLeft.fillSquare3x3AtPoint(color: NSColor.yellow) // bottom left
            nctRotatedRect.stroke();*/
     
            var quadrant : Int = 0;
            if(counter != 0)
            {

                // MARK: CURRENT ANGLE FOR BRUSH TIP STAMP
                var a = rad2deg(atan2(pkPoint.location.x - lastPoints.strokePoint.x , pkPoint.location.y - lastPoints.strokePoint.y ))
                if(a < 0)
                {
                    a = 360 + a;
                }
                
                 a = floor(a) - 90
                 
                 if( a < 0)
                 {
                    a = 360 + a;

                 }
                
                
                var correlateAngle : CGFloat = 0;
                if( a < 180)
                {
                    correlateAngle = a + 180;
                }
                else
                {
                    correlateAngle = a - 180;
                }
                
//                Int(a).drawAtPoint(pkPoint.location)
                
//                let angleRange1 = (correlateAngle - 6)...(correlateAngle + 6)
                
//                let angleRange2 = (a - 6)...(a + 6)
                
                let convertedToDegAzimuth = floor(rad2deg(pkPoint.azimuth))
                
                if(
                ((convertedToDegAzimuth >= (a - 5)) &&
                (convertedToDegAzimuth <= (a + 5))
                ) ||
                
                ((convertedToDegAzimuth >= (correlateAngle - 5)) &&
                (convertedToDegAzimuth <= (correlateAngle + 5))
                )
                
                    && (didAppendBrushTip == false)
                )
                {
                         var c = [nctRotatedRect.bottomLeft,nctRotatedRect.topLeft,nctRotatedRect.topRight,nctRotatedRect.bottomRight,nctRotatedRect.bottomLeft,];
                    
                    let p = NSBezierPath()
                    p.appendPoints(&c, count: c.count)
                p.close()
                bezierTipStampArray.append(p)
                                    didAppendBrushTip = true;

//                pkPoint.location.fillSquare3x3AtPoint(color: NSColor.blue)

                }
                else if(didAppendBrushTip == true)
                {
                    didAppendBrushTip = false;
                }
                
  
                quadrant = NSBezierPath.quadrantFrom(point1: lastPoints.strokePoint, point2: pkPoint.location)
           
                /// if quadrant changes,
                /// start new path
                
               

                if((lastQuadrant != quadrant) && (counter > 1) )
                {
                    currentlyOperatedOnBezierPathStripA.appendPoints(&stripAPointArray, count: stripAPointArray.count)
                    currentlyOperatedOnBezierPathStripB.appendPoints(&stripBPointArray, count: stripBPointArray.count)
                    
                    currentlyOperatedOnBezierPathMainStrip1.appendPoints(&mainStripPointArray1, count: mainStripPointArray1.count)
                    currentlyOperatedOnBezierPathMainStrip2.appendPoints(&mainStripPointArray2, count: mainStripPointArray2.count)

                    let restartP1 = mainStripPointArray1[mainStripPointArray1.count - 1]
                    let restartP2 = mainStripPointArray1[0]
                    let restartP1_2 = mainStripPointArray2[mainStripPointArray2.count - 1]
                    let restartP2_2 = mainStripPointArray2[0]
    
                    /* DEBUG
                     let r = NSRect.init(origin: restartP1, size: NSSize.init(width: 10, height: 10)).centerOnPoint(restartP1)
                     NSColor.white.setFill();
                     
                     r.fill();
                     
                     let r2 = NSRect.init(origin: restartP2, size: NSSize.init(width: 10, height: 10)).centerOnPoint(restartP2)
                     NSColor.white.setFill();
                    r2.fill()
                    */
                   
                    stripAPointArray.removeAll();
                    stripBPointArray.removeAll();
                    mainStripPointArray1.removeAll();
                    mainStripPointArray2.removeAll();

                    currentlyOperatedOnBezierPathStripA = NSBezierPath();
                    currentlyOperatedOnBezierPathStripB = NSBezierPath();
                    currentlyOperatedOnBezierPathMainStrip1 = NSBezierPath();
                    currentlyOperatedOnBezierPathMainStrip2 = NSBezierPath();
//                    currentlyOperatedOnBezierPathMainStrip3 = NSBezierPath();

                
                    mainStripPointArray1.append(restartP1)
                    mainStripPointArray1.insert(restartP2, at: 0)
                    mainStripPointArray2.append(restartP1_2)
                    mainStripPointArray2.insert(restartP2_2, at: 0)
                   
                    bezierPathArrayStripA.append(currentlyOperatedOnBezierPathStripA)
                    bezierPathArrayStripB.append(currentlyOperatedOnBezierPathStripB)
                    bezierPathArrayMainStrip1.append(currentlyOperatedOnBezierPathMainStrip1)
                    bezierPathArrayMainStrip2.append(currentlyOperatedOnBezierPathMainStrip2)
//                    bezierPathArrayMainStrip3.append(currentlyOperatedOnBezierPathMainStrip3)

                    
                    var pointsForTipPath = [lastNctRotatedRect!.bottomLeft,lastNctRotatedRect!.topLeft,lastNctRotatedRect!.topRight,lastNctRotatedRect!.bottomRight,lastNctRotatedRect!.bottomLeft,];
                    
                    let tipPath = NSBezierPath()
                    tipPath.appendPoints(&pointsForTipPath, count: pointsForTipPath.count)
                    tipPath.close()
                   // bezierTipStampArray.append(tipPath)
                    
                  //   lastPoints.strokePoint.fillSquare3x3AtPoint(color: NSColor.cyan)

                    
                    /*
                     let nctRotatedRect2 : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: lastPoints.pointA, degrees: rad2deg(pkPoint.azimuth))
                    */
                    var pointsForTipPath2 =  [nctRotatedRect.bottomLeft,nctRotatedRect.topLeft,nctRotatedRect.topRight,nctRotatedRect.bottomRight,nctRotatedRect.bottomLeft];
                    
                    let tipPath2 = NSBezierPath()
                    tipPath2.appendPoints(&pointsForTipPath2, count: pointsForTipPath2.count)
                    tipPath2.close()
                 bezierTipStampArray.append(tipPath2)
                    
                    
                    // pkPoint.location.fillSquare3x3AtPoint(color: NSColor.green)
                     
                }

            }
           
            let pointA = pkPoint.location.pointFromAngleAndLength(angleRadians: -pkPoint.azimuth, length: pkPoint.size.width / 2.0)//.fillSquare3x3AtPoint();
            
            let pointB = pkPoint.location.pointFromAngleAndLength(angleRadians: -pkPoint.azimuth, length: -pkPoint.size.width / 2.0)//.fillSquare3x3AtPoint();
            
            
            /*
            if(counter == 0)
            {
            currentlyOperatedOnBezierPathMainStrip1.move(to: nctRotatedRect.bottomLeft)
                        currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomRight)
            }
             else  if(counter % 2 == 0)
                    {
                       currentlyOperatedOnBezierPathMainStrip1.move(to: nctRotatedRect.bottomLeft)
                        currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomRight)
                   //     currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomLeft)
                     //   currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.topLeft)
                       // currentlyOperatedOnBezierPathMainStrip1.close()
                    }
                    else
                    {
                      currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomRight)
                        currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomLeft)
                        currentlyOperatedOnBezierPathMainStrip1.close()
                        
                        
                    }
        */
        
           
                    
            if(lastNctRotatedRect != nil)
            {
                //if(quadrant > 0)
              //  {

                if(counter == 1)
                {
                    mainStripPointArray1.append(lastNctRotatedRect!.topLeft)
                    mainStripPointArray1.insert(lastNctRotatedRect!.topRight, at: 0)
                    mainStripPointArray2.append(lastNctRotatedRect!.bottomLeft)
                    mainStripPointArray2.insert(lastNctRotatedRect!.bottomRight, at: 0)
                    
                }
                    
                    stripAPointArray.append(lastNctRotatedRect!.topRight)
                    stripAPointArray.append(nctRotatedRect.topRight)
                    
                    stripAPointArray.insert(lastNctRotatedRect!.bottomRight, at: 0)
                    stripAPointArray.insert(nctRotatedRect.bottomRight, at: 0)
                    
                    mainStripPointArray1.append(nctRotatedRect.topLeft)
                    mainStripPointArray1.insert(nctRotatedRect.topRight, at: 0)
                    mainStripPointArray2.append(nctRotatedRect.bottomLeft)
                    mainStripPointArray2.insert(nctRotatedRect.bottomRight, at: 0)


               
                    
                    
                    stripBPointArray.append(lastNctRotatedRect!.topLeft)
                    stripBPointArray.append(nctRotatedRect.topLeft)
                    
                    stripBPointArray.insert(lastNctRotatedRect!.bottomLeft, at: 0)
                    stripBPointArray.insert(nctRotatedRect.bottomLeft, at: 0)

               // }


            }
         
            lastQuadrant = quadrant;
            lastNctRotatedRect = nctRotatedRect;
            lastPoints = (pkPoint.location, pointA, pointB)
            counter += 1;
        }

        currentlyOperatedOnBezierPathStripA.appendPoints(&stripAPointArray, count: stripAPointArray.count)
        currentlyOperatedOnBezierPathStripB.appendPoints(&stripBPointArray, count: stripBPointArray.count)
        currentlyOperatedOnBezierPathMainStrip1.appendPoints(&mainStripPointArray1, count: mainStripPointArray1.count)
        currentlyOperatedOnBezierPathMainStrip2.appendPoints(&mainStripPointArray2, count: mainStripPointArray2.count)
        
        
        for (index, fmStrokePoint) in self.arrayOfFMStrokePoints.enumerated()
        {
            
            let array : [FMStrokePointType] = [.hardCorner,.hardCornerBowedLine/*,.roundedCorner,.roundedCornerBowedLine*/]
            if(array.contains(fmStrokePoint.fmStrokePointType) || (index == 0) || (index == arrayOfFMStrokePoints.count - 1))
            {
            
                let brushTipUntransformedRect = NSMakeRect(0, 0, fmStrokePoint.brushSize.width , fmStrokePoint.brushSize.height)
           
            // fmStrokePoint.cgPoint().fillSquare3x3AtPoint(color: NSColor.orange)

            let cgP = fmStrokePoint.cgPoint()
            /*if(fmStrokePoint.fmStrokePointType == .roundedCorner)
            {
            
                let a : [PKStrokePoint] = fmStrokePoint.pkStrokePointsArrayForFMStrokePoint(parentArrayFMStrokePointIndex: index, parentArrayPassed: arrayOfFMStrokePoints)
                
                for a1 in a
                {
                    a1.location.fillSquare3x3AtPoint(color: NSColor.orange)
                }
                
            }*/
            
            
            let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: cgP, degrees: rad2deg(fmStrokePoint.azimuth))
            
            
            
            
            let p = NSBezierPath()
            var pA = nctRotatedRect.perimenterRectanglePoints()
            p.appendPoints(&pA, count: pA.count)

                bezierTipStampArray.append(p)

            }
            
        }


    /*
        for p in pkStrokePath.interpolatedPoints(by: .parametricStep(1.0))
        {
            
             let brushTipUntransformedRect = NSMakeRect(0, 0, p.size.width , p.size.height)
             
                 let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: p.location, degrees: rad2deg(p.azimuth))
            
        
            let p = NSBezierPath()
            var pA = nctRotatedRect.perimenterRectanglePoints()
            p.appendPoints(&pA, count: pA.count)

                bezierTipStampArray.append(p)
            
        }
        */

        
        liveBezierPathArray.removeAll()

        
        
//        fmInk.mainColor.set()
        for path in bezierPathArrayStripA
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
            path.lineWidth = self.lineWidth
//            NSColor.green.withAlphaComponent(0.5).set()
//            path.stroke();
           
//            path.fill();
            
            
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
        
        liveBezierPathArray.append(contentsOf: bezierPathArrayStripA)
        
        
        for path in bezierPathArrayStripB
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
            path.lineWidth = self.lineWidth
//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.cyan.setFill()

            
//            path.fill();
//            path.stroke();
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
        
        liveBezierPathArray.append(contentsOf: bezierPathArrayStripB)
        
        for path in bezierPathArrayMainStrip1
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
            path.lineWidth = self.lineWidth
            path.close()
//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.black.setFill()
          
//            path.fill();
//            path.stroke();
         
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }

        liveBezierPathArray.append(contentsOf: bezierPathArrayMainStrip1)
     
        for path in bezierPathArrayMainStrip2
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
            path.lineWidth = self.lineWidth
            path.close()
//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.white.setStroke()
            
//            path.fill();

//            path.stroke();
            
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
        
        liveBezierPathArray.append(contentsOf: bezierPathArrayMainStrip2)


        for path in bezierTipStampArray
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
            path.lineWidth = self.lineWidth
//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.white.setStroke();

//            path.stroke();
//            path.fill();
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
  
        liveBezierPathArray.append(contentsOf: bezierTipStampArray)
        
        /*
        NSColor.green.setFill()
        if(currentlyOperatedOnBezierPathMainStrip3.isEmpty == false)
        {
        currentlyOperatedOnBezierPathMainStrip3.fill()
        }
        */
        
        /*
        let p1 = pkStrokePath.interpolatedPoint(at: 0)
        let p2 = pkStrokePath.interpolatedPoint(at: CGFloat((pkStrokePath.count - 1)))
        
        for pkPoint in [p1,p2]
        {
        
               let brushTipUntransformedRect = NSMakeRect(0, 0, pkPoint.size.width , pkPoint.size.width * heightFactor)
            let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: pkPoint.location, degrees: rad2deg(pkPoint.azimuth))
            
            let p = NSBezierPath()
            var pA = nctRotatedRect.perimenterRectanglePoints()
            p.appendPoints(&pA, count: pA.count)
            
            NSColor.white.setStroke();
            p.fill();
            p.stroke();
        }
        */
       

        
//        let bb = NSBezierPath();
//        bb.windingRule = .nonZero
//
//         bb.appendPoints(&mainStripPointArray1, count: mainStripPointArray1.count)
//         bb.fill()
         
    }

    func displayFMStrokeEllipseLive()
    {
    
        guard (self.arrayOfFMStrokePoints.isEmpty == false) else {
            return
        }
    
        // point arrays
        var stripAPointArray : [NSPoint] = [];
        var stripBPointArray : [NSPoint] = [];
        var lastTwoStripA :[NSPoint] = [];
        var lastTwoStripB :[NSPoint] = [];
        
        var mainStripPointArray1 : [NSPoint] = [];
        var mainStripPointArray2 : [NSPoint] = [];
//        var mainStripPointArray3 : [NSPoint] = [];
        
        // currently operated on bezier paths
        var currentlyOperatedOnBezierPathStripA : NSBezierPath = NSBezierPath();
        var currentlyOperatedOnBezierPathStripB : NSBezierPath = NSBezierPath();
        var currentlyOperatedOnBezierPathMainStrip1 : NSBezierPath = NSBezierPath();
        var currentlyOperatedOnBezierPathMainStrip2 : NSBezierPath = NSBezierPath();
//       var currentlyOperatedOnBezierPathMainStrip3 : NSBezierPath = NSBezierPath();

        
        // bezier path arrays
        var bezierPathArrayStripA : [NSBezierPath] = [];
        var bezierPathArrayStripB : [NSBezierPath] = [];
        var bezierPathArrayMainStrip1 : [NSBezierPath] = [];
        var bezierPathArrayMainStrip2 : [NSBezierPath] = [];
//        var bezierPathArrayMainStrip3 : [NSBezierPath] = [];

        
        let pkStrokePath = self.pkStrokePathCached ?? self.pkStrokePathAcc()

            let bPath = NSBezierPath();
            bPath.windingRule = .evenOdd
            bPath.lineJoinStyle = .round
            bPath.lineWidth = 1.0;
        var lastPoints : (strokePoint: NSPoint, pointA: NSPoint, pointB: NSPoint) = (.zero,.zero,.zero);
        var lastQuadrant : Int = 0;
//        var lastAngle : Int = 0;
        var counter = 0;
        var lastNctRotatedRect : NCTRotatedRect?
        


        bezierPathArrayStripA.append(currentlyOperatedOnBezierPathStripA);
        bezierPathArrayStripB.append(currentlyOperatedOnBezierPathStripB)
        bezierPathArrayMainStrip1.append(currentlyOperatedOnBezierPathMainStrip1);
        bezierPathArrayMainStrip2.append(currentlyOperatedOnBezierPathMainStrip2);

        var didAppendBrushTip = false;
        
        var bezierTipStampArray : [NSBezierPath] = [];
        
        var distanceForInterpolation : CGFloat = 10;
        
        if(self.arrayOfFMStrokePoints.first!.brushSize.width < 7)
        {
                distanceForInterpolation = 10;
        }
        
//        let baseRectPath = NSBezierPath();
//        var rotatedBrush = NSBezierPath();
        
        for pkPoint in pkStrokePath.interpolatedPoints(by: .distance(distanceForInterpolation))
        {
        
            // pkPoint.location.fillSquare3x3AtPoint(color: NSColor.white)
        
            let brushTipUntransformedRect = NSMakeRect(0, 0, pkPoint.size.width , pkPoint.size.height
            ).centerOnPoint(pkPoint.location)
            
            let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: pkPoint.location, degrees: rad2deg(pkPoint.azimuth))
            
     
        /*
            baseRectPath.appendOval(in: brushTipUntransformedRect)
            
            rotatedBrush.removeAllPoints();
            rotatedBrush.appendPathRotatedAboutCenterPoint(path: baseRectPath, angleDegrees: rad2deg(pkPoint.azimuth), centerPoint: pkPoint.location)
            let flattedBrushPath = rotatedBrush.flattened;
            var closestPointA : NSPoint = .zero
            
            var closestPointB : NSPoint = .zero
            
            var points : [NSPoint] = Array.init(repeating: .zero, count: 3)
            for pIndex in 0..<flattedBrushPath.elementCount
            {
               flattedBrushPath.element(at: pIndex, associatedPoints: &points)
//               if( closestPointA.distanceFrom(point2: points[0]) )
               
            }*/
                
            /*
            // ---DEBUG
            NSColor.darkGray.setStroke()

            nctRotatedRect.stroke();
            
            nctRotatedRect.bottomRight.fillSquare3x3AtPoint(color: NSColor.red) // top right
            nctRotatedRect.bottomLeft.fillSquare3x3AtPoint(color: NSColor.green) // top left
         
            nctRotatedRect.topRight.fillSquare3x3AtPoint(color: NSColor.blue) // bottom right
            nctRotatedRect.topLeft.fillSquare3x3AtPoint(color: NSColor.yellow) // bottom left
            nctRotatedRect.stroke();*/
     
            var quadrant : Int = 0;
            var a : CGFloat = 0;
            if(counter != 0)
            {

                // MARK: CURRENT ANGLE FOR BRUSH TIP STAMP
                 a = rad2deg(atan2(pkPoint.location.x - lastPoints.strokePoint.x , pkPoint.location.y - lastPoints.strokePoint.y ))
                if(a < 0)
                {
                    a = 360 + a;
                }
                
                 a = floor(a) - 90
                 
                 if( a < 0)
                 {
                    a = 360 + a;

                 }
                
                
                var correlateAngle : CGFloat = 0;
                if( a < 180)
                {
                    correlateAngle = a + 180;
                }
                else
                {
                    correlateAngle = a - 180;
                }
                
//                Int(a).drawAtPoint(pkPoint.location)
                
//                let angleRange1 = (correlateAngle - 6)...(correlateAngle + 6)
                
//                let angleRange2 = (a - 6)...(a + 6)
                
                let convertedToDegAzimuth = floor(rad2deg(pkPoint.azimuth))
                
                if(
                ((convertedToDegAzimuth >= (a - 5)) &&
                (convertedToDegAzimuth <= (a + 5))
                ) ||
                
                ((convertedToDegAzimuth >= (correlateAngle - 5)) &&
                (convertedToDegAzimuth <= (correlateAngle + 5))
                )
                
                    && (didAppendBrushTip == false)
                )
                {
                
                         var c = nctRotatedRect.perimeterEllipsePoints(degreeStep:2)
                         
                    let p = NSBezierPath()
                    p.appendPoints(&c, count: c.count)
                p.close()
                bezierTipStampArray.append(p)
                                    didAppendBrushTip = true;
                

//                pkPoint.location.fillSquare3x3AtPoint(color: NSColor.blue)

                }
                else if(didAppendBrushTip == true)
                {
                    didAppendBrushTip = false;
                }
                
  
                quadrant = NSBezierPath.quadrantFrom(point1: lastPoints.strokePoint, point2: pkPoint.location)
           
                /// if quadrant changes,
                /// start new path
                
               

                if((lastQuadrant != quadrant) && (counter > 1) )
                {
                    currentlyOperatedOnBezierPathStripA.appendPoints(&stripAPointArray, count: stripAPointArray.count)
                    currentlyOperatedOnBezierPathStripB.appendPoints(&stripBPointArray, count: stripBPointArray.count)
                    
                    
                    currentlyOperatedOnBezierPathMainStrip1.appendPoints(&mainStripPointArray1, count: mainStripPointArray1.count)
                    currentlyOperatedOnBezierPathMainStrip2.appendPoints(&mainStripPointArray2, count: mainStripPointArray2.count)

                    let restartP1 = mainStripPointArray1[mainStripPointArray1.count - 1]
                    let restartP2 = mainStripPointArray1[0]
                    let restartP1_2 = mainStripPointArray2[mainStripPointArray2.count - 1]
                    let restartP2_2 = mainStripPointArray2[0]
    
                    /* DEBUG
                     let r = NSRect.init(origin: restartP1, size: NSSize.init(width: 10, height: 10)).centerOnPoint(restartP1)
                     NSColor.white.setFill();
                     
                     r.fill();
                     
                     let r2 = NSRect.init(origin: restartP2, size: NSSize.init(width: 10, height: 10)).centerOnPoint(restartP2)
                     NSColor.white.setFill();
                    r2.fill()
                    */
                   
                    stripAPointArray.removeAll();
                    stripBPointArray.removeAll();
                    mainStripPointArray1.removeAll();
                    mainStripPointArray2.removeAll();

                    currentlyOperatedOnBezierPathStripA = NSBezierPath();
                    currentlyOperatedOnBezierPathStripB = NSBezierPath();
                    currentlyOperatedOnBezierPathMainStrip1 = NSBezierPath();
                    currentlyOperatedOnBezierPathMainStrip2 = NSBezierPath();
//                    currentlyOperatedOnBezierPathMainStrip3 = NSBezierPath();

                
                    mainStripPointArray1.append(restartP1)
                    mainStripPointArray1.insert(restartP2, at: 0)
                    mainStripPointArray2.append(restartP1_2)
                    mainStripPointArray2.insert(restartP2_2, at: 0)
                
                   
                    bezierPathArrayStripA.append(currentlyOperatedOnBezierPathStripA)
                    bezierPathArrayStripB.append(currentlyOperatedOnBezierPathStripB)
                    bezierPathArrayMainStrip1.append(currentlyOperatedOnBezierPathMainStrip1)
                    bezierPathArrayMainStrip2.append(currentlyOperatedOnBezierPathMainStrip2)
//                    bezierPathArrayMainStrip3.append(currentlyOperatedOnBezierPathMainStrip3)

                    
                    var pointsForTipPath = lastNctRotatedRect!.perimeterEllipsePoints(degreeStep:2)

                    
                    let tipPath = NSBezierPath()
                    tipPath.appendPoints(&pointsForTipPath, count: pointsForTipPath.count)
                    tipPath.close()
                    bezierTipStampArray.append(tipPath)
                    
                  //   lastPoints.strokePoint.fillSquare3x3AtPoint(color: NSColor.cyan)

                    
                    /*
                     let nctRotatedRect2 : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: lastPoints.pointA, degrees: rad2deg(pkPoint.azimuth))
                    */
                    var pointsForTipPath2 =  [nctRotatedRect.middleLeft,nctRotatedRect.bottomMiddle,nctRotatedRect.middleRight,nctRotatedRect.topMiddle,nctRotatedRect.middleLeft];
                    
                    let tipPath2 = NSBezierPath()
                    tipPath2.appendPoints(&pointsForTipPath2, count: pointsForTipPath2.count)
                    tipPath2.close()
                 bezierTipStampArray.append(tipPath2)
                    
                    
                    // pkPoint.location.fillSquare3x3AtPoint(color: NSColor.green)
                     
                }

            }
           
            let pointA = pkPoint.location.pointFromAngleAndLength(angleRadians: -pkPoint.azimuth, length: pkPoint.size.width / 2.0)//.fillSquare3x3AtPoint();
            
            let pointB = pkPoint.location.pointFromAngleAndLength(angleRadians: -pkPoint.azimuth, length: -pkPoint.size.width / 2.0)//.fillSquare3x3AtPoint();
            
            
            /*
            if(counter == 0)
            {
            currentlyOperatedOnBezierPathMainStrip1.move(to: nctRotatedRect.bottomLeft)
                        currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomRight)
            }
             else  if(counter % 2 == 0)
                    {
                       currentlyOperatedOnBezierPathMainStrip1.move(to: nctRotatedRect.bottomLeft)
                        currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomRight)
                   //     currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomLeft)
                     //   currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.topLeft)
                       // currentlyOperatedOnBezierPathMainStrip1.close()
                    }
                    else
                    {
                      currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomRight)
                        currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomLeft)
                        currentlyOperatedOnBezierPathMainStrip1.close()
                        
                        
                    }
        */

            if(counter == 0)
            {
                
                stripAPointArray.append(nctRotatedRect.ellipsePointAtAngle(radians: 0.25 * .pi))
                stripAPointArray.insert( nctRotatedRect.ellipsePointAtAngle(radians: 1.25 * .pi), at: 0)
                
                stripBPointArray.append(nctRotatedRect.ellipsePointAtAngle(radians: 0.75 * .pi))
                stripBPointArray.insert( nctRotatedRect.ellipsePointAtAngle(radians: 1.75 * .pi), at: 0)
                
                
            }
           
                    
            if(lastNctRotatedRect != nil)
            {
            

                if(counter == 1)
                {
                    mainStripPointArray1.append(lastNctRotatedRect!.middleLeft)
                    mainStripPointArray1.append(nctRotatedRect.middleLeft)
                    
                    mainStripPointArray1.insert(lastNctRotatedRect!.middleRight, at: 0)
                    mainStripPointArray1.insert(nctRotatedRect.middleRight, at: 0)
                }
                
             
                
                    
                /*
                mainStripPointArray1.append(nctRotatedRect.topLeft)
                mainStripPointArray1.insert(nctRotatedRect.topRight, at: 0)
                mainStripPointArray2.append(nctRotatedRect.bottomLeft)
                mainStripPointArray2.insert(nctRotatedRect.bottomRight, at: 0)
*/

                // HORIZONTAL IS ARRAY 1
                mainStripPointArray1.append(lastNctRotatedRect!.middleLeft)
                mainStripPointArray1.append(nctRotatedRect.middleLeft)
                
                mainStripPointArray1.insert(lastNctRotatedRect!.middleRight, at: 0)
                mainStripPointArray1.insert(nctRotatedRect.middleRight, at: 0)
                
                // VERTICAL IS ARRAY 1
                mainStripPointArray2.append(lastNctRotatedRect!.topMiddle)
                mainStripPointArray2.append(nctRotatedRect.topMiddle)
                
                mainStripPointArray2.insert(lastNctRotatedRect!.bottomMiddle, at: 0)
                mainStripPointArray2.insert(nctRotatedRect.bottomMiddle, at: 0)
                
   /*
                stripBPointArray.append(lastNctRotatedRect!.topMiddle)
                stripBPointArray.append(nctRotatedRect.topMiddle)
                
                stripBPointArray.insert(lastNctRotatedRect!.bottomMiddle, at: 0)
                stripBPointArray.insert(nctRotatedRect.bottomMiddle, at: 0)
                
                
               
                stripAPointArray.append(lastNctRotatedRect!.topMiddle)
                stripAPointArray.append(nctRotatedRect.topMiddle)
                
                stripAPointArray.insert(lastNctRotatedRect!.bottomMiddle, at: 0)
                stripAPointArray.insert(nctRotatedRect.bottomRight, at: 0)
                */


           let xRad = brushTipUntransformedRect.width / 2;
                let yRad = brushTipUntransformedRect.height / 2;
//                let a2 = rad2deg(atan2(pkPoint.location.x - lastPoints.strokePoint.x , pkPoint.location.y - lastPoints.strokePoint.y ))
                
                let x1 = brushTipUntransformedRect.centroid().x
                    +
                    ( (xRad * cos(deg2rad( 45)))    )
                
                let y1 = brushTipUntransformedRect.centroid().y +
                    ( (yRad * sin(deg2rad( 45)))   )

                let x2 = brushTipUntransformedRect.centroid().x
                    +
                    ( (xRad * cos(deg2rad( 225)))    )
                
                let y2 = brushTipUntransformedRect.centroid().y +
                    ( (yRad * sin(deg2rad( 225)))   )

                let x3 = brushTipUntransformedRect.centroid().x
                    +
                    ( (xRad * cos(deg2rad( 135)))    )
                
                let y3 = brushTipUntransformedRect.centroid().y +
                    ( (yRad * sin(deg2rad( 135)))   )
                    
                let x4 = brushTipUntransformedRect.centroid().x
                    +
                    ( (xRad * cos(deg2rad( 315)))    )
                
                let y4 = brushTipUntransformedRect.centroid().y +
                    ( (yRad * sin(deg2rad( 315)))   )
                
                let p = NSMakePoint(x1, y1)
                let xfm = RotationTransform(angleRadians:  -pkPoint.azimuth, centerPoint: brushTipUntransformedRect.centroid())
                let p45 = xfm.transform(p)
                let p225 = xfm.transform(NSMakePoint(x2, y2))
                let p135 = xfm.transform(NSMakePoint(x3, y3))
                let p315 = xfm.transform(NSMakePoint(x4, y4))
//                p45.fillSquare3x3AtPoint(color: NSColor.white)
                
//                p235.fillSquare3x3AtPoint(color: NSColor.white)

                if(lastTwoStripA.isEmpty == false)
                {
                //  stripAPointArray.append(lastNctRotatedRect!.pointAtAngle(radians: deg2rad(45)))
                    stripAPointArray.append(lastTwoStripA[0])
                }
                /*else
                {
                    stripAPointArray.append(lastNctRotatedRect!.ellipsePointAtAngle(radians: deg2rad(45)))
                }*/
              
                stripAPointArray.append(p45)
                
                
                
                
                if(lastTwoStripA.isEmpty == false)
                {
                stripAPointArray.insert(lastTwoStripA[1], at: 0)
                //stripAPointArray.append(lastTwoStripA[1])
                
                }
                /*else
                {
                    stripAPointArray.insert(lastNctRotatedRect!.ellipsePointAtAngle(radians: deg2rad(235)), at: 0)

                }*/
                
                
                 stripAPointArray.insert(p225, at: 0)

                lastTwoStripA = [p45,p225]
  
  
  
  
                if(lastTwoStripB.isEmpty == false)
                {
                
                    stripBPointArray.append(lastTwoStripB[0])
                }
                stripBPointArray.append(p135)
                
                
                 if(lastTwoStripB.isEmpty == false)
                {
                    
                    stripBPointArray.insert(lastTwoStripB[1], at: 0)
                }
                /*else
                {
                    stripAPointArray.insert(lastNctRotatedRect!.ellipsePointAtAngle(radians: deg2rad(315)), at: 0)
                }*/
                
                stripBPointArray.insert(p315, at: 0)
                
                lastTwoStripB = [p135,p315]
                


                    /*
                    stripBPointArray.append(lastNctRotatedRect!.middleLeft.midpoint(pointB: nctRotatedRect.topMiddle))
                    stripBPointArray.append(nctRotatedRect.middleLeft.midpoint(pointB: nctRotatedRect.topMiddle))
                    */
                    /*
                    stripBPointArray.insert(lastNctRotatedRect!.middleRight.midpoint(pointB: nctRotatedRect.topMiddle), at: 0)
                    stripBPointArray.insert(nctRotatedRect.middleRight.midpoint(pointB: nctRotatedRect.topMiddle), at: 0)
                    */
                    
               // }


            }
         
            lastQuadrant = quadrant;
            lastNctRotatedRect = nctRotatedRect;
            lastPoints = (pkPoint.location, pointA, pointB)
            counter += 1;
        }

        currentlyOperatedOnBezierPathStripA.appendPoints(&stripAPointArray, count: stripAPointArray.count)
        currentlyOperatedOnBezierPathStripB.appendPoints(&stripBPointArray, count: stripBPointArray.count)
        currentlyOperatedOnBezierPathMainStrip1.appendPoints(&mainStripPointArray1, count: mainStripPointArray1.count)
        currentlyOperatedOnBezierPathMainStrip2.appendPoints(&mainStripPointArray2, count: mainStripPointArray2.count)
        
        
        for (index, fmStrokePoint) in self.arrayOfFMStrokePoints.enumerated()
        {
            
            let array : [FMStrokePointType] = [.hardCorner,.hardCornerBowedLine/*,.roundedCorner,.roundedCornerBowedLine*/]
            if(array.contains(fmStrokePoint.fmStrokePointType) || (index == 0) || (index == arrayOfFMStrokePoints.count - 1))
            {
            
                let brushTipUntransformedRect = NSMakeRect(0, 0, fmStrokePoint.brushSize.width , fmStrokePoint.brushSize.height)
           
            // fmStrokePoint.cgPoint().fillSquare3x3AtPoint(color: NSColor.orange)

            let cgP = fmStrokePoint.cgPoint()
            /*if(fmStrokePoint.fmStrokePointType == .roundedCorner)
            {
            
                let a : [PKStrokePoint] = fmStrokePoint.pkStrokePointsArrayForFMStrokePoint(parentArrayFMStrokePointIndex: index, parentArrayPassed: arrayOfFMStrokePoints)
                
                for a1 in a
                {
                    a1.location.fillSquare3x3AtPoint(color: NSColor.orange)
                }
                
            }*/
            
            
            let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: cgP, degrees: rad2deg(fmStrokePoint.azimuth))
            
            
            
            
            let p = NSBezierPath()
            var pA = nctRotatedRect.perimeterEllipsePoints(degreeStep:2)
            p.appendPoints(&pA, count: pA.count)

                bezierTipStampArray.append(p)

            }
            
        }


    /*
        for p in pkStrokePath.interpolatedPoints(by: .parametricStep(1.0))
        {
            
             let brushTipUntransformedRect = NSMakeRect(0, 0, p.size.width , p.size.height)
             
                 let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: p.location, degrees: rad2deg(p.azimuth))
            
        
            let p = NSBezierPath()
            var pA = nctRotatedRect.perimenterRectanglePoints()
            p.appendPoints(&pA, count: pA.count)

                bezierTipStampArray.append(p)
            
        }
        */

        
        liveBezierPathArray.removeAll()

        
        
        fmInk.mainColor.set()
        

        for path in bezierPathArrayStripA
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
//            NSColor.green.withAlphaComponent(0.5).set()
//            path.stroke();
           
            path.fill();
            
            
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
        
        liveBezierPathArray.append(contentsOf: bezierPathArrayStripA)
        
        
        
        for path in bezierPathArrayStripB
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.cyan.setFill()

            path.lineWidth = self.lineWidth
            path.fill();
//            path.stroke();
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
        
        liveBezierPathArray.append(contentsOf: bezierPathArrayStripB)
  
        for path in bezierPathArrayMainStrip1
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.black.setFill()
          path.lineWidth = self.lineWidth
            path.fill();
//            path.stroke();
         
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
    liveBezierPathArray.append(contentsOf: bezierPathArrayMainStrip1)


    

        for path in bezierPathArrayMainStrip2
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.white.setStroke()
            path.lineWidth = self.lineWidth
            path.fill();
//            path.stroke();
            
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
        


        for path in bezierTipStampArray
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round

//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.white.setStroke();
            path.lineWidth = self.lineWidth
//            path.stroke();
            path.fill();
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
        liveBezierPathArray.append(contentsOf: bezierTipStampArray)
      
         
    }

    // a dictionary with associated points
    // for each fmstrokepoint
    
    // MARK: -
    
    func isOnlyTwoBSplines() -> Bool
    {
        if(self.arrayOfFMStrokePoints.count == 2)
        {
            if(
            (self.arrayOfFMStrokePoints[0].fmStrokePointType == .bSpline) &&
            (self.arrayOfFMStrokePoints[1].fmStrokePointType == .bSpline)
            )
            {
                return true;
            }
        }
    
        return false;
    }
    
    var convexHullPath = NSBezierPath();

    func makeFMStrokeFinalSegmentBased(distanceForInterpolation:CGFloat, uniformTipSimplificationTolerance: CGFloat, tip:FMBrushTip)
    {
        guard (self.arrayOfFMStrokePoints.isEmpty == false) else
        {
            return
        }
        
        convexHullPath.removeAllPoints()

        
        if(tip.isUniform)
        {
        
            let pathStart = self.uniformTipBezierPath(distanceForInterpolation: distanceForInterpolation, doSimplify:true, simplificationTolerance: uniformTipSimplificationTolerance.float(), isFinal: true)


            self.lineCapStyle = fmInk.uniformTipLineCapStyle
            self.lineJoinStyle = fmInk.uniformTipLineJoinStyle
            self.miterLimit = 40;
           
            
            if(self.fmInk.brushTip == .uniform)
            {
                self.removeAllPoints();
                self.append(pathStart);
                /*let arrayOfDots = pathStart.pointsForConvexHull();
                let p = NSBezierPath();
                let a = Double(self.largestFMPointBrushWidth())
                let h = Hull(concavity: a)
                
                
                
                if let hull = h.hull(arrayOfDots, nil) as? [[Double]]
                {
                    let hullCount = hull.count;
                    
                    for i in 0..<hullCount
                    {
                        
                        let lineToPoint = NSMakePoint(CGFloat(hull[i][0]), CGFloat(hull[i][1]))
                        
                        p.moveToIfEmptyOrLine(to: lineToPoint)
                    }
                    
                    
                    p.close();
                    
                    // NSColor.white.setStroke()
                    // p.stroke()
                
 
                }
 
//                pathStart.removeAllPoints();
//                pathStart.append(p)
                self.removeAllPoints();
                self.append(p)*/
            }
            else
            {

                
 
            }
//            if(self.closeUniformBezier)
//            {
               // self.close();
//            }
            
            if(self.fmInk.brushTip == .uniformPath)
            {
              self.lineWidth = arrayOfFMStrokePoints.last?.brushSize.width ?? 10;
            }

            
            
            // ------------
            // RETURN
            // ------------
            return;
            
            
        }
        
        var pkStrokePath : PKStrokePath!
        
        // if only two bsplines, the
        // processing algorithm leaves gaps in
        // the final shape.
        if(self.isOnlyTwoBSplines())
        {
            self.arrayOfFMStrokePoints[0].fmStrokePointType = .hardCorner
            self.arrayOfFMStrokePoints[1].fmStrokePointType = .hardCorner
            pkStrokePath = self.pkStrokePathAcc()
            self.arrayOfFMStrokePoints[0].fmStrokePointType = .bSpline
            self.arrayOfFMStrokePoints[1].fmStrokePointType = .bSpline

        }
        else
        {
            pkStrokePath = self.pkStrokePathCached ?? self.pkStrokePathAcc()
        }
  
        
        let interpolatedStrokePathPoints = pkStrokePath.interpolatedPoints(by: PKStrokePath.InterpolatedSlice.Stride.distance(distanceForInterpolation))
        
        var modifiedInterpolatedStrokePathPoints : [PKStrokePoint] = []
        
        var aCounter = 0
        var lastPKIn : PKStrokePoint!
        
        
        // MARK: make modifiedInterpolatedStrokePathPoints

        for interpPKStPoint in interpolatedStrokePathPoints
        {
           
            if(aCounter == 0)
            {
                aCounter += 1;
                
                lastPKIn = interpPKStPoint
                modifiedInterpolatedStrokePathPoints.append(interpPKStPoint)
                continue
            }
            
            // MARK: interpolate points for gaps between this brush shape and the last point
            let d = (NSPoint.distanceBetween(lastPKIn.location, interpPKStPoint.location)) + 1;
            
            if((NSPoint.distanceBetween(lastPKIn.location, interpPKStPoint.location)) > distanceForInterpolation)
            {
                for r in stride(from: 1, to: d, by: distanceForInterpolation / 4.0)
                {
                    
                    let interpolatedPoint = (vDSP.linearInterpolate([interpPKStPoint.location.x.double(),interpPKStPoint.location.y.double()],[lastPKIn.location.x.double(),lastPKIn.location.y.double()],  using: Double(r / d)))
                    
                    let interpolatedNSPoint = NSPoint(x: CGFloat(interpolatedPoint[0]), y: CGFloat(interpolatedPoint[1]))
                    
                    let pkStrokePtToAppend = PKStrokePoint.init(location: interpolatedNSPoint, timeOffset: 0, size: lastPKIn.size, opacity: lastPKIn.opacity, force: lastPKIn.force, azimuth: lastPKIn.azimuth, altitude: lastPKIn.altitude)
                    modifiedInterpolatedStrokePathPoints.append(pkStrokePtToAppend)
                    
                    
                } // END for r in stride(from: 1, to: d, by:
                
                
            }
            
            modifiedInterpolatedStrokePathPoints.append(interpPKStPoint)
            lastPKIn = interpPKStPoint

        }
        
        
        var counter : Int = 0;
        var lastPKPoint : PKStrokePoint!
        
        convexHullPath.removeAllPoints()
       
        let ptArrayForNoiseCount = modifiedInterpolatedStrokePathPoints.count
        let pathLengthCGFloat : CGFloat = CGFloat(ptArrayForNoiseCount) * distanceForInterpolation
       
        var gkNoiseToUse : GKNoise? = nil;
        if(fmInk.gkPerlinNoiseWithAmplitude != nil)
        {
            if(fmInk.gkPerlinNoiseWithAmplitude!.noisingMode == 1)
            {
                let gkNoiseSource = fmInk.gkPerlinNoiseWithAmplitude?.gkPerlinNoiseSource;
                gkNoiseToUse = GKNoise.init(GKPerlinNoiseSource.init(frequency: ( (gkNoiseSource!.frequency / 100.0) * 0.5 * Double(pathLengthCGFloat)) , octaveCount: gkNoiseSource!.octaveCount, persistence: gkNoiseSource!.persistence, lacunarity: gkNoiseSource!.lacunarity, seed: gkNoiseSource!.seed) )
            }
            
        }
        
       // MARK: make the bezier path
        for (index, pkPoint) in modifiedInterpolatedStrokePathPoints.enumerated()
        {
            if counter == 0
            {
                lastPKPoint = pkPoint
                counter += 1
            
                continue
            }
            
            
            var pkPointToUse = pkPoint
            
            
            if(gkNoiseToUse != nil)
            {
                
                let pathPosition = ( CGFloat(index) / CGFloat(ptArrayForNoiseCount));
                
                
                let positionMappedForNoise = (2 * pathPosition ) - 1;
                
                var value = CGFloat( gkNoiseToUse!.value(atPosition: simd_float2(repeating: Float(positionMappedForNoise)) ) );
                
                if(fmInk.gkPerlinNoiseWithAmplitude!.useAbsoluteValues)
                {
                    value = abs(value)
                }
                
                let noiseValueWidth : CGFloat = pkPointToUse.size.width + ( fmInk.gkPerlinNoiseWithAmplitude!.amplitude * value);
               
               let noiseLocationPoint : NSPoint = pkPointToUse.location
               //NSMakePoint(
               // pkPointToUse.location.x + (value * fmInk.gkPerlinNoiseWithAmplitude!.amplitude),
               // pkPointToUse.location.y + (value * fmInk.gkPerlinNoiseWithAmplitude!.amplitude)
               // )
                
                pkPointToUse = PKStrokePoint.init(location: noiseLocationPoint, timeOffset: pkPointToUse.timeOffset, size: CGSize.init(width: noiseValueWidth, height: pkPointToUse.size.height), opacity: pkPointToUse.opacity, force: pkPointToUse.force, azimuth: pkPointToUse.azimuth, altitude: pkPointToUse.altitude)
                
                
            }
           
       
            // LAST BRUSH TIP AND POINT
            let lastBrushTipUntransformedRect = NSMakeRect(0, 0, lastPKPoint.size.width - 0.25 , lastPKPoint.size.height - 0.25
            ).centerOnPoint(lastPKPoint.location)
            
            let lastNctRotatedRect : NCTRotatedRect = lastBrushTipUntransformedRect.rotatedAroundPoint(point: lastPKPoint.location, degrees: rad2deg(lastPKPoint.azimuth))
            
            // CURRENT BRUSH TIP AND POINT
            let brushTipUntransformedRect = NSMakeRect(0, 0, pkPointToUse.size.width , pkPointToUse.size.height
            ).centerOnPoint(pkPointToUse.location)
            
            let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: pkPointToUse.location, degrees: rad2deg(pkPointToUse.azimuth))
            
            
            
            
            // MARK: ------ hull approach
          
            
            let p = NSBezierPath();
            var arrayOfDots : [[Double]] = [];
            
            var degreeStep : CGFloat = 20
            if (((pkPointToUse.size.height / pkPointToUse.size.width) < 10) && (pkPointToUse.size.width > 80) )
            {
                degreeStep = 10;
            }
            
            if(tip == .ellipse)
            {
                arrayOfDots.append(contentsOf: lastNctRotatedRect.perimeterEllipsePointsForConvexHull(degreeStep:degreeStep))
                
                arrayOfDots.append(contentsOf: nctRotatedRect.perimeterEllipsePointsForConvexHull(degreeStep:degreeStep))
            }
            else
            {
                arrayOfDots.append(contentsOf: lastNctRotatedRect.perimenterRectanglePointsForConvexHull() )
                
                arrayOfDots.append(contentsOf: nctRotatedRect.perimenterRectanglePointsForConvexHull() )
            }
            
                let h = Hull(concavity: Double(distanceForInterpolation + max(lastBrushTipUntransformedRect.height, lastBrushTipUntransformedRect.width) + max(brushTipUntransformedRect.height, brushTipUntransformedRect.width) ))
                if let hull = h.hull(arrayOfDots, nil) as? [[Double]]
                {
                    let hullCount = hull.count;
                    
                    for i in 0..<hullCount
                    {
                        
                        let lineToPoint = NSMakePoint(CGFloat(hull[i][0]), CGFloat(hull[i][1]))
                        
                        p.moveToIfEmptyOrLine(to: lineToPoint)
                    }
                    
                    
                    p.close();
                    
                   // NSColor.white.setStroke()
                   // p.stroke()
                    
                    arrayOfDots.removeAll()
                   
    
                    p.windingRule = NSBezierPath.WindingRule.nonZero
                    convexHullPath.windingRule = NSBezierPath.WindingRule.nonZero
                    if(convexHullPath.isEmpty){convexHullPath.append(p)}
                    else{
                        
                        convexHullPath = convexHullPath.wfUnion(with: p)//fb_union(p)
                        
                    }

              
                }
    
                
       
            // LOOP ADVANCEMENT
            lastPKPoint = pkPointToUse
            counter += 1
            
           
            if(counter == 2)
            {
            //    break
            }
            
        } //END         for pkPoint in pkStrokePath.interpolatedPoints(by: .distance(distanceForInterpolation))

        self.removeAllPoints();
        
        
        
        
        self.append(convexHullPath)
        self.windingRule = NSBezierPath.WindingRule.evenOdd

        if(fmInk.gkPerlinNoiseWithAmplitude != nil)
        {
            /*
            let allPoints = self.buildupModePoints()
            var simplifiedPoints = SwiftSimplify.simplify(allPoints, tolerance:
                                                            0.01)
            self.removeAllPoints();
            self.appendPoints(&simplifiedPoints, count: simplifiedPoints.count);
           */
          
          if(fmInk.gkPerlinNoiseWithAmplitude!.noisingMode == 0)
          {
            self.applyNoiseToPath(gkNoiseSource: fmInk.gkPerlinNoiseWithAmplitude!.gkPerlinNoiseSource, amplitude: fmInk.gkPerlinNoiseWithAmplitude!.amplitude, useAbsoluteValues: fmInk.gkPerlinNoiseWithAmplitude!.useAbsoluteValues, makeFragmentedLineSegments:(false,distanceForInterpolation));
          }
        }


        liveBezierPathArray.removeAll();


        convexHullPath.removeAllPoints();
        
        
    }
 
 
    func reducePointsOfPathForNonUniform(simplificationTolerance: CGFloat)
    {
        
        // uniform is simplified in the preceding
        // function, makeFMStrokeFinalSegmentBased(...
        guard (fmInk.brushTip.isUniform == false) else
        {
            return
        }
    
       
        
        if(self.isEmpty == false)
        {
        
               
            if(self.countSubPathsNCT() > 1)
            {
                let tempPath = NSBezierPath()
                
                for path in self.subPathsNCT()
                {
                    let allPoints = path.buildupModePoints()
                    
                  
                    var simplifiedPoints = SwiftSimplify.simplify(allPoints, tolerance:
                                                                    Float(simplificationTolerance))
                    
                    guard simplifiedPoints.first != nil else {
                        self.removeAllPoints();
                        self.append( self.uniformTipBezierPath(distanceForInterpolation: liveDistanceForInterpolationUniformTip, doSimplify:true, simplificationTolerance: Float(simplificationTolerance), isFinal: true) )
                        print("simplifiedPoints.first was nil")
                        return;
                    }
                    
                    tempPath.move(to: simplifiedPoints.first!)
                    tempPath.appendPoints(&simplifiedPoints, count: simplifiedPoints.count);
                    tempPath.close()
                    
                
                }
                
                self.removeAllPoints();
                self.append(tempPath)
                self.windingRule = NSBezierPath.WindingRule.evenOdd
                
                
            }
            else
            {
                let allPoints = self.buildupModePoints()
                
               /* if(doFitCurve)
               {
                allPoints.remove(at: allPoints.last!)
                let cgPath = CGPath.path(thatFits: allPoints, tolerance: 0.8)
                let p = NSBezierPath.init(cgPath: cgPath)
                self.removeAllPoints();
                self.append(p);
                }
               */
                
                var simplifiedPoints = SwiftSimplify.simplify(allPoints, tolerance:
                                                                Float(simplificationTolerance))
                self.removeAllPoints();

                if(simplifiedPoints.count > 6)
                {
                    
                    // prevents an a stray line from connecting the beginning of the
                    // shape to the beginning (resulting from SwiftSimplify).
                    simplifiedPoints.removeLast()
                    self.appendPoints(&simplifiedPoints, count: simplifiedPoints.count);
                    self.close();
                }
                else
                {
                
                    simplifiedPoints = SwiftSimplify.simplify(allPoints, tolerance:
                                                                0.2)
                    
                    // prevents an a stray line from connecting the beginning of the
                    // shape to the beginning (resulting from SwiftSimplify).
                   // simplifiedPoints.removeLast()
                    self.appendPoints(&simplifiedPoints, count: simplifiedPoints.count);
                    self.close();
                }
                
                
            }
        
        }// END  if(self.isEmpty == false)
        
        
      
        
    }
   
    func makeFMStrokeFinalCommonEllipseTangents(distanceForInterpolation:CGFloat)
    {
        guard (self.arrayOfFMStrokePoints.isEmpty == false) else {
            return
        }
        let pkStrokePath = self.pkStrokePathCached ?? self.pkStrokePathAcc()
        
        var counter : Int = 0;
        var lastPKPoint : PKStrokePoint!
        
        var pathForUnion : NSBezierPath = NSBezierPath();
        
        for pkPoint in pkStrokePath.interpolatedPoints(by: .distance(distanceForInterpolation))
        {
            if counter == 0
            {
                lastPKPoint = pkPoint
                counter += 1
                
                continue
            }
            
            
            // LAST BRUSH TIP AND POINT
            let lastBrushTipUntransformedRect = NSMakeRect(0, 0, lastPKPoint.size.width - 1 , lastPKPoint.size.height - 1
            ).centerOnPoint(lastPKPoint.location)
            
            let lastNctRotatedRect : NCTRotatedRect = lastBrushTipUntransformedRect.rotatedAroundPoint(point: lastPKPoint.location, degrees: rad2deg(lastPKPoint.azimuth))
            
            // CURRENT BRUSH TIP AND POINT
            let brushTipUntransformedRect = NSMakeRect(0, 0, pkPoint.size.width , pkPoint.size.height
            ).centerOnPoint(pkPoint.location)
            
            let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: pkPoint.location, degrees: rad2deg(pkPoint.azimuth))
            
            
            
            let angleRadiansBetweenTwoCenters : CGFloat = NSBezierPath.lineAngleRadiansFrom(point1: lastNctRotatedRect.centerPoint, point2: nctRotatedRect.centerPoint)
            
            
            let p = NSBezierPath();
            
            
            var d = lastNctRotatedRect.perimeterEllipsePoints(startAngleDegrees: 180 + round(rad2deg(angleRadiansBetweenTwoCenters - (0.5 * .pi)))  , endAngleDegrees: 180 + round(rad2deg(angleRadiansBetweenTwoCenters + (0.5 * .pi))) , degreeStep: 15,directionForward:true);
            
            p.appendPoints(&d, count: d.count)
            
            let angleRadiansBetweenTwoCenters2 : CGFloat = NSBezierPath.lineAngleRadiansFrom(point1: nctRotatedRect.centerPoint, point2: lastNctRotatedRect.centerPoint)
            
            var e : [NSPoint] = nctRotatedRect.perimeterEllipsePoints(startAngleDegrees: 180 + round(rad2deg(angleRadiansBetweenTwoCenters2 - (0.5 * .pi))), endAngleDegrees: 180 + round(rad2deg(angleRadiansBetweenTwoCenters2 + (0.5 * .pi))), degreeStep: 15,directionForward:true);
            
            

            
            p.appendPoints(&e, count: e.count)
            
            p.close();
           
            // p.stroke();
            
            
            // LOOP ADVANCEMENT
            lastPKPoint = pkPoint
            counter += 1
            
            
            if(counter == 2)
            {
                //    break
            }
            
            
            if(pathForUnion.isEmpty)
            {
                pathForUnion = p
            }
            else
            {
                pathForUnion = pathForUnion.wfUnion(with: p)
            }
            
        }// END for pkPoint in pkStrokePath.interpolatedPoints(by: .distance(distanceForInterpolation))
        
        self.removeAllPoints();
        self.append(pathForUnion)

        
    }
    
    
   func displayFMStrokeCommonEllipseTangents(distanceForInterpolation:CGFloat)
   {
      guard (self.arrayOfFMStrokePoints.isEmpty == false) else {
            return
        }
        let pkStrokePath = self.pkStrokePathCached ?? self.pkStrokePathAcc()
        
        var counter : Int = 0;
        var lastPKPoint : PKStrokePoint!
        
       // convexHullPath.removeAllPoints()
        for pkPoint in pkStrokePath.interpolatedPoints(by: .distance(distanceForInterpolation))
        {
            if counter == 0
            {
                lastPKPoint = pkPoint
                counter += 1
            
                continue
            }
            
            
            // LAST BRUSH TIP AND POINT
            let lastBrushTipUntransformedRect = NSMakeRect(0, 0, lastPKPoint.size.width - 1 , lastPKPoint.size.height - 1
            ).centerOnPoint(lastPKPoint.location)
            
            let lastNctRotatedRect : NCTRotatedRect = lastBrushTipUntransformedRect.rotatedAroundPoint(point: lastPKPoint.location, degrees: rad2deg(lastPKPoint.azimuth))
            
            // CURRENT BRUSH TIP AND POINT
            let brushTipUntransformedRect = NSMakeRect(0, 0, pkPoint.size.width , pkPoint.size.height
            ).centerOnPoint(pkPoint.location)
            
            let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: pkPoint.location, degrees: rad2deg(pkPoint.azimuth))
            
             
                
                let angleRadiansBetweenTwoCenters : CGFloat = NSBezierPath.lineAngleRadiansFrom(point1: lastNctRotatedRect.centerPoint, point2: nctRotatedRect.centerPoint)
                
                
                
                
                NSColor.black.setStroke();
                let p = NSBezierPath();
                
                
                NSColor.green.setStroke()
                
                
                p.move(to: lastNctRotatedRect.centerPoint)
                //            lastNctRotatedRect.centerPoint.fillSquare3x3AtPoint()
                p.line(to: nctRotatedRect.centerPoint)
                
                // nctRotatedRect.centerPoint.fillSquare3x3AtPoint()
                
                p.stroke()
                
                p.removeAllPoints();
                var a = lastNctRotatedRect.perimeterEllipsePoints(degreeStep: 20)
                p.appendPoints(&a, count: a.count)
                p.close()
                p.stroke()
                
                p.removeAllPoints();
                
                a = nctRotatedRect.perimeterEllipsePoints(degreeStep: 20)
                p.appendPoints(&a, count: a.count)
                p.close()
                
                p.stroke()
                
                p.removeAllPoints();
                
                
                NSColor.blue.setStroke()
                
                p.move(to: lastNctRotatedRect.centerPoint)
                p.line(to: lastNctRotatedRect.centerPoint.pointFromAngleAndLength(angleRadians: angleRadiansBetweenTwoCenters, length: lastNctRotatedRect.width))
                
                p.move(to: lastNctRotatedRect.centerPoint)
                p.line(to: lastNctRotatedRect.centerPoint.pointFromAngleAndLength(angleRadians: lastPKPoint.azimuth  + angleRadiansBetweenTwoCenters, length: lastNctRotatedRect.width))
                
                p.stroke()
                p.removeAllPoints()
                
                NSColor.purple.setStroke();
                p.move(to: lastNctRotatedRect.centerPoint)
                p.line(to: lastNctRotatedRect.centerPoint.pointFromAngleAndLength(angleRadians: lastPKPoint.azimuth + (-0.5 * .pi) + angleRadiansBetweenTwoCenters, length: lastNctRotatedRect.width))
                
                p.move(to: lastNctRotatedRect.centerPoint)
                p.line(to: lastNctRotatedRect.centerPoint.pointFromAngleAndLength(angleRadians: lastPKPoint.azimuth + (0.5 * .pi) + angleRadiansBetweenTwoCenters, length: lastNctRotatedRect.width))
                
                p.move(to: lastNctRotatedRect.centerPoint)
                p.line(to: lastNctRotatedRect.centerPoint.pointFromAngleAndLength(angleRadians: lastPKPoint.azimuth + (-1 * .pi) + angleRadiansBetweenTwoCenters, length: lastNctRotatedRect.width))
                
                p.move(to: lastNctRotatedRect.centerPoint)
                p.line(to: lastNctRotatedRect.centerPoint.pointFromAngleAndLength(angleRadians: lastPKPoint.azimuth + (1 * .pi) + angleRadiansBetweenTwoCenters, length: lastNctRotatedRect.width))
                
                p.stroke()
                p.removeAllPoints()
                NSColor.orange.setStroke();
                
                p.move(to: lastNctRotatedRect.centerPoint)
                p.line(to: lastNctRotatedRect.middleRight)
                p.move(to: lastNctRotatedRect.centerPoint)
                p.line(to: lastNctRotatedRect.middleLeft)
                p.stroke()
                
                
                
                
                p.removeAllPoints();
                
                NSColor.black.setStroke()
                
                
                
                var d = lastNctRotatedRect.perimeterEllipsePoints(startAngleDegrees: 180 + round(rad2deg(angleRadiansBetweenTwoCenters - (0.5 * .pi)))  , endAngleDegrees: 180 + round(rad2deg(angleRadiansBetweenTwoCenters + (0.5 * .pi))) , degreeStep: 15,directionForward:true);
                
                NSBezierPath.strokeLine(from: lastNctRotatedRect.centerPoint, to: lastNctRotatedRect.ellipsePointAtAngle(radians: angleRadiansBetweenTwoCenters - (0.5 * .pi)))
                
                NSBezierPath.strokeLine(from: lastNctRotatedRect.centerPoint, to: lastNctRotatedRect.ellipsePointAtAngle(radians: angleRadiansBetweenTwoCenters + (0.5 * .pi)))
                
                
                p.appendPoints(&d, count: d.count)
                
                
                
                
                
                let angleRadiansBetweenTwoCenters2 : CGFloat = NSBezierPath.lineAngleRadiansFrom(point1: nctRotatedRect.centerPoint, point2: lastNctRotatedRect.centerPoint)
                
                var e : [NSPoint] = nctRotatedRect.perimeterEllipsePoints(startAngleDegrees: 180 + round(rad2deg(angleRadiansBetweenTwoCenters2 - (0.5 * .pi))), endAngleDegrees: 180 + round(rad2deg(angleRadiansBetweenTwoCenters2 + (0.5 * .pi))), degreeStep: 15,directionForward:true);
                
                
                NSBezierPath.strokeLine(from: nctRotatedRect.centerPoint, to: nctRotatedRect.ellipsePointAtAngle(radians: angleRadiansBetweenTwoCenters2 - (0.5 * .pi)))
                
                NSBezierPath.strokeLine(from: nctRotatedRect.centerPoint, to: nctRotatedRect.ellipsePointAtAngle(radians: angleRadiansBetweenTwoCenters2 + (0.5 * .pi)))
                
                p.appendPoints(&e, count: e.count)
                
                p.close()
                p.stroke();


            // LOOP ADVANCEMENT
            lastPKPoint = pkPoint
            counter += 1
            
           
            if(counter == 2)
            {
            //    break
            }
            
        }
   }
    
   func makeFMStrokeEllipseLiveVersionExtended(distance:CGFloat)
    {
    
        guard (self.arrayOfFMStrokePoints.isEmpty == false) else {
            return
        }
    
        // point arrays
        var stripAPointArray : [NSPoint] = [];
        var stripBPointArray : [NSPoint] = [];
        var stripCPointArray : [NSPoint] = [];
        var stripDPointArray : [NSPoint] = [];
       

        var mainStripPointArray1 : [NSPoint] = [];
        var mainStripPointArray2 : [NSPoint] = [];
//        var mainStripPointArray3 : [NSPoint] = [];
        
        // currently operated on bezier paths
        var currentlyOperatedOnBezierPathStripA : NSBezierPath = NSBezierPath();
        var currentlyOperatedOnBezierPathStripB : NSBezierPath = NSBezierPath();
        var currentlyOperatedOnBezierPathStripC : NSBezierPath = NSBezierPath();
        var currentlyOperatedOnBezierPathStripD : NSBezierPath = NSBezierPath();
        var currentlyOperatedOnBezierPathMainStrip1 : NSBezierPath = NSBezierPath();
        var currentlyOperatedOnBezierPathMainStrip2 : NSBezierPath = NSBezierPath();
//       var currentlyOperatedOnBezierPathMainStrip3 : NSBezierPath = NSBezierPath();

        
        // bezier path arrays
        var bezierPathArrayStripA : [NSBezierPath] = [];
        var bezierPathArrayStripB : [NSBezierPath] = [];
        var bezierPathArrayStripC : [NSBezierPath] = [];
        var bezierPathArrayStripD : [NSBezierPath] = [];
        var bezierPathArrayMainStrip1 : [NSBezierPath] = [];
        var bezierPathArrayMainStrip2 : [NSBezierPath] = [];
//        var bezierPathArrayMainStrip3 : [NSBezierPath] = [];

        
        let pkStrokePath = self.pkStrokePathCached ?? self.pkStrokePathAcc()

            let bPath = NSBezierPath();
            bPath.windingRule = .evenOdd
            bPath.lineJoinStyle = .round
            bPath.lineWidth = 1.0;
        var lastPoints : (strokePoint: NSPoint, pointA: NSPoint, pointB: NSPoint) = (.zero,.zero,.zero);
        var lastQuadrant : Int = 0;
//        var lastAngle : Int = 0;
        var counter = 0;
        var lastNctRotatedRect : NCTRotatedRect?
        


        bezierPathArrayStripA.append(currentlyOperatedOnBezierPathStripA);
        bezierPathArrayStripB.append(currentlyOperatedOnBezierPathStripB)
        bezierPathArrayStripC.append(currentlyOperatedOnBezierPathStripC);
        bezierPathArrayStripD.append(currentlyOperatedOnBezierPathStripD)
        bezierPathArrayMainStrip1.append(currentlyOperatedOnBezierPathMainStrip1);
        bezierPathArrayMainStrip2.append(currentlyOperatedOnBezierPathMainStrip2);

        var didAppendBrushTip = false;
        
        var bezierTipStampArray : [NSBezierPath] = [];
        
        let distanceForInterpolation : CGFloat = distance;
        
        /*
        if(self.arrayOfFMStrokePoints.first!.brushSize.width < 7)
        {
                distanceForInterpolation = 10;
        }*/
        
//        let baseRectPath = NSBezierPath();
//        var rotatedBrush = NSBezierPath();
        
        for pkPoint in pkStrokePath.interpolatedPoints(by: .distance(distanceForInterpolation))
        {
        
            // pkPoint.location.fillSquare3x3AtPoint(color: NSColor.white)
        
            let brushTipUntransformedRect = NSMakeRect(0, 0, pkPoint.size.width , pkPoint.size.height
            ).centerOnPoint(pkPoint.location)
            
            let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: pkPoint.location, degrees: rad2deg(pkPoint.azimuth))
            
     
        /*
            baseRectPath.appendOval(in: brushTipUntransformedRect)
            
            rotatedBrush.removeAllPoints();
            rotatedBrush.appendPathRotatedAboutCenterPoint(path: baseRectPath, angleDegrees: rad2deg(pkPoint.azimuth), centerPoint: pkPoint.location)
            let flattedBrushPath = rotatedBrush.flattened;
            var closestPointA : NSPoint = .zero
            
            var closestPointB : NSPoint = .zero
            
            var points : [NSPoint] = Array.init(repeating: .zero, count: 3)
            for pIndex in 0..<flattedBrushPath.elementCount
            {
               flattedBrushPath.element(at: pIndex, associatedPoints: &points)
//               if( closestPointA.distanceFrom(point2: points[0]) )
               
            }*/
                
            /*
            // ---DEBUG
            NSColor.darkGray.setStroke()

            nctRotatedRect.stroke();
            
            nctRotatedRect.bottomRight.fillSquare3x3AtPoint(color: NSColor.red) // top right
            nctRotatedRect.bottomLeft.fillSquare3x3AtPoint(color: NSColor.green) // top left
         
            nctRotatedRect.topRight.fillSquare3x3AtPoint(color: NSColor.blue) // bottom right
            nctRotatedRect.topLeft.fillSquare3x3AtPoint(color: NSColor.yellow) // bottom left
            nctRotatedRect.stroke();*/
     
            var quadrant : Int = 0;
            var a : CGFloat = 0;
            if(counter != 0)
            {

                // MARK: CURRENT ANGLE FOR BRUSH TIP STAMP
                 a = rad2deg(atan2(pkPoint.location.x - lastPoints.strokePoint.x , pkPoint.location.y - lastPoints.strokePoint.y ))
                if(a < 0)
                {
                    a = 360 + a;
                }
                
                 a = floor(a) - 90
                 
                 if( a < 0)
                 {
                    a = 360 + a;

                 }
                
                
                var correlateAngle : CGFloat = 0;
                if( a < 180)
                {
                    correlateAngle = a + 180;
                }
                else
                {
                    correlateAngle = a - 180;
                }
                
//                Int(a).drawAtPoint(pkPoint.location)
                
//                let angleRange1 = (correlateAngle - 6)...(correlateAngle + 6)
                
//                let angleRange2 = (a - 6)...(a + 6)
                
                let convertedToDegAzimuth = floor(rad2deg(pkPoint.azimuth))
                
                if(
                ((convertedToDegAzimuth >= (a - 5)) &&
                (convertedToDegAzimuth <= (a + 5))
                ) ||
                
                ((convertedToDegAzimuth >= (correlateAngle - 5)) &&
                (convertedToDegAzimuth <= (correlateAngle + 5))
                )
                
                    && (didAppendBrushTip == false)
                )
                {
                
                         var c = nctRotatedRect.perimeterEllipsePoints(degreeStep:2)
                         
                    let p = NSBezierPath()
                    p.appendPoints(&c, count: c.count)
                p.close()
                bezierTipStampArray.append(p)
                                    didAppendBrushTip = true;
                

//                pkPoint.location.fillSquare3x3AtPoint(color: NSColor.blue)

                }
                else if(didAppendBrushTip == true)
                {
                    didAppendBrushTip = false;
                }
                
  
                quadrant = NSBezierPath.quadrantFrom(point1: lastPoints.strokePoint, point2: pkPoint.location)
           
                /// if quadrant changes,
                /// start new path
                
               

                if((lastQuadrant != quadrant) && (counter > 1) )
                {
                    currentlyOperatedOnBezierPathStripA.appendPoints(&stripAPointArray, count: stripAPointArray.count)
                    currentlyOperatedOnBezierPathStripB.appendPoints(&stripBPointArray, count: stripBPointArray.count)
                    currentlyOperatedOnBezierPathStripC.appendPoints(&stripCPointArray, count: stripCPointArray.count)
                    currentlyOperatedOnBezierPathStripD.appendPoints(&stripDPointArray, count: stripDPointArray.count)
                    
                    
                    currentlyOperatedOnBezierPathMainStrip1.appendPoints(&mainStripPointArray1, count: mainStripPointArray1.count)
                    currentlyOperatedOnBezierPathMainStrip2.appendPoints(&mainStripPointArray2, count: mainStripPointArray2.count)

                    let restartP1 = mainStripPointArray1[mainStripPointArray1.count - 1]
                    let restartP2 = mainStripPointArray1[0]
                    let restartP1_2 = mainStripPointArray2[mainStripPointArray2.count - 1]
                    let restartP2_2 = mainStripPointArray2[0]
    
                    /* DEBUG
                     let r = NSRect.init(origin: restartP1, size: NSSize.init(width: 10, height: 10)).centerOnPoint(restartP1)
                     NSColor.white.setFill();
                     
                     r.fill();
                     
                     let r2 = NSRect.init(origin: restartP2, size: NSSize.init(width: 10, height: 10)).centerOnPoint(restartP2)
                     NSColor.white.setFill();
                    r2.fill()
                    */
                   
                    stripAPointArray.removeAll();
                    stripBPointArray.removeAll();
                    stripCPointArray.removeAll();
                    stripDPointArray.removeAll();
                    mainStripPointArray1.removeAll();
                    mainStripPointArray2.removeAll();

                    currentlyOperatedOnBezierPathStripA = NSBezierPath();
                    currentlyOperatedOnBezierPathStripB = NSBezierPath();
                    currentlyOperatedOnBezierPathStripC = NSBezierPath();
                    currentlyOperatedOnBezierPathStripD = NSBezierPath();
                    currentlyOperatedOnBezierPathMainStrip1 = NSBezierPath();
                    currentlyOperatedOnBezierPathMainStrip2 = NSBezierPath();
//                  currentlyOperatedOnBezierPathMainStrip3 = NSBezierPath();

                
                    mainStripPointArray1.append(restartP1)
                    mainStripPointArray1.insert(restartP2, at: 0)
                    mainStripPointArray2.append(restartP1_2)
                    mainStripPointArray2.insert(restartP2_2, at: 0)
                
                   
                    bezierPathArrayStripA.append(currentlyOperatedOnBezierPathStripA)
                    bezierPathArrayStripB.append(currentlyOperatedOnBezierPathStripB)
                    bezierPathArrayStripC.append(currentlyOperatedOnBezierPathStripC)
                    bezierPathArrayStripD.append(currentlyOperatedOnBezierPathStripD)
                    bezierPathArrayMainStrip1.append(currentlyOperatedOnBezierPathMainStrip1)
                    bezierPathArrayMainStrip2.append(currentlyOperatedOnBezierPathMainStrip2)
//                  bezierPathArrayMainStrip3.append(currentlyOperatedOnBezierPathMainStrip3)

                    
                    var pointsForTipPath = lastNctRotatedRect!.perimeterEllipsePoints(degreeStep:2)

                    
                    let tipPath = NSBezierPath()
                    tipPath.appendPoints(&pointsForTipPath, count: pointsForTipPath.count)
                    tipPath.close()
                    bezierTipStampArray.append(tipPath)
                    
                  //   lastPoints.strokePoint.fillSquare3x3AtPoint(color: NSColor.cyan)

                    
                    /*
                     let nctRotatedRect2 : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: lastPoints.pointA, degrees: rad2deg(pkPoint.azimuth))
                    */
                    var pointsForTipPath2 =  [nctRotatedRect.middleLeft,nctRotatedRect.bottomMiddle,nctRotatedRect.middleRight,nctRotatedRect.topMiddle,nctRotatedRect.middleLeft];
                    
                    let tipPath2 = NSBezierPath()
                    tipPath2.appendPoints(&pointsForTipPath2, count: pointsForTipPath2.count)
                    tipPath2.close()
                 bezierTipStampArray.append(tipPath2)
                    
                    
                    // pkPoint.location.fillSquare3x3AtPoint(color: NSColor.green)
                     
                }

            }
           
            let pointA = pkPoint.location.pointFromAngleAndLength(angleRadians: -pkPoint.azimuth, length: pkPoint.size.width / 2.0)//.fillSquare3x3AtPoint();
            
            let pointB = pkPoint.location.pointFromAngleAndLength(angleRadians: -pkPoint.azimuth, length: -pkPoint.size.width / 2.0)//.fillSquare3x3AtPoint();
            
            
            /*
            if(counter == 0)
            {
            currentlyOperatedOnBezierPathMainStrip1.move(to: nctRotatedRect.bottomLeft)
                        currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomRight)
            }
             else  if(counter % 2 == 0)
                    {
                       currentlyOperatedOnBezierPathMainStrip1.move(to: nctRotatedRect.bottomLeft)
                        currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomRight)
                   //     currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomLeft)
                     //   currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.topLeft)
                       // currentlyOperatedOnBezierPathMainStrip1.close()
                    }
                    else
                    {
                      currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomRight)
                        currentlyOperatedOnBezierPathMainStrip1.line(to: nctRotatedRect.bottomLeft)
                        currentlyOperatedOnBezierPathMainStrip1.close()
                        
                        
                    }
        */

            if(counter == 0)
            {
                
                stripAPointArray.append(nctRotatedRect.ellipsePointAtAngle(radians: (1/6) * .pi))
                stripAPointArray.insert( nctRotatedRect.ellipsePointAtAngle(radians: (7/6) * .pi), at: 0)
                
                stripBPointArray.append(nctRotatedRect.ellipsePointAtAngle(radians: (1/3) * .pi))
                stripBPointArray.insert( nctRotatedRect.ellipsePointAtAngle(radians: (4/3) * .pi), at: 0)

                stripCPointArray.append(nctRotatedRect.ellipsePointAtAngle(radians: (2/3) * .pi))
                stripCPointArray.insert(nctRotatedRect.ellipsePointAtAngle(radians: (5/3) * .pi), at: 0)

                stripDPointArray.append(nctRotatedRect.ellipsePointAtAngle(radians: (5/6) * .pi))
                stripDPointArray.insert( nctRotatedRect.ellipsePointAtAngle(radians: (11/6) * .pi), at: 0)



            }
           
                    
            if(lastNctRotatedRect != nil)
            {
            

                if(counter == 1)
                {
                    mainStripPointArray1.append(lastNctRotatedRect!.middleLeft)
                    mainStripPointArray1.append(nctRotatedRect.middleLeft)
                    
                    mainStripPointArray1.insert(lastNctRotatedRect!.middleRight, at: 0)
                    mainStripPointArray1.insert(nctRotatedRect.middleRight, at: 0)
                }
                
             
                
                    
                /*
                mainStripPointArray1.append(nctRotatedRect.topLeft)
                mainStripPointArray1.insert(nctRotatedRect.topRight, at: 0)
                mainStripPointArray2.append(nctRotatedRect.bottomLeft)
                mainStripPointArray2.insert(nctRotatedRect.bottomRight, at: 0)
*/

                // HORIZONTAL IS ARRAY 1
                mainStripPointArray1.append(lastNctRotatedRect!.middleLeft)
                mainStripPointArray1.append(nctRotatedRect.middleLeft)
                
                mainStripPointArray1.insert(lastNctRotatedRect!.middleRight, at: 0)
                mainStripPointArray1.insert(nctRotatedRect.middleRight, at: 0)
                
                // VERTICAL IS ARRAY 1
                mainStripPointArray2.append(lastNctRotatedRect!.topMiddle)
                mainStripPointArray2.append(nctRotatedRect.topMiddle)
                
                mainStripPointArray2.insert(lastNctRotatedRect!.bottomMiddle, at: 0)
                mainStripPointArray2.insert(nctRotatedRect.bottomMiddle, at: 0)
                
   
                stripAPointArray.append(lastNctRotatedRect!.ellipsePointAtAngle(radians: (1/6) * .pi))
                stripAPointArray.append(nctRotatedRect.ellipsePointAtAngle(radians: (1/6) * .pi))
                stripAPointArray.insert( lastNctRotatedRect!.ellipsePointAtAngle(radians: (7/6) * .pi), at: 0)
                stripAPointArray.insert( nctRotatedRect.ellipsePointAtAngle(radians: (7/6) * .pi), at: 0)
                
                stripBPointArray.append(lastNctRotatedRect!.ellipsePointAtAngle(radians: (1/3) * .pi))
                
                stripBPointArray.append(nctRotatedRect.ellipsePointAtAngle(radians: (1/3) * .pi))
                stripBPointArray.insert( lastNctRotatedRect!.ellipsePointAtAngle(radians: (4/3) * .pi), at: 0)
                stripBPointArray.insert( nctRotatedRect.ellipsePointAtAngle(radians: (4/3) * .pi), at: 0)
                
                
                
                stripCPointArray.append(lastNctRotatedRect!.ellipsePointAtAngle(radians: (2/3) * .pi))

                stripCPointArray.append(nctRotatedRect.ellipsePointAtAngle(radians: (2/3) * .pi))
                stripCPointArray.insert(lastNctRotatedRect!.ellipsePointAtAngle(radians: (5/3) * .pi), at: 0)

                stripCPointArray.insert(nctRotatedRect.ellipsePointAtAngle(radians: (5/3) * .pi), at: 0)


                stripDPointArray.append(lastNctRotatedRect!.ellipsePointAtAngle(radians: (5/6) * .pi))

                stripDPointArray.append(nctRotatedRect.ellipsePointAtAngle(radians: (5/6) * .pi))
               stripDPointArray.insert( lastNctRotatedRect!.ellipsePointAtAngle(radians: (11/6) * .pi), at: 0)
                stripDPointArray.insert( nctRotatedRect.ellipsePointAtAngle(radians: (11/6) * .pi), at: 0)


                    /*
                    stripBPointArray.append(lastNctRotatedRect!.middleLeft.midpoint(pointB: nctRotatedRect.topMiddle))
                    stripBPointArray.append(nctRotatedRect.middleLeft.midpoint(pointB: nctRotatedRect.topMiddle))
                    */
                    /*
                    stripBPointArray.insert(lastNctRotatedRect!.middleRight.midpoint(pointB: nctRotatedRect.topMiddle), at: 0)
                    stripBPointArray.insert(nctRotatedRect.middleRight.midpoint(pointB: nctRotatedRect.topMiddle), at: 0)
                    */
                    
               // }


            }
         
            lastQuadrant = quadrant;
            lastNctRotatedRect = nctRotatedRect;
            lastPoints = (pkPoint.location, pointA, pointB)
            counter += 1;
        }

        currentlyOperatedOnBezierPathStripA.appendPoints(&stripAPointArray, count: stripAPointArray.count)
        currentlyOperatedOnBezierPathStripB.appendPoints(&stripBPointArray, count: stripBPointArray.count)
    
       currentlyOperatedOnBezierPathStripC.appendPoints(&stripCPointArray, count: stripCPointArray.count)
        currentlyOperatedOnBezierPathStripD.appendPoints(&stripDPointArray, count: stripDPointArray.count)
        
        currentlyOperatedOnBezierPathMainStrip1.appendPoints(&mainStripPointArray1, count: mainStripPointArray1.count)
        currentlyOperatedOnBezierPathMainStrip2.appendPoints(&mainStripPointArray2, count: mainStripPointArray2.count)
        
        
        for (index, fmStrokePoint) in self.arrayOfFMStrokePoints.enumerated()
        {
            
            let array : [FMStrokePointType] = [.hardCorner,.hardCornerBowedLine/*,.roundedCorner,.roundedCornerBowedLine*/]
            if(array.contains(fmStrokePoint.fmStrokePointType) || (index == 0) || (index == arrayOfFMStrokePoints.count - 1))
            {
            
                let brushTipUntransformedRect = NSMakeRect(0, 0, fmStrokePoint.brushSize.width , fmStrokePoint.brushSize.height)
           
            // fmStrokePoint.cgPoint().fillSquare3x3AtPoint(color: NSColor.orange)

            let cgP = fmStrokePoint.cgPoint()
            /*if(fmStrokePoint.fmStrokePointType == .roundedCorner)
            {
            
                let a : [PKStrokePoint] = fmStrokePoint.pkStrokePointsArrayForFMStrokePoint(parentArrayFMStrokePointIndex: index, parentArrayPassed: arrayOfFMStrokePoints)
                
                for a1 in a
                {
                    a1.location.fillSquare3x3AtPoint(color: NSColor.orange)
                }
                
            }*/
            
            
            let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: cgP, degrees: rad2deg(fmStrokePoint.azimuth))
            
            
            
            
            let p = NSBezierPath()
            var pA = nctRotatedRect.perimeterEllipsePoints(degreeStep:2)
            p.appendPoints(&pA, count: pA.count)

                bezierTipStampArray.append(p)

            }
            
        }


    /*
        for p in pkStrokePath.interpolatedPoints(by: .parametricStep(1.0))
        {
            
             let brushTipUntransformedRect = NSMakeRect(0, 0, p.size.width , p.size.height)
             
                 let nctRotatedRect : NCTRotatedRect = brushTipUntransformedRect.rotatedAroundPoint(point: p.location, degrees: rad2deg(p.azimuth))
            
        
            let p = NSBezierPath()
            var pA = nctRotatedRect.perimenterRectanglePoints()
            p.appendPoints(&pA, count: pA.count)

                bezierTipStampArray.append(p)
            
        }
        */

        
        liveBezierPathArray.removeAll()

        
//        fmInk.mainColor.set();
        

        for path in bezierPathArrayStripA
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
//            NSColor.green.withAlphaComponent(0.5).set()
//            path.stroke();
           
//            path.fill();
            
            
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
        
        liveBezierPathArray.append(contentsOf: bezierPathArrayStripA)
      
        
   
        for path in bezierPathArrayStripB
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.cyan.setFill()
            path.lineWidth = self.lineWidth
            
//            path.fill();
//            path.stroke();
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
        
        liveBezierPathArray.append(contentsOf: bezierPathArrayStripB)

    
    for path in bezierPathArrayStripC
    {
        path.windingRule = .nonZero
        path.lineJoinStyle = .round
        //            NSColor.purple.withAlphaComponent(0.5).set()
        //            NSColor.cyan.setFill()
        path.lineWidth = self.lineWidth
        
//        path.fill();
        //            path.stroke();
        //            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
    }
    liveBezierPathArray.append(contentsOf: bezierPathArrayStripC)
    
    
    for path in bezierPathArrayStripD
    {
        path.windingRule = .nonZero
        path.lineJoinStyle = .round
        //            NSColor.purple.withAlphaComponent(0.5).set()
        //            NSColor.cyan.setFill()
        path.lineWidth = self.lineWidth
        
//        path.fill();
        //            path.stroke();
        //            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
    }
    liveBezierPathArray.append(contentsOf: bezierPathArrayStripD)


        for path in bezierPathArrayMainStrip1
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
            path.lineWidth = self.lineWidth
            
           
            
            
//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.black.setFill()
          
//            path.fill();
//            path.stroke();
         
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
    liveBezierPathArray.append(contentsOf: bezierPathArrayMainStrip1)


    

        for path in bezierPathArrayMainStrip2
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.white.setStroke()
            path.lineWidth = self.lineWidth
//            path.fill();
//            path.stroke();
            
        
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
        
         
        
        liveBezierPathArray.append(contentsOf: bezierPathArrayMainStrip2)


        for path in bezierTipStampArray
        {
            path.windingRule = .nonZero
            path.lineJoinStyle = .round
            path.lineWidth = self.lineWidth
//            NSColor.purple.withAlphaComponent(0.5).set()
//            NSColor.white.setStroke();

//            path.stroke();
//            path.fill();
//            path.pointAtIndex(0).fillSquare3x3AtPoint(color: NSColor.white)
        }
      
       liveBezierPathArray.append(contentsOf: bezierTipStampArray)


        
    }// END self.makeFMStrokeEllipseLiveVersionExtended(distance:)



    /*
     let img = NSImage.init(size: NSSize.init(width: 500, height: 500), flipped: false) { (rect) -> Bool in
     
     let p = NSBezierPath()
     
     p.appendOval(in: NSRect.init(origin: .zero, size: NSSize.init(width: 500, height: 500)))
     //self.fmInk.mainColor.
     NSColor.blue.setFill();
     p.fill()
     
     
     
     return true;
     }*/
    
        
    func displayFMStrokeEllipseSequentialTipsLive()
    {
        if(self.arrayOfFMStrokePoints.isEmpty)
        {
            return;
        }
    
        let pkStrokePath = pkStrokePathCached ?? self.pkStrokePathAcc()
        //let pkStrokePath = pkStroke.path

        self.fmInk.mainColor.setFill();
 
        
        
        
        
        
        var lastPoint : NSPoint = .zero;
        
//        let avgHeight = self.averageFMPointBrushHeight();
       
        let distanceBetweenLoopPoints : CGFloat = 1.0 // (avgHeight / 2) - (avgHeight * 0.3) //(avgHeight < 20) ? (0.8 * avgHeight) : (realtimeVectorFactor * avgHeight - (avgHeight * 0.2));
//        print(distanceBetweenLoopPoints)

        let baseRectPath = NSBezierPath()
        let rotatedBrush = NSBezierPath();

        for pkPoint in pkStrokePath.interpolatedPoints(by: .distance(distanceBetweenLoopPoints))
        {
            baseRectPath.removeAllPoints();
            
//            let brushWidth = pkPoint.size.width;
            
            if(lastPoint == .zero)
            {
                lastPoint = pkPoint.location
            }
            rotatedBrush.removeAllPoints();
                
                
                var baseRect = NSMakeRect(0,0, pkPoint.size.width,  pkPoint.size.height ).centerOnPoint(pkPoint.location)
                baseRectPath.appendOval(in: baseRect)
                
         
                
         
                rotatedBrush.appendPathRotatedAboutCenterPoint(path: baseRectPath, angleDegrees: rad2deg(pkPoint.azimuth), centerPoint: pkPoint.location)
                rotatedBrush.fill();
         
               
                 // MARK: interpolate points for gaps between this brush shape and the last point
                let d = (NSPoint.distanceBetween(lastPoint, pkPoint.location)) + 1;
                
            if((NSPoint.distanceBetween(lastPoint, pkPoint.location)) > distanceBetweenLoopPoints)
            {

                
                for r in stride(from: 1, to: d, by: distanceBetweenLoopPoints / 2.0)
                {
                    baseRectPath.removeAllPoints();
                    rotatedBrush.removeAllPoints();
                    
                    let interpolatedPoint = (vDSP.linearInterpolate([pkPoint.location.x.double(),pkPoint.location.y.double()],[lastPoint.x.double(),lastPoint.y.double()],  using: Double(r / d)))
                    
                    let interpolatedNSPoint = NSPoint(x: CGFloat(interpolatedPoint[0]), y: CGFloat(interpolatedPoint[1]))
                    
                    
                     baseRect = NSMakeRect(0,0, pkPoint.size.width,  pkPoint.size.height ).centerOnPoint(interpolatedNSPoint)
                    
                    
 
                    baseRectPath.appendOval(in: baseRect)
                    
                    rotatedBrush.appendPathRotatedAboutCenterPoint(path: baseRectPath, angleDegrees: rad2deg(pkPoint.azimuth), centerPoint: interpolatedNSPoint)
                    rotatedBrush.fill();
                    
                    
                } // END for r in stride(from: 1, to: d, by:

                
                
            }// END if
      
        lastPoint = pkPoint.location
      
        }// END for
        
    } // END displayFMStrokeLive()
    
    
    
    
    override func controlPointsBoundsForBSpline() -> NSRect
    {
        
        let path = NSBezierPath();
        
        for a in arrayOfFMStrokePoints
        {
            let p = a.cgPoint();
            path.moveToIfEmptyOrLine(to: p)
            
        }
        return path.bounds.insetBy(dx: -8.0, dy: -8.0);
        
    }
    
    override func displayControlPoints()
    {
        let path = NSBezierPath();

        for fmStrokePt in arrayOfFMStrokePoints
        {
            
            let p = fmStrokePt.cgPoint();
            path.moveToIfEmptyOrLine(to: p)
            
            var colorForRect = NSColor.purple;
            
            if(fmStrokePt.fmStrokePointType == .hardCorner)
            {
                colorForRect = NSColor.orange
            }
            else if(fmStrokePt.fmStrokePointType == .hardCornerBowedLine)
            {
                colorForRect = NSColor.orange.blended(withFraction: 0.5, of: NSColor.red) ?? colorForRect
            }
             else if(fmStrokePt.fmStrokePointType == .roundedCorner)
            {
                colorForRect = NSColor.green
            }

             else if(fmStrokePt.fmStrokePointType == .roundedCornerBowedLine)
            {
                colorForRect = NSColor.green.blended(withFraction: 0.5, of: NSColor.red) ?? colorForRect
            }
            
            p.fillSquareAtPoint(sideLength: 10.0, color: colorForRect);
        }
        
        NSColor.blue.setStroke();
        path.stroke()
        
    
        
        // interpolated points
        
        /*
        if(pkStrokePathCached != nil)
        {
            
        
            let path = NSBezierPath();
            for p in pkStrokePathCached!.interpolatedPoints(by: PKStrokePath.InterpolatedSlice.Stride.parametricStep(1.0))
            {
            
                path.moveToIfEmptyOrLine(to: p.location)
    
                p.location.fillSquare3x3AtPoint(color: NSColor.green)
            }
        
            NSColor.green.setStroke();
            path.stroke()
            
            
        }*/
        
    
    
    }
    
    
    // MARK: DISPLAY FINISHED
    func displayFinishedRectangleBrushTip()
    {

        if(liveBezierPathArray.isEmpty == false)
        {
            fmInk.mainColor.set()
            for path in liveBezierPathArray
            {
                path.fill()
                path.stroke();
                
            }
            
        }
        
    }
    
    var debugTransparency : Bool = true;
    
    func displayFinishedEllipseBrushTip()
    {

        if(liveBezierPathArray.isEmpty == false)
        {

          /*
            var unioned = NSBezierPath();
                        unioned.windingRule = NSBezierPath.WindingRule.evenOdd

                for path in self.liveBezierPathArray
                {
                    if(unioned.isEmpty)
                    {
                        unioned = path;
                        unioned.windingRule = NSBezierPath.WindingRule.evenOdd

                    }
                    else
                    {
                    unioned = unioned.fb_union(path)
                    }
                }
               unioned.stroke();
            return;*/
            

            if((self.fmInk.mainColor.alphaComponent < 1.0) && (debugTransparency == false))
            {
                
                
                let img = NSImage.init(size: self.renderBounds().size, flipped: false) { (rect) -> Bool in
                
                    self.fmInk.mainColor.withAlphaComponent(1.0).set();
                    
                    NSGraphicsContext.saveGraphicsState()
                    //            var r = NSRect.zero
                    let xfm = NSAffineTransform.init();
                    xfm.translateX(by: -self.renderBounds().minX, yBy: -self.renderBounds().minY)
                    xfm.concat()
                    
                    for path in self.liveBezierPathArray
                    {
                        path.fill()
                        path.stroke();
                    }
                    NSGraphicsContext.restoreGraphicsState()
                    
                    return true;
                }
                
                img.draw(in: self.renderBounds(), from: .zero, operation: NSCompositingOperation.sourceOver, fraction: self.fmInk.mainColor.alphaComponent)
                
            }
            else
            {
                self.fmInk.mainColor.set()

//              var count : Int = 0;

                for path in self.liveBezierPathArray
                {
                    path.fill()
                    path.stroke();
                
//                    count += path.elementCount

                }
//                print(count)

            }
            
        }// END   if(liveBezierPathArray.isEmpty == false)
    }
    
    func imageForLiveReplication() -> NSImage
    {
     
        let imgToReturn = NSImage.init(size: self.renderBounds().size, flipped: true) { (rect) -> Bool in
            
            self.fmInk.mainColor.withAlphaComponent(1.0).set();
            
            NSGraphicsContext.saveGraphicsState()
            //            var r = NSRect.zero
            let xfm = NSAffineTransform.init();
            xfm.translateX(by: -self.renderBounds().minX, yBy: -self.renderBounds().minY)
            xfm.concat()
            
            
            if((self.fmInk.brushTip == .ellipse) || (self.fmInk.brushTip == .rectangle))
            {
                if(self.liveBezierPathArray.isEmpty)
                {
                    if(self.fmInk.brushTip == .ellipse)
                    {
                        self.makeFMStrokeEllipseLiveVersionExtended(distance:self.liveDistanceForInterpolation);
                        
                    }
                    else if(self.fmInk.brushTip == .rectangle)
                    {
                        self.makeFMStrokeRectangleLive(distanceForInterpolation: self.liveDistanceForInterpolation)
                    }
                    
                }
                
                for path in self.liveBezierPathArray
                {
                    path.fill()
                    path.stroke();
                }
            }
            else if(self.fmInk.brushTip.isUniform)
            {
                self.displayUniformBrushTipLive();
            }
            
            
            NSGraphicsContext.restoreGraphicsState()
            
            return true;
        }
        
        return imgToReturn;
    }
    
   
   /*
    override func standardRepresentationModeDisplay(path:NSBezierPath)
    {
        NSGraphicsContext.current?.saveGraphicsState()
    
        switch fmInk.representationMode {
        case .inkColorIsStrokeOnly:
            fmInk.mainColor.set()
            path.stroke()
            
        case .inkColorIsFillOnly:
            fmInk.mainColor.set()
            path.fill()
            
            path.addClip()
            let s = NSShadow.init()
            s.shadowColor = self.fmInk.mainColor.blended(withFraction: 0.2, of: NSColor.black)
            s.shadowBlurRadius = 15;
            s.shadowOffset = NSMakeSize(0, 0 );
            s.set()
            let p = uniformTipBezierPath(distanceForInterpolation: 4)
            p.lineWidth = 5;
            s.shadowColor!.setStroke()
            p.stroke()
            
        case .inkColorIsStrokeAndFill:
            fmInk.mainColor.set()
            path.fill()
            path.stroke()
            
        case .inkColorIsStrokeWithSeparateFill:
            if(fmInk.secondColor != nil)
            {
                fmInk.secondColor?.setFill()
            }
            else
            {
                fmInk.mainColor.setFill()
                path.fill()
                
            }
            fmInk.mainColor.setStroke()
            path.stroke()
            
       
        }
        
        NSGraphicsContext.current?.restoreGraphicsState()
        
    }// END standardDisplay
    */
    
    var debugDisplay : Bool = false;
    override func display()
    {
    
        if(self.isFinished == false)
        {
//            NSColor.green.setFill()
//            self.renderBounds().frame(withWidth: 2.0, using: .sourceOver)
        }
        
        if(isFinished)
        {
            // SELECTION SHADOW
            selectionShadowBeginSaveGState()
            
            if(self.fmInk.brushTip == .ellipse)
            {
                
                if(self.isEmpty == false)
                {
                   
                    standardRepresentationModeDisplay(path:self)

                }
                else
                {
                
                    //displayFMStrokeCommonEllipseTangents(distanceForInterpolation: 10)
                    //return
                    if(liveBezierPathArray.isEmpty)
                    {
                        makeFMStrokeLive2(distanceForInterpolation: 15, tip: FMBrushTip.ellipse)

                        //makeFMStrokeEllipseLiveVersionExtended(distance:15);
                    }
                    liveRenderBezierArraysAsImg()
                    
                }
                
               
            }
            else if(self.fmInk.brushTip == .rectangle)
            {
                if(self.isEmpty == false)
                {
                    standardRepresentationModeDisplay(path:self)

//                    self.stroke();
//                    NSColor.white.setStroke()
//                    self.stroke();
//                    self.displayAllBezierPathPoints();
                }
                else
                {
                 //   if(liveBezierPathArray.isEmpty)
                   // {
               //         makeFMStrokeLive2(distanceForInterpolation: 15, tip: FMBrushTip.rectangle)
                   // }
                    if(liveBezierPathArray.isEmpty)
                    {
                        makeFMStrokeRectangleLive(distanceForInterpolation: self.liveDistanceForInterpolation);
                    }
                    liveRenderBezierArraysAsImg()
                    //displayFinishedRectangleBrushTip()
                }
                
            }
            else if(self.fmInk.brushTip.isUniform)
            {
            
                displayUniformBrushTipFinished();

            }
            
            
                
            selectionShadowRestoreGState()

           return;
        
        }// END if(isFinished)
        
        else if(isFinished == false)
        {
            // SELECTION SHADOW
            selectionShadowBeginSaveGState()
            
            // MARK: live ellipse
            if(self.fmInk.brushTip == .ellipse)
            {
             
               
            
            /*
                var liveCommonEllipse : Bool = false;
                if(pkStrokePathCached != nil)
                {
                    if(pkStrokePathCached!.isEmpty == false)
                    {
                        
                        if( (pkStrokePathCached!.first!.size.width < 15))
                        {
                            if(self.allSatisfyEqualBrushSize())
                            {
                                liveCommonEllipse = true;
                                
                                
                            }
                        }
                    }
                    
                }
                
                if(liveCommonEllipse)
                {
                    makeFMStrokeFinalCommonEllipseTangents(distanceForInterpolation: liveDistanceForInterpolation)
                }
                else
                {*/
                   makeFMStrokeEllipseLiveVersionExtended(distance:liveDistanceForInterpolation);
                   liveRenderBezierArraysAsImg()
                
                //}
                
                
                
                
                
                // displayFMStrokeEllipseLiveVersionSegmentBased(distanceForInterpolation: 20)
                /*
                 for a in liveBezierPathArray
                 {
                 NSColor.white.setStroke()
                 a.stroke()
                 }*/
                
            }
            
            
            // MARK: live rectangle
            else if(self.fmInk.brushTip == .rectangle)
            {
                makeFMStrokeRectangleLive(distanceForInterpolation: liveDistanceForInterpolation)
                liveRenderBezierArraysAsImg()

            }
            else if(self.fmInk.brushTip.isUniform)
            {
                displayUniformBrushTipLive();
            }
            
            //            debug3()

        }
        

        if(accessoryFMStrokes != nil)
        {
            for accessoryFMStroke in accessoryFMStrokes!
            {
                accessoryFMStroke.display();
            }
        }
    

        // debug3();

        selectionShadowRestoreGState()

        /*
        if(self.isSelected)
        {
            guard pkStrokePathCached != nil else {
                return
            }
            for pkP in self.pkStrokePathCached!.interpolatedPoints(by: .parametricStep(0.25))
            {
                pkP.location.fillSquare3x3AtPoint(color: NSColor.white)
            }
        }
        */
        
    }
    
    func liveRenderBezierArraysAsImg()
    {
    
        if(self.fmInk.mainColor.alphaComponent < 1.0)
        {
                
                let img = NSImage.init(size: self.renderBounds().size, flipped: false) { (rect) -> Bool in
                
                    self.fmInk.mainColor.withAlphaComponent(1.0).set();
                    


                    NSGraphicsContext.saveGraphicsState()
                    //            var r = NSRect.zero
                    let xfm = NSAffineTransform.init();
                    xfm.translateX(by: -self.renderBounds().minX, yBy: -self.renderBounds().minY)
                    xfm.concat()
                    
                    for path in self.liveBezierPathArray
                    {
                        self.standardRepresentationModeDisplay(path: path)
                        if((self.fmInk.brushTip != .uniform) && (self.fmInk.representationMode == .inkColorIsStrokeOnly))
                        {
                            self.fmInk.mainColor.setFill()
                            path.fill()
                        }
                        // path.fill()
                        // path.stroke();
                    }
                    NSGraphicsContext.restoreGraphicsState()
                    
                    return true;
                }
                
                img.draw(in: self.renderBounds(), from: .zero, operation: NSCompositingOperation.sourceOver, fraction: self.fmInk.mainColor.alphaComponent)
                
        }
        else
        {
            self.fmInk.mainColor.set()
            
           // NSColor.init(red: 0.5, green: 0, blue: 0, alpha: 0.5).setFill()
            
            for path in self.liveBezierPathArray
            {
                standardRepresentationModeDisplay(path: path)
                
                if((self.fmInk.brushTip != .uniform) && (self.fmInk.representationMode == .inkColorIsStrokeOnly))
                {
                    self.fmInk.mainColor.setFill()
                    path.fill()
                }
           
            }

            
        }
    }
    

    let pathInterpolationAndUnioningQueue = DispatchQueue(label: "com.noctivagous.pathInterpolationAndUnioning")

    func averageFMPointBrushHeight() -> CGFloat
    {
        var a : CGFloat = 0;
        arrayOfFMStrokePoints.forEach { (fmStrokePoint) in
            a += fmStrokePoint.brushSize.height;
        }
        return a / CGFloat(arrayOfFMStrokePoints.count)
        
    }
 
    func largestFMPointBrushWidth() -> CGFloat
    {
        var s : CGFloat = 0;
        arrayOfFMStrokePoints.forEach
        { (fmStrokePoint) in
           
            if(s == 0)
            {
                s = fmStrokePoint.brushSize.width;
            }
            else
            {
                if(fmStrokePoint.brushSize.width > s)
                {
                    s = fmStrokePoint.brushSize.width;
                }
            }
            
        }
    
        return max(s, 1);
        
    }
  
      func largestFMPointBrushHeight() -> CGFloat
    {
        var s : CGFloat = 0;
        arrayOfFMStrokePoints.forEach
        { (fmStrokePoint) in
           
            if(s == 0)
            {
                s = fmStrokePoint.brushSize.height;
            }
            else
            {
                if(fmStrokePoint.brushSize.height > s)
                {
                    s = fmStrokePoint.brushSize.height;
                }
            }
            
        }
    
        return max(s, 1);
        
    }
    
    func smallestFMPointBrushWidth() -> CGFloat
    {
        var s : CGFloat = 0;
        arrayOfFMStrokePoints.forEach { (fmStrokePoint) in
            if(s == 0)
            {
                s = fmStrokePoint.brushSize.width;
            }
            else
            {
                if(fmStrokePoint.brushSize.width < s)
                {
                    s = fmStrokePoint.brushSize.width;
                }
            }
            
        }
    
        return max(s, 1);
        
    }
    
    func smallestFMPointBrushHeight() -> CGFloat
    {
        var s : CGFloat = 0;
        arrayOfFMStrokePoints.forEach { (fmStrokePoint) in
        if(s == 0)
            {
                s = fmStrokePoint.brushSize.height;
            }
            else
            {
                if(fmStrokePoint.brushSize.height < s)
                {
                    s = fmStrokePoint.brushSize.height;
                }
            }
            
        }
    
        return max(s, 1);
        
    }
    
    func pkStrokePathAcc() -> PKStrokePath
    {
        var pkControlPoints : [PKStrokePoint] = [];
        for (index, fmStrokePoint) in self.arrayOfFMStrokePoints.enumerated()
        {
            for pkStrokePoint in fmStrokePoint.pkStrokePointsArrayForFMStrokePoint(parentArrayFMStrokePointIndex: index, parentArrayPassed: self.arrayOfFMStrokePoints)
            {
                pkControlPoints.append(pkStrokePoint)
            }
        
        
        }
        
        return PKStrokePath.init(controlPoints: pkControlPoints, creationDate: Date());
    
    }
    
    
    // MARK: UNIFORM TIP BEZIER PATH
    
    var closeUniformBezier : Bool = false;
    
    // MARK: Live Distance For Interpolation
    var liveDistanceForInterpolation : CGFloat = 15.0;
    var liveDistanceForInterpolationUniformTip : CGFloat = 1.0;
    
    
    // called by lineWorkInteractionManager: completeCurrentLineIntoShapeKeyPress()
    func makeUniformTipBezierPathForLive()
    {
        self.removeAllPoints();
        
        self.lineCapStyle = fmInk.uniformTipLineCapStyle
        self.lineJoinStyle = fmInk.uniformTipLineJoinStyle
        self.miterLimit = fmInk.uniformTipMiterLimit;
        
        let liveSimplificationFloat : Float = 0.4
        
        
        
        self.append(uniformTipBezierPath(distanceForInterpolation: fmInk.brushTip == .uniformPath ? liveDistanceForInterpolationUniformTip : 5, doSimplify:true, simplificationTolerance: liveSimplificationFloat, isFinal: false) )
        
        if(self.fmInk.brushTip == .uniformPath)
        {
           self.lineWidth = arrayOfFMStrokePoints.last?.brushSize.width ?? 10;
        }
        
        //-------------
        // lineJoinStyle = .round is temporary because of the many extra points
        // produced in the process of eliminating
        // normal internal bends for .uniform.
        //-------------
        if(self.fmInk.brushTip == .uniform)
        {
            self.lineJoinStyle = .round
        }
    }

    
    func uniformTipBezierPath(distanceForInterpolation:CGFloat, doSimplify:Bool,simplificationTolerance:Float?, isFinal:Bool) -> NSBezierPath
    {
    
        // ---------------------------
        // MAKE THE UNIFORM TIP BEZIER PATH
        // ---------------------------
        var pathToReturn = NSBezierPath();
    
    
        let pkStrokePath = self.pkStrokePathCached ?? self.pkStrokePathAcc()

        let interpolatedStrokePathPoints = pkStrokePath.interpolatedPoints(by: PKStrokePath.InterpolatedSlice.Stride.distance(distanceForInterpolation))
        
        var lastPt : NSPoint = .zero;
        for pkPt in interpolatedStrokePathPoints
        {
            // eliminates duplicate points
            if((lastPt != .zero) && (lastPt == pkPt.location))
            {
                lastPt = .zero;
                continue;
            }
        
            pathToReturn.moveToIfEmptyOrLine(to: pkPt.location)
            lastPt = pkPt.location;
        }
    
        if(self.fmInk.brushTip == .uniformPath)
        {
            if((fmInk.gkPerlinNoiseWithAmplitude != nil) && (pathToReturn.elementCount > 2))
            {
                /*
                 let allPoints = pathToReturn.buildupModePoints()
                 var simplifiedPoints = SwiftSimplify.simplify(allPoints, tolerance:
                 0.2)
                 pathToReturn.removeAllPoints();
                 pathToReturn.appendPoints(&simplifiedPoints, count: simplifiedPoints.count);
                 */
                
                pathToReturn.applyNoiseToPath(gkNoiseSource: fmInk.gkPerlinNoiseWithAmplitude!.gkPerlinNoiseSource, amplitude: fmInk.gkPerlinNoiseWithAmplitude!.amplitude, useAbsoluteValues: fmInk.gkPerlinNoiseWithAmplitude!.useAbsoluteValues, makeFragmentedLineSegments:(false,0));
            }
        }
        // ---------------------------
        // SIMPLIFY THE UNIFORM TIP BEZIER PATH
        // ---------------------------
        if(doSimplify)
        {
            
            let allPoints = pathToReturn.buildupModePoints()
            var simplifiedPoints = SwiftSimplify.simplify(allPoints, tolerance:
                                                            simplificationTolerance)//0.03)
            
            pathToReturn.removeAllPoints();
            pathToReturn.appendPoints(&simplifiedPoints, count: simplifiedPoints.count);
            
            if(closeUniformBezier )
            {
                pathToReturn.close();
            }
        }
        else
        {
            if(closeUniformBezier )
            {
                pathToReturn.close();
            }
        }
        
        
        if(self.fmInk.brushTip == .uniform)
        {
            
            let widthForStrokedPath : CGFloat = arrayOfFMStrokePoints.last?.brushSize.width ?? 10
            pathToReturn.lineCapStyle = self.fmInk.uniformTipLineCapStyle
            pathToReturn.lineJoinStyle = self.fmInk.uniformTipLineJoinStyle;
            
            // ------
            // by using withFragmentedLineSegments
            // all of the intersection points are available
            // that are not there with the normals stroking from
            // Quartz.
            // -----------
            
            
            
            
            let pathToReturnStrokedPath = pathToReturn.strokedPath(withStrokeWidth: widthForStrokedPath)
            
            //return pathToReturnStrokedPath
            
            let pathToReturnWithFragSeg = pathToReturnStrokedPath.withFragmentedLineSegments( isFinal ? 0.5 : 1)
            
            
            let differenceVal : CGFloat = 0.25;
            
            let smallerVal = max(widthForStrokedPath - differenceVal, 0.5)
            let smallerPathForExcludingStrokedPathByproducts = pathToReturn.strokedPath(withStrokeWidth: smallerVal)
            
            /*
            var smallerSmaller : NSBezierPath?
            if(closeUniformBezier && isFinal)
            {
                smallerSmaller = pathToReturn.strokedPath(withStrokeWidth: smallerVal - differenceVal)
            }
            */
            
            if(smallerVal != widthForStrokedPath)
            {


                // ------------------------
                // attemptOmitDuplicates eliminates
                // jagged edges caused by subtracting one
                // stroked path from another.
                // ------------------------
                
                pathToReturn = pathToReturnWithFragSeg.pathExcludingPointsFromInsideFillPath(path: smallerPathForExcludingStrokedPathByproducts, attemptOmitDuplicates: isFinal ? true : false )//isFinal ? smallerPathForExcludingStrokedPathByproducts.withFragmentedLineSegments(0.5): smallerPathForExcludingStrokedPathByproducts)
                
                /*
                if(isFinal)
                {
                    
                    var lastPointRect : NSRect = .zero;
                    for pkPt in interpolatedStrokePathPoints
                    {
                    
                        
                        // eliminates duplicate points
                        if((lastPt != .zero) && (lastPt == pkPt.location))
                        {
                            lastPt = .zero;
                            continue;
                        }
                        
                        pathToReturn.moveToIfEmptyOrLine(to: pkPt.location)
                        lastPt = pkPt.location;
                    }
        
                   // pathToReturn.cleanUpLineSegmentStrokePath();
              
                }*/
                       
                    
                
                //pathToReturn = NSBezierPath(cgPath: CGPath.path(thatFits: pathToReturn.buildupModePoints(), tolerance: 1.0))
                
                
                /*
                if(closeUniformBezier && isFinal)
                {
                    
                    let smallerSmaller2 = smallerPathForExcludingStrokedPathByproducts.withFragmentedLineSegments(1).pathExcludingPointsFromInsideFillPath(path: smallerSmaller!)
                    
                    pathToReturn = pathToReturn.fb_union(smallerSmaller2)
                }*/
            }
            
            // ---------------------------
            // NOISE THE UNIFORM TIP SHAPE
            // ---------------------------
            
            if((fmInk.gkPerlinNoiseWithAmplitude != nil) && (pathToReturn.elementCount > 2))
            {
                /*
                 let allPoints = pathToReturn.buildupModePoints()
                 var simplifiedPoints = SwiftSimplify.simplify(allPoints, tolerance:
                 0.2)
                 pathToReturn.removeAllPoints();
                 pathToReturn.appendPoints(&simplifiedPoints, count: simplifiedPoints.count);
                 */
                
                pathToReturn.applyNoiseToPath(gkNoiseSource: fmInk.gkPerlinNoiseWithAmplitude!.gkPerlinNoiseSource, amplitude: fmInk.gkPerlinNoiseWithAmplitude!.amplitude, useAbsoluteValues: fmInk.gkPerlinNoiseWithAmplitude!.useAbsoluteValues, makeFragmentedLineSegments:(false,0));
            }
            
            // ---------------------------
            // SIMPLIFY THE UNIFORM TIP SHAPE
            // ---------------------------
            
            if(doSimplify)
            {
                if(pathToReturn.isEmpty == false)
                {

                    let allPoints = pathToReturn.buildupModePoints()
                    var simplifiedPoints = SwiftSimplify.simplify(allPoints, tolerance:
                                                                simplificationTolerance)
                    pathToReturn.removeAllPoints();
                    pathToReturn.appendPoints(&simplifiedPoints, count: simplifiedPoints.count)
                                                            
                    
                }
            }
            
            pathToReturn.close();
            
            
            
        }
        else if(self.fmInk.brushTip == .uniformPath)
        {
            /*
           let allPoints = pathToReturn.buildupModePoints()
            var simplifiedPoints = SwiftSimplify.simplify(allPoints, tolerance:
                                                            0.1)
            pathToReturn.removeAllPoints();
            pathToReturn.appendPoints(&simplifiedPoints, count: simplifiedPoints.count);
            */
        }
        
        
     
        
     
        
        return pathToReturn;
    }

/*
    func uniformTipBezierPathFromFMPoints() -> NSBezierPath
    {
        let pathToReturn = NSBezierPath();
        let arrayCount = arrayOfFMStrokePoints.count;
        
        if(arrayCount == 2)
        {
            if((self.arrayOfFMStrokePoints[0].fmStrokePointType == .bSpline) && (self.arrayOfFMStrokePoints[1].fmStrokePointType == .bSpline))
            {
                var pArray = [self.arrayOfFMStrokePoints[0].cgPoint(),self.arrayOfFMStrokePoints[1].cgPoint()]
                pathToReturn.appendPoints(&pArray, count: 2)
                return pathToReturn
                
                
            }
        }
        
      //  var lastFMStrokePoint : FMStrokePoint!;
        
        
        for (index, fmStrokePoint) in self.arrayOfFMStrokePoints.enumerated()
        {
            if(index == 0)
            {
                if(fmStrokePoint.fmStrokePointType == .bSpline)
                {
                    if(arrayCount > 1)
                    {
                        if(self.arrayOfFMStrokePoints[1].fmStrokePointType == .hardCorner)
                        {
                            pathToReturn.moveToIfEmptyOrLine(to: fmStrokePoint.cgPoint())
                            continue;
                        }
                    }
                }
            }
            
            if(index == 1)
            {
                if(fmStrokePoint.fmStrokePointType == .bSpline)
                {
                    if(self.arrayOfFMStrokePoints[0].fmStrokePointType == .bSpline)
                    {
                        pathToReturn.moveToIfEmptyOrLine(to: fmStrokePoint.cgPoint())
                        continue;
                    }
                }
            }
            
            if(fmStrokePoint.fmStrokePointType == .hardCorner)
            {
                pathToReturn.moveToIfEmptyOrLine(to: fmStrokePoint.cgPoint())
            }
            else if(fmStrokePoint.fmStrokePointType == .roundedCorner)
            {
                let pkStrokePoints = fmStrokePoint.pkStrokePointsArrayForFMStrokePoint(parentArrayFMStrokePointIndex: index, parentArrayPassed: arrayOfFMStrokePoints)
                
               
                let pkStrokePath = PKStrokePath.init(controlPoints: pkStrokePoints, creationDate: Date.init())
                
                for interpPoint in pkStrokePath.interpolatedPoints(by: PKStrokePath.InterpolatedSlice.Stride.distance(1.0))
                {
                    pathToReturn.moveToIfEmptyOrLine(to: interpPoint.location);
                    
                    
                }

            }
            else if(fmStrokePoint.fmStrokePointType == .bSpline)
            {
                
                // 1. find fmStrokePoint locations in pkStrokePathAcc
                // 2. 
                
                // TEMPORARY:
                pathToReturn.moveToIfEmptyOrLine(to: fmStrokePoint.cgPoint())


                if(arrayCount > 0)
                {
                    if((index) < (arrayCount - 1))
                    {
                    
                        let nextFMStrokePoint = self.arrayOfFMStrokePoints[index + 1]
                            let p2 = PKStrokePoint.init(location: fmStrokePoint.cgPoint(), timeOffset: 0.1, size: fmStrokePoint.brushSize, opacity: 1.0, force: 1.0, azimuth: fmStrokePoint.azimuth, altitude: fmStrokePoint.altitude)
                            let p3 = PKStrokePoint.init(location: nextFMStrokePoint.cgPoint(), timeOffset: 0.1, size: fmStrokePoint.brushSize, opacity: 1.0, force: 1.0, azimuth: fmStrokePoint.azimuth, altitude: fmStrokePoint.altitude)
                            
                            let pkStrokePath = PKStrokePath.init(controlPoints: [p2,p3], creationDate: Date.init())
                            
                            
                            for interpPoint in pkStrokePath.interpolatedPoints(by: PKStrokePath.InterpolatedSlice.Stride.distance(5.0))
                            {
                                pathToReturn.moveToIfEmptyOrLine(to: interpPoint.location);
                            }
                        
                    }
                }
                else
                {
                   pathToReturn.moveToIfEmptyOrLine(to: fmStrokePoint.cgPoint())
                }
                
                
            }
            else if((fmStrokePoint.fmStrokePointType == .hardCornerBowedLine) || (fmStrokePoint.fmStrokePointType == .roundedCornerBowedLine))
            {
                if((index) < (arrayOfFMStrokePoints.count - 1))
                {
                    let bowedInfo = fmStrokePoint.bowedInfo;
                    let nextFMStrokePoint = self.arrayOfFMStrokePoints[index + 1]
                    var lineAngleRadians = NSBezierPath.lineAngleRadiansFrom(point1: fmStrokePoint.cgPoint(), point2: nextFMStrokePoint.cgPoint())
                    let midPoint : NSPoint = nextFMStrokePoint.cgPoint().interpolatedPointAt(secondPoint: fmStrokePoint.cgPoint(), factor: bowedInfo.lineInterpolationLocation)
                    let distanceBetweenPoints = NSPoint.distanceBetween(nextFMStrokePoint.cgPoint(), fmStrokePoint.cgPoint());
                    lineAngleRadians += bowedInfo.isFacingA ? -(.pi * 0.5) : (.pi * 0.5);
           
                    let normalTravel = bowedInfo.normalHeightIsPercentageOfLineLength ? (bowedInfo.normalHeight / 100.0 * distanceBetweenPoints) : (bowedInfo.normalHeight)
                    
                    let x = (normalTravel * cos(lineAngleRadians)) + midPoint.x
                    let y = (normalTravel * sin(lineAngleRadians)) + midPoint.y

//                    pathToReturn.moveToIfEmptyOrLine(to: fmStrokePoint.cgPoint());
//                    pathToReturn.moveToIfEmptyOrLine(to: NSMakePoint(x, y));
//                    pathToReturn.moveToIfEmptyOrLine(to: nextFMStrokePoint.cgPoint());
                    
                    if((bowedInfo.isArc == true) && (distanceBetweenPoints <= 1))
                    {
                            pathToReturn.moveToIfEmptyOrLine(to: fmStrokePoint.cgPoint());
                    }
              
                    if(bowedInfo.isArc == false)
                    {
                        if(distanceBetweenPoints < 5.0)
                        {
                            pathToReturn.moveToIfEmptyOrLine(to: fmStrokePoint.cgPoint());

                        }
                        else
                        {
                            let p1 = PKStrokePoint.init(location: fmStrokePoint.cgPoint(), timeOffset: 0.1, size: fmStrokePoint.brushSize, opacity: 1.0, force: 1.0, azimuth: fmStrokePoint.azimuth, altitude: fmStrokePoint.altitude)
                            let p2 = PKStrokePoint.init(location: NSMakePoint(x, y), timeOffset: 0.1, size: fmStrokePoint.brushSize, opacity: 1.0, force: 1.0, azimuth: fmStrokePoint.azimuth, altitude: fmStrokePoint.altitude)
                            let p3 = PKStrokePoint.init(location: nextFMStrokePoint.cgPoint(), timeOffset: 0.1, size: fmStrokePoint.brushSize, opacity: 1.0, force: 1.0, azimuth: fmStrokePoint.azimuth, altitude: fmStrokePoint.altitude)
                            let pkStrokePath = PKStrokePath.init(controlPoints: [p1,p2,p3], creationDate: Date.init())
                            
                            let pkPt = pkStrokePath.interpolatedPoint(at: 5.0);
                                
                                //pathToReturn.moveToIfEmptyOrLine(to: pkPt.location)

                            pathToReturn.moveToIfEmptyOrLine(to:fmStrokePoint.cgPoint())
                            pathToReturn.moveToIfEmptyOrLine(to: pkPt.location)
                            pathToReturn.moveToIfEmptyOrLine(to:nextFMStrokePoint.cgPoint())
                            /*
                            for interpPoint in pkStrokePath.interpolatedPoints(by: PKStrokePath.InterpolatedSlice.Stride.distance(5.0))
                            {
                                pathToReturn.moveToIfEmptyOrLine(to: interpPoint.location);
                            }
                            */
                        }
                        
                    }
                    if((bowedInfo.isArc == true) && (distanceBetweenPoints > 1))
                    {
                            var arcPath = makeArcFromThreePoints(T: [fmStrokePoint.cgPoint().cgVector(),NSMakePoint(x, y).cgVector(),nextFMStrokePoint.cgPoint().cgVector()])


                            if(bowedInfo.isFacingA == false)
                            {
                               arcPath = arcPath.reversed;
                            }
                            
                            if(self.isEmpty)
                            {
                                self.append(arcPath)
                            }
                            else
                            {
                                self.appendThroughOmitFirstMoveToOfIncomingPath(incomingPath: arcPath);
                            }
                         
                    }
                    
              
                  
                    
                }
            }
            
            /*
             if(index == arrayOfFMStrokePoints.count - 2)
             {
             liveSecondToLastPenPoint = pathToReturn.lastPoint()
             }
             
             if(index == arrayOfFMStrokePoints.count - 1)
             {
             liveLastPenPoint = pathToReturn.lastPoint()
             }*/
            
         //   lastFMStrokePoint = fmStrokePoint;
        }// END for
        
        
        
        return pathToReturn;
    }
*/

    func debugDisplay1()
    {
        
        let controlPointsPath = NSBezierPath();
        let interpolatedControlPointsPath = NSBezierPath();
    
        //let pkS = self.pkStroke()
        let pkStrokePath = pkStrokePathAcc()
        
        for p in pkStrokePath
        {
            controlPointsPath.moveToIfEmptyOrLine(to: p.location);
        }
        
    
        for (fmStrokePointArrayIndex, fmStrokePoint) in self.arrayOfFMStrokePoints.enumerated()
        {
            
            
            for point in pkStrokePath.interpolatedPoints(by: .distance(1.0))
            {
                NSColor.lightGray.withAlphaComponent(0.9).setFill();
                
                point.location.fillSquare3x3AtPoint();
                
                
            }
            
         //   print("fmStrokePointArrayIndex: \(fmStrokePointArrayIndex) c \(self.arrayOfFMStrokePoints.count)")
//            if(fmStrokePoint.parentArray !== self.arrayOfFMStrokePoints)
//            {
//
//            }

            let pkStrokePointsCalculatedEnumerated = fmStrokePoint.pkStrokePointsArrayForFMStrokePoint(parentArrayFMStrokePointIndex:fmStrokePointArrayIndex, parentArrayPassed: self.arrayOfFMStrokePoints).enumerated()
            
            for (pkSIndex, _ /*pkStrokePoint*/)  in pkStrokePointsCalculatedEnumerated
            {
                let pkStrokePoint = pkStrokePath.interpolatedPoint(at: CGFloat(fmStrokePointArrayIndex))
                NSColor.green.setFill();
                pkStrokePoint.location.fillSquareAtPoint(sideLength: 10.0, color: NSColor.green)
                
              
                
                
                interpolatedControlPointsPath.moveToIfEmptyOrLine(to: pkStrokePoint.location)
                
                
                let loc = pkStrokePoint.location.offsetBy(x: -10 * CGFloat(1 + pkSIndex), y: 0)
                    NSColor.purple.withAlphaComponent(0.9).setFill();
                //pkSIndex.drawAtPoint(loc);
                
                loc.fillSquare3x3AtPoint();
                
                
            }
            
        
        
            
            /*
            switch fmStrokePoint.fmStrokePointType {
            case .hardCorner:
                
            default:
                break;
            }
            */
              
        }
        
//        NSColor.green.setStroke()
//        interpolatedControlPointsPath.stroke();
        
//        NSColor.blue.setStroke()
//        controlPointsPath.stroke()
    }

    func firstAndLastAreSameBrushSize() -> Bool
    {
        let arrayCount = self.arrayOfFMStrokePoints.count
        if arrayCount == 1
        {
            return true;
        }
        
        if(arrayCount > 1)
        {
            if(self.arrayOfFMStrokePoints.first!.brushSize == self.arrayOfFMStrokePoints.first!.brushSize)
            {
                return true
            }
        }
        
        return false;
 
    }
    
    func isStraightLineWithColinearBrushTipAngle() -> Bool
    {
        if(firstAndLastAreSameBrushSize())
        {
           // print("angleOfLine");
            let angleOfLine = round(NSBezierPath.lineAngleDegreesFrom(point1: arrayOfFMStrokePoints.first!.cgPoint(), point2: arrayOfFMStrokePoints.last!.cgPoint()) )
            
            //print("\(angleOfLine)")

           // print("angleOfBrushes");
            let angleOfBrushes = round(rad2deg(arrayOfFMStrokePoints.first!.azimuth))
        
           // print("\(angleOfBrushes)")
        
            if((angleOfLine == angleOfBrushes) || (angleOfLine == (angleOfBrushes + 180)))
            {
                return true
            }
        }
    
        return false;
    }
    
    func maxBrushDimensionIsInUpperBound(brushSize:CGSize, upperBound:CGFloat) -> Bool
    {
        if(max(brushSize.width,brushSize.height) <= upperBound)
        {
            return true
        }
        
        return false;
    
    }
    
    
    func assembleFinalBezierPathOnBackgroundThread(distanceForInterpolation:CGFloat, simplificationTolerance: CGFloat, completion: @escaping (FMStroke) -> Void)
    {
    

        var distanceForInterpolationToUse : CGFloat = distanceForInterpolation;
        
        // -----
        // Prevents the oversimplification
        // of single stroke lines that have their
        // brush angle colinear with the line itself.
        // Without changing parameters, the simplification
        // algorithm will return a shape with too few points.
        // -----
        if(simplificationTolerance >= 1.0)
        {
            if(arrayOfFMStrokePoints.isEmpty == false)
            {
                if(arrayOfFMStrokePoints.count == 2)
                {
                    if(firstAndLastAreSameBrushSize())
                    {
                        if(maxBrushDimensionIsInUpperBound(brushSize: arrayOfFMStrokePoints.first!.brushSize, upperBound: 12))
                        {
                            if(isStraightLineWithColinearBrushTipAngle())
                            {
                                distanceForInterpolationToUse = min(arrayOfFMStrokePoints.first!.brushSize.width,arrayOfFMStrokePoints.first!.brushSize.height)
                                
                            }
                        }
                    }
                }
            }
 
        }
        
    
        
        pathInterpolationAndUnioningQueue.async
        {
        

          self.makeFMStrokeFinalSegmentBased(distanceForInterpolation: distanceForInterpolationToUse, uniformTipSimplificationTolerance: simplificationTolerance, tip: self.fmInk.brushTip)
            
           

            
            /*
            let timeForMakeFMStrokeFinal1 = timeElapsedInSecondsWhenRunningCode
           {
             if(self.allSatisfyEqualBrushWidthLessThanOrEqualTo(upperBound: 15))
             {
             self.makeFMStrokeFinalCommonEllipseTangents(distanceForInterpolation: distanceForInterpolationToUse);
             }
             else
             {
             self.makeFMStrokeFinalSegmentBased(distanceForInterpolation: distanceForInterpolationToUse, uniformTipSimplificationTolerance: simplificationTolerance, tip: self.fmInk.brushTip)
                }
             }*/
            
        
           
            // print(timeForMakeFMStrokeFinal1)
           
           /*
           let timeForMakeFMStrokeFinal2 = timeElapsedInSecondsWhenRunningCode
           {

              self.makeFMStrokeFinalSegmentBased(distanceForInterpolation: distanceForInterpolationToUse, uniformTipSimplificationTolerance: simplificationTolerance, tip: self.fmInk.brushTip)
           
            
           }
           
           
              print("----")
             print("makeFMStrokeFinalCommonEllipseTangents sec: \(timeForMakeFMStrokeFinal1)")
                
                print("makeFMStrokeFinalSegmentBased sec: \(timeForMakeFMStrokeFinal2)")
                
                
                if(timeForMakeFMStrokeFinal1 > timeForMakeFMStrokeFinal2)
                {
                    
                }
                
                if(timeForMakeFMStrokeFinal1 > 4)
                {
                    
                }*/
            
            // uniform is simplified in makeFMStrokeFinalSegmentBased(
            if(self.fmInk.brushTip.isUniform == false)
            {
                self.reducePointsOfPathForNonUniform(simplificationTolerance: simplificationTolerance)

                /*
                let timeForReducePoints = timeElapsedInSecondsWhenRunningCode {
                    
                    self.reducePointsOfPathForNonUniform(simplificationTolerance: simplificationTolerance)
                }
                

                print("reducePointsOfPathForNonUniform sec: \(timeForReducePoints)")
                
                if(timeForReducePoints > 4)
                {
                    
                }
                */
            }
            
            self.liveBezierPathArray.removeAll();
            self.convexHullPath.removeAllPoints();
            completion(self);
        }// END dispatch
        
        
        
        
    } // END beginConstructionOfEllipseTipFinalBezier
    
    func allSatisfyEqualBrushWidthLessThanOrEqualTo(upperBound:CGFloat) -> Bool
    {
 
        let pkStrokePath = self.pkStrokePathCached ?? pkStrokePathAcc()
        
        guard pkStrokePath.isEmpty == false else
        {
            return false
        }
       
        if(pkStrokePath.first!.size.width > upperBound)
        {
            return false;
        }

        
        let allSatisfyEqualBrushSize = pkStrokePath.allSatisfy { (pkStrokePoint) -> Bool in
            
            if(pkStrokePath.first == nil)
            {
                return false
            }
            
            return pkStrokePoint.size == pkStrokePath.first!.size
            
        }
        
        return allSatisfyEqualBrushSize;
    }
     
    func thinFMStrokePoints(by:CGFloat)
    {
        for i in 0..<arrayOfFMStrokePoints.count
        {
            arrayOfFMStrokePoints[i].brushSize.width = max(arrayOfFMStrokePoints[i].brushSize.width - 1, 0.5)
            arrayOfFMStrokePoints[i].brushSize.height = max(arrayOfFMStrokePoints[i].brushSize.height - 1, 0.5)

        }
        
        pkStrokePathCached = pkStrokePathAcc()
    }

    func thickenFMStrokePoints(by:CGFloat)
    {
        for i in 0..<arrayOfFMStrokePoints.count
        {
            arrayOfFMStrokePoints[i].brushSize.width = min(arrayOfFMStrokePoints[i].brushSize.width + 1, 500)
            arrayOfFMStrokePoints[i].brushSize.height = min(arrayOfFMStrokePoints[i].brushSize.height + 1, 500)

        }
        
        pkStrokePathCached = pkStrokePathAcc()

    }
     
    override func renderBounds() -> NSRect
    {
        
        if(self.fmInk.brushTip.isUniform)
        {
            if(self.isEmpty == false)
            {
                var b = self.bounds
                b = b.insetBy(dx: -1 * self.lineWidth, dy: -1 * self.lineWidth)
                if(self.lineJoinStyle == .miter)
                {
                    b = b.insetBy(dx: -1 * self.lineWidth, dy: -1 * self.lineWidth)
                }
                return b
            }
            else
            {
                return .zero
            }
        }
        else
        {
            if(self.isEmpty == false)
            {
                var b = self.bounds
                b = b.insetBy(dx: -1 * self.lineWidth, dy: -1 * self.lineWidth)
                if(self.lineJoinStyle == .miter)
                {
                    b = b.insetBy(dx: -1 * self.lineWidth, dy: -1 * self.lineWidth)
                }
                return b
            }
            else
            {
                
                
                if(pkStrokePathCached == nil)
                {
                    pkStrokePathCached = self.pkStrokePathAcc();
                }
                
           
                let largestBrushTipWidth : CGFloat = largestFMPointBrushWidth();
                let largestBrushTipHeight : CGFloat = largestFMPointBrushHeight();
              
                return PKStroke.init(ink: self.pkInk, path: pkStrokePathCached!).renderBounds.insetBy(dx: -largestBrushTipWidth * 0.5, dy: -largestBrushTipHeight * 0.5).insetBy(dx: -10, dy: -10)
                
                
                
                // return PKStroke.init(ink: self.pkInk, path: pkStrokePathCached ?? self.pkStrokePathAcc()).renderBounds.insetBy(dx: -a.size.width, dy: -a.size.width)
            }
        }
        
    }
    

    
    func pkStroke() -> PKStroke
    {

        let pkStroke = PKStroke.init(ink: self.pkInk, path: self.pkStrokePathCached ?? self.pkStrokePathAcc())
        return pkStroke
    }

    func firstFMStrokePoint() -> FMStrokePoint?
    {
        return self.arrayOfFMStrokePoints.isEmpty ? nil : self.arrayOfFMStrokePoints[0]
    }

    func penultimateFMStrokePoint() -> FMStrokePoint?
    {
        return self.arrayOfFMStrokePoints.isEmpty ? nil : self.arrayOfFMStrokePoints[(self.arrayOfFMStrokePoints.count - 2)]
    }
    
    func lastFMStrokePoint() -> FMStrokePoint?
    {
        return self.arrayOfFMStrokePoints.isEmpty ? nil : self.arrayOfFMStrokePoints[(self.arrayOfFMStrokePoints.count - 1)]
    }


    

    override func pointHitTest(point : NSPoint) -> (didHit:Bool, cgPoint: CGPoint, pkStrokePoint: PKStrokePoint?)
    {
    
        for fmStrokePoint in self.arrayOfFMStrokePoints
        {
            if(fmStrokePoint.fmStrokePointType == .hardCorner)
            {
                let rToTest = NSMakeRect(0, 0, 6, 6).centerOnPoint(fmStrokePoint.cgPoint())
                if(rToTest.contains(point))
                {
                    return(true,fmStrokePoint.cgPoint(),nil);
                
                }
                
                
            }
        }
    
    
        let pkStrokePath = self.pkStrokePathCached ?? self.pkStrokePathAcc()
        
        /*
        guard pkStrokePath != nil else {
            print("FMStroke pointHitTest had no pkStrokePath")
            return (false, .zero, nil)
        }
        */
        
        guard pkStrokePath.isEmpty == false else {
            print("FMStroke pointHitTest had empty pkStrokePath")
            return (false, .zero, nil)
        }
        
        
        var didHit = false;
        var pkStrokePoint : PKStrokePoint? = nil;
        var cgPoint : CGPoint = .zero;
        
     
        for pkPoint in pkStrokePath.interpolatedPoints(by: PKStrokePath.InterpolatedSlice.Stride.parametricStep(1.0))
        {
    
            
            let location = pkPoint.location
            if(NSPointInRect(point, NSMakeRect(0, 0, 6, 6).centerOnPoint(location)))
            {
                didHit = true
                pkStrokePoint = pkPoint
                cgPoint = pkPoint.location;
                break;
            }
        
        
        }
    
        return ( didHit:didHit, cgPoint: cgPoint, pkStrokePoint:pkStrokePoint)
    }// END func pointHitTest(point : NSPoint) -> (didHit:Bool, cgPoint: CGPoint, pkStrokePoint: PKStrokePoint?)

    override func pathHitTest(point : NSPoint) -> (didHit:Bool, cgPoint: CGPoint, pkStrokePoint: PKStrokePoint?)
    {
        let pkStrokePath = pkStrokePathCached;
        
        guard pkStrokePath != nil else {
            print("FMStroke pathHitTest had no pkStrokePath")
            return (false, .zero, nil)
        }
        
        var didHit = false;
        var pkStrokePoint : PKStrokePoint? = nil;
        var cgPoint : CGPoint = .zero;
        
        for pkPoint in pkStrokePath!.interpolatedPoints(by: PKStrokePath.InterpolatedSlice.Stride.distance(4.0))
        {
        
            let location = pkPoint.location
            if(NSPointInRect(point, NSMakeRect(0, 0, 6, 6).centerOnPoint(location)))
            {
                didHit = true
                pkStrokePoint = pkPoint
                cgPoint = pkPoint.location;
                break;
            }
        
        
        }
    
        return ( didHit:didHit, cgPoint: cgPoint, pkStrokePoint:pkStrokePoint)
    
    
    } // END pathHitTest(point : NSPoint) -> (didHit:Bool, cgPoint: CGPoint, pkStrokePoint: PKStrokePoint?)
    
    override func copy() -> Any
    {
        let fmStrokeCopy : FMStroke = super.copy() as! FMStroke

        // in super call: fmStrokeCopy.fmInk = self.fmInk; //
        fmStrokeCopy.arrayOfFMStrokePoints.removeAll();
        fmStrokeCopy.arrayOfFMStrokePoints.append(contentsOf: self.arrayOfFMStrokePointsDeepCopy)
        
        // ------------------
        // Change parent stroke for each FMStrokePoint
        // to FMStroke copy
        // -------------------
        for i in 0..<fmStrokeCopy.arrayOfFMStrokePoints.count
        {
            fmStrokeCopy.arrayOfFMStrokePoints[i].parentFMStroke = fmStrokeCopy;
        }
        
        fmStrokeCopy.isFinished = self.isFinished;
        

        return fmStrokeCopy

    }
    
    override func xmlElements(includeFMKRTags:Bool) -> [XMLElement]
    {
    
        var xmlElementsToReturn : [XMLElement] = [];
    
        var pathSVGElement = bezierPathSVGXMLElement()
        
        xmlElementsToReturn.append(pathSVGElement)
        
        applyFillAndStrokeSVGPathAttributes(pathSVGElement: &pathSVGElement)
        applyAnyShadingShapes(xmlElementsToReturn: &xmlElementsToReturn)
      
        if(includeFMKRTags)
        {
          
            pathSVGElement.removeAttribute(forName: "fmkr:DrawableType")
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "fmkr:DrawableType", stringValue: "FMStroke") as! XMLNode)
            
            var fmStrokeXMLElement = XMLElement.init(name: "fmkr:FMStroke")
            
            pathSVGElement.addChild(fmStrokeXMLElement)

            if(self.fmInk.brushTip.isUniform)
            {
                fmStrokeXMLElement.addAttribute(XMLNode.attribute(withName: "closeUniformBezier", stringValue: self.closeUniformBezier ? "true" : "false") as! XMLNode);
            }
            
            addAccompanyingFMKRTagsInkShadingShapes(xmlElement: &fmStrokeXMLElement)
            
         
         
         
            for fmStrokePoint in arrayOfFMStrokePoints
            {
                let xmlFMStrokePoint = XMLElement.init(name: "fmkr:FMStrokePoint");
                
                xmlFMStrokePoint.attributes = [
                    XMLNode.attribute(withName: "type", stringValue: "\(fmStrokePoint.fmStrokePointType.rawValue)") as! XMLNode,
                    
                    XMLNode.attribute(withName: "location", stringValue: "\(fmStrokePoint.x),\(fmStrokePoint.y)")  as! XMLNode,
                    
                    XMLNode.attribute(withName: "azimuth", stringValue: "\(fmStrokePoint.azimuth)") as! XMLNode,
                    
                    XMLNode.attribute(withName: "brushSize", stringValue: "\(fmStrokePoint.brushSize.width),\(fmStrokePoint.brushSize.height)") as! XMLNode
                    
                    
                ]
                
                
                if((fmStrokePoint.fmStrokePointType == .hardCornerBowedLine) || (fmStrokePoint.fmStrokePointType == .roundedCornerBowedLine))
                {
                    
                    // bowedInfo =  (isFacingA : Bool, normalHeight: CGFloat, normalHeightIsPercentageOfLineLength: Bool, lineInterpolationLocation : CGFloat, isArc : Bool) = (true, 20, false, 0.5, false);
                    
                    let xmlFMBowedInfo = fmStrokePoint.bowedInfo.xmlElement()
                    /*
                     XMLElement.init(name: "fmkr:FMSPBowedInfo");
                     xmlFMBowedInfo.attributes = [
                     XMLNode.attribute(withName: "isFacingA", stringValue: "\(fmStrokePoint.bowedInfo.isFacingA)") as! XMLNode,
                     
                     XMLNode.attribute(withName: "normalHeight", stringValue: "\(fmStrokePoint.bowedInfo.normalHeight)")  as! XMLNode,
                     
                     XMLNode.attribute(withName: "normalHeightIsPercentageOfLineLength", stringValue: "\(fmStrokePoint.bowedInfo.normalHeightIsPercentageOfLineLength)") as! XMLNode,
                     
                     XMLNode.attribute(withName: "lineInterpolationLocation", stringValue: "\(fmStrokePoint.bowedInfo.lineInterpolationLocation)") as! XMLNode,
                     
                     XMLNode.attribute(withName: "isArc", stringValue: "\(fmStrokePoint.bowedInfo.isArc)") as! XMLNode
                     ]
                     */
                    xmlFMStrokePoint.addChild(xmlFMBowedInfo)
                }
                
                if((fmStrokePoint.fmStrokePointType == .roundedCorner) || (fmStrokePoint.fmStrokePointType == .roundedCornerBowedLine))
                {
                    
                    let xmlFMSPRoundedCornerInfo = XMLElement.init(name: "fmkr:FMSPRoundedCornerInfo");
                    
                    xmlFMSPRoundedCornerInfo.attributes = [
                        XMLNode.attribute(withName: "cornerRoundingType", stringValue: "\(fmStrokePoint.cornerRoundingType)") as! XMLNode,
                        
                        XMLNode.attribute(withName: "roundedCornerSegmentLength", stringValue: "\(fmStrokePoint.roundedCornerSegmentLength)")  as! XMLNode,
                    ]
                    
                    xmlFMStrokePoint.addChild(xmlFMSPRoundedCornerInfo)
                    
                }
                
                fmStrokeXMLElement.addChild(xmlFMStrokePoint)
                
                //            stringForXMLFMStrokePoints.append("\(fmStrokePoint.fmStrokePointType.rawValue)\(fmStrokePoint.x),\(fmStrokePoint.y)")
                
            }
            
        }
    

        
        return xmlElementsToReturn;
    
    }
 
 
 
     // MARK: ---  NSPasteboardWriting
    
    /*
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
 
     This method returns an array of UTIs for the data types your object can write to the pasteboard.
 The order in the array is the order in which the types should be added to the pasteboard—this is important as only the first type is written initially, the others are provided lazily (see Promised Data).
 The method provides the pasteboard argument so that you can return different arrays for different pasteboards. You might, for example, put different data types on the dragging pasteboard than you do on the general pasteboard, or you might put on the same data types but in a different order. You might add to the dragging pasteboard a special representation that indicates the indexes of items being dragged so that they can be reordered.
 
     */
    
    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
    
        let customUTIForDrawable = self.pasteboardTypeUTIForDrawableClass
        return [customUTIForDrawable,NSPasteboard.PasteboardType.string]
        
    }
    
    
    override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
    
    
        if(type == self.pasteboardTypeUTIForDrawableClass)
        {
        
            let xmlElement = xmlElementsWrappedInSVG(includeFMKRTags: true)
            
            return xmlElement.xmlString
            /*
            do {
                
                
                
                return try xmlElements(includeFMKRTags:true)[0]
                //NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
                
            } catch  {
                print("error archiving for pasteboard");
            }*/
        }
       // else if(type == NSPasteboard.PasteboardType.html)
       // {
        //}
        else if(type == NSPasteboard.PasteboardType.string)
        {
        
            return xmlElementsWrappedInSVG(includeFMKRTags: false).xmlString
            
        }
        
        return nil
    }
    
    
    
    // NSPasteboardReading
    /*
      class func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
 This class method returns an array of UTIs for the data types your object can read from the pasteboard.
 The method provides the pasteboard argument so that you can return for different arrays for different pasteboards. As with reading, you might put different data types on the general pasteboard than you do on the dragging pasteboard, or you might put on the same data types but in a different order.
 */
    override class func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
    {
        let customUTIForDrawable = NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmstroke")
        
        
        return [customUTIForDrawable]
        
    }
    
    // MARK: PASTEBOARD READING
    
    
    override class func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions {
        
        if(type == NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmstroke"))
        {
            return NSPasteboard.ReadingOptions.asString
        }
     //   else if(type == NSPasteboard.PasteboardType.string)
     //   {
         
     //       return "quartzCode for Drawable"
            
      //  }
        
        return NSPasteboard.ReadingOptions.asString
        
    }
    
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType)
    {
        super.init()
   
        if let propertyListString = propertyList as? String
        {
            
            do{
             
                let svgXMLElement = try XMLElement.init(xmlString: propertyListString)
                
                if let pathXMLElement = try svgXMLElement.nodes(forXPath: "path[1]")[0] as? XMLElement
                {
                    
                    if let dContents = pathXMLElement.attribute(forName: "d")?.stringValue
                    {
                        
                        baseFMDrawableClassInitStep(baseXMLElement: pathXMLElement, svgPath: dContents)
                        secondaryStepForInit(baseXMLElement: pathXMLElement, svgPath: dContents)
                        
                    }
                    
                }
                else
                {
                    
                    
                }
                
            }
            catch{
                print("error init from pasteboard");
            }
            
            
        }
        
        else
        {
            print("propertyListString = propertyList as? String not a string")
            
        }
        
    }// END required init?(pasteboardPropertyList

    
}// END FMStroke

enum FMStrokePointType : String {
    case bSpline
    case roundedCorner
    case hardCorner
    case hardCornerBowedLine
    case roundedCornerBowedLine
    case arcByThreeP1
    case arcByThreeP2
    case bezierFitCurve
    
}

struct FMStrokePoint : Equatable {

    var x : CGFloat;
    var y : CGFloat;
    var fmStrokePointType : FMStrokePointType;
    var azimuth : CGFloat
    {
        didSet
        {
            if(azimuth > (2 * .pi))
            {
                azimuth = (2 * .pi) - azimuth
            }
            else if(azimuth < 0)
            {
                azimuth = (2 * .pi) + azimuth
            }
            
        }
    }
    var altitude : CGFloat;
    var brushSize : CGSize;
    var bowedInfo : BowedInfo;
    
    var roundedCornerSegmentLength : CGFloat = 25.0;
    var cornerRoundingType : NCTCornerRoundingType = .bSpline;


    init(xmlElement:XMLElement,parentFMStroke:FMStroke) {
      //  type="bSpline" location="1070.349609375,193.1116943359375" azimuth="0.0" brushSize="68.0,13.600000000000001"
    
        
        let strokeTypeString = xmlElement.attribute(forName: "type")?.stringValue
        
     
        
        let strokePointType = FMStrokePointType.init(rawValue: strokeTypeString ?? "") ?? .hardCorner
        
        var x : CGFloat = 0;
        var y : CGFloat = 0;
        if let locationString = xmlElement.attribute(forName: "location")?.stringValue
        {
            let locationXYArray = locationString.components(separatedBy: ",")
            if(locationXYArray.count > 1)
            {
                
                x = CGFloat(Double(locationXYArray[0]) ?? 0)
                y = CGFloat(Double(locationXYArray[1]) ?? 0)
            }
        }
        
        let brushSizeString = xmlElement.attribute(forName: "brushSize")?.stringValue
        let brushSizeWidth = CGFloat(Double(brushSizeString?.components(separatedBy: ",")[0] ?? "10") ?? 10)
        let brushSizeHeight = CGFloat(Double(brushSizeString?.components(separatedBy: ",")[1] ?? "10") ?? 10)
  
        let azimuthString = xmlElement.attribute(forName: "azimuth")?.stringValue
        let azimuthInCGFloat = CGFloat(Double(azimuthString ?? "0") ?? 0 )
    
        self.init(xIn: x, yIn: y, fmStrokePointTypeIn: strokePointType, azimuthIn: azimuthInCGFloat, altitudeIn: 0, brushSizeIn: CGSize.init(width: brushSizeWidth, height: brushSizeHeight), parentFMStroke: parentFMStroke)
        
        
        if(strokeTypeString != nil)
        {
            if( (strokeTypeString == "roundedCorner") || (strokeTypeString == "roundedCornerBowedLine"))
            {
                do {
                    let rCInfo = try xmlElement.nodes(forXPath: "fmkr:FMSPRoundedCornerInfo")
                    if(rCInfo.isEmpty == false)
                    {
                        
                        if let a = rCInfo[0] as? XMLElement
                        {
                            let attrStr = a.stringFromAttribute(attributeName: "cornerRoundingType", defaultVal: "bSpline")
                            self.cornerRoundingType = NCTCornerRoundingType.init(rawString: attrStr)
                            self.roundedCornerSegmentLength = a.cgFloatFromAttribute(attributeName: "roundedCornerSegmentLength", defaultVal: 5.0)
                        }
                    }
                    
                    
                }
                catch
                {
                    
                }
                
            }
            
            if((strokeTypeString == "hardCornerBowedLine") || (strokeTypeString == "roundedCornerBowedLine"))
            {
                do {
                    let bowedInfoArray = try xmlElement.nodes(forXPath: "fmkr:FMSPBowedInfo")
                    if(bowedInfoArray.isEmpty == false)
                    {
                        self.bowedInfo = BowedInfo.init(xmlElement: bowedInfoArray[0] as! XMLElement)
                    }
                }
                catch
                {
                    
                }
              
            }
        }
        
      
    }

    init(xIn:CGFloat,yIn:CGFloat,fmStrokePointTypeIn:FMStrokePointType,azimuthIn:CGFloat,altitudeIn:CGFloat,
    brushSizeIn:CGSize, parentFMStroke: FMStroke?) {
        x = xIn
        y = yIn
        fmStrokePointType = fmStrokePointTypeIn
        azimuth = azimuthIn
        altitude = altitudeIn
        brushSize = brushSizeIn
       self.parentFMStroke = parentFMStroke
       bowedInfo = BowedInfo.init(isFacingA: true, normalHeight: 10, normalHeightIsPercentageOfLineLength: false, lineInterpolationLocation: 0.5, lineInterpolationLocationMultiplier: 1.0, isArc: false, makeCornered: false, corneredAsHard: false, lineInterpolationDualDistance:0)
    }
  
      init(xIn:CGFloat,yIn:CGFloat,fmStrokePointTypeIn:FMStrokePointType,azimuthIn:CGFloat,altitudeIn:CGFloat,
    brushSizeIn:CGSize, parentFMStroke: FMStroke?, bowedInfo : BowedInfo) {
        x = xIn
        y = yIn
        fmStrokePointType = fmStrokePointTypeIn
        azimuth = azimuthIn
        altitude = altitudeIn
        brushSize = brushSizeIn
       self.parentFMStroke = parentFMStroke
       self.bowedInfo = bowedInfo;
    }
    
    weak var parentFMStroke : FMStroke?
    
    func pkStrokePointsArrayForFMStrokePoint(parentArrayFMStrokePointIndex:Int, parentArrayPassed: [FMStrokePoint]?) -> [PKStrokePoint]
    {
    
        var pkPtArray : [PKStrokePoint] = [];

        if(parentArrayPassed != nil)
        {
            // MARK: .bSpline
            if(self.fmStrokePointType == .bSpline)
            {
                let pkStkPt = PKStrokePoint.init(location: self.cgPoint(), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                pkPtArray.append(pkStkPt)
                
                
                
            }
            // MARK: .roundedCorner
            else if (self.fmStrokePointType == .roundedCorner)
            {
            
                if((parentArrayFMStrokePointIndex > 0)  && (parentArrayFMStrokePointIndex < (parentArrayPassed!.count - 1)))
                {
                    if(roundedCornerSegmentLength == 1.0)
                    {
                        var count = 0;
                        repeat{
                            let pkStkPt = PKStrokePoint.init(location: self.cgPoint(), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                            pkPtArray.append(pkStkPt)
                            count += 1
                        } while count < 2
                        
                        return pkPtArray
                    }
                
                
                    let prev = parentArrayPassed![parentArrayFMStrokePointIndex - 1];
                        let next = parentArrayPassed![parentArrayFMStrokePointIndex + 1];

                    var roundingSegmentLengthToUse : CGFloat = 1;
                    if(
                    
                    (( NSPoint.distanceBetween(prev.cgPoint(),self.cgPoint()) / 2) > (roundedCornerSegmentLength ) )  &&
                    ((NSPoint.distanceBetween(next.cgPoint(),self.cgPoint()) / 2) > (roundedCornerSegmentLength ))
                    )
                    
                    {
                        roundingSegmentLengthToUse = roundedCornerSegmentLength
                    }
                    else
                    {
                        
                        let minDistOfTwo = min(
                        NSPoint.distanceBetween(prev.cgPoint(),self.cgPoint() ) / 2, NSPoint.distanceBetween(next.cgPoint(),self.cgPoint()) / 2 );
                        
                            roundingSegmentLengthToUse = 0.5 * minDistOfTwo
                
                    }
                    
                        let angle1 = NSBezierPath.lineAngleRadiansFrom(point1: self.cgPoint(), point2: prev.cgPoint())
                        
                        let angle2 = NSBezierPath.lineAngleRadiansFrom(point1: self.cgPoint(), point2: next.cgPoint())
                    
                    
                       let location1 = NSMakePoint(self.x + (roundingSegmentLengthToUse * cos(angle1)), self.y + (roundingSegmentLengthToUse * sin(angle1)))
                       
                        let location2 = NSMakePoint(self.x + (roundingSegmentLengthToUse * cos(angle2)), self.y + (roundingSegmentLengthToUse * sin(angle2)))
                    
                    
                        
                        if(cornerRoundingType == .arc)
                        {

                            let bezierPathForBSplinePoints = NSBezierPath();
                        
                            bezierPathForBSplinePoints.move(to: location1)
                            bezierPathForBSplinePoints.appendArc(from: self.cgPoint(), to: location2, radius: roundingSegmentLengthToUse)
                            
                            let buildupModePoints = bezierPathForBSplinePoints.buildupModePoints();
                            for cgpt in buildupModePoints
                            {
                                let pkStkPt = PKStrokePoint.init(location: cgpt, timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                                pkPtArray.append(pkStkPt)
                            }
                        
                            return pkPtArray
                        }
                    
                    
                    let pkStkPt = PKStrokePoint.init(location: location1, timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                    pkPtArray.append(pkStkPt)
                    
                    if(cornerRoundingType == .bevel)
                    {
                        pkPtArray.append(pkStkPt)
                        pkPtArray.append(pkStkPt)
                    }
                    
                        let pkStkPt2 = PKStrokePoint.init(location: location2, timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                    pkPtArray.append(pkStkPt2)
                    if(cornerRoundingType == .bevel)
                    {
                    pkPtArray.append(pkStkPt2)
                    pkPtArray.append(pkStkPt2)
                    }
                    return pkPtArray

                    
                    
                    
                }
             
                 var count = 0;
                repeat{
                    let pkStkPt = PKStrokePoint.init(location: self.cgPoint(), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                    pkPtArray.append(pkStkPt)
                    count += 1
                } while count < 2
                
                
                return pkPtArray
                
            }
            // MARK: .hardCorner
            else if (self.fmStrokePointType == .hardCorner)
            {
                var count = 0;
                repeat{
                    let pkStkPt = PKStrokePoint.init(location: self.cgPoint(), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                    pkPtArray.append(pkStkPt)
                    count += 1
                } while count < 3
            }
            // MARK: .roundedCornerBowedLine
            else if (self.fmStrokePointType == .roundedCornerBowedLine)
            {
                var count = 0;
                repeat{
                    let pkStkPt = PKStrokePoint.init(location: self.cgPoint(), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                    pkPtArray.append(pkStkPt)
                    count += 1
                } while count < 2
                
                if((parentArrayFMStrokePointIndex) < (parentArrayPassed!.count - 1))
                {
                    guard parentFMStroke != nil else {
                        print("parentFMStroke was nil in FMStrokePoint .roundedCornerBowedLine")
                        return pkPtArray;
                    }
                    
                    let nextFMStrokePoint = parentFMStroke!.arrayOfFMStrokePoints[parentArrayFMStrokePointIndex + 1]
                
                    var lineAngleRadians = NSBezierPath.lineAngleRadiansFrom(point1: self.cgPoint(), point2: nextFMStrokePoint.cgPoint())
                 
                 
                 
                    let midPoint : NSPoint = nextFMStrokePoint.cgPoint().interpolatedPointAt(secondPoint: self.cgPoint(), factor: bowedInfo.lineInterpolationLocationMultiplier * bowedInfo.lineInterpolationLocation)
                    let distanceBetweenPoints = NSPoint.distanceBetween(nextFMStrokePoint.cgPoint(), self.cgPoint());
                    
                    
                    
                    lineAngleRadians += bowedInfo.isFacingA ? -(.pi * 0.5) : (.pi * 0.5);
                    
                    let normalTravel = bowedInfo.normalHeightIsPercentageOfLineLength ? (bowedInfo.normalHeight / 100.0 * distanceBetweenPoints) : bowedInfo.normalHeight
                    
//                    print(bowedInfo.normalHeight)
                    
                    let x = (normalTravel * cos(lineAngleRadians)) + midPoint.x
                    let y = (normalTravel * sin(lineAngleRadians)) + midPoint.y
                    
                    let bowedPkStkPt = PKStrokePoint.init(location: NSMakePoint(x, y), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                    
                    if(bowedInfo.isArc == false)
                    {
                        if(bowedInfo.lineInterpolationDualDistance == 0)
                        {
                            pkPtArray.append(bowedPkStkPt)
                            
                            if(bowedInfo.makeCornered)
                            {
                                pkPtArray.append(bowedPkStkPt)
                                if(bowedInfo.corneredAsHard)
                                {
                                    pkPtArray.append(bowedPkStkPt)
                                }
                            }
                            
                            
                        }
                        else
                        {
                            
                            let linePointA = nextFMStrokePoint.cgPoint().interpolatedPointAt(secondPoint: self.cgPoint(), factor: (bowedInfo.lineInterpolationLocationMultiplier * bowedInfo.lineInterpolationLocation) - (0.5 * bowedInfo.lineInterpolationDualDistance))
                            
                            
                            let linePointB = nextFMStrokePoint.cgPoint().interpolatedPointAt(secondPoint: self.cgPoint(), factor: (bowedInfo.lineInterpolationLocationMultiplier * bowedInfo.lineInterpolationLocation) + (0.5 * bowedInfo.lineInterpolationDualDistance))
 
                            let xLocationA = (normalTravel * cos(lineAngleRadians)) + linePointA.x
                            let yLocationA = (normalTravel * sin(lineAngleRadians)) + linePointA.y
                            
                            let xLocationB = (normalTravel * cos(lineAngleRadians)) + linePointB.x
                            let yLocationB = (normalTravel * sin(lineAngleRadians)) + linePointB.y
                            
                            
                            let bowedPkStkPtLocationA = PKStrokePoint.init(location: NSMakePoint(xLocationA, yLocationA), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                            
                            pkPtArray.append(bowedPkStkPtLocationA)
                            
                           // pkPtArray.append(bowedPkStkPtLocationA)

                            if(bowedInfo.makeCornered)
                            {
                                pkPtArray.append(bowedPkStkPtLocationA)
                                if(bowedInfo.corneredAsHard)
                                {
                                pkPtArray.append(bowedPkStkPtLocationA)
                                }
                            }
                            
                            
                            
                            let bowedPkStkPtLocationB = PKStrokePoint.init(location: NSMakePoint(xLocationB, yLocationB), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                            
                            pkPtArray.append(bowedPkStkPtLocationB)
                        
                            //pkPtArray.append(bowedPkStkPtLocationB)
                            
                            if(bowedInfo.makeCornered)
                            {
                                pkPtArray.append(bowedPkStkPtLocationB)
                                if(bowedInfo.corneredAsHard)
                                {
                                    pkPtArray.append(bowedPkStkPtLocationB)
                                }
                            }

                        }
                        
                                                
                    }
                    
                    if((bowedInfo.isArc == true) && (distanceBetweenPoints <= 1))
                    {
                        pkPtArray.append(bowedPkStkPt)
                    }
                    
                    if((bowedInfo.isArc == true) && (distanceBetweenPoints > 1))
                    {
                            let arcPath = makeArcFromThreePoints(T: [self.cgPoint().cgVector(),bowedPkStkPt.location.cgVector(),nextFMStrokePoint.cgPoint().cgVector()])

                            var buildupModePoints = arcPath.buildupModePoints();

                            if(bowedInfo.isFacingA == false)
                            {
                                buildupModePoints.reverse()
                            }

                            for cgpt in buildupModePoints
                            {
                                let pkStkPt = PKStrokePoint.init(location: cgpt, timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                                pkPtArray.append(pkStkPt)
                            }
                        
                    }
                    
                }
                else
                {
//                    print("\(parentArrayFMStrokePointIndex) \(parentArrayPassed!.count - 1)")
                }
                
                
            }
            else if(self.fmStrokePointType == .arcByThreeP1)
            {
                // --------
                // equiv to hard corner and will remain
                // until modified below the repeat.
                // --------
                var count = 0;
                repeat{
                    let pkStkPt = PKStrokePoint.init(location: self.cgPoint(), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                    pkPtArray.append(pkStkPt)
                    count += 1
                } while count < 3
                
                if
                (
                (parentArrayPassed!.count > 2)
                &&
                (parentArrayFMStrokePointIndex < (parentArrayPassed!.count - 1))
                &&
                (parentArrayFMStrokePointIndex > 0)
                )
                {
                    
                    guard parentFMStroke != nil else {
                        print("parentFMStroke was nil in FMStrokePoint .hardCornerBowedLine")
                        return pkPtArray;
                        
                    }
                    
                    let nextFMStrokePoint = parentFMStroke!.arrayOfFMStrokePoints[parentArrayFMStrokePointIndex + 1]
                    
                    if(nextFMStrokePoint.fmStrokePointType == .arcByThreeP2)
                    {
                        // REMOVE ALL.
                        pkPtArray.removeAll();
                    
                        let previousCGpt = parentFMStroke!.arrayOfFMStrokePoints[parentArrayFMStrokePointIndex - 1].cgPoint();
                        
                        
                        let arcPath = makeArcFromThreePoints(T: [previousCGpt.cgVector(),self.cgPoint().cgVector(),nextFMStrokePoint.cgPoint().cgVector()])
                        
                        var buildupModePoints = arcPath.buildupModePoints();
                        
                        
                        if(buildupModePoints.isEmpty == false)
                        {
                            if(NSPointInRect(buildupModePoints.first!, nextFMStrokePoint.cgPoint().squareForPointWithInradius(inradius: 2)))
                            {
                                buildupModePoints.reverse()
                            }
                            
                        }
                        
                        for cgpt in buildupModePoints
                        {
                            let pkStkPt = PKStrokePoint.init(location: cgpt, timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                            pkPtArray.append(pkStkPt)
                        }
                        
                    }
                    else
                    {
                        return pkPtArray;
                    }
                    
                }
                
                
            }
            else if(self.fmStrokePointType == .arcByThreeP2)
            {
                /*
                var count = 0;
                repeat{
                    let pkStkPt = PKStrokePoint.init(location: self.cgPoint(), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                    pkPtArray.append(pkStkPt)
                    count += 1
                } while count < 3
                */
            }
            
            // MARK: .hardCornerBowedLine
            else if (self.fmStrokePointType == .hardCornerBowedLine)
            {
            
                // --------
                // equiv to hard corner and will remain
                // until modified below the repeat.
                var count = 0;
                repeat{
                    let pkStkPt = PKStrokePoint.init(location: self.cgPoint(), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                    pkPtArray.append(pkStkPt)
                    count += 1
                } while count < 3
                
                if((parentArrayFMStrokePointIndex) < (parentArrayPassed!.count - 1))
                {
                    
                     guard parentFMStroke != nil else {
                        print("parentFMStroke was nil in FMStrokePoint .hardCornerBowedLine")
                        return pkPtArray;
                        
                     }
                    
                    let nextFMStrokePoint = parentFMStroke!.arrayOfFMStrokePoints[parentArrayFMStrokePointIndex + 1]
                
                    var lineAngleRadians = NSBezierPath.lineAngleRadiansFrom(point1: self.cgPoint(), point2: nextFMStrokePoint.cgPoint())
                 
                    let midPoint : NSPoint = nextFMStrokePoint.cgPoint().interpolatedPointAt(secondPoint: self.cgPoint(), factor: bowedInfo.lineInterpolationLocationMultiplier * bowedInfo.lineInterpolationLocation)
                    let distanceBetweenPoints = NSPoint.distanceBetween(nextFMStrokePoint.cgPoint(), self.cgPoint());
                    
                    lineAngleRadians += bowedInfo.isFacingA ? -(.pi * 0.5) : (.pi * 0.5);
                    
                    
                    
                    let normalTravel = bowedInfo.normalHeightIsPercentageOfLineLength ? (bowedInfo.normalHeight / 100.0 * distanceBetweenPoints) : (bowedInfo.normalHeight)
                    
                
                    
                    let x = (normalTravel * cos(lineAngleRadians)) + midPoint.x
                    let y = (normalTravel * sin(lineAngleRadians)) + midPoint.y
                    
                    let bowedPkStkPt = PKStrokePoint.init(location: NSMakePoint(x, y), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                    
                    if(bowedInfo.isArc == false)
                    {
                        if(bowedInfo.lineInterpolationDualDistance == 0)
                        {
                            pkPtArray.append(bowedPkStkPt)
                            
                            if(bowedInfo.makeCornered)
                            {
                                pkPtArray.append(bowedPkStkPt)
                                if(bowedInfo.corneredAsHard)
                                {
                                    pkPtArray.append(bowedPkStkPt)
                                }
                            }
                            
                            
                        }
                        else
                        {
                            
                            let linePointA = nextFMStrokePoint.cgPoint().interpolatedPointAt(secondPoint: self.cgPoint(), factor: (bowedInfo.lineInterpolationLocationMultiplier * bowedInfo.lineInterpolationLocation) - (0.5 * bowedInfo.lineInterpolationDualDistance))
                            
                            
                            let linePointB = nextFMStrokePoint.cgPoint().interpolatedPointAt(secondPoint: self.cgPoint(), factor: (bowedInfo.lineInterpolationLocationMultiplier * bowedInfo.lineInterpolationLocation) + (0.5 * bowedInfo.lineInterpolationDualDistance))
 
                            let xLocationA = (normalTravel * cos(lineAngleRadians)) + linePointA.x
                            let yLocationA = (normalTravel * sin(lineAngleRadians)) + linePointA.y
                            
                            let xLocationB = (normalTravel * cos(lineAngleRadians)) + linePointB.x
                            let yLocationB = (normalTravel * sin(lineAngleRadians)) + linePointB.y
                            
                            
                            let bowedPkStkPtLocationA = PKStrokePoint.init(location: NSMakePoint(xLocationA, yLocationA), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                            
                            pkPtArray.append(bowedPkStkPtLocationA)
                            
                           // pkPtArray.append(bowedPkStkPtLocationA)

                            if(bowedInfo.makeCornered)
                            {
                                pkPtArray.append(bowedPkStkPtLocationA)
                                if(bowedInfo.corneredAsHard)
                                {
                                pkPtArray.append(bowedPkStkPtLocationA)
                                }
                            }
                            
                            
                            
                            let bowedPkStkPtLocationB = PKStrokePoint.init(location: NSMakePoint(xLocationB, yLocationB), timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                            
                            pkPtArray.append(bowedPkStkPtLocationB)
                        
                            //pkPtArray.append(bowedPkStkPtLocationB)
                            
                            if(bowedInfo.makeCornered)
                            {
                                pkPtArray.append(bowedPkStkPtLocationB)
                                if(bowedInfo.corneredAsHard)
                                {
                                    pkPtArray.append(bowedPkStkPtLocationB)
                                }
                            }

                        }
                        
                                                
                    }
           
                    
                    if((bowedInfo.isArc == true) && (distanceBetweenPoints <= 1))
                    {
                        pkPtArray.append(bowedPkStkPt)
                    }
                    
                    if((bowedInfo.isArc == true) && (distanceBetweenPoints > 1))
                    {
                            let arcPath = makeArcFromThreePoints(T: [self.cgPoint().cgVector(),bowedPkStkPt.location.cgVector(),nextFMStrokePoint.cgPoint().cgVector()])

                            var buildupModePoints = arcPath.buildupModePoints();

                            if(bowedInfo.isFacingA == false)
                            {
                                buildupModePoints.reverse()
                            }

                            for cgpt in buildupModePoints
                            {
                                let pkStkPt = PKStrokePoint.init(location: cgpt, timeOffset: 0.1, size: self.brushSize, opacity: 1.0, force: 1.0, azimuth: self.azimuth, altitude: self.altitude)
                                pkPtArray.append(pkStkPt)
                            }
                        
                    }
                    
                }
                else
                {
//                    print("\(parentArrayFMStrokePointIndex) \(parentArrayPassed!.count - 1)")
                }
                
            }
            
            
        }
        else
        {
           assert(parentFMStroke?.arrayOfFMStrokePoints != nil)
        }
        
        return pkPtArray
    }
    
    
    /*
    func centralHardCornerPoint(parentArrayFMStrokePointIndex:Int, parentArrayPassed: [FMStrokePoint]?) -> CGPoint
    {
    
        // three points are deposited for a hard corner,
        // so get the third PKStrokePoint and its location
        if(self.fmStrokePointType == .hardCorner)
        {
           if let a = self.pkStrokePointsArrayForFMStrokePoint(parentArrayFMStrokePointIndex: parentArrayFMStrokePointIndex, parentArrayPassed: parentArrayPassed) as? [PKStrokePoint]
            {
                if((a.count - 1) > 1)
                {
                    return a[1].location
                }
            }
        }
    
        return self.cgPoint()
    
    }*/

    
    func cgPoint() -> CGPoint
    {
        return CGPoint.init(x: x, y: y);
    }
    
    func interpolatedBeginningPoint() -> CGPoint
    {
            return .zero;
    
    }
    func interpolatedMiddlePoint() -> CGPoint
    {
        
            return .zero;
    
    }
    func interpolatedEndPoint() -> CGPoint
    {
            return .zero;
    
    }
    
    mutating func setFromCGPoint(_ cgPoint : CGPoint)
    {
        x = cgPoint.x;
        y = cgPoint.y;
        
        
        
    }
    
    func angleDegreesActingAsPointBofABC() -> CGFloat?
    {

        guard (parentFMStroke != nil)
        else{
        return nil};
        
        let indexOfSelf = (parentFMStroke!.arrayOfFMStrokePoints.firstIndex(of:self)!)
        
        guard parentFMStroke != nil else {
            print("parentFMStroke was nil in angleDegreesActingAsPointBofABC")
            return nil;
        }
        guard (parentFMStroke!.arrayOfFMStrokePoints.count > indexOfSelf) else {
            return nil
        }
        
        let nextFMStrokePoint = parentFMStroke!.arrayOfFMStrokePoints[indexOfSelf + 1];
        
        let angleDegrees = NSBezierPath.lineAngleDegreesFrom(point1: self.cgPoint(), point2: nextFMStrokePoint.cgPoint())
        
       
        
         /*
         
        guard ((indexOfSelf + 1) < parentFMStroke!.arrayOfFMStrokePoints.count)
        else {
            
            fatalError("index out of range")
            return nil;
        }
        
        print("count: \(parentFMStroke!.arrayOfFMStrokePoints.count)")
        //let a = parentFMStroke!.arrayOfFMStrokePoints[];
        print("ioS - 1: \(indexOfSelf - 1)")
        print("ioS: \(indexOfSelf)")
        print("IoS + 1: \(indexOfSelf + 1)")
        
        let angleDegrees = NSBezierPath.angleDegreesFromThreePoints(
        
        p0: parentFMStroke!.arrayOfFMStrokePoints[indexOfSelf - 1].cgPoint(),
        centerPoint: self.cgPoint(),
        p2: parentFMStroke!.arrayOfFMStrokePoints[indexOfSelf + 1].cgPoint()
        
        )
        
        */
        
        
        return angleDegrees
    
    }
    
    
    
    
    static func ==(lhs: FMStrokePoint, rhs: FMStrokePoint) -> Bool {
    return  NSEqualPoints(lhs.cgPoint(), rhs.cgPoint())
    }

}


 // MARK: ---  PERFORMANCE BENCHMARKING
    func printTimeElapsedWhenRunningCode(title:String, operation:()->()) {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("Time elapsed for \(title): \(timeElapsed) s.")
    }
    
    func timeElapsedInSecondsWhenRunningCode(operation: ()->()) -> Double {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return Double(timeElapsed)
    }
