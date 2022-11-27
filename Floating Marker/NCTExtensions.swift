//
//  NCTExtensions.swift
//  NCTTextKitDemos
//
//  Created by John Pratt on 10/5/20.
//

import Cocoa
import Foundation
import SpriteKit
import Accelerate
import GameplayKit.GKNoise

let NSNotFoundPoint : NSPoint = NSMakePoint(-50001, -50001);

extension XMLElement
{
    func stringFromAttribute(attributeName:String, defaultVal:String) -> String
    {
        let s = self.attribute(forName: attributeName)?.stringValue
        
        if(s != nil)
        {
            return s!
        }
        
        return defaultVal
    }

    func cgFloatFromAttribute(attributeName:String, defaultVal:CGFloat) -> CGFloat
    {
        let attributeDoubleString = (self.attribute(forName: attributeName)?.stringValue) ?? "\(defaultVal)"
        
        let cgFloatToReturn : CGFloat = CGFloat(Double( attributeDoubleString ) ?? defaultVal.double())
        return cgFloatToReturn;
        
    }
    
    func intFromAttribute(attributeName:String, defaultVal:Int) -> Int
    {
        let attributeIntString = (self.attribute(forName: attributeName)?.stringValue) ?? "\(defaultVal)"
        
        let intToReturn : Int = Int( attributeIntString ) ?? defaultVal
        return intToReturn;
        
    }
    
    func boolFromAttribute(attributeName:String, defaultVal:Bool) -> Bool
    {
        let boolToReturn = (self.attribute(forName: attributeName)?.stringValue ?? "\(defaultVal)").boolFromString()
        
        return boolToReturn;
    }
    
    func colorFromAttribute(attributeName:String, defaultVal:NSColor) -> NSColor
    {
        
        let colorToReturnStr = self.attribute(forName: attributeName)?.stringValue ?? "rgb(0,0,0)"
        let colorToReturn = NSColor.initWithSvgSRGBAttributeStringArray(rgbColorString: colorToReturnStr) ?? defaultVal
        return colorToReturn;
    }

}


extension NSPopUpButton
{
    func selectItemWithRepresentedString(string:String)
    {
        for (index, item) in self.itemArray.enumerated()
        {
            if let stringRepresentedObj = item.representedObject as? String
            {
                if(stringRepresentedObj == string)
                {
                    self.selectItem(at: index)
                    break;
                }
            }
        }
    
    }

}

extension NSAttributedString
{
    func entireRange() -> NSRange
    {
        return NSMakeRange(0, self.length)
    }

}

extension String
{

    func boolFromString() -> Bool
    {
        return (self == "true") ?  true : false;
    
    }
    
    func print()
    {
        Swift.print(self)
    }

}

extension CGFloat
{
 func float() -> Float
  {
    return Float(self)
  }
    
    func double() -> Double
    {
        return Double(self)
    }
}


extension CGSize
{

    /*
//    e.g. : "1920x1080"
    init(dimensionsString:String)
    {
        let a = dimensionsString.components(separatedBy: "x")
        if(a.count > 1)
        {
            self.init(width: CGFloat(a[0]), height: CGFloat(a[1]))

        }
    
    }*/



    init(widthInches:CGFloat, heightInches:CGFloat)
    {
        self.init(width: 72 * widthInches, height: 72 * heightInches)
    
    }

    init(widthFeet:CGFloat, heightFeet:CGFloat)
    {
        self.init(width: 72 * 12 * widthFeet, height: 72 * 12 * heightFeet)
    
    }
    

    func inInches() -> (widthInches:CGFloat,heightInches:CGFloat)
    {
        return (width / 72.0, height / 72.0)
    }
    
    func multiplied(factor:CGFloat) -> CGSize
    {
        return CGSize.init(width: self.width * factor, height: self.height * factor)
    }

}

extension CGVector
{
    init( nspoint: NSPoint)
    {
        self.init()
        dx = CGFloat(nspoint.x);
        dy = CGFloat(nspoint.y);
    }
    
    func nspoint() -> NSPoint
    {
        return NSPoint(x: dx, y: dy);
    }
    
}


// MARK: NSWINDOW EXTENSION

enum NCTWindowRelativePosition : Int {
    /*
    0 1 2
    7 █ 3
    6 5 4
    */
    
    case topLeft = 0
    case topMiddle = 1
    case topRight = 2
    case middleRight = 3
    case bottomRight = 4
    case bottomMiddle = 5
    case bottomLeft = 6
    case middleLeft = 7
    
}

extension NSWindow
{
    func toggleVisibility()
    {
        self.setIsVisible(!self.isVisible)
    }
    
    func positionAtTopLeftOfScreen(xPadding:CGFloat, yPadding: CGFloat)
    {
        if let screenFrame = self.screen?.frame
        {
            let menuHeight :CGFloat = 25.0;
            self.setFrameTopLeftPoint(NSMakePoint(xPadding, screenFrame.height - yPadding - menuHeight ))
            
            self.setIsVisible(true)
        }
    }
    
    

/*
    There are four edges and
    four corners of a rectangle (of a window)
    and these are 8 locations
    we put into this function.
    
    0 1 2
    7 █ 3
    6 5 4
    
    We position the window with top left bias, meaning that
    if the window is moved to location number 3
    and its height is shorter than that of the target
    window, it will be "floated" to the top instead of the bottom.
    
    parameters:
    
    window - the target window to position self next to
    locationNumber - one of the eight positions above
    paddingFromNumberedEdge - padding away from the edge
    matchingHeightOfWindow - change the height of the self to be the same as target
    matchingWidthOfWindow -  change the width of the self to be the same as target
*/
    func positionWithTopLeftBias(nextTo window:NSWindow, locationNumber:NCTWindowRelativePosition,  paddingAwayFromEdge:CGFloat, matchingHeightOfWindow:Bool, matchingWidthOfWindow:Bool )
    {
        if (self.screen?.frame) != nil
       {
        
        let selfFrame = self.frame
        let targetFrame = window.frame;
        
        var newFrame = selfFrame;
        
        if matchingHeightOfWindow { newFrame.size.height = window.frame.size.height }
        
        if matchingWidthOfWindow { newFrame.size.width = window.frame.size.width }
         
        /*
            0 1 2
            7 █ 3
            6 5 4
        */
         
        switch locationNumber {
        case .topLeft:
        
            newFrame.origin.x = targetFrame.minX - selfFrame.width
            newFrame.origin.y = targetFrame.maxY
            
        case .topMiddle:
            self.setFrameOrigin(targetFrame.topLeft().offsetBy(x: 0, y: -paddingAwayFromEdge))
            newFrame = self.frame
            
        case .topRight:
            self.setFrameOrigin(targetFrame.topRight().offsetBy(x: -paddingAwayFromEdge, y: -paddingAwayFromEdge))
            newFrame = self.frame
            
        case .middleRight:
            self.setFrameTopLeftPoint(targetFrame.topRight().offsetBy(x: -paddingAwayFromEdge, y: 0))
            newFrame = self.frame
            
        case .bottomRight:
            self.setFrameTopLeftPoint(targetFrame.bottomRight().offsetBy(x: -paddingAwayFromEdge, y: paddingAwayFromEdge))
            newFrame = self.frame
            
        case .bottomMiddle:
            self.setFrameTopLeftPoint(window.frame.origin.offsetBy(x: 0, y: paddingAwayFromEdge))
            newFrame = self.frame
            
        case .bottomLeft:
            newFrame.origin.x = targetFrame.minX - selfFrame.width
            newFrame.origin.y = targetFrame.minY - selfFrame.height
            
        case .middleLeft:
            newFrame.origin.x = targetFrame.minX - selfFrame.width
            newFrame.origin.y = targetFrame.minY
    
        }
        
        
        self.setFrame(newFrame, display: true)
        self.setIsVisible(true)
        
    }
        
        
        
    
    
    }
    
    
    func setSizeOfWindow( width : CGFloat, height: CGFloat)
    {
        setSizeOfWindow(NSMakeSize(width, height))
        
    }
    
    func setSizeOfWindow( _ windowSize :CGSize)
    {
        let oldFrame = self.frame;
        var newFrame = oldFrame;
        newFrame.size = windowSize
        
        self.setFrame(newFrame, display: true)
        self.setIsVisible(true)
    }
    
    func setWidthOfWindow(_ windowWidth : CGFloat)
    {
        let oldFrame = self.frame;
        var newFrame = oldFrame;
        newFrame.size.width = windowWidth;
        
        self.setFrame(newFrame, display: true)
        self.setIsVisible(true)
        
    }

    func setHeightOfWindow(_ windowHeight : CGFloat)
    {
        let oldFrame = self.frame;
        var newFrame = oldFrame;
        newFrame.size.height = windowHeight;
        
        self.setFrame(newFrame, display: true)
        self.setIsVisible(true)
        
    }
    
    func translateHorizontal(_ x: CGFloat)
    {
        let oldFrame = self.frame;
        var newFrame = oldFrame;
        newFrame.origin.x += x;
        
        self.setFrame(newFrame, display: true)
        self.setIsVisible(true)
    }
    
    func translateVertical(_ y: CGFloat)
    {
        let oldFrame = self.frame;
        var newFrame = oldFrame;
        newFrame.origin.y += y;
        
        self.setFrame(newFrame, display: true)
        self.setIsVisible(true)
    
    }


}

extension Int
{

    var boolValue : Bool
    {
        get{return self <= 0 ? false : true;}
    }

    func drawAtPoint(_ p : NSPoint)
    {
        let string = "\(self)"
        string.drawStringInsideRectWithMenlo(fontSize: 11, textAlignment: NSTextAlignment.left, fontForegroundColor: NSColor.white, rect: NSMakeRect(p.x, p.y, 30, 12));
    
    }
    
    func drawAtPoint(_ p : NSPoint, color: NSColor?)
    {
        let string = "\(self)"
        string.drawStringInsideRectWithMenlo(fontSize: 11, textAlignment: NSTextAlignment.left, fontForegroundColor: color ?? NSColor.white, rect: NSMakeRect(p.x, p.y, 30, 12));
    
    }

    func drawAtPoint(_ p : NSPoint, color: NSColor?, fontSize: CGFloat)
    {
        let string = "\(self)"
        
        let f = fontSize >= 5 ? fontSize : 5;
        string.drawStringInsideRectWithMenlo(fontSize: f, textAlignment: NSTextAlignment.left, fontForegroundColor: color ?? NSColor.white, rect: NSMakeRect(p.x, p.y, 50, fontSize + 2));
    
    }


}

extension NSPoint
{

    func squareForPointWithInradius(inradius:CGFloat) -> NSRect
    {
        var r = NSMakeRect(0, 0, inradius * 2, inradius * 2)
        r = r.centerOnPoint(self)
        
        return r;
    }

    func sitsWithinSquareOnTopOfPoint(point:NSPoint, squareInradius:CGFloat) -> Bool
    {
        var r = NSMakeRect(0, 0, 1 + squareInradius, 1 + squareInradius)
        r = r.centerOnPoint(point)
        return NSPointInRect(self, r);
    
    }
    
    
    func sitsInsideRect(_ rect:NSRect) -> Bool
    {
        return NSPointInRect(self, rect);
    }


    func sitsOnXOfPoint(_ point:NSPoint, padding:CGFloat) -> Bool
    {
        return ( (self.x <= (point.x + padding)) && (self.x >= (point.x - padding)) );
    }
    
    func sitsOnYOfPoint(_ point:NSPoint,padding:CGFloat) -> Bool
    {
        return ( (self.y <= (point.y + padding)) && (self.y >= (point.y - padding)) );
    }

