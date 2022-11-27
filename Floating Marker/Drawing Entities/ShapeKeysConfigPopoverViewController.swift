//
//  ShapeKeysConfigPopoverViewController.swift
//  Floating Marker
//
//  Created by John Pratt on 3/8/21.
//

import Cocoa

class ShapeKeysConfigPopoverViewController: NSViewController {
    
    @IBOutlet var inkAndLineSettingsManager : InkAndLineSettingsManager!
    
    @IBOutlet var shapeKeysConfigPopover : NSPopover?
    
    @IBOutlet var rectangleDrawingEntity : RectangleDrawingEntity!
    @IBOutlet var shapeInQuadDrawingEntity : ShapeInQuadDrawingEntity!
    @IBOutlet var ellipseDrawingEntity : EllipseDrawingEntity!
    
    // when the popover changes to a new shape keys entity,
    // the controls in the popover are loaded with that entity's settings.
    var currentPopoverShapeKeyDrawingEntity: DrawingEntity?
    
    var shapeForRectangleDrawingEntity : FMDrawable = FMDrawable()
    var selectedSettingForRectangleDrawingEntity : String = "rectangle"
    {
        didSet
        {
            rectangleShapeKeySlotPopUpButton?.selectItem(withTitle: self.selectedSettingForRectangleDrawingEntity)
            
            if(shapeKeysSettingsPopOverViews.keys.contains(selectedSettingForRectangleDrawingEntity))
            {
                rectangleConfigureButton?.isEnabled = true
            }
            else
            {
                rectangleConfigureButton?.isEnabled = false
            }
            
        }
    }
    
    var baseRectForShape = NSMakeRect(0, 0, 500, 500)
    
    var shapeForShapeInQuadDrawingEntity : FMDrawable
    {
        get
        {
            var baseShapeToReturn = FMDrawable();
            
            /*
             "rectangle" : [:],
             "rounded rectangle" : [:],
             "ellipse" : [:],
             "grid" : [:],
             "regular polygon" : [:],
             "right triangle" : [:],
             "loaded object" : [:]
             */
            
            switch selectedSettingForShapeInQuadDrawingEntity
            {
            case "rectangle" :
                baseShapeToReturn.appendRect(baseRectForShape)
            case "rounded rectangle" :
            
                // -------------
                // replace with FMStroke with added .cornerRounding FMStrokeType points
                // with processed (.uniformPath) bezier path.
                // -------------
            
                baseShapeToReturn.append(withRoundedRectangle: baseRectForShape, withRadius: inkAndLineSettingsManager.cornerRounding)
            case "grid" :
                baseShapeToReturn.appendRect(baseRectForShape)
            case "regular polygon" :
                baseShapeToReturn.appendRect(baseRectForShape)
                makeRegularPolygon(circleOrigin: baseRectForShape.centroid(), numOfSides: polygonSides, radius: baseRectForShape.width / 2, angleInDegrees: 0, drawable: &baseShapeToReturn);
//                baseShapeToReturn.move(to: baseRectForShape.origin)
//                baseShapeToReturn.line(to: baseRectForShape.bottomRight())
//                baseShapeToReturn.line(to: baseRectForShape.topMiddle())
//                baseShapeToReturn.close();
            case "right triangle" :
                baseShapeToReturn.move(to: baseRectForShape.origin)
                baseShapeToReturn.line(to: baseRectForShape.bottomRight())
                baseShapeToReturn.line(to: baseRectForShape.topLeft())
                baseShapeToReturn.close();
            case "ellipse" :
                baseShapeToReturn.appendOval(in: baseRectForShape)
            case "loaded object" :
                baseShapeToReturn = inkAndLineSettingsManager.loadedObject.copy() as! FMDrawable
            default:
                baseShapeToReturn.appendOval(in: baseRectForShape)
            }
            
            
            
            return baseShapeToReturn;
            
        }
    }
    
