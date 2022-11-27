//
//  ShapeInQuadDrawingEntity.swift
//  Floating Marker
//
//  Created by John Pratt on 3/8/21.
//

import Cocoa

enum ShapeInQuadDrawingEntityMode : Int
{
    case shapeInQuad // four points of a quadrilateral
    case shapeInQuadTaperedRect // three points: middle point of one side, then
                                // the following two corner pts of
                                // the quadrilateral.
    
}

class ShapeInQuadDrawingEntity: DrawingEntity
{
    @IBOutlet var shapeKeysConfigPopoverViewController : ShapeKeysConfigPopoverViewController?
    @IBOutlet var shapeKeysConfigPopover : NSPopover?
    
    
    
    var shapeInQuadDrawingEntityMode : ShapeInQuadDrawingEntityMode = ShapeInQuadDrawingEntityMode.shapeInQuad;
    override var designatedEnumRawValue : Int
    {
        
        get{ return shapeInQuadDrawingEntityMode.rawValue }
    }


    override init() {
        super.init();
        
        let shapeInQuadWorkflowStates = ["idle","liveFirstAndSecondPoint","liveThirdPoint","liveFourthPoint"];
        let shapeInQuadWorkflow = DrawingEntityWorkflow.init(workflowStates: shapeInQuadWorkflowStates, currentState: shapeInQuadWorkflowStates[0], drawingEntity: self);
        workflows = [0 : shapeInQuadWorkflow]
        
    }

  override var currentlyDrawnForState: FMDrawable
    {
        get
        {
            let currentworkflowState = workflows[0]!.currentState;

            if(currentworkflowState == "liveFourthPoint")
            {
                return fmDrawableForEntity;
            }
            else
            {
                return underlayPathForCurrentMode;
            }
            
        }
    }

    // MARK: KEY PRESS
    func shapeInQuad()
    {
        let currentworkflowState = workflows[0]!.currentState;
 
       // Actions under these states prepare for the next one.
        if( currentworkflowState == "idle")
        {
            pointsArrayForCurrentMode.removeAll();
            pointsArrayForCurrentMode.append(lineWorkInteractionEntity!.currentPointInActiveLayer!)
            pointsArrayForCurrentMode.append(lineWorkInteractionEntity!.currentPointInActiveLayer!)
            updatePreviewForCurrentMode();

        }
        if( currentworkflowState == "liveFirstAndSecondPoint")
        {
            if(pointsArrayForCurrentMode.count >= 2)
            {
                pointsArrayForCurrentMode.append(lineWorkInteractionEntity!.currentPointInActiveLayer!)
                updatePreviewForCurrentMode();

            }
            
        }
        else if( currentworkflowState == "liveThirdPoint")
        {
            if(pointsArrayForCurrentMode.count >= 3)
            {
                pointsArrayForCurrentMode.append(lineWorkInteractionEntity!.currentPointInActiveLayer!)
                pointsArrayForCurrentMode[2] = lineWorkInteractionEntity!.currentPointInActiveLayer!;
            }
        }
        else if( currentworkflowState == "liveFourthPoint")
        {
            if(pointsArrayForCurrentMode.count >= 4)
            {
                pointsArrayForCurrentMode[3] = lineWorkInteractionEntity!.currentPointInActiveLayer!;
                affirmFourthQuadrilateralPointIsValidAndMakeNCTQuad();

            }
        }
        
       workflows[0]?.advanceState();
    
    }

    // MARK: MOUSE MOVED
    override func mouseMoved(with event: NSEvent)
    {
        let currentworkflowState = workflows[0]!.currentState;
        
        if(shapeInQuadDrawingEntityMode == .shapeInQuad)
        {
            
            if( currentworkflowState == "liveFirstAndSecondPoint")
            {
                if(pointsArrayForCurrentMode.count >= 2)
                {
                    pointsArrayForCurrentMode[1] = lineWorkInteractionEntity!.currentPointInActiveLayer!;
                }
                
                updatePreviewForCurrentMode();
                
            }
            else if( currentworkflowState == "liveThirdPoint")
            {
                if(pointsArrayForCurrentMode.count >= 3)
                {
                    pointsArrayForCurrentMode[2] = lineWorkInteractionEntity!.currentPointInActiveLayer!;
                }
                
                updatePreviewForCurrentMode();
            }
            else if( currentworkflowState == "liveFourthPoint")
            {
                if(pointsArrayForCurrentMode.count >= 4)
                {
                    pointsArrayForCurrentMode[3] = lineWorkInteractionEntity!.currentPointInActiveLayer!;
                    affirmFourthQuadrilateralPointIsValidAndMakeNCTQuad();
                    
                    depositDrawable = nctQuad.transformedFMDrawable;

                }
                
                updatePreviewForCurrentMode();
            }
        }
    }

