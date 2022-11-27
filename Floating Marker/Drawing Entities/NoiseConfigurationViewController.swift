//
//  NoiseConfigurationViewController.swift
//  Graphite Glider Preview
//
//  Created by John Pratt on 4/29/20.
//  Copyright © 2020 Noctivagous, Inc. All rights reserved.
//

import Cocoa
import GameplayKit.GKNoise
class NoiseConfigurationViewController: NSViewController, NSPopoverDelegate
{

    //@IBOutlet var configurationWindowManager : ConfigurationWindowManager!
    
    var perlinNoiseSource : GKPerlinNoiseSource!
    var gkNoise : GKNoise!
    var gkNoiseMap : GKNoiseMap!

    @IBOutlet var noisePopover : NSPopover!;
    @IBOutlet var noisePathPreview : NoisedPathPreview?
    @IBOutlet var noisePathPreview2 : NoisedPathPreview?

    var pathLengthMultiplier : CGFloat = 5;
    
    
    var seed : Int32 = Int32.random(in: 2...40);
    
    @IBAction func launchNoiseConfigPopover(_ sender : NCTButton?)
    {
            
        guard sender != nil else {
            return;
        }
        
       noisePopover.close();
       noisePopover.show(relativeTo: sender!.bounds, of: sender!, preferredEdge: NSRectEdge.minX)
    
    }
    
    @IBAction func launchNoiseConfigPopoverFromNoisePathPreview(_ sender : NoisedPathPreview?)
    {
    
        guard sender != nil else {
            return;
        }
        
        noisePopover.close();
        noisePopover.show(relativeTo: sender!.bounds, of: sender!, preferredEdge: NSRectEdge.minX)
    }
    
    
    func updateSeedIfNeeded()
    {
        if(self.newSeedEachTime)
        {
            seed = Int32.random(in: 2...40);
            
            updateNoiseSource()
        }
    
    }
    
    // MARK: ---  AMPLITUDE
    var amplitude : Float = 3
    {
        didSet
        {
            amplitudeTextField.floatValue = amplitude;
            amplitudeSlider.floatValue = amplitude;
            updateNoiseSource()
            updateNoisePathPreview();
        }
    }
    
    @IBOutlet var amplitudeTextField : NSTextField!
    @IBOutlet var amplitudeSlider : NSSlider!
    
    @IBAction func changeAmplitude(_ sender : NSControl)
    {
      /*  let storedNewSeedEachTime = self.newSeedEachTime
        if(sender.isContinuous)
        {
            newSeedEachTime = false;
        }*/
    
        amplitude = sender.floatValue;
    }
    
    // MARK: ---  FREQUENCY
    var frequency : Float = 1
    {
        didSet
        {
            frequencyTextField.floatValue = frequency;
            frequencySlider.floatValue = frequency;
            updateNoiseSource()
            updateNoisePathPreview();
        }
    }
    @IBOutlet var frequencyTextField : NSTextField!
    @IBOutlet var frequencySlider : NSSlider!
    @IBAction func changeFrequency(_ sender : NSControl)
    {
        frequency = sender.floatValue;
    }


    //  MARK: ---  OCTAVE COUNT
    var octaveCount : Int32 = 6
    {
        didSet
        {
            octaveCountTextField.intValue = octaveCount
            octaveCountSlider.intValue = octaveCount
            updateNoiseSource()
            updateNoisePathPreview();
        }
    }
    @IBOutlet var octaveCountTextField : NSTextField!
    @IBOutlet var octaveCountSlider : NSSlider!

    @IBAction func changeOctaveCount(_ sender : NSControl)
    {
        octaveCount = sender.intValue;
    }


    // MARK: ---  PERSISTENCE
    var persistence : Float = 0.5
    {
        didSet
        {
            persistenceTextField.floatValue = persistence
            persistenceSlider.floatValue = persistence;
            updateNoiseSource()
            updateNoisePathPreview();
        }
    }
    @IBOutlet var persistenceTextField : NSTextField!
    @IBOutlet var persistenceSlider : NSSlider!

