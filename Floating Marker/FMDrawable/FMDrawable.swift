//
//  Drawable.swift
//  Floating Marker
//
//  Created by John Pratt on 2/7/21.
//

import Cocoa
import PencilKit
import GameplayKit.GKNoise

// Representation
enum RepresentationMode : String
{
    case inkColorIsStrokeOnly
    case inkColorIsFillOnly
    case inkColorIsStrokeAndFill
    case inkColorIsStrokeWithSeparateFill
    
    
}

enum PaintFillMode : String
{
    case solidColorFill = "solidFill"
    case gradient = "gradient"
    case noise = "noise"
    case hatching = "hatching"
    case pattern = "pattern"
    
    
    func rawIntEquiv() -> Int
    {
            let a = ["solidColorFill","gradient","noise","hatching","pattern"];

        return a.firstIndex(of: self.rawValue) ?? 0
    }
    
    init(rawIntEquiv:Int) {
        self = .solidColorFill
        self.setFromRawIntEquiv(int: rawIntEquiv)
    }
    
    mutating func setFromRawIntEquiv(int:Int)
    {
        let a = ["solidColorFill","gradient","noise","hatching","pattern"];

        if((int > -1) && (int < a.count))
        {
            self = PaintFillMode.init(rawValue: a[int]) ?? .solidColorFill
        }
    }
}





struct FMDrawableAggregratedSettings
{
    var fmInk : FMInk = FMInk.init(inkColor: NSColor.black, brushTip: FMBrushTip.rectangle)
    var lineWidth : CGFloat = 1.0;
    var lineJoinStyle : NSBezierPath.LineJoinStyle = .miter
    var lineCapStyle : NSBezierPath.LineCapStyle = .butt
    var miterLimit : CGFloat = 40.0;
    
    // LINE DASH
    var lineDashCount : Int = 0
    var lineDashPattern : [CGFloat] = []
    var lineDashPhase : CGFloat = 0.0

    func lineDash() -> LineDash
    {
        return LineDash.init(count: lineDashCount, pattern: lineDashPattern, phase: lineDashPhase)
    }

    init(
    fmInk:FMInk,
    lineWidth:CGFloat,
    lineJoinStyle:NSBezierPath.LineJoinStyle,
    lineCapStyle : NSBezierPath.LineCapStyle,
    miterLimit : CGFloat,
    lineDashCount : Int,
    lineDashPattern : [CGFloat],
    lineDashPhase : CGFloat
    )
    {
        self.fmInk = fmInk
        self.lineWidth = lineWidth
        self.lineJoinStyle = lineJoinStyle
        self.lineCapStyle = lineCapStyle
        self.miterLimit = miterLimit
        
        self.lineDashCount = lineDashCount
        self.lineDashPattern = lineDashPattern;
        self.lineDashPhase = lineDashPhase;
        
    }

    func applyToDrawable(fmDrawable: inout FMDrawable)
    {
        fmDrawable.fmInk = fmInk
        fmDrawable.lineWidth = lineWidth
        fmDrawable.lineJoinStyle = lineJoinStyle
        fmDrawable.lineCapStyle = lineCapStyle
        fmDrawable.miterLimit = miterLimit
        fmDrawable.setLineDash(lineDashPattern, count: lineDashCount, phase: lineDashPhase)
    }

    init(fmDrawable:FMDrawable) {
        
        fmInk = fmDrawable.fmInk
        fmInk.mainColor = fmDrawable.fmInk.mainColor
        fmInk.secondColor = fmDrawable.fmInk.secondColor
        lineWidth = fmDrawable.lineWidth
        lineJoinStyle = fmDrawable.lineJoinStyle
        lineCapStyle = fmDrawable.lineCapStyle
        miterLimit = fmDrawable.miterLimit
        
        var pattern : [CGFloat] = Array(repeatElement(0.0, count: 10))
        var count : Int = 1
        var phase : CGFloat = 0
        fmDrawable.getLineDash(&pattern, count: &count, phase: &phase)
       
        lineDashPattern = pattern
        lineDashCount = count
        lineDashPhase = phase
    }
    
}


struct FMInk
{
    
    var representationMode : RepresentationMode = .inkColorIsStrokeOnly
    var paintFillMode : PaintFillMode = .solidColorFill;
    
  
    
    var mainColor : NSColor = NSColor.init(red: 0, green: 0, blue: 0, alpha: 1.0);
    var secondColor : NSColor?
    
    var brushTip : FMBrushTip = .uniform;
    
    var isUniformPathThatIsStrokeOnly : Bool
    {
        return ((self.brushTip == .uniformPath) && (self.representationMode == .inkColorIsStrokeOnly))
    }
    
    var isUniformPathThatIsFillOnly : Bool
    {
        return (self.brushTip == .uniformPath) && (self.representationMode == .inkColorIsFillOnly)
    }
    
    init(inkColor:NSColor,brushTip:FMBrushTip) {
        self.mainColor = inkColor
        self.brushTip = brushTip
    }
    
