//
//  NCTQuad.swift
//  Floating Marker
//
//  Created by John Pratt on 2/12/21.
//

import Foundation

class NCTQuad : NSObject
{
    var fmDrawableToTransform : FMDrawable = FMDrawable();
    var transformedFMDrawable : FMDrawable = FMDrawable();
    func updateTransformedWithBounds(rect: NSRect)
    {
            //ovalPath(baseRect: rect)
        guard fmDrawableToTransform.isEmpty == false else {
            fatalError("updateTransformedWithBounds")
        }
        
        let p = pathTransformed(baseRect: rect, path: fmDrawableToTransform as NSBezierPath);
        transformedFMDrawable.removeAllPoints()
        transformedFMDrawable.append(p)
        
    }
    

    var topLeft : NSPoint = .zero
    var topRight : NSPoint = .zero
    var bottomLeft : NSPoint = .zero
    var bottomRight : NSPoint = .zero
    
    init(topLeft: NSPoint, topRight : NSPoint, bottomRight : NSPoint, bottomLeft : NSPoint) {
        
        self.topLeft = topLeft;
        self.topRight = topRight;
        self.bottomLeft = bottomLeft;
        self.bottomRight = bottomRight;
        
    }
    
    func intersectionPoint() -> NSPoint
    {
    
        if let iP = NSPoint.Intersection2(p1: self.bottomLeft, p2: self.topRight, p3: self.topLeft, p4: self.bottomRight)
        {
            return iP
        }
        else
        {
            return .zero;
        }
        
  
    }

    // These are the homographic coefficients
    var A : CGFloat = 0
    var B : CGFloat  = 0
    var D : CGFloat  = 0
    var E : CGFloat  = 0
    var G : CGFloat  = 0
    var H : CGFloat  = 0
    
    
    let perspectiveUpperBound : CGFloat = 1.0; // was originally 1.0 (without variable label)

    func perspective(U : CGFloat, V : CGFloat) -> NSPoint
    {
        var T : CGFloat = 0;
        
        T = G * U + H * V + perspectiveUpperBound;
        
        let x = (A * U + B * V) / T + bottomLeft.x
        let y = (D * U + E * V) / T + bottomLeft.y
        return NSPoint.init(x: x, y: y)
    
    }
    
     func solvePerspective()
    {
        var T : CGFloat = 0;
        
        T = (topRight.x - bottomRight.x) * (topRight.y - topLeft.y) - (topRight.x - topLeft.x) * (topRight.y - bottomRight.y)
    
        
    
        G = ((topRight.x - bottomLeft.x) * (topRight.y - topLeft.y) - (topRight.x - topLeft.x) * (topRight.y - bottomLeft.y)) / T
        H = ((topRight.x - bottomRight.x) * (topRight.y - bottomLeft.y) - (topRight.x - bottomLeft.x) * (topRight.y - bottomRight.y)) / T

        A = G * (bottomRight.x - bottomLeft.x)
        D = G * (bottomRight.y - bottomLeft.y)
        B = H * (topLeft.x - bottomLeft.x)
        E = H * (topLeft.y - bottomLeft.y)

        G -= 1
        H -= 1
        
    }
    
    func display()
    {
        displayBackgroundGrid()
    }
    
    
    func makePerspectiveTransformBezierPath(bezierPathToPerspectiveTransform : NSBezierPath) -> NSBezierPath
    {
        var p = bezierPathToPerspectiveTransform.copy() as! NSBezierPath
        perspectiveTransformBezierPath(bezierPathToPerspectiveTransform: &p)
        return p
    }
    
