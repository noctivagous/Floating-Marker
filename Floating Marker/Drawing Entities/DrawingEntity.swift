//
//  DrawingEntity.swift
//  Floating Marker
//
//  Created by John Pratt on 3/8/21.
//

import Cocoa


class DrawingEntityWorkflow : NSObject
{
    var workflowStates : [String] = [];
    var currentState : String = ""
    
    var drawingEntity : DrawingEntity?
    
    func baseFMDrawableDidChange()
    {
    
    
    }
    
    init(workflowStates: [String], currentState: String, drawingEntity: DrawingEntity)
    {
        super.init();
        self.workflowStates = workflowStates
        self.currentState = currentState
        self.drawingEntity = drawingEntity
    }
    
    static func ==(lhs: DrawingEntityWorkflow, rhs: DrawingEntityWorkflow) -> Bool
    {
        return lhs.drawingEntity == rhs.drawingEntity && lhs.workflowStates == rhs.workflowStates
    }
    
    func advanceState()
    {
        guard ((currentState != "") && (workflowStates.isEmpty == false)) else
        {
            return;
        }
    
        if let indexOfCurrentState = workflowStates.firstIndex(of: currentState)
        {
        
            if(indexOfCurrentState == (workflowStates.count - 1))
            {
                currentState = workflowStates[0];
                
            }
            else
            {
                currentState = workflowStates[indexOfCurrentState + 1];
            }


            drawingEntity?.workflowStateJustAdvancedCallback(drawingEntityWorkflow : self);
            
        }
    
    
    } // END     func advanceState()
    
    func currentStateIsLast() -> Bool
    {
        if let indexOfCurrentState = workflowStates.firstIndex(of: currentState)
        {
            if(indexOfCurrentState == workflowStates.count - 1)
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        
        return false
    }

}

class DrawingEntity: NSObject
{
    @IBOutlet var lineWorkInteractionEntity : LineWorkInteractionEntity?


    var designatedEnumRawValue : Int
    {
        get{ return 0 }
    }
    
    var workflows : [Int : DrawingEntityWorkflow] = [:]
    var currentWorkflowIndex : Int = 0;
    
    var currentWorkflow : DrawingEntityWorkflow
    {
        get
        {
            return workflows[currentWorkflowIndex]!
        }
    }
    func currentWorkflowIsLast() -> Bool
    {
        return currentWorkflow.currentStateIsLast()
    }
    
    /*
    var currentWorkflow : DrawingEntityWorkflow
    {
        get{
            return workflows[0];
        }
    }*/

    var fmDrawableForEntity : FMDrawable = FMDrawable();
    var pointsArrayForCurrentMode : [NSPoint] = [];
    var underlayPathForCurrentMode : FMDrawable = FMDrawable();
  

    override init() {
        super.init();
        
   
    }
    
   

    func drawForActivePenLayer()
    {
    
    
    }
    
    func updatePreviewForCurrentMode()
    {
    
    }
    
    func updateRect() -> NSRect
    {
        var updateRectToReturn : NSRect = .zero;
        if(underlayPathForCurrentMode.isEmpty == false)
        {
            updateRectToReturn = updateRectToReturn.unionProtectFromZeroRect(underlayPathForCurrentMode.extendedBezierPathBounds)
        }

        if(fmDrawableForEntity.isEmpty == false)
        {
            updateRectToReturn = updateRectToReturn.unionProtectFromZeroRect(fmDrawableForEntity.extendedBezierPathBounds)
        }

        
        return updateRectToReturn;
    
    }
    
    func hasReachedFinalStep() -> Bool
    {
        return currentWorkflowIsLast();
    }
    
    func end()
    {
    
        if(hasReachedFinalStep())
        {
            deposit();
        }
        else
        {
            escape();
        }

    }
    
    var currentlyDrawnForState : FMDrawable
    {
        get
        {
            return underlayPathForCurrentMode;
        }
    }
    
    var depositDrawable : FMDrawable = FMDrawable();
    
    func deposit()
    {
        fmDrawableForEntity.removeAllPoints();
        fmDrawableForEntity.append(depositDrawable);
        
        let fmDrawableForDeposit = FMShapeKeyDrawable();
        fmDrawableForDeposit.append(fmDrawableForEntity)
          var d = fmDrawableForDeposit as FMDrawable
            
        lineWorkInteractionEntity!.inkAndLineSettingsManager!.aggregatedSetting.applyToDrawable(fmDrawable: &d)
//        fmDrawableForDeposit.fmInk = lineWorkInteractionEntity!.inkAndLineSettingsManager!.fmInk;
//
//        fmDrawableForDeposit.lineWidth = lineWorkInteractionEntity!.inkAndLineSettingsManager!.currentBrushTipWidth;
        
        fmDrawableForDeposit.pointsArrayForModeBounds = self.pointsArrayForCurrentMode;
        
        lineWorkInteractionEntity?.rawFMDrawableDepositOntoCurrentPaperLayer(fmDrawableToDeposit:fmDrawableForDeposit,undoMessage:"Shape");
        
        lineWorkInteractionEntity?.multistateEntityEnded()
        resetDrawingEntity()
    }
    
    func escape()
    {
    
        resetDrawingEntity()
        lineWorkInteractionEntity?.multistateEntityEnded()

    }
    
    func resetDrawingEntity()
    {
        let oldRect = self.updateRect();
        
        fmDrawableForEntity.removeAllPoints();
        underlayPathForCurrentMode.removeAllPoints()
        pointsArrayForCurrentMode.removeAll();
        
        // iterates through all workflows and
        // sets them to idle.  does not trigger any callback
        // because advanceState() is not called.
        for (_,wf) in workflows.keys.enumerated()
        {
            if(workflows[wf] != nil)
            {
                if(workflows[wf]!.workflowStates.count > 0)
                {
                    workflows[wf]!.currentState = workflows[wf]!.workflowStates[0]
                }
            }
        }
        
        lineWorkInteractionEntity?.activePenLayer?.setNeedsDisplay(oldRect);


    }
    
    func advanceWorkflow()
    {
    
    
    }
    
    func workflowStateJustAdvancedCallback(drawingEntityWorkflow : DrawingEntityWorkflow)
    {
    
    
    }
    
    /*
    func workflowStatesRS()
    {
        for workflow in workflows.values
        {
            if(workflow.workflowStates.isEmpty == false)
            {
                workflow.currentState = workflow.workflowStates[0]
            }
        }
    }
    */
    
    // MARK: MOUSE
    
    func mouseMoved(with event: NSEvent)
    {
        
    }

}
