//
//  EllipseDrawingEntity.swift
//  Floating Marker
//
//  Created by John Pratt on 3/8/21.
//

import Cocoa

enum EllipseDrawingEntityMode : Int
{
    case byTwoAxes
}

class EllipseDrawingEntity: DrawingEntity
{
    @IBOutlet var shapeKeysConfigPopoverViewController : ShapeKeysConfigPopoverViewController?
    @IBOutlet var shapeKeysConfigPopover : NSPopover?

    var ellipseDrawingEntityMode : EllipseDrawingEntityMode = .byTwoAxes
    override var designatedEnumRawValue : Int
    {
        get{ return ellipseDrawingEntityMode.rawValue }
        
    }
    
    // MARK: INIT
    override init() {
        super.init();
        
        let byTwoAxesWorkflowStates = ["idle","liveFirstAndSecondPoint","liveThirdPoint"]
        let byTwoAxesWorkflow = DrawingEntityWorkflow.init(workflowStates: byTwoAxesWorkflowStates, currentState: byTwoAxesWorkflowStates[0], drawingEntity: self);
        workflows = [EllipseDrawingEntityMode.byTwoAxes.rawValue : byTwoAxesWorkflow]
        
    }
    
    override func drawForActivePenLayer()
    {
    
       if(ellipseDrawingEntityMode == .byTwoAxes)
        {
            NSColor.black.setStroke()
            underlayPathForCurrentMode.stroke();
            
        }
        
        if(fmDrawableForEntity.isEmpty == false)
        {
            fmDrawableForEntity.display();
        }
        
    }

    // MARK: KEY PRESS
    func ellipseByTwoAxes()
    {
       let currentworkflowState = workflows[ellipseDrawingEntityMode.rawValue]!.currentState;
 
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
                pointsArrayForCurrentMode[2] = lineWorkInteractionEntity!.currentPointInActiveLayer!;
            }
        }

       workflows[ellipseDrawingEntityMode.rawValue]?.advanceState();
       
    }


    // MARK: MOUSE MOVED
    override func mouseMoved(with event: NSEvent)
    {
        let currentworkflowState = workflows[ellipseDrawingEntityMode.rawValue]!.currentState;
        
        if(ellipseDrawingEntityMode == .byTwoAxes)
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
            
        }
    }
    
    // MARK: workflowStateJustAdvancedCallback
    override func workflowStateJustAdvancedCallback(drawingEntityWorkflow: DrawingEntityWorkflow)
    {
        let currentworkflowState = drawingEntityWorkflow.currentState;


        if(ellipseDrawingEntityMode == .byTwoAxes)
        {
           // print(drawingEntityWorkflow.currentState)
            if( currentworkflowState == "idle")
            {
            
                lineWorkInteractionEntity?.multistateEntityEnded()
                resetDrawingEntity()
                

            }
            if( currentworkflowState == "liveFirstAndSecondPoint")
            {
           
                
            }
            else if( currentworkflowState == "liveThirdPoint")
            {
            
            }
        }
    
    }
    
    // MARK: updatePreviewForCurrentMode
    override func updatePreviewForCurrentMode()
    {
        let currentworkflowState = workflows[ellipseDrawingEntityMode.rawValue]!.currentState;

        if(ellipseDrawingEntityMode == .byTwoAxes)
        {
            let oldRect = updateRect();
            
            if( currentworkflowState == "liveFirstAndSecondPoint")
            {
                
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

        }


    }
    
   
     
}
