//
//  RectangleDrawingEntity.swift
//  Floating Marker
//
//  Created by John Pratt on 3/8/21.
//

import Cocoa

enum RectangleDrawingEntityMode : Int
{
    case byTwoLines
    case fromDiagonal
    case usingBisector
    case fromCenter
}

class RectangleDrawingEntity: DrawingEntity
{
    @IBOutlet var shapeKeysConfigPopoverViewController : ShapeKeysConfigPopoverViewController?
    @IBOutlet var shapeKeysConfigPopover : NSPopover?

    var rectangleDrawingEntityMode : RectangleDrawingEntityMode = .byTwoLines;
    override var designatedEnumRawValue : Int
    {
        get{ return rectangleDrawingEntityMode.rawValue }
        
    }
  
    /*
    override var currentWorkflow : DrawingEntityWorkflow
    {
        get{
            return workflows[rectangleDrawingEntityMode.rawValue];
        }
    }*/
    
    override init() {
        super.init();
        
        let byTwoLinesWorkflowStates = ["idle","liveFirstAndSecondPoint","liveThirdPoint"]
        let byTwoLinesWorkflow = DrawingEntityWorkflow.init(workflowStates: byTwoLinesWorkflowStates, currentState: byTwoLinesWorkflowStates[0], drawingEntity: self);
        workflows = [RectangleDrawingEntityMode.byTwoLines.rawValue : byTwoLinesWorkflow]
        
    }
    
    
  
    
    override func drawForActivePenLayer()
    {
        if(rectangleDrawingEntityMode == .byTwoLines)
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
    func rectangleByTwoLines()
    {
       let currentworkflowState = workflows[rectangleDrawingEntityMode.rawValue]!.currentState;
 
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

       workflows[rectangleDrawingEntityMode.rawValue]?.advanceState();
       
    }

    // MARK: MOUSE MOVED
    override func mouseMoved(with event: NSEvent)
    {
        let currentworkflowState = workflows[rectangleDrawingEntityMode.rawValue]!.currentState;
        
        if(rectangleDrawingEntityMode == .byTwoLines)
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


        if(rectangleDrawingEntityMode == .byTwoLines)
        {
            //print(drawingEntityWorkflow.currentState)
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
    
    override func updatePreviewForCurrentMode()
    {
        let currentworkflowState = workflows[rectangleDrawingEntityMode.rawValue]!.currentState;

        if(rectangleDrawingEntityMode == .byTwoLines)
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
