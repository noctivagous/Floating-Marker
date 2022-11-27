//
//  InkAndLineSettingsManager.swift
//  Floating Marker
//
//  Created by John Pratt on 1/10/21.
//

import Cocoa
import PencilKit
import GameplayKit.GKNoise

 enum NCTWidthPaletteMode : String {
        case strokeWidths = "Brush Tip Width Palette:" // default, no modifier
        case grayscaleStrokeColors = "Grayscale:" // Control
        case shadesOfCurrentStrokeColor = "Shades of Current Color:" // Shift
        case tintsOfCurrentStrokeColor = "Tints of Current Color:" // Option
        case tonesOfCurrentStrokeColor = "Tones of Current Color:" // Option + Shift
        case basicHuesStrokeColors = "Basic Hues:" // Control + Option
        
        // for changes in hue, brightness, and saturation of the current color:
        // such as to get a different green
        case currentColorVariations = "Current Color Variations:" // Control + Shift

    }
    
enum NCTCornerRoundingType : Int{
    case arc
    case bSpline
    case bevel
    
    init(rawString:String)
    {
        //var a = NCTCornerRoundingType.bSpline
        
        switch rawString {
        case "arc":
            self = NCTCornerRoundingType.arc
        case "bSpline":
            self = NCTCornerRoundingType.bSpline
            case "bevel":
            self = NCTCornerRoundingType.bevel
        default:
            self = NCTCornerRoundingType.arc
        }
        

        
    }
    
    var stringValue : String
    {
        switch self {
        case .arc:
            return "arc"
        case .bSpline:
            return "bSpline"
        case .bevel:
            return "bevel"
       
        }
    }
    
}
    
class InkAndLineSettingsManager: NSWindowController, PaletteSegmentedControlSegmentPropertyDelegate {

    @IBOutlet var appDelegate : AppDelegate?

    @IBOutlet var inputInteractionManager : InputInteractionManager?
    
//    @IBOutlet var colorPalettePanel : NSPanel!;

    @IBOutlet var lineWorkInteractionEntity: LineWorkInteractionEntity?

    @IBOutlet var brushTipWidthPaletteSegmentedControl : NCTSegmentedControl!

    @IBOutlet var shapeInQuadDrawingEntity : ShapeInQuadDrawingEntity?
    @IBOutlet var rectangleDrawingEntity : RectangleDrawingEntity?
    @IBOutlet var ellipseDrawingEntity : EllipseDrawingEntity?


    @IBOutlet var noiseConfigurationViewController : NoiseConfigurationViewController?

    var appliesToEntireStroke : Bool = false
    {
        didSet
        {
            appliesToCurrentPointOrEntireStrokeNCTSegmCont.selectedSegment = appliesToEntireStroke ? 1 : 0;
        }
    }
    @IBOutlet var appliesToCurrentPointOrEntireStrokeNCTSegmCont : NCTSegmentedControl!
    @IBAction func changeAppliesToEntireStroke(_ sender : NCTSegmentedControl)
    {
        appliesToEntireStroke = (sender.selectedSegment == 0) ? false : true
        
    }
   
   
    @IBOutlet var labelForWidthPaletteSegmControl : NSTextField?
    
    
    // MARK: -
    // MARK: usesAlternatePalettes
   
    var usesAlternatePalettes : Bool = false
    {
        didSet
        {
            useAlternatePalettesSegm?.selectedSegment = usesAlternatePalettes.onOffSwitchInt;

            if((oldValue == true) && (usesAlternatePalettes == false))
            {
                modeForWidthPaletteSegmControl = .strokeWidths;
            }
        
        }
    }
    
    @IBOutlet var useAlternatePalettesSegm : NCTSegmentedControl?
    
    @IBAction func changeUsesAlternatePalettes(_ sender : NCTSegmentedControl)
    {
        usesAlternatePalettes = sender.onOffSwitchBool;
    }
    

    var modeForWidthPaletteSegmControl : NCTWidthPaletteMode = .strokeWidths
    {
        didSet
        {
            if((usesAlternatePalettes == false) && (modeForWidthPaletteSegmControl != .strokeWidths))
            {
                modeForWidthPaletteSegmControl = .strokeWidths;
            }
        
            labelForWidthPaletteSegmControl?.stringValue = modeForWidthPaletteSegmControl.rawValue;
        
        }
    }
  
    // MARK: -
    // MARK: usesPushPullRelToPaletteKeys
    
    var aggregatedSettingCurrent : FMDrawableAggregratedSettings = .init(fmDrawable: FMDrawable.init())
    
    var aggregatedSetting : FMDrawableAggregratedSettings
    {
        set
        {
            aggregatedSettingCurrent = newValue;
            
            var d = lineWorkInteractionEntity!.currentFMStroke as FMDrawable
            newValue.applyToDrawable(fmDrawable: &d)

            currentStrokeColor = aggregatedSettingCurrent.fmInk.mainColor;
            
             
            //self.fmInk = newValue.fmInk;
            self.fmInk.mainColor = aggregatedSettingCurrent.fmInk.mainColor
            self.fmInk.secondColor = aggregatedSettingCurrent.fmInk.secondColor
            self.fmInk.representationMode = aggregatedSettingCurrent.fmInk.representationMode
            lineWorkInteractionEntity!.updateFMInk(fmInk)
            
            self.currentLineDash = newValue.lineDash();
            self.bezierPathStrokeWidthCurrent = newValue.lineWidth;
            self.uniformTipLineCapStyleCurrent = newValue.lineCapStyle
            self.uniformTipLineJoinStyleCurrent = newValue.lineJoinStyle;
            
            brushTipWidthPaletteSegmentedControl.needsDisplay = true;
            
         
        }
        
        get
        {
            let fmDA = FMDrawableAggregratedSettings.init(fmInk: self.fmInk, lineWidth: self.bezierPathStrokeWidthCurrent, lineJoinStyle: uniformTipLineJoinStyleCurrent, lineCapStyle: uniformTipLineCapStyleCurrent, miterLimit: 1.0, lineDashCount: currentLineDash.count, lineDashPattern: currentLineDash.pattern, lineDashPhase: currentLineDash.phase);
            
            return fmDA;
        }
        
    }
    
    var usesPushPullRelToPaletteKeys : Bool = false
    {
        didSet
        {
            usesPushPullRelToPaletteKeysSegm?.selectedSegment = usesPushPullRelToPaletteKeys.onOffSwitchInt;
            updatePullPushRelToPaletteVisibility()
        }
    }
    
    @IBOutlet var usesPushPullRelToPaletteKeysSegm : NCTSegmentedControl?
    
    @IBAction func changeUsesPushPullRelToPaletteKeys(_ sender : NCTSegmentedControl)
    {
        usesPushPullRelToPaletteKeys = sender.onOffSwitchBool;
    }
    
   
//    @IBOutlet var colorPaletteSegmentedControl : NCTSegmentedControl!
   
    // MARK: -
    
    var currentPaperLayer : PaperLayer?
    {
        return self.currentFMDocument?.drawingPage.currentPaperLayer
    }
    
    var currentFMDocument : FMDocument?
    {
        get{
        
            return NSDocumentController.shared.currentDocument as? FMDocument;
        }
    }
    
    var allFMDocuments : [FMDocument]?
    {
        get{
        
            return NSDocumentController.shared.documents as? [FMDocument]
        }
    }
    
    
    // MARK: -
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: ------- INTERPOLATION
    
    // ------------------------------
    // MARK: ---- distanceForOvalAndChiselLiveInterpolation
    // ------------------------------
    var distanceForOvalAndChiselLiveInterpolation : CGFloat = 10
    {
        didSet
        {
            distanceForOvalAndChiselLiveInterpolationSlider?.setCGFloatValue(distanceForOvalAndChiselLiveInterpolation)
            distanceForOvalAndChiselLiveInterpolationTextField?.setCGFloatValue(distanceForOvalAndChiselLiveInterpolation)
        }
    }
    
    @IBOutlet var distanceForOvalAndChiselLiveInterpolationSlider : NCTSlider?
    
    @IBOutlet var distanceForOvalAndChiselLiveInterpolationTextField : NCTTextField?
    
    @IBAction func changeOvalAndChiselDistanceForLiveInterpolation(_ sender : NSControl)
    {
        distanceForOvalAndChiselLiveInterpolation = sender.cgfloatValue()
    }
    
    
    // ------------------------------
    // MARK: ---- distanceForOvalAndChiselFinalInterpolation
    // ------------------------------
    var distanceForOvalAndChiselFinalInterpolation : CGFloat = 3
    {
        didSet
        {
                distanceForOvalAndChiselFinalInterpolation.formClamp(to: 1.0...50)
                distanceForOvalAndChiselFinalInterpolationSlider?.setCGFloatValue(distanceForOvalAndChiselFinalInterpolation)
                distanceForOvalAndChiselFinalInterpolationTextField?.setCGFloatValue(distanceForOvalAndChiselFinalInterpolation);
        
        }
    }
    @IBOutlet var distanceForOvalAndChiselFinalInterpolationSlider : NCTSlider?
    
    @IBOutlet var distanceForOvalAndChiselFinalInterpolationTextField : NCTTextField?

    @IBAction func changeDistanceForOvalAndChiselFinalInterpolation(_ sender : NSControl)
    {
            distanceForOvalAndChiselFinalInterpolation = sender.cgfloatValue()
    }
    
        // ------------------------------
    // MARK: ---- finalSimplificationToleranceForOvalAndChisel
    // ------------------------------
    let minFinalSimplificationToleranceForOvalAndChisel : CGFloat = 0.1;
    let maxFinalSimplificationToleranceForOvalAndChisel : CGFloat = 10.0;
    
    var finalSimplificationToleranceForOvalAndChisel : CGFloat = 1.0
    {
        didSet
        {
            let min = minFinalSimplificationToleranceForOvalAndChisel;
            let max = maxFinalSimplificationToleranceForOvalAndChisel
            finalSimplificationToleranceForOvalAndChisel.formClamp(to: min...max)

            ovalAndChiselFinalSimplificationTextField?.setCGFloatValue( finalSimplificationToleranceForOvalAndChisel)

            let mapped : CGFloat = mapy(
            n: finalSimplificationToleranceForOvalAndChisel,
            start1: min,
            stop1: max,
            start2: CGFloat(ovalAndChiselFinalSimplificationSlider!.minValue),
            stop2: CGFloat((ovalAndChiselFinalSimplificationSlider!.maxValue)))

            ovalAndChiselFinalSimplificationSlider?.setCGFloatValue(mapped);
            
        }
    }
    @IBOutlet var ovalAndChiselFinalSimplificationSlider : NCTSlider?
    @IBOutlet var ovalAndChiselFinalSimplificationTextField : NCTTextField?

    @IBAction func changeOvalAndChiselSimplificationTolerance(_ sender : NSControl)
    {
        
        if(sender == ovalAndChiselFinalSimplificationTextField)
        {
            finalSimplificationToleranceForOvalAndChisel = sender.cgfloatValue()
        }
        else if(sender == ovalAndChiselFinalSimplificationSlider)
        {
            finalSimplificationToleranceForOvalAndChisel = sender.cgfloatValue() / 10.0;
        }
        
        
    }
    
    
        // ------------------------------
    // MARK: ---- distanceForUniformLiveInterpolation
    // ------------------------------
    var distanceForUniformLiveInterpolation : CGFloat = 1.0



    // ------------------------------
    // MARK: ---- distanceForUniformFinalInterpolation
    // ------------------------------
    var distanceForUniformFinalInterpolation : CGFloat = 1.0
    {
        didSet
        {
        
            distanceForUniformFinalInterpolation.formClamp(to: 1.0...50)
            distanceForFinalUniformInterpolationSlider?.setCGFloatValue(distanceForOvalAndChiselFinalInterpolation)
          distanceForFinalUniformInterpolationTextField?.setCGFloatValue(distanceForOvalAndChiselFinalInterpolation)
        
        }
    }
    @IBOutlet var distanceForFinalUniformInterpolationSlider : NCTSlider?
    @IBOutlet var distanceForFinalUniformInterpolationTextField : NCTTextField?

    @IBAction func changeDistanceForFinalUniformInterpolation(_ sender : NSControl)
    {
        distanceForUniformFinalInterpolation = sender.cgfloatValue();
    }

    // ------------------------------
    // MARK: finalSimplificationToleranceForUniform
    // ------------------------------
    let minFinalSimplificationToleranceForUniform : CGFloat = 0.1;
    let maxFinalSimplificationToleranceUniform : CGFloat = 10.0;
    var finalSimplificationToleranceForUniform : CGFloat = 0.2
    {
        didSet
        {
        
            let min = minFinalSimplificationToleranceForUniform;
            let max = maxFinalSimplificationToleranceUniform
            
            finalSimplificationToleranceForUniform.formClamp(to: min...max)
            
            uniformFinalSimplificationTextField?.setCGFloatValue(finalSimplificationToleranceForUniform )
            
            let mapped : CGFloat = mapy(
                n: finalSimplificationToleranceForUniform,
                start1: min,
                stop1: max,
                start2: CGFloat(uniformFinalSimplificationSlider!.minValue),
                stop2: CGFloat((uniformFinalSimplificationSlider!.maxValue)))
            
            uniformFinalSimplificationSlider?.setCGFloatValue(mapped);
            
        }
    }
    
     @IBOutlet var uniformFinalSimplificationSlider : NCTSlider?
    @IBOutlet var uniformFinalSimplificationTextField : NCTTextField?

    @IBAction func changeUniformFinalSimplificationTolerance(_ sender : NSControl)
    {
        
        if(sender == uniformFinalSimplificationTextField)
        {
        finalSimplificationToleranceForUniform = sender.cgfloatValue();
        }
        else
        {
        finalSimplificationToleranceForUniform = sender.cgfloatValue() / 10.0;
        }
        
    }

    
    // ------------------------------
    // MARK: resetVectorAccuracySettings
    // ------------------------------
    @IBAction func resetVectorAccuracySettings(_ sender : NSControl)
    {
        
        distanceForOvalAndChiselLiveInterpolation = 10.0;
        distanceForOvalAndChiselFinalInterpolation = 3.0;
        finalSimplificationToleranceForOvalAndChisel = 1.0;
        
        distanceForUniformLiveInterpolation = 1.0;
        distanceForUniformFinalInterpolation = 1.0;
        finalSimplificationToleranceForUniform = 0.2;
        
    }
    
    // MARK: -
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: HEIGHT FACTOR
    var heightFactor : CGFloat = 0.2// 0.35
    {
        didSet
        {
            heightFactor.formClamp(to: 0.001...1.0)
            heightTextField?.setCGFloatValue(heightFactor)
            heightSlider?.setCGFloatValue(heightFactor * 100)
           
            lineWorkInteractionEntity?.updateBrushTipSize(width: currentBrushTipWidth, height: currentBrushTipWidth * heightFactor)
           // lineWorkInteractionEntity?.updateCurrentStrokeWidth(width:currentBrushTipWidth)

        }
    }
    
    @IBOutlet var heightSlider : NCTSlider?
    @IBOutlet var heightTextField : NSTextField?
    @IBAction func changeHeight(_ sender : NSControl)
    {
        if(sender == heightTextField)
        {
            heightFactor = sender.cgfloatValue();
        }
        else if(sender == heightSlider)
        {
            heightFactor = sender.cgfloatValue() / 100;
        }
    }
    
     // ---------------------------------------------
    // ---------------------------------------------
    // MARK: FMInk
    
    var currentSelectedFMRepresentationMode : RepresentationMode = .inkColorIsStrokeOnly
    {
        didSet
        {
            
            
        }
        
    }
    
    var fmRepresentationMode : RepresentationMode
    {
        get
        {
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                return currentSelectedFMRepresentationMode
            }
            else
            {
                return self.fmInk.representationMode
            }
        }
        set{
        
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection && (lineWorkInteractionEntity!.lineWorkEntityMode == .idle))
            {
                currentSelectedFMRepresentationMode = newValue;
                
            }
            else
            {
                self.fmInk.representationMode = newValue;
                lineWorkInteractionEntity!.currentFMStroke.fmInk.representationMode = newValue;
                lineWorkInteractionEntity!.syncCurrentFMDrawableToInkSettings();
                lineWorkInteractionEntity!.redisplayCurrentFMDrawable();

            }
            
            updateRepresentationModeSegmCont()
        