    func cgVector() -> CGVector
    {
        return CGVector(dx: x, dy: y)
    }

    static func nctNegativePointForNoPoint() -> NSPoint
    {
        return NSPoint.init(x: -1, y: -1);
    }

    func midpoint(pointB: NSPoint) -> NSPoint
    {
        return NSPoint(x: (self.x + pointB.x) / 2.0, y: (self.y + pointB.y) / 2.0)
    }
    
   
    
    func offsetBy(x: CGFloat, y:CGFloat) -> NSPoint
    {
        return NSPoint(x: self.x - x, y: self.y - y);
    }

 func unflipInsideBounds(boundsForUnflipping : NSRect) -> NSPoint
    {
        let yFlipped = boundsForUnflipping.height - (self.y);
        
        var unflipped = self
        unflipped.y = yFlipped
        
        return unflipped;
    }
    
    func distanceFrom(point2: NSPoint) -> CGFloat
    {
        let xDelta = (point2.x - self.x)
        let yDelta = (point2.y - self.y)
        
        
        return sqrt(xDelta * xDelta + yDelta * yDelta);
    }
    
    static func distanceBetween(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat
    {
        // alternative: is one line: return hypot(a.x - b.x, a.y - b.y)
    
        let xDelta = (point2.x - point1.x)
        let yDelta = (point2.y - point1.y)
        
        
        return sqrt(xDelta * xDelta + yDelta * yDelta);
    }
    
    
    static func pointWithGreatestDistanceFromReferencePoint( referencePoint : NSPoint, pointArray : [NSPoint]) -> NSPoint
    {
        var pointToReturn = referencePoint
        var lastGreatestDistance : CGFloat = 0;
        
        for p in pointArray
        {
            let distance = NSPoint.distanceBetween(referencePoint, p)
            if(distance > lastGreatestDistance)
            {
                
                pointToReturn = p
                lastGreatestDistance = distance;
            }
        }
        
        return pointToReturn
    
    }
    
    static func pointWithLeastDistanceFromReferencePoint( referencePoint : NSPoint, pointArray : [NSPoint], normalLength:CGFloat) -> NSPoint
    {
    
        var shortestDistancePoint : NSPoint = .zero;
        var lastShortestDistance :CGFloat = normalLength;
        
        for p in pointArray
        {
            
            let distance = NSPoint.distanceBetween(referencePoint,p)
            if(distance < lastShortestDistance)
            {
                lastShortestDistance = distance
                shortestDistancePoint = p
            }
            
        }
    
        return shortestDistancePoint
    
    }
    
    func hullPoint() -> [Double]
    {
        return [x.double(),y.double()]
    }
    
    func fillSquare3x3AtPoint()
    {
        let r = NSMakeRect(0, 0, 3, 3).centerOnPoint(self)
        r.fill();
    }
    
    func fillSquare3x3AtPoint(color : NSColor?)
    {
        let r = NSMakeRect(0, 0, 3, 3).centerOnPoint(self)
        color?.setFill() ?? NSColor.black.setFill();
        r.fill();
    }
    
    func fillSquareAtPoint(sideLength: CGFloat, color : NSColor?)
    {
        let r = NSMakeRect(0, 0, sideLength, sideLength).centerOnPoint(self)
        color?.setFill() ?? NSColor.black.setFill();
        r.fill();
    }
    
    
    func pointFromAngleAndLength(angleRadians:CGFloat, length:CGFloat) -> NSPoint
    {
        var nP = NSPoint()
        nP.x = self.x + length * cos(angleRadians)
        nP.y = self.y + length * sin(angleRadians)
        
        return nP;
    }
    
     static func Intersection2(p1: NSPoint, p2 : NSPoint, p3: NSPoint, p4:NSPoint) -> NSPoint?
    {
        // return the intersecting point of two lines SEGMENTS p1-p2 and p3-p4, whose end points are passed in. If the lines are parallel,
        // the result is NSNotFoundPoint. Uses an alternative algorithm from Intersection() - this is faster and more usable. This only returns a
        // point if the two segments actually intersect - it doesn't project the lines.
        
        let d : CGFloat = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y);
        
        // if d is 0, then lines are parallel and don't intersect
        if (d == 0.0)
        {
            return nil;
        }
        
        let ua : CGFloat = ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / d;
        
        if (ua >= 0.0 && ua <= 1.0)
        {
            // segments do intersect
            var ip : NSPoint = .zero;
            
            ip.x = p1.x + ua * (p2.x - p1.x);
            ip.y = p1.y + ua * (p2.y - p1.y);
            
            return ip;
        }
        else
        {
            return nil
        }
        
    }
   
   func interpolatedPointAt(secondPoint:NSPoint,factor:CGFloat) -> NSPoint
   {
    let factorToUse = factor//.clamped(to: 0...1.0)
   
    let interpolatedPoint =
        (
            vDSP.linearInterpolate(
                [secondPoint.x.double(),secondPoint.y.double()],
                [self.x.double(),self.y.double()],
                using: Double(factorToUse))
        )
                    
     return NSPoint(x: CGFloat(interpolatedPoint[0]), y: CGFloat(interpolatedPoint[1]))
                    
   }
   
   static func midpoint(p1:NSPoint, p2:NSPoint) -> NSPoint
   {
     return NSMakePoint( (p1.x + p2.x) / 2  , (p1.y + p2.y) / 2)
   
   }
   
}// END ext NSPoint





extension NSRect
{
    func maxLength() -> CGFloat
    {
        return max(self.size.width,self.size.height)
    }
    
    func diagonalLength() -> CGFloat
    {
        
        return hypot(minX - maxX, minY - maxY);
        
    }
    
    func bottomMiddle() -> NSPoint
    {
        return NSMakePoint(self.midX, self.minY)
        
    }
    
    func bottomRight() -> NSPoint
    {
        return NSMakePoint(self.maxX, self.minY)
        
    }
    
    func middleLeft() -> NSPoint
    {
        return NSMakePoint(self.minX, self.midY)
        
    }
    
    
    func bottomLeft() -> NSPoint
    {
        return NSMakePoint(self.minX, self.minY)
        
    }
    
    func topMiddle() -> NSPoint
    {
        return NSMakePoint(self.midX, self.maxY)
        
    }
    
    
    func topRight() -> NSPoint
    {
        return NSMakePoint(self.maxX, self.maxY)
        
    }
    
    func middleRight() -> NSPoint
    {
        return NSMakePoint(self.maxX, self.midY)
        
    }
    
    
    func topLeft() -> NSPoint
    {
        return NSMakePoint(self.minX, self.maxY)
        
    }
    
    func centroid() -> NSPoint
    {
        return NSMakePoint(midX, midY)
    }
    
    func shortestLength() -> CGFloat
    {
        
        return min(self.width,self.height)
    }
    
    func longestLength() -> CGFloat
    {
        return max(self.width,self.height)
    }
    
    // relocates the rect so its centre is at p. Does not change the rect's size
    
    func centerOnPoint(_ point : NSPoint) -> NSRect
    {
        var r = self;
        
        r.origin.x = point.x - (self.size.width * 0.5);
        r.origin.y = point.y - (self.size.height * 0.5);
        
        return r;
        
    }
    
    func centerInRect(_ r : NSRect) -> NSRect
    {
        var nr : NSRect = .zero;
        
        nr.size = r.size;
        
        nr.origin.x = NSMinX(self) + ((self.size.width - r.size.width) / 2.0);
        nr.origin.y = NSMinY(self) + ((self.size.height - r.size.height) / 2.0);
        
        return nr;
    }
    
    func againstInsideRightEdgeOf(_ r : NSRect, padding: CGFloat) ->NSRect
    {
        var nr : NSRect = .zero;
        
        nr.size = self.size;
        nr.origin = self.origin
        nr.origin.x = r.maxX - nr.width - padding;
        
        return nr;
        
        
    }
    
    func unflipInsideBounds(boundsForUnflipping : NSRect) -> NSRect
    {
        let yFlipped = boundsForUnflipping.height - (self.origin.y + self.height);
        
        var unflipped = self
        unflipped.origin.y = yFlipped
        
        return unflipped;
    }
    
}

extension NSBezierPath
{


    
    func moveToIfEmptyOrLine(to point: NSPoint)
    {
        if(self.isEmpty)
        {
            self.move(to: point)
        }
        else
        {
            self.line(to: point)
        }
    
    }
    
     func setLastPoint(_ lastPoint: NSPoint)
    {
        
      
        if(elementCount > 0)
        {

            let a : NSPointArray = NSPointArray.allocate(capacity: 3)
            a[0] = lastPoint;
            a[1] = lastPoint;
            a[2] = lastPoint;
        
            self.setAssociatedPoints(a, at: self.elementCount - 1);
            
            a.deallocate();
        }
        
    }
  
  func firstPoint() -> NSPoint
    {
        var points: [NSPoint] = Array.init(repeating: .zero, count: 3)
        
        if(self.elementCount > 0)
        {
           
            let elementType = self.element(at: 0, associatedPoints: &points)
        
            if(elementType == .curveTo)
            {
                return points[2];
            }
        
            return points[0];
        }
        
        return NSZeroPoint;
    }
    
    
    func lastPoint() -> NSPoint
    {
        var points: [NSPoint] = Array.init(repeating: .zero, count: 3)
        
        if(self.elementCount > 0)
        {
           
            let elementType = self.element(at: self.elementCount - 1, associatedPoints: &points)
        
            if(elementType == .curveTo)
            {
                return points[2];
            }
        
            return points[0];
        }
        
        return NSZeroPoint;
    }
    
    
    func penultimatePoint() -> NSPoint
    {
        var points: [NSPoint] = Array.init(repeating: .zero, count: 3)
        
        if(self.elementCount > 1)
        {
           
            let elementType = self.element(at: self.elementCount - 2, associatedPoints: &points)
        
            if(elementType == .curveTo)
            {
                return points[2];
            }
        
            return points[0];
        }
        
        return NSZeroPoint;
    }
    
    func pointAtIndex(_ index : Int) -> NSPoint
    {
        var points: [NSPoint] = Array.init(repeating: .zero, count: 3)
        
        if(self.elementCount > index)
        {
            
            let bezierElementType = self.element(at: index, associatedPoints: &points)
            
            if (bezierElementType == NSBezierPath.ElementType.curveTo)
            {
                return points[2];
            }
            
            return points[0];
        }
                
        return NSZeroPoint;
    }
    
    func appendRotatedOvalAtCenterPoint(angleDegrees:CGFloat, centerPoint:NSPoint, width:CGFloat,height:CGFloat)
    {
        let rectForOval = NSMakeRect(0, 0, width, height);
        let rectForOvalCenteredOnPoint = rectForOval.centerOnPoint(centerPoint);
        
        let p = NSBezierPath();
        p.appendOval(in: rectForOvalCenteredOnPoint);
        
        var a = AffineTransform();
        a.translate(x: centerPoint.x, y: centerPoint.y)
        a.rotate(byDegrees: angleDegrees);
        a.translate(x: -centerPoint.x, y: -centerPoint.y)
        
        p.transform(using: a)
        self.append(p)
    
    }

    func appendPathRotatedAboutCenterPoint(path:NSBezierPath, angleDegrees:CGFloat, centerPoint:NSPoint)
    {
        let p = path.rotatedPath(angleDegrees: angleDegrees, aboutPoint: centerPoint)
        self.append(p)
    }

   /* func rotatedPath(angle : CGFloat) -> NSBezierPath
{

}*/