    @IBAction func changePersistence(_ sender : NSControl)
    {
        persistence = sender.floatValue;
    }


    // MARK: ---  LACUNARITY
    var lacunarity : Float = 2
    {
        didSet
        {
            lacunarityTextField.floatValue = lacunarity
            lacunaritySlider.floatValue = lacunarity
            updateNoiseSource()
            updateNoisePathPreview();
        }
    }
    @IBOutlet var lacunarityTextField : NSTextField!
    @IBOutlet var lacunaritySlider : NSSlider!

    @IBAction func changeLacunarity(_ sender : NSControl)
    {
        lacunarity = sender.floatValue;
    }


    // MARK: ---  CHECKBOXES
    // MARK: ---  newSeedEachTime

    var newSeedEachTime : Bool = false
    {
        didSet
        {
            newSeedEachTimeCheckbox.state = newSeedEachTime.stateValue;
            updateNoiseSource();
            updateNoisePathPreview();
        }
    }
    @IBOutlet var newSeedEachTimeCheckbox : NSButton!;
    
    
    @IBAction func changeNewSeedEachTime(_ sender : NSButton)
    {
        newSeedEachTime = sender.boolFromState;
    }
    

    // MARK: ---  smoothResult
    var smoothResult : Bool = false
    {
        didSet
        {
            smoothResultCheckbox.state = smoothResult.stateValue;
            updateNoiseSource();
            updateNoisePathPreview();
        }
    }
    
    @IBOutlet var smoothResultCheckbox : NSButton!;

    @IBAction func changeSmoothResult(_ sender : NSButton)
    {
        smoothResult = sender.boolFromState;
    }
    
    
    var noisingMode : Int = 0
    {
        didSet
        {
            noisingModeNCTSegm?.selectedSegment = noisingMode
            updateNoiseSource();
        }
    }
    
    @IBOutlet var noisingModeNCTSegm : NCTSegmentedControl?
    
    @IBAction func changeNoisingMode(_ sender : NCTSegmentedControl)
    {
        noisingMode = sender.selectedSegment
    }
    
    
    // MARK: ---  useAbsoluteValues

    var useAbsoluteValues : Bool = true
    {
        didSet
        {
            useAbsoluteValuesCheckbox.state = useAbsoluteValues.stateValue;
            updateNoiseSource();
            updateNoisePathPreview();
        }
    }
    
    @IBAction func changeUseAbsoluteValues(_ sender : NSButton)
    {
        useAbsoluteValues = sender.boolFromState;
    }
    
    @IBOutlet var useAbsoluteValuesCheckbox : NSButton!;
    

   
    // REDUCE POINTS
    // MARK: ---  reducePoints

    var reducePoints : Bool = false
    {
        didSet
        {
            reducePointsCheckbox.state = reducePoints.stateValue;
            updateNoiseSource();
            updateNoisePathPreview();
        }
    }
    
    @IBAction func changeReducePoints(_ sender : NSButton)
    {
        reducePoints = sender.boolFromState;
    }
    
    @IBOutlet var reducePointsCheckbox : NSButton!;
    




    
    // MARK: ---  UPDATE NOISE
    @IBOutlet var inkAndLineSettingsManager : InkAndLineSettingsManager!
    
    func updateNoiseSource()
    {
    
        perlinNoiseSource =
                    GKPerlinNoiseSource(frequency: Double(frequency / 100.0) * 0.5 * Double(pathLengthMultiplier), octaveCount: Int(octaveCount), persistence: Double(persistence), lacunarity: Double(lacunarity), seed: self.seed)
            
        gkNoise = GKNoise(perlinNoiseSource);
        gkNoiseMap = GKNoiseMap(gkNoise);
        
        if(inkAndLineSettingsManager.noisingOfLinesIsOn)
        {
            inkAndLineSettingsManager.fmInk.gkPerlinNoiseWithAmplitude = perlinNoiseSourceUnmodifiedTuple();
        }
        
        
    }


   