    func affirmFourthQuadrilateralPointIsValidAndMakeNCTQuad()
    {
           let fmDrawableForRegeneratedNCTQuad = self.nctQuad.fmDrawableToTransform;
           self.nctQuad = NCTQuad.init(topLeft: pointsArrayForCurrentMode[0], topRight: pointsArrayForCurrentMode[1] , bottomRight : pointsArrayForCurrentMode[2], bottomLeft : pointsArrayForCurrentMode[3]);
           self.nctQuad.fmDrawableToTransform = fmDrawableForRegeneratedNCTQuad;
           
           // https://math.stackexchange.com/questions/129854/convex-quadrilateral-test
           /*
           let a = 360 - NSBezierPath.lineAngleDegreesFrom(point1: pointsArrayForCurrentMode[0], point2: pointsArrayForCurrentMode[3])
        let b = 360 - NSBezierPath.lineAngleDegreesFrom(point1: pointsArrayForCurrentMode[3], point2: pointsArrayForCurrentMode[2])

           print("\(a - b)")*/
           /*
           let intersectionP : NSPoint = nctQuad.intersectionPoint();
           
           let d1 = intersectionP.distanceFrom(point2: pointsArrayForCurrentMode[0])
           let d2 = intersectionP.distanceFrom(point2: pointsArrayForCurrentMode[1])
           let d3 = intersectionP.distanceFrom(point2: pointsArrayForCurrentMode[2])
           let d4 = intersectionP.distanceFrom(point2: pointsArrayForCurrentMode[3])
           
           
           
           print("""
           d1 \(d1)
           d2 \(d2)
           d3 \(d3)
           d4 \(d4)
           """)*/
           
          //  let c1 = 360 - NSBezierPath.lineAngleDegreesFrom(point1: pointsArrayForCurrentMode[0], point2: pointsArrayForCurrentMode[2])
        //    var a1 = c1 + 360 - NSBezierPath.lineAngleDegreesFrom(point1: pointsArrayForCurrentMode[3], point2: pointsArrayForCurrentMode[0])
          //  var a2 = c1 + 360 - NSBezierPath.lineAngleDegreesFrom(point1: pointsArrayForCurrentMode[3], point2: pointsArrayForCurrentMode[2])
            
            /*
        var a1 = 360 - NSBezierPath.lineAngleDegreesFrom(point1: pointsArrayForCurrentMode[1], point2: pointsArrayForCurrentMode[0])
            
        var a2 = 360 - NSBezierPath.lineAngleDegreesFrom(point1: pointsArrayForCurrentMode[1], point2: pointsArrayForCurrentMode[2])
        
        let c1 = 360 - NSBezierPath.lineAngleDegreesFrom(point1: pointsArrayForCurrentMode[1], point2: pointsArrayForCurrentMode[3])
            
            if(a1 >= 360)
            {
                a1 -= 360;
            
            }
 
            
            if(a2 >= 360)
            {
                a2 -= 360;
            
            }
        */
//        print(" a1:\(a1 - c1) \n a2: \(a2 - c1)")
//            print(" c1:\(c1)\n a1:\(a1) \n a2:\(a2)")

//        if((a2 - c1) < 0)
//        {
////            let dist : CGFloat = NSPoint.distanceBetween( pointsArrayForCurrentMode[1], pointsArrayForCurrentMode[2])
//            
////            pointsArrayForCurrentMode[3] = pointsArrayForCurrentMode[2].pointFromAngleAndLength(angleRadians: 0 - deg2rad(a2), length:dist)
//        }

            
    
    }

    override func workflowStateJustAdvancedCallback(drawingEntityWorkflow: DrawingEntityWorkflow)
    {
        let currentworkflowState = drawingEntityWorkflow.currentState;


        if(shapeInQuadDrawingEntityMode == .shapeInQuad)
        {
            print(drawingEntityWorkflow.currentState)
            // advanced from fourth point
            if( currentworkflowState == "idle")
            {
            
                let oldRect = underlayPathForCurrentMode.extendedBezierPathBounds;
                underlayPathForCurrentMode.removeAllPoints();
              
                if(includeBoundingBoxInFinalResult)
                {
                    underlayPathForCurrentMode.appendPoints(&pointsArrayForCurrentMode, count: pointsArrayForCurrentMode.count)
                    underlayPathForCurrentMode.close()
                }
                
                if(includeBackgroundGridInFinalResult)
                {
                   nctQuad.solvePerspective();
                   underlayPathForCurrentMode.append(nctQuad.backgroundGridBezierPath())
                }
                
                if(pointsArrayForCurrentMode.count >= 4)
                {
                    let p1 = NSBezierPath();
                    p1.appendPoints(&pointsArrayForCurrentMode, count: pointsArrayForCurrentMode.count)
                    nctQuad.solvePerspective();
//                    nctQuad.cornerRadius = lineWorkInteractionEntity!.inkAndLineSettingsManager!.cornerRounding
//                    underlayPathForCurrentMode.append(nctQuad.ovalPath(baseRect: p1.bounds))

                    nctQuad.updateTransformedWithBounds(rect: p1.bounds)
                    underlayPathForCurrentMode = nctQuad.transformedFMDrawable
                    
                    depositDrawable = nctQuad.transformedFMDrawable;
                    
                    // underlayPathForCurrentMode.append(nctQuad.backgroundGridBezierPath())
                }
                

                deposit()
                
                lineWorkInteractionEntity?.activePenLayer?.setNeedsDisplay(underlayPathForCurrentMode.extendedBezierPathBounds.unionProtectFromZeroRect(oldRect))
            }
            if( currentworkflowState == "liveFirstAndSecondPoint")
            {
           
                
            }
            else if( currentworkflowState == "liveThirdPoint")
            {
            
            }
            else if( currentworkflowState == "liveFourthPoint")
            {
            
            }
        }
    
    }
    