   func rotatedPath(angleDegrees : CGFloat, aboutPoint:NSPoint) -> NSBezierPath
{

	if (angleDegrees == 0.0)
 {
		return self;
  }
	else {
        let copy = self.copy() as! NSBezierPath;
        let xfm = RotationTransform(angleDegrees: angleDegrees, centerPoint: aboutPoint)
        
		copy.transform(using: xfm)

		return copy ;
	}
}



    /*
    func rotatedPath(_ angle: CGFloat, aboutPoint:NSPoint) -> NSBezierPath
    {
        
    }*/

    class func lineAngleDegreesFrom(point1: NSPoint, point2: NSPoint) -> CGFloat
    {
        let width = point2.x - point1.x;
        let height = point2.y - point1.y;
        
        var angleClockwiseRadians = atan2(height, width);
        
        if(angleClockwiseRadians < 0)
        {
            angleClockwiseRadians += (2 * 3.14159265);
        }
        
        let angleInDegreesForReturn = angleClockwiseRadians * (180 / 3.14159265);
        
        
        return angleInDegreesForReturn;
        
    }
      
    class func lineAngleRadiansFrom(point1: NSPoint, point2: NSPoint) -> CGFloat
    {
        let width = point2.x - point1.x;
        let height = point2.y - point1.y;
        
        var angleClockwiseRadians = atan2(height, width);
        
        if(angleClockwiseRadians < 0)
        {
            angleClockwiseRadians += (2 * 3.14159265);
        }
        
        return angleClockwiseRadians;
        
    }
    
    class func quadrantFrom(point1: NSPoint, point2: NSPoint) -> Int
    {
        let angleInDegrees = NSBezierPath.lineAngleDegreesFrom(point1: point1, point2: point2)
        return Int(ceil( angleInDegrees / 90.0));
    }
    
    class func quadrantFrom(point1: NSPoint, point2: NSPoint, counterclockwiseOffsetDegrees : CGFloat) -> Int
    {
        let angleInDegrees = NSBezierPath.lineAngleDegreesFrom(point1: point1, point2: point2)
        var angleInDegreesAdjusted = angleInDegrees - counterclockwiseOffsetDegrees;
       
        if(angleInDegreesAdjusted < 0)
        {
            angleInDegreesAdjusted = 360 + angleInDegreesAdjusted;
        }
        else if (angleInDegreesAdjusted > 360)
        {
            angleInDegreesAdjusted = angleInDegreesAdjusted - 360;
        }
        
         return Int(ceil( angleInDegrees / 90.0));
    }
    
    class func secondPointFromAngleAndLength(firstPoint:NSPoint, angleDegrees:CGFloat,length:CGFloat) -> NSPoint
    {
        let radiansAngle = deg2rad(angleDegrees)
        
        let x = firstPoint.x + (length * cos(radiansAngle))
        let y = firstPoint.y + (length * sin(radiansAngle))
        