    // -------
    // This is unmodified, which means the frequency does not
    // have the length of the path multplied on it.
    // The applyNoise... extension function for NSBezierPath uses this unmodified and finds
    // its own length for the path each time.
    // -------
    func perlinNoiseSourceUnmodifiedTuple() -> (GKPerlinNoiseSource,CGFloat, Bool, Int)
    {
        return(perlinNoiseSourceUnmodified(),CGFloat(amplitude), self.useAbsoluteValues, self.noisingMode);
    
    }
    
    func perlinNoiseSourceUnmodified() -> GKPerlinNoiseSource
    {
        return GKPerlinNoiseSource(frequency: Double(frequency), octaveCount: Int(octaveCount), persistence: Double(persistence), lacunarity: Double(lacunarity), seed: self.seed)
    
    }

    func updateNoisePathPreviewFromParameterChange()
    {
    
    }
    
    func updateNoisePathPreview()
    {
    
        guard noisePathPreview != nil else {
            return;
        }
        
        guard noisePathPreview2 != nil else {
            return;
        }
    
        pathLengthMultiplier = noisePathPreview!.bounds.size.width
        self.updateNoiseSource();
          
        noisePathPreview!.noisedPath = self.applyNoiseToPathFromSettingsForPreview(path: noisePathPreview!.equilibriumLine, updateSeed:false);
        noisePathPreview!.needsDisplay = true
        
        
        
        pathLengthMultiplier = noisePathPreview2!.bounds.size.width
        self.updateNoiseSource();
          
        noisePathPreview2!.noisedPath = self.applyNoiseToPathFromSettingsForPreview(path: noisePathPreview2!.equilibriumLine, updateSeed:false);
        noisePathPreview2!.needsDisplay = true
    }

    func applyNoiseToPathFromSettingsForPreview(path : NSBezierPath, updateSeed: Bool)  -> NSBezierPath
    {
    
    
        return self.applyNoiseToPath(path: path, amplitude: CGFloat(self.amplitude), reducePoints: self.reducePoints, smoothPath: self.smoothResult, updateSeed: updateSeed, useAbsoluteValues: self.useAbsoluteValues);
        
    }

    // prevents update of seed during live drawing
    func applyNoiseToPathFromSettingsForDrawing(path : NSBezierPath)  -> NSBezierPath
    {
    
        return self.applyNoiseToPath(path: path, amplitude: CGFloat(self.amplitude), reducePoints: self.reducePoints, smoothPath: self.smoothResult, updateSeed: false, useAbsoluteValues: useAbsoluteValues);
    
    }
    

