//
//  FMImageDrawable.swift
//  Floating Marker
//
//  Created by John Pratt on 4/6/21.
//

import Cocoa

class FMImageDrawable: FMDrawable
{

    var imageFileType : String = "tiff"

  // NOTE: "Swift 4 does not allow its subclasses to inherit its superclass initializers"
    // So all subclasses must implement an override of this method.
    override  init(baseXMLElement: XMLElement, svgPath: String)
    {
        super.init()
        baseFMDrawableClassInitStep(baseXMLElement: baseXMLElement, svgPath: svgPath)
        secondaryStepForInit(baseXMLElement: baseXMLElement, svgPath: svgPath)
        
        
    }

    override func secondaryStepForInit(baseXMLElement: XMLElement, svgPath: String)
    {
        if(baseXMLElement.name != nil)
        {
            if(baseXMLElement.name! == "image")
            {
                if let xlinkAttributeString = baseXMLElement.attribute(forName: "xlink:href")?.stringValue
                {
                    //data:image/tiff;base64,
                    //print("-------")
                    let imageTypeRange = xlinkAttributeString.range(of: "data:image/")
                    
                    if let taggedBase64StringRange = xlinkAttributeString.range(of: "base64,")
                    {
                        
                        imageFileType = String(xlinkAttributeString[imageTypeRange!.upperBound..<taggedBase64StringRange.lowerBound].dropLast())
                        
                        
                        let imageBase64String = String(xlinkAttributeString[taggedBase64StringRange.upperBound..<xlinkAttributeString.endIndex])
                        
                        if let imageData = Data.init(base64Encoded: imageBase64String)
                        {
                            nsImage = NSImage(data: imageData)
                            

                                self.removeAllPoints()
                                
                                //ciImage = CIImage(data: nsImage!.tiffRepresentation!)
                                ciImage = CIImage.init(data: imageData)
                                
                                let x = baseXMLElement.cgFloatFromAttribute(attributeName: "x", defaultVal: 0)
                                let y = baseXMLElement.cgFloatFromAttribute(attributeName: "y", defaultVal: 0)
                                let width = baseXMLElement.cgFloatFromAttribute(attributeName: "width", defaultVal: 100)
                                let height = baseXMLElement.cgFloatFromAttribute(attributeName: "height", defaultVal: 100)
                                
                                self.removeAllPoints();
                                self.appendRect(NSMakeRect(x, y, width, height))
                                alterImageAccordingToNewQuadCorners()
                                
                                
                                /*
                                let zeroPtString = NSStringFromPoint(.zero)
                                let pt0 = NSPointFromString(baseXMLElement.stringFromAttribute(attributeName: "fmkr:pt0", defaultVal: zeroPtString))
                                let pt1 = NSPointFromString(baseXMLElement.stringFromAttribute(attributeName: "fmkr:pt1", defaultVal: zeroPtString))
                                let pt2 = NSPointFromString(baseXMLElement.stringFromAttribute(attributeName: "fmkr:pt2", defaultVal: zeroPtString))
                                let pt3 = NSPointFromString(baseXMLElement.stringFromAttribute(attributeName: "fmkr:pt3", defaultVal: zeroPtString))
                                self.removeAllPoints();
                                self.move(to: pt0)
                                self.line(to: pt1)
                                self.line(to: pt2)
                                self.line(to: pt3)
                                self.close()
                                //alterImageAccordingToNewQuadCorners()
                                */
                                
                            
                        }
                        else
                        {
                            print("image data was not successfully derived from base64Encoded string")
                        }
                        
                        //print("-------")

                      //  let a : Range<String.Index> = Range(uncheckedBounds: (lower:taggedBase64StringRange.lowerBound , upper: taggedBase64StringRange.upperBound))
                    
                       // attributeString.firstIndex(of: "base64,")
                        //stringRange.upperBound
                    
                    }
                
                }
            }
        }
    
    }
    
/*
    var img : NSImage?
    
    init(img: NSImage, frame: NSRect) {
        super.init()
        self.img = img
        self.removeAllPoints();
        self.appendRect(frame);
    }
    
    required init?(coder: NSCoder) {
       super.init(coder: coder)
    }
    
    override func display()
    {
    
        if(img != nil)
        {
            if(self.isEmpty == false)
            {
                img?.draw(in: self.bounds)
            }
        }
    }

    override func copy() -> Any
    {
        let imgDrawableCopy : FMImageDrawable = super.copy() as! FMImageDrawable

        imgDrawableCopy.img = self.img
        
        return imgDrawableCopy

    }
    
}


class ImageDrawable: FMDrawable
{*/