        return NSMakePoint(x, y);
    
    }

    
    var extendedBezierPathBounds : NSRect
    {
        get{
            
            if(self.isEmpty)
            {
                return NSZeroRect;
            }
            
            let rectForExtendedBounds : NSRect = self.bounds;
            let insetRect = rectForExtendedBounds.insetBy(dx: -self.lineWidth, dy: -self.lineWidth)
            
            return insetRect
            /*
            if(self.lineWidth > 10)
            {
                rectForExtendedBounds = self.strokedPath(withStrokeWidth: self.lineWidth).bounds;
                /*
                let v : CGPath = (self.cgPath)
                let z = v.copy(strokingWithWidth: self.lineWidth, lineCap: .butt, lineJoin: CGLineJoin.miter, miterLimit: 5.0)
                
                let x = NSBezierPath(cgPath: z)
                rectForExtendedBounds = x.bounds;
                */
                
            }
            else
            {
                rectForExtendedBounds = rectForExtendedBounds.insetBy(dx: -0.5 * self.lineWidth, dy: -0.5 * self.lineWidth)
            }
            
            if(additionalRectForExtendedBounds != NSZeroRect)
            {
                rectForExtendedBounds = rectForExtendedBounds.union(additionalRectForExtendedBounds);
            }*/
            
//            if((debugIsOn == true) || (isBeingInspected == true))
//            {
//            self.updateDebugPointLabelsRect()
//                let r = rectForExtendedBounds.insetBy(dx: -5, dy: -5)
//            return r.union(debugRect)
//
//            }
            
//            if(isSelected == true)
//            {
//                return rectForExtendedBounds.insetBy(dx: -10, dy: -10)
//            }
//
//                return rectForExtendedBounds;
            }
        
    }
    
    
       func appendThroughOmitFirstMoveToOfIncomingPath( incomingPath: NSBezierPath)
    {
        if self.elementCount > 0
        {
          
            
            for index in 0..<incomingPath.elementCount {
                
                 let points : NSPointArray = NSPointArray.allocate(capacity: 3)
                
                let pathType = incomingPath.element(at: index, associatedPoints: points)
                
                if (pathType == .lineTo)
                {
                    self.line(to: points[0]);
                }
                else if (pathType == .moveTo)
                {
               //     self.line(to: points[0]);
                }
                else if (pathType == .curveTo)
                {
                    self.curve(to: points[2], controlPoint1: points[0], controlPoint2: points[1])
                }
                
                 //   case .closePath:
                
                points.deallocate()
                
            }// end for
            
            
        }
        
    }
    
     
    func removeElement(at indx: Int) -> NSBezierPath
    {

	if ((indx < 0) || (indx >= self.elementCount))
 {
		return self;
  }
//    var i : Int = 0;
    var m : Int = 0;

    var firstPoint : NSPoint = NSPoint.zero;
    var originalFirstPoint : NSPoint = NSPoint.zero;
    
    var ap : [NSPoint] = Array.init(repeating: NSPoint.zero, count: 3)

        let newPath : NSBezierPath = NSBezierPath();

    var element : NSBezierPath.ElementType
    
    var hasDeleted : Bool = false;


	m = self.elementCount

    for i in 0..<m
    {
    
        element = self.element(at: i, associatedPoints: &ap)
    
		if (i == indx)
        {
            // this is the one to delete, so start a new subpath at its end point
            
            if (element == NSBezierPath.ElementType.curveTo)
            {
                firstPoint = ap[2];
            }
            else if (element == NSBezierPath.ElementType.closePath)
            {
                // no-op
            }
            else
            {
                firstPoint = ap[0];
                
                newPath.move(to: firstPoint)
                
                hasDeleted = true;
            }
        }
        else
        {
			switch (element)
            {
            
			case NSBezierPath.ElementType.moveTo:
                newPath.move(to: ap[0])
				firstPoint = ap[0]
            originalFirstPoint = ap[0]
    
				break;

			case NSBezierPath.ElementType.lineTo:
                newPath.line(to:ap[0]);
				break;

			case NSBezierPath.ElementType.curveTo:
                    newPath.curve(to: ap[2], controlPoint1: ap[0], controlPoint2: ap[1])
                
				break;

			case NSBezierPath.ElementType.closePath:
				// because a segment might have been deleted, so changing the point for closing a path, a line to the original first point must be
				// set instead.

				if (hasDeleted)
					{newPath.line(to: originalFirstPoint)}
				else
					{newPath.close()}
				break;

			default:
				break;
			} // END switch (element)
                

		}// END if (i == indx)

    }// END for


    return newPath

    }
    
    
     func splineFromSegments(_ segmentPoints : [CGPoint]) -> NSBezierPath
    {
        let selfAsCGPath : CGPath = self.cgPath
        var points : [CGPoint] = segmentPoints.isEmpty ? selfAsCGPath.getPointsForLineSegments() : segmentPoints

        /*
        let linearShapeNode = SKShapeNode(points: &points,
        count: points.count)
        */
        
        let splineShapeNode = SKShapeNode(splinePoints: &points,
        count: points.count)
        
        
        let p = NSBezierPath.jns_bezierPath(with: splineShapeNode.path!) // NSBezierPath.init(cgPath: splineShapeNode.path!)

       // removing first extraneous point:
        let p2 = p.removeElement(at: 0)
        
        return p2
//        return p2

        
    }
    
    func pointsForConvexHull() -> [[Double]]
    {
        
        //            var pointsInArrayToReturn : [[Double]] = [];
        
        var pointsInArrayToReturn : [[Double]] = [];
        
        
        if(true)
        {
            
            let pathFlattened = self.flattened
            
            
            
            for bezierElementIndex in 0..<pathFlattened.elementCount
            {
                var pArray : [NSPoint] = Array.init(repeating: .zero, count: 3)
                
                _ = pathFlattened.element(at: bezierElementIndex, associatedPoints: &pArray);
                
                let point = pArray[0];
                
                
                
                pointsInArrayToReturn.append([point.x.double(),point.y.double()])
                
            }// END for
        }
        
        return pointsInArrayToReturn;
        
    }
    
    func buildupModePoints() -> [CGPoint]
    {
        
        //            var pointsInArrayToReturn : [[Double]] = [];
        
        var pointsInArrayToReturn : [CGPoint] = [];
        
        
        if(true)
        {
            
            let pathFlattened = self.flattened
            
            for bezierElementIndex in 0..<pathFlattened.elementCount
            {
                var pArray : [NSPoint] = Array.init(repeating: .zero, count: 3)
                
                _ = pathFlattened.element(at: bezierElementIndex, associatedPoints: &pArray);
                
                let point = pArray[0];
                
                pointsInArrayToReturn.append(point)
                
            }// END for
        }
        
        return pointsInArrayToReturn;
        
    }
    
       // NCTVS
    func cleanUpLineSegmentStrokePath()
    {

            let copyBeforeCleanUp = NSBezierPath()
            
        
            copyBeforeCleanUp.append(self)
            
            // debug
            //var bezPathForShowing = NSBezierPath()
            //bezPathForShowing.lineWidth = 1.0
            
            // go through each line segment.  check segment up one, and
            // segment down one, from current segment, to see if those two segments
            // intersect
            
            var lineArray : [Line] = []
            
            var pArray : [NSPoint] = []
            let points = UnsafeMutablePointer<NSPoint>.allocate(capacity: 3)
            
            let firstSubpathCalculated = self.subPathsNCT()[0]
            
            for i in 0 ..< firstSubpathCalculated.elementCount
            {
                let elementType = self.element(at: i, associatedPoints: points)
                
                if(elementType == NSBezierPath.ElementType.curveTo)
                {
                    pArray.append(points[2])
                }
                else
                {
                    pArray.append(points[0])
                }
            }
            
            points.deallocate();
            
            for index in 0 ..< pArray.count - 1
            {
                lineArray.append(Line(point1: pArray[index], point2: pArray[index + 1]))
                //print("point \(index): \(pArray[index]), point2: \(index + 1) \(pArray[index + 1])")
            }
            
           // var whatNeedsToChange : [] = Dictionary
            
            for lineIndex in stride(from: 1, to:  lineArray.count - 1, by: 1)
            {
            
                // lineIndex is where we are, but we check the neighbor lines
                let intersectionPoint =
                NSPoint.Intersection2(p1: lineArray[lineIndex - 1].point1, p2: lineArray[lineIndex - 1].point2, p3: lineArray[lineIndex + 1].point1, p4: lineArray[lineIndex + 1].point2)
                if( intersectionPoint != nil)
                {
                    
                    /*
                     // --- DEBUG ---
                    if(bezPathForShowing.isEmpty)
                    {
                    bezPathForShowing.move(to:lineArray[lineIndex - 1].point1)
                    }
                    else
                    {
                    bezPathForShowing.line(to:lineArray[lineIndex - 1].point1)
                    }
                    
                    bezPathForShowing.line(to:lineArray[lineIndex - 1].point2)
                    bezPathForShowing.line(to:lineArray[lineIndex + 1].point1)
                    bezPathForShowing.line(to:lineArray[lineIndex + 1].point1)
                    // --- END DEBUG ---
                     */
                    
                    //   print(p)
            
                     let arrayForNewPoint : NSPointArray = NSPointArray.allocate(capacity: 1)
                      arrayForNewPoint[0] = intersectionPoint!;
                    
                    // change position of second point
                       self.setAssociatedPoints(arrayForNewPoint, at: (lineIndex)) // lineArray[lineIndex - 1].point2
                       self.setAssociatedPoints(arrayForNewPoint, at: (lineIndex + 1)) // lineArray[lineIndex + 1].point1
                    
                    // ---- DEBUG
                    //  bezPathForShowing.appendArc(withCenter: intersectionPoint, radius: 30, startAngle: 0, endAngle: 360)
                    //  bezPathForShowing.appendArc(withCenter: lineArray[lineIndex - 1].point2, radius: 10, startAngle: 0, endAngle: 360)
                    //  bezPathForShowing.appendArc(withCenter: lineArray[lineIndex + 1].point1, radius: 10, startAngle: 0, endAngle: 360)
                    // ---- END DEBUG
                    
                    arrayForNewPoint.deallocate();
                }
                  // ---- DEBUG
                  // self.close()
                  // self.append(bezPathForShowing)
                  // ---- END DEBUG
            }
       
            let firstSubpathCalculatedAfterModification = self.subPathsNCT()[0];
            
            
            if(self.hasClose)
            {
                let subElementCountCalcAfterMod = firstSubpathCalculatedAfterModification.elementCount;
                // the last connection
                // between first and last
                let intersectionPoint =
                NSPoint.Intersection2(p1: firstSubpathCalculatedAfterModification.pointAtIndex(subElementCountCalcAfterMod - 5), p2: firstSubpathCalculatedAfterModification.pointAtIndex(subElementCountCalcAfterMod - 4), p3: firstSubpathCalculatedAfterModification.pointAtIndex(0), p4: firstSubpathCalculatedAfterModification.pointAtIndex(1))
               
                
                if( intersectionPoint != nil)
                {
                    let arrayForNewPoint : NSPointArray = NSPointArray.allocate(capacity: 1)
                    arrayForNewPoint[0] = intersectionPoint!
                    
                    // index 0 move to intersectionPoint
                    self.setAssociatedPoints(arrayForNewPoint, at: 0)
                    // (elementCnt - 3) at same point as index 0
                    self.setAssociatedPoints(arrayForNewPoint, at: (subElementCountCalcAfterMod - 3))
                    // (elementCnt - 2) at same point as index 0
                    self.setAssociatedPoints(arrayForNewPoint, at: (subElementCountCalcAfterMod - 2))
                   
                    self.setAssociatedPoints(arrayForNewPoint, at: (subElementCountCalcAfterMod - 4))
                    
                    arrayForNewPoint.deallocate();
                 
                   
                }

     
                
               // self.appendArc(withCenter: firstSubpathCalculated.pointAtIndex(elementCnt - 2), radius: 30, startAngle: 0, endAngle: 360)
                
                
            }
            
           // self.append(copyBeforeCleanUp)
        
      
        
    }
    
    
    // TRANSLATE
    func nctTranslateBy(vector:CGVector)
    {
        var xfm = AffineTransform.init()
        xfm.translate(x: vector.dx, y: vector.dy)
        self.transform(using: xfm);
    
    }
    
    
    // MARK: MAKE IMAGE USING CLOSURE
    func image(sizeForRescale: NSSize, boundsPadding:CGFloat, untranslatedDrawingBounds:NSRect, drawingCode:() -> Void, flippedImage:Bool) -> NSImage
    {
       
        let nsImage : NSImage = NSImage(size: untranslatedDrawingBounds.size.multiplied(factor: 1) )
        //nsImage.usesEPSOnResolutionMismatch = true
        
        nsImage.lockFocusFlipped(flippedImage)
        //nsImage.lockFocus()

            let context :CGContext! = NSGraphicsContext.current!.cgContext
        
            context.saveGState()  // Push the current context settings
            
                NSGraphicsContext.current?.imageInterpolation = NSImageInterpolation.high;
                context.translateBy(x: (-1 * untranslatedDrawingBounds.origin.x), y: (-1 * untranslatedDrawingBounds.origin.y) )
        
                      
                drawingCode();
  
            context.restoreGState()  // Push the current context settings
        
        nsImage.unlockFocus()





        /*
        // NSImage is stored
        // so that downscaling
        // will not diminish original resolution.
        // Could be replaced by second CIImage called originalCIImage.
       
        if let ciImageForScaling = CIImage(data: nsImage.tiffRepresentation!)
        {
            let rescaleBasedOnWidth : Bool = sizeForRescale.width > sizeForRescale.height;
            
            let scale = rescaleBasedOnWidth ? (extendedBezierPathBoundsComputed.width / sizeForRescale.width) : (extendedBezierPathBoundsComputed.height / sizeForRescale.height)
            
            
            let lanczosScaleTransform = CIFilter(name: "CILanczosScaleTransform")!
            lanczosScaleTransform.setValue(ciImageForScaling, forKey: "inputImage")
            lanczosScaleTransform.setValue(scale, forKey: "inputScale")
            lanczosScaleTransform.setValue(1.0, forKey: "inputAspectRatio")
            
            if let ciImage = lanczosScaleTransform.value(forKey: "outputImage") as? CIImage
            {
            
                let cIImageRepresentation : NSBitmapImageRep = NSBitmapImageRep(ciImage: ciImage);
                let rescaledNSImageForReturn = NSImage(size: cIImageRepresentation.size);
                rescaledNSImageForReturn.addRepresentation(cIImageRepresentation);
                
                return rescaledNSImageForReturn;
            }
        }
        */
        
        return nsImage;
        
    }
    
    // MARK: CGPATH
    
    

    /*
    
    public convenience init(path: CGPath) {
        
        self.init()
        
        
        
        let pathPtr = UnsafeMutablePointer<NSBezierPath>.allocate(capacity: 1)
        
        pathPtr.initialize(to: self)
        
        
        
        let infoPtr = UnsafeMutableRawPointer(pathPtr)
        
        
        path.apply(info: infoPtr) { (infoPtr, elementPtr) -> Void in
            
            let path = UnsafeMutablePointer<NSBezierPath>(infoPtr).memory
            
            let element = elementPtr.memory
            
            
            
            let pointsPtr = element.points
            
            
            
            switch element.type {
            
            case .MoveToPoint:
                
                path.moveToPoint(pointsPtr.memory)
                
                
                
            case .AddLineToPoint:
                
                path.lineToPoint(pointsPtr.memory)
                
                
                
            case .AddQuadCurveToPoint:
                
                let firstPoint = pointsPtr.memory
                
                let secondPoint = pointsPtr.successor().memory
                
                
                
                let currentPoint = path.currentPoint
                
                let x = (currentPoint.x + 2 * firstPoint.x) / 3
                
                let y = (currentPoint.y + 2 * firstPoint.y) / 3
                
                let interpolatedPoint = CGPoint(x: x, y: y)
                
                
                
                let endPoint = secondPoint
                
                
                
                path.curveToPoint(endPoint, controlPoint1: interpolatedPoint, controlPoint2: interpolatedPoint)
                
                
                
            case .AddCurveToPoint:
                
                let firstPoint = pointsPtr.memory
                
                let secondPoint = pointsPtr.successor().memory
                
                let thirdPoint = pointsPtr.successor().successor().memory
                
                
                
                path.curveToPoint(thirdPoint, controlPoint1: firstPoint, controlPoint2: secondPoint)
                
                
                
            case .CloseSubpath:
                
                path.closePath()
                
            }
            
            
            
            pointsPtr.destroy()
            
        }
        
    }

    */


    



    
     public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
            @unknown default:
                fatalError()
            }
        }
        return path
    }
    
    func addQuadCurve(to endPoint: CGPoint, controlPoint: CGPoint){
        let startPoint = self.currentPoint
        let controlPoint1 = CGPoint(x: (startPoint.x + (controlPoint.x - startPoint.x) * 2.0/3.0), y: (startPoint.y + (controlPoint.y - startPoint.y) * 2.0/3.0))
        let controlPoint2 = CGPoint(x: (endPoint.x + (controlPoint.x - endPoint.x) * 2.0/3.0), y: (endPoint.y + (controlPoint.y - endPoint.y) * 2.0/3.0))
        curve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }



    
  
    func relativeLineToByAngle(angle:CGFloat, length:CGFloat)
    {
        var p = CGPoint()
        p.x = CGFloat(length * cos(deg2rad(angle)))
        p.y = CGFloat(length * sin(deg2rad(angle)))
        self.relativeLine(to: p)
        
        
    }
    
    func relativeMoveToByAngle(angle:CGFloat, length:CGFloat)
    {
        var p = CGPoint()
        p.x = CGFloat(length * cos(deg2rad(angle)))
        p.y = CGFloat(length * sin(deg2rad(angle)))
        self.relativeMove(to: p)
        
    }
    
    class func angleDegreesFromThreePoints(p0 : NSPoint, centerPoint : NSPoint, p2 : NSPoint) -> CGFloat // Center point is p1;
    {
        let a = pow(centerPoint.x-p0.x,2) + pow(centerPoint.y-p0.y,2);
        let b = pow(centerPoint.x-p2.x,2) + pow(centerPoint.y-p2.y,2);
        let c = pow(p2.x-p0.x,2) + pow(p2.y-p0.y,2);
        
        return acos( (a+b-c) / sqrt(4*a*b) )  * (180 / 3.14159265);
        
    }
    
    class func angleRadiansFromThreePoints(p0 : NSPoint, centerPoint : NSPoint, p2 : NSPoint) -> CGFloat // Center point is p1;
    {
        let a = pow(centerPoint.x-p0.x,2) + pow(centerPoint.y-p0.y,2);
        let b = pow(centerPoint.x-p2.x,2) + pow(centerPoint.y-p2.y,2);
        let c = pow(p2.x-p0.x,2) + pow(p2.y-p0.y,2);
        
        return acos( (a+b-c) / sqrt(4*a*b) );
        
    }
    
    public var hasCurveTo : Bool
    {
        
        
        for bezierElementIndex in 0..<self.elementCount
        {
            let pArray : NSPointArray = NSPointArray.allocate(capacity: 3);
            let element = self.element(at: bezierElementIndex, associatedPoints: pArray);
            
            if(element == .curveTo)
            {
                
                return true;
            }
            
            pArray.deallocate();
            
        }
        
        return false;
        
        
    }
    
    public var hasClose : Bool
    {
        
        
        for bezierElementIndex in 0..<self.elementCount
        {
            let pArray : NSPointArray = NSPointArray.allocate(capacity: 3);
            let element = self.element(at: bezierElementIndex, associatedPoints: pArray);
            
            if(element == .closePath)
            {
                
                return true;
            }
            
            pArray.deallocate();
            
        }
        
        return false;
        
        
    }
    
    /*
    func roughEstimateOfLengthUsingFlattened() -> CGFloat
    {
        let selfFlattened = self.flattened;
    
        for bezierElementIndex in 0..<selfFlattened.elementCount
        {
            let pArray : NSPointArray = NSPointArray.allocate(capacity: 3);
            let element = self.element(at: bezierElementIndex, associatedPoints: pArray);
            
            if(element == .curveTo)
            {
            }
            
        }
    
    }*/
    
    // MARK: NOISE
    
    func applyNoiseToPath(gkNoiseSource: GKPerlinNoiseSource?, amplitude: CGFloat, useAbsoluteValues:Bool, makeFragmentedLineSegments:(Bool,CGFloat))
    {

        guard gkNoiseSource != nil else {
            return
        }
         
            var p : NSBezierPath = NSBezierPath();
            
            if(self.hasCurveTo)
            {
                p = self.flattened
            }
            else
            {
                p.append(self)
            }
         
            let pathLengthMultiplier : CGFloat = p.pathLengthForLineTo() //self.length
            
            let gkNoiseToUse = GKNoise.init(GKPerlinNoiseSource.init(frequency: ( (gkNoiseSource!.frequency / 100.0) * 0.5 * Double(pathLengthMultiplier)) , octaveCount: gkNoiseSource!.octaveCount, persistence: gkNoiseSource!.persistence, lacunarity: gkNoiseSource!.lacunarity, seed: gkNoiseSource!.seed) )
                
                if(makeFragmentedLineSegments.0)
                {
                    p = p.withFragmentedLineSegments(makeFragmentedLineSegments.1);
                }
                    
                              

            
    

            let p2 = NSBezierPath();
            
            let pElementCount = p.elementCount;
            for e in 0..<pElementCount
            {
        
                let pathPosition = ( CGFloat(e) / CGFloat(pElementCount));
                
                
                let positionMappedForNoise = (2 * pathPosition ) - 1;
                
                var pArray :[NSPoint] = Array(repeating: NSPoint.zero, count: 3)
                let elementType : NSBezierPath.ElementType = p.element(at: e, associatedPoints: &pArray)
                
                //let value =  CGFloat( gkNoiseMap.interpolatedValue(at: simd_float2(repeating: Float(position) )) );
                var value = CGFloat( gkNoiseToUse.value(atPosition: simd_float2(repeating: Float(positionMappedForNoise)) ) );
                
                if(useAbsoluteValues)
                {
                    value = abs(value)
                }
                
                let normalValue = p.getNormalForPosition(pathPosition);
                
                
                let x = pArray[0].x + (cos(deg2rad(normalValue)) * (amplitude) * value)
                let y = pArray[0].y + (sin(deg2rad(normalValue)) * (amplitude) * value)
                   
                let noisedPoint =  NSMakePoint(x,y )
                
                /*
                if( (e - 1) > -1)
                {
                    let normalValueNext = p.getNormalForPosition(pathPositionPrev);
                    if(abs(normalValue - normalValueNext) > 90)
                    {
                    
                    skipNext = true;
                    p2.appendArc(withCenter: noisedPoint, radius: 2, startAngle: 0, endAngle: 360)
                        //continue;
                        //normalValue = 1;
                    }
                
                }*/
                
                
                if(elementType == .moveTo)
                {
                     p2.move(to: noisedPoint)
                }
                else if(elementType == .lineTo)
                {
                    p2.line( to: noisedPoint )
                
                }
                
               // p.setAssociatedPoints(&pArray, at: e)
                
            }
            
            
            
    
        self.removeAllPoints();
        self.append(p2)


    }
    
    
 // MARK: pathLengthForLineTo
    func pathLengthForLineTo() -> CGFloat
   {
    
    let elements = self.elementCount;
	var length : CGFloat = 0.0;
	var pointForClose : NSPoint = NSMakePoint(0.0, 0.0);
    var lastPoint : NSPoint = NSMakePoint(0.0, 0.0);
    
    var pointArray : [NSPoint] = Array.init(repeating: NSPoint.zero, count: 3)
    
    for i in 0..<elements
    {
        
        let elementType = self.element(at: i, associatedPoints: &pointArray)
        
        switch elementType
        {
        
        case .moveTo:
            lastPoint = pointArray[0];
            pointForClose = lastPoint;

        case .lineTo:
 
        	length += NSPoint.distanceBetween(lastPoint, pointArray[0]);
			lastPoint = pointArray[0];
            
        case .curveTo:
            length += NSPoint.distanceBetween(lastPoint, pointArray[2]);

            //NSPoint bezier[4] = { lastPoint, points[0], points[1], points[2] };
			//length += lengthOfBezier(bezier, maxError);
			//lastPoint = points[2];
                
        case .closePath:
            length += NSPoint.distanceBetween(lastPoint, pointForClose);
			lastPoint = pointForClose;
        @unknown default:
            print("unknown NSBezierPath element");
        }
        
        
    
    }
//    print(length)
    return length;
  
  }
  
    /*
    - (CGFloat)lengthWithMaximumError:(CGFloat)maxError
{
	NSInteger elements = [self elementCount];
	NSInteger n;
	CGFloat length = 0.0;
	NSPoint pointForClose = NSMakePoint(0.0, 0.0);
	NSPoint lastPoint = NSMakePoint(0.0, 0.0);

	for (n = 0; n < elements; ++n) {
		NSPoint points[3];
		NSBezierPathElement element = [self elementAtIndex:n
										  associatedPoints:points];

		switch (element) {
		case NSBezierPathElementMoveTo:
			pointForClose = lastPoint = points[0];
			break;

		case NSBezierPathElementLineTo:
			length += distanceBetween(lastPoint, points[0]);
			lastPoint = points[0];
			break;

		case NSBezierPathElementCurveTo: {
			NSPoint bezier[4] = { lastPoint, points[0], points[1], points[2] };
			length += lengthOfBezier(bezier, maxError);
			lastPoint = points[2];
			break;
		}

		case NSBezierPathElementClosePath:
			length += distanceBetween(lastPoint, pointForClose);
			lastPoint = pointForClose;
			break;

		default:
			break;
		}
	}

	return length;
}
   
   */
    
    
    // MARK: CLASS MAKE BEZIER PATH SHAPES
    class func rectBezierPathFromRect(rect: NSRect) -> NSBezierPath
    {
        let p = NSBezierPath();
        p.appendRect(rect)
        return p
    }
    
      class func ovalBezierPathFromRect(rect: NSRect) -> NSBezierPath
    {
        let p = NSBezierPath();
        p.appendOval(in: rect)
        return p
    }
   
 
   
    // MARK: SVG XML ELEMENT
   
    func bezierPathSVGXMLElement() -> XMLElement
    {
        let pathSVGElement = XMLElement.init(name: "path")
            
        if(self.elementCount > 1)
        {
            var svgPathElementPointsString = ""
            for bezierElementIndex in 0..<self.elementCount
            {
                var pointsArray : [NSPoint] = Array.init(repeating: .zero, count: 3)
                let elementType = self.element(at: bezierElementIndex, associatedPoints: &pointsArray);
                
                switch (elementType)
                {
                case .moveTo:
                svgPathElementPointsString.append("M \(pointsArray[0].x),\(pointsArray[0].y) \n")
                
                case .lineTo:
                svgPathElementPointsString.append("L \(pointsArray[0].x),\(pointsArray[0].y) \n")
                case .curveTo:
                svgPathElementPointsString.append(
                "C\(pointsArray[0].x) \(pointsArray[0].y) \(pointsArray[1].x) \(pointsArray[1].y) \(pointsArray[2].x) \(pointsArray[2].y)")
                
                case .closePath:
                svgPathElementPointsString.append("Z\n")
                    
                default: break
                }
                
            }
            
            pathSVGElement.setAttributesAs(["stroke" : "blue","d":svgPathElementPointsString,
            "fill":"none", "stroke-width" : "\(self.lineWidth)"])

            var c : Int = 0;
            self.getLineDash(nil, count: &c, phase: nil)
            if(c > 0)
            {
                let lD = self.lineDash()
                
                pathSVGElement.addAttribute(XMLNode.attribute(withName: "stroke-dasharray", stringValue: lD.patternSVGStringRepresentation() ) as! XMLNode)
            }
            //stroke-dasharray="40,10"
            
            if(self.countSubPathsNCT() > 0)
            {
                pathSVGElement.addAttribute(XMLNode.attribute(withName: "fill-rule", stringValue: "evenodd" ) as! XMLNode)
            }
            
            if(self.lineCapStyle != .butt)
            {
            
            //  ----- "stroke-linecap" default is butt
                pathSVGElement.addAttribute(XMLNode.attribute(withName: "stroke-linecap", stringValue: (self.lineCapStyle == .round) ? "round" : "square") as! XMLNode)
            }
            
            if(self.lineJoinStyle != .miter)
            {
            // ----- "stroke-linejoin" default is miter
                pathSVGElement.addAttribute(XMLNode.attribute(withName: "stroke-linejoin", stringValue: (self.lineJoinStyle == .bevel) ? "bevel" : "round") as! XMLNode)
            }
            
            if(self.lineJoinStyle == .miter)
            {
            // ----- "stroke-linejoin" default is miter
                pathSVGElement.addAttribute(XMLNode.attribute(withName: "stroke-miterlimit", stringValue: "\(self.miterLimit)") as! XMLNode)
            }
            
            

        }
    
    
        
    
        return pathSVGElement;
    }
  


    // MARK: SUBPATHS


    func countSubPathsNCT() -> Int
    {
        let elementCountOfSelf = self.elementCount;
        
        guard (elementCountOfSelf > 0)
        else {
            return 0;
        }
    
        var m : Int = 0
        var spc : Int = 0
        
        m = elementCountOfSelf - 1;
        
        for i in 0..<m {
            
            if(self.element(at: i) == .moveTo)
            {
                spc += 1;
            }
        }
        
        return spc;
        
    }
    
    func subPathsNCT() -> [NSBezierPath]
    {
        // returns an array of bezier paths, each derived from this path's subpaths.
        // first see if we can take a shortcut - if there's only one subpath, just return self in the array
        
        if(self.countSubPathsNCT() < 2)
        {
            return [self]
        }
        
        // more than 1 subpath, break it down:
        
        var subPathsToReturn : [NSBezierPath] = [];
        
        var temp : NSBezierPath!
        var added : Bool = false;
        
        let numElements = self.elementCount
        
        var points : [NSPoint] = Array.init(repeating: NSPoint.zero, count: 3)
    
        for i in 0..<numElements
        {
            
            let elementType = self.element(at: i, associatedPoints: &points)
            
            
            switch elementType {
            case .moveTo:
                temp = NSBezierPath()
                temp.move(to: points[0])
                added = false;
            case .lineTo:
                temp.line(to: points[0])
                
            case .curveTo:
                
                temp.curve(to: points[2], controlPoint1: points[0], controlPoint2: points[1])
            case .closePath:
                temp.close()
            default:
                break;
                
            }
        
            // object is added only if it has more than just the moveTo element
            if (!added && temp.elementCount > 1)
            {
                subPathsToReturn.append(temp)
                added = true;
            }
            
       
          
        }
        
        return subPathsToReturn;
    }
  
    // MARK: DEBUG DISPLAY FOR BEZIER PATH
   func drawAllBezierPoints()
   {
    
    var ap : [NSPoint] = Array.init(repeating: NSPoint.zero, count: 3)
    
    var m : Int = 0;
    
    
    
    m = self.elementCount
    
    for i in 0..<m
    {
        
        let elementType = self.element(at: i, associatedPoints: &ap)
        
        
        var pointRect : NSRect = NSMakeRect(0, 0, 3,3)
        
        
        pointRect = pointRect.centerOnPoint(elementType == NSBezierPath.ElementType.curveTo ? ap[2] : ap[0])
        
        switch elementType {
        case .curveTo:
            NSColor.purple.setFill();
        case .moveTo:
            NSColor.green.setFill();
        case .closePath:
            NSColor.red.setFill();
        case .lineTo:
            NSColor.orange.setFill();
        default:
            NSColor.blue.setFill();
        }
        
        pointRect.fill()
        
        
        
        
    }
  
  }
    
  
    func displayAllBezierPathPoints()
    {
        for bezierElementIndex in 0..<self.elementCount
        {
            var pointsArray : [NSPoint] = Array.init(repeating: .zero, count: 3)
            let elementType = self.element(at: bezierElementIndex, associatedPoints: &pointsArray);
            
            var colorForText = NSColor.white
            switch (elementType)
            {
            case .moveTo:
                pointsArray[0].fillSquare3x3AtPoint(color: NSColor.green)
                colorForText = .green
            case .lineTo:
                pointsArray[0].fillSquare3x3AtPoint(color: NSColor.blue)
                colorForText = .blue
            case .curveTo:
                
                NSColor.orange.setStroke();
                NSBezierPath.strokeLine(from: pointsArray[0], to: pointsArray[2])
                NSBezierPath.strokeLine(from: pointsArray[1], to: pointsArray[2])
                pointsArray[0].fillSquare3x3AtPoint(color: NSColor.purple)
                pointsArray[1].fillSquare3x3AtPoint(color: NSColor.purple)
                pointsArray[2].fillSquare3x3AtPoint(color: NSColor.orange)
                colorForText = .orange
                
            case .closePath:
                pointsArray[0].fillSquare3x3AtPoint(color: NSColor.red)
                
            default: break
            }
            
            
            
            bezierElementIndex.drawAtPoint(pointsArray[0], color: colorForText.withAlphaComponent(0.5), fontSize: 14)

        }// END for
    
            
    }


    func pathExcludingPointsFromInsideFillPath(path:NSBezierPath, attemptOmitDuplicates:Bool) -> NSBezierPath
    {
        let pathToReturn : NSBezierPath = NSBezierPath.init();
        
        for bezierElementIndex in 0..<self.elementCount
        {
            var pointsArray : [NSPoint] = Array.init(repeating: .zero, count: 3)
            let elementType = self.element(at: bezierElementIndex, associatedPoints: &pointsArray);
            
           
            
            switch (elementType)
            {
            case .moveTo:
                if(path.contains(pointsArray[0]))
                {
                    continue;
                }
                else
                {
                
                    pathToReturn.move(to: pointsArray[0])
                }
            case .lineTo:
                

                
                if(path.contains(pointsArray[0]))
                {
                    continue;
                }
                else
                {
                    if(pathToReturn.isEmpty == false)
                    {
                        if(attemptOmitDuplicates)
                        {
                            if(pathToReturn.isStrokeHit(by: pointsArray[0], padding: 2))
                            {
                                continue
                            }
                        }
     
                        pathToReturn.line(to: pointsArray[0])
                    }
                    else
                    {
                       pathToReturn.move(to: pointsArray[0])
                    }

                }
            case .curveTo:
                
                if(path.contains(pointsArray[2]))
                {
                    continue;
                }
                else
                {
                    if(pathToReturn.isEmpty == false)
                    {
                        pathToReturn.curve(to: pointsArray[2], controlPoint1: pointsArray[0], controlPoint2: pointsArray[1])
                    }
                    else
                    {
                        pathToReturn.move(to: pointsArray[2])

                    }
                }
                
            case .closePath:
                if(path.contains(pointsArray[0]))
                {
                    continue;
                }
                else
                {
                    if(pathToReturn.isEmpty == false)
                    {
                        pathToReturn.close()
                    }
                    else
                    {
                        path.move(to: pointsArray[0])
                    }
                }
                
            default: break
            }
            
        }// END for
        
        return pathToReturn
    }
    
    
    func reversePath()
    {
        let bezierReversed = self.reversed;
        self.removeAllPoints();
        self.append(bezierReversed);
        
    }
    

    
    
} // END NSBezierPath