    func applyNoiseToPath(path : NSBezierPath, amplitude: CGFloat, reducePoints : Bool, smoothPath: Bool, updateSeed: Bool, useAbsoluteValues: Bool) -> NSBezierPath
    {

            //return path.withZig(amplitude, zag: amplitude);
            //return path.withWavelength(50, amplitude: amplitude, spread: 1);
            
            if(updateSeed)
            {
                seed = Int32.random(in: 2...40);
            }

        
         
            var p : NSBezierPath = NSBezierPath();
            
            if(path.hasCurveTo)
            {
                p = path.flattened
            }
            else
            {
                p.append(path)
            }
            
            let pathLength : CGFloat = p.pathLengthForLineTo()//.length
            self.pathLengthMultiplier = pathLength;
            self.updateNoiseSource();
         
         
            p = p.withFragmentedLineSegments(1);
            
    
            
            let p2 = NSBezierPath();
            
            let pElementCount = p.elementCount;
            for e in 0..<pElementCount
            {
        
                
                let pathPosition = ( CGFloat(e) / CGFloat(pElementCount));
                
                
                let positionMappedForNoise = (2 * pathPosition ) - 1;
                
                var pArray :[NSPoint] = Array(repeating: NSPoint.zero, count: 3)
                let elementType : NSBezierPath.ElementType = p.element(at: e, associatedPoints: &pArray)
                
                //let value =  CGFloat( gkNoiseMap.interpolatedValue(at: simd_float2(repeating: Float(position) )) );
                var value = CGFloat( gkNoise.value(atPosition: simd_float2(repeating: Float(positionMappedForNoise)) ) );
                
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
            
            
            /*
            if(self.reducePoints)
            {
                let buildupModePoints = p2.buildupModePoints();
                
                var simplifiedPoints = SwiftSimplify.simplify(buildupModePoints, tolerance:
                                                                Float(0.5))
                p2.removeAllPoints();
                p2.appendPoints(&simplifiedPoints, count: simplifiedPoints.count)
            
                if(self.smoothResult)
                {
              //      let cgPath = CGPath.path(thatFits: simplifiedPoints)
            //        p2 = NSBezierPath.init(cgPath: cgPath)
                    
                }
            }
            */
            /*
            if(self.smoothResult && ())
            {
            CGPath.path(thatFits: <#T##[CGPoint]#>)
                p2.cgPath.path
               p2.makeCurve()
            }*/
    

        return p2;
    }
    
    override func awakeFromNib()
    {
        noisePopover.animates = false;
        noisePopover.behavior = NSPopover.Behavior.transient
        
        
        amplitude = 15;
        frequency = 1;
        octaveCount = 6
        persistence = 0.5;
        lacunarity = 2;
        
        newSeedEachTime = true;
        
        updateNoiseSource();
        updateNoisePathPreview();
        
    
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func loadSettings(dict : Dictionary<String,Any>?)
    {
        resetSettingsToDefault();
        updateNoiseSource();
    }
    
    func resetSettingsToDefault()
    {
        amplitude = 3.0;
        frequency = 1.0;
        lacunarity = 2
        octaveCount = 6
        persistence = 0.5;
        newSeedEachTime = true;
        useAbsoluteValues = true;
        
    }
    
    @IBAction func resetNoiseSettingsToDefault(_ sender : NSControl)
    {
        resetSettingsToDefault()
    }

    // MARK: -
    // MARK: POPOVER DELEGATE METHODS
    
    func popoverShouldDetach(_ popover: NSPopover) -> Bool
    {
        return true;
    
    
    }
    
    
    
}// END NoiseConfigViewContr

class NoisedPathPreview: NSControl
{
    
    @IBInspectable var isClickable : Bool = false;
    
    @IBInspectable var showsMiddleLine : Bool = true;
    @IBInspectable var middleLineStrokeColor : NSColor = .lightGray;

    
    @IBInspectable var backgroundColor : NSColor = .white;
    @IBInspectable var noisedLineStrokeColor : NSColor = .black;
    @IBInspectable var strokeBorder: Bool = false;
    @IBInspectable var borderStrokeColor : NSColor = .black;
    
    var equilibriumLine : NSBezierPath
    {
        get
        {
            let p = NSBezierPath();
            p.move(to: NSMakePoint(self.bounds.minX, self.bounds.midY))
            p.line(to: NSMakePoint(self.bounds.maxX, self.bounds.midY))
            return p
        }
    }
    
    var noisedPath : NSBezierPath = NSBezierPath();
    
    
    func updateNoisedPath(noiseObj : GKNoise)
    {
    
        noisedPath.removeAllPoints();
        noisedPath.move(to: NSMakePoint(self.bounds.minX, self.bounds.midY))
        noisedPath.line(to: NSMakePoint(self.bounds.maxX, self.bounds.midY))
        
        noisedPath = noisedPath.withFragmentedLineSegments(1)
    
        let p2 = NSBezierPath();
            for e in 0..<noisedPath.elementCount
            {
                let pathPosition = ( CGFloat(e) / CGFloat(noisedPath.elementCount));
                let position = (2 * pathPosition   ) - 1;
                var pArray :[NSPoint] = Array(repeating: NSPoint.zero, count: 3)
                let elementType : NSBezierPath.ElementType = noisedPath.element(at: e, associatedPoints: &pArray)
                
                let value = CGFloat( noiseObj.value(atPosition: simd_float2(repeating: Float(position)) ) );
                
                let normalValue = noisedPath.getNormalForPosition(pathPosition);                let multiplier :CGFloat = 30;
                
                
                if(elementType == .moveTo)
                {
                     p2.move(to: pArray[0])
                }
                else if(elementType == .lineTo)
                {
                
                    let x = pArray[0].x + (cos(deg2rad(normalValue)) * multiplier * value)
                    let y = pArray[0].y + (sin(deg2rad(normalValue)) * multiplier * value)
                   
                    let p =  NSMakePoint(x,y )
                    p2.line( to:p )
                
                }
                
                
                 //   pArray[0].x = pArray[0].x + (cos(radians(normalValue)) * multiplier * value)
                   // pArray[0].y = pArray[0].y + (sin(radians(normalValue)) * multiplier * value)
               
                
              //  noisedPath.setAssociatedPoints(&pArray, at: e)
                
            }
        
        noisedPath.removeAllPoints();
        noisedPath.append(p2)
        self.needsDisplay = true;
    }
    
    override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            
    }
        
    required init?(coder decoder: NSCoder) {
            super.init(coder:decoder)
            
    }

    override func draw(_ dirtyRect: NSRect)
    {

            if(mouseIsDown)
            {
                (backgroundColor.blended(withFraction: 0.75, of: NSColor.black) ?? .black).setFill()

            }
            else if(mouseIsInside)
            {
                (backgroundColor.blended(withFraction: 0.5, of: NSColor.black) ?? .black).setFill()
            }
            else
            {
                backgroundColor.setFill()
            }
            dirtyRect.fill()
            
            if(showsMiddleLine)
            {
                middleLineStrokeColor.setStroke();
                
                let p = NSBezierPath.init()
                p.move(to: NSMakePoint(self.bounds.minX, self.bounds.midY))
                p.line(to: NSMakePoint(self.bounds.maxX, self.bounds.midY))
                var d : [CGFloat] = [2,4];
                p.setLineDash(&d, count: 2, phase: 0)
                p.stroke();
            }
            
            noisedLineStrokeColor.setStroke();
            noisedPath.stroke();
            
            if(strokeBorder)
            {
                if(mouseIsInside)
                {
                    NSColor.green.setFill();
                }
                else
                {
                    borderStrokeColor.setFill()
                }
                self.bounds.frame(withWidth: 2.0, using: NSCompositingOperation.sourceOver)
            }
            
    }

    override func mouseDown(with event: NSEvent)
    {
        mouseIsDown = true
        self.needsDisplay = true

        
  
    }
    
    
    override func mouseUp(with event: NSEvent) {
        mouseIsDown = false
        self.needsDisplay = true
 
        if(self.target != nil)
        {
            self.sendAction(self.action, to: self.target)
        }
    }
    
    
    var mouseIsDown : Bool = false;
    var mouseIsInside : Bool = false;
    override func mouseEntered(with event: NSEvent)
    {
        if(isClickable)
        {
            mouseIsInside = true;
            self.needsDisplay = true
        }
    }
    
    override func mouseExited(with event: NSEvent)
    {
        if(isClickable)
        {
            mouseIsInside = false;
            self.needsDisplay = true
        }
        
    }
    
     override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true;
     }


    var trackingArea = NSTrackingArea();
    override func viewDidMoveToWindow()
    {
        
        
        
        // for mouseEntered and Exited events
        let options = NSTrackingArea.Options.mouseEnteredAndExited.rawValue |
            NSTrackingArea.Options.activeAlways.rawValue;
        
        trackingArea = NSTrackingArea(rect: self.bounds, options: NSTrackingArea.Options(rawValue: options), owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
    
    // for keydown
    override var acceptsFirstResponder: Bool { return false }
    
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited,.mouseMoved],
                                      owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
        
        
    }
}