    var ciImage : CIImage?
    var nsImage : NSImage?
    var cartingNSImage : NSImage!
    var imageData : Data!
    
    override init()
    {
        super.init()
       // shapeName = "Image"
       // usesFill = true
        ciImage = CIImage()
        
       // cgImage = CGImage()
    }
    
    
    
    convenience init(url:URL, atPoint:NSPoint)
    {
        self.init()
        
        nsImage = NSImage(byReferencing: url)
        ciImage = CIImage(contentsOf: url)
        if (nsImage != nil)
        {
            // let width : Int = ciImage.properties["PixelWidth"] as! Int
            // let height : Int = ciImage.properties["PixelHeight"] as! Int
            // let imageRect = NSRect(x: atPoint.x, y: atPoint.y, width: CGFloat(width), height: CGFloat(height))
            
        
            self.appendRect(NSMakeRect(atPoint.x, atPoint.y, nsImage!.size.width, nsImage!.size.height))
            
            alterImageAccordingToNewQuadCorners()
            
           
            
        }
        else
        {
            print("error loading CIImage from data")
        }
    }
    
    convenience init(data:Data, atPoint:NSPoint)
    {
        self.init()

        nsImage = NSImage(data: data)
        ciImage = CIImage(data: data )
        if (nsImage != nil)
        {
            // let width : Int = ciImage.properties["PixelWidth"] as! Int
            // let height : Int = ciImage.properties["PixelHeight"] as! Int
            // let imageRect = NSRect(x: atPoint.x, y: atPoint.y, width: CGFloat(width), height: CGFloat(height))

            //print(nsImage.representations)
            
            self.appendRect(NSMakeRect(atPoint.x, atPoint.y, nsImage!.size.width, nsImage!.size.height))
            
            alterImageAccordingToNewQuadCorners()
            
        
        }
        else
        {
            print("error loading CIImage from data")
        }
 
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        nsImage = aDecoder.decodeObject(of: [NSImage.self], forKey: "nsImage") as? NSImage
        ciImage = aDecoder.decodeObject(of: [NSImage.self], forKey: "ciImage") as? CIImage
        
        self.alterImageAccordingToNewQuadCorners();
        
    }
    
    // MARK: PASTEBOARD WRITING AND READING PROTOCOL FUNCTIONS
    override var pasteboardTypeUTIForDrawableClass : NSPasteboard.PasteboardType
    {
        return NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmimagedrawable")
        
    }

    // MARK: ---  NSPasteboardWriting
    
    /*
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
 
     This method returns an array of UTIs for the data types your object can write to the pasteboard.
 The order in the array is the order in which the types should be added to the pasteboard—this is important as only the first type is written initially, the others are provided lazily (see Promised Data).
 The method provides the pasteboard argument so that you can return different arrays for different pasteboards. You might, for example, put different data types on the dragging pasteboard than you do on the general pasteboard, or you might put on the same data types but in a different order. You might add to the dragging pasteboard a special representation that indicates the indexes of items being dragged so that they can be reordered.
 
     */
    
    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
    