extension NSColor
{

     
        
    // random color;
    static var pastelRandom: NSColor {
        
       return NSColor.init(calibratedHue: 1.0 - CGFloat.random(in: 0.6...1.0), saturation: 1.0 - CGFloat.random(in: 0.3...0.8), brightness: 1.0, alpha: 1.0)
        

    }
    
    static var random: NSColor {
        return NSColor(red: CGFloat.random(in: 0...1.0),
                       green: CGFloat.random(in: 0...1.0),
                       blue: CGFloat.random(in: 0...1.0),
                      alpha: 1.0)
        
        }
}


extension Bool {
    init(_ integer: Int) {
        if integer > 0 {
            self.init(true)
        } else {
            self.init(false)
        }
    }
    
    var intValue : Int {
     
        get
        
        {
          return self ? 1 : 0
        }
        
    }
    
    var stateValue : NSControl.StateValue
    {
    
        get
        {
            return NSControl.StateValue.init(self.intValue);
        
        }
    
    }
    
    var onOffSwitchInt : Int
    {
        get
        {
            return self ? 0 : 1
        }
        
    }
    
}


extension NSColor
{

    class func initWithSvgSRGBAttributeStringArray(rgbColorString: String) -> NSColor?
    {
        
        var rgbStringValuesArray : [String] = [];
        if var p = rgbColorString.firstIndex(of: "(")
        {
            rgbColorString.formIndex(after: &p)
            
            if let p2 = rgbColorString.firstIndex(of: ")")
            {
                rgbStringValuesArray = rgbColorString[p..<p2].components(separatedBy: ",")
            }
        }
        
