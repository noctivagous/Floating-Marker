//
//  FMShapeKeyDrawable.swift
//  Floating Marker
//
//  Created by John Pratt on 3/10/21.
//

import Cocoa

class FMShapeKeyDrawable : FMDrawable
{


  // NOTE: "Swift 4 does not allow its subclasses to inherit its superclass initializers"
    // So all subclasses must implement an override of this method.
        override init() {
        super.init()
    }
  
    override var pasteboardTypeUTIForDrawableClass : NSPasteboard.PasteboardType
    { return NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmshapekeydrawable") }

    override init(baseXMLElement: XMLElement, svgPath: String)
    {
        super.init(baseXMLElement: baseXMLElement, svgPath: svgPath)
       
    }
    
    // required in Swift but not Obj-C
    // this is not called, because readingOptions is put in.
    // This function is not doing what it is asked to do because
    // of NSKeyedUnarchiver not unarchiving the data into a decodable format
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
      
        super.init(pasteboardPropertyList: propertyList, ofType: type)
        
       
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    var pointsArrayForModeBounds : [NSPoint] = [];

    func displayShapeGuidelines()
    {
        if(pointsArrayForModeBounds.count >= 4)
        {
            let p = NSBezierPath();
            p.appendPoints(&pointsArrayForModeBounds, count: pointsArrayForModeBounds.count)
            
            var a1 = [pointsArrayForModeBounds[0],pointsArrayForModeBounds[2]];
            p.appendPoints(&a1,
            count: 2)
            
            var a2 = [pointsArrayForModeBounds[0],pointsArrayForModeBounds[2]];

            p.appendPoints(&a2,
            count: 2)
            
            p.lineWidth = 1.0;
            NSColor.black.setStroke();
            p.stroke();
        }
    }
    
    /*
    override func xmlElements() -> [XMLElement] {
        var xmlXtoRet = super.xmlElements();
        
        pathSVGElement.removeAttribute(forName: "stroke-width")
        
        pathSVGElement.addAttribute(XMLNode.attribute(withName: "stroke-width", stringValue: fmInk.mainColor.xmlRGBAttributeStringContent()) as! XMLNode)

        
    }*/


            
}