    var selectedSettingForShapeInQuadDrawingEntity : String = "ellipse"
    {
        didSet
        {
            shapeInQuadShapeKeySlotPopUpButton?.selectItem(withTitle: self.selectedSettingForShapeInQuadDrawingEntity)

            if(shapeKeysSettingsPopOverViews.keys.contains(selectedSettingForShapeInQuadDrawingEntity))
            {
                shapeInQuadConfigureButton?.isEnabled = true
            }
            else
            {
                shapeInQuadConfigureButton?.isEnabled = false
            }
        }
    }
    
  
    
    
    var shapeForEllipseDrawingEntity : FMDrawable = FMDrawable()
    var selectedSettingForEllipseDrawingEntity : String = "ellipse"
    {
        didSet
        {
            ellipseShapeKeySlotPopUpButton?.selectItem(withTitle: self.selectedSettingForEllipseDrawingEntity)
            
            if(shapeKeysSettingsPopOverViews.keys.contains(selectedSettingForEllipseDrawingEntity))
            {
                ellipseConfigureButton?.isEnabled = true
            }
            else
            {
                ellipseConfigureButton?.isEnabled = false
            }
        }
    }
    var loadedObject : FMDrawable = FMDrawable()
    
   
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        
     // shape: rectangle, ellipse, grid, rounded rectangle, regular polygon, right triangle, loaded object
    
     // fill mode: pattern image, linear gradient, radial gradient, noise

    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
     
     
     // MARK: SETTINGS DICTIONARY FOR SHAPE KEYS
    
    var shapeKeysSettingsDictionary : [String : Dictionary<String,Any>] = [:];
    
    var shapeKeysSettingsPopOverViews : [String : NSView?] = [:];
    @IBOutlet var rectangleConfigView : NSView?
    @IBOutlet var ellipseConfigView : NSView?
    @IBOutlet var gridConfigView : NSView?
    @IBOutlet var regularPolygonConfigView : NSView?
    @IBOutlet var rightTriangleConfigView : NSView?
    @IBOutlet var loadedObjectConfigView : NSView?
    
    override func awakeFromNib()
    {
    
        shapeKeysSettingsDictionary =
            [
                "rectangle" : [:],
                "rounded rectangle" : [:],
                "ellipse" : [:],
                "grid" : [:],
                "regular polygon" : [:],
                "right triangle" : [:],
                "loaded object" : [:]
            ]
        
        shapeKeysSettingsPopOverViews =
            [
                "rectangle" : rectangleConfigView,
                "ellipse" : ellipseConfigView,
                "grid" : gridConfigView,
                "regular polygon" : regularPolygonConfigView,
                "right triangle" : rightTriangleConfigView,
                "loaded object" : loadedObjectConfigView
                
            ]
        
        let popUpButtons : [NSPopUpButton?] = [rectangleShapeKeySlotPopUpButton,ellipseShapeKeySlotPopUpButton,shapeInQuadShapeKeySlotPopUpButton];
        
        for pUB in popUpButtons
        {
           pUB?.removeAllItems()
           
           var s = Array(shapeKeysSettingsDictionary.keys)
           s.sort()
           for k in s
           {
                pUB?.addItem(withTitle: k)
           }
            
        }
        
        
        loadSettings()

     
    }
    
    func loadSettings()
    {
        selectedSettingForRectangleDrawingEntity = "rectangle"
        selectedSettingForShapeInQuadDrawingEntity = "ellipse"
        selectedSettingForEllipseDrawingEntity = "ellipse"
       
        shapeKeysSettingsDictionary["grid"] =
        [
            "gridRows" : 20.0,
            "gridColumns" : 20.0,
        ]
        
        polygonSides = 5
        shapeKeysSettingsDictionary["regular polygon"] =
            [
                "sides" : polygonSides
            ]
        
         
         shapeKeysSettingsDictionary["right triangle"] =
         [
            "orientation" : 0
         ]
        
        /*
         [
         "cornerRadiusForRectangle" : 10.0,
         "gridRows" : 20.0,
         "gridColumns" : 20.0,
         "regularPolygonSides" : 5,
         ]
         */
        
    }
    

    
    // MARK: POPUPBUTTONS FOR SHAPE KEYS
    
    func populateShapeKeysPopUpButtons()
    {
        
    }
    
    @IBOutlet var rectangleShapeKeySlotPopUpButton : NSPopUpButton?
    @IBOutlet var ellipseShapeKeySlotPopUpButton : NSPopUpButton?
    @IBOutlet var shapeInQuadShapeKeySlotPopUpButton : NSPopUpButton?