        var r : CGFloat = 0,  g : CGFloat = 0,  b : CGFloat = 0,  a : CGFloat = 1.0;
        
        if(rgbStringValuesArray.count >= 3)
        {
            r = CGFloat(Double(rgbStringValuesArray[0]) ?? 0) / 255.0
            g = CGFloat(Double(rgbStringValuesArray[1]) ?? 0) / 255.0
            b = CGFloat(Double(rgbStringValuesArray[2]) ?? 0) / 255.0
            
            if(rgbStringValuesArray.count == 4)
            {
                a = CGFloat(Double(rgbStringValuesArray[3]) ?? 1.0)
            }
            return NSColor.init(srgbRed: r, green: g, blue: b, alpha: a)
        }
        
      
        return nil;
    
    }

    func xmlRGBAttributeStringContent() -> String
    {
        // another option: NSColorSpace.genericGray
        if(self.colorSpace == NSColorSpace.sRGB)
        {
        
            if(self.alphaComponent != 1.0)
            {
                
                return "rgba(\(self.redComponent * 255.0),\(self.greenComponent * 255.0),\(self.blueComponent * 255.0),\(self.alphaComponent))"
            }
            else
            {
                return "rgb(\(self.redComponent * 255.0),\(self.greenComponent * 255.0),\(self.blueComponent * 255.0))"
                
            }
            
        }
        else
        {
            if let rgbVersion = self.usingColorSpace(NSColorSpace.sRGB)
            {
                
                if(self.alphaComponent != 1.0)
                {
                    
                    return "rgba(\(rgbVersion.redComponent * 255.0),\(rgbVersion.greenComponent * 255.0),\(rgbVersion.blueComponent * 255.0),\(rgbVersion.alphaComponent))"
                }
                else
                {
                    return "rgb(\(rgbVersion.redComponent * 255.0),\(rgbVersion.greenComponent * 255.0),\(rgbVersion.blueComponent * 255.0))"
                    
                }
            }
        }
        return "rgb(0,0,0)"
    }
    
    
    var grayscaleVersionInvertedNoAlpha : NSColor{
        get
        {
            // another option: NSColorSpace.genericGray
            if let rgbVersion = self.usingColorSpace(NSColorSpace.sRGB)
            {
                var red : CGFloat  = 0;
                var blue: CGFloat  = 0;
                var green: CGFloat  = 0;
                var alpha: CGFloat  = 0;
                
                rgbVersion.getRed(&red, green: &green, blue: &blue, alpha: &alpha);
                
                
                return NSColor(white: 1.0 - (0.299 * red + 0.587 * green + 0.114 * blue), alpha: 1.0);
                
            }
            
            else
            {
                return self;
            }
            
        }
        
    }// END var
    
    var grayscaleVersion : NSColor{
        get
        {
        
          
        
            // another option: NSColorSpace.genericGray
            if let rgbVersion = self.usingColorSpace(NSColorSpace.sRGB)
            {
                if(self.colorSpace == NSColorSpace.genericGray)
                {
                    return rgbVersion;
                }
                
                if((rgbVersion.hueComponent == 0) && (rgbVersion.saturationComponent == 0))
                {
                    return rgbVersion;
                }
            
                var red : CGFloat  = 0;
                var blue: CGFloat  = 0;
                var green: CGFloat  = 0;
                var alpha: CGFloat  = 0;
                
                rgbVersion.getRed(&red, green: &green, blue: &blue, alpha: &alpha);
                
                
                return NSColor(white: (0.299 * red + 0.587 * green + 0.114 * blue), alpha: alpha);
                
            }
            
            else
            {
                return self;
            }
            
        }
        
    }// END var
    
}


extension CGPath {

    func forEach( body: @escaping @convention(block) (CGPathElement) -> Void) {
        typealias Body = @convention(block) (CGPathElement) -> Void
        let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
            let body = unsafeBitCast(info, to: Body.self)
            body(element.pointee)
        }
        //print(MemoryLayout.size(ofValue: body))
        let unsafeBody = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
        self.apply(info: unsafeBody, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
    }
    
 // for lines consisting only of moveTo and lineTo
     func getPointsForLineSegments() -> [CGPoint] {
  
        var arrayPoints : [CGPoint]! = [CGPoint]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                arrayPoints.append(element.points[0])
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
              
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
            
            default: break
            }
        }
        return arrayPoints
        
        
    }
    
}

/*
struct DualSwitch {
    // initialize
    
    // subscripting
    var value
}
*/

/*
// credit: https://stackoverflow.com/questions/12992462/how-to-get-the-cgpoints-of-a-cgpath/36374209#36374209
extension CGPath {
    
    func forEach( body: @escaping @convention(block) (CGPathElement) -> Void) {
        typealias Body = @convention(block) (CGPathElement) -> Void
        let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
            let body = unsafeBitCast(info, to: Body.self)
            body(element.pointee)
        }
        //print(MemoryLayout.size(ofValue: body))
        let unsafeBody = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
        self.apply(info: unsafeBody, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
    }
    
    
    // for lines consisting only of moveTo and lineTo
    func getPointsForLineSegments() -> [CGPoint] {
  
        var arrayPoints : [CGPoint]! = [CGPoint]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                arrayPoints.append(element.points[0])
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
              
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
            
            default: break
            }
        }
        return arrayPoints
        
    }
    
    func getPathElementsPointsForPKit() -> [CGPoint] {
        var arrayPoints : [CGPoint]! = [CGPoint]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
              arrayPoints.append(element.points[0])
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayPoints.append(element.points[2])
            default: break
            }
        }
        return arrayPoints
    }
    
    
    func getPathElementsPoints() -> [CGPoint] {
        var arrayPoints : [CGPoint]! = [CGPoint]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                arrayPoints.append(element.points[0])
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayPoints.append(element.points[2])
            default: break
            }
        }
        return arrayPoints
    }
    
    func getPathElementsPointsAndTypes() -> ([CGPoint],[CGPathElementType]) {
        var arrayPoints : [CGPoint]! = [CGPoint]()
        var arrayTypes : [CGPathElementType]! = [CGPathElementType]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                arrayPoints.append(element.points[0])
                arrayTypes.append(element.type)
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
                arrayTypes.append(element.type)
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayPoints.append(element.points[2])
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
            default: break
            }
        }
        return (arrayPoints,arrayTypes)
    }
    
    
    
    
}
*/