            self.brushTipWidthPaletteSegmentedControl.needsDisplay = true;
        
            
        }
       
    }
    
    func updateSelectedRepresentationMode()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            updateRepresentationModeBasedOnSelectionStateForCallbacks(representationMode: currentPaperLayer!.selectedDrawables.first!.fmInk.representationMode)
        }
    }
    
    func updateRepresentationModeSegmCont()
    {
            if(fmRepresentationMode == .inkColorIsStrokeOnly)
            {
                self.representationModeNCTSegmControl?.selectedSegment = 0;
                
                
                paintModeTrayNCTSegm?.frame.size.width = 108.0
                paintModeTrayNCTSegm?.columns = 1;
                paintModeTrayNCTSegm?.setSegmentLabelAtIndex(label: "stroke color", index: 0)
                paintModeTrayNCTSegm?.needsDisplay = true;
                
                
                bezierPathStrokeWidthControlsBox?.frame.origin.x = paintModeTrayNCTSegm!.frame.maxX + 4;
                bezierPathStrokeWidthControlsBox?.isHidden = false;
                
                bezierPathStrokeWidthControlsBox?.needsDisplay = true;
                paintModeTrayNCTSegm?.superview!.needsDisplay = true;
            }
            else if(fmRepresentationMode == .inkColorIsFillOnly)
            {
                self.representationModeNCTSegmControl?.selectedSegment = 1;
                paintModeTrayNCTSegm?.frame.size.width = 457.0
                paintModeTrayNCTSegm?.columns = 5;
                paintModeTrayNCTSegm?.setSegmentLabelAtIndex(label: "fill color", index: 0)
                bezierPathStrokeWidthControlsBox?.isHidden = true;
                bezierPathStrokeWidthControlsBox?.frame.origin.x = paintModeTrayNCTSegm!.frame.maxX + 4;
                bezierPathStrokeWidthControlsBox?.needsDisplay = true;
                paintModeTrayNCTSegm?.superview!.needsDisplay = true;
                //paintModeTrayNCTSegm?.window!.isOpaque = true;
            }
            else if(fmRepresentationMode == .inkColorIsStrokeAndFill)
            {
                self.representationModeNCTSegmControl?.selectedSegment = 2;
                paintModeTrayNCTSegm?.frame.size.width = 497.0
                paintModeTrayNCTSegm?.setSegmentLabelAtIndex(label: "fill/stroke color", index: 0)
                paintModeTrayNCTSegm?.columns = 5;
                
                bezierPathStrokeWidthControlsBox?.frame.origin.x = paintModeTrayNCTSegm!.frame.maxX + 4;
                bezierPathStrokeWidthControlsBox?.isHidden = false;
                bezierPathStrokeWidthControlsBox?.needsDisplay = true;
                paintModeTrayNCTSegm?.superview!.needsDisplay = true;
            }
            else if(fmRepresentationMode == .inkColorIsStrokeWithSeparateFill)
            {
                self.representationModeNCTSegmControl?.selectedSegment = 3;
                paintModeTrayNCTSegm?.frame.size.width = 457.0
                paintModeTrayNCTSegm?.setSegmentLabelAtIndex(label: "fill color", index: 0)
                paintModeTrayNCTSegm?.columns = 6;
                
                bezierPathStrokeWidthControlsBox?.frame.origin.x = paintModeTrayNCTSegm!.frame.maxX + 4;
                bezierPathStrokeWidthControlsBox?.isHidden = false;
                bezierPathStrokeWidthControlsBox?.needsDisplay = true;
                paintModeTrayNCTSegm?.superview!.needsDisplay = true;

            }

            chosenPaintModeTrayNCTSegm?.frame.size.width = paintModeTrayNCTSegm!.frame.size.width;
            chosenPaintModeTrayNCTSegm?.segmentLabels = paintModeTrayNCTSegm!.segmentLabels;
            chosenPaintModeTrayNCTSegm?.columns = paintModeTrayNCTSegm!.columns
            paintModeTrayNCTSegm?.needsDisplay = true;
    }
    

    
    func updateRepresentationModeBasedOnSelectionStateForCallbacks(representationMode : RepresentationMode)
    {
        
        fmRepresentationMode = representationMode
        /*
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            currentSelectedFMRepresentationMode = representationMode
                        
        }
        else
        {
            fmRepresentationMode = representationMode
        }*/
        
    }
    
     @IBOutlet var representationModeNCTSegmControl : NCTSegmentedControl?
    
    var useSeparateFill : Bool = false
    
    @IBAction func changeRepresentationMode(_ sender : NCTSegmentedControl)
    {
        if(sender.selectedSegment == 0)
        {
            fmRepresentationMode = .inkColorIsStrokeOnly
        }
        else if(sender.selectedSegment == 1)
        {
            fmRepresentationMode = .inkColorIsFillOnly
        }
        else if(sender.selectedSegment == 2)
        {
           fmRepresentationMode = .inkColorIsStrokeAndFill
        }
        else if(sender.selectedSegment == 3)
        {
            
            fmRepresentationMode = .inkColorIsStrokeWithSeparateFill
        }
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            currentPaperLayer!.makeSelectedBasedOnRepMode(repMode: fmRepresentationMode)
        }

    }
    
    func representationModeForStrokeAndFill() -> RepresentationMode
    {
        if(useSeparateFill)
        {
            return .inkColorIsStrokeWithSeparateFill
        }
        else
        {
            return  .inkColorIsStrokeAndFill
        }
    }
    
   
    
    
    
    // MARK: PAINT MODE TRAY
    
    @IBOutlet var paintModeTrayNCTSegm : NCTSegmentedControl?
    @IBOutlet var chosenPaintModeTrayNCTSegm : NCTSegmentedControl?

    @IBOutlet var paintModeTrayTabView : NSTabView?
    var paintFillModeSelected : PaintFillMode = .solidColorFill
    var paintFillModeCurrent : PaintFillMode = .solidColorFill
    
    var paintFillMode : PaintFillMode
    {

        set
        {

            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                for d in lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables
                {
                    d.fmInk.paintFillMode = newValue;
                }
                
                lineWorkInteractionEntity!.currentPaperLayer!.updateDynamicTreeProxyBoundsForSelectedDrawables()
                lineWorkInteractionEntity!.currentPaperLayer!.redisplaySelectedTotalRegionRect();
            }
            else
            {
                fmInk.paintFillMode = newValue;
                paintFillModeCurrent = newValue
                lineWorkInteractionEntity?.currentFMStroke.fmInk.paintFillMode = newValue
                lineWorkInteractionEntity?.currentMultistateDrawingEntity?.underlayPathForCurrentMode.fmInk.paintFillMode = newValue;
            }
            
            
            paintModeTrayTabView?.selectTabViewItem(at: newValue.rawIntEquiv())
            paintModeTrayNCTSegm?.selectedSegment = newValue.rawIntEquiv()
            
           
        }
    
        get
        {
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                return paintFillModeSelected;
            }
            else
            {
                return lineWorkInteractionEntity!.currentFMStroke.fmInk.paintFillMode;
            }
        
        }
    }
    @IBAction func changeTabToPaintMode(_ sender : NCTSegmentedControl)
    {
        paintFillMode = PaintFillMode.init(rawIntEquiv: sender.selectedSegment)
        //print(paintMode.rawValue)
    }
    
    @IBAction func changeChosenPaintMode(_ sender : NCTSegmentedControl)
    {
        paintFillMode = PaintFillMode.init(rawIntEquiv: sender.selectedSegment)
        //print(paintMode.rawValue)
    }
    
    
    var bezierPathStrokeWidthSelected : CGFloat = 1.0
    {
        didSet
        {
            bezierPathStrokeWidthSelected = bezierPathStrokeWidthSelected.clamped(to: 0.5...maxStrokeWidth)
        }
    }
    
    var bezierPathStrokeWidthCurrent : CGFloat = 1.0
    {
        didSet
        {
            bezierPathStrokeWidthCurrent = bezierPathStrokeWidthCurrent.clamped(to: 0.5...maxStrokeWidth)
            lineWorkInteractionEntity!.currentFMStroke.lineWidth = bezierPathStrokeWidthCurrent;
            if(lineWorkInteractionEntity!.lineWorkEntityMode == .isInLinearDrawing)
            {
                lineWorkInteractionEntity!.redisplayCurrentFMDrawable();
            }
        }
    }

    func updateBezierPathStrokeWidthBasedOnSelectionStateForCallbacks(bezierPathStrokeWidthCGFloat : CGFloat)
    {
        bezierPathStrokeWidthSelected = bezierPathStrokeWidthCGFloat;
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            if(lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables.first!.fmInk.isUniformPathThatIsStrokeOnly)
            {
                self.currentBrushTipWidth = bezierPathStrokeWidthCGFloat;
            }
        
        }
        
        
    }
    
    @IBOutlet var bezierPathStrokeWidthControlsBox : NSBox?
    @IBOutlet var bezierPathStrokeWidthSlider : NCTSlider?
    @IBOutlet var bezierPathStrokeWidthTextField : NCTTextField?
    @IBAction func changeBezierPathStrokeWidth(_ sender : NSControl)
    {
        bezierPathStrokeWidth = sender.cgfloatValue();
    
       
    }
    
    @IBAction func changeBezierPathStrokeWidthFromNCTSegmPicker(_ sender : NCTSegmentedControl)
    {
        bezierPathStrokeWidth = sender.cgfloatValue();
    }
    
    
    func updateBezierPathStrokeWidthControls()
    {
        bezierPathStrokeWidthSlider?.setCGFloatValue(bezierPathStrokeWidth)
        bezierPathStrokeWidthTextField?.setCGFloatValue(bezierPathStrokeWidth)
        
        var lineDashToLoadIntoPopUpButton : LineDash = LineDash.init(dashArray: []);
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            lineDashToLoadIntoPopUpButton = lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables.first!.lineDash();
        
            //print(lD)

        }
        else
        {
            lineDashToLoadIntoPopUpButton = lineDash;
        }
        
        
        
        if ( self.lineDashArraysArray.contains(lineDashToLoadIntoPopUpButton ))
        {
            dashArrayPopUpButton!.selectItem(at: self.lineDashArraysArray.firstIndex(of: lineDashToLoadIntoPopUpButton)!)
        }
        else
        {
            
            if(dashArrayPopUpButton!.menu!.items.count == lineDashArraysArray.count)
            {
                let m = NSMenuItem.init();
                m.representedObject = lineDashToLoadIntoPopUpButton
                m.view = lineDashToLoadIntoPopUpButton.lineDashMenuItemView()
                m.view?.frame = dashArrayPopUpButton!.frame
                dashArrayPopUpButton?.menu?.addItem(m)
            }
            else
            {
                dashArrayPopUpButton!.menu!.removeItem(at: dashArrayPopUpButton!.menu!.items.count - 1)
                
                let m = NSMenuItem.init();
                m.representedObject = lineDashToLoadIntoPopUpButton
                m.view = lineDashToLoadIntoPopUpButton.lineDashMenuItemView()
                m.view?.frame = dashArrayPopUpButton!.frame
                dashArrayPopUpButton?.menu?.addItem(m)
            }
        }
        
    }
    
    
    
    var bezierPathStrokeWidth : CGFloat
    {
        set
        {
            var newValueClamped = newValue.clamped(to: 0.5...maxStrokeWidth)
            newValueClamped = newValueClamped.reduceScale(to: 1)
            
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                let oldRect = lineWorkInteractionEntity!.currentPaperLayer!.selectionTotalRegionRectExtendedRenderBounds();
                
                bezierPathStrokeWidthSelected = newValueClamped;
                for d in lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables
                {
                    d.lineWidth = bezierPathStrokeWidthSelected
                }
                
                
                lineWorkInteractionEntity!.currentPaperLayer!.updateDynamicTreeProxyBoundsForSelectedDrawables()
                let newRect = lineWorkInteractionEntity!.currentPaperLayer!.selectionTotalRegionRectExtendedRenderBounds();
                lineWorkInteractionEntity!.currentPaperLayer!.setNeedsDisplay(oldRect.union(newRect));
                
            }
            else
            {
                bezierPathStrokeWidthCurrent = newValueClamped
            }
        
           updateBezierPathStrokeWidthControls()
           
            DispatchQueue.main.async
            {
                self.brushTipWidthPaletteSegmentedControl.needsDisplay = true;
            }
        
        }
        
        get
        {
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                return bezierPathStrokeWidthSelected;
            }
            else
            {
                
                return lineWorkInteractionEntity!.currentlyDrawnObjectForLineWorkMode?.lineWidth ?? lineWorkInteractionEntity!.currentFMStroke.lineWidth
            }
        
        }
        
    }

    
    var fmBrushTip : FMBrushTip
    {
        set{
            self.fmInk.brushTip = newValue;
            currentFMDocument?.activePenLayer.reconstructCursorBezierPath();
            
            self.lineWorkInteractionEntity?.currentFMDrawable.fmInk.brushTip = newValue;
            self.lineWorkInteractionEntity?.redisplayCurrentlyDrawnObjectForLineWorkMode();
            
        }
        get
        {
            return self.fmInk.brushTip
        }
    }
    
    var fmInk :FMInk = FMInk.init(inkColor: NSColor.black, brushTip: FMBrushTip.rectangle)
     {
        didSet
        {
            lineWorkInteractionEntity?.updateFMInk(fmInk)



            if(oldValue.brushTip != fmInk.brushTip)
            {
                let brushTipRawValue : Int = fmInk.brushTip.rawIntValue();
                brushTipNCTSegmControl?.selectedSegment = brushTipRawValue;
                brushTipNCTSegmControl?.needsDisplay = true;
                
                DispatchQueue.main.async
                {
                    
                    for doc in NSDocumentController.shared.documents
                    {
                        if let fmDoc = doc as? FMDocument
                        {
                            
                            fmDoc.activePenLayer.setupCursor();
                        }
                        
                    }
                    
                    
                }
                
                DispatchQueue.main.async
                {
                    self.brushTipWidthPaletteSegmentedControl.needsDisplay = true;
                }
                
                
            }
        }
    }
    
    func loadFMInkSetting()
    {
        lineWorkInteractionEntity?.updateFMInk(fmInk)
        brushTipNCTSegmControl?.selectedSegment = fmInk.brushTip.rawIntValue();
        brushTipNCTSegmControl?.needsDisplay = true;

    }
    
    
   
    
    
    @IBOutlet var brushTipNCTSegmControl : NCTSegmentedControl?
    
    @IBAction func changeBrushTip(_ sender : NCTSegmentedControl)
    {
        fmBrushTip = FMBrushTip.init(intRaw: sender.selectedSegment) ?? .rectangle;
        
    }
    
  

    
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: AZIMUTH
    @IBOutlet var azimuthTextField : NSTextField?
    @IBOutlet var azimuthCircularSlider : NCTAngularCircularSlider?
    var azimuthRadians : CGFloat = 0
    {
        didSet
        {
            let roundedToDegConversion = round(rad2deg(azimuthRadians))
        
            azimuthTextField?.setCGFloatValue(roundedToDegConversion)
            azimuthCircularSlider?.setCGFloatValue(roundedToDegConversion)
            
            lineWorkInteractionEntity?.updateAzimuth(azimuthRadians)
            
            DispatchQueue.main.async()
            {
                for doc in NSDocumentController.shared.documents
                {
                    if let fmDoc = doc as? FMDocument
                    {
                        fmDoc.docFMWindow.azimuthCircularSlider?.setCGFloatValue(roundedToDegConversion)
                        fmDoc.activePenLayer.setupCursor();
                    }
                    
                }
                
                
            }// END DispatchQueue
           
        }
    }
    var azimuthDegrees : CGFloat
    { get { return rad2deg(azimuthRadians) }
        set{
        
            var valueToCheck = newValue;
            if(valueToCheck < 0)
            {
                valueToCheck = 360 + valueToCheck
            }
            else if(valueToCheck > 360)
            {
                valueToCheck = valueToCheck - 360
            }
        
            let clamped = valueToCheck.clamped(to: 0...360);
            var flooredClamped = round(clamped);
            
            // Removes the 360 degree case
            if(flooredClamped == 360)
            {
                flooredClamped = 0;
            }
            
            azimuthRadians = deg2rad(flooredClamped)
            
        }
    
    }
    
    @IBAction func changeAzimuth(_ sender : NSControl)
    {
    
        let changedAzimuth = sender.cgfloatValue();
        let remainder = round(changedAzimuth).truncatingRemainder(dividingBy: 5.0)
        
        azimuthDegrees = round(changedAzimuth) - remainder
        
    }
    
    
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: ALTITUDE
    @IBOutlet var altitudeTextField : NSTextField?
    @IBOutlet var altitudeCircularSlider : NCTAngularCircularSlider?
    var altitudeRadians : CGFloat = 0
    {
        didSet
        {
          //  altitudeTextField?.setCGFloatValue(round(rad2deg(altitudeRadians)))
          //  altitudeCircularSlider?.setCGFloatValue(round(rad2deg(altitudeRadians)))
            
            lineWorkInteractionEntity?.updateAltitude(altitudeRadians)
            
        }
    }
    var altitudeDegrees : CGFloat
    { get { return rad2deg(altitudeRadians) }
        set{
            var valueToCheck = newValue;
            if(valueToCheck < 0)
            {
                valueToCheck = 360 + valueToCheck
            }
            else if(valueToCheck > 360)
            {
               valueToCheck = valueToCheck - 360
            }
            
            let clamped = newValue.clamped(to: 0...360);
            let flooredClamped = floor(clamped);
            altitudeRadians = deg2rad(flooredClamped)
        }
        
    }
    @IBAction func changeAltitude(_ sender : NSControl)
    {
        altitudeDegrees = sender.cgfloatValue();
    }
 
 
 
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: STROKE WIDTH
    var maxStrokeWidth : CGFloat = 500;
    var maxLayerCount : Int = 20;
    
    // MARK: STARTING STROKE WIDTH
    @IBOutlet var startingStrokeWidthTextField : NSTextField?
    @IBOutlet var startingStrokeWidthStepper : NSStepper?
    var startingStrokeWidth : CGFloat = 5.0
    {
        didSet
        {
            startingStrokeWidthTextField?.setCGFloatValue(startingStrokeWidth)
            startingStrokeWidthStepper?.setCGFloatValue(startingStrokeWidth)
            self.updateCurrentStrokeWidthUsingSelectedSegment()
            
            brushTipWidthPaletteSegmentedControl.needsDisplay = true;
        }
        
    }
    @IBAction func changeStartingStrokeWidth(_ sender : NSControl)
    {
        startingStrokeWidth = sender.cgfloatValue()
        
    }
    
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: COEFFICIENT

    @IBOutlet var coefficientTextField : NSTextField?
    @IBOutlet var coefficientStepper : NSStepper?
    var coefficient :CGFloat = 1.0
    {
        didSet
        {
            coefficientTextField?.setCGFloatValue(coefficient)
            coefficientStepper?.setCGFloatValue(coefficient)
            self.updateCurrentStrokeWidthUsingSelectedSegment()
            brushTipWidthPaletteSegmentedControl.needsDisplay = true;
        }
    }
    @IBAction func changeCoefficient(_ sender : NSControl)
    {
        coefficient = sender.cgfloatValue()
        
    }
    
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: CURRENT STROKE COLOR
    
    var colorBasedOnSelectedOrCurrentStroke : NSColor
    {
        get
        {
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                return currentSelectedColor
            }
            else
            {
                return currentStrokeColor;
            }
        }
        
        set
        {
            updateColorWellBasedOnSelectionState(color: newValue)
           
        }
    }
    
    var currentSelectedColor : NSColor = NSColor.black.usingColorSpace(NSColorSpace.sRGB)!
    {
        didSet
        {
        
            colorwell?.color = currentSelectedColor
            brushTipWidthPaletteSegmentedControl.needsDisplay = true;
            
             // nctColorPickerGridView
            appDelegate?.nctColorPickerGridView.updateSelectedColor()

        }
    
    }
    
    var currentStrokeColor : NSColor = NSColor.black.usingColorSpace(NSColorSpace.sRGB)!
    {
        didSet{
        
            currentStrokeColor = currentStrokeColor.usingColorSpace(NSColorSpace.sRGB)!
            
            fmInk.mainColor = currentStrokeColor;
            brushTipWidthPaletteSegmentedControl.needsDisplay = true;
            
            lineWorkInteractionEntity?.updateFMInk(fmInk)
            colorwell?.color = fmInk.mainColor
            
            // nctColorPickerGridView
            appDelegate?.nctColorPickerGridView.updateSelectedColor()

            
            if(self.lineWorkInteractionEntity!.lineWorkEntityMode != .idle)
            {
                lineWorkInteractionEntity!.redisplayCurrentFMDrawable();
            }

        }
    }
    
    @IBAction func changeCurrentStrokeColor(_ sender : NSColorWell)
    {
    
        updateColorWellBasedOnSelectionState(color: sender.color)
        
        
        
        
    }
    
    @IBOutlet var colorwell : NSColorWell?
    
    /*
    func updateCurrentStrokeColorUsingSelectedSegment()
    {
        
        
        let color = NSColor.init(white: CGFloat(1 + colorPaletteSegmentedControl.selectedSegment) / 10, alpha: 1.0)
   
        updateColorWellBasedOnSelectionState(color: color)
    }*/
    
    func updateColorWellBasedOnSelectionState(color : NSColor)
    {
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            currentSelectedColor = color
            
            currentPaperLayer!.applyColorToSelectedDrawablesTargetTrait(color:currentSelectedColor)
            
        }
        else
        {
            currentStrokeColor = color;
        }
        
    }
    
    func updateColorWellBasedOnSelectionStateForCallbacks(color : NSColor)
    {
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            currentSelectedColor = color
                        
        }
        else
        {
            currentStrokeColor = color;
        }
        
    }
 
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: CURRENT STROKE WIDTH

    @IBOutlet var currentBrushTipWidthTextField : NSTextField?
    
    /*
    var strokeWidthBasedOnSelectedOrCurrentStroke : CGFloat
    {
        get
        {
            return currentSelectedStrokeWidth
            /*
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                return currentSelectedStrokeWidth
            }
            else
            {
                return currentBrushTipWidth;
            }
            */
        }
        
        set
        {
            currentSelectedStrokeWidth = newValue
            //updateStrokeWidthBasedOnSelectionState(strokeWidth: newValue)
        }
    }
    
    var currentSelectedStrokeWidth : CGFloat = 1.0
    {
        didSet
        {
            
            /*
            colorwell?.color = currentSelectedColor
            brushTipWidthPaletteSegmentedControl.needsDisplay = true;
            currentPaperLayer!.applyColorToSelectedDrawablesTargetTrait(color:currentSelectedColor)
            
            currentBrushTipWidth.formClamp(to: 1.0...maxStrokeWidth)
            currentBrushTipWidth = round(currentBrushTipWidth)
            
            // if the current strokeWidth changed as a result of
            // width-modifier keys, then change the selected segment to zero
            // because the currentBrushTipWidth is now custom.
            if((currentBrushTipWidth != brushTipWidthForSegment(brushTipWidthPaletteSegmentedControl.selectedSegment)))
            
            {
                customSlotStrokeWidth = currentBrushTipWidth;
                brushTipWidthPaletteSegmentedControl.selectedSegment = 0;
                
            }
            
            currentBrushTipWidthTextField?.setCGFloatValue(currentBrushTipWidth)
            
            lineWorkInteractionEntity?.updateBrushTipSize(width: currentBrushTipWidth, height: currentBrushTipWidth * heightFactor)
            */
        }
        
    }
    */
    
    var currentBrushTipWidth : CGFloat = 1.0
    {
        didSet
        {
            currentBrushTipWidth.formClamp(to: 1.0...maxStrokeWidth)
            currentBrushTipWidth = round(currentBrushTipWidth)

            // if the current strokeWidth changed as a result of
            // width-modifier keys, then change the selected segment to zero
            // because the currentBrushTipWidth is now custom.
            if((currentBrushTipWidth != brushTipWidthForSegment(brushTipWidthPaletteSegmentedControl.selectedSegment)))
            
            {
                customSlotStrokeWidth = currentBrushTipWidth;
                brushTipWidthPaletteSegmentedControl.selectedSegment = 0;

            }
            
            currentBrushTipWidthTextField?.setCGFloatValue(currentBrushTipWidth)
            
            // -------------
            // when isUniformPathThatIsStrokeOnly
            // then keep the two in sync.
            
            if(self.fmInk.isUniformPathThatIsStrokeOnly)
            {
                self.bezierPathStrokeWidth = currentBrushTipWidth
            }
            
            
            lineWorkInteractionEntity?.updateBrushTipSize(width: currentBrushTipWidth, height: currentBrushTipWidth * heightFactor)

            
            
        }
    }
    /*
    func updateStrokeWidthBasedOnSelectionState(strokeWidth:CGFloat)
    {
        currentBrushTipWidth = strokeWidth;
        /*
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            currentSelectedStrokeWidth = strokeWidth
        }
        else
        {
            currentBrushTipWidth = strokeWidth;
        }
        */
    }
    */
    var currentBrushTipWidthAsCGSize : CGSize
    {
        
        let heightFactorVersion = self.heightFactor * currentBrushTipWidth;
        return CGSize.init(width: currentBrushTipWidth, height: heightFactorVersion /*1.0*/);
    }

    func decreaseStrokeWidthBy(_ decrement : CGFloat)
    {
        let currentHeight = heightFactor * currentBrushTipWidth

        var decrementToUse = decrement
        // cut the decrement in half if
        // the next approaches the minimum
        if((currentBrushTipWidth - decrement) < currentHeight)
        {
            if( (currentBrushTipWidth - (decrement / 2 )) >= currentHeight )
            {
                decrementToUse = decrement / 2;
            }
            else
            {
                heightFactor = 1.0
                currentBrushTipWidth = currentHeight;
                return;
            }
        }
    
  
        let transitionalCurrentStrokeWidth = (currentBrushTipWidth - decrementToUse).clamped(to: 1...maxStrokeWidth);
        
        heightFactor = currentHeight / transitionalCurrentStrokeWidth;
        
        currentBrushTipWidth = transitionalCurrentStrokeWidth;
        
        
    }

    func increaseStrokeWidthBy(_ increment : CGFloat)
    {
        let currentHeight = heightFactor * currentBrushTipWidth
        
        var incrementToUse = increment
        if((currentBrushTipWidth - increment) <= currentHeight)
        {
            incrementToUse = increment / 2;
        }

        
        let transitionalCurrentStrokeWidth = (currentBrushTipWidth + incrementToUse).clamped(to: 1...maxStrokeWidth);
        
        heightFactor = currentHeight / transitionalCurrentStrokeWidth;
        
        currentBrushTipWidth = transitionalCurrentStrokeWidth;
    }
    
    @IBAction func changeCurrentStrokeWidth(_ sender : NSControl)
    {
    
        currentBrushTipWidth = sender.cgfloatValue().clamped(to: 1...maxStrokeWidth)
        
    }
    
   
   
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: CUSTOM SLOT STROKE WIDTH
   
    var customSlotStrokeWidth : CGFloat = 55.0;

   
    func updateCurrentStrokeWidthUsingSelectedSegment()
    {
//        let currentHeight = heightFactor * currentBrushTipWidth;
//        heightFactor = currentHeight / brushTipWidthForSegment(brushTipWidthPaletteSegmentedControl.selectedSegment)
        currentBrushTipWidth = brushTipWidthForSegment(brushTipWidthPaletteSegmentedControl.selectedSegment)
    }

    
    var isExponentialDistribution : Bool = true
    var paletteShiftIndex : CGFloat = 1.0
    {
        didSet
        {
            paletteShiftIndex.formClamp(to: 1.0...10)
            self.brushTipWidthPaletteSegmentedControl.needsDisplay = true;
        }
    }
    var paletteShiftCoefficient : CGFloat = 1.0
  
    
    func brushTipWidthForSegment(_ segmentIndex :Int) -> CGFloat
    {
        if(segmentIndex == 0)
        {
            return customSlotStrokeWidth;
        }
        //var segmentIndex2 = segmentIndex
        //segmentIndex2 += 1;
        //let returnValue = (3 * CGFloat(segmentIndex2)) + startingStrokeWidth//0.5 * pow(startingStrokeWidth, CGFloat(segmentIndex))
        //CGFloat(segmentIndex) * startingStrokeWidth
        //(segmentIndex == 1) ? startingStrokeWidth :  (coefficient * CGFloat(segmentIndex - 1))
    
        var returnValue :CGFloat = 1;
        if(isExponentialDistribution)
        {
         returnValue = (segmentIndex == 1) ? startingStrokeWidth : startingStrokeWidth + (coefficient * pow(CGFloat(segmentIndex),1.65))
         returnValue = floor(returnValue)
        }
        else
        {
            returnValue = (segmentIndex == 1) ? startingStrokeWidth : coefficient * (CGFloat(segmentIndex - 1) * startingStrokeWidth)
        }
        
        
        return min(returnValue, maxStrokeWidth);
    }

    // MARK: Palette Keys Basic Hues Brightness and Saturation

    var basicHuesBrightness : CGFloat = 0.5
    {
        didSet
        {
            basicHuesBrightness = basicHuesBrightness.reduceScale(to: 2)
            basicHuesBrightness = basicHuesBrightness.clamped(to: 0...1.0)
            if(modeForWidthPaletteSegmControl == .basicHuesStrokeColors)
            {
                brushTipWidthPaletteSegmentedControl.needsDisplay = true
            }
        }
    }
    
    var basicHuesSaturation : CGFloat = 0.5
    {
        didSet
        {
            basicHuesSaturation = basicHuesSaturation.reduceScale(to: 2)
            basicHuesSaturation = basicHuesSaturation.clamped(to: 0...1.0)
            if(modeForWidthPaletteSegmControl == .basicHuesStrokeColors)
            {
                brushTipWidthPaletteSegmentedControl.needsDisplay = true
            }

        }
    }

    // MARK: PaletteSegmentedControl delegate methods
    func selectedSegmentDidChange(control: NSControl, segmentIndex: Int)
    {
        if(control == brushTipWidthPaletteSegmentedControl)
        {
        
            switch modeForWidthPaletteSegmControl {
            case .strokeWidths:
                updateCurrentStrokeWidthUsingSelectedSegment()
            default:
                break;
            }

        }
        
        if(control == brushTipNCTSegmControl)
        {
        
        }
        
        /*
        if(control == colorPaletteSegmentedControl)
        {
            updateCurrentStrokeColorUsingSelectedSegment()
        }*/
    }
    
    func drawPaletteSegmentPropertyBackgroundInsideRect(control: NCTSegmentedControl, rect : NSRect, segmentIndex : Int, segmentLabel: String, isSelected: Bool, isHighlighted: Bool)
    {
    
        if(control == brushTipNCTSegmControl)
        {
            if(segmentIndex == 3)
            {
              
                let p = NSBezierPath.init(roundedRect: rect, xRadius: control.cellCornerRadius, yRadius: control.cellCornerRadius)
                
                NSColor.init(calibratedWhite: 0.1, alpha: 0.8).setFill()
                p.fill()
                
                NSColor.black.setStroke()
                p.stroke()
                
            }
        }
        /*
        if(control == colorPaletteSegmentedControl)
        {
            NSColor.init(white: CGFloat(segmentIndex) / CGFloat(control.segmentCount), alpha: 1.0).setFill()
            rect.fill();
            /*            var rectForColor = rect.insetBy(dx: rect.height * 0.1, dy:  rect.width * 0.1)
            rectForColor.size.width = 0.55 * rect.width;
            
            rectForColor = rectForColor.againstInsideRightEdgeOf(rect, padding: 0.1 * rect.width);
        
           

            NSColor.init(white: CGFloat(segmentIndex) / CGFloat(control.segmentCount), alpha: 1.0).setFill()
            rect.fill();
                
            NSColor.black.setFill()
            rectForColor.frame();*/
        }*/
    }
    
    func drawOnTopOfSegmentedControl(control: NCTSegmentedControl, bounds: NSRect)
    {
    
    
        if(control == brushTipWidthPaletteSegmentedControl)
        {
            if(modeForWidthPaletteSegmControl == .basicHuesStrokeColors)
            {
                var b1 = bounds.insetBy(dx: 5, dy: 2)
                b1.size.height = 15;
                var b2 = b1;
                b2.origin.y = 17;
                let bString = "brightness: \(basicHuesBrightness.percentageString()) - press ↑ ↓"
                
                let sString = "saturation : \(basicHuesSaturation.percentageString()) - press ← →"
                
                bString.drawStringInsideRectWithSFProFontReg(fontSize: 12, textAlignment: NSTextAlignment.left, fontForegroundColor: .white, rect: b2)
                
                sString.drawStringInsideRectWithSFProFontReg(fontSize: 12, textAlignment: NSTextAlignment.left, fontForegroundColor: .white, rect: b1)
              
            }
            
        }
    }
    
    func drawPaletteSegmentPropertyInsideRect(control: NCTSegmentedControl, rect : NSRect, segmentIndex : Int, segmentLabel: String, isSelected: Bool, isHighlighted: Bool)
    {
    
  

        // MARK: representationModeNCTSegmControl
  /*      if(control == representationModeNCTSegmControl)
        {
        
        }
*/
        // MARK: brushTipNCTSegmControl
         if(control == brushTipNCTSegmControl)
        {
        
            // save-restore tag:"clip and shadow for brush tip control"
            NSGraphicsContext.current?.saveGraphicsState()
            let p = NSBezierPath()
            p.appendRect(rect.insetBy(dx: 1, dy: 1))
            p.addClip()
             let shadow = NSShadow()
                shadow.shadowBlurRadius = (brushTipNCTSegmControl!.selectedSegment == segmentIndex) ? 5.0 : 3.0;
                shadow.shadowOffset = NSSize(width: 0, height: 0)
                shadow.shadowColor = (brushTipNCTSegmControl!.selectedSegment == segmentIndex) ? NSColor.green : NSColor.white
                
                shadow.set()
              
            if(segmentIndex == 3)
            {
                let img = NSImage.init(imageLiteralResourceName: "penUniformPath")
                
                img.draw(in: rect.insetBy(dx: 0.2 * rect.width, dy: -0.5 * rect.height).offsetBy(dx: 0, dy:  0.65 * rect.height))
                
  
            }
            else if(segmentIndex == 2)
            {
                let img = NSImage.init(imageLiteralResourceName: "pen")
                
                img.draw(in: rect.insetBy(dx: 0.2 * rect.width, dy: -0.5 * rect.height).offsetBy(dx: 0, dy:  0.65 * rect.height))
                
  
            }
            else if(segmentIndex == 1)
            {

                
                let img = NSImage.init(imageLiteralResourceName: "rectangleMarker")
                
                img.draw(in: rect.insetBy(dx: 0.1 * rect.width, dy: -0.5 * rect.height).offsetBy(dx: 0.051 * rect.width, dy:  0.65 * rect.height))
            }
            else if(segmentIndex == 0)
            {

                
                let img = NSImage.init(imageLiteralResourceName: "ellipseMarker")
                
                img.draw(in: rect.insetBy(dx: 0.1 * rect.width, dy: -0.5 * rect.height).offsetBy(dx: 0.051 * rect.width, dy:  0.65 * rect.height))
            }
            
            
            // save-restore tag:"clip and shadow for brush tip control"
            NSGraphicsContext.current?.restoreGraphicsState()
            
            
            
            if(isSelected)
            {
                let p2 = NSBezierPath();
                p2.appendRoundedRect(rect, xRadius: control.cellCornerRadius, yRadius: control.cellCornerRadius)
                NSColor.green.setStroke()
                p2.lineWidth = 2;
                p2.stroke()
            }
            
        }

        // MARK: combinatoricsModeNCTSegmentedControl
        if(control == combinatoricsModeNCTSegmentedControl)
        {
            
            //let ctx =
            
            NSGraphicsContext.current?.saveGraphicsState()
            
            
            
            let p = NSBezierPath()
            p.appendRect(rect.insetBy(dx: 1, dy: 1))
            p.addClip()
            let shadow = NSShadow()
            shadow.shadowBlurRadius = (brushTipNCTSegmControl!.selectedSegment == segmentIndex) ? 5.0 : 3.0;
            shadow.shadowOffset = NSSize(width: 0, height: 0)
            shadow.shadowColor = NSColor.red //(brushTipNCTSegmControl!.selectedSegment == segmentIndex) ? NSColor.green : NSColor.red
            
            shadow.set()
            
            if(segmentIndex == 2)
            {
                let img = NSImage.init(imageLiteralResourceName: "unionKbImg")
                
                img.draw(in: rect.insetBy(dx: 5, dy: 0.15 * rect.height).offsetBy(dx: 0, dy: -0.10 * rect.height))

               // img.draw(in: rect.insetBy(dx: 0.2 * rect.width, dy: -0.5 * rect.height).offsetBy(dx: 0, dy:  0.65 * rect.height))
                
                
            }
            else if(segmentIndex == 1)
            {
                
                let img = NSImage.init(imageLiteralResourceName: "intersectionKbImg")
                img.draw(in: rect.insetBy(dx: 5, dy: 0.15 * rect.height).offsetBy(dx: 0, dy: -0.10 * rect.height))
//                img.draw(in: rect.insetBy(dx: 0.1 * rect.width, dy: -0.5 * rect.height).offsetBy(dx: 0.051 * rect.width, dy:  0.65 * rect.height))
            }
            else if(segmentIndex == 0)
            {
                
                let img = NSImage.init(imageLiteralResourceName: "subtractionKbImg")
                
                img.draw(in: rect.insetBy(dx: 5, dy: 0.15 * rect.height).offsetBy(dx: 0, dy: -0.10 * rect.height))

//                img.draw(in: rect.insetBy(dx: 0.1 * rect.width, dy: -0.5 * rect.height).offsetBy(dx: 0.051 * rect.width, dy:  0.65 * rect.height))
            }
            
            
            NSGraphicsContext.current?.restoreGraphicsState()
            //ctx?.restoreGraphicsState()
            
            
            if(isSelected)
            {
                let p2 = NSBezierPath();
                p2.appendRoundedRect(rect, xRadius: control.cellCornerRadius, yRadius: control.cellCornerRadius)
                NSColor.green.setStroke()
                p2.lineWidth = 2;
                p2.stroke()
            }
            
        
        }
        
        // MARK: brushTipWidthPaletteSegmentedControl
        // MARK: NOTE: EACH SUB MODE RETURNS THE FUNCTION
        if(control == brushTipWidthPaletteSegmentedControl)
        {
            
            /*
           
             let clippingPathForRoundedBoundary = NSBezierPath()
             clippingPathForRoundedBoundary.appendRoundedRect(rect.insetBy(dx: 1, dy: 1), xRadius: control.cellCornerRadius, yRadius: control.cellCornerRadius)
             //   NSColor.purple.setStroke()
             //clippingPathForRoundedBoundary.stroke()
             clippingPathForRoundedBoundary.addClip()
             */
            
          
            
            if(modeForWidthPaletteSegmControl != .strokeWidths)
            {
            
                let segCGFloat = CGFloat(segmentIndex);
                let segP = segCGFloat / 10;
                // SHADE ADDS BLACK
                // MARK: shadesOfCurrentStrokeColor
                if(modeForWidthPaletteSegmControl == .shadesOfCurrentStrokeColor)
                {
                    

                
                let fillColor = colorBasedOnSelectedOrCurrentStroke.blended(withFraction: segCGFloat / 10, of: NSColor.black) ?? colorBasedOnSelectedOrCurrentStroke
                
                fillColor.setFill()
                rect.fill()
                if(isSelected)
                {
     //               NSColor.darkGray.setFill()

                }
               
                 let s = "+\(segP.percentageString()) black";
                s.drawStringInsideRectWithSFProFontReg(fontSize: 12, textAlignment: NSTextAlignment.left, fontForegroundColor: .white, rect: rect)
            }
            
            // MARK: grayscaleStrokeColors

            else if(modeForWidthPaletteSegmControl == .grayscaleStrokeColors)
            {
              
                let fillColor = NSColor.init(white: segP, alpha: 1.0);
                
                fillColor.setFill()
                rect.fill()
                
                let s = "\(segP.percentageString()) white";
                s.drawStringInsideRectWithSFProFontReg(fontSize: 12, textAlignment: NSTextAlignment.left, fontForegroundColor: .white, rect: rect)
                
            }
            
            // TINT ADDS WHITE
            // MARK: tintsOfCurrentStrokeColor
            else if(modeForWidthPaletteSegmControl == .tintsOfCurrentStrokeColor)
            {
               let fillColor =  colorBasedOnSelectedOrCurrentStroke.blended(withFraction: segP, of: NSColor.white) ?? colorBasedOnSelectedOrCurrentStroke
                
                fillColor.setFill()
                rect.fill()
                
                 let s = "+\(segP.percentageString()) white";
                s.drawStringInsideRectWithSFProFontReg(fontSize: 12, textAlignment: NSTextAlignment.left, fontForegroundColor: .white, rect: rect)
                
            }
            // TONE ADDS GRAY
            // MARK: tonesOfCurrentStrokeColor
            else if(modeForWidthPaletteSegmControl == .tonesOfCurrentStrokeColor)
            {
                let fillColor =  colorBasedOnSelectedOrCurrentStroke.blended(withFraction: segP, of: NSColor.gray) ?? colorBasedOnSelectedOrCurrentStroke
                
                fillColor.setFill()
                rect.fill()
                
                        let s = "+\(segP.percentageString()) gray";
                s.drawStringInsideRectWithSFProFontReg(fontSize: 12, textAlignment: NSTextAlignment.left, fontForegroundColor: .white, rect: rect)

                
            }
            // Basic Hues for Stroke Colors
            // MARK: basicHuesStrokeColors
            else if(modeForWidthPaletteSegmControl == .basicHuesStrokeColors)
            {
                let fillColor =  NSColor.init(hue: segCGFloat / 10, saturation: basicHuesSaturation, brightness: basicHuesBrightness, alpha: 1.0);
                
                fillColor.setFill()
                rect.fill()
                
                let s = "hue: \(segP.percentageString()) ";
                s.drawStringInsideRectWithSFProFontReg(fontSize: 12, textAlignment: NSTextAlignment.left, fontForegroundColor: .white, rect: rect)
 
               
                
            }




        // MARK: draw number label
            let fontSizeForLabel = 0.50 * min(NSHeight(rect),NSWidth(rect));
            //fontSizeForLabel = max(fontSizeForLabel,20)
            
            NSGraphicsContext.current?.saveGraphicsState()
                let segmentLabelShadow = NSShadow()
                segmentLabelShadow.shadowBlurRadius = 2.0
                segmentLabelShadow.shadowOffset = NSSize(width: 1, height: 0)
                segmentLabelShadow.shadowColor = NSColor.init(white: 0.2, alpha: 1.0)
                
                segmentLabelShadow.set()
                
                
                // isHighlighted ? NSColor.init(calibratedWhite: 0.8, alpha: 1.0) :
                
                segmentLabel.drawStringInsideRectWithMenlo(fontSize: fontSizeForLabel, textAlignment: NSTextAlignment.right, fontForegroundColor: isSelected ? NSColor.white : NSColor.lightGray, rect: rect.offsetBy(dx: -2, dy: 0))
            
            NSGraphicsContext.current?.restoreGraphicsState()
            
            return
            }
            if(isSelected)
            {
                NSColor.green.blended(withFraction: 0.3, of: NSColor.white)?.setFill()
            }
            else if(segmentIndex > 0)
            {
            
                NSColor.white.setFill();

                /*
                if(self.currentStrokeColor.brightnessComponent == 0)
                {
                    NSColor.gray.setFill();
                }
                else
                {
                    
                    //self.currentStrokeColor.grayscaleVersionInvertedNoAlpha.setFill()
                    
                    NSColor.white.setFill();
                }
                */
                
                //            NSColor.gray.setFill()
            }
            else if(segmentIndex == 0)
            {
                NSColor.white.setFill()
            }
            
            
            let p = NSBezierPath();
            
            let g = NSGradient.init(colors: [NSColor.white,NSColor.gray.withAlphaComponent(0.5),NSColor.gray.withAlphaComponent(0.5),NSColor.white], atLocations: [0.0,0.15,0.90,1.0], colorSpace: NSColorSpace.sRGB)
            
            if(segmentIndex == 0)
            {
                p.appendRect(rect)
            }
            else
            {
                p.appendRoundedRect(rect, xRadius: 3, yRadius: 3)
            }
           
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                NSColor.black.setFill()
            }
            
            p.fill()
            p.lineWidth = 2.0
            NSColor.black.setStroke()
            p.stroke()
            g?.draw(in: p, angle: 0)
            g?.draw(in: p, angle: 90)

            //let mPoint = NSPoint.init(x: rect.midX, y: rect.midY);
            
            
           
            
            
            let inset2 = rect.insetBy(dx: 1, dy: 2)
            
            colorBasedOnSelectedOrCurrentStroke.setFill()
            //NSColor.black.setFill()
            //        inset2.frame()
            
            
            var sRectW = min(brushTipWidthForSegment(segmentIndex), inset2.width - 5)
            let strokeWidth = self.brushTipWidthForSegment(segmentIndex);
            
            
            
            var s = (strokeWidth - (floor(strokeWidth)) == 0) ? "\(Int(strokeWidth))pt" : "\(strokeWidth)pt"
            
            if(segmentIndex == 0)
            {
                sRectW = min(customSlotStrokeWidth, inset2.width - 2.5);
                s = "\(customSlotStrokeWidth)pt"
                
            }
            
        
            
            var onePxRect = NSMakeRect(inset2.minX + 5, inset2.minY, sRectW, inset2.height - 4)//.centerInRect(inset2)
            if(sRectW < inset2.width - 5)
            {
                onePxRect.origin.x = inset2.midX - (0.5 * sRectW)
            }
            
            
            NSGraphicsContext.current?.saveGraphicsState()
            let shadowForStrokeWidth = NSShadow()
            shadowForStrokeWidth.shadowBlurRadius = 3.0
            shadowForStrokeWidth.shadowOffset = NSSize(width: 0, height: 0)
            shadowForStrokeWidth.shadowColor = NSColor.white
            shadowForStrokeWidth.set()
           
            // fill if fmInk has fill or isUniformPathThatIsStrokeOnly
            if((self.fmRepresentationMode != .inkColorIsStrokeOnly) || (self.fmInk.isUniformPathThatIsStrokeOnly && (self.fmRepresentationMode == .inkColorIsStrokeOnly)))
            {
                
                if((self.fmInk.isUniformPathThatIsStrokeOnly) && (strokeWidth > 2))
                {
                    var strokeSample = NSBezierPath();
                    strokeSample.move(to: onePxRect.bottomMiddle())
                    strokeSample.line(to: onePxRect.topMiddle())
                    strokeSample.lineWidth = onePxRect.width;
                    self.lineDash.applyLineDashToBezierPath(path: &strokeSample)
                    colorBasedOnSelectedOrCurrentStroke.setStroke();
                    strokeSample.stroke();
                    
                    let pMiddle = NSBezierPath();
                    pMiddle.move(to: onePxRect.bottomMiddle())
                    pMiddle.line(to: onePxRect.topMiddle())
                    pMiddle.lineWidth = 1.0;
                    pMiddle.setLineDash([1,2,1], count: 3, phase: 0)
                    NSColor.gray.setStroke();
                    pMiddle.stroke();
                    
                }
                else
                {
                    onePxRect.fill();
                }
                
                
            }
            
            if((self.fmRepresentationMode == .inkColorIsStrokeOnly) || (self.fmRepresentationMode == .inkColorIsStrokeAndFill) && (self.fmInk.isUniformPathThatIsStrokeOnly == false))
            {
//                onePxRect.frame(withWidth: self.bezierPathStrokeWidth, using: NSCompositingOperation.sourceOver);
                
                var pRect = NSBezierPath();
                pRect.move(to: onePxRect.origin)
                pRect.line(to: onePxRect.topLeft())
                pRect.line(to: onePxRect.topRight())
                pRect.line(to: onePxRect.bottomRight())
                self.lineDash.applyLineDashToBezierPath(path: &pRect)
                
                if(self.fmRepresentationMode != .inkColorIsStrokeOnly)
                {
                pRect.lineWidth = self.bezierPathStrokeWidth;
                }
                else
                {
                pRect.lineWidth = 1.0;
                }
                colorBasedOnSelectedOrCurrentStroke.setStroke()
                pRect.stroke();
                

            }
            
            if((self.fmInk.brushTip == .uniformPath) && (self.fmRepresentationMode == .inkColorIsFillOnly))
            {
                NSColor.gray.setFill()
                rect.fill()
            }
            
            
            NSGraphicsContext.current?.restoreGraphicsState()

            
            var fontSizeForPt = 0.35 * min(NSHeight(inset2),NSWidth(inset2));
            fontSizeForPt = min(fontSizeForPt, 15)
            var strokePtLabelBgRect = inset2
            strokePtLabelBgRect.size.height = fontSizeForPt + 3;
            
            NSColor.lightGray.setFill()
            //NSColor.init(calibratedWhite: 0.9, alpha: 1.0).setFill()
            
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                NSColor.black.setFill()
            }
            
            if(isSelected)
            {
                NSColor.darkGray.setFill()
                
            }
            
            strokePtLabelBgRect.fill();
            
            if((segmentIndex == 0) && (control.selectedSegment == 0))
            {
               let rS = "custom"
               rS.drawStringInsideRectWithSystemFont(fontSize: fontSizeForPt / 1.5, textAlignment: NSTextAlignment.right, fontForegroundColor: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1), rect: rect.insetBy(dx: 0.1 * rect.width, dy: 0.3 * rect.height))
            }
            
            NSGraphicsContext.current?.saveGraphicsState()
                let shadowForSlotNumber = NSShadow()
                shadowForSlotNumber.shadowBlurRadius = 2.0
                shadowForSlotNumber.shadowOffset = NSSize(width: 1, height: -2)
                shadowForSlotNumber.shadowColor = NSColor.darkGray
                
                shadowForSlotNumber.set()
                
                
                
                let fColor : NSColor = isSelected ? NSColor.green : NSColor.white;
                
                if(isSelected)
                {
                  s.drawStringInsideRectWithSFProFontReg(fontSize: fontSizeForPt, textAlignment: NSTextAlignment.center, fontForegroundColor: fColor, rect: strokePtLabelBgRect)
                }
                else
                {
                s.drawStringInsideRectWithSFProFont(fontSize: fontSizeForPt, textAlignment: NSTextAlignment.center, fontForegroundColor: fColor, rect: strokePtLabelBgRect)
                }
            NSGraphicsContext.current?.restoreGraphicsState()
            
            
            // MARK: draw number label
            let fontSizeForLabel = 0.30 * min(NSHeight(rect),NSWidth(rect));
            //fontSizeForLabel = max(fontSizeForLabel,20)
            
            
            
                NSGraphicsContext.current?.saveGraphicsState()
                let segmentLabelShadow = NSShadow()
                segmentLabelShadow.shadowBlurRadius = 2.0
                segmentLabelShadow.shadowOffset = NSSize(width: 1, height: 0)
                segmentLabelShadow.shadowColor = NSColor.init(white: 0.2, alpha: 1.0)
                
                segmentLabelShadow.set()
                
                
                // isHighlighted ? NSColor.init(calibratedWhite: 0.8, alpha: 1.0) :
                
                segmentLabel.drawStringInsideRectWithMenlo(fontSize: fontSizeForLabel, textAlignment: NSTextAlignment.right, fontForegroundColor: isSelected ? NSColor.white : NSColor.lightGray, rect: rect.offsetBy(dx: -2, dy: 0))


            if(fmInk.brushTip == .uniformPath)
            {
                var rS = "path"
                if(fmInk.isUniformPathThatIsFillOnly)
                {
                    
                    rS = "path fill only"
                }
                
                if(fmInk.isUniformPathThatIsStrokeOnly)
                {
                    rS = "path stroke only"
                }
                
                
                rS.drawStringInsideRectWithMenlo(fontSize: 14, textAlignment: NSTextAlignment.left, fontForegroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), rect: rect.insetBy(dx: 0.1 * rect.width, dy: 0))
            }
            
            NSGraphicsContext.current?.restoreGraphicsState()
            
            

               
            /*
             NSColor.black.setStroke()
             let p = NSBezierPath();
             p.move(to: NSPoint.init(x: rect.midX, y: rect.minY))
             p.line(to: NSPoint.init(x: rect.midX, y: rect.maxY))
             p.lineWidth = CGFloat(segmentIndex + 1)
             p.stroke()
             */
        }
    
        
        
    }// END draw palette property


    // MARK: Width Palette SegmentedControl action
    @IBAction func changeWidthPaletteSegment(_ sender : NSControl)
    {
        if sender is NCTSegmentedControl
        {
            if(modeForWidthPaletteSegmControl == .strokeWidths)
            {
                updateCurrentStrokeWidthUsingSelectedSegment();
            }
            //print(paletteSegmControl.selectedSegment)
        
        }
    
    
    }
    
  
    
    // MARK: COLOR PALETTE SEGMENTED CONTROL
    
    class NCTColorPalette : NSObject
    {
    
        init(name: String, arrayOfColors : [NSColor])
        {
            self.name = name;
            self.arrayOfColors = arrayOfColors
            super.init();
        }
        
        init(propertyList:String)
        {
        
            super.init();
        }
        
        var name : String = ""
        var arrayOfColors : [NSColor] = [];
         func menuItemWithRepresentedObject() -> NSMenuItem
         {
            let paletteMenuItem : NSMenuItem = NSMenuItem(title: name, action: nil, keyEquivalent: "");
            paletteMenuItem.representedObject = self;
            return paletteMenuItem;
         }
    }
    
    
    @IBAction func makeColorEraser(_ sender : NSControl)
    {
            updateColorWellBasedOnSelectionState(color: NSColor.clear)
    }
    
    /*
     // MARK: Color Palette Segmented Control action
    @IBAction func changeColorPaletteSegment(_ sender : NSControl)
    {
        if sender is NCTSegmentedControl
        {
            updateCurrentStrokeColorUsingSelectedSegment();
        
        }
    
    }*/


    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: WIDTH SEGMENTED CONTROL

    func widthPaletteIncrementIndex()
    {
        if((brushTipWidthPaletteSegmentedControl.selectedSegment + 1) <= (brushTipWidthPaletteSegmentedControl.segmentCount - 1))
        {
        
            brushTipWidthPaletteSegmentedControl.selectedSegment = brushTipWidthPaletteSegmentedControl.selectedSegment + 1;
        
        }
    
    }
    
    func widthPaletteDecrementIndex()
    {
    
        if((brushTipWidthPaletteSegmentedControl.selectedSegment - 1) >= 0)
        {
        
            brushTipWidthPaletteSegmentedControl.selectedSegment = brushTipWidthPaletteSegmentedControl.selectedSegment - 1;
        
        }
    
    }


    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: BOWED LINE
    
    
    var bowedInfoAssembled : BowedInfo
    {
    
        get
        {
        let bowedInfoAssembledToReturn = BowedInfo.init(isFacingA: false, normalHeight: self.bowedLineNormalHeightIsPercentageOfLineLength ? self.bowedLineNormalHeightPercentage : self.bowedLineNormalHeightFixed , normalHeightIsPercentageOfLineLength: self.bowedLineNormalHeightIsPercentageOfLineLength, lineInterpolationLocation: self.bowedLineInterpolationLocation, lineInterpolationLocationMultiplier: self.bowedLineInterpolationLocationMultiplier, isArc: self.bowedLineModeIsArc, makeCornered: self.bowedLineMakeCornered, corneredAsHard: self.bowedLineCorneredAsHard, lineInterpolationDualDistance : self.bowedLineInterpolationDualDistance)
        
            return bowedInfoAssembledToReturn;
        
        }
        
    }
    
    func bowedInfoAssembledWithFacingA(facingA:Bool) -> BowedInfo
    {
        var bowedInfoToReturn = self.bowedInfoAssembled
        bowedInfoToReturn.isFacingA = facingA
        return bowedInfoToReturn;
    
    }
    
    func bowedInfoSettingsSetToDefaults()
    {
        bowedLineNormalHeightFixed = 10.0;
        bowedLineNormalHeightPercentage = 10.0;
        bowedLineNormalHeightIsPercentageOfLineLength = true;
        bowedLineInterpolationLocation = 0.5;
        bowedLineInterpolationLocationMultiplier = 1.0;
        bowedLineInterpolationDualDistance = 0;
        bowedLineMakeCornered = false;
    }
    
    @IBOutlet var bowedLineModeIsArcNCTSegm : NCTSegmentedControl?
    var bowedLineModeIsArc : Bool = false
    {
        didSet
        {
            bowedLineModeIsArcNCTSegm!.selectedSegment = bowedLineModeIsArc ? 1 : 0;
        
        
        }
    }
    
    @IBAction func changeBowedLineModeIsArc(_ sender : NSControl)
    {
        if(sender == bowedLineModeIsArcNCTSegm)
        {
            bowedLineModeIsArc = (bowedLineModeIsArcNCTSegm!.selectedSegment > 0) ? true : false
        }
        
    }
    
    @IBOutlet var bowedLineNormalIsFixedNSRadioButton : NSButton?
    @IBOutlet var bowedLineNormalIsPercentageNSRadioButton : NSButton?
    
    
    // Normal Height: fixed or percentage
    var bowedLineNormalHeightFixed : CGFloat = 10.0
    { didSet {
    bowedLineNormalHeightFixed.formClamp(to: 1...400.00)
    bowedLineNormalHeightFixedTextField?.setCGFloatValue(bowedLineNormalHeightFixed)} }
    @IBAction func changeBowedLineNormalHeightFixed(_ sender : NSControl)
    {
        
        bowedLineNormalHeightFixed = sender.cgfloatValue()
        bowedLineNormalHeightFixedTextField?.setCGFloatValue(bowedLineNormalHeightFixed);
    }
    
    
    @IBOutlet var bowedLineNormalHeightFixedTextField : NSTextField?
    
    
    @IBOutlet var bowedLineNormalHeightPercentageTextField : NSTextField?
    @IBOutlet var bowedLineNormalHeightPercentageSlider : NSSlider?


    var bowedLineNormalHeightPercentage : CGFloat = 10.00
    { didSet {
        bowedLineNormalHeightPercentage.formClamp(to: 1...400.00)
        
        bowedLineNormalHeightPercentage = round(bowedLineNormalHeightPercentage);
        
        bowedLineNormalHeightPercentageTextField?.setCGFloatValue(bowedLineNormalHeightPercentage)
        bowedLineNormalHeightPercentageSlider?.setCGFloatValue(bowedLineNormalHeightPercentage)
        
    } }
    
    @IBAction func changeBowedLineNormalHeightPercentage(_ sender : NSControl)
    {
            bowedLineNormalHeightPercentage = sender.cgfloatValue()
    }
    
    var bowedLineNormalHeightIsPercentageOfLineLength: Bool = false
    { didSet {
    
        if(bowedLineNormalHeightIsPercentageOfLineLength == true)
        {
            bowedLineNormalIsFixedNSRadioButton?.state = false.stateValue
            bowedLineNormalIsPercentageNSRadioButton?.state = true.stateValue
        
        }
       else
       {
       bowedLineNormalIsFixedNSRadioButton?.state = true.stateValue
            bowedLineNormalIsPercentageNSRadioButton?.state = false.stateValue
        
       }
    
    }
    
    }
    
    
    @IBAction func changeBowedLineNormalHeightIsPercentage(_ sender : NSControl)
    {
        if let radioButton = sender as? NSButton
        {
            bowedLineNormalHeightIsPercentageOfLineLength
            = radioButton.tag.boolValue
            
//            print(radioButton.title)
//            print(bowedLineNormalHeightIsPercentageOfLineLength)
            
        }
    
    }
    
    /*
    
    // MARK: bowedLinePeakFlatness
    var bowedLinePeakFlatness : CGFloat = 0
     {
        didSet
        {
            if(bowedLinePeakFlatnessSlider != nil)
            {
                let mappedVal = mapy(n: Double(bowedLinePeakFlatness), start1: 0, stop1: 1.0, start2: bowedLinePeakFlatnessSlider!.minValue, stop2: bowedLinePeakFlatnessSlider!.maxValue)
                
                bowedLinePeakFlatnessSlider!.doubleValue = mappedVal
            }
            
        }
    }*/
    
    var bowedLineCorneredAsHard : Bool = false
    {
        didSet
        {
            bowedLineCorneredAsHardNCTSegm?.selectedSegment = (bowedLineCorneredAsHard == true) ? 1 : 0;
        }
    
    }
    @IBOutlet var bowedLineCorneredAsHardNCTSegm : NCTSegmentedControl?
    @IBAction func changeBowedLineCorneredAsHard(_ sender : NCTSegmentedControl)
    {
        bowedLineCorneredAsHard = (sender.selectedSegment == 1) ? true : false;
    }
    
    // MARK: bowedLineMakeCornered
    var bowedLineMakeCornered : Bool = false
    {
        didSet
        {
            bowedLineMakeCorneredCheckbox?.state = bowedLineMakeCornered.stateValue
        }
    }
    
    @IBOutlet var bowedLineMakeCorneredCheckbox : NSButton?
    @IBAction func changeBowedLineUseMakeCornered(_ sender : NSButton)
    {
        bowedLineMakeCornered = sender.state.boolValue
    }
    
    /*
    
    @IBOutlet var bowedLinePeakFlatnessSlider : NCTSlider?
    @IBAction func changeBowedLinePeakFlatness(_ sender : NSSlider)
    {
       let mappedVal = mapy(n: sender.doubleValue, start1: sender.minValue, stop1: sender.maxValue, start2: 0, stop2: 1.0)
    
        bowedLinePeakFlatness = CGFloat(mappedVal)
        
        
    }*/


    // MARK: bowedLineInterpolationLocation
    var bowedLineInterpolationLocation : CGFloat = 0.5
    {
        didSet
        {
            if(bowedLineInterpolationLocationSlider != nil)
            {
                let mappedVal = mapy(n: Double(bowedLineInterpolationLocation), start1: 0, stop1: 1.0, start2: bowedLineInterpolationLocationSlider!.minValue, stop2: bowedLineInterpolationLocationSlider!.maxValue)
                
                bowedLineInterpolationLocationSlider!.doubleValue = mappedVal
            }
            
        }
    }
    @IBOutlet var bowedLineInterpolationLocationSlider : NCTSlider?

    @IBAction func changeBowedLineInterpolationLocation(_ sender : NSSlider)
    {
    
        let mappedVal = mapy(n: sender.doubleValue, start1: sender.minValue, stop1: sender.maxValue, start2: 0, stop2: 1.0)
    
        bowedLineInterpolationLocation = CGFloat(mappedVal)
        
        
        
    }
    
    // MARK: bowedLineInterpolationLocationMultiplier
     var bowedLineInterpolationLocationMultiplier : CGFloat = 1.0
     {
        didSet
        {
            bowedLineInterpolationLocationMultiplier = bowedLineInterpolationLocationMultiplier.clamped(to: 1.0...maxLineInterpolationLocationMultiplier)
            
             let mappedVal = mapy(
             n: Double(bowedLineInterpolationLocationMultiplier),
             start1: 1.0,
             stop1: maxLineInterpolationLocationMultiplier.double(),
             start2: bowedLineInterpolationLocationMultiplierSlider!.minValue,
             stop2: bowedLineInterpolationLocationMultiplierSlider!.maxValue)
                
               bowedLineInterpolationLocationMultiplierSlider!.doubleValue = mappedVal
        
        }
     }
     @IBOutlet var bowedLineInterpolationLocationMultiplierSlider : NCTSlider?

    @IBAction func changeBowedLineInterpolationLocationMultiplier(_ sender : NSSlider)
    {
    
        let mappedVal = mapy(
        n: sender.doubleValue,
        start1: sender.minValue,
        stop1: sender.maxValue,
        start2: 1.0,
        stop2: maxLineInterpolationLocationMultiplier.double())
    
        bowedLineInterpolationLocationMultiplier = CGFloat(mappedVal)
        
        
        
    }
     // MARK: bowedLineInterpolationDualDistance
     var bowedLineInterpolationDualDistance : CGFloat = 0
     {
        didSet
        {
         bowedLineInterpolationDualDistance = bowedLineInterpolationDualDistance.clamped(to: 0...1.0)
            
             let mappedVal = mapy(
             n: Double(bowedLineInterpolationDualDistance),
             start1: 0.0,
             stop1: 1.0,
             start2: bowedLineInterpolationDualDistanceSlider!.minValue,
             stop2: bowedLineInterpolationDualDistanceSlider!.maxValue)
                
               bowedLineInterpolationDualDistanceSlider!.doubleValue = mappedVal
        
        }
     }
     
    @IBOutlet var bowedLineInterpolationDualDistanceSlider : NCTSlider?
      
    @IBAction func changeBowedLineInterpolationDualDistance(_ sender : NSSlider)
    {
    
        let mappedVal = mapy(n: sender.doubleValue, start1: sender.minValue, stop1: sender.maxValue, start2: 0, stop2: 1.0)
    
        bowedLineInterpolationDualDistance = CGFloat(mappedVal)
        
        
        
    }
    
    @IBAction func makeBowedLineSettingFromPreset(_ sender : NCTSegmentedControl)
    {
        if(sender.stringValue == "semicircle")
        {
         bowedLineModeIsArc = true;
         bowedLineNormalHeightIsPercentageOfLineLength = true;
         bowedLineNormalHeightPercentage = 50;
         
        }
        else if(sender.stringValue == "bubble")
        {
            bowedLineModeIsArc = false;
            bowedLineNormalHeightIsPercentageOfLineLength = true;
            bowedLineNormalHeightPercentage = 30;
            bowedLineInterpolationDualDistance = 0.75;
        }
    
    }
    
    
    @IBAction func resetBowedLineSettings(_ sender : NCTButton)
    {
        
        bowedInfoSettingsSetToDefaults()

    
    }
      
      // ---------------------------------------------
    // ---------------------------------------------
    // MARK: SNAPPING
    
    
    
    
    // angle snapping boolean
    var angleSnapping : Bool = false
    {
        didSet
        {
            angleSnappingCheckbox.state = angleSnapping.stateValue
            
          
            
            if(angleSnapping == true)
            {
                if(gridSnapping == true)
                {
                    gridSnapping = false;
                    angleSnappingWasOn = false;
                }
            }
            
           /* appDelegate?.fmDocs.forEach({ (fmDocument) in
                fmDocument.drawingPageController?.angleSnappingTitlebarIndicatorLabel?.isHidden = !angleSnapping
            })
            */
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "angle snapping\n \(angleSnapping ? "on" : "off")", duration: self.messageIndicatorPresenceDuration, messageLevel:1)

        }
        
    }
    @IBOutlet var angleSnappingCheckbox : NSButton!
    @IBAction func changeAngleSnapping(_ sender : NSButton)
    {
        angleSnapping = sender.state.boolValue
    }

    // angle snapping interval cgfloat
    var angleSnappingInterval : CGFloat = 10
    { didSet{ angleSnappingIntervalTextField.setCGFloatValue(angleSnappingInterval)} }

    @IBOutlet var angleSnappingIntervalTextField : NSTextField!
    @IBAction func changeAngleSnappingInterval(_ sender : NSControl)
    {
        angleSnappingInterval = sender.cgfloatValue();
    }
    
    // length snapping
    
    var lengthSnapping : Bool = false
    {
        didSet
        {
        
        
            
            lengthSnappingCheckbox.state = lengthSnapping.stateValue
            
            /*appDelegate?.fmDocs.forEach({ (fmDocument) in
                fmDocument.drawingPageController?.lengthSnappingTitlebarIndicatorLabel?.isHidden = !lengthSnapping
            })*/
            
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "length snapping\n \(lengthSnapping ? "on" : "off")", duration: self.messageIndicatorPresenceDuration, messageLevel:1)
        }
        
    }
    @IBOutlet var lengthSnappingCheckbox : NSButton!
    @IBAction func changeLengthSnapping(_ sender : NSButton)
    {
        lengthSnapping = sender.state.boolValue;
    }

    // length snapping interval cgfloat
    var lengthSnappingInterval : CGFloat = 25
    {    didSet{    lengthSnappingIntervalTextField.setCGFloatValue(lengthSnappingInterval)} }

    @IBOutlet var lengthSnappingIntervalTextField : NSTextField!
    @IBAction func changeLengthSnappingInterval(_ sender : NSControl)
    {
        lengthSnappingInterval = sender.cgfloatValue();
    }
    
    // points snapping
    var pointsSnapping : Bool = false
    {
        didSet
        {
        

            
            pointsSnappingCheckbox.state = pointsSnapping.stateValue
            
            /*appDelegate?.fmDocs.forEach({ (fmDocument) in
                fmDocument.drawingPageController?.pointsSnappingTitlebarIndicatorLabel?.isHidden = !pointsSnapping
             })*/
            
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "points snapping\n \(pointsSnapping ? "on" : "off")", duration: self.messageIndicatorPresenceDuration, messageLevel:1)
        }
    
    }
    @IBOutlet var pointsSnappingCheckbox : NSButton!
    @IBAction func changePointsSnapping(_ sender : NSButton)
    {
        pointsSnapping = sender.state.boolValue;
        
    }
   
   
    // paths snapping
    var pathsSnapping : Bool = false
    {
        didSet
        {

            
            pathsSnappingCheckbox.state = pathsSnapping.stateValue
            
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "paths snapping\n \(pathsSnapping ? "on" : "off")", duration: self.messageIndicatorPresenceDuration, messageLevel:1)
            /*appDelegate?.fmDocs.forEach({ (fmDocument) in
                fmDocument.drawingPageController?.pathsSnappingTitlebarIndicatorLabel?.isHidden = !pathsSnapping
            })*/
            
        }
    }
    @IBOutlet var pathsSnappingCheckbox : NSButton!
    @IBAction func changePathsSnapping(_ sender : NSButton)
    {
        pathsSnapping = sender.state.boolValue;
    }
   
    
    var autoTurnOnPointSnappingForVanishingPointGuides : Bool = true;
    var pointSnappingWasOff : Bool = false;
    // vanishing point lines snapping
    var vanishingPointLinesSnapping : Bool = false
    {
        didSet
        {
          
            
            vanishingPointLinesCheckbox.state = vanishingPointLinesSnapping.stateValue
            
            /*appDelegate?.fmDocs.forEach({ (fmDocument) in
                fmDocument.drawingPageController?.vanishingPointsSnappingTitlebarIndicatorLabel?.isHidden = !vanishingPointLinesSnapping
            })*/
            
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "perspective drawing mode\n \(vanishingPointLinesSnapping ? "on" : "off")", duration: self.messageIndicatorPresenceDuration, messageLevel:1)
            
            
        }
    }
    @IBOutlet var vanishingPointLinesCheckbox : NSButton!
    @IBAction func changeVanishingPointLinesSnapping(_ sender : NSButton)
    {
        vanishingPointLinesSnapping = sender.state.boolValue;
    }
    
    var vanishingPointLinesSnappingAngleRange : CGFloat = 10
    {
        didSet
        {
        
        }
        
    }
        
    // alignment point lines snapping
    var alignmentPointLinesSnapping : Bool = false
    {
        didSet
        {
            alignmentPointLinesCheckbox.state = alignmentPointLinesSnapping.stateValue
            
            /*appDelegate?.fmDocs.forEach({ (fmDocument) in
             fmDocument.drawingPageController?.alignmentSnappingTitlebarIndicatorLabel?.isHidden = !alignmentPointLinesSnapping
             })*/
            
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "alignment snapping\n \(alignmentPointLinesSnapping ? "on" : "off")", duration: self.messageIndicatorPresenceDuration, messageLevel:1)
        }
    }
    @IBOutlet var alignmentPointLinesCheckbox : NSButton!
    @IBAction func changeAlignmentPointLinesSnapping(_ sender : NSButton)
    {
        alignmentPointLinesSnapping = sender.state.boolValue;
    }
    
    // MARK: GRID AND SNAPPING
    
    var connectLivePathToPaths : Bool = true
    {
        didSet
        {
            connectLivePathToPathsNCTSegm?.selectedSegment = connectLivePathToPaths.onOffSwitchInt;
        }
    }

    
    @IBAction func changeConnectLivePathToPaths(_ sender: NCTSegmentedControl)
    {
        connectLivePathToPaths = sender.onOffSwitchBool;
    }
    
    @IBOutlet weak var connectLivePathToPathsNCTSegm: NCTSegmentedControl?
    
    
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: GRID AND SNAPPING
    
    
    var showGrid : Bool = false
    {
        didSet
        {
            
            currentFMDocument?.drawingPage.showGrid = showGrid;
            showGridNCTSegmControl?.selectedSegment = 1 - showGrid.intValue
            
            
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "grid\n \(self.showGrid ? "visible" : "hidden")", duration: self.messageIndicatorPresenceDuration, messageLevel:2)
            
            
        }
    }
    @IBOutlet var showGridNCTSegmControl : NCTSegmentedControl?
    @IBAction func changeShowGrid(_ sender : NCTSegmentedControl)
    {

        showGrid = !sender.selectedSegment.boolValue
        
    }
    
    @IBOutlet var backgroundColorWell : NCTColorWell?
    
    var backgroundColor : NSColor = NSColor.init(white: 0.5, alpha: 1.0)
    {
        didSet
        {
            backgroundColorWell?.color = backgroundColor;
            currentFMDocument?.drawingPage.defaultBackgroundColor = backgroundColor;

        }
    }
    
    @IBAction func changeBackgroundColor(_ sender : NCTColorWell)
    {
        backgroundColor = sender.color;
    }
    
    @IBOutlet var gridColorWell : NCTColorWell?
    var gridColor : NSColor = NSColor.darkGray
    {
        didSet{
            gridColorWell?.color = gridColor;
            currentFMDocument?.drawingPage.gridColor = gridColor;

        }
    }
    
    @IBAction func changeGridColor(_ sender : NCTColorWell)
    {
        gridColor = sender.color;
    }
    
    
    
    @IBAction func resetAllSnappingToOff(_ sender: Any)
    {
        suspendMessageIndicator = true
    
        angleSnapping = false
        gridSnapping = false
        pathsSnapping = false;
        lengthSnapping = false;
        pointsSnapping = false;
        alignmentPointLinesSnapping = false;
    
        suspendMessageIndicator = false
        
        self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "all snapping\n turned off", duration: self.messageIndicatorPresenceDuration, messageLevel:1);
        
    }
    
    @IBOutlet var suspendsAngleSnappingLabel : NSTextField?
    var angleSnappingWasOn : Bool = false
    {
        didSet
        {
            suspendsAngleSnappingLabel?.isHidden = !angleSnappingWasOn;
            // turn on label 'suspends angle snapping'
        }
    }

  
    
    
    var gridSnapping : Bool = false
    {
        didSet
        {
            currentFMDocument?.drawingPage.gridSnapping = gridSnapping;
            gridSnappingCheckbox?.state = gridSnapping.stateValue;
            
  
            
            // clear out any grid snapping crosshair
            if(gridSnapping == false)
            {
                if(lineWorkInteractionEntity!.currentPointHitPath != nil)
                {
                    if(lineWorkInteractionEntity!.currentPointHitPath!.isEmpty == false)
                    {
                        let oldRect = lineWorkInteractionEntity!.currentPointHitPath!.bounds.insetBy(dx: -8, dy: -8);
                        lineWorkInteractionEntity!.currentPointHit.nsPoint = nil;
                        lineWorkInteractionEntity?.activePenLayer?.setNeedsDisplay(oldRect);
                    }
                }
                
                if(oldValue == true)
                {
                    if(angleSnappingWasOn)
                    {
                        angleSnapping = true;
                        angleSnappingWasOn = false;
                    }
                }
                
            }
            
            if((gridSnapping == true) && (angleSnapping == true))
            {
                angleSnappingWasOn = true;
                angleSnapping = false;
            }
            
            /* appDelegate?.fmDocs.forEach({ (fmDocument) in
                fmDocument.drawingPageController?.gridSnappingTitlebarIndicatorLabel?.isHidden = !gridSnapping
            }) */
            
           
                self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "grid snapping\n \(self.gridSnapping ? "on" : "off")", duration: self.messageIndicatorPresenceDuration, messageLevel:1)
           


        }// END didSet
    }
    @IBOutlet var gridSnappingCheckbox : NSButton?
    @IBAction func changeGridSnappingFromCheckbox(_ sender : NSButton)
    {
        gridSnapping = sender.boolFromState;
    }
    
    var gridSnappingType : NCTGridSnappingType = .squareDots
    {
        didSet{
        
            gridSnappingPopUpButton?.selectItemWithRepresentedString(string: gridSnappingType.rawValue)
         //   gridSnappingPopUpButton?.selectItem(withTag: gridSnappingType.rawValue);
            currentFMDocument?.drawingPage.gridSnappingType = gridSnappingType;
        
        }
    }
    @IBOutlet var gridSnappingPopUpButton : NSPopUpButton?
    @IBAction func changeGridSnappingType(_ sender : NSPopUpButton)
    {
        if let representedObjStringOfSelectedMenuItem = sender.selectedItem?.representedObject as? String
        {
            gridSnappingType = NCTGridSnappingType.init(rawValue: representedObjStringOfSelectedMenuItem ) ?? .squareEdges
        }
        if(showGrid == false)
        {
            showGrid = true;
        }
    }
    
    var gridSnappingEdgeLength : CGFloat = 10.0
    {
        didSet{
            gridSnappingEdgeLength = gridSnappingEdgeLength.clamped(to: 2...400);
            gridSnappingEdgeLengthTextField?.setCGFloatValue(gridSnappingEdgeLength)
            currentFMDocument?.drawingPage.gridSnappingEdgeLength = gridSnappingEdgeLength;
        }
    }
    
    @IBOutlet var gridSnappingEdgeLengthTextField : NSTextField?
    @IBAction func changeGridSnappingEdgeLength(_ sender : NSControl)
    {
        gridSnappingEdgeLength = sender.cgfloatValue();
    }
    
    @IBAction func changeGridSnappingEdgeLengthFromNCTSegm(_ sender : NCTSegmentedControl)
    {
        gridSnappingEdgeLength = sender.cgfloatValue();
    }
    
    
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: VANISHING POINTS
     // vanishing point guides
     
    // Vanishing Point Count
    var vanishingPointCount : Int = 2
    {
        didSet{
        vanishingPointCount.formClamp(to: 1...3)
        vanishingPointCountNCTSegmCont.selectedSegment = (vanishingPointCount - 1)
//        lineWorkInteractionEntity.updateVanishingPoints()
        }
    }
    @IBOutlet var vanishingPointCountNCTSegmCont : NCTSegmentedControl!
    @IBAction func changeVanishingPointCount(_ sender : NCTSegmentedControl)
    {
        vanishingPointCount = (sender.selectedSegment + 1)
    }
    
    // Vanishing Point Guides
    var vanishingPointGuides : Bool = false
    {
        didSet{
            vanishingPointGuidesNCTSegmCont.selectedSegment = vanishingPointGuides.onOffSwitchInt;
            lineWorkInteractionEntity?.activePenLayer?.needsDisplay = true;
            
            if((vanishingPointGuides == true) && (oldValue == false))
            {
                if(autoTurnOnPointSnappingForVanishingPointGuides)
                {
                    if(pointsSnapping == false)
                    {
                        pointSnappingWasOff = true;
                        pointsSnapping = true;
                    }
                    else
                    {
                        
                    }
                }
            }
            else if((vanishingPointGuides == false) && (oldValue == true))
            {
                if(autoTurnOnPointSnappingForVanishingPointGuides)
                {
                    if(pointSnappingWasOff)
                    {
                        if(pointsSnapping)
                        {
                            pointsSnapping = false;
                            pointSnappingWasOff = false;
                        }
                    }
                }
                
            }
            
        }
        
    }
    
    @IBOutlet var vanishingPointGuidesNCTSegmCont : NCTSegmentedControl!
    @IBAction func changeVanishingPointGuides(_ sender : NCTSegmentedControl)
    {
        
        vanishingPointGuides = !(sender.selectedSegment.boolValue)
    }

    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: SHOW CONTROL POINTS
    
    // ---------------------------------------------
    // ------- showStrokeControlPoints
    var showStrokeControlPoints : Bool = false
    {
        didSet{
        
        showStrokeControlPointsCheckbox.state = showStrokeControlPoints.stateValue
    
        
    
        
        }
    }
    @IBOutlet var showStrokeControlPointsCheckbox : NSButton!
    @IBAction func changeShowStrokeControlPoints(_ sender : NSButton)
    {
        showStrokeControlPoints = sender.state.boolValue;
    }

    // ---------------------------------------------
    // ------- showAllControlPoints
    var showAllControlPoints : Bool = false
    {
        didSet{
        
        showAllControlPointsCheckbox.state = showAllControlPoints.stateValue
        
        currentFMDocument?.drawingPage.currentPaperLayer.needsDisplay = true
        
//            currentFMDocument?.drawingPage.paperLayer.needsDisplay = true


/*        for fmDoc! : FMDocument in self.allFMDocuments
        {
            fmDoc.
        }
  */
        
        }
    }
    @IBOutlet var showAllControlPointsCheckbox : NSButton!
    @IBAction func changeShowAllControlPoints(_ sender : NSButton)
    {
        showAllControlPoints = sender.state.boolValue;
                 currentFMDocument?.activePenLayer.needsDisplay = true
   
    }


    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: COMPLETION OF SHAPE
   
    var makeAllShapeCompletionsHardCorner : Bool = false
   
   
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: CORNER ROUNDING
    
    var cornerRounding : CGFloat = 1.0
    {
        didSet
        {
            cornerRounding = cornerRounding.clamped(to: 1...200.0);
            cornerRoundingTextField?.setCGFloatValue(cornerRounding)
            
             self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "\(cornerRoundingType.stringValue) corner rounding length:\n \(cornerRounding)", duration: self.messageIndicatorPresenceDurationShort, messageLevel:2)
                
        }
    }
    
    @IBOutlet var cornerRoundingTextField : NSTextField?
    @IBAction func changeCornerRounding(_ sender : NSControl)
    {
        cornerRounding = sender.cgfloatValue();
    }

    @IBAction func changeCornerRoundingFromNCTSegm(_ sender : NCTSegmentedControl)
    {
        cornerRounding = sender.cgfloatValue();
    }

    var cornerRoundingType : NCTCornerRoundingType = .bSpline
    {
        didSet
        {
            cornerRoundingTypeNCTSegmCont?.selectedSegment = cornerRoundingType.rawValue;
        
        self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "corner rounding\n \(cornerRoundingType.stringValue)", duration: self.messageIndicatorPresenceDuration, messageLevel:2)
        
        }
    }
    
    @IBOutlet var cornerRoundingTypeNCTSegmCont : NCTSegmentedControl?

    @IBAction func changeCornerRoundingType(_ sender : NCTSegmentedControl)
    {
        cornerRoundingType = NCTCornerRoundingType.init(rawValue: sender.selectedSegment) ?? .bSpline;
    }



    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: UNIFORM
    //

    // -----------
    // MARK: line cap style

    
    var uniformTipLineCapStyleCurrent : NSBezierPath.LineCapStyle = .butt

    var uniformTipLineCapStyle : NSBezierPath.LineCapStyle = .butt
    {
        didSet
        {
            fmInk.uniformTipLineCapStyle = uniformTipLineCapStyle
            lineWorkInteractionEntity?.currentFMStroke.fmInk.uniformTipLineCapStyle = uniformTipLineCapStyle
            uniformTipLineCapStyleNCTSegm?.selectedSegment = Int(uniformTipLineCapStyle.rawValue)
        }
    }
     
    @IBOutlet var uniformTipLineCapStyleNCTSegm : NCTSegmentedControl?
    
    @IBAction func changeUniformTipLineCapStyle(_ sender : NCTSegmentedControl)
    {
        // -----
        // linecapstyle: butt = 0, round = 1, square = 2
        // corresponds to Obj-C constants and segments.
        // -----
        uniformTipLineCapStyle = NSBezierPath.LineCapStyle.init(rawValue: UInt(sender.selectedSegment)) ?? .butt

    }
    
    

    // -----------
    // MARK: line join style
    var uniformTipLineJoinStyleCurrent : NSBezierPath.LineJoinStyle = .miter
    var uniformTipLineJoinStyle : NSBezierPath.LineJoinStyle = .miter
    {
        didSet
        {
            fmInk.uniformTipLineJoinStyle = uniformTipLineJoinStyle
            lineWorkInteractionEntity?.currentFMStroke.fmInk.uniformTipLineJoinStyle = uniformTipLineJoinStyle
            uniformTipLineJoinStyleNCTSegm?.selectedSegment = Int(uniformTipLineJoinStyle.rawValue)
        }
    }
    
    @IBOutlet var uniformTipLineJoinStyleNCTSegm : NCTSegmentedControl?
    
    @IBAction func changeUniformTipLineJoinStyle(_ sender : NCTSegmentedControl)
    {
        // -----
        // linejoinstyle: miter = 0, round = 1, bevel = 2
        // corresponds to Obj-C constants and segments.
        // -----
        uniformTipLineJoinStyle = NSBezierPath.LineJoinStyle.init(rawValue: UInt(sender.selectedSegment)) ?? .miter
        
    }
    
    var uniformTipMiterLimit : CGFloat = 40
    {
        didSet
        {
            lineWorkInteractionEntity?.currentFMDrawable.miterLimit = uniformTipMiterLimit
            lineWorkInteractionEntity?.currentFMStroke.fmInk.uniformTipMiterLimit = uniformTipMiterLimit;
        }
    }
    
    @IBAction func resetUniformTipFeatures(_ sender : NSControl)
    {
        uniformTipLineCapStyle = .butt
        uniformTipLineJoinStyle = .miter
        uniformTipMiterLimit = 40;
    }
    
    
    /*
    // MARK: UNIFORM FLAT PATH
    
    var uniformTipFlatPathIsOn : Bool = false
    {
      didSet
      {
     //   lineWorkInteractionEntity?.currentFMStroke.fmInk.representationMode = uniformTipFillModeIsOn ? .inkColorIsFillOnly : .inkColorIsStrokeOnly;
     //   fmInk.representationMode = uniformTipFillModeIsOn ? .inkColorIsFillOnly : .inkColorIsStrokeOnly;
        
        uniformTipFlatPathIsOnNCTSegmCont?.selectedSegment = uniformTipFlatPathIsOn.onOffSwitchInt;
        uniformTipFlatPathIsOnCheckbox?.state = uniformTipFlatPathIsOn.stateValue;
      }
    }
    
    @IBOutlet var uniformTipFlatPathIsOnNCTSegmCont : NCTSegmentedControl?
    
    @IBOutlet var uniformTipFlatPathIsOnCheckbox : NSButton?
    
    @IBAction func changeUniformFlatPathIsOn(_ sender : NCTSegmentedControl)
    {
        uniformTipFlatPathIsOn = (sender.selectedSegment == 0) ? true : false;
    }
    
    @IBAction func changeUniformFlatPathIsOnCheckbox(_ sender : NSButton)
    {
        uniformTipFlatPathIsOn = sender.boolFromState;
        
    }
    */

    // MARK: SHADING SHAPES
    var shadingShapesModeIsOn : Bool = false
    {
        didSet
        {
           shadingShapesModeIsOnNCTSegmentedControl?.selectedSegment = shadingShapesModeIsOn.onOffSwitchInt;
           
            if(appDelegate != nil)
            {
                for doc in appDelegate!.fmDocs
                {
                    doc.drawingPageController?.shadingShapesModeBox.alphaValue = shadingShapesModeIsOn ? 1.0 : 0.0;
                }
                appDelegate?.currentFMDocument?.activePenLayer.setupCursor()
            }
           
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "shading shapes mode\n \(shadingShapesModeIsOn ? "on" : "off")", duration: self.messageIndicatorPresenceDuration, messageLevel:1)
        }
    }
   
    @IBOutlet var shadingShapesModeIsOnNCTSegmentedControl : NCTSegmentedControl?
    
    @IBAction func changeShadingShapesModeIsOn(_ sender : NCTSegmentedControl)
    {
        shadingShapesModeIsOn = sender.onOffSwitchBool;
    }
    
    
    // MARK: strokesAddShadeForSS
    var strokesAddShadeForSS : Bool = false
    {
        didSet
        {
           strokesAddShadeForSSNCTSegmentedControl?.selectedSegment = strokesAddShadeForSS.onOffSwitchInt;
        }
    }
   
    @IBOutlet var strokesAddShadeForSSNCTSegmentedControl : NCTSegmentedControl?
    
    @IBAction func changeStrokesAddShadeForSS(_ sender : NCTSegmentedControl)
    {
        strokesAddShadeForSS = sender.onOffSwitchBool;
    }
    
    
     var currentShadingShapeSettingsAsDictionary : Dictionary<String,Any>
    {
        get
        {
            let shadingShapeSettingsDictionary : Dictionary<String,Any> = [:]
        return shadingShapeSettingsDictionary
        }
        /*
            var shadingShapeSettingsDictionary : Dictionary<String,Any> = [:];
            
            switch self.shadingShapesModeSegmentedControl.label(forSegment: self.shadingShapesModeSegmentedControl.selectedSegment)
             {
                case "hatching":
                    shadingShapeSettingsDictionary["usesHatching"] = true;
                    shadingShapeSettingsDictionary["hatchingSpacing"] = self.shadingHatchingSpacing;
                    shadingShapeSettingsDictionary["hatchingRotation"] = self.shadingHatchingAngle;
                    shadingShapeSettingsDictionary["usesCrosshatching"] = self.shadingHatchingDoCrosshatch;
                case "noise":
                    shadingShapeSettingsDictionary["usesNoise"] = true;
                    shadingShapeSettingsDictionary["gkNoise"] = noiseConfigurationViewController.gkNoise;
                    /*shadingShapeSettingsDictionary["hatchingSpacing"] = self.shadingHatchingSpacing;
                    shadingShapeSettingsDictionary["hatchingRotation"] = self.shadingHatchingAngle;
                    shadingShapeSettingsDictionary["usesCrosshatching"] = self.shadingHatchingDoCrosshatch;
                      */
                default:
                      return shadingShapeSettingsDictionary;
                        }

                      return shadingShapeSettingsDictionary;

            }
            */
    }
    
    func drawingLayerDidDepositShadingShape(_ drawinglayer : PaperLayer)
    {
        // update noise object's seed
    
    }
    
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: COMBINATORICS
    var combinatoricsModeIsOn : Bool = false
    {
        didSet
        {
            combinatoricsModeIsOnNCTSegmentedControl?.selectedSegment = combinatoricsModeIsOn.onOffSwitchInt;
            
      
            
            if(appDelegate != nil)
            {
                for doc in appDelegate!.fmDocs
                {
                    doc.drawingPageController?.combinatoricsModeBox.alphaValue = (combinatoricsModeIsOn || unionWithLastDrawnShapeForDrawing) ? 1.0 : 0.0;
                    
                    if(unionWithLastDrawnShapeForDrawing == false)
                    {
                        doc.drawingPageController?.combinatoricsModeLabel.stringValue = combinatoricsMode.stringValue();
                    }
                }
                appDelegate?.currentFMDocument?.activePenLayer.setupCursor()
            }
            
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                if(lineWorkInteractionEntity!.currentPaperLayer!.isCarting)
                {
                    lineWorkInteractionEntity!.currentPaperLayer!.redisplaySelectedTotalRegionRect();
                }
            }
            
            updateCombinatoricsKeysVisibility();
            
          
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "live combinatorics\n \(self.combinatoricsModeIsOn ? "on" : "off")", duration: self.messageIndicatorPresenceDuration, messageLevel:1)
            

        }
    }
    var messageIndicatorPresenceDurationShort : CGFloat = 0.30;
    var messageIndicatorPresenceDuration : CGFloat = 0.50;
    var messageIndicatorPresenceDurationLong : CGFloat = 0.75;
    
    @IBOutlet var combinatoricsModeIsOnNCTSegmentedControl : NCTSegmentedControl?

    @IBAction func changeCombinatoricsModeIsOn(_ sender : NCTSegmentedControl)
    {
        combinatoricsModeIsOn = sender.onOffSwitchBool;
    }
    
    var combinatoricsMode : CombinatoricsDrawingMode = .union
    {
        didSet
        {
            combinatoricsModeNCTSegmentedControl?.selectedSegment = combinatoricsMode.rawValue;
            
            if(appDelegate != nil)
            {
                for doc in appDelegate!.fmDocs
                {
                    //doc.drawingPageController?.combinatoricsModeBox.isHidden = !combinatoricsModeIsOn
                    if(unionWithLastDrawnShapeForDrawing == false)
                    {
                        doc.drawingPageController?.combinatoricsModeLabel.stringValue = combinatoricsMode.stringValue();
                    }
                }
                appDelegate?.currentFMDocument?.activePenLayer.setupCursor()
            }
            
            
            if(combinatoricsModeIsOn || lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithNoSelection)
            {
                self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "\(self.combinatoricsMode.stringValue())\n for live mode", duration: self.messageIndicatorPresenceDurationLong, messageLevel:2)
            }
            
        }
    }
    
    @IBOutlet var combinatoricsModeNCTSegmentedControl : NCTSegmentedControl?
    @IBAction func changeCombinatoricsMode(_ sender : NCTSegmentedControl)
    {
    
        combinatoricsMode = CombinatoricsDrawingMode.init(rawValue: sender.selectedSegment) ?? .union
    }
    
    var unionWithLastDrawnShapeForDrawing : Bool = false
    {
        didSet
        {
            unionWithLastDrawnShapeForDrawingNCTSegmCont?.selectedSegment = unionWithLastDrawnShapeForDrawing.onOffSwitchInt;
           
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "union last shape\n \(unionWithLastDrawnShapeForDrawing ? "on" : "off")", duration: self.messageIndicatorPresenceDurationLong, messageLevel:2)
            
            if(appDelegate != nil)
            {
                for doc in appDelegate!.fmDocs
                {
                    doc.drawingPageController?.combinatoricsModeBox.alphaValue = (unionWithLastDrawnShapeForDrawing || combinatoricsModeIsOn) ? 1.0 : 0.0;
                    doc.drawingPageController?.combinatoricsModeLabel.stringValue = unionWithLastDrawnShapeForDrawing ? "∪ last shape" : combinatoricsModeIsOn ? combinatoricsMode.stringValue() : "";
                }
                appDelegate?.currentFMDocument?.activePenLayer.setupCursor()
            }
        }
    }
    
    @IBOutlet var unionWithLastDrawnShapeForDrawingNCTSegmCont : NCTSegmentedControl?
    
    @IBAction func changeUnionWithLastDrawnShapeForDrawing(_ sender : NCTSegmentedControl)
    {
        unionWithLastDrawnShapeForDrawing = sender.onOffSwitchBool;
    }
    
    // MARK: separateSubtractionPieces
    
    var separateSubtractionPieces : Bool = false
    {
        didSet
        {
            separateSubtractionPiecesCheckBox?.state = separateSubtractionPieces.stateValue;
        }
    }

    @IBOutlet var separateSubtractionPiecesCheckBox : NSButton?

    @IBAction func changeSeparateSubtractionPieces(_ sender: NSButton)
    {
        separateSubtractionPieces = sender.boolFromState
    }
    
    // MARK: depositIfNoOverlap
    
    var depositIfNoOverlap : Bool = true
    {
        didSet
        {

            depositIfNoOverlapCheckbox?.state = depositIfNoOverlap.stateValue

        }
    }

    
    @IBOutlet var depositIfNoOverlapCheckbox : NSButton?

    @IBAction func changeDepositIfNoOverlap(_ sender: NSButton)
    {
    
        depositIfNoOverlap = sender.boolFromState;
    
    }
    
    
    // MARK: receiverDeterminesStyle
    
    @IBOutlet var receiverDeterminesStyleCheckbox : NSButton?

    @IBAction func changeReceiverDeterminesStyle(_ sender : NSButton)
    {
        receiverDeterminesStyle = sender.boolFromState
        
    }
    
    var receiverDeterminesStyle : Bool = true
    {
        didSet
        {
            receiverDeterminesStyleCheckbox?.state = receiverDeterminesStyle.stateValue
        }
    }
    
    
    
    // MARK: -
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: REPLICATION
    
    var replicationMode : ReplicationMode = .radial
    {
        didSet
        {
            if let idx = replicationModePopUpButton?.indexOfItem(withRepresentedObject: replicationMode.rawValue )
            {
                if(idx > -1)
                {
                    replicationModePopUpButton!.selectItem(at: idx);
                
                    
                }
            }
            
            lineWorkInteractionEntity!.replicationConfigurationViewController!.updateGuidelines()
            
        }
    }

    @IBOutlet var replicationModePopUpButton : NSPopUpButton?
    
    @IBAction func changeReplicationMode(_ sender : NSControl)
    {
        if let popUpButton = sender as? NSPopUpButton
        {
            if let str : String = popUpButton.selectedItem!.representedObject as? String
            {
                replicationMode = ReplicationMode.init(rawValue: str) ?? .radial;
            }
            
        }
        
    }
    
    var replicationModeIsOn : Bool = false
    {
        didSet
        {
            replicationModeIsOnNCTSegmentedControl?.selectedSegment = replicationModeIsOn.onOffSwitchInt;
            
            /*
            if(replicationModeIsOn)
            {
                if(lineWorkInteractionEntity!.showAnchorPoint == false)
                {
                    lineWorkInteractionEntity!.showAnchorPoint = true
                }
            }
            else
            {
                //lineWorkInteractionEntity!.showAnchorPoint = false
            }*/
            
            if(replicationModeIsOn == true)
            {
                lineWorkInteractionEntity?.replicationConfigurationViewController!.updateGuidelines()
            }
            else
            {
            lineWorkInteractionEntity?.replicationConfigurationViewController!.updateGuidelinesRectRedisplayForTurnOff()
            }
            
            
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "replication mode\n \(replicationModeIsOn ? "on" : "off")", duration: self.messageIndicatorPresenceDuration, messageLevel:1)
        }
    }
    
    @IBOutlet var replicationModeIsOnNCTSegmentedControl : NCTSegmentedControl?

    @IBAction func changeReplicationModeIsOn(_ sender : NCTSegmentedControl)
    {
        replicationModeIsOn = sender.onOffSwitchBool;
    }
    
    
    
    var replicationOutputIsSingleDrawable : Bool = true
    {
        didSet
        {
            
        }
    }

    

       // MARK: -
        // MARK: NOISE



    var noisingOfLinesIsOn : Bool = false
    {
        didSet
        {
            if(noisingOfLinesIsOn == true)
            {
                noiseConfigurationViewController!.updateNoiseSource();
            }
            else
            {
                fmInk.gkPerlinNoiseWithAmplitude = nil;
            }
            
            noisingOfLinesIsOnNCTSegmentedControl?.setOnOffFromBool(bool: noisingOfLinesIsOn)
            
            
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "noising mode\n \(noisingOfLinesIsOn ? "on" : "off")", duration: self.messageIndicatorPresenceDuration, messageLevel:1)
            
        }
    }
    
    @IBOutlet var noisingOfLinesIsOnNCTSegmentedControl : NCTSegmentedControl?
    
    @IBAction func changeNoisingOfLinesIsOn(_ sender : NCTSegmentedControl)
    {
        noisingOfLinesIsOn = sender.onOffSwitchBool;
    }

    // MARK: -
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: LINE DASH

    var currentLineDash : LineDash = LineDash.init(dashArray: [])
    {
        didSet
        {
        
        }
    
    }

    var lineDash : LineDash
    {
        set{
        
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                for d in lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables
                {
                    var e: NSBezierPath = d;
                    newValue.applyLineDashToBezierPath(path: &e)
                }
                
               // lineWorkInteractionEntity!.currentPaperLayer!.updateDynamicTreeProxyBoundsForSelectedDrawables();
                lineWorkInteractionEntity!.currentPaperLayer!.redisplaySelectedTotalRegionRect();
                
            }
            else
            {
                currentLineDash = newValue
                lineWorkInteractionEntity?.syncCurrentFMDrawableToInkSettings();
                
                //lineDash.applyLineDashToBezierPath(path: &d)

                
            }
            
            DispatchQueue.main.async
            {
                self.brushTipWidthPaletteSegmentedControl.needsDisplay = true;
            }
            
        }
        
        get
        {
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                return lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables.first!.lineDash()
            }
            else
            {
                return currentLineDash
            }
        
        
        }
    
    }


    @IBOutlet var dashArrayPopUpButton : NSPopUpButton?
    @IBAction func changeLineDashFromPopUpButton(_ sender : NSPopUpButton)
    {
        if let lineDashFromSelected = sender.selectedItem?.representedObject as? LineDash
        {
            lineDash = lineDashFromSelected;
        }
    }
    
    var lineDashArraysArray : [LineDash] = [
    LineDash.init(dashArray: []),
    LineDash.init(dashArray: [1,1]),
    LineDash.init(dashArray: [1,2]),
    LineDash.init(dashArray: [2,4]),
    LineDash.init(dashArray: [5,6]),
    LineDash.init(dashArray: [3,4]),
    LineDash.init(dashArray: [1,5,1]),
    ]




 
    // MARK: -
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: LOADED OBJECT
    var loadedObject : FMDrawable = FMDrawable()
    {
        didSet
        {
            self.appDelegate?.currentFMDocument?.drawingPageController?.fadeInOutMessageIndicatorWithMessage(string: "new loaded object", duration: self.messageIndicatorPresenceDuration, messageLevel:1)
          
            
            //loadedObjectPreview?.image = loadedObject.image(sizeForRescale: loadedObjectPreview?.bounds.size ?? .zero, boundsPadding: 1) {                 loadedObject.display();
 
            
            
            let imgForPreview = loadedObject.image(sizeForRescale: loadedObjectPreview?.bounds.size ?? .zero, boundsPadding: 0, untranslatedDrawingBounds: loadedObject.renderBounds(), drawingCode: {
                loadedObject.display();
            }, flippedImage:false)
            
            loadedObjectPreview?.image = imgForPreview
            loadedObjectPreviewForShapeKeysConfig?.image = imgForPreview
            
            
            loadedObjectPreview?.needsDisplay = true;
            loadedObjectPreviewForShapeKeysConfig?.needsDisplay = true;

        }
    }

    @IBOutlet var loadedObjectPreview : NSImageView?;
    @IBOutlet var loadedObjectPreviewForShapeKeysConfig : NSImageView?;
    
    // MARK: -


    
    
    // MARK: -
    // ---------------------------------------------
    
    var allowStatusMessagesBecauseOfKeypress : Bool = false;
        
    var statusMessageMaxmimumPriorityLevel : Int = 5
    {
        didSet
        {
            statusMessageMaxmimumPriorityLevel = statusMessageMaxmimumPriorityLevel.clamped(to: 1...5);
            statusMessageMaxmimumPriorityLevelSlider?.integerValue = statusMessageMaxmimumPriorityLevel;
        }
    }

    @IBOutlet var statusMessageMaxmimumPriorityLevelSlider : NCTSlider?
   
    @IBAction func changeStatusMessageMaximumPriorityLevel(_ sender: NSSlider)
    {
        statusMessageMaxmimumPriorityLevel = sender.integerValue;
    }
    

    var statusMessagesIsOn : Bool = true
    {
        didSet
        {
            statusMessagesIsOnNCTSegmControl?.selectedSegment = statusMessagesIsOn.onOffSwitchInt
        }
    }

    
    @IBOutlet var statusMessagesIsOnNCTSegmControl : NCTSegmentedControl?
    
    @IBAction func changeStatusMessagesIsOn(_ sender: NCTSegmentedControl)
    {
    
            statusMessagesIsOn = sender.onOffSwitchBool;

    }
    
     
    // -------------
    // suspends message indicator in
    // document.updateSelfToReflectPanelsWithDocumentSpecificSettings
    // so that turning off message indicator temporarily
    // does not change any visible control.
    // -------------
    var suspendMessageIndicator : Bool = false;
   
   
   
    // MARK: jumpToPanelBoxOnCommands
    var jumpToPanelBoxAfterRelevantCommand : Bool = true
    {
        didSet
        {
            jumpToPanelBoxAfterRelevantCommandNCTSegmControl?.selectedSegment = jumpToPanelBoxAfterRelevantCommand.onOffSwitchInt;
        }
    }
    
    @IBOutlet var jumpToPanelBoxAfterRelevantCommandNCTSegmControl : NCTSegmentedControl?
    
    @IBAction func changeJumpToPanelBoxAfterRelevantCommand(_ sender: NCTSegmentedControl)
    {
    
            jumpToPanelBoxAfterRelevantCommand = sender.onOffSwitchBool;

    }


 
 
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: LOAD SETTINGS
    func loadSettings()
    {
    
        suspendMessageIndicator = true;
        
        dashArrayPopUpButton?.menu?.removeAllItems();
        //dashArrayPopUpButton?.addItem(withTitle: "no dash")
        for (index,lineDash) in lineDashArraysArray.enumerated()
        {
            let m = NSMenuItem.init();
            
            m.representedObject = lineDash
            let lineDashViewForMenuItem = lineDash.lineDashMenuItemView();
            lineDashViewForMenuItem.frame = dashArrayPopUpButton!.frame
            if(index == (lineDashArraysArray.count - 1))
            {
                lineDashViewForMenuItem.makeCustomMode()
            }
            
            m.view = lineDashViewForMenuItem
            
            //m.view?.frame = dashArrayPopUpButton!.frame
            dashArrayPopUpButton?.menu?.addItem(m)
            
        }
        
        
        // STROKE CHARACTERISTICS


        // MARK: APPLIES TO CURRENT POINT OR ENTIRE STROKE
        appliesToEntireStroke = false;

        // MARK: WIDTH PALETTE panel
        brushTipWidthPaletteSegmentedControl.selectedSegment = 10//2;
        startingStrokeWidth = 1.0;  // first was 5.0
        coefficient = 1.5; // first was 2.0
        customSlotStrokeWidth = 55.0;
        azimuthDegrees = 0//20;
        altitudeDegrees = 45;
        heightFactor = 0.2;

        // MARK:  COLOR PALETTE PANEL SETTINGS
//        colorPaletteSegmentedControl.selectedSegment = 0;
        
        let colorToLoad = NSColor.black
        
        fmInk = FMInk.init(inkColor: NSColor.black, brushTip: FMBrushTip.ellipse)
        loadFMInkSetting()
        currentStrokeColor = colorToLoad

        
        
        
        // MARK: DRAWING SETTINGS PANEL SETTINGS
        
        // MARK: bowed line
        // DRAWING SETTINGS PANEL: BOWED LINE
        bowedLineNormalHeightFixed = 10.0;
        bowedLineNormalHeightPercentage = 10.0;
        bowedLineNormalHeightIsPercentageOfLineLength = true;
        bowedLineInterpolationLocation = 0.5;
        bowedLineInterpolationLocationMultiplier = 1.0;
        bowedLineInterpolationDualDistance = 0;
        bowedLineMakeCornered = false;
        bowedLineCorneredAsHard = false;
        
        // MARK: b-spline
        // DRAWING SETTINGS PANEL: B-SPLINE
        showStrokeControlPoints = false;
        showAllControlPoints = false;
        
        // MARK: snapping
        // DRAWING SETTINGS PANEL: SNAPPING
        angleSnapping = false;
        angleSnappingInterval = 15.0;
        lengthSnapping = false;
        lengthSnappingInterval = 25.0;
        pointsSnapping = false;
        pathsSnapping = false;
        alignmentPointLinesSnapping = false;
        
        connectLivePathToPaths = true;
        
        // MARK: uniformTipMode
        // DRAWING SETTINGS PANEL: UNIFORM TIP MODE
        uniformTipLineCapStyle = .butt
        uniformTipLineJoinStyle = .miter;

        // DRAWING SETTINGS PANEL: CORNER ROUNDING
        cornerRounding = 5.0
        cornerRoundingType = .bSpline

        // MARK: perspective mode
        // DRAWING SETTINGS PANEL: PERSPECTIVE
        vanishingPointGuides = false;
        vanishingPointCount = 2;
        // separated and sits in the vanishing point mode
        vanishingPointLinesSnapping = true;
        vanishingPointLinesSnappingAngleRange = 10.0;

        // MARK: combinatorics mode
        // DRAWING SETTINGS PANEL: COMBINATORICS MODE
        combinatoricsModeIsOn = false;
        combinatoricsMode = .union;
        unionWithLastDrawnShapeForDrawing = false;
        receiverDeterminesStyle = true;
        depositIfNoOverlap = false;
        separateSubtractionPieces = true;
        
        // MARK: replication mode
        // DRAWING SETTINGS PANEL: REPLICATION MODE
        replicationModeIsOn = false;
        
        // MARK: noising of lines mode
        // DRAWING SETTINGS PANEL: NOISING OF LINES
        noisingOfLinesIsOn = false;
        noiseConfigurationViewController!.updateNoiseSource();
        noiseConfigurationViewController!.loadSettings(dict: nil);
        
        
        // MARK: vector accuracy
        // DRAWING SETTINGS PANEL: VECTOR ACCURACY

        distanceForOvalAndChiselLiveInterpolation = 15.0;
        distanceForOvalAndChiselFinalInterpolation = 10.0;
        finalSimplificationToleranceForOvalAndChisel = 1.0;
        
        distanceForUniformLiveInterpolation = 1.0;
        distanceForUniformFinalInterpolation = 1.0;
        finalSimplificationToleranceForUniform = 0.2;

        // MARK: representationMode
        fmRepresentationMode = .inkColorIsFillOnly
        
        // MARK: bezierPathStrokeWidth
        bezierPathStrokeWidthSelected = 1.0
        bezierPathStrokeWidth = 1.0;
        
        // MARK: shadingShapesModeIsOn, strokesAddShadeForSS
        shadingShapesModeIsOn = false;
        strokesAddShadeForSS = false;
        
        // MARK: palette keys extras
        // DRAWING SETTINGS PANEL: PALETTE KEYS
        usesAlternatePalettes = true;
        usesPushPullRelToPaletteKeys = true;
        
        // MARK: status messages
        statusMessagesIsOn = true;
        statusMessageMaxmimumPriorityLevel = 3;
        jumpToPanelBoxAfterRelevantCommand = true;
        
        // MARK: loaded object
        loadedObject.removeAllPoints();
        loadedObject.fmInk = self.fmInk;
        loadedObject.fmInk.mainColor = .green;
        let r = NSMakeRect(0, 0, 100, 100)
        loadedObject.appendRoundedRect(r, xRadius: 10, yRadius: 10);

        suspendMessageIndicator = false;
        
        // MARK: replicationConfigurationViewController
        lineWorkInteractionEntity?.replicationConfigurationViewController?.loadSettings(dict: nil)
    }

   
    
    
    
    // MARK: LOAD CURRENT DOCUMENT'S SPECIFIC SETTINGS
    func loadDocumentSpecificSettingsForCurrentDocument()
    {
        suspendMessageIndicator = true;
        
        updateCombinatoricsKeysVisibility();
        updatePullPushRelToPaletteVisibility();
        
        suspendMessageIndicator = false;
    }

    func updateCombinatoricsKeysVisibility()
    {
        if (lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection) || (combinatoricsModeIsOn)
        {
            let thereAreGreaterThanOne = (lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables.count > 1)
    
            let displayStateIsHidden = !(thereAreGreaterThanOne || combinatoricsModeIsOn)
            // The combinatorics keys
            self.appDelegate!.registeredButtonKeyCodesToButtonObjects[43]?.isHidden = displayStateIsHidden
            self.appDelegate!.registeredButtonKeyCodesToButtonObjects[47]?.isHidden = displayStateIsHidden
            self.appDelegate!.registeredButtonKeyCodesToButtonObjects[44]?.isHidden = displayStateIsHidden
        }
        else
        {
            self.appDelegate!.registeredButtonKeyCodesToButtonObjects[43]?.isHidden = true
            self.appDelegate!.registeredButtonKeyCodesToButtonObjects[47]?.isHidden = true
            self.appDelegate!.registeredButtonKeyCodesToButtonObjects[44]?.isHidden = true
        }
        
    }
    
    func updatePullPushRelToPaletteVisibility()
    {
        // ---------------
        // Using alphaValue instead of
        // isHidden prevents titlebarView from
        // making inkSettingsPanel key.
        // ---------------
    
        if(usesPushPullRelToPaletteKeys == false)
        {
            self.appDelegate!.pushAndPullRelToPaletteTitlebarView!.alphaValue = 0.0
        
        }
        else
        {
            if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
            {
                self.appDelegate!.pushAndPullRelToPaletteTitlebarView!.alphaValue = 1.0
            }
            else
            {
            self.appDelegate!.pushAndPullRelToPaletteTitlebarView!.alphaValue = 0.0
            }
        }
    }

    // MARK: -
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: COMPILE LIST OF PANELBOXES
    
    @IBOutlet var panelBoxesScrollView : NSScrollView?
    @IBOutlet var panelBoxesView : NCTFlippedNSView?
    
    var panelBoxesAreInListArrangement : Bool = false
    {
        didSet
        {
        
        }
    }
    
    var panelBoxes : [NCTPanelBox1] = [];
    var jumpBarPopUpButton : NSPopUpButton?
    
    @IBOutlet weak var jumpBarViewForDrawingSettings: NCTFlippedNSView!
    
    func compileListOfPanelBoxes()
    {
        guard ((panelBoxesView != nil) && (panelBoxesScrollView != nil)) else {
            print("panelBoxesView nil, not available for list of panel boxes compilation");
            return;
        }
        
        panelBoxesScrollView!.scrollerStyle = NSScroller.Style.legacy
        panelBoxesScrollView!.hasHorizontalScroller = false;
        
        for view in panelBoxesView!.subviews
        {
            if let panelBox = view as? NCTPanelBox1
            {
                if (panelBox.isInUse)
                {
                    panelBoxes.append(panelBox)
                }
            }
        }
        
        panelBoxesView!.subviews = [];
        
        

        
        
        
        let panelBoxSpacing : CGFloat = 10.0;
        let panelBoxWidth : CGFloat = 180.0;
        let topMargin : CGFloat = 0.0;
        
 
        // JUMPBAR POPUPBUTTON
        jumpBarPopUpButton = NSPopUpButton.init(frame: NSRect.init(x: 3, y: 3, width: panelBoxWidth - 5 /*+ 20*/, height: 30))
        let popUpButton = jumpBarPopUpButton!;
        
        let inactiveMenuItemForTitle = NSMenuItem.init()
        inactiveMenuItemForTitle.attributedTitle = NSAttributedString.init(string: "Jump to Section...", attributes: [NSAttributedString.Key.foregroundColor : NSColor.black])
//        inactiveMenuItemForTitle.isEnabled = false;
        
        popUpButton.menu?.addItem(inactiveMenuItemForTitle)
        
        
        
        popUpButton.target = self;
        popUpButton.action = #selector(jumpToDrawingSettingsPanelBox(_:))
        popUpButton.pullsDown = true;
        
        
        
        var yCoordinate : CGFloat = topMargin + (panelBoxSpacing / 2.0);
        for (_, panelBox) in panelBoxes.enumerated()
        {
            panelBox.setFrameSize(NSMakeSize(panelBoxWidth,panelBox.frame.size.height))
            panelBox.setFrameOrigin(NSMakePoint(panelBoxSpacing / 2.0, yCoordinate))
            panelBox.autoresizingMask = .maxYMargin;
            yCoordinate += panelBox.frame.size.height + panelBoxSpacing
            panelBoxesView!.addSubview(panelBox)

            let item = NSMenuItem.init()

            item.attributedTitle = NSAttributedString.init(string: panelBox.labelText as String, attributes: [NSAttributedString.Key.foregroundColor : panelBox.fontColor, .backgroundColor : panelBox.fillColor.blended(withFraction: 0.5, of: NSColor.black) ?? .black, .font : NSFont.systemFont(ofSize: 17, weight: NSFont.Weight.bold)])
            
            popUpButton.menu?.addItem(item)
            //popUpButton.addItem(withTitle: panelBox.labelText.lowercased as String)

        }
        

        
        panelBoxesView!.window!.setWidthOfWindow(panelBoxWidth + 25.0)

        panelBoxesView!.setFrameSize(NSMakeSize(panelBoxWidth + 10, yCoordinate))
        panelBoxesView!.window!.maxSize = NSMakeSize(panelBoxWidth + 25.0, 5000)
        panelBoxesView!.window!.minSize = NSMakeSize(panelBoxWidth + 25.0, 200)

   
        // ADD POPUPBUTTON
        jumpBarViewForDrawingSettings.addSubview(popUpButton)


    }
    
    @IBAction func jumpToDrawingSettingsPanelBox(_ sender : NSPopUpButton)
    {



        let firstIndex = panelBoxes.firstIndex(where: {$0.labelText as String == sender.selectedItem!.title.uppercased()})
        
        if( firstIndex != nil)
        {
//            print(panelBoxes[firstIndex!].frame)
           // panelBoxesView!.scroll(panelBoxes[firstIndex!].frame.origin.offsetBy(x: 0, y: 4))
           
           
            // -----------------------
            // PREVENTS HIGHLIGHTS BECAUSE
            // ANIMATION MOVES CURSOR ACROSS
            // CONTROLS AND ACTIVATES MOUSEENTERED, BUT NOT MOUSEEXITED
            // --------------------
            var firstMousePosition = NSEvent.mouseLocation
            
            firstMousePosition.y = NSScreen.main!.frame.height -  firstMousePosition.y
            
            let pointInWindow = sender.convert(NSPoint.zero, to: nil)
            let pointOnScreen = sender.window!.convertToScreen(NSRect(origin: pointInWindow, size: .zero)).origin

            NSCursor.hide()
            CGWarpMouseCursorPosition(pointOnScreen)
           
            panelBoxesScrollView?.scroll(to: panelBoxes[firstIndex!].frame.origin.offsetBy(x: 0, y: 4), animationDuration: 0.35)
           
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { timer in
                
                CGWarpMouseCursorPosition(firstMousePosition)
                
                NSCursor.unhide()
            }
            
            
            
           
        }
        
    }
    
    
    func jumpToPanelBoxAfterRelevantCommand(panelBoxNamed:String)
    {
        guard jumpToPanelBoxAfterRelevantCommand else
        {
            return;
        }
    
        guard suspendMessageIndicator != true else {
            return;
        }
    
         let firstIndex = panelBoxes.firstIndex(where: {$0.labelText as String == panelBoxNamed})
        
        if( firstIndex != nil)
        {
//            print(panelBoxes[firstIndex!].frame)
           // panelBoxesView!.scroll(panelBoxes[firstIndex!].frame.origin.offsetBy(x: 0, y: 4))
           
           
            // -----------------------
            // PREVENTS HIGHLIGHTS BECAUSE
            // ANIMATION MOVES CURSOR ACROSS
            // CONTROLS AND ACTIVATES MOUSEENTERED, BUT NOT MOUSEEXITED
            // --------------------
            /*
            var firstMousePosition = NSEvent.mouseLocation
            
            firstMousePosition.y = NSScreen.main!.frame.height -  firstMousePosition.y
            
            let pointInWindow = sender.convert(NSPoint.zero, to: nil)
            let pointOnScreen = sender.window!.convertToScreen(NSRect(origin: pointInWindow, size: .zero)).origin

            NSCursor.hide()
            CGWarpMouseCursorPosition(pointOnScreen)
           */
            panelBoxesScrollView?.scroll(to: panelBoxes[firstIndex!].frame.origin.offsetBy(x: 0, y: 4), animationDuration: 0.25)
           
            /*
            _ = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { timer in
                
                CGWarpMouseCursorPosition(firstMousePosition)
                
                NSCursor.unhide()
            }
            */
            
            
            
           
        }
    
    }
    
    
    
    // ---------------------------------------------
    // ---------------------------------------------
    // MARK: AWAKE FROM NIB
    override func awakeFromNib()
    {
        DispatchQueue.main.async {
       // called in AppDelegate
       // self.compileListOfPanelBoxes();
        self.loadSettings()
            
        }
        
    }

}



enum CombinatoricsDrawingMode : Int
{
    
    
    case subtraction = 0;
    case intersection = 1;
    case union = 2;
    
    func stringValue() -> String
    {
        switch self
        {
        case .subtraction:
            return "subtraction"
        case .intersection:
            return "intersection"
        case .union:
            return "union"
        }
    
    }
    
}