    var includeBoundingBoxInFinalResult : Bool = false;
    var includeBackgroundGridInFinalResult : Bool = false;
    var showPreviewBackgroundGrid : Bool = false;
    
    override func updatePreviewForCurrentMode()
    {
        let currentworkflowState = workflows[shapeInQuadDrawingEntityMode.rawValue]!.currentState;

        if(shapeInQuadDrawingEntityMode == .shapeInQuad)
        {
      
            let oldRect = updateRect();
            
            if( currentworkflowState == "liveFirstAndSecondPoint")
            {
                nctQuad.fmDrawableToTransform = shapeKeysConfigPopoverViewController!.shapeForShapeInQuadDrawingEntity
                
                guard nctQuad.fmDrawableToTransform.isEmpty == false else {
                    fatalError("fmDrawableToTransform empty")
                }
                underlayPathForCurrentMode.removeAllPoints();
                underlayPathForCurrentMode.appendPoints(&pointsArrayForCurrentMode, count: pointsArrayForCurrentMode.count)
                lineWorkInteractionEntity?.activePenLayer?.setNeedsDisplay(underlayPathForCurrentMode.extendedBezierPathBounds.unionProtectFromZeroRect(oldRect))
            }
            else if( currentworkflowState == "liveThirdPoint")
            {
                underlayPathForCurrentMode.removeAllPoints();
                underlayPathForCurrentMode.appendPoints(&pointsArrayForCurrentMode, count: pointsArrayForCurrentMode.count)
                lineWorkInteractionEntity?.activePenLayer?.setNeedsDisplay(underlayPathForCurrentMode.extendedBezierPathBounds.unionProtectFromZeroRect(oldRect))
            }
            else if( currentworkflowState == "liveFourthPoint")
            {
                shapeKeysConfigPopoverViewController!.baseRectForShape = underlayPathForCurrentMode.bounds
                nctQuad.fmDrawableToTransform = shapeKeysConfigPopoverViewController!.shapeForShapeInQuadDrawingEntity

                underlayPathForCurrentMode.removeAllPoints();
              
                underlayPathForCurrentMode.appendPoints(&pointsArrayForCurrentMode, count: pointsArrayForCurrentMode.count)
                underlayPathForCurrentMode.close()
                
                
                if(pointsArrayForCurrentMode.count >= 4)
                {
                    nctQuad.solvePerspective();

                    nctQuad.updateTransformedWithBounds(rect: underlayPathForCurrentMode.bounds)
                  
                    fmDrawableForEntity.removeAllPoints();
                    fmDrawableForEntity.append(nctQuad.transformedFMDrawable);
                  
                    //underlayPathForCurrentMode.append(nctQuad.ovalPath(baseRect: underlayPathForCurrentMode.bounds))
                }
                
                lineWorkInteractionEntity?.activePenLayer?.setNeedsDisplay(underlayPathForCurrentMode.extendedBezierPathBounds.unionProtectFromZeroRect(oldRect)/*.unionProtectFromZeroRect(nctQuad.transformedFMDrawable.bounds)*/)
            }
        }


    }
    
    var nctQuad : NCTQuad = NCTQuad.init(topLeft: .zero, topRight: .zero, bottomRight: .zero, bottomLeft: .zero);
    
    
    override func drawForActivePenLayer()
    {
        if(shapeInQuadDrawingEntityMode == .shapeInQuad)
        {
            NSColor.black.setStroke()
            
            underlayPathForCurrentMode.stroke();
            if(pointsArrayForCurrentMode.count >= 4)
            {
                if(showPreviewBackgroundGrid)
                {
                    nctQuad.displayBackgroundGrid()
                }
                //nctQuad.transformedFMDrawable.display();
                
              
            }
        }
        

        
        if(fmDrawableForEntity.isEmpty == false)
        {
            fmDrawableForEntity.display();
        }
        
    
    }
    
    
    // MARK: SETTINGS CONTROLS FROM POPOVER VIEWS
    var usesIndependentStrokeWidth : Bool = true
    {
        didSet
        {
        }
    }
    
    var independentStrokeWidth : CGFloat = 1
    {
        didSet
        {
            
            independentStrokeWidth.formClamp(to: 0.5...400.0)
            
            
        }
    }
    
    
    
}