struct NCTRotatedRect {
    var bottomLeft : NSPoint
    var bottomRight : NSPoint
    var topRight : NSPoint
    var topLeft : NSPoint
    var middleRight : NSPoint
    var middleLeft : NSPoint
    var topMiddle : NSPoint
    var bottomMiddle : NSPoint
    var centerPoint : NSPoint
    var angleRadians : CGFloat
    var width: CGFloat
    var height: CGFloat
    
    init(bottomLeft : NSPoint, bottomRight : NSPoint, topRight : NSPoint, topLeft : NSPoint, middleLeft : NSPoint, middleRight : NSPoint, topMiddle:NSPoint, bottomMiddle:NSPoint, centerPoint:NSPoint, angleRadians: CGFloat,width: CGFloat,height:CGFloat)
    {
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.topRight = topRight
        self.topLeft = topLeft
        self.middleLeft = middleLeft
        self.middleRight = middleRight
        self.topMiddle = topMiddle
        self.bottomMiddle = bottomMiddle
        self.centerPoint = centerPoint;
        self.angleRadians = angleRadians;
        self.width = width
        self.height = height
    }
    
    func pointAtAngle(radians:CGFloat) -> NSPoint
    {
      let xRad = self.width / 2
        let yRad = self.height / 2;
        
        let x = centerPoint.x + (xRad * cos(angleRadians ))
        let y = centerPoint.y + (yRad * sin(angleRadians))
        
        return NSMakePoint(x, y)
    
    }
    
    func ellipsePointAtAngle(radians:CGFloat) -> NSPoint
    {
        let xRad = self.width / 2
        let yRad = self.height / 2;
       
        let x1 = centerPoint.x
            +
            ( (xRad * cos(radians))    )
        
        let y1 = centerPoint.y +
            ( (yRad * sin(radians))   )
        
        let p = NSMakePoint(x1, y1)

        let xfm = RotationTransform(angleRadians:  -angleRadians, centerPoint: centerPoint)
        return xfm.transform(p)
    }
    
    /*
        baseRect = NSMakeRect(0,0, pkPoint.size.width,  pkPoint.size.height ).centerOnPoint(interpolatedNSPoint)
                    
                    
 
                    baseRectPath.appendOval(in: baseRect)
                    
                    rotatedBrush.appendPathRotatedAboutCenterPoint(path: baseRectPath, angleDegrees: rad2deg(pkPoint.azimuth), centerPoint: interpolatedNSPoint)
     */

    func perimenterRectanglePoints() -> [NSPoint]
    {
        return [bottomLeft,bottomRight,topRight,topLeft]
    }
    
    func perimenterRectanglePointsForConvexHull() -> [[Double]]
    {
        return [
            [bottomLeft.x.double(),bottomLeft.y.double()],
            [middleLeft.x.double(),middleLeft.y.double()],
                 [topLeft.x.double(),topLeft.y.double()],
                 [topMiddle.x.double(),topMiddle.y.double()],
                    [topRight.x.double(),topRight.y.double()],
                    [middleRight.x.double(),middleRight.y.double()],
                    [bottomRight.x.double(),bottomRight.y.double()],
                    [bottomMiddle.x.double(),bottomMiddle.y.double()],
                    ]
    }
    
    func perimenterDiamondPoints() -> [NSPoint]
    {
        return [middleLeft,bottomMiddle,middleRight,topMiddle]
    }

    func perimeterEllipsePoints(degreeStep:CGFloat) -> [NSPoint]
    {
        var pointsToReturn : [NSPoint] = [];
        
        let xRad = self.width / 2
        let yRad = self.height / 2;
        
        let xfm = RotationTransform(angleRadians:  -angleRadians, centerPoint: centerPoint)

        for i : CGFloat in stride(from: 0, through: 360, by: degreeStep)
        {
            let x =
                centerPoint.x
                +
                ( (xRad * cos(deg2rad(i)))    )
            
            let y = centerPoint.y +
                ( (yRad * sin(deg2rad(i)))   )
            
            
            let p = NSMakePoint(x, y)
            let p2 = xfm.transform(p)
            
            pointsToReturn.append(p2)
            
            
        }
        
        return pointsToReturn
    }
    
    func perimeterEllipsePointsForConvexHull(degreeStep:CGFloat) -> [[Double]]
    {
        var pointsToReturn :  [[Double]] = [];
        
        let xRad = self.width / 2
        let yRad = self.height / 2;
        
        let xfm = RotationTransform(angleRadians:  -angleRadians, centerPoint: centerPoint)

        for i : CGFloat in stride(from: 0, through: 360, by: degreeStep)
        {
            let x =
                centerPoint.x
                +
                ( (xRad * cos(deg2rad(i)))    )
            
            let y = centerPoint.y +
                ( (yRad * sin(deg2rad(i)))   )
            
            
            let p = NSMakePoint(x, y)
            let p2 = xfm.transform(p)
            
            pointsToReturn.append([p2.x.double(),p2.y.double()])
            
            
        }
        
        return pointsToReturn
    }

    func perimeterEllipsePoints(startAngleDegrees:CGFloat,endAngleDegrees:CGFloat,degreeStep:CGFloat, directionForward:Bool) -> [NSPoint]
    {
        var pointsToReturn : [NSPoint] = [];
        
        let xRad = self.width / 2
        let yRad = self.height / 2;
        
        let xfm = RotationTransform(angleRadians:  -angleRadians, centerPoint: centerPoint)

        if(directionForward)
        {
            for i : CGFloat in stride(from: startAngleDegrees, through: endAngleDegrees, by: degreeStep)
            {
                let x =
                    centerPoint.x
                    +
                    ( (xRad * cos(deg2rad(i)))    )
                
                let y = centerPoint.y +
                    ( (yRad * sin(deg2rad(i)))   )
                
                
                let p = NSMakePoint(x, y)
                let p2 = xfm.transform(p)
                
                pointsToReturn.append(p2)
                
                
            }
        }
        else
        {
            for i : CGFloat in stride(from: startAngleDegrees, through: endAngleDegrees, by: degreeStep)
            {
                let x =
                    centerPoint.x
                    +
                    ( (xRad * cos(deg2rad(i)))    )
                
                let y = centerPoint.y +
                    ( (yRad * sin(deg2rad(i)))   )
                
                
                let p = NSMakePoint(x, y)
                let p2 = xfm.transform(p)
                
                pointsToReturn.append(p2)
                
                
            }
        }
        
        if(directionForward == false)
        {
            return pointsToReturn.reversed()
        }
        
        return pointsToReturn
    }


    func strokeRectangle()
    {
        let p = NSBezierPath()
        var pointsToAppend = self.perimenterRectanglePoints()
        p.appendPoints(&pointsToAppend, count: 4)
        p.stroke();
    
    }
    
    func appendTopPoints( path : inout NSBezierPath)
    {
    
    }

    func appendBottomPoints( path : inout NSBezierPath)
    {
        
    
    
    }


}

extension NSControl.StateValue
{
        var boolValue : Bool {
     
        get
        
        {
          return self.rawValue > 0 ? true : false;
        }
        
    }
}

extension NSRect
{

    func rotatedAroundPoint(point : CGPoint, degrees: CGFloat) -> NCTRotatedRect
    {
        let centeredSelfRect = self.centerOnPoint(point);
        
    
        let xfm = RotationTransform(angleDegrees: degrees, centerPoint: point)
        var points = [centeredSelfRect.bottomLeft(),centeredSelfRect.bottomRight(),centeredSelfRect.topRight(),centeredSelfRect.topLeft(),centeredSelfRect.middleLeft(),centeredSelfRect.middleRight(),centeredSelfRect.topMiddle(),centeredSelfRect.bottomMiddle()];
        
        for i in 0..<points.count
        {
        
            points[i] = xfm.transform(points[i])
        }
        
        return NCTRotatedRect.init(bottomLeft: points[0], bottomRight: points[1], topRight: points[2], topLeft: points[3], middleLeft:points[4],middleRight:points[5],topMiddle:points[6],bottomMiddle:points[7],centerPoint:centeredSelfRect.centroid(),angleRadians: deg2rad(degrees), width: self.width,height: self.height )
        
    
    }
    
    func unionProtectFromZeroRect(_ r2 : NSRect) -> NSRect
    {
        if(self == .zero)
        {
            return r2
        }
        
        return self.union(r2)
    
    }

}

// UTILITIES FUNCTIONS
func RotationTransform(angleDegrees: CGFloat, centerPoint:NSPoint) -> AffineTransform
{
	// return a transform that will cause a rotation about the point given at the angle given
    var xfm = AffineTransform();
    xfm.translate(x: centerPoint.x, y: centerPoint.y)
    xfm.rotate(byDegrees: -angleDegrees)
    xfm.translate(x: -centerPoint.x, y: -centerPoint.y)

	return xfm;
}

func RotationTransform(angleRadians: CGFloat, centerPoint:NSPoint) -> AffineTransform
{
	// return a transform that will cause a rotation about the point given at the angle given
    var xfm = AffineTransform();
    xfm.translate(x: centerPoint.x, y: centerPoint.y)
    xfm.rotate(byRadians: angleRadians);
    xfm.translate(x: -centerPoint.x, y: -centerPoint.y)

	return xfm;
}


func Slope(_ a : NSPoint, _ b : NSPoint) -> CGFloat
{
	// returns the slope of a line given its end points, in radians

	return atan2(b.y - a.y, b.x - a.x);
}

func AngleBetween(a : NSPoint, b : NSPoint,  c : NSPoint) -> CGFloat
{
	return Slope(a, b) - Slope(b, c);
}


// MARK: ARC BY THREE POINTS

public struct Vector3: Equatable {
    public var x: CGFloat = 0.0
    public var y: CGFloat = 0.0
    public var z: CGFloat = 0.0
    