    @IBAction func changeShapeKeySlot(_ sender : NSPopUpButton)
    {
        switch sender {
        case rectangleShapeKeySlotPopUpButton:
            selectedSettingForRectangleDrawingEntity = sender.titleOfSelectedItem ?? "rectangle"
        case ellipseShapeKeySlotPopUpButton:
            selectedSettingForEllipseDrawingEntity = sender.titleOfSelectedItem ?? "ellipse"
        case shapeInQuadShapeKeySlotPopUpButton:
            selectedSettingForShapeInQuadDrawingEntity = sender.titleOfSelectedItem ?? "grid"
        default:
            break;
        }
        
    }

    @IBOutlet var rectangleConfigureButton : NCTButton?
    @IBOutlet var ellipseConfigureButton : NCTButton?
    @IBOutlet var shapeInQuadConfigureButton : NCTButton?

    @IBAction func launchShapeKeysConfigPopover(_ sender : NCTButton?)
    {
        if let configureButton = sender
        {
            shapeKeysConfigPopover!.performClose(configureButton)
            switch configureButton
            {
            case rectangleConfigureButton:
                if(shapeKeysSettingsPopOverViews.keys.contains(selectedSettingForRectangleDrawingEntity))
                {
                    self.view = shapeKeysSettingsPopOverViews[selectedSettingForRectangleDrawingEntity]!!
                }
            case ellipseConfigureButton:
                if(shapeKeysSettingsPopOverViews.keys.contains(selectedSettingForEllipseDrawingEntity))
                {
                    self.view = shapeKeysSettingsPopOverViews[selectedSettingForEllipseDrawingEntity]!!
                }
                
            case shapeInQuadConfigureButton:
                if(shapeKeysSettingsPopOverViews.keys.contains(selectedSettingForShapeInQuadDrawingEntity))
                {
                    self.view = shapeKeysSettingsPopOverViews[selectedSettingForShapeInQuadDrawingEntity]!!
                }
            default:
                return;
            }

            // workaround for some kind of contentSize problem in NSPopover
            shapeKeysConfigPopover!.contentSize = NSMakeSize(400, 120)
            if(self.view.frame.size.height < shapeKeysConfigPopover!.contentSize.height)
            {
                    shapeKeysConfigPopover!.contentSize.height = self.view.frame.size.height
            }

            shapeKeysConfigPopover?.show(relativeTo: sender!.bounds, of: sender!, preferredEdge: NSRectEdge.minX)


        }
        
    
    }
    
    
    // MARK: REGULAR POLYGON CONTROLS

    @IBOutlet var polygonSidesTextField : NCTTextField?
    @IBOutlet var polygonSidesSlider : NCTSlider?
    var polygonSides : Int = 3
    {
        didSet
        {
            polygonSides = polygonSides.clamped(to: 3...500)
            polygonSidesTextField?.integerValue = polygonSides
            polygonSidesSlider?.integerValue = polygonSides
            shapeKeysSettingsDictionary["regular polygon"]?["sides"] = polygonSides
        }
    }
    
    @IBAction func changePolygonSides(_ sender : NSControl)
    {
        polygonSides = sender.integerValue;
    }
    
    func makeRegularPolygon(circleOrigin: NSPoint, numOfSides: Int, radius: CGFloat, angleInDegrees: CGFloat, drawable : inout FMDrawable)
    {
        
        drawable.removeAllPoints();
        
        var sides = numOfSides
        if (sides < 3) //
        {
            sides = 3;
        }
        
        var theta : CGFloat = .pi * 2;  //This makes a full circle in radians.
        let sliceAngle : CGFloat = CGFloat(theta / CGFloat(sides));
        var index : Int = sides;
        
        drawable.move(to: NSPoint(x: 1.0, y: 0))  // start at a point on the unit circle..
        
        
        
        while (index != 0)  // count down
        {
            index -= 1
            theta -= sliceAngle;
            drawable.line(to: NSPoint(x: cos(theta), y: sin(theta)))
        }
        
        drawable.close()  // This gets you a proper linejoin for the last segment.
        
        var affineTransform : AffineTransform = AffineTransform();
        affineTransform.rotate(byDegrees: angleInDegrees);
        affineTransform.scale(radius);
        drawable.transform(using: affineTransform);
        
        var translateAffineTransform : AffineTransform = AffineTransform();
        translateAffineTransform.translate(x: circleOrigin.x, y: circleOrigin.y);
        drawable.transform(using: translateAffineTransform);
        
    }
  
  
  
  
    // MARK: -
    override func viewDidLoad()
    {
        super.viewDidLoad()
    
      
        
    }
    
}