    func perspectiveTransformBezierPath(bezierPathToPerspectiveTransform : inout NSBezierPath)
    {
        for i in 0..<bezierPathToPerspectiveTransform.elementCount
        {
        
            var pointArray : [NSPoint] = Array.init(repeating: NSPoint.init(), count: 3);
            let elementType = bezierPathToPerspectiveTransform.element(at: i, associatedPoints: &pointArray)
            let bezierPathToPerspectiveTransformBounds = bezierPathToPerspectiveTransform.bounds
          //  let p2 = perspective(U: (perspectiveUpperBound * pointArray[0].x - bezierPathToPerspectiveTransform.bounds.minX) / bezierPathToPerspectiveTransform.bounds.width, V: perspectiveUpperBound * (pointArray[0].y - bezierPathToPerspectiveTransform.bounds.minY) / bezierPathToPerspectiveTransform.bounds.height)
            
            if(elementType == .curveTo)
            {
            
                // index 2 is the curveTo point while 0 and 1 are the control points
                pointArray[2] = perspective(U: perspectiveUpperBound * (pointArray[2].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: perspectiveUpperBound * (pointArray[2].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
                
                
                
                // control point
                let k : CGFloat = 0.98;
                
                pointArray[1] = perspective(U: k * perspectiveUpperBound * ( pointArray[1].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: perspectiveUpperBound * (pointArray[1].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
                

                // control point
                pointArray[0] = perspective(U: perspectiveUpperBound * (pointArray[0].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: perspectiveUpperBound * (pointArray[0].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
                

                
                
            }
            else
            {
                pointArray[0] = perspective(U: perspectiveUpperBound * (pointArray[0].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: perspectiveUpperBound * (pointArray[0].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
            

            }
            
            bezierPathToPerspectiveTransform.setAssociatedPoints(&pointArray, at: i)

            
        }
        
    
    }
    
    func backgroundGridBezierPath() -> NSBezierPath
    {
        
        let bezierPathToReturn = NSBezierPath();

        let incr : CGFloat = perspectiveUpperBound * 0.0625

        for u : CGFloat in stride(from: incr , through: perspectiveUpperBound - incr, by: incr)
        {
            bezierPathToReturn.move(to: perspective(U: u, V: 0))
            bezierPathToReturn.line(to: perspective(U: u, V: perspectiveUpperBound))

        }
        
        
        for V : CGFloat  in stride(from: incr, through: perspectiveUpperBound - incr, by: incr)
        {
            bezierPathToReturn.move(to: perspective(U: 0, V: V))
            bezierPathToReturn.line(to: perspective(U: perspectiveUpperBound, V: V))

            
        }
        
        return bezierPathToReturn;
    }
    
    func displayBackgroundGrid()
    {
        solvePerspective();
        
        

        for u : CGFloat in stride(from: 0.0625, through: 1 - 0.0625, by: 0.0625)
        {
        
            NSBezierPath.strokeLine(from: perspective(U: u, V: 0), to: perspective(U: u, V: 1))
            // perspective(U: u, V: 0).fillSquareAtPoint(sideLength: 10, color: NSColor.red)
            // perspective(U: u, V: 1).fillSquareAtPoint(sideLength: 10, color: NSColor.red)
        }
        
        
        for V : CGFloat  in stride(from: 0.0625, through: 1 - 0.0625, by: 0.0625)
        {
            NSBezierPath.strokeLine(from: perspective(U: 0, V: V), to: perspective(U: 1, V: V))
            // perspective(U: 0, V: V).fillSquare3x3AtPoint(color: NSColor.green)
            
        }
        
    }
    
    
    var cornerRadius : CGFloat = 10.0;


    func ovalPath(baseRect : NSRect) -> NSBezierPath
    {
        var bezierPathToPerspectiveTransform : NSBezierPath = NSBezierPath();
        bezierPathToPerspectiveTransform.appendOval(in: baseRect)
//        bezierPathToPerspectiveTransform.appendRoundedRect(baseRect, xRadius: cornerRadius, yRadius: cornerRadius)
        
        //
        // "Efficient" option will draw inside controlPointBounds
        // all throughout the perspective transform,
        // leaving a gap.
        // 
        
        bezierPathToPerspectiveTransform = bezierPathToPerspectiveTransform.flattened
        let bezierPathToPerspectiveTransformBounds = bezierPathToPerspectiveTransform.bounds
//        let bezierPathToPerspectiveTransformBounds = bezierPathToPerspectiveTransform.controlPointBounds
//        let bezierPathToPerspectiveTransformControlPointBounds = bezierPathToPerspectiveTransform.controlPointBounds;
        
        let xformedPath = NSBezierPath();
        
        // TRANSFORM WITH PERSPECTIVE
        for i in 0..<bezierPathToPerspectiveTransform.elementCount
        {
            
            var pointArray : [NSPoint] = Array.init(repeating: NSPoint.init(), count: 3);
            let elementType = bezierPathToPerspectiveTransform.element(at: i, associatedPoints: &pointArray)
            
//            NSColor.green.setFill();
            
            //let p2 = perspective(U: (pointArray[0].x - bezierPathToPerspectiveTransform.bounds.minX) / bezierPathToPerspectiveTransform.bounds.width, V: (pointArray[0].y - bezierPathToPerspectiveTransform.bounds.minY) / bezierPathToPerspectiveTransform.bounds.height)
            //p2.fillSquareAtPoint(sideLength: 4, color: NSColor.purple)
            
            switch elementType {
            case .curveTo:
                // index 2 is the curveTo point while 0 and 1 are the control points
                pointArray[2] = perspective(U: (pointArray[2].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[2].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
                
//                pointArray[2].fillSquareAtPoint(sideLength: 10, color: NSColor.blue)
                
                // control point
                let k : CGFloat = 1.0//0.98;
                
                pointArray[1] = perspective(U: k * ( pointArray[1].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[1].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
     
                
//                pointArray[1].fillSquareAtPoint(sideLength: 10, color: NSColor.orange)
                // control point
                
                 pointArray[0] = perspective(U: (pointArray[0].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[0].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
                
//                pointArray[0].fillSquareAtPoint(sideLength: 10, color: NSColor.purple)
                
                
                xformedPath.curve(to: pointArray[2], controlPoint1: pointArray[0], controlPoint2: pointArray[1])
                
//                NSBezierPath.strokeLine(from: pointArray[2], to: pointArray[1])
//                NSBezierPath.strokeLine(from: pointArray[2], to: pointArray[0])
                
            case .lineTo:
            pointArray[0] = perspective(U: (pointArray[0].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[0].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
            xformedPath.line(to: pointArray[0])
            case .moveTo:
            pointArray[0] = perspective(U: (pointArray[0].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[0].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
            xformedPath.move(to: pointArray[0])
            case .closePath:
            pointArray[0] = perspective(U: (pointArray[0].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[0].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
            xformedPath.close()
            default:
                break;
            }
            
            
            //bezierPathToPerspectiveTransform.setAssociatedPoints(&pointArray, at: i)
          
            
//            xformedPath.stroke();
//            bezierPathToPerspectiveTransform.stroke();
        
            
        }
        
        
        return xformedPath
    }
    
   func pathTransformed(baseRect : NSRect, path : NSBezierPath) -> NSBezierPath
    {
    var bezierPathToPerspectiveTransform : NSBezierPath = path.copy() as! NSBezierPath//();
        //bezierPathToPerspectiveTransform.appendOval(in: baseRect)
//        bezierPathToPerspectiveTransform.appendRoundedRect(baseRect, xRadius: cornerRadius, yRadius: cornerRadius)
        
        //
        // "Efficient" option will draw inside controlPointBounds
        // all throughout the perspective transform,
        // leaving a gap.
        //
        
        bezierPathToPerspectiveTransform = bezierPathToPerspectiveTransform.flattened
        let bezierPathToPerspectiveTransformBounds = bezierPathToPerspectiveTransform.bounds
//        let bezierPathToPerspectiveTransformBounds = bezierPathToPerspectiveTransform.controlPointBounds
//        let bezierPathToPerspectiveTransformControlPointBounds = bezierPathToPerspectiveTransform.controlPointBounds;
        
        let xformedPath = NSBezierPath();
        
        // TRANSFORM WITH PERSPECTIVE
        for i in 0..<bezierPathToPerspectiveTransform.elementCount
        {
            
            var pointArray : [NSPoint] = Array.init(repeating: NSPoint.init(), count: 3);
            let elementType = bezierPathToPerspectiveTransform.element(at: i, associatedPoints: &pointArray)
            
//            NSColor.green.setFill();
            
            //let p2 = perspective(U: (pointArray[0].x - bezierPathToPerspectiveTransform.bounds.minX) / bezierPathToPerspectiveTransform.bounds.width, V: (pointArray[0].y - bezierPathToPerspectiveTransform.bounds.minY) / bezierPathToPerspectiveTransform.bounds.height)
            //p2.fillSquareAtPoint(sideLength: 4, color: NSColor.purple)
            
            switch elementType {
            case .curveTo:
                // index 2 is the curveTo point while 0 and 1 are the control points
                pointArray[2] = perspective(U: (pointArray[2].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[2].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
                
//                pointArray[2].fillSquareAtPoint(sideLength: 10, color: NSColor.blue)
                
                // control point
                let k : CGFloat = 1.0//0.98;
                
                pointArray[1] = perspective(U: k * ( pointArray[1].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[1].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
     
                
//                pointArray[1].fillSquareAtPoint(sideLength: 10, color: NSColor.orange)
                // control point
                
                 pointArray[0] = perspective(U: (pointArray[0].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[0].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
                
//                pointArray[0].fillSquareAtPoint(sideLength: 10, color: NSColor.purple)
                
                
                xformedPath.curve(to: pointArray[2], controlPoint1: pointArray[0], controlPoint2: pointArray[1])
                
//                NSBezierPath.strokeLine(from: pointArray[2], to: pointArray[1])
//                NSBezierPath.strokeLine(from: pointArray[2], to: pointArray[0])
                
            case .lineTo:
            pointArray[0] = perspective(U: (pointArray[0].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[0].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
            xformedPath.line(to: pointArray[0])
            case .moveTo:
            pointArray[0] = perspective(U: (pointArray[0].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[0].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
            xformedPath.move(to: pointArray[0])
            case .closePath:
            pointArray[0] = perspective(U: (pointArray[0].x - bezierPathToPerspectiveTransformBounds.minX) / bezierPathToPerspectiveTransformBounds.width, V: (pointArray[0].y - bezierPathToPerspectiveTransformBounds.minY) / bezierPathToPerspectiveTransformBounds.height)
            xformedPath.close()
            default:
                break;
            }
            
            
            //bezierPathToPerspectiveTransform.setAssociatedPoints(&pointArray, at: i)
          
            
//            xformedPath.stroke();
//            bezierPathToPerspectiveTransform.stroke();
        
            
        }
        
        
        return xformedPath
    }
      
}