    public init() {
        
    }
    public init(x: CGFloat, y: CGFloat, z: CGFloat) {
        self.x = x
        self.y = y
        self.z = z
    }
}
  // an array of three points is passed in
    // as a CGVector array
    func makeArcFromThreePoints(T : [CGVector]) -> NSBezierPath
    {
        let firstArcPoint = T[0].nspoint()
        let secondArcPoint = T[1].nspoint()
        let thirdArcPoint = T[2].nspoint()
        
        let pathToReturn = NSBezierPath();

        var mp : [Vector3] = [Vector3(),Vector3(),Vector3()];
        
        
        // does not really need a for loop,
        // but was in original processing.org code file.
        // places the mid point of each of the two lines
        // into the mp[] Vector3 array.
        for k in 0..<2
        {
           mp[k] = midpoint(A: T[k], B: T[k+1]); //find 2 midpoints
        }
       
        // the third value in the mp[] Vector3 array is theta,
        // the bisector angle.  this is used in centerFromTwoMidpoints().
        // tangent func's opposite side is AB or BC, while adjacent side is
        // the radius.
        let centerPoint = centerFromTwoMidpoints(mp);   //find the center of the circle
        
        
        let R = sqrt(pow((centerPoint.x-T[2].dx),2)+pow((centerPoint.y - T[2].dy),2)); //calculate the radius
        

        let angle1 = NSBezierPath.lineAngleDegreesFrom(point1: centerPoint, point2: firstArcPoint)
   
        
        //let angle2 = Drawable.lineAngleDegreesFrom(point1: centerPoint, point2: secondArcPoint)
        let angle3 = NSBezierPath.lineAngleDegreesFrom(point1: centerPoint, point2: thirdArcPoint)
        
        
      

        
        let A1 = NSBezierPath.lineAngleDegreesFrom(point1: secondArcPoint, point2: firstArcPoint)
        
        let A2 = NSBezierPath.lineAngleDegreesFrom(point1: secondArcPoint, point2: thirdArcPoint)
        
        var o = A2 - A1;
        
        if(o < 0)
        {
            o += 360;
        }
        
    
//        let b = NSBezierPath();


        
        if(o <= 180)
        {

            pathToReturn.appendArc(withCenter: centerPoint, radius: R, startAngle: angle3, endAngle: angle1)

        }
         else
        {
          
            pathToReturn.appendArc(withCenter: centerPoint, radius: R, startAngle: angle1, endAngle: angle3)
        
        }
        
        return pathToReturn;
        
    }


 // function for each midpoint of
    // when three points are provided
    func midpoint(A : CGVector, B : CGVector) -> Vector3
     {
        var C : CGVector = CGVector();
        var r, theta : CGFloat;
        var p : Vector3;
     
     //stroke(128);
     //strokeWeight(1);
     //line(A.x,A.y,B.x,B.y);
     
        let distance : CGVector = thetaTest(A: A, B: B);
        r = distance.dx; //distance AB
        theta = distance.dy; //inclination of AB
     
        r /= 2; //half distance for the midpoint
        
        
        
        C = CGVector(dx: A.dx + r*cos(theta), dy: A.dy + r*sin(theta)); //midpoint
        theta -= (.pi / 2);  //inclination of the bissecteur
        //line(C.x, C.y, C.x + 40*cos(theta), C.y + 40*sin(theta));
     
        p = Vector3(x: C.dx, y: C.dy, z: theta);  //export midpoint position and bissecteur angle to a global PVector
       
        return p;
     }
    
    
     func thetaTest( A : CGVector, B : CGVector) -> CGVector
     {
        var ctheta, stheta : CGFloat;
        var theta : CGFloat = 0;
        var r : CGFloat;
        var v : CGVector;
     
        r = sqrt(pow((B.dy-A.dy),2)+pow((B.dx-A.dx),2));  //distance AB
     
        ctheta = (B.dx - A.dx)/r;
        stheta = (B.dy - A.dy)/r;
        
         if (ctheta >= 0 && stheta >= 0) {theta = acos(abs(ctheta));} //quadrant 1
         if (ctheta < 0 && stheta > 0) {theta = .pi - acos(abs(ctheta));} //quadrant 2
         if (ctheta <= 0 && stheta <= 0) {theta = acos(abs(ctheta)) + .pi;} //quadrant 3
         if (ctheta > 0 && stheta < 0) {theta = acos(abs(ctheta)) * (-1);} //quadrant 4
        
        
        v = CGVector(dx: r, dy: theta);
        
         return v;
     }

    //The centre of the circle is the intersection of the two lines perpendicular to and
    // passing through the midpoints of the lines AB and BC
    func centerFromTwoMidpoints(_ P : [Vector3]) -> NSPoint //(centerOfCircle: CGVector, radius: CGFloat)
    {
        var ox, oy, a: CGFloat;
        var eq : [Vector3] = [Vector3(),Vector3()];
            
        
        for i in 0..<2
        {
            a = tan(P[i].z);
            eq[i] = Vector3(x: a, y: -1, z: -1*(P[i].y - P[i].x*a)) //equation of the first bissector (ax - y =  -b)
        }
        
        //calculate x and y coordinates of the center of the circle
        ox = (eq[1].y * eq[0].z - eq[0].y * eq[1].z) / (eq[0].x * eq[1].y - eq[1].x * eq[0].y);
        oy =  (eq[0].x * eq[1].z - eq[1].x * eq[0].z) / (eq[0].x * eq[1].y - eq[1].x * eq[0].y);
        
        
        var O = NSPoint();
        
        O.x = ox;
        O.y = oy;
        
       // let  R = sqrt(sq(O.x-T[2].p.x)+sq(O.y - T[2].p.y)); //calculate the radius
        
        return O //(O,R);
    }


/*
https://github.com/SusanDoggie/Doggie/blob/d790d7dbe9737091f39c0d9b85dca78c1f89f206/Sources/DoggieGeometry/Geometry/Geometry.swift

public func Barycentric(_ p0: Point, _ p1: Point, _ p2: Point, _ q: Point) -> Vector? {
    
    let det = (p1.y - p2.y) * (p0.x - p2.x) + (p2.x - p1.x) * (p0.y - p2.y)
    
    if det.almostZero() {
        return nil
    }
    
    let s = ((p1.y - p2.y) * (q.x - p2.x) + (p2.x - p1.x) * (q.y - p2.y)) / det
    let t = ((p2.y - p0.y) * (q.x - p2.x) + (p0.x - p2.x) * (q.y - p2.y)) / det
    
    return Vector(x: s, y: t, z: 1 - s - t)
}


//
//  Geometry.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2021 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
@inlinable
@inline(__always)
public func Collinear(_ p0: Point, _ p1: Point, _ p2: Point) -> Bool {
    let d = p0.x * (p1.y - p2.y) + p1.x * (p2.y - p0.y) + p2.x * (p0.y - p1.y)
    return d.almostZero()
}

@inlinable
@inline(__always)
public func CircleInside(_ p0: Point, _ p1: Point, _ p2: Point, _ q: Point) -> Bool? {
    
    func det(_ x0: Double, _ y0: Double, _ z0: Double,
             _ x1: Double, _ y1: Double, _ z1: Double,
             _ x2: Double, _ y2: Double, _ z2: Double) -> Double {
        
        return x0 * y1 * z2 +
            y0 * z1 * x2 +
            z0 * x1 * y2 -
            z0 * y1 * x2 -
            y0 * x1 * z2 -
            x0 * z1 * y2
    }
    
    let s = dot(q, q)
    
    let r = det(p0.x - q.x, p0.y - q.y, dot(p0, p0) - s,
                p1.x - q.x, p1.y - q.y, dot(p1, p1) - s,
                p2.x - q.x, p2.y - q.y, dot(p2, p2) - s)
    
    return r.almostZero() ? nil : r.sign == cross(p1 - p0, p2 - p0).sign
}

@inlinable
@inline(__always)
public func Barycentric(_ p0: Point, _ p1: Point, _ p2: Point, _ q: Point) -> Vector? {
    
    let det = (p1.y - p2.y) * (p0.x - p2.x) + (p2.x - p1.x) * (p0.y - p2.y)
    
    if det.almostZero() {
        return nil
    }
    
    let s = ((p1.y - p2.y) * (q.x - p2.x) + (p2.x - p1.x) * (q.y - p2.y)) / det
    let t = ((p2.y - p0.y) * (q.x - p2.x) + (p0.x - p2.x) * (q.y - p2.y)) / det
    
    return Vector(x: s, y: t, z: 1 - s - t)
}

@inlinable
@inline(__always)
public func inTriangle(_ p0: Point, _ p1: Point, _ p2: Point, _ position: Point) -> Bool {
    
    var q0 = p0
    var q1 = p1
    var q2 = p2
    
    sort(&q0, &q1, &q2) { $0.y < $1.y }
    
    if q0.y <= position.y && position.y < q2.y {
        
        let t1 = (position.y - q0.y) / (q2.y - q0.y)
        let x1 = q0.x + t1 * (q2.x - q0.x)
        
        let t2: Double
        let x2: Double
        
        if position.y < q1.y {
            t2 = (position.y - q0.y) / (q1.y - q0.y)
            x2 = q0.x + t2 * (q1.x - q0.x)
        } else {
            t2 = (position.y - q1.y) / (q2.y - q1.y)
            x2 = q1.x + t2 * (q2.x - q1.x)
        }
        
        let mid_t = (q1.y - q0.y) / (q2.y - q0.y)
        let mid_x = q0.x + mid_t * (q2.x - q0.x)
        
        if mid_x < q1.x {
            return x1 <= position.x && position.x < x2
        } else {
            return x2 <= position.x && position.x < x1
        }
    }
    
    return false
}

public func Collinear(_ p0: Point, _ p1: Point, _ p2: Point) -> Bool {
    let d = p0.x * (p1.y - p2.y) + p1.x * (p2.y - p0.y) + p2.x * (p0.y - p1.y)
    return d.almostZero()
}


 */

class NCTFlippedNSView : NSView
{
    override var isFlipped: Bool
    {
        return true;
    }
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        self.bounds.fill()
        //NSColor.white.setFill()
        //self.bounds.frame(withWidth: 2, using: NSCompositingOperation.sourceOver)
    }
}

class NCTPopoverBackgroundView : NSView
{
    @IBInspectable var viewBackgroundColor : NSColor = NSColor.black;

    override func draw(_ dirtyRect: NSRect) {
        viewBackgroundColor.setFill()
        self.bounds.fill()
    }
    
}




// MARK: ---  NCTVGS VECTORBOOLEAN EXTENSIONS

func pathsIntersect(path1 : NSBezierPath, path2 : NSBezierPath) -> Bool
{
        var didIntersect:Bool = false;
        
      // get both [FBBezierCurve] sets
      let curves1 = FBBezierCurve.bezierCurvesFromBezierPath(path1)
      let curves2 = FBBezierCurve.bezierCurvesFromBezierPath(path2)

      for curve1 in curves1 {
        for curve2 in curves2 {

          var unused: FBBezierIntersectRange?

          curve1.intersectionsWithBezierCurve(curve2, overlapRange: &unused){ (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue: Bool) in

            didIntersect = true;
            
            
            return (false, true)
            
          }
          
          if(didIntersect == true)
          {
            break;
          }
          
        }
      }
      
    
    return didIntersect;

}

func intersectionPointsBetweenPaths(drawables : [FMDrawable]) -> (didIntersect:Bool,intersectionPoints:[NSPoint])
{
    var didIntersect:Bool = false;
    var intersectionPoints : [NSPoint] = []
    
  // If we have exactly two objects, show where they intersect
    if drawables.count == 2 {

      let path1 = drawables[0]
      let path2 = drawables[1]
      // get both [FBBezierCurve] sets
      let curves1 = FBBezierCurve.bezierCurvesFromBezierPath(path1)
      let curves2 = FBBezierCurve.bezierCurvesFromBezierPath(path2)

      for curve1 in curves1 {
        for curve2 in curves2 {

          var unused: FBBezierIntersectRange?

          curve1.intersectionsWithBezierCurve(curve2, overlapRange: &unused){ (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue: Bool) in

            /*
            if intersection.isTangent {
              UIColor.purple.setStroke()
            } else {
              UIColor.green.setStroke()
            }
            */
            
            intersectionPoints.append(intersection.location);
            /*
            let inter = UIBezierPath(ovalIn: self.BoxFrame(intersection.location))
            inter.lineWidth = self.decorationLineWidth
            inter.stroke()
            */
            
            return (false, false)
            
          }
        }
      }
    }
    
    didIntersect = (!intersectionPoints.isEmpty)
    
    return ( didIntersect, intersectionPoints);

}

extension NSScrollView {

    // from https://stackoverflow.com/questions/19399242/soft-scroll-animation-nsscrollview-scrolltopoint
    func scroll(to point: NSPoint, animationDuration: Double)
    {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = animationDuration
        contentView.animator().setBoundsOrigin(point)
        reflectScrolledClipView(contentView)
        NSAnimationContext.endGrouping()
    }
}
