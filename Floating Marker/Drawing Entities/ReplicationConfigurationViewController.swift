//
//  ReplicationConfigurationViewController.swift
//  Graphite Glider Preview
//
//  Created by John Pratt on 6/22/20.
//  Copyright © 2020 Noctivagous, Inc. All rights reserved.
//

import Cocoa


// ---------------------------
// ---------------------------
// TODO: Pasting an object will immediately
// replicate it in relation to the replicationAnchorPoint
// (according to the current replication settings)
// ---------------------------
// ---------------------------

/*/
For each DrawingEntity:



 1 ---  self.displayLiveReplication();
    in drawForActiveLayer()


 2 ---
 self.determineReplicationLive(rectDrawable.copy() as! RectangularlyContainedDrawable);
 
 in processMouseMoved()
 




 3 ---
 updateRectStored = drawingEntityManager.liveReplicationUpdateRectUnionedIfAny(updateRectStored)
  
   updateRectCurrent = drawingEntityManager.liveReplicationUpdateRectUnionedIfAny(updateRectCurrent)
            drawingEntityManager.updateActiveLayerInRect(updateRectCurrent)
            
    in updateLayer()
  
 4  --- r = determineReplicationForDeposit(r);
   during deposit


*/

enum ReplicationMode : String {
    case radial
    case mirror
    case oneDimensional
    case twoDimensional
    
    case alongStroke
    case normalsReflector // makes multiples of the stroke on either side
    //
    case treeBranch
    case lSystem
    case whorl
    case rectangularFrame
    
}


struct NCTReplicationEffectOnIncrement
{
    

    func radiusDidStepUp()
    {
    
    }

    func rowDidStepUp()
    {
    
    }

    func columnDidStepUp()
    {
    
    }

    func cellDidStepUp()
    {
    
    }
    
    func applyShift ( drawable : inout FMDrawable)
    {
    
    }
    
}

struct NCTReplicatorStruct
{
    var replicationMode : ReplicationMode = .radial
    var replicationSettings : [String:Any] = [:];
    var replicationModeFunction : (FMDrawable, [String:Any]) -> FMDrawable? =  { (fmDrawable:FMDrawable, replicationSettings: [String:Any]) -> FMDrawable? in return nil}
    
    init(replicationMode:ReplicationMode, replicationSettings:[String:Any], replicationModeFunction : @escaping (FMDrawable, [String:Any]) -> FMDrawable? )
    {
        self.replicationMode = replicationMode;
        self.replicationSettings = replicationSettings;
        self.replicationModeFunction = replicationModeFunction
    }
    
    func xmlElement() -> XMLElement
    {
    
        return XMLElement.init();
    }
    
}