    init(xmlElement:XMLElement)
    {
        mainColor = xmlElement.colorFromAttribute(attributeName: "mainColor", defaultVal: NSColor.black)
        
        representationMode = RepresentationMode.init(rawValue: xmlElement.stringFromAttribute(attributeName: "representationMode", defaultVal: "inkColorIsStrokeOnly")) ?? .inkColorIsStrokeOnly
        
        let  brushTipString = xmlElement.attribute(forName: "brushTip")?.stringValue ?? "uniform"
        brushTip = FMBrushTip.init(rawValue: brushTipString) ?? .uniform
        
    }

    
    // MARK: uniform tip features
    var uniformTipLineCapStyle : NSBezierPath.LineCapStyle = .square
    {
        didSet
        {
        }
        
    }
    
    var uniformTipLineJoinStyle : NSBezierPath.LineJoinStyle = .round
    {
        didSet
        {
        
        }
        
    }
    
    var uniformTipMiterLimit : CGFloat = 40.0
    {
        didSet
        {
        }
        
    }
    
    
    

    var gkPerlinNoiseWithAmplitude : (gkPerlinNoiseSource: GKPerlinNoiseSource,amplitude:CGFloat,useAbsoluteValues:Bool, noisingMode : Int)? = nil;
    
    var nctReplicatorStruct : NCTReplicatorStruct?

   


    // ---------------------
    // ---------------------
    // MARK: XMLELEMENT
    func xmlElement() -> XMLElement
    {
        let fmInkXMLToReturn = XMLElement.init(name: "fmkr:FMInk");
        
        
        let attributesStringDictionary : [String: String] =
            [ "brushTip":"\(brushTip.rawValue)",
              "mainColor":mainColor.xmlRGBAttributeStringContent(),
              "representationMode":"\(representationMode.rawValue)",
              
            ];
        
        
        fmInkXMLToReturn.setAttributesWith(attributesStringDictionary)
        
        
        
        return fmInkXMLToReturn;
    }
    
} // END FMInk

 struct Line {
        var point1 : CGPoint = CGPoint.zero
        var point2 : CGPoint = CGPoint.zero
        
    }
    

class FMDrawable: NSBezierPath, NSPasteboardWriting, NSPasteboardReading
{


    override init() {
        super.init()
    }


    var pasteboardTypeUTIForDrawableClass : NSPasteboard.PasteboardType
    {
    
    return NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmdrawable")
    }

    init(baseXMLElement: XMLElement, svgPath: String)
    {
        super.init()
        baseFMDrawableClassInitStep(baseXMLElement: baseXMLElement, svgPath: svgPath)
    
    }
    
    func baseFMDrawableClassInitStep(baseXMLElement: XMLElement, svgPath: String)
    {
        lineWidth = baseXMLElement.cgFloatFromAttribute(attributeName: "stroke-width", defaultVal: 1.0);
        
        let lineCapStr = baseXMLElement.stringFromAttribute(attributeName: "stroke-linecap", defaultVal: "butt")
        lineCapStyle = NSBezierPath.LineCapStyle.fromString(rawStringForValue: lineCapStr)
        
        let lineJoinStr = baseXMLElement.stringFromAttribute(attributeName: "stroke-linejoin", defaultVal: "miter")
        lineJoinStyle = NSBezierPath.LineJoinStyle.fromString(rawStringForValue: lineJoinStr)
        
        let windingRuleString = baseXMLElement.stringFromAttribute(attributeName: "fill-rule", defaultVal: "evenodd")
        if(windingRuleString == "evenodd")
        {
            windingRule = .evenOdd;
        }
        else
        {
            windingRule = .nonZero;
        }
        
        if let dashArrayAttribute = baseXMLElement.attribute(forName: "stroke-dasharray")
        {
            if let dashArrayString = dashArrayAttribute.stringValue
            {
                let dashArray = dashArrayString.components(separatedBy: ",")
                var dashArrayCGFloat : [CGFloat] = dashArray.map {  CGFloat(Double($0) ?? 1.0) }
                if(dashArrayCGFloat.count > 0)
                {
                    self.setLineDash(&dashArrayCGFloat, count: dashArrayCGFloat.count, phase: 0)
                }
            }
        
        }
        
        if(baseXMLElement.name != nil)
        {
            if(baseXMLElement.name == "path")
            {
                self.applyCommands(from: SVGPath(svgPath), offset: 0)
            }
        }
        
        
        do {

            // The first FMInk is the FMInk for the path
            // Use . for the current node, followed by // for all nodes matching
            // the tag name "fmkr:FMInk".
            let fmInkArr = try baseXMLElement.nodes(forXPath: ".//fmkr:FMInk")
            
            if(fmInkArr.isEmpty == false)
            {
            
                if let fmInkXMLElement = fmInkArr.first! as? XMLElement
                {
                    let fmInkForFMDrawable = FMInk.init(xmlElement: fmInkXMLElement)
                    
                    self.fmInk = fmInkForFMDrawable
                    
                    
                }
            }// END if(fmInkArr.isEmpty == false)
            
            findShadingShapesAndLoad(baseXMLElement:baseXMLElement)
        }
        catch
        {
        
        }
        
        
        
    }
    
