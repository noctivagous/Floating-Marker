//
//  GroupDrawable.swift
//  Graphite Glider
//
//  Created by John Pratt on 2/11/19.
//  Copyright © 2019 Noctivagous, Inc. All rights reserved.
//

import Cocoa

class GroupDrawable: FMDrawable {

    var arrayOfDrawables : [FMDrawable] = []
    
    override init()
    {
        super.init()
        shapeName = "Group"
        
    }
    
    convenience init(array:[FMDrawable])
    {
        self.init()
        
        arrayOfDrawables = array;
        
    
        makeBezierPathBoundsRect();
        
    }
    
    func makeBezierPathBoundsRect()
    {
        var boundsRect : NSRect = NSRect.zero
        
        self.removeAllPoints();
        
        for drawable in arrayOfDrawables
        {
            
            if(boundsRect == NSRect.zero)
            {
                boundsRect = drawable.bounds
            }
            else
            {
                boundsRect = boundsRect.union(drawable.bounds)
            }
            
        }
        
        self.appendRect(boundsRect)
    }
    
    
    
    override func hitTestForClickBasedOnStrokeOrFillState(point: NSPoint) -> (didHit: Bool, wasStroke: Bool,wasShadingShape:Bool)
    {
    
    
        for drawable in arrayOfDrawables
        {
            let tupleForHitTest = drawable.hitTestForClickBasedOnStrokeOrFillState(point: point)
            if(tupleForHitTest.didHit == true)
            {
                return tupleForHitTest;
            }
        }
    
        return (false, true,false)
    }
    
    
    override func hitTestInsideFilledShape(point: NSPoint) -> Bool
    {
        for drawable in arrayOfDrawables
        {
            
            if(drawable.hitTestInsideFilledShape(point: point))
            {
                return true
            }
        }
        
        return false;
    }
    
    override func contains(_ point: NSPoint) -> Bool {

        for drawable in arrayOfDrawables
        {
            
            if(drawable.contains(point))
            {
                return true
            }
        }
        
        return false;

    }
    
    override func isStrokeHit(by point: NSPoint) -> Bool
    {
        for drawable in arrayOfDrawables
        {
            
            if(drawable.isStrokeHit(by: point))
            {
                return true
            }
        }
        
        return false;

    }
    
    override func isStrokeHit(by point: NSPoint, padding: CGFloat) -> Bool
    {
        for drawable in arrayOfDrawables
        {
            
            if(drawable.isStrokeHit(by: point, padding: padding))
            {
                return true
            }
        }
        
        return false;
    }
    
    
    override func hitTestOnStrokeLines(point: NSPoint) -> Bool
    {
        for drawable in arrayOfDrawables
        {
        
            if(drawable.hitTestOnStrokeLines(point: point))
            {
                return true
            }

        }
        
        return false;
 
    }
    
    
    
    override func transform(using transform: AffineTransform) {
        
        super.transform(using: transform)
        
        for drawable in arrayOfDrawables
        {
            drawable.transform(using: transform)
        }
        
        makeBezierPathBoundsRect()
        
    }
    
  
    override func segmentHit(by point: NSPoint, position: UnsafeMutablePointer<CGFloat>!, padding: CGFloat) -> Int {
        
        
        for d in arrayOfDrawables
        {
            let i : Int = d.segmentHit(by: point, position: position, padding: padding)
            
            if(i > 0)
            {
            return i;
            }
        }
        
        return 0;
    }
    
    /*
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    
        arrayOfDrawables = aDecoder.decodeObject(forKey: "arrayOfDrawables") as? [FMDrawable] ?? []
        
        
    }
    
    override func encode(with aCoder: NSCoder) {
        
      aCoder.encode(arrayOfDrawables, forKey: "arrayOfDrawables")
        
    }*/
    
    override func copy() -> Any {
        
        var arrayForGD : [FMDrawable] = []
        
        for a in self.arrayOfDrawables
        {
            arrayForGD.append(a.copy() as! FMDrawable)
        }
        
        let groupDrawableCopy = GroupDrawable(array: arrayForGD)
        
        return groupDrawableCopy
        
    }
    
    /*
    override func applyDrawableCharacteristics(_ drawableCharacteristics: DrawableCharacteristics)
    {
        for d in self.arrayOfDrawables
        {
            d.applyDrawableCharacteristics(drawableCharacteristics)
        }

    }*/
    

    
    override func display() {
        
        for drawable in arrayOfDrawables
        {
            drawable.display()
            
        }
        
        if(isSelected)
        {
            self.selectionShadowBeginSaveGState()
            NSColor.blue.setStroke()
            self.stroke();
            self.selectionShadowRestoreGState()
        }
        
    }
    
    
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        super.init(pasteboardPropertyList: propertyList, ofType: type)
        
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    
        arrayOfDrawables = aDecoder.decodeObject(forKey: "arrayOfDrawables") as? [FMDrawable] ?? []
    }
    
    
    
    override class var supportsSecureCoding : Bool
        {
        get
        {
            return true
        }
    }
    
    
    override init(baseXMLElement: XMLElement, svgPath: String)
    {
        super.init()
        
        if let appDelegate = NSApp.delegate as? AppDelegate
        {
            guard baseXMLElement.children != nil else {
                return;
            }
            
            for child in baseXMLElement.children!
            {
                if let fmDrawable = appDelegate.fmDrawableFromBaseXMLElement(baseXMLElement: child as! XMLElement)
                {
                    self.arrayOfDrawables.append(fmDrawable)
                }
            }
            
            makeBezierPathBoundsRect();
            
        }
        
        
    
    }
    
    
    override func xmlElements(includeFMKRTags:Bool) -> [XMLElement]
    {
        var xmlElementsToReturn : [XMLElement] = [];
        
        let groupSVGElement = XMLElement.init(name: "g")
        
        if(includeFMKRTags)
        {
            groupSVGElement.addAttribute(XMLNode.attribute(withName: "fmkr:DrawableType", stringValue: "GroupDrawable") as! XMLNode)
            
        }
        
        for drawable in self.arrayOfDrawables
        {
            xmlElementsToReturn.append(contentsOf: drawable.xmlElements(includeFMKRTags: includeFMKRTags))
        }
        
        return xmlElementsToReturn;
        
    }
    
}