class ReplicationConfigurationViewController: NSViewController, NSPopoverDelegate
 {
 
    @IBOutlet var lineWorkInteractionEntity : LineWorkInteractionEntity?
 
    @IBOutlet var replicationPopover : NSPopover!;

    var currentReplicatorStruct : NCTReplicatorStruct?


    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        /*
        let replicationModeFunction = { (fmDrawable, [ : ]) -> FMDrawable? in
            
            
        })
        
        currentReplicatorStruct = NCTReplicatorStruct.init(replicationMode: .radial, replicationSettings: [:], replicationModeFunction:
        */
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
  
    
    @IBOutlet  var radialReplicationSettingsPopoverView: NSView!
    
    @IBOutlet  var twoDReplicationSettingsPopoverView: NSView!
    
    @IBOutlet  var oneDReplicationSettingsPopoverView: NSView!
    
    @IBOutlet  var mirrorReplicationSettingsPopoverView: NSView!
    
    @IBOutlet var whorlReplicationSettingsPopoverView: NSView!
    
    @IBAction func launchReplicationModePopover(_ sender: Any?)
    {
    
        if let configureButton = sender as? NCTButton
        {
            replicationPopover!.performClose(configureButton)
           
            var contentSizeOfPopover : NSSize = .zero
            switch replicationMode
            {
            case .radial:
                self.view = radialReplicationSettingsPopoverView
                contentSizeOfPopover = radialReplicationSettingsPopoverView.frame.size
            case .twoDimensional:
                self.view = twoDReplicationSettingsPopoverView;
                contentSizeOfPopover = twoDReplicationSettingsPopoverView.frame.size
            case .mirror:
                self.view = mirrorReplicationSettingsPopoverView;
                contentSizeOfPopover = mirrorReplicationSettingsPopoverView.frame.size
            case .oneDimensional:
                self.view = oneDReplicationSettingsPopoverView;
                contentSizeOfPopover = oneDReplicationSettingsPopoverView.frame.size
            case .whorl:
                self.view = whorlReplicationSettingsPopoverView;
                contentSizeOfPopover = whorlReplicationSettingsPopoverView.frame.size
            default:
                self.view = radialReplicationSettingsPopoverView
                contentSizeOfPopover = radialReplicationSettingsPopoverView.frame.size
                return;
            }
            
            
        
            // workaround for some kind of contentSize problem in NSPopover
            replicationPopover!.contentSize = contentSizeOfPopover//NSMakeSize(400, 120)
            if(self.view.frame.size.height != replicationPopover!.contentSize.height)
            {
                replicationPopover!.contentSize.height = self.view.frame.size.height
                replicationPopover!.contentSize.width = self.view.frame.size.width
            }

            replicationPopover?.show(relativeTo: configureButton.bounds, of: configureButton, preferredEdge: NSRectEdge.minX)
            
        
        }
    }

    @IBOutlet var useBoundsAsReferenceForRepetitionCheckbox : NSButton!
    @IBOutlet var addStrokeWidthToSpacingCheckbox : NSButton!
    
    
    // MARK: ---  USE BOUNDS AS REFERENCE FOR REPETITION
    var useBoundsAsReferenceForRepetition : Bool = true
    {
        didSet
        {
            useBoundsAsReferenceForRepetitionCheckbox.state = useBoundsAsReferenceForRepetition.stateValue;
        
        }
    }

    var addStrokeWidthToSpacing : Bool = false
    {
        didSet
        {
            addStrokeWidthToSpacingCheckbox.state = addStrokeWidthToSpacing.stateValue;
        
        }
    
    }


    var produceGroupDrawable : Bool = false
    {
        didSet
        {
        
        }
    }

    var repeatHorizontally : Bool = true
    {
        didSet
        {
        
        }
    }

    // MARK: RADIAL REPLICATION
    
    var numberOfRings : Int = 1
    {
        didSet
        {
            numberOfRingsTextField?.integerValue = numberOfRings;
        }
    }
    @IBOutlet var numberOfRingsTextField : NCTTextField?
    @IBAction func changeNumberOfRings(_ sender : NSControl)
    {
        numberOfRings = sender.integerValue
    }
    
    var ringDistanceIncrementType : String = "fixed"; //
    
    func ringIncrementDistanceAtIndex(index:Int, boundingBox:NSRect) -> CGFloat
    {
        
        return 10.0;
    }
    
    
    @IBOutlet var replicateByAngleDistanceOffsetTextField : NSTextField?
    var replicateByAngleDistanceOffset : CGFloat = 150
    {
        didSet
        {
        
            replicateByAngleDistanceOffsetTextField?.setCGFloatValue(replicateByAngleDistanceOffset)
        
            updateGuidelines()
            
        }
    }

    @IBAction func changeReplicateByAngleDistanceOffset(_ sender : NSControl)
    {
        self.replicateByAngleDistanceOffset = sender.cgfloatValue();
    }
    
    
    @IBOutlet weak var endAngleTextField: NCTTextField?
    
    
    
    @IBOutlet weak var startAngleTextField: NCTTextField?
    
    
    @IBAction func changeStartAngle(_ sender: NSControl)
    {
        startAngle = sender.cgfloatValue()
    }
    
    @IBAction func changeEndAngle(_ sender: NSControl)
    {
        endAngle = sender.cgfloatValue()
    }
    
    var startAngle : CGFloat = 0
    {
        didSet
        {
            startAngle = startAngle.clamped(to: 0...358)
            
            if(startAngle > endAngle)
            {
                startAngle = 0;
            }
            
            startAngleTextField?.setCGFloatValue(startAngle);
        }
    }

    var endAngle : CGFloat = 360
    {
        didSet
        {
            endAngle = endAngle.clamped(to: 3...360);
            if(endAngle < startAngle)
            {
                startAngle = 0;
            }
            
            endAngleTextField?.setCGFloatValue(endAngle);
        }
    }


    @IBOutlet weak var radialCountLabelField: NSTextField?
    
    @IBOutlet var angleIntervalForReplicationTextfield : NSTextField!
   
    var angleIntervalForReplication  : CGFloat = 20.0
    {
        didSet
        {
        
           
        
            angleIntervalForReplication = angleIntervalForReplication.clamped(to: 1.0...180.0)
          //  angleIntervalForReplication = floor(angleIntervalForReplication);
            
            angleIntervalForReplicationTextfield.setCGFloatValue(angleIntervalForReplication);
            
 
            radialCountLabelField?.stringValue = "\(360 / Int(angleIntervalForReplication) )"
           // angleIntervalForReplication = angleIntervalForReplication.clamped(to: -180.0...180.0)
            //if (angleIntervalForReplication == 0)
            //{ angleIntervalForReplication = 1.0 }
            
            updateGuidelines()

            
        }
    }
    
    
    @IBAction func changeAngleIntervalForReplication(_ sender : NSControl)
    {
        self.angleIntervalForReplication = sender.cgfloatValue();
    }
    
    
    @IBAction func setToAngleIntervalPreset(_ sender: NCTSegmentedControl)
    {
        
        self.angleIntervalForReplication = sender.cgfloatValue();

    }
    
    // MARK: MIRROR
    
    var numberOfMirrorsAvailableArray = [1,2]
    var numberOfMirrors : Int = 1
    {
        didSet
        {
            if(numberOfMirrorsAvailableArray.contains(numberOfMirrors) == false)
            {
                numberOfMirrors = 1;
            }
        
            if(numberOfMirrors == 1)
            {
                numberOfMirrorsNCTSegm?.selectedSegment = 0
                
            }
            if(numberOfMirrors == 2)
            {
                numberOfMirrorsNCTSegm?.selectedSegment = 1
            }
            
            updateGuidelines();
        }
    }

    @IBOutlet var numberOfMirrorsNCTSegm : NCTSegmentedControl?
    
    @IBAction func changeNumberOfMirrors(_ sender : NCTSegmentedControl)
    {
        if(sender.selectedSegment == 0)
        {
            numberOfMirrors = 1
        }
        if(sender.selectedSegment == 1)
        {
            numberOfMirrors = 2
        }
    }
    
    var mirrorDegreesRotation : CGFloat = 0
    {
        didSet
        {
            //            if(oldValue != mirrorDegreesRotation)
            //            {
            
            mirrorDegreesRotation = mirrorDegreesRotation.clamped(to: 0...360)
            
            if(mirrorDegreesRotationTextField != nil)
            {
                if(mirrorDegreesRotationTextField!.cgfloatValue() != mirrorDegreesRotation)
                {
                    mirrorDegreesRotationTextField!.setCGFloatValue(mirrorDegreesRotation);
                }
            }
            updateGuidelines()
            //            }
        }
    }
    
    @IBOutlet var mirrorDegreesRotationTextField : NCTTextField?
    @IBAction func changeMirrorDegreesRotation(_ sender : NSControl)
    {
        mirrorDegreesRotation = sender.cgfloatValue()
    }

    
    // MARK: ONE DIMENSIONAL REPLICATION
    

    @IBOutlet var oneDimReplicationAngleSlider : NSSlider!
    @IBOutlet var oneDimReplicationAngleTextfield : NSTextField!
    
    
    
    var oneDimReplicationAngle : CGFloat = 20.0
    {
        didSet
        {
            oneDimReplicationAngle = oneDimReplicationAngle.clamped(to: 1.0...360.0)
        
            oneDimReplicationAngleSlider.setCGFloatValue(oneDimReplicationAngle);
            oneDimReplicationAngleTextfield.setCGFloatValue(oneDimReplicationAngle);
        
            replicationAngleRadiansCached = deg2rad(oneDimReplicationAngle);
        
        }
    }

    var replicationAngleRadiansCached : CGFloat = 0;



    /*
    var repeatHorizontallyStartingPosition : Int = 0
    {
        didSet
        {
        
        }
    }*/
    
    var replicateRadialCount : Int = 20
    {
        didSet
        {
        
        }
    }


    // MARK: --- REPLICATION MODE
    var replicationMode : ReplicationMode
    {
        get{ return lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode}
    }

    @IBOutlet var oneDimensionalReplicationCountTextField : NSTextField!;
    
    var oneDimensionalReplicationCount : Int = 10
    {
        didSet
        {
        
            if(oneDimensionalReplicationCount < 2)
            {
                oneDimensionalReplicationCount = 2;
            }
        
            oneDimensionalReplicationCountTextField.integerValue = oneDimensionalReplicationCount;
        }
    }

    @IBOutlet var oneDimensionalReplicationSpacingTextField : NSTextField!;

    var oneDimensionalReplicationSpacing : CGFloat = 5.0
    {
        didSet
        {
            oneDimensionalReplicationSpacingTextField.setCGFloatValue(oneDimensionalReplicationSpacing);
        
        }
    }
    
    // MARK: --- PROCESS SCALE UP AND DOWN BUTTONS FOR COUNT
    
    func processScaleUpForCount()
    {
        if(replicationMode == .oneDimensional)
        {
            oneDimensionalReplicationCount += 1;
        }
    
    }

    func processScaleDownForCount()
    {
    
        if(replicationMode == .oneDimensional)
        {
            oneDimensionalReplicationCount -= 1;
        }
        
    }

    // MARK: --- IBACTIONS

    @IBAction func changeOneDimensionalAngle(_ sender : NSControl)
    {
        self.oneDimReplicationAngle = sender.cgfloatValue();
    }

    @IBAction func changeReplicationMode(_ sender : NSButton)
    {
    
       // self.replicationMode = ReplicationMode(rawValue: sender.tag) ?? .oneDimensional;

    }

    @IBAction func changeSpacingIsRelativeToBoundingBox(_ sender : NSButton)
    {
    
        self.useBoundsAsReferenceForRepetition = sender.boolFromState;
    
    }
    
    @IBAction func changeOneDimensionalReplicationSpacing(_ sender: NSTextField)
    {
        self.oneDimensionalReplicationSpacing = sender.cgfloatValue();
        
    }
    
    @IBAction func changeOneDimensionalReplicationCount(_ sender: NSTextField)
    {
        self.oneDimensionalReplicationCount = sender.integerValue;
        
    }
    
    @IBAction func changeAddStrokeWidthToRepeatBoundingBox(_ sender : NSButton)
    {
    
        self.addStrokeWidthToSpacing = sender.boolFromState;
    
    }


    @IBAction func changeRadialReplicationIntervalType(_ sender : NSButton)
    {
    
      
    
    }
    
    // MARK: --- PROPERTIES

    // MARK: REPLICATION FRAME

    var replicationFrame : NSRect = NSMakeRect(0, 0, 100, 100)
    {
        didSet
        {
            replicationFrameSizeHeightTextField?.setCGFloatValue(replicationFrame.size.height)
            replicationFrameSizeWidthTextField?.setCGFloatValue(replicationFrame.size.width)
            
            updateGuidelines();
        }
    }
    
    var addClippingMaskOfReplicationFrame : Bool = false
    {
        didSet
        {
            
        }
    }
    
    
    @IBAction func changeReplicationFrameSizeWidth(_ sender : NSControl)
    {
        let val = sender.cgfloatValue().clamped(to: 1...5000)
        replicationFrame.size.width = val
    }
    
    @IBOutlet var replicationFrameSizeHeightTextField : NCTTextField?
    @IBOutlet var replicationFrameSizeWidthTextField : NCTTextField?

    @IBAction func changeReplicationFrameSizeHeight(_ sender : NSControl)
    {
        let val = sender.cgfloatValue().clamped(to: 1...5000)
        replicationFrame.size.height = val
    }

 // MARK: TWO DIMENSIONAL REPLICATION

    var twoDUsesReplicationFrameBounds : Bool = true
    {
        didSet
        {
            twoDUsesReplicationFrameBoundsNCTSegmCont?.selectedSegment = twoDUsesReplicationFrameBounds.onOffSwitchInt
        }
    }


    @IBOutlet var twoDUsesReplicationFrameBoundsNCTSegmCont : NCTSegmentedControl?

    @IBAction func changeTwoDUsesReplicationFrameBounds(_ sender : NCTSegmentedControl)
    {
        twoDUsesReplicationFrameBounds = sender.onOffSwitchBool;
    }


    var twoDOffset : Int = 0 // none, row, column
    {
        didSet
        {
            twoDOffsetNCTSegmCont?.selectedSegment = twoDOffset;
        }
    }


    @IBOutlet var twoDOffsetNCTSegmCont : NCTSegmentedControl?

    @IBAction func changeTwoDOffset(_ sender : NCTSegmentedControl)
    {
        twoDOffset = sender.selectedSegment;
    }


    // MARK: vertical
    
    var replicate2DVerticalRepeatCount : Int = 10
    {
        didSet
        {
            replicate2DVerticalRepeatCount = replicate2DVerticalRepeatCount.clamped(to: 1...5000)
            replicate2DVerticalRepeatCountTextField?.integerValue = replicate2DVerticalRepeatCount;
        }
    }
    @IBOutlet var replicate2DVerticalRepeatCountTextField : NCTTextField?
    @IBAction func changeReplicate2DVerticalRepeatCount(_ sender : NSControl)
    {
        replicate2DVerticalRepeatCount = sender.integerValue
    }
    
    
    
    var replicate2DVerticalSpacing : CGFloat = 3.0
    {
        didSet
        {
            replicate2DVerticalSpacing = replicate2DVerticalSpacing.clamped(to: 1...5000)
            replicate2DVerticalSpacingTextField?.setCGFloatValue(replicate2DVerticalSpacing)
        }
    }
    
    @IBOutlet var replicate2DVerticalSpacingTextField : NCTTextField?
    @IBAction func changeReplicate2DVerticalSpacing(_ sender : NSControl)
    {
        replicate2DVerticalSpacing = sender.cgfloatValue()
    }
    
    
    
    // MARK: horizontal
    
     var replicate2DHorizontalRepeatCount : Int = 10
    {
        didSet
        {
            replicate2DHorizontalRepeatCount = replicate2DHorizontalRepeatCount.clamped(to: 1...5000);
            replicate2DHorizontalRepeatCountTextField?.integerValue = replicate2DHorizontalRepeatCount;
            
            updateGuidelines()
        }
    }
    @IBOutlet var replicate2DHorizontalRepeatCountTextField : NCTTextField?
    @IBAction func changeReplicate2DHorizontalRepeatCount(_ sender : NSControl)
    {
        replicate2DHorizontalRepeatCount = sender.integerValue
    }
    
    
    
    var replicate2DHorizontalSpacing : CGFloat = 3.0
    {
        didSet
        {
            replicate2DHorizontalSpacing = replicate2DHorizontalSpacing.clamped(to: 1...5000)
            replicate2DHorizontalSpacingTextField?.setCGFloatValue(replicate2DHorizontalSpacing)
            
            updateGuidelines()
        }
    }
    @IBOutlet var replicate2DHorizontalSpacingTextField : NCTTextField?
    @IBAction func changeReplicate2DHorizontalSpacing(_ sender : NSControl)
    {
        replicate2DHorizontalSpacing = sender.cgfloatValue()
    }
    
    
    
    var replicate2DStartingPosition : Int = 0
    {
        didSet
        {
        
        }
    }
    
    
 


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    // MARK:  --- MAKE THE REPLICATION DRAWABLE(S)
    
    var permanentAnchorPoint : NSPoint
    {
        get
        {
            if(lineWorkInteractionEntity?.currentDrawingPage != nil)
            {
                return lineWorkInteractionEntity!.currentDrawingPage!.permanentAnchorPoint
            }
            else
            {
            
                return .zero;
            }
            
        }
    }
    
   
    
    // MARK: REPLICATION LIVE IMAGE
    var replicationDrawableLiveUnitOfReplicImage : NSImage?
    var replicationDrawableLiveUnitOfReplicImageSize : NSSize = .zero;

    var replicationDrawableLiveUnitOfReplicImageBounds : NSRect = .zero;
    
    var calculatedRepetitionBoundsForReplicatedDrawableImg : NSRect = .zero;
    var calculatedRepetitionBoundsForReplicatedDrawableImgOld : NSRect = .zero;
    
    func makeReplicationDrawableLiveImage(_ drawable : FMDrawable)
    {
        
        let drawableToReplicate = drawable;
        
        //        var arrayOfReplicationResults : [FMDrawable] = [];
        
        var referenceSize : NSSize = NSSize.zero
        
        
        if(addStrokeWidthToSpacing)
        {
            referenceSize.width += drawable.lineWidth;
            referenceSize.height += drawable.lineWidth;
        }
        
        if(useBoundsAsReferenceForRepetition)
        {
            referenceSize.width = drawableToReplicate.renderBounds().size.width
            referenceSize.height = drawableToReplicate.renderBounds().size.height
        }
        
        
        calculatedRepetitionBoundsForReplicatedDrawableImgOld = calculatedRepetitionBoundsForReplicatedDrawableImg;
        
        if(lineWorkInteractionEntity?.currentDrawingPage != nil)
        {
            lineWorkInteractionEntity!.currentDrawingPage!.activePenLayer.layer!.sublayers?.removeAll()
            let replicatorLayer = CAReplicatorLayer()
            replicatorLayer.frame.size = lineWorkInteractionEntity!.currentDrawingPage!.frame.size;
            replicatorLayer.isGeometryFlipped = true;
            replicatorLayer.masksToBounds = true
            
            replicationDrawableLiveUnitOfReplicImageBounds = drawableToReplicate.renderBounds();
            replicationDrawableLiveUnitOfReplicImageSize = replicationDrawableLiveUnitOfReplicImageBounds.size;
            
            //  repetitionBoundsForReplicatedDrawableImg =
            let drawableToReplicateRenderBounds = replicationDrawableLiveUnitOfReplicImageBounds;

            if(replicationDrawableLiveUnitOfReplicImageBounds.size != .zero)
            {
                
                
                replicationDrawableLiveUnitOfReplicImage = drawableToReplicate.image(sizeForRescale: replicationDrawableLiveUnitOfReplicImageBounds.size, boundsPadding: 0, untranslatedDrawingBounds: replicationDrawableLiveUnitOfReplicImageBounds, drawingCode:
                                                                            {
                                                                                
                                                                                drawableToReplicate.display();
                                                                                
                                                                            }, flippedImage: true)
                
                // MARK: radial
                if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .radial)
                {

                    calculatedRepetitionBoundsForReplicatedDrawableImg = drawableToReplicateRenderBounds;
                    let boundsCalculatorBP = NSBezierPath();
                    
                    
                    for currentAngle : CGFloat in stride(from: startAngle, through: endAngle, by: angleIntervalForReplication)
                    {
                        boundsCalculatorBP.appendRect(calculatedRepetitionBoundsForReplicatedDrawableImg);
                        
                        let transform = NSAffineTransform.init();
                        //                        let ctrdRB = drawableToReplicate.centroidOfRenderbounds;
                        let initialX = permanentAnchorPoint.x//ctrdRB.x;
                        let initialY = permanentAnchorPoint.y//ctrdRB.y;
                        
                        transform.translateX(by: initialX, yBy: initialY)
                        transform.rotate(byDegrees: currentAngle)
                        transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
                        
                        boundsCalculatorBP.transform(using: transform as AffineTransform )
                        
                        calculatedRepetitionBoundsForReplicatedDrawableImg = calculatedRepetitionBoundsForReplicatedDrawableImg.union(boundsCalculatorBP.bounds);
                        
                        boundsCalculatorBP.removeAllPoints();
                        
                        
                    }
                    
                    
                }
                // MARK: mirror
                else if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .mirror)
                {
                    // start out with the unitDrawableToReplicate
                    calculatedRepetitionBoundsForReplicatedDrawableImg = drawableToReplicateRenderBounds;
                    
                    let boundsCalculatorBP = NSBezierPath();
                    boundsCalculatorBP.appendRect(calculatedRepetitionBoundsForReplicatedDrawableImg);
                    
                    let transform = NSAffineTransform.init();
                    
                    let initialX = permanentAnchorPoint.x//ctrdRB.x;
                    let initialY = permanentAnchorPoint.y//ctrdRB.y;
                    
                    transform.translateX(by: initialX, yBy: initialY)
                    
                    transform.scaleX(by: 1.0, yBy: -1.0)
                    
                    transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
                    
                    if(mirrorDegreesRotation != 0)
                    {
                        transform.translateX(by: initialX, yBy: initialY)
                        
                        transform.rotate(byDegrees: 2 * mirrorDegreesRotation)
                        
                        transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
                    }
                    
                    boundsCalculatorBP.transform(using: transform as AffineTransform )
                    
                    
                    calculatedRepetitionBoundsForReplicatedDrawableImg = calculatedRepetitionBoundsForReplicatedDrawableImg.union(boundsCalculatorBP.bounds);
                    
                    
                    if(numberOfMirrors == 2)
                    {
                        
                        let p1 = NSBezierPath();
                        p1.appendRect(replicationDrawableLiveUnitOfReplicImageBounds)
                        
                        var transformFourfold = NSAffineTransform.init();
                        transformFourfold.translateX(by: initialX, yBy: initialY)
                        
                        transformFourfold.scaleX(by: -1.0, yBy: 1.0)
                        
                        transformFourfold.translateX(by: -1 * initialX, yBy: -1 * initialY)
                        
                        if(mirrorDegreesRotation != 0)
                        {
                            transformFourfold.translateX(by: initialX, yBy: initialY)
                            
                            transformFourfold.rotate(byDegrees: 2 * mirrorDegreesRotation)
                            
                            transformFourfold.translateX(by: -1 * initialX, yBy: -1 * initialY)
                        }
                        
                        p1.transform(using: transformFourfold as AffineTransform )
                        
                        calculatedRepetitionBoundsForReplicatedDrawableImg = calculatedRepetitionBoundsForReplicatedDrawableImg.union(p1.bounds);
                        
                        let p2 = NSBezierPath();
                        p2.appendRect(replicationDrawableLiveUnitOfReplicImageBounds)
                        
                        transformFourfold = NSAffineTransform.init();
                        transformFourfold.translateX(by: initialX, yBy: initialY)
                        
                        transformFourfold.scaleX(by: -1.0, yBy: -1.0)
                        
                        transformFourfold.translateX(by: -1 * initialX, yBy: -1 * initialY)
                        
                        /*
                        if(mirrorDegreesRotation != 0)
                        {
                            transformFourfold.translateX(by: initialX, yBy: initialY)
                            
                            transformFourfold.rotate(byDegrees: 2 * mirrorDegreesRotation)
                            
                            transformFourfold.translateX(by: -1 * initialX, yBy: -1 * initialY)
                        }*/
                        
                        p2.transform(using: transformFourfold as AffineTransform )
                        
                        calculatedRepetitionBoundsForReplicatedDrawableImg = calculatedRepetitionBoundsForReplicatedDrawableImg.union(p2.bounds);
                    }
                    
                    boundsCalculatorBP.removeAllPoints();
                    
                    
                }
                else if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .twoDimensional)
                {
                    //        replicate2DVerticalRepeatCount = 7;
                    //        replicate2DVerticalSpacing = 5.0;
                    //
                    //        replicate2DHorizontalRepeatCount = 7;
                    //        replicate2DHorizontalSpacing = 5.0;
                    
                    calculatedRepetitionBoundsForReplicatedDrawableImg = drawableToReplicateRenderBounds;
                    let boundsCalculatorBP = NSBezierPath();
                    
                    
                    for currentRow : Int in stride(from: 0, to: replicate2DHorizontalRepeatCount, by: 1)
                    {
                        
                        for currentColumn : Int in stride(from: 0, to: replicate2DVerticalRepeatCount, by: 1)
                        {
                            
                            boundsCalculatorBP.appendRect(calculatedRepetitionBoundsForReplicatedDrawableImg);
                            
                            let transform = NSAffineTransform.init();
                            
                            transform.translateX(by: CGFloat(currentColumn) * replicationFrame.width , yBy: CGFloat( currentRow) * CGFloat(replicationFrame.height))
                            
                            boundsCalculatorBP.transform(using: transform as AffineTransform )
                            
                            calculatedRepetitionBoundsForReplicatedDrawableImg = calculatedRepetitionBoundsForReplicatedDrawableImg.union(boundsCalculatorBP.bounds);
                            
                            boundsCalculatorBP.removeAllPoints();
                            
                        }
                        
                        
                    }
                    
                }
                
            }
            else
            {
                
            }
            
        }
        
        
        
        /*
        if(replicationMode == .radial)
        {
            
            if replicateRadiallyByCount
            {
                
            }
            else
            {
            //    let rotationPoint = lastReplicationAnchorPoint
                
                
                //                drawableToReplicate.append(drawableCopy);
                
               // for _ /*currentAngle*/ : CGFloat in stride(from: angleIntervalForReplication, through: 360, by: angleIntervalForReplication)
               
                 
                let horiz = permanentAnchorPoint.distanceFrom(point2: drawableToReplicate.renderBounds().bottomRight())
                
                self.replicationDrawableLiveUnitOfReplicImageSize = NSSize.init(width: horiz * 2, height: horiz * 2)
                self.replicationDrawableLiveUnitOfReplicImageBounds = NSRect.init(origin: .zero, size: replicationDrawableLiveUnitOfReplicImageSize).centerOnPoint(permanentAnchorPoint)
                
        
                
                print(replicationDrawableLiveUnitOfReplicImageBounds);
                
                
                replicationDrawableLiveUnitOfReplicImage = NSImage.init(size: replicationDrawableLiveUnitOfReplicImageSize, flipped: true, drawingHandler: { rect in
                    
                    print("liveRect: \(rect)")
                    
                    for currentAngle : CGFloat in stride(from: 0, through: 360, by: 30)
                    {
                        
                        NSGraphicsContext.current?.saveGraphicsState()
                             
                            let transform = NSAffineTransform.init();
                            //                        let ctrdRB = drawableToReplicate.centroidOfRenderbounds;
                            let initialX = self.permanentAnchorPoint.x//ctrdRB.x;
                            let initialY = self.permanentAnchorPoint.y//ctrdRB.y;
                            
                            transform.translateX(by: initialX, yBy: initialY)
                            transform.rotate(byDegrees: currentAngle)
                            transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
                            
                            transform.concat()
                            drawableToReplicate.display();
                        
                        NSGraphicsContext.current?.restoreGraphicsState()
                        
                        /*
                         //COMMENTED OUT FOR LIVE IMAGE
                         
                         let affineTranslation = AffineTransform(translationByX: replicateByAngleDistanceOffset * cos(deg2rad(angleIntervalForReplication)), byY:  replicateByAngleDistanceOffset * sin(deg2rad(angleIntervalForReplication)));
                         
                         drawableCopy.transform(using: affineTranslation);
                         
                         
                         drawableCopy.rotateFrom(pointLocation: FMDrawable.TransformPoint.passedParameter, point: rotationPoint, angle: angleIntervalForReplication)
                         
                         if(produceGroupDrawable == false)
                         {
                         drawableToReplicate.append(drawableCopy);
                         }
                         else
                         {
                         arrayOfReplicationResults.append(drawableCopy)
                         }
                         */
                        
                        
                    }
                    
                    return true
                })// END closure for NSImage.init(size:....
            }
            
        }// END else if(replicationMode == .radial)
        */
        
        
    }
    
    
    

    
    func drawReplicationLiveImage()
    {
        
        if((replicationDrawableLiveUnitOfReplicImage != nil) && (replicationDrawableLiveUnitOfReplicImageBounds != .zero))
        {
            if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .radial)
            {
                
                
                for i in 0..<numberOfRings
                {
                    
                    for currentAngle : CGFloat in stride(from: startAngle, through: endAngle, by: angleIntervalForReplication)
                    {
                        
                        NSGraphicsContext.current?.saveGraphicsState()
                        
                        let transform = NSAffineTransform.init();
                        //                        let ctrdRB = drawableToReplicate.centroidOfRenderbounds;
                        let initialX = permanentAnchorPoint.x//ctrdRB.x;
                        let initialY = permanentAnchorPoint.y//ctrdRB.y;
                        
                        transform.translateX(by: initialX, yBy: initialY)
                        
                        if(numberOfRings > 1)
                        {
                            transform.translateX(
                                by:
                                    self.ringIncrementDistanceAtIndex(index: i, boundingBox: replicationFrame),
                                yBy: 0)
                        }
                        
                        transform.rotate(byDegrees: currentAngle)
                        transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
                        
                        transform.concat()
                        
                        replicationDrawableLiveUnitOfReplicImage?.draw(in: replicationDrawableLiveUnitOfReplicImageBounds);
                        
                        NSGraphicsContext.current?.restoreGraphicsState()
                        
                    }
                }
            }
            else if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .mirror)
            {
                NSGraphicsContext.current?.saveGraphicsState()
                
                let transform = NSAffineTransform.init();
                //                        let ctrdRB = drawableToReplicate.centroidOfRenderbounds;
                let initialX = permanentAnchorPoint.x//ctrdRB.x;
                let initialY = permanentAnchorPoint.y//ctrdRB.y;
                
                transform.translateX(by: initialX, yBy: initialY)
                transform.scaleX(by: 1.0, yBy: -1.0)
                transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
                
                if (mirrorDegreesRotation != 0)
                {
                    transform.translateX(by: initialX, yBy: initialY)
                    transform.rotate(byDegrees: 2 * mirrorDegreesRotation)
                    transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
                }
                
                transform.concat()
                
                replicationDrawableLiveUnitOfReplicImage?.draw(in: replicationDrawableLiveUnitOfReplicImageBounds);
              
                
                NSGraphicsContext.current?.restoreGraphicsState()
                
                  
                if(numberOfMirrors == 2)
                {
                    NSGraphicsContext.current?.saveGraphicsState()
                    
                    let transform2 = NSAffineTransform.init();
                    
                    transform2.translateX(by: initialX, yBy: initialY)
                    transform2.scaleX(by: -1.0, yBy: 1.0)
                    transform2.translateX(by: -1 * initialX, yBy: -1 * initialY)
                    
                    if (mirrorDegreesRotation != 0)
                    {
                        transform2.translateX(by: initialX, yBy: initialY)
                        transform2.rotate(byDegrees: 2 * mirrorDegreesRotation)
                        transform2.translateX(by: -1 * initialX, yBy: -1 * initialY)
                    }
                    
                    transform2.concat()

                    replicationDrawableLiveUnitOfReplicImage?.draw(in: replicationDrawableLiveUnitOfReplicImageBounds);
                    
                    NSGraphicsContext.current?.restoreGraphicsState()
                    
                    
                    
                    
                    NSGraphicsContext.current?.saveGraphicsState()
                    
                    let transform3 = NSAffineTransform.init();
                    
                    transform3.translateX(by: initialX, yBy: initialY)
                    transform3.scaleX(by: -1.0, yBy: -1.0)
                    transform3.translateX(by: -1 * initialX, yBy: -1 * initialY)
                    
                    /*
                    if (mirrorDegreesRotation != 0)
                    {
                        transform3.translateX(by: initialX, yBy: initialY)
                        transform3.rotate(byDegrees: 2 * mirrorDegreesRotation)
                        transform3.translateX(by: -1 * initialX, yBy: -1 * initialY)
                    }*/
                    
                    transform3.concat()

                    replicationDrawableLiveUnitOfReplicImage?.draw(in: replicationDrawableLiveUnitOfReplicImageBounds);
                    
                    NSGraphicsContext.current?.restoreGraphicsState()
                    
                    
                    
                    
                }
                
                
            }
            
            // MARK: twoDimensional
            else if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .twoDimensional)
            {
            
            
                for currentRow : Int in stride(from: 0, to: replicate2DHorizontalRepeatCount, by: 1)
                {
                    
                    for currentColumn : Int in stride(from: 0, to: replicate2DVerticalRepeatCount, by: 1)
                    {
                        
                        let transform = NSAffineTransform.init();
                    
                        NSGraphicsContext.current?.saveGraphicsState()
                        transform.translateX(by: CGFloat(currentColumn) * replicationFrame.width , yBy: CGFloat(currentRow) * replicationFrame.height)
                        transform.concat()
                        replicationDrawableLiveUnitOfReplicImage?.draw(in: replicationDrawableLiveUnitOfReplicImageBounds);
                        
                        NSGraphicsContext.current?.restoreGraphicsState()
                        
                        
                    }
                    
                    
                }
                
            
            }
    
            //replicationDrawableLiveUnitOfReplicImageBounds.frame(withWidth: 5, using: NSCompositingOperation.sourceOver)
        }
        else
        {
        
        }
    }
    
    
    
     // MARK: WHORL
     @IBOutlet var whorlPhyllotaxisView : PhyllotaxisView?
    var isFixedCircleRadius : Bool = true;
 
    
    
    
    // MARK: MAKE REPLICATION DRAWABLE
    func replicatedFMDrawable(_ drawable :  FMDrawable, replicationMode: ReplicationMode) -> [FMDrawable]
    {
        var arrayOfRepeated : [FMDrawable] = []
        
        // MARK: radial
        if(replicationMode == .radial)
        {
            
            for currentAngle : CGFloat in stride(from: startAngle, to: endAngle, by: angleIntervalForReplication)
            {
              //  print(currentAngle)
            
                let fmDrawable2 = drawable.copy() as! FMDrawable
                
                let transform = NSAffineTransform.init();
                //                        let ctrdRB = drawableToReplicate.centroidOfRenderbounds;
                let initialX = permanentAnchorPoint.x//ctrdRB.x;
                let initialY = permanentAnchorPoint.y//ctrdRB.y;
                
                transform.translateX(by: initialX, yBy: initialY)
                transform.rotate(byDegrees: currentAngle)
                transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
                fmDrawable2.transform(using: transform as AffineTransform)
                
                arrayOfRepeated.append(fmDrawable2)
                
             
            }
            
            
        }
        // MARK: two dimensional
        else if (replicationMode == .twoDimensional)
        {
            
            for currentRow : Int in stride(from: 0, to: replicate2DHorizontalRepeatCount, by: 1)
            {
                
                for currentColumn : Int in stride(from: 0, to: replicate2DVerticalRepeatCount, by: 1)
                {
                    
                    let fmDrawable2 = drawable.copy() as! FMDrawable
                    
                    let transform = NSAffineTransform.init();
                    
                    transform.translateX(by: CGFloat(currentColumn) * replicationFrame.width , yBy: CGFloat(currentRow) * replicationFrame.height)
                    
                    fmDrawable2.transform(using: transform as AffineTransform )
                    
                    arrayOfRepeated.append(fmDrawable2)
                    
                    
                }
                
                
            }
       
        }
        
        // MARK: mirror
        else if(replicationMode == .mirror)
        {
            arrayOfRepeated.append(drawable.copy() as! FMDrawable);
            
            let fmDrawable2 = drawable.copy() as! FMDrawable
            
            var transform = NSAffineTransform.init();
            //                        let ctrdRB = drawableToReplicate.centroidOfRenderbounds;
            let initialX = permanentAnchorPoint.x//ctrdRB.x;
            let initialY = permanentAnchorPoint.y//ctrdRB.y;
            
            transform.translateX(by: initialX, yBy: initialY)
            transform.scaleX(by: 1.0, yBy: -1.0)
            transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
            fmDrawable2.transform(using: transform as AffineTransform)
           
           
             let transform2 = NSAffineTransform.init();
            transform2.translateX(by: initialX, yBy: initialY)
            transform2.rotate(byDegrees: 360 - (2 * mirrorDegreesRotation))
            transform2.translateX(by: -1 * initialX, yBy: -1 * initialY)
            fmDrawable2.transform(using: transform2 as AffineTransform)
           
           
            arrayOfRepeated.append(fmDrawable2)
            
            if(numberOfMirrors == 2)
            {
              
                
                let fmDrawable3 = drawable.copy() as! FMDrawable
                transform = NSAffineTransform.init();
                
                transform.translateX(by: initialX, yBy: initialY)
                transform.scaleX(by: -1.0, yBy: 1.0)
                transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
                fmDrawable3.transform(using: transform as AffineTransform)
                
                if(mirrorDegreesRotation != 0)
                {
                    let transformRotate = NSAffineTransform.init();
                    transformRotate.translateX(by: initialX, yBy: initialY)
                    transformRotate.rotate(byDegrees: 360 - (2 * mirrorDegreesRotation))
                    transformRotate.translateX(by: -1 * initialX, yBy: -1 * initialY)
                    fmDrawable3.transform(using: transformRotate as AffineTransform)
                }
                
                arrayOfRepeated.append(fmDrawable3)
                
                
                let fmDrawable21 = drawable.copy() as! FMDrawable
                transform = NSAffineTransform.init();
                
                transform.translateX(by: initialX, yBy: initialY)
                transform.scaleX(by: -1.0, yBy: -1.0)
                transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
                fmDrawable21.transform(using: transform as AffineTransform)
                
                
                arrayOfRepeated.append(fmDrawable21)
            
            }
            
            
        }
        // MARK: WHORL
        else if(replicationMode == .whorl)
        {
            
            let ratioFactor : CGFloat = whorlPhyllotaxisView!.ratioFactor;
            let circleRadius : CGFloat = isFixedCircleRadius ? whorlPhyllotaxisView!.radius : drawable.renderBounds().centroid().distanceFrom(point2: permanentAnchorPoint)
            let shapeDepositCount : Int = whorlPhyllotaxisView!.shapeDepositCount;
            let angleForRepetitionDegrees : CGFloat = whorlPhyllotaxisView!.angleForRepetitionDegrees;
            let scalingPosition : CGFloat = whorlPhyllotaxisView!.scalingPosition;
            let loadedObjectScaleFactor : CGFloat = whorlPhyllotaxisView!.loadedObjectScaleFactor;
            
            
            
            let dBoundsCentr = drawable.renderBounds().centroid()

            let startingAngleFromPermanentToObject : CGFloat = NSBezierPath.lineAngleDegreesFrom(point1: permanentAnchorPoint, point2: dBoundsCentr)
            
//            print(startingAngleFromPermanentToObject);
            
            var startingRadiusPt = dBoundsCentr; //NSPoint.distanceBetween(permanentAnchorPoint, dBoundsCentr)
            startingRadiusPt.x = startingRadiusPt.x - permanentAnchorPoint.x;
            startingRadiusPt.y = startingRadiusPt.y - permanentAnchorPoint.y;
            
            for i in 1...shapeDepositCount
            {
                let d = drawable.copy() as! FMDrawable
                d.nctTranslateBy(vector: CGVector.init(dx: -dBoundsCentr.x, dy: -dBoundsCentr.y))
                
                //  let dot_rad = objectScaleFactor *CGFloat(i);
                let ratio = ratioFactor * CGFloat(i) / CGFloat(shapeDepositCount);
                let angle = (CGFloat(i) * deg2rad(angleForRepetitionDegrees));
                let spiralRadius = ratio * circleRadius;
                
                if(spiralRadius > circleRadius)
                {
                    break;
                }
                
                
                
                let x = /*startingRadiusPt.x + */ permanentAnchorPoint.x + cos(startingAngleFromPermanentToObject + angle) * spiralRadius;
                let y = /*startingRadiusPt.y + */ permanentAnchorPoint.y + sin(startingAngleFromPermanentToObject + angle) * spiralRadius;
                
                let shapeBezierPath = d;
                /*
                // shapeBezierPath.lineWidth = b.lineWidth + 0.01;
                // shapeBezierPath.line(to: NSPoint(x: x, y: y))
                
                
                if(isTriangle)
                {
                    // TRIANGLE
                    shapeBezierPath.move(to: NSPoint.zero)
                    shapeBezierPath.line(to: NSPoint(x: 10, y: 0))
                    shapeBezierPath.line(to: NSPoint(x: 5, y: 10))
                    shapeBezierPath.close();
                }
                else
                {
                    
                    // ROUNDED RECTANGLE
                    shapeBezierPath.appendRoundedRect(NSMakeRect(0, 0, 10, 10), xRadius: 2, yRadius: 2)
                    
                }*/
                
                // CIRCLE
                //shapeBezierPath.appendArc(withCenter: NSPoint(x: 0, y: 0), radius: 3, startAngle: 0, endAngle: 360)
                
                let shapeBezierBounds = d.renderBounds();
                
                
                
                // MARK: rotateTransform
                var affineTransformScaleRotate = AffineTransform();
                
                affineTransformScaleRotate.translate(x: -shapeBezierBounds.midX, y: -shapeBezierBounds.midY)
                affineTransformScaleRotate.rotate(byRadians: angle);
                affineTransformScaleRotate.scale( abs(scalingPosition - (loadedObjectScaleFactor * spiralRadius / circleRadius)) )
                affineTransformScaleRotate.translate(x: shapeBezierBounds.midX, y: shapeBezierBounds.midY)
                
                shapeBezierPath.transform(using: affineTransformScaleRotate);
                
                
                
                
                
                // MARK: translateTransform
                var affineTransformTranslate = AffineTransform();
                affineTransformTranslate.translate(x: x , y: y);
                
                // affineTransformTranslate.translate(x: x - dot_rad / 2, y: y - dot_rad / 2);
                shapeBezierPath.transform(using: affineTransformTranslate);
                
                
                arrayOfRepeated.append(shapeBezierPath)
                
                /*
                NSColor(calibratedRed: 0.8, green: 0.5, blue: CGFloat(i) / CGFloat(shapeDepositCount), alpha: 1).setFill()
                shapeBezierPath.fill();
                
                NSColor.black.setStroke();
                
                
                shapeBezierPath.stroke();*/
                //   if (i < 800){fill('#a6cf02');}
                //  else if (i < 1300){fill('#4ba41a');}
                //   else {fill('#229946');}
                
            }
            
            
        }
        
        
        return arrayOfRepeated;
        
    }
    
    
    func makeReplicationDrawable(_ drawable : FMDrawable, isLive: Bool) -> FMDrawable
    {
        
        
        let drawableToReplicate = drawable;
        
        var arrayOfReplicationResults : [FMDrawable] = [];
        
        var referenceSize : NSSize = NSSize.zero
        
        
        /*
         referenceSize.width = (useBoundsAsReferenceForRepetition) ? referenceSize.width + oneDimensionalReplicationSpacing : oneDimensionalReplicationSpacing;
         referenceSize.height = (useBoundsAsReferenceForRepetition) ? referenceSize.height + oneDimensionalReplicationSpacing : oneDimensionalReplicationSpacing;
         */
        
        if(addStrokeWidthToSpacing)
        {
            referenceSize.width += drawable.lineWidth;
            referenceSize.height += drawable.lineWidth;
        }
        
        
        
        let drawableCopy =  drawableToReplicate.copy() as! FMDrawable
        drawableToReplicate.removeAllPoints();
        
        arrayOfReplicationResults.append(drawableToReplicate);
        
        // MARK: ONE DIMENSIONAL REPLICATION
        if(replicationMode == .oneDimensional)
        {
            if(produceGroupDrawable == false)
            {
                drawableToReplicate.append(drawableCopy);
            }
            else
            {
                arrayOfReplicationResults.append(drawableCopy.copy() as! FMDrawable)
            }
            
            var distanceTraveled : CGFloat = 0;
            
            for _ : Int in stride(from: 0, to: oneDimensionalReplicationCount, by: 1)
            {
                distanceTraveled += oneDimensionalReplicationSpacing
                
                let affineTranslation = AffineTransform(translationByX: (referenceSize.width + oneDimensionalReplicationSpacing) * cos(replicationAngleRadiansCached), byY:  (referenceSize.height + oneDimensionalReplicationSpacing) * sin(replicationAngleRadiansCached));
                
                drawableCopy.transform(using: affineTranslation);
                
                if(produceGroupDrawable == false)
                {
                    drawableToReplicate.append(drawableCopy);
                }
                else
                {
                    arrayOfReplicationResults.append(drawableCopy.copy() as! FMDrawable)
                    
                }
                
                
            }
            
        }// END  if(replicationMode == .oneDimensional)
        
        
        // compounds radial replication
        // to linear replication
        //let addRadial = false;
        
        // MARK: RADIAL REPLICATION
        if(replicationMode == .radial)// || (addRadial))
        {
            
            /*
             if(addRadial)
             {
             drawableCopy.removeAllPoints();
             drawableCopy.append(drawableToReplicate);
             }*/
            
            
          //  if(lastReplicationAnchorPoint == NSNotFoundPoint)
          //  {
           //     lastReplicationAnchorPoint = drawableCopy.pointAtIndex(0);
              //  print(lastReplicationAnchorPoint)
                // replicateByAngleDistanceOffset
                
            //}
            
         
                let rotationPoint = permanentAnchorPoint
                
                
                drawableToReplicate.append(drawableCopy);
                
                
                
                for _ /*currentAngle*/ : CGFloat in stride(from: angleIntervalForReplication, through: 360, by: angleIntervalForReplication)
                {
                    
                    let affineTranslation = AffineTransform(translationByX: replicateByAngleDistanceOffset * cos(deg2rad(angleIntervalForReplication)), byY:  replicateByAngleDistanceOffset * sin(deg2rad(angleIntervalForReplication)));
                    
                    drawableCopy.transform(using: affineTranslation);
                    
                    
                    drawableCopy.rotateFrom(pointLocation: FMDrawable.TransformPoint.passedParameter, point: rotationPoint, angle: angleIntervalForReplication)
                    
                    if(produceGroupDrawable == false)
                    {
                        drawableToReplicate.append(drawableCopy);
                    }
                    else
                    {
                        arrayOfReplicationResults.append(drawableCopy)
                    }
                    
                }
                
                
                //let interval
                /*
                 for y : Int in stride(from: 0, to: verticalRepeatCount, by: 1)
                 {
                 let affineTranslation = AffineTransform(translationByX: 0, byY: referenceSize.height + verticalSpacing);
                 
                 drawableCopy.transform(using: affineTranslation);
                 
                 if(produceGroupDrawable == false)
                 {
                 drawableToReplicate.append(drawableCopy);
                 }
                 else
                 {
                 arrayOfReplicationResults.append(drawableCopy)
                 }
                 
                 
                 }*/
            
            
            
            
            
        }// END else if(replicationMode == .radial)
        
        
        // MARK: TWO DIMENSIONAL REPLICATION
        if(replicationMode == .twoDimensional)
        {
            
            
        }
        
        
        /*
         if(produceGroupDrawable)
         {
         return (GroupDrawable(array: arrayOfReplicationResults));
         
         }
         else
         {
         */
        
        return drawableToReplicate;
        //}
        
        
        //  return drawable;
    }
    
    
    /*
    // called by each drawing entity
    func drawOverlayForLiveReplication()
    {
    
        
    }
    
    */
  //  func drawForActivePenLayer()
 //   {
        
    
  //  }
  
  
    // MARK: GUIDELINES
    
    func updateGuidelinesRectRedisplayForTurnOff()
    {
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayer)
        {
            var updateRect = replicationGuidesBezierPathOldRect
        
            if(replicationGuidesBezierPath.isEmpty == false)
            {
                updateRect = replicationGuidesBezierPathOldRect.union(replicationGuidesBezierPath.bounds)
                
            }
        
            lineWorkInteractionEntity!.activePenLayer!.setNeedsDisplay(updateRect);
        }
        
        
        
    }
    
    func updateGuidelines()
    {
    
        guard  lineWorkInteractionEntity!.currentPaperLayer != nil else {
            return
        }
    
        if(replicationGuidesBezierPath.isEmpty == false)
        {
            replicationGuidesBezierPathOldRect = replicationGuidesBezierPath.bounds;
        }
    
        replicationGuidesBezierPath.removeAllPoints();
        
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayer)
        {
            lineWorkInteractionEntity!.activePenLayer!.setNeedsDisplay(replicationGuidesBezierPathOldRect);
        }
        

        let aRect1 = NSRect.init(origin: .zero, size: NSMakeSize(10, 10)).centerOnPoint(permanentAnchorPoint)
        replicationGuidesBezierPath.appendRect(aRect1)
        let aRect2 = NSRect.init(origin: .zero, size: NSMakeSize(15, 15)).centerOnPoint(permanentAnchorPoint)
        replicationGuidesBezierPath.appendRect(aRect2)
        
        let b = lineWorkInteractionEntity!.currentPaperLayer!.bounds


        if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .radial)
        {
            
            for currentAngle : CGFloat in stride(from: startAngle, through: endAngle, by: angleIntervalForReplication)
            {
                
                replicationGuidesBezierPath.move(to: permanentAnchorPoint)
                replicationGuidesBezierPath.relativeLineToByAngle(angle: currentAngle, length: b.width)
                
            }
            
            
            
        }
        
        if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .mirror)
        {
                    
                    

            replicationGuidesBezierPath.move(to: permanentAnchorPoint)
            replicationGuidesBezierPath.relativeLineToByAngle(angle: 360 - ( mirrorDegreesRotation), length: b.maxLength())
            replicationGuidesBezierPath.move(to: permanentAnchorPoint)
            replicationGuidesBezierPath.relativeLineToByAngle(angle: 360 - ( mirrorDegreesRotation) + 180, length: b.maxLength())
            
            if(numberOfMirrors == 2)
            {
                replicationGuidesBezierPath.move(to: permanentAnchorPoint)
                replicationGuidesBezierPath.relativeLineToByAngle(angle: 360 - ( mirrorDegreesRotation) + 90, length: b.maxLength())
                replicationGuidesBezierPath.move(to: permanentAnchorPoint)
                replicationGuidesBezierPath.relativeLineToByAngle(angle: 360 - ( mirrorDegreesRotation) + 180 + 90, length: b.maxLength())
            }
            
            //            replicationGuidesBezierPath.move(to: permanentAnchorPoint)
            //            replicationGuidesBezierPath.relativeLineToByAngle(angle: 90 + mirrorDegreesRotation, length: b.height)
            

            
        }
        
        
        if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .twoDimensional)
        {
        
            replicationGuidesBezierPath.move(to: permanentAnchorPoint)
            replicationGuidesBezierPath.relativeLineToByAngle(angle: 360 - ( mirrorDegreesRotation), length: b.maxLength())
            replicationGuidesBezierPath.move(to: permanentAnchorPoint)
            replicationGuidesBezierPath.relativeLineToByAngle(angle: 360 - ( mirrorDegreesRotation) + 180, length: b.maxLength())
            
            var r = replicationFrame;
            r.origin = permanentAnchorPoint;
            replicationGuidesBezierPath.appendRect(r);
        
        }
        
         if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .oneDimensional)
        {
        
            replicationGuidesBezierPath.move(to: permanentAnchorPoint)
            replicationGuidesBezierPath.relativeLineToByAngle(angle: 360 - ( mirrorDegreesRotation), length: b.maxLength())
            replicationGuidesBezierPath.move(to: permanentAnchorPoint)
            replicationGuidesBezierPath.relativeLineToByAngle(angle: 360 - ( mirrorDegreesRotation) + 180, length: b.maxLength())
            
            var r = replicationFrame;
            r.origin = permanentAnchorPoint;
            replicationGuidesBezierPath.appendRect(r);
        
        }
        
        if(replicationGuidesBezierPath.isEmpty == false)
        {
        
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayer)
            {
            lineWorkInteractionEntity!.activePenLayer!.needsDisplay = true;
                //lineWorkInteractionEntity!.activePenLayer!.setNeedsDisplay(replicationGuidesBezierPath.bounds);
            }
            else
            {
            
            }
        }
    
    }
    
    var drawReplicationGuidesIsOn : Bool = true;
    var replicationGuidesBezierPath : NSBezierPath = NSBezierPath();
    var replicationGuidesBezierPathOldRect : NSRect = .zero
    
    func drawReplicationGuides()
    {

/*
        let anchorRect = NSRect.init(origin: .zero, size: NSMakeSize(10, 10)).centerOnPoint(permanentAnchorPoint);
        NSColor.purple.setFill();
        let anchorRect2 = NSRect.init(origin: .zero, size: NSMakeSize(15, 15)).centerOnPoint(permanentAnchorPoint);
        
        anchorRect.frame(withWidth: 3, using: NSCompositingOperation.sourceOver)
        anchorRect2.frame(withWidth: 1, using: NSCompositingOperation.sourceOver)
*/

        if(drawReplicationGuidesIsOn)
        {

            NSColor.purple.setStroke();
        
            if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .radial)
            {
                replicationGuidesBezierPath.stroke()

            }
            if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .mirror)
            {
                replicationGuidesBezierPath.stroke()

            }
            if(lineWorkInteractionEntity!.inkAndLineSettingsManager!.replicationMode == .twoDimensional)
            {
                replicationGuidesBezierPath.stroke()

            }
        
        }

                
    }
    
    override func awakeFromNib() {

            replicationPopover.animates = false;
            replicationPopover.behavior = NSPopover.Behavior.transient
            
    }
    
    func loadSettings(dict : Dictionary<String,Any>?)
    {
    
        useBoundsAsReferenceForRepetition = true;
        addStrokeWidthToSpacing = true;
        oneDimensionalReplicationCount = 5;
        oneDimensionalReplicationSpacing = 50;
        oneDimReplicationAngle = 0.0;
    
        angleIntervalForReplication = 90.0;
        replicateByAngleDistanceOffset = 0.0;
        
        // replication frame
        replicationFrame = NSMakeRect(0, 0, 200, 100);
        
        // mirror
        mirrorDegreesRotation = 0;
        numberOfMirrors = 1;
        
        // Two D
        twoDUsesReplicationFrameBounds = true;
        
        replicate2DVerticalRepeatCount = 7;
        replicate2DVerticalSpacing = 5.0;
        
        replicate2DHorizontalRepeatCount = 7;
        replicate2DHorizontalSpacing = 5.0;
        
    }
}