    func secondaryStepForInit(baseXMLElement: XMLElement, svgPath: String)
    {
    
    }
    
    func findShadingShapesAndLoad(baseXMLElement: XMLElement)
    {
        if let appDelegate = NSApp.delegate as? AppDelegate
        {
            
            let shadingShapeFMDrawables = appDelegate.shadingShapesFromBaseXMLElement(baseXMLElement:baseXMLElement)
            
            if(shadingShapeFMDrawables != nil)
            {
                
                shadingShapesArray = [];
                shadingShapesArray?.append(contentsOf: shadingShapeFMDrawables!)
                
                for shadingShape in shadingShapesArray!
                {
                    shadingShape.actsAsShadingShape = true
                }
            }
            
        }
        
    }
    
    
    override func transform(using transform: AffineTransform) {
        super.transform(using: transform)


        if(shadingShapesArray != nil)
        {
            if(self.shadingShapesArray!.isEmpty == false)
            {
                for shadingShape in self.shadingShapesArray!
                {
                    shadingShape.transform(using: transform);
                }
            }
        }
        
    }

    var shapeName : String = "Shape"
/*
    init(fmDrawableXmlNode: XMLNode) {
        super.init()
        
        /*
        let dNode =  try xmlNode.nodes(forXPath: "@d")
        if(dNode.isEmpty == false)
        {
            if let s = dNode.first?.stringValue
            {
                let fmDrawable = FMDrawable.init(svgPath: s);
                paperLayerObj.arrayOfFMDrawables.append(fmDrawable)
            }
        }
        */
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }*/

    // MARK: INK STRUCTS
    var fmInk : FMInk = FMInk.init(inkColor: NSColor.black, brushTip: FMBrushTip.rectangle)
    {
        didSet
        {
//            pkInk.color = fmInk.color
        }
    }
    
    var pkInk : PKInk
    {
        get
        {
          return PKInk.init(PKInk.InkType.marker, color: fmInk.mainColor)
        }
    }

  

    public var debugRect : NSRect = .zero
    var debugIsOn : Bool = false
    
    var treeProxy : Int = 0
    var drawingOrderIndex: Int = -1
    var isSelected : Bool = false
    
    var isBeingCarted : Bool = false{
        didSet {
    //        self.adjustBasedOnCartingChange()
        }
    }
    
    var isBeingInspected : Bool = false;
    
    override func copy() -> Any
    {
        let fmDrawableCopy : FMDrawable = super.copy() as! FMDrawable

        fmDrawableCopy.fmInk = self.fmInk;
       
        if(shadingShapesArray != nil)
        {
            if(shadingShapesArray!.isEmpty == false)
            {
                fmDrawableCopy.shadingShapesArray = [];
                for shadingShape in shadingShapesArray!
                {
                    fmDrawableCopy.shadingShapesArray?.append(shadingShape.copy() as! FMDrawable)
                
                }
            }
        }

        return fmDrawableCopy

    }
    
    func standardRepresentationModeDisplay(path:NSBezierPath)
    {
        
        switch fmInk.representationMode
        {
        
        case .inkColorIsStrokeOnly:
            
            shadingShapesArrayDisplay()
            fmInk.mainColor.setStroke()
            path.stroke()
            
            
        case .inkColorIsFillOnly:
        
            standardPaintFillDisplay(path:path)
            shadingShapesArrayDisplay()
            
            
        case .inkColorIsStrokeAndFill:
        
            standardPaintFillDisplay(path:path)
            shadingShapesArrayDisplay()

            fmInk.mainColor.setStroke()
            path.stroke()
            
            
        case .inkColorIsStrokeWithSeparateFill:
            
            standardPaintFillDisplay(path:path)
            shadingShapesArrayDisplay()
            
            
            fmInk.mainColor.setStroke()
            path.stroke()
            
            
        }// END switch
        
        
    }
    

    
    func standardPaintFillDisplay(path:NSBezierPath)
    {
        guard path.isEmpty == false else {
            //print("standardPaintFillDisplay path isEmpty")
            return;
        }
        
        switch fmInk.representationMode
        {
        case .inkColorIsFillOnly:
            fmInk.mainColor.set()
            path.fill()
            
            
        case .inkColorIsStrokeAndFill:
            fmInk.mainColor.set()
            path.fill()
            
            
            
        case .inkColorIsStrokeWithSeparateFill:
            if(fmInk.secondColor != nil)
            {
                fmInk.secondColor?.setFill()
            }
            else
            {
                fmInk.mainColor.setFill()
                
            }
            path.fill()
            
        default:
            break;
            
        }// END switch
        
        standardNonSolidColorFillDisplay(path:path);
  
    }
    
    
    var patternImage : NSImage?
    
    func standardNonSolidColorFillDisplay(path:NSBezierPath)
    {
        
        
        if(fmInk.paintFillMode == .noise)
        {
            guard self.isEmpty == false else {
                return
            }
        
            NSGraphicsContext.current?.saveGraphicsState()
            self.addClip()

            /*
            let b = self.bounds
            for i in 0..<Int(b.height * b.width / 5)
            {
                let p = NSMakePoint(CGFloat.random(in: b.origin.x...b.origin.x + b.width), CGFloat.random(in: b.origin.y...b.origin.y + b.height))
                p.fillSquareAtPoint(sideLength: CGFloat(Int.random(in: 1...3)), color: .black)
                
            }
            */

//            img.draw(in: self.bounds)
            
            
            NSGraphicsContext.current?.restoreGraphicsState()

            
        
        }
        else if(fmInk.paintFillMode == .gradient)
        {
            let g = NSGradient.init(starting: .black, ending: .white)
            g?.draw(in: path, angle: 90);
        
        }
        else if(fmInk.paintFillMode == .pattern)
        {
        
        }
        else if(fmInk.paintFillMode == .hatching)
        {
        
        }
        
    }
    
    func shadingShapesArrayDisplay()
    {
    
        if(self.shadingShapesArray != nil)
        {
            guard (shadingShapesArray!.isEmpty != true)
            else{ return }
            
            NSGraphicsContext.current?.saveGraphicsState()
            
            self.addClip();
            
            for shadingShape in shadingShapesArray!
            {
                shadingShape.display();
            }
            
            
            NSGraphicsContext.current?.restoreGraphicsState();
        }
        
    }
    
    
    func display()
    {
    
        selectionShadowBeginSaveGState()
        
        standardRepresentationModeDisplay(path: self)
        
        selectionShadowRestoreGState()
    
    }
    
    @objc func display2()
    {
        selectionShadowBeginSaveGState()
        
        standardRepresentationModeDisplay(path: self)
        
        selectionShadowRestoreGState()

    }

    func renderBounds() -> NSRect
    {
        var rectToReturn = self.extendedBezierPathBounds;
        if(self.isSelected)
        {
           rectToReturn = rectToReturn.insetBy(dx: -8, dy: -8)
        }
    
        return rectToReturn;
    }
  
    
    func controlPointsBoundsForBSpline() -> NSRect
    {
    
        return .zero
    }
    
    func displayControlPoints()
    {
    
    }
    
    // MARK: HIT TEST FUNCTIONS
    
     func hitTestForClickBasedOnStrokeOrFillState(point: NSPoint) -> (didHit:Bool, wasStroke:Bool, wasShadingShape: Bool)
    {
        
        if(self.fmInk.representationMode != .inkColorIsStrokeOnly)
        {
            if( hitTestOnStrokeLines(point: point))
            {
                return (true, true, false)
            }
            else if(self.shadingShapesArray?.isEmpty == false)
            {
                if(hitTestInsideFilledShape(point:point))
                {
                    let b = self.bounds;
                    for shadingShape in shadingShapesArray!
                    {
                        
                        if(shadingShape.hitTestInsideFilledShape(point:point) && NSPointInRect(point, b))
                        {
                            return (true, false, true)
                        }
                        
                    }
                }
            }
            
            if(hitTestInsideFilledShape(point:point))
            {
                   return (true, false, false)
            }
            
        }
        else
        {
            if(self.shadingShapesArray?.isEmpty == false)
            {
                if(hitTestInsideFilledShape(point:point))
                {
                    let b = self.bounds;
                    for shadingShape in shadingShapesArray!
                    {
                        
                        if( (shadingShape.hitTestInsideFilledShape(point:point)) && NSPointInRect(point, b))
                        {
                            return (true, false, true)
                        }
                        
                    }
                }
            }
        
            return (hitTestOnStrokeLines(point: point), true, false)
        }
        
        return (false, false, false)
    
    
    }
    
    func hitTestInsideFilledShape(point: NSPoint) -> Bool
    {
        return self.contains(point)
    }
    
    func hitTestOnStrokeLines(point: NSPoint) -> Bool
    {
        return self.isStrokeHit(by:point)
    }
    
    
      
    func pathHitTest(point : NSPoint) -> (didHit:Bool, cgPoint: CGPoint, pkStrokePoint: PKStrokePoint?)
    {

        return (didHit:false, cgPoint: CGPoint.zero, pkStrokePoint: nil);
    }
    
    func pointHitTest(point : NSPoint) -> (didHit:Bool, cgPoint: CGPoint, pkStrokePoint: PKStrokePoint?)
    {
        // go through all bezier path element points
        // and see if intersection with point.
    
        return (didHit:false, cgPoint: CGPoint.zero, pkStrokePoint: nil);
    }
    
    
    
    // MARK: SELECTION OUTLINING
    
    func shouldShowSelectionShadow() -> Bool
    {
        return (self.isSelected && (self.actsAsShadingShape == false))
    }
    
    func selectionShadowBeginSaveGState()
    {
        if( shouldShowSelectionShadow() )
        {
            NSGraphicsContext.current?.saveGraphicsState()
            //NSGraphicsContext.current?.compositingOperation = .overlay
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 7.0
            shadow.shadowOffset = NSSize(width: 0, height: 0)
            shadow.shadowColor = isBeingCarted ? .green : NSColor.blue;
            
            /*
            // For when solid fills are selected so that active
            // changing of opacity is reflected
            if((self.fmInk.mainColor.alphaComponent != 1.0) && (fmInk.representationMode != .inkColorIsStrokeOnly))
            {
                shadow.shadowColor = shadow.shadowColor?.withAlphaComponent(self.fmInk.mainColor.alphaComponent)
            }
            */
            
            shadow.set()
            
        }
    }
    
    func selectionShadowRestoreGState()
    {
        if( shouldShowSelectionShadow() )
        {
            NSGraphicsContext.current?.restoreGraphicsState()
        }
    }
    
    
    // MARK: SHADING SHAPES
    
    // Shading shapes that the drawable carries
    var shadingShapesArray : [FMDrawable]? = [];
    
    // Settings for when the drawable acts as a shadingShape
    var actsAsShadingShape : Bool = false;
    var actsAsShadingShapeDictionary : Dictionary<String,Any> = ["usesHatching" : true, "hatchingSpacing": CGFloat(4.0), "hatchingRotation": CGFloat(45.0)/*CGFloat.random(in: 0.0 ... 360.0)*/, "hatchingLineWidth" : 1.0,];
    
    
    // MARK: XML ELEMENTS
    
    func applyFillAndStrokeSVGPathAttributes(pathSVGElement: inout XMLElement)
    {
        pathSVGElement.removeAttribute(forName: "stroke")
        
        pathSVGElement.removeAttribute(forName: "fill")
        
        if(self.fmInk.representationMode == .inkColorIsStrokeOnly)
        {
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "stroke", stringValue: fmInk.mainColor.xmlRGBAttributeStringContent()) as! XMLNode)
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "fill", stringValue: "none")as! XMLNode)
        }
        else if(self.fmInk.representationMode == .inkColorIsFillOnly)
        {
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "fill", stringValue: fmInk.mainColor.xmlRGBAttributeStringContent()) as! XMLNode)
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "stroke", stringValue: "none") as! XMLNode)
        }
        
        else if(self.fmInk.representationMode == .inkColorIsStrokeAndFill)
        {
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "stroke", stringValue: fmInk.mainColor.xmlRGBAttributeStringContent()) as! XMLNode)
            
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "fill", stringValue: fmInk.mainColor.xmlRGBAttributeStringContent()) as! XMLNode)
            
        }
        else if(self.fmInk.representationMode == .inkColorIsStrokeWithSeparateFill)
        {
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "stroke", stringValue: fmInk.mainColor.xmlRGBAttributeStringContent()) as! XMLNode)
            
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "fill", stringValue: (fmInk.secondColor != nil ) ? fmInk.secondColor!.xmlRGBAttributeStringContent() : fmInk.mainColor.xmlRGBAttributeStringContent()) as! XMLNode)
            
        }
        else
        {
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "stroke", stringValue: fmInk.mainColor.xmlRGBAttributeStringContent()) as! XMLNode)
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "fill", stringValue: "none") as! XMLNode)
            
        }
        
        
   
        // "\(Unmanaged.passUnretained(pathSVGElement).toOpaque())"
        
        
        
        if(actsAsShadingShape == false)
        {
            pathSVGElement.addAttribute(
                XMLNode.attribute(withName: "id", stringValue: "fmd\(drawingOrderIndex)") as! XMLNode
                
            )
            

        }
      
    }
    
    func applyAnyShadingShapes( xmlElementsToReturn: inout [XMLElement])
    {
        if(shadingShapesArray != nil)
        {
            if(shadingShapesArray!.isEmpty == false)
            {
                //    <g fmkr:GroupType="ShadingShapes">
                let gElement = XMLElement.init(name: "g")
                
                let clipPathElement = XMLElement.init(name: "clipPath")
                clipPathElement.addAttribute(XMLNode.attribute(withName: "id", stringValue: "clipMaskFor-fmd\(drawingOrderIndex)") as! XMLNode)

                let useElement = XMLElement.init(name: "use")
                useElement.setAttributesAs(["xlink:href":"#fmd\(drawingOrderIndex)"])
                
                clipPathElement.addChild(useElement)
                gElement.addChild(clipPathElement)

                for shadingShape in shadingShapesArray!
                {
                    let shadingShapeXMLElement = shadingShape.xmlElements(includeFMKRTags: false)[0]
                    shadingShapeXMLElement.removeAttribute(forName: "id")
                    shadingShapeXMLElement.addAttribute(XMLNode.attribute(withName: "clip-path", stringValue: "url(#clipMaskFor-fmd\(drawingOrderIndex))") as! XMLNode)
                    
                    gElement.addChild(shadingShapeXMLElement)

                }

                
                xmlElementsToReturn.append(gElement)
                // opportunity for file optimization, as
                // the shape is rendered twice here with <use>.
                if(self.fmInk.representationMode != .inkColorIsFillOnly)
                {
                    xmlElementsToReturn.append(useElement.copy() as! XMLElement)
                }
              
                
            }
        }
        
    }
    
    func xmlElements(includeFMKRTags:Bool) -> [XMLElement]
    {
        var xmlElementsToReturn : [XMLElement] = [];
    
        var pathSVGElement = bezierPathSVGXMLElement()
        
        xmlElementsToReturn.append(pathSVGElement)
        
        applyFillAndStrokeSVGPathAttributes(pathSVGElement: &pathSVGElement)
        applyAnyShadingShapes(xmlElementsToReturn: &xmlElementsToReturn)
        
       
        if(includeFMKRTags)
        {
        
            pathSVGElement.addAttribute(XMLNode.attribute(withName: "fmkr:DrawableType", stringValue: "FMDrawable") as! XMLNode)
        
            var fmDrawableElement = XMLElement.init(name: "fmkr:FMDrawable");
            
            addAccompanyingFMKRTagsInkShadingShapes(xmlElement: &fmDrawableElement)
            
            pathSVGElement.addChild(fmDrawableElement)
    
        }
        
        return xmlElementsToReturn;
        
    }
    
    func xmlElementsWrappedInSVG(includeFMKRTags:Bool) -> XMLElement
    {
        let xmlElements = xmlElements(includeFMKRTags: includeFMKRTags)
        
        let svgElement = svgRootElement;
        
        svgElement.setChildren(xmlElements)
        
        return svgElement
    
    }
    
    var svgRootElement : XMLElement
    {
        get
        {
         let rootSVGElement : XMLElement = XMLElement.init(name: "svg")

        rootSVGElement.addNamespace(XMLNode.namespace(withName: "", stringValue: "http://www.w3.org/2000/svg") as! XMLNode)
        rootSVGElement.addNamespace(XMLNode.namespace(withName: "svg", stringValue: "http://www.w3.org/2000/svg") as! XMLNode)
          rootSVGElement.addNamespace(XMLNode.namespace(withName: "fmkr", stringValue: "http://www.noctivagous.com/fmkr/") as! XMLNode)
         rootSVGElement.addNamespace(XMLNode.namespace(withName: "xlink", stringValue: "http://www.w3.org/1999/xlink") as! XMLNode)
        
        /*
         let w = drawingPageController!.canvasWidthForCurrentUnits
        let h = drawingPageController!.canvasHeightForCurrentUnits
        let units = drawingPageController!.canvasUnitsString
         rootSVGElement.attributes = [
            XMLNode.attribute(withName: "width", stringValue: "\(w)\(units)") as! XMLNode,
            
            XMLNode.attribute(withName: "height", stringValue: "\(h)\(units)")  as! XMLNode
            ]
        
        let svgDoc = XMLDocument.init(rootElement: rootSVGElement);
        svgDoc.version = "1.0"
        svgDoc.characterEncoding = "UTF-8"
        svgDoc.isStandalone = true;
        */
            return rootSVGElement;
        }
    
    }
    
    
  func addAccompanyingFMKRTagsInkShadingShapes(xmlElement: inout XMLElement)
    {
            // MARK: ADD fmkr:FMInk
            xmlElement.addChild(fmInk.xmlElement());
            
            if(actsAsShadingShape)
            {
                xmlElement.addAttribute(XMLNode.attribute(withName: "actsAsShadingShape", stringValue: "\(actsAsShadingShape)") as! XMLNode)
            }
            
            if(shadingShapesArray != nil)
            {
                if(shadingShapesArray!.isEmpty == false)
                {
                    xmlElement.addChild(self.shadingShapesFMKRXMLElement());
                }
            }
    }
    
    func shadingShapesFMKRXMLElement() -> XMLElement
    {
        let shadingShapesFMKRXMLElementToReturn = XMLElement.init(name: "fmkr:ShadingShapesArray");
        
        var xmlChildren : [XMLElement] = [];
 
        for shadingShape in shadingShapesArray!
        {
            let xmlElements = shadingShape.xmlElements(includeFMKRTags: true)
            xmlElements[0].removeAttribute(forName: "id")

            xmlChildren.append(contentsOf:xmlElements)
        //    print(shadingShape)
        }
        shadingShapesFMKRXMLElementToReturn.setChildren(xmlChildren)
        /*
        let attributesStringDictionary : [String: String] =
            [ "brushTip":"\(brushTip.rawValue)",
              "inkColor":inkColor.xmlRGBAttributeStringContent(),
              "representationMode":"\(representationMode.rawValue)",
              
            ];
        
        shadingShapesFMKRXMLElementToReturn.setAttributesWith(attributesStringDictionary)
        */
        
        return shadingShapesFMKRXMLElementToReturn;
    
    }
    
      // MARK: ---  NSPasteboardWriting
    
    /*
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
 
     This method returns an array of UTIs for the data types your object can write to the pasteboard.
 The order in the array is the order in which the types should be added to the pasteboard—this is important as only the first type is written initially, the others are provided lazily (see Promised Data).
 The method provides the pasteboard argument so that you can return different arrays for different pasteboards. You might, for example, put different data types on the dragging pasteboard than you do on the general pasteboard, or you might put on the same data types but in a different order. You might add to the dragging pasteboard a special representation that indicates the indexes of items being dragged so that they can be reordered.
 
     */
    
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
    
        let customUTIForDrawable = NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmdrawable")
        return [customUTIForDrawable,NSPasteboard.PasteboardType.string]
        
    }
    
    
    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
    
    
        if(type == self.pasteboardTypeUTIForDrawableClass)
        {
        
            let xmlElement = xmlElementsWrappedInSVG(includeFMKRTags: true)
            
            return xmlElement.xmlString
        }
        else if(type == NSPasteboard.PasteboardType.string)
        {
            return xmlElements(includeFMKRTags:false)[0].xmlString
            
        }
        
        return nil
    }
    
    
    

    
    // MARK: PASTEBOARD READING
    
    // NSPasteboardReading
    /*
      class func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
 This class method returns an array of UTIs for the data types your object can read from the pasteboard.
 The method provides the pasteboard argument so that you can return for different arrays for different pasteboards. As with reading, you might put different data types on the general pasteboard than you do on the dragging pasteboard, or you might put on the same data types but in a different order.
 */
    class func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
    {
        let customUTIForDrawable = NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmdrawable")
        
        let pasteboardTypesArray = [customUTIForDrawable]
        
        return pasteboardTypesArray
        
    }
    
    class func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions {
        
        if(type == NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmdrawable"))
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
        
        
        /*
        if(type.rawValue == "com.noctivagous.floating-marker.fmdrawable")
        {
        
            do{
                
                
                
                if let propertyListString = propertyList as? String
                {
                
                    print(propertyListString)
                
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
            }
            catch{
                print("error init from pasteboard");
            
            }
            
        }
        
       
     
        
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
        */
        
        
    }// END required init?(pasteboardPropertyList
    
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
  
    // MARK: -
    // MARK: SCALE, ROTATE, TRANSFORM POINT
    enum TransformPoint {
        case center
        case bottomLeft
        case topLeft
        case topRight
        case bottomRight
        case passedParameter
    }
    
       
    func scaleFrom(pointLocation:TransformPoint, point:NSPoint,  scale:CGFloat, doScaleLineWidth:Bool)
    {
        var pointForScale = NSPoint.zero
        
        switch pointLocation {
        case TransformPoint.bottomLeft:
            pointForScale = self.bottomLeftPt
        case TransformPoint.topLeft:
            pointForScale = self.topLeftPt
        case TransformPoint.topRight:
            pointForScale = self.topRightPt
        case TransformPoint.bottomRight:
            pointForScale = self.bottomRightPt
        case TransformPoint.center:
            pointForScale = self.centroid
            
        case TransformPoint.passedParameter:
            pointForScale = point
     //   default:
        //    pointForScale = self.bottomRightPt
        }
        
        
        var translateAndScaleAffineTransform = AffineTransform();
        translateAndScaleAffineTransform.translate(x:  pointForScale.x, y: pointForScale.y);
        translateAndScaleAffineTransform.scale(scale);
        translateAndScaleAffineTransform.translate(x: -1 * pointForScale.x, y: -1 * pointForScale.y);
        
        self.transform(using: translateAndScaleAffineTransform)
        
        if(doScaleLineWidth)
        {
            self.lineWidth = self.lineWidth * scale;
        }
        
        
        /*
       // Graphite Glider:
        if(self.hasLineShape && (self.lineShapeFoundationBezierPath != nil))
        {
            lineShapeFoundationBezierPath.transform(using: translateAndScaleAffineTransform);
            
        
        }*/
    }

    func rotateFrom(pointLocation:TransformPoint, point:NSPoint, angle:CGFloat)
    {
        var pointForRotate = NSPoint.zero
        
        switch pointLocation {
        case TransformPoint.bottomLeft:
            pointForRotate = self.bottomLeftPt
        case TransformPoint.topLeft:
            pointForRotate = self.topLeftPt
        case TransformPoint.topRight:
            pointForRotate = self.topRightPt
        case TransformPoint.bottomRight:
            pointForRotate = self.bottomRightPt
        case TransformPoint.center:
            pointForRotate = self.centroid
        case TransformPoint.passedParameter:
            pointForRotate = point
     //   default:
        //    pointForRotate = self.bottomRightPt
        }
        
        var translateAndRotateAffineTransform = AffineTransform();
        translateAndRotateAffineTransform.translate(x:  pointForRotate.x, y: pointForRotate.y);
        translateAndRotateAffineTransform.rotate(byDegrees: angle);
        translateAndRotateAffineTransform.translate(x: -1 * pointForRotate.x, y: -1 * pointForRotate.y);
        

        self.transform(using: translateAndRotateAffineTransform);
        
        
        /*
      // Graphite Glider:
        if(self.hasLineShape && (self.lineShapeFoundationBezierPath != nil))
        {
            self.lineShapeFoundationBezierPath.transform(using: translateAndRotateAffineTransform);
           
        }
       */
        
    }
    
    
    
   // MARK: POINTS OF BOUNDS
    var centroid : NSPoint
    {
        get{
         return NSMakePoint(self.bounds.midX, self.bounds.midY)
        }
        
    }
    
    var centroidOfRenderbounds : NSPoint
    {
        get
        {
         return NSMakePoint(self.renderBounds().midX, self.renderBounds().midY)
        }
        
    }
    
    var bottomLeftPt : NSPoint {
        get {
         return self.bounds.origin
        }
    }
    
    var topLeftPt : NSPoint  {
        get {
            
            return NSMakePoint(self.bounds.minX, self.bounds.maxY)
        }
    }
    
    
    var topRightPt : NSPoint  {
        get {
            return NSMakePoint(self.bounds.maxX, self.bounds.maxY)
        }
    }
    
    var bottomRightPt  : NSPoint  {
        get
        {
            return NSMakePoint(self.bounds.maxX, self.bounds.minY)
        }
    }

    var topMiddlePt  : NSPoint  {
        get {
        
            return NSPoint.midpoint(p1: self.topLeftPt, p2: self.topRightPt)
        }
    }
    
    var middleRightPt  : NSPoint  {
        get {
            
            return NSPoint.midpoint(p1: self.bottomRightPt, p2: self.topRightPt)
        }
    }
    
    
    var middleLeftPt  : NSPoint  {
        get {
            return NSPoint.midpoint(p1: self.bottomLeftPt, p2: self.topLeftPt)

            
        }
    }
    
    var bottomMiddlePt  : NSPoint  {
        get {
            return NSPoint.midpoint(p1: self.bottomLeftPt, p2: self.bottomRightPt)
            
        }
    }
  
  
  
      // MARK: --- SUBPATH OPERATIONS
    
    func extractAnySubpathsWithNoOverlapWithTheInitialPath() -> [FMDrawable]
    {
        // SUBTRACTED RESULT ARRAY
        var subtractedResultArray : [FMDrawable] = [];
        
        
        // --------
        // if there is more than one subpath
        if(self.countSubPathsNCT() > 1)
        {
            let baseShapeForSubtractedResult = FMDrawable();
            
            let subpaths = self.subPathsNCT();
            
            // --------
            // BASE SHAPE CARRIES SUBPATHS
            // THAT SIT INSIDE IT.
            baseShapeForSubtractedResult.append(subpaths[0])
            //subtractedResultArray.append(baseShapeForSubtractedResult);
            
            // REMOVE THE BASE SHAPE FROM THE SUBPATHS
            let dropFirstSlice = subpaths.dropFirst(1)
            
            let subpaths2 = Array(dropFirstSlice)
            
            for subpath in subpaths2
            {
                var isInsideBaseShape : Bool = true;
                let subpathPointsArray = subpath.buildupModePoints();
                
                for subpathPoint in subpathPointsArray
                {
                    if(baseShapeForSubtractedResult.contains(subpathPoint) == false)
                    {
                        isInsideBaseShape = false
                        break;
                    }
                }
                
                
                if(isInsideBaseShape == false)
                {
                    // THE subpath IS OUTSIDE OF THE BASE SHAPE,
                    // SO ADD IT AS A SEPARATE PATH IN THE ARRAY
                    let sResult = FMDrawable();
                    sResult.append(subpath)
                    subtractedResultArray.append(sResult)
                }
                else
                {
                    // The subpath is INSIDE THE BASE SHAPE,
                    // SO ADD IT AS A SUBPATH TO THE BASE SHAPE.
                    baseShapeForSubtractedResult.append(subpath)
                }
                
            
            }// END for subpath in subpaths2
            
            
            if(subtractedResultArray.isEmpty == false)
            {
                self.removeAllPoints();
                self.append(baseShapeForSubtractedResult)
                return subtractedResultArray;
            }
            else
            {
                return [];
            }
            
        }// END if(self.countSubPathsNCT() > 1)
        else
        {
            return [];
        }
    
//        return [];
  
    }// END extractAnySubpathsWithNoOverlapWithTheInitialPath();
    
    /*
    func isPathInsidePathShape(pathToTest:NSBezierPath,pathShape:NSBezierPath)
    {
    
    
    }*/
    
    
}// END FMDrawable