        let customUTIForDrawable = NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmimagedrawable")
        return [customUTIForDrawable,NSPasteboard.PasteboardType.string]
        
    }
    
    override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
    
    
        if(type == NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmimagedrawable"))
        {
            return xmlElements(includeFMKRTags:true)[0].xmlString
            /*
            do {
                
                
                
                return try xmlElements(includeFMKRTags:true)[0]
                //NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
                
            } catch  {
                print("error archiving for pasteboard");
            }*/
        }
       // else if(type == NSPasteboard.PasteboardType.html)
       // {
       // }
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
 
    let acceptedImagePasteboardTypes : [NSPasteboard.PasteboardType] = [NSPasteboard.PasteboardType.pdf, NSPasteboard.PasteboardType.tiff, NSPasteboard.PasteboardType.png,
        NSPasteboard.PasteboardType.init("public.jpeg"), NSPasteboard.PasteboardType.init("com.compuserve.gif")]
        
 
    override class func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
    {
        let customUTIForDrawable = NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmimagedrawable")
        
        let pasteboardTypesArray = [customUTIForDrawable, NSPasteboard.PasteboardType.pdf, NSPasteboard.PasteboardType.tiff, NSPasteboard.PasteboardType.png,
        NSPasteboard.PasteboardType.init("public.jpeg"), NSPasteboard.PasteboardType.init("com.compuserve.gif")]
        
        return pasteboardTypesArray
        
    }
    
    override class func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions {
        
        if(type == NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmimagedrawable"))
        {
            return NSPasteboard.ReadingOptions.asString
            
        }
        
        let pasteboardImageTypesArray = [NSPasteboard.PasteboardType.pdf, NSPasteboard.PasteboardType.tiff, NSPasteboard.PasteboardType.png,
        NSPasteboard.PasteboardType.init("public.jpeg"), NSPasteboard.PasteboardType.init("com.compuserve.gif")]
   
        if(pasteboardImageTypesArray.contains(type))
        {
            return NSPasteboard.ReadingOptions.asData
        }
        
   
        
        //else if(self.accepted)
        
     //   else if(type == NSPasteboard.PasteboardType.string)
     //   {
         
     //       return "quartzCode for Drawable"
            
      //  }
        
        return NSPasteboard.ReadingOptions.asString
        
    }
    
     required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType)
    {
        super.init()
        
        if(self.acceptedImagePasteboardTypes.contains(type))
        {
            if let propertyListAsData = propertyList as? Data
            {
                
                nsImage = NSImage.init(data: propertyListAsData)
                
                
                if(nsImage != nil)
                {
                    
                    ciImage = CIImage.init(data: propertyListAsData) //CIImage(data: nsImage!.tiffRepresentation!)
                    if(ciImage != nil)
                    {
                        self.removeAllPoints();
                        self.appendRect(NSMakeRect(0, 0, nsImage!.size.width, nsImage!.size.height))
                    }
                }
            }
            
        }
        
        
    }
    
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
          
        aCoder.encode(nsImage, forKey: "nsImage")
        aCoder.encode(ciImage, forKey: "ciImage")
 
    }
    
    override func copy() -> Any {
        
        let drawableImageCopy : FMImageDrawable = super.copy() as! FMImageDrawable
        
        drawableImageCopy.nsImage = self.nsImage;
        drawableImageCopy.ciImage = self.ciImage;
        
        return drawableImageCopy
        
    }
    
    
    
    
    /*required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        super.init(pasteboardPropertyList: propertyList, ofType: type)
        
    }*/
    
    
    /*
    override var bottomLeftPt : NSPoint {
        get {
            return self.pointAtIndex(0);
        }
    }
    override var bottomRightPt  : NSPoint  {
        get {
            return self.pointAtIndex(1);
        }
    }
    
    override var topRightPt : NSPoint  {
        get {
            return self.pointAtIndex(2);
        }
    }
    
    override  var topLeftPt : NSPoint  {
        get {
            
            return self.pointAtIndex(3);
        }
    }
    */
    
    
    override func transform(using transform: AffineTransform) {
        super.transform(using: transform);
        
        /*
        
        // scale
        // .m11 will transform the x (resulting width)
        // .m12 will transform the y (resulting height)
        if((transform.m11 != 0) && (transform.m22 != 0) && (transform.m21 == 0) && (transform.m12 == 0)
            
            && ((transform.m11 != 1.0)  && (transform.m22 != 1.0))
            
            )
        {
            
            print("transform.m11 \(transform.m11) transform.m22 \(transform.m22)");
            self.scaleImageLanczos(scale: transform.m11);
        }
            
        else
        */
        
        /*
        if((nsImage != nil) && (self.isEmpty == false))
        {
            let img = NSImage.init(size: nsImage!.size, flipped: true) { rect in
            
            let t = transform as NSAffineTransform
            t.concat()
            self.nsImage!.draw(in: self.bounds, from: .zero, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
            
            return true
            }
            
            nsImage = NSImage.init(data: img.tiffRepresentation!)
            
        }*/
        
        
        alterImageAccordingToNewQuadCorners();
        
        /*
        if(ciImage != nil)
        {
            let cgAffineXForm =
            CGAffineTransform.init(
            a: transform.m11,
            b: transform.m12,
            c: transform.m21,
            d: transform.m22,
            tx:transform.tX,// (transform.m21 != 0) ? transform.tX : 0,//((transform.m21 != 0) || (transform.m22 != 0)) ? transform.tX : 0,
            ty: transform.tY)
            //(transform.m22 != 1) ? transform.tY : 0)//((transform.m21 != 0) || (transform.m22 != 0)) ? transform.tY : 0)
            //print(transform.m21)
            //print(transform.m22)
            
            
            
            ciImage = ciImage?.transformed(by: cgAffineXForm)
            
            //
        }*/
        
    }
    
    func scaleImageLanczos(scale:CGFloat)
    {
        guard nsImage != nil else {
            return
        }
        // NSImage is stored
        // so that downscaling
        // will not diminish original resolution.
        // Could be replaced by second CIImage called originalCIImage.
        
        if let ciImage2 = CIImage(data: nsImage!.tiffRepresentation!)
        {
            
         
             
            let lanczosScaleTransform = CIFilter(name: "CILanczosScaleTransform")!
            lanczosScaleTransform.setValue(ciImage2, forKey: "inputImage")
            lanczosScaleTransform.setValue(scale, forKey: "inputScale")
            lanczosScaleTransform.setValue(1.0, forKey: "inputAspectRatio")
            
            ciImage = lanczosScaleTransform.value(forKey: "outputImage") as? CIImage
   
         
            
        }
    }
    
    func alterImageAccordingToNewQuadCorners()
    {
        guard nsImage != nil else {
            return
        }
        // this function is called in the initializers.
        // it is also called when there are 3D transformations
        // (transform3D...) called on the DrawingLayer
        
        // NSImage is stored
        // so that downscaling
        // will not diminish original resolution.
        // Could be replaced by second CIImage called originalCIImage.
        
        if let ciImageTemp = CIImage(data: nsImage!.tiffRepresentation!)
        {
            
            var btmLeftPt = self.bottomLeftPt
            btmLeftPt.y = self.bottomRightPt.y
            btmLeftPt.x = self.topLeftPt.x
            
            var btmRightPt = self.bottomRightPt
            btmRightPt.y = self.bottomLeftPt.y
            btmRightPt.x = self.topRightPt.x
            
            var tpRightPt = self.topRightPt
            tpRightPt.y = self.topLeftPt.y
            tpRightPt.x = self.bottomRightPt.x
            
            var tpLeftPt = self.topLeftPt
            tpLeftPt.y = self.topRightPt.y
            tpLeftPt.x = self.bottomLeftPt.x
            
            let perspectiveTransform = CIFilter(name: "CIPerspectiveTransform")!
            
            perspectiveTransform.setValue(CIVector(cgPoint:tpLeftPt),
                                          forKey: "inputTopLeft")
            perspectiveTransform.setValue(CIVector(cgPoint:tpRightPt),
                                          forKey: "inputTopRight")
            perspectiveTransform.setValue(CIVector(cgPoint:btmRightPt),
                                          forKey: "inputBottomRight")
            perspectiveTransform.setValue(CIVector(cgPoint:btmLeftPt),
                                          forKey: "inputBottomLeft")
            perspectiveTransform.setValue(ciImageTemp,
                                          forKey: kCIInputImageKey)
            
            ciImage = perspectiveTransform.outputImage;
            
            if(self.isBeingCarted)
            {
                self.adjustBasedOnCartingChange();
            }
            
        }
        
        
    }
    
    func adjustBasedOnCartingChange()
    {
        guard nsImage != nil else {
            return
        }
        
        if(self.isBeingCarted)
        {
            // drawing an image is done faster
            // with NSImage, so cartingNSImage is created
            // whenever carting is turned on.
            
            //let cIImageRepresentation : NSCIImageRep = NSCIImageRep(ciImage: ciImage);
            if ciImage == nil
            {
                ciImage = CIImage(data: nsImage!.tiffRepresentation!)
            }
            
            let cIImageRepresentation : NSBitmapImageRep = NSBitmapImageRep(ciImage: ciImage!);
            cartingNSImage = NSImage(size: cIImageRepresentation.size);
            cartingNSImage.addRepresentation(cIImageRepresentation);
        
            
          
        }
        else
        {
            cartingNSImage = nil;
        }
        
        
        //    nsImage.size = nsImage.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5))
        //   nsImage.resizingMode = NSImage.ResizingMode.stretch
        
    }
    
    override func display() {
        
        selectionShadowBeginSaveGState()
        
        // find angle of moveTo point to lineTo point
        
        
        // if image is always drawn
        // as a result of clipping mask,
        // when subtractions are made
        // to the bezier shape,
        // the mask for the image can reflect this
        
       // nsImage?.draw(at: NSPoint.zero, from: .zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
        
        let bounds = self.bounds
 
       
        
        // drawing an image is done faster
        // with NSImage, so cartingNSImage is created
        // whenever carting is turned on.
        if(self.isBeingCarted)
        {
        
            if((cartingNSImage) != nil)
            {
//                cartingNSImage.draw(in: bounds, from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0);
            
                cartingNSImage.draw(in: bounds, from: NSRect.zero, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
              //  ciImage.draw(in: bounds, from: bounds, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
                
            }
        }
        
        else
        {
            if((ciImage) != nil)
            {
                ciImage?.draw(in: bounds, from: bounds, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
            
              //ciImage.draw(in: bounds, from: NSRect(x: 0, y: 0, width: b.width, height: b.height), operation: NSCompositingOperation.sourceOver, fraction: 1.0)
            }
        }

      
        if(self.isSelected)
        {
            NSColor.white.setStroke()
            self.stroke()
        }
    
        //displayAllBezierPathPoints()
            /*
        
        
    
        
 
        //nsImage.drawRepresentation(<#T##imageRep: NSImageRep##NSImageRep#>, in: <#T##NSRect#>)
        
        
        // drawing an image is done faster
        // with NSImage, so cartingNSImage is created
        // whenever carting is turned on.
        if(self.isBeingCarted)
        {
            if((cartingNSImage) != nil)
            {
                //cartingNSImage.draw(in: bounds, from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0, respectFlipped: true, hints: [NSImageRep.HintKey.interpolation : NSImageInterpolation.low])
                cartingNSImage.draw(in: bounds, from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0, respectFlipped: true, hints: [.interpolation : NSImageInterpolation.low.rawValue]);
            //[NSImageRep.HintKey.interpolation : NSImageInterpolation.low]
            
              //  ciImage.draw(in: bounds, from: bounds, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
              
   
            }
        }
        
        else
        {
            if((ciImage) != nil)
            {
              ciImage?.draw(in: bounds, from: NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height), operation: NSCompositingOperation.sourceOver, fraction: 1.0)
        
              //ciImage.draw(in: bounds, from: NSRect(x: 0, y: 0, width: b.width, height: b.height), operation: NSCompositingOperation.sourceOver, fraction: 1.0)
            }
            
//            if(self.isBeingCarted == false)
//            {
//                nsImage?.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
//            }
        }
            */
        
       // displayAllBezierPathPoints();

        selectionShadowRestoreGState()
     
    }
    
    override func hitTestForClickBasedOnStrokeOrFillState(point: NSPoint) -> (didHit:Bool, wasStroke:Bool, wasShadingShape: Bool)
    {
    
        
        
        let didHitTuple = super.hitTestForClickBasedOnStrokeOrFillState(point: point)
        
        if( hitTestOnStrokeLines(point: point))
        {
            return (true, true, false)
        }
        else if(self.shadingShapesArray?.isEmpty == false)
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
        
        if(hitTestInsideFilledShape(point:point))
        {
            return (true, false, false)
        }
            
    
        return didHitTuple
    
    }
    
    override func xmlElements(includeFMKRTags: Bool) -> [XMLElement]
    {
        var xmlElementsArray = super.xmlElements(includeFMKRTags: includeFMKRTags)
        
        
        
        if let imageXMLElement = imageXMLElement(includeFMKRTags: includeFMKRTags)
        {
            
            xmlElementsArray[0] = imageXMLElement
            
        
        }
        
        return xmlElementsArray;
    }
    
    func imageXMLElement(includeFMKRTags:Bool) -> XMLElement?
    {
        
        guard ciImage != nil else {
            fatalError("ciImage == nil in imageXMLElement()")
        }
        
        // https://stackoverflow.com/questions/17386650/converting-ciimage-into-nsimage
        
        //let ciImageRep = NSCIImageRep(ciImage: ciImage!)
       // let nsImageForXMLElement = NSImage(size: ciImageRep.size)
       // nsImageForXMLElement.addRepresentation(ciImageRep)
        
        var bitmapRepresentation : NSBitmapImageRep?
        
        

        bitmapRepresentation = NSBitmapImageRep.init(ciImage: ciImage!)
        //NSBitmapImageRep(data: nsImageForXMLElement.tiffRepresentation!)!

        // IMAGE HAS TRANSPARENCY, SO MAKE PNG
        //if(ciImageRep.hasAlpha == false)
        //{
            // if let tiffData = nsImageForXMLElement.tiffRepresentation
            if let pngData = bitmapRepresentation!.representation(using: NSBitmapImageRep.FileType.png, properties: [NSBitmapImageRep.PropertyKey.interlaced : NSNumber(booleanLiteral: false)])
            {
            
                let imageXMLElement = XMLElement.init(name: "image")
                
             
                
                imageXMLElement.setAttributesAs(
                    [
                        "x" : "\(self.bounds.origin.x)",
                        "y" : "\(self.bounds.origin.y)",
                        "height" : "\(Int(bitmapRepresentation!.size.height))",
                        "width" : "\(Int(bitmapRepresentation!.size.width))",
                        "xlink:href" : "data:image/png;base64,\(pngData.base64EncodedString())",
                    ])
                
                if(includeFMKRTags)
                {
                    imageXMLElement.addAttribute(XMLNode.attribute(withName: "fmkr:pt0", stringValue: NSStringFromPoint(self.bottomLeftPt)) as! XMLNode)
                    
                    imageXMLElement.addAttribute(XMLNode.attribute(withName: "fmkr:pt1", stringValue: NSStringFromPoint(self.bottomRightPt)) as! XMLNode)
                    
                    imageXMLElement.addAttribute(XMLNode.attribute(withName: "fmkr:pt2", stringValue: NSStringFromPoint(self.topRightPt)) as! XMLNode)
                    
                    imageXMLElement.addAttribute(XMLNode.attribute(withName: "fmkr:pt3", stringValue: NSStringFromPoint(self.topLeftPt)) as! XMLNode)
        
                    
                }
                
                return imageXMLElement
            }
        //}
        /*// IMAGE HAS NO TRANSPARENCY, SO MAKE JPG
        else
        {
            if let jpgData = bitmapRepresentation!.representation(
            using: NSBitmapImageRep.FileType.jpeg,
            properties:
            [
            NSBitmapImageRep.PropertyKey.progressive : NSNumber(booleanLiteral: false),
            NSBitmapImageRep.PropertyKey.compressionFactor : NSNumber(1.0)
            ]
                
            )
            {
                let imageXMLElement = XMLElement.init(name: "image")
                
                imageXMLElement.setAttributesAs(
                    [
                        "x" : "\(self.bounds.origin.x)",
                        "y" : "\(self.bounds.origin.y)",
                        "height" : "\(nsImageForXMLElement.size.height)",
                        "width" : "\(nsImageForXMLElement.size.width)",
                        "xlink:href" : "data:image/jpg;base64,\(jpgData.base64EncodedString())",
                        "fmkr:pt0" : NSStringFromPoint(self.bottomLeftPt),
                        "fmkr:pt1" : NSStringFromPoint(self.bottomRightPt),
                        "fmkr:pt2" : NSStringFromPoint(self.topRightPt),
                        "fmkr:pt3" : NSStringFromPoint(self.topLeftPt),
                    ])
                
                return imageXMLElement
                
                
            }
        
        
        }
        */
        return nil;
    }

    
    override var bottomLeftPt : NSPoint {
        get {
            
            if(self.isEmpty)
            {
                return NSPoint.zero
            }
            
        
            return self.pointAtIndex(0);
        }
    }
    override var bottomRightPt  : NSPoint  {
        get {
            
            if(self.isEmpty)
            {
                return NSPoint.zero
            }
            
            return self.pointAtIndex(1);
        }
    }
    

    
    override var topRightPt : NSPoint  {
        get {
            return self.pointAtIndex(2);
        }
    }
    
    override  var topLeftPt : NSPoint  {
        get {
            
            return self.pointAtIndex(3);
        }
    }
    
    
}
