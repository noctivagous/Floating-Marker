//
//  NCTDrawingPageController.swift
//  Floating Marker
//
//  Created by John Pratt on 2/14/21.
//

import Cocoa

class NCTDrawingPageController: NSObject, NSPopoverDelegate, NSTableViewDataSource, NSTableViewDelegate
{

    @IBOutlet var fmDocument : FMDocument!

    var inputInteractionManager : InputInteractionManager?
    var lineWorkInteractionEntity: LineWorkInteractionEntity?
    var inkAndLineSettingsManager: InkAndLineSettingsManager?
    

    var drawingBoardMargin : CGFloat = 15.0
    let defaultDocumentWidth : CGFloat = 1920.0
    let defaultDocumentHeight : CGFloat = 1080.0

    // MARK: -
// MARK: DRAWING BOARD
	@IBOutlet var drawingBoard : DrawingBoard! // inherits from NSView.
							            // is the embedded documentView for NSScrollView
  						                // It holds the drawingPage (layers), surrounds it with
						                // horizontal and vertical margins.
                      
    var drawingPage : DrawingPage!
 
    //MARK: LAYERS PANEL
    @IBOutlet var fmLayersPanel : FMLayersPanel!;
    let baseFMLayersPanelSize : NSSize = NSMakeSize(301, 301);
    
    func changeVisibilityForLayersPanel(_ visible:Bool)
    {
        
      
        // prevents interruption of window animation
        guard( (fmLayersPanel.frame.size.height == baseFMLayersPanelSize.height) || (fmLayersPanel.frame.size.height == 10)) else {
            print("\(fmLayersPanel.frame.size.height) is not \(baseFMLayersPanelSize.height)")
            
            return
        }
    
    
        if(visible == false)
        {

            var pFrame = fmLayersPanel.frame

            pFrame.size.height = 10;
            fmLayersPanel.setFrame(pFrame, display: true, animate: true)
            
            fmLayersPanel.setIsVisible(visible)
            
            layersPanelBox.fillColor = .clear
        }
        else
        {
            
            fmLayersPanel.parent?.removeChildWindow(fmLayersPanel);
            self.fmDocument.docFMWindow.addChildWindow(fmLayersPanel, ordered: NSWindow.OrderingMode.above)
            fmLayersPanel.positionToWindowAccordingToConfiguration();
            
            var pFrame = fmLayersPanel.frame
            var pFrame2 = pFrame;
            pFrame2.size.height = 10;
            fmLayersPanel.setFrame(pFrame2, display: true)
            
            
            pFrame.size.height = baseFMLayersPanelSize.height;
            fmLayersPanel.setFrame(pFrame, display: true, animate: true)
            
                        
            layersPanelBox.fillColor = .lightGray

            DispatchQueue.main.async
            {
                if(self.fmLayersPanel.frame.size.height != self.baseFMLayersPanelSize.height)
                {
                    self.fmLayersPanel.setSizeOfWindow(self.baseFMLayersPanelSize)
                }
                
            }


            //print(fmLayersPanel.frame.size.height)
            /*
              fmPaintFillModeTrayPanel.parent?.removeChildWindow(fmPaintFillModeTrayPanel);
            currentFMDocument?.docFMWindow.addChildWindow(fmPaintFillModeTrayPanel, ordered: NSWindow.OrderingMode.above)
          
           var pFrame = fmPaintFillModeTrayPanel.frame
           pFrame.size.height = 10;
            fmPaintFillModeTrayPanel.setFrame(pFrame, display: false)
          
            fmPaintFillModeTrayPanel.positionToWindowAccordingToConfiguration();
          
           var fFrame = fmPaintFillModeTrayPanel.frame
           fFrame.size.height = 115;
            
            if let topLeftPt = fmPaintFillModeTrayPanel.parent?.frame.topLeft()
            {
                fFrame.origin.y = topLeftPt.y - 145;
            }
          
           fmPaintFillModeTrayPanel.setFrame(fFrame, display: true, animate: true)
           
               
            fmPaintFillModeTrayPanel.setIsVisible(true)
            */
            
        }
     
    
    }
 
    //MARK: BOXES IN TITLEBAR
    @IBOutlet var selectedObjectsBox : NSBox!
    @IBOutlet var cartingModeBox : NSBox!
    @IBOutlet var selectedObjectsLabel : NSTextField!
    @IBOutlet var cartingModeLabel : NSTextField!
    @IBOutlet var shadingShapesModeBox : NSBox!
    @IBOutlet var combinatoricsModeBox : NSBox!
    @IBOutlet var combinatoricsModeLabel : NSTextField!
    @IBOutlet var layersPanelBox : NSBox!;
    @IBOutlet var paintFillModeTrayBox : NSBox!;
    
    // MARK: init
    override init()
    {

        super.init();
        canvasSizePxComputed = NSMakeSize(defaultDocumentWidth, defaultDocumentHeight)
        
        canvasSizeWidthStagingCurrentUnitsForPopover = canvasSizePxComputed.width;
        canvasSizeHeightStagingCurrentUnitsForPopover = canvasSizePxComputed.height;
        
        drawingPage = DrawingPage();
        drawingPage.drawingBoard = drawingBoard;
        activePenLayer = drawingPage.activePenLayer
        drawingPage.drawingPageController = self;
    
        
    }
    
                 
    var activePenLayer : ActivePenLayer?

    func setUpBlankDocument()
    {
        
        for (index, paperLayer) in drawingPage.paperLayers.enumerated()
        {
            paperLayer.name = "Layer \(index + 1)";
            paperLayer.currentDrawingPage = drawingPage;
        }
        
        drawingPage.updateDrawingLayersAndActivePenLayer()
        //drawingPage.refreshLayersPopUpButton();
    }
    
    func setUpDocumentLoadedFromFile()
    {
        // add layers here
        drawingPage.updateDrawingLayersAndActivePenLayer()
        //drawingPage.refreshLayersPopUpButton();
    }
    
    // MARK: -
    // MARK: TITLEBAR VIEWS
   
    @IBOutlet var nctPageSizeTitlebarView : NCTPageSizeTitlebarView?
    
      @IBOutlet var exportFrameTitlebarView : NCTExportFramingTitlebarView?


   

    
    // MARK: -
    // MARK: SET UP DRAWING BOARD, LOAD APP SETTINGS
    
    func setUpDrawingBoardForBlankDocument()
    {
        
        adjustDrawingBoardAndPageAndLayersToMatchPageSize()
        
        drawingBoard.addSubview(drawingPage)
        
                
    }
    
    func centerPermanentAnchorPoint()
    {
        drawingPage.permanentAnchorPoint = drawingPage.bounds.centroid()
    }
    
    
    // label:KEEPDOC_AND_APPSYNCed
    func loadCurrentAppSettingsIntoDrawing()
    {
        DispatchQueue.main.async {
            self.activePenLayer?.setupCursor();    
        }
        
        if let appDelegate = NSApp.delegate as? AppDelegate
        {
            shadingShapesModeBox.alphaValue = appDelegate.inkAndLineSettingsManager.shadingShapesModeIsOn ? 1.0 : 0.0;
            combinatoricsModeBox.alphaValue = appDelegate.inkAndLineSettingsManager.combinatoricsModeIsOn ? 1.0 : 0.0;
            combinatoricsModeLabel.stringValue = (appDelegate.inkAndLineSettingsManager.combinatoricsMode.stringValue())
            paintFillModeTrayBox.fillColor = appDelegate.fmPaintFillModeTrayPanel.isVisible ? .lightGray : .clear
        }
        
//        drawingPage.updateDrawingLayersAndActivePenLayer();
    }
    
    
    /*
    func changeDrawingBoardAndPagesToSize(_ size : NSSize)
    {
        let spaceAroundPage : CGFloat = 72;
        let rectBasedOnPaperSize = NSRect.init(origin: .zero, size: size)
        
        drawingBoard.frame = rectBasedOnPaperSize.insetBy(dx: -spaceAroundPage, dy: -spaceAroundPage)
        drawingBoard.subviews = [];
        
        drawingPage.frame = rectBasedOnPaperSize.offsetBy(dx: spaceAroundPage, dy: spaceAroundPage)
        drawingBoard.addSubview(drawingPage);
        
    }*/
    
    // MARK: -
    // MARK: CANVAS SIZE

   func adjustDrawingBoardAndPageAndLayersToMatchPageSize()
   {
    
        drawingBoard.frame = NSMakeRect(0, 0, canvasSizePxComputed.width + (drawingBoardMargin * 2) , canvasSizePxComputed.height + (drawingBoardMargin * 2))
        

        drawingPage.frame = drawingBoard.frame.insetBy(dx: drawingBoardMargin, dy: drawingBoardMargin)
        
        drawingPage.updateDrawingLayersAndActivePenLayer()
     
        nctPageSizeTitlebarView?.needsDisplay = true;
        
    }
    
    
    // https://oreillymedia.github.io/Using_SVG/guide/units.html
    let unitsConversionDictionary : [String:CGFloat] = ["px":1.0,"pt":1.3333,"in":96.0,"cm":37.795,"mm":3.7795]
  
    
    var canvasUnitsString : String = "px"
    
    var canvasWidthForCurrentUnits : CGFloat = 1920
    {
        didSet
        {
        
            if let truncatedValue = Double(String(format: "%.000f", canvasWidthForCurrentUnits))
            {
                canvasWidthForCurrentUnits = CGFloat(truncatedValue);
            }
        
        }
    }
    
    var canvasHeightForCurrentUnits : CGFloat = 1080
    {
        didSet
        {
            if let truncatedValue = Double(String(format: "%.000f", canvasHeightForCurrentUnits))
            {
                canvasHeightForCurrentUnits = CGFloat(truncatedValue);
            }
        }
    }
    
    var currentUnitsInNSSizeComputed : NSSize
    {
        get
        {
            return NSMakeSize(canvasWidthForCurrentUnits, canvasHeightForCurrentUnits);
        }
    }
    
    var canvasSizeString : String
    {
        get {
        
            return "\(canvasWidthForCurrentUnits) x \(canvasHeightForCurrentUnits) \(canvasUnitsString)"
        }
    }

    var canvasSizePxComputed : NSSize
    {
        set
        {
            if let unitsFactor : CGFloat = unitsConversionDictionary[canvasUnitsString]
            {
                canvasWidthForCurrentUnits = newValue.width / unitsFactor
                canvasHeightForCurrentUnits = newValue.height / unitsFactor
            }
        }

        get
        {
            if let unitsFactor : CGFloat = unitsConversionDictionary[canvasUnitsString]
            {
                let w = unitsFactor * canvasWidthForCurrentUnits
                let h = unitsFactor * canvasHeightForCurrentUnits
                return NSMakeSize(w, h);
            }
            else
            {
                return NSMakeSize(canvasWidthForCurrentUnits, canvasHeightForCurrentUnits)
            }
        
        }
        
    }
    
    
    
    var canvasSizeWidthStagingCurrentUnitsForPopover : CGFloat = 1920
    {
        didSet
        {
        
            canvasSizeWidthStagingTextField?.setCGFloatValue(canvasSizeWidthStagingCurrentUnitsForPopover)
            
        }
    }

    var canvasSizeHeightStagingCurrentUnitsForPopover : CGFloat = 1080
    {
        didSet
        {
            canvasSizeHeightStagingTextField?.setCGFloatValue(canvasSizeHeightStagingCurrentUnitsForPopover)
        }
    }


    @IBOutlet var canvasSizeStagingPopUpButton : NSPopUpButton?
    
  
    @IBAction func swapStagingSizeDimensions(_ sender : NCTButton)
    {
        let w = canvasSizeWidthStagingCurrentUnitsForPopover
        let h = canvasSizeHeightStagingCurrentUnitsForPopover
        canvasSizeWidthStagingCurrentUnitsForPopover = h;
        canvasSizeHeightStagingCurrentUnitsForPopover = w;
        
        stagingValueWasEdited = true;

        

    }
 
 
    @IBAction func changeCanvasSizeStagingFromPopUp(_ sender : NSPopUpButton)
    {
        if let selectedMenuItem = sender.selectedItem
       {
            if let representedObjectString = selectedMenuItem.representedObject as? String
            {
              
                let paperSizeRatioArray = representedObjectString.components(separatedBy: ",")
                if(paperSizeRatioArray.count > 2)
                {
                
                    guard unitsConversionDictionary.keys.contains(paperSizeRatioArray[2])  else
                    {
                        print("changeCanvasSizeStagingFromPopUp unit not in dictionary")
                        return;
                    }
                    
                    guard let stagingWidth = Double(paperSizeRatioArray[0]) else {
                        return
                    }
                  
                    guard let stagingHeight = Double(paperSizeRatioArray[1]) else {
                        return
                    }
                  
                    canvasSizeWidthStagingCurrentUnitsForPopover = CGFloat(stagingWidth)
                    canvasSizeHeightStagingCurrentUnitsForPopover = CGFloat(stagingHeight)
                    
                    canvasUnitsStagingString = paperSizeRatioArray[2];
                    
                    stagingValueWasEdited = true;
                }
                
                
            }
       }

    }
 
    
    // MARK: -
    // MARK: CANVAS SIZE STAGING
    
    @IBOutlet var applyCanvasStagingButton : NCTButton?
    var stagingValueWasEdited : Bool = false
    {
        didSet
        {
            if(stagingValueWasEdited == false)
            {
                applyCanvasStagingButton?.titleTextColor = .lightGray
            }
            else
            {
                applyCanvasStagingButton?.titleTextColor = .green
            }
            
            applyCanvasStagingButton?.needsDisplay = true;
        }
    }
    
    @IBOutlet var canvasUnitsStagingNCTSegm : NCTSegmentedControl?
    @IBAction func changeCanvasUnitsNCTSegm(_ sender : NCTSegmentedControl)
    {
    
                     
        // --------------------------------------
        // 1. convert from old canvas unit to px
        var pxWidth : CGFloat = canvasSizeWidthStagingCurrentUnitsForPopover
        var pxHeight : CGFloat = canvasSizeHeightStagingCurrentUnitsForPopover
        
        let oldUnitsStagingStringValue = canvasUnitsStagingString
        if let oldValueUnitsFactor = unitsConversionDictionary[oldUnitsStagingStringValue]
        {
            pxWidth = canvasSizeWidthStagingCurrentUnitsForPopover * oldValueUnitsFactor
            pxHeight = canvasSizeHeightStagingCurrentUnitsForPopover * oldValueUnitsFactor
            
        }
    
      
        // --------------------------------------
        // 2. update the control
    
        switch sender.selectedSegment
        {
        case 0:
            canvasUnitsStagingString = "px"
        case 1:
            canvasUnitsStagingString = "pt"
        case 2:
            canvasUnitsStagingString = "in"
        case 3:
            canvasUnitsStagingString = "cm"
        default:
            canvasUnitsStagingString = "px"
        }
    
        
        // --------------------------------------
        // 2. update the px computed, which updates the dimensions with units
        self.canvasSizePxComputedStaging = NSMakeSize(pxWidth, pxHeight)
    
        
        stagingValueWasEdited = true;
        

    }
    
    var canvasUnitsStagingString = "px"
    {
        didSet
        {
            
            if(unitsConversionDictionary.keys.contains(canvasUnitsStagingString) == false)
            {
                canvasUnitsStagingString = "px"
            }

          
            switch canvasUnitsStagingString
            {
            case "px":
                canvasUnitsStagingNCTSegm?.selectedSegment = 0
            case "pt":
                canvasUnitsStagingNCTSegm?.selectedSegment = 1
            case "in":
                canvasUnitsStagingNCTSegm?.selectedSegment = 2
            case "cm":
                canvasUnitsStagingNCTSegm?.selectedSegment = 3
            default:
                canvasUnitsStagingNCTSegm?.selectedSegment = 0
            }
        }
    
    }
    
    var canvasSizePxComputedStaging : NSSize
    {
        set
        {
            if let unitsFactor : CGFloat = unitsConversionDictionary[canvasUnitsStagingString]
            {
                canvasSizeWidthStagingCurrentUnitsForPopover = newValue.width / unitsFactor
                canvasSizeHeightStagingCurrentUnitsForPopover = newValue.height / unitsFactor
            }
        }

        get
        {
            if let unitsFactor : CGFloat = unitsConversionDictionary[canvasUnitsStagingString]
            {
                let w = unitsFactor * canvasSizeWidthStagingCurrentUnitsForPopover
                let h = unitsFactor * canvasSizeHeightStagingCurrentUnitsForPopover
                return NSMakeSize(w, h);
            }
            else
            {
                return NSMakeSize(canvasSizeWidthStagingCurrentUnitsForPopover, canvasSizeHeightStagingCurrentUnitsForPopover)
            }
        
        }
    
    }
    
    @IBOutlet var canvasSizeWidthStagingTextField : NSTextField?
    @IBAction func changeCanvasSizeStagingWidth(_ sender : NSControl)
    {
        canvasSizeWidthStagingCurrentUnitsForPopover = sender.cgfloatValue()
        
        stagingValueWasEdited = true;
        
        
    }
    
    @IBOutlet var canvasSizeHeightStagingTextField : NSTextField?
    @IBAction func changeCanvasSizeStagingHeight(_ sender : NSControl)
    {
        canvasSizeHeightStagingCurrentUnitsForPopover = sender.cgfloatValue()
        
        stagingValueWasEdited = true;
        

    }
    
    @IBAction func applyCanvasSizeStagingSettings(_ sender : NCTButton)
    {

    
        // 1. sets the units ("px" "pt" "in" "cm")
        canvasUnitsString = canvasUnitsStagingString;
        // 2. computes canvasSizeCurrentUnits
        canvasSizePxComputed = canvasSizePxComputedStaging
        // 3.
        adjustDrawingBoardAndPageAndLayersToMatchPageSize();
    
        stagingValueWasEdited = false;
    }
    
    @IBAction func resetCanvasSizeStagingSettings(_ sender : NCTButton)
    {
        loadAllCanvasSizePopoverControls()
        stagingValueWasEdited = false;
        
    }
    
    // MARK: -
    // MARK: EXPORT FRAME
    
    var exportFrame : NSRect = NSMakeRect(100, 50, 500, 900)
    {
        didSet
        {
        
        
        }
    }

    var exportFrameUnitsString : String = "px"
    var exportFrameWidthForCurrentUnits : CGFloat = 500.0
    var exportFrameHeightForCurrentUnits : CGFloat = 900.0
    
    var exportFrameWithUnitsOrigin : NSPoint
    {
        get
        {
            let x = exportFrame.origin.x * (unitsConversionDictionary[exportFrameUnitsString] ?? 0)
            let y = exportFrame.origin.y * (unitsConversionDictionary[exportFrameUnitsString] ?? 0)
            return NSMakePoint(x, y)
        }
    }
    var exportFrameWithUnitsNSRect : NSRect
    {
        get
        {
            let x = exportFrame.origin.x * (unitsConversionDictionary[exportFrameUnitsString] ?? 0)
            let y =  exportFrame.origin.y * (unitsConversionDictionary[exportFrameUnitsString] ?? 0)
            
            return NSMakeRect(x, y, exportFrameWidthForCurrentUnits, exportFrameHeightForCurrentUnits)
        }
    }

  var exportSizeString : String
    {
        get {
        
            return "\(exportFrameWidthForCurrentUnits) x \(exportFrameHeightForCurrentUnits) \(exportFrameUnitsString)"
        }
    }
    
    var exportFrameIsVisible : Bool = false
    {
        didSet
        {
            exportFrameIsVisibleNCTSegm?.selectedSegment = exportFrameIsVisible.onOffSwitchInt;
            self.drawingPage.activePenLayer.needsDisplay = true;
            exportFrameTitlebarView?.needsDisplay = true;
        }
    }

    var exportFrameIsOnTop : Bool = true
    {
        didSet
        {
            self.drawingPage.activePenLayer.needsDisplay = true;
        }
    }
    
    @IBOutlet var exportFrameIsVisibleNCTSegm : NCTSegmentedControl?
    
    func changeExportFrameCenterPointTo(point:NSPoint)
    {
        
        exportFrame = exportFrame.centerOnPoint(point)
        self.drawingPage.activePenLayer.needsDisplay = true;

    }
    
    @IBAction func changeExportFrameIsVisible(_ sender : NCTSegmentedControl)
    {
        exportFrameIsVisible = sender.onOffSwitchBool;
    }
    
    
    var exportFrameSource : Int = 0
    {
        didSet
        {
            exportFrameSourceNCTSegm?.selectedSegment = exportFrameSource
            
            if(exportFrameSource == 0)
            {
                makeExportFrameEqualToCanvas()
            }
            else if(exportFrameSource == 1)
            {
                makeExportFrameEqualToPageSetup()
            }
            
            
        }
    }
    
    @IBOutlet var exportFrameSourceNCTSegm : NCTSegmentedControl?

    @IBAction func changeExportFrameSource(_ sender : NCTSegmentedControl)
    {
    
        exportFrameSource = sender.selectedSegment;
    
    }
    
    func makeExportFrameEqualToCanvas()
    {
    
    }
    
    func makeExportFrameEqualToPageSetup()
    {
    
    }
    
    @IBAction func centerExportFrameInCanvas(_ sender : NCTButton?)
    {
        exportFrame = exportFrame.centerInRect(drawingPage.frame)
    }
    
    @IBOutlet var exportFrameSizeWidthTextField : NCTTextField?
    @IBAction func changeExportFrameSizeWidth(_ sender : NSControl)
    {
        
    }
    
    @IBOutlet var exportFrameSizeHeightTextField : NCTTextField?
    @IBAction func changeExportFrameSizeHeight(_ sender : NSControl)
    {
        
    }
    
    // MARK: -
    // MARK: LOADING A FILE
    

    func setUpDrawingBoardAndPageFromXML()
    {
        guard fmDocument.loadedXMLDoc != nil
        else
        {
            let a2 = NSAlert.init()
            a2.messageText = "XML Doc not loaded."
            a2.runModal()
            return
        }
    
        // loaded from the root element, <svg width="" height="">
        var widthToApply : CGFloat = 1920.0;
        var heightToApply : CGFloat = 1080.0;
        var unitsToApply = "px"
        
        // MARK: WIDTH FROM XML
        if let stringForWidth = fmDocument.loadedXMLDoc?.rootElement()?.attribute(forName: "width")?.stringValue
        {
            if(stringForWidth.count > 2)
            {
                let secondUnitLetter = stringForWidth.lastIndex(of: stringForWidth.last!)!;
                let firstUnitLetter = stringForWidth.index(secondUnitLetter, offsetBy: String.IndexDistance.init(-1))
            
               
            
                let a = stringForWidth[firstUnitLetter...secondUnitLetter];
        
                if(unitsConversionDictionary.keys.contains(String(a)))
                {
                    unitsToApply = String(a);
                }
       
                let wValString = stringForWidth[stringForWidth.startIndex..<firstUnitLetter]
                if let widthStringConvertedToDouble = Double(wValString)
                {
                    widthToApply = CGFloat(widthStringConvertedToDouble)
                }
             

            }
         
         
        }
        
        // MARK: HEIGHT FROM XML
        
        if let stringForHeight = fmDocument.loadedXMLDoc?.rootElement()?.attribute(forName: "height")?.stringValue
        {
            if(stringForHeight.count > 2)
            {
                let secondUnitLetter = stringForHeight.lastIndex(of: stringForHeight.last!)!;
                let firstUnitLetter = stringForHeight.index(secondUnitLetter, offsetBy: String.IndexDistance.init(-1))
            

                let a = stringForHeight[firstUnitLetter...secondUnitLetter];
        
                if(unitsConversionDictionary.keys.contains(String(a)))
                {
                    unitsToApply = String(a);
                }
       
                let hValString = stringForHeight[stringForHeight.startIndex..<firstUnitLetter]
                if let heightStringConvertedToDouble = Double(hValString)
                {
                    heightToApply = CGFloat(heightStringConvertedToDouble)
                }
             

            }
         
        }

        canvasUnitsString = unitsToApply
        canvasWidthForCurrentUnits = widthToApply
        canvasHeightForCurrentUnits = heightToApply;
        
        adjustDrawingBoardAndPageAndLayersToMatchPageSize()
        
        drawingBoard.addSubview(drawingPage)
     
     
        // MARK: SETTINGS FOR PAGE
        
        do {
            // XPath info: https://www.w3schools.com/xml/xpath_syntax.asp
            // MARK: GET G NODES WITH PAPERLAYER
            let drawingBoardSettingsNodesArray : [XMLElement] = try fmDocument.loadedXMLDoc!.nodes(forXPath: "/svg/defs[@fmkr:Defs='DocumentInformation']/fmkr:DrawingBoardSettings") as? [XMLElement] ?? []
           
            if(drawingBoardSettingsNodesArray.isEmpty == false)
            {
            
               if let margin = drawingBoardSettingsNodesArray[0].attribute(forName: "margin") as? XMLElement
               {
                let d = Double(margin.stringValue ?? "15.0") ?? 15.0
                drawingBoardMargin = CGFloat(d);
               }
               
                if let drawingSettings = drawingBoardSettingsNodesArray[0].children?[0].children as? [XMLElement]
                {
                    for setting in drawingSettings
                    {
                        if(setting.name != nil)
                        {
                            switch setting.name! {
                            case "fmkr:DrawingPageBackground":
                                drawingPage.defaultBackgroundColor = setting.colorFromAttribute(attributeName: "defaultBackgroundColor", defaultVal: NSColor.black)

                            case "fmkr:DrawingPageGrid":
                            
                                drawingPage.showGrid = setting.boolFromAttribute(attributeName: "showGrid", defaultVal: false)
                                drawingPage.gridSnappingEdgeLength = setting.cgFloatFromAttribute(attributeName: "gridSnappingEdgeLength", defaultVal: 40.0)
                                drawingPage.gridColor = setting.colorFromAttribute(attributeName: "gridColor", defaultVal: NSColor.white)
                                drawingPage.gridSnappingType = NCTGridSnappingType.init(rawValue: setting.attribute(forName: "gridSnappingType")?.stringValue ?? "squareDots") ?? .squareDots
                            
                            case "fmkr:ExportFrame":
                                
                                if let units = setting.attribute(forName: "units")?.stringValue
                                {
                                    exportFrameUnitsString = units
                                }
                                
                                if let exportRectStr =  setting.attribute(forName: "frameForUnits")?.stringValue
                                {
                                    let r = NSRectFromString(exportRectStr);
                                    exportFrameWidthForCurrentUnits = r.width
                                    exportFrameHeightForCurrentUnits = r.height
                                    
                                }
                                
                            case "fmkr:PermanentAnchorPoint":
                                let s = setting.stringFromAttribute(attributeName: "pt", defaultVal: NSStringFromPoint(.zero))
                                drawingPage.permanentAnchorPoint = NSPointFromString(s);
                                
                            default:
                            break;
                            }

                        }
                        
                    }

                }
            
            
            
            }
            
            
        }
        catch
        {
            
        }

    }
    
    
    @IBOutlet var progressIndicator : NSProgressIndicator!
    
    func setUpLayersFromXML()
    {
        guard fmDocument.loadedXMLDoc != nil else
        {
            print("fmDocument.loadedXMLDoc was nil in setUpLayersFromXML()")
            return
        }
        
        do {
            // XPath info: https://www.w3schools.com/xml/xpath_syntax.asp
            
            
            

            
            
            // MARK: GET G NODES (GROUP NODES) WITH PAPERLAYER
            let paperLayersGNodesArray : [XMLNode] = try fmDocument.loadedXMLDoc!.nodes(forXPath: "/svg/g[@fmkr:groupType='DrawingPage']/g[@fmkr:groupType='PaperLayer']")
            
            //let objects = try svgNode.nodes(forXPath: "/g[@fmkr:groupType='DrawingPage']/g[@fmkr:groupType='PaperLayer']")
            
            
            
            // MARK: CLEAR OUT EXISTING PAPER LAYERS
            drawingPage.paperLayers.removeAll();
            drawingPage.subviews.removeAll();
            
            var counter = 1
            
            
            
            progressIndicator.minValue = 0
            progressIndicator.isIndeterminate = false;
            progressIndicator.isHidden = false;
                        

            // ------------
            // FOR EACH LAYER IN THE ARRAY OF LAYERS
            for paperLayerGNode in paperLayersGNodesArray
            {
            
                progressIndicator.doubleValue = 0;
                
                let fmkrNameNodes = try paperLayerGNode.nodes(forXPath: "@fmkr:name")
                
                let fmkrIsHiddenNodes = try paperLayerGNode.nodes(forXPath: "@fmkr:isHidden")
                
                let isHiddenString : String = fmkrIsHiddenNodes.first?.stringValue ?? "false"
                
                let paperLayerObj = PaperLayer.init(frame: NSRect.init(origin: .zero, size: canvasSizePxComputed), name: fmkrNameNodes.first?.stringValue ?? "Layer \(counter)-D", isHidden: isHiddenString == "false" ? false : true,drawingPage: self.drawingPage)
                
                drawingPage.paperLayers.append(paperLayerObj);
                
                // ------------
                //  THERE ARE OBJECTS IN THE LAYER GROUP
                if(paperLayerGNode.children != nil)
                {
                    
                    
                    progressIndicator.maxValue = Double(paperLayerGNode.children!.count);

                    
                    for childOfGNode in paperLayerGNode.children!
                    {
                        guard childOfGNode.name != nil else {
                            
                            continue
                        }
                        
                        
                        var fmDrawableThatIsAdded : FMDrawable?
                        
                        
                        
                        fmDrawableThatIsAdded = fmDocument.appDelegate!.fmDrawableFromBaseXMLElement(baseXMLElement:childOfGNode as! XMLElement)
                        
                        
                        
                        if(fmDrawableThatIsAdded != nil)
                        {
                            paperLayerObj.orderingArray.append(fmDrawableThatIsAdded!)
                            
                        }
                    }// END for childOfGNode in paperLayerGNode.children!
                }// END if paperLayerGNode.children != nil
                
                // MARK: reindexOrderingArrayDrawables
                paperLayerObj.reindexOrderingArrayDrawables();
                
                counter += 1;
                
                progressIndicator.increment(by: 1.0);
                
            }// END for paperLayerGNode in paperLayersGNodesArray
            
            progressIndicator.isHidden = true;
            
            
            // MARK: SET THE CURRENTPAPERLAYERINDEX
            let drawingPageGNodeArray : [XMLNode] = try fmDocument.loadedXMLDoc!.nodes(forXPath: "/svg/g[@fmkr:groupType='DrawingPage']");
            
            
            if(drawingPageGNodeArray.isEmpty == false)
            {
                
                let g = drawingPageGNodeArray[0] as! XMLElement;
                
                drawingPage.currentPaperLayerIndex = g.intFromAttribute(attributeName: "fmkr:currentPaperLayerIndex", defaultVal: 0);
                
            }
            
            adjustDrawingBoardAndPageAndLayersToMatchPageSize();
            
            
            
            
        } catch  {
            print("fmDocument.loadedXMLDoc forXPath did not return objects for g")
            return;
        }
        
        
        
        
    }
    
    override func awakeFromNib()
    {
        drawingPage.setupActivePenLayerForDrawing();
        loadSettings()
        
        layersTableView?.gridStyleMask = .dashedHorizontalGridLineMask;
        
 
        if(fadingMessageIndicator != nil)
        {
            fadingMessageIndicator!.removeFromSuperview();
            fadingMessageIndicator!.layer?.opacity = 0.0;
            if(fadingMessageIndicator!.layer == nil)
            {
                fadingMessageIndicator!.isHidden = true;
                
            }
        }
    }
    
    func loadSettings()
    {
        exportFrameIsVisible = false;
        exportFrameSource = 0;
       
       canvasWidthForCurrentUnits = 1920;
       canvasHeightForCurrentUnits = 1080;
       canvasUnitsString = "px"
       
       // LAYERS TABLE VIEW
       //baseFMLayersPanelSize = fmLayersPanel.frame.size;
       layersTableView?.usesAlternatingRowBackgroundColors = true;
       //layersTableView?.allowsMultipleSelection = true;
        //layersTableView!.target = self;
        //layersTableView?.doubleAction = #selector( doubleClickLayersTableRow(_:) )
        layersTableVerticalScroller?.scrollerStyle = .legacy;
        
    }
    
    // MARK: -
    // MARK: POPOVER DELEGATE MATHODS
    
    @IBOutlet var canvasSizePopover : NSPopover?
    @IBOutlet var exportFramePopover : NSPopover?
    
    func popoverWillShow(_ notification: Notification)
    {
    
        if canvasSizePopover == notification.object as? NSPopover
        {
            loadAllCanvasSizePopoverControls()
        }

        if exportFramePopover == notification.object as? NSPopover
        {
            loadAllExportFramePopoverControls()
        }

    }
    
    func popoverWillClose(_ notification: Notification)
    {
        
        if canvasSizePopover == notification.object as? NSPopover
        {
            stagingValueWasEdited = false;
        }
    }
    
    func loadAllCanvasSizePopoverControls()
    {
        canvasSizeWidthStagingCurrentUnitsForPopover = canvasWidthForCurrentUnits
        canvasSizeHeightStagingCurrentUnitsForPopover = canvasHeightForCurrentUnits
        
        canvasUnitsStagingString = canvasUnitsString;
       
        stagingValueWasEdited = false;

        
    }
    
    func loadAllExportFramePopoverControls()
    {
    
    }
    
    // MARK: layersTableView
    @IBOutlet var layersTableView : NSTableView?
    
    @IBOutlet var layersTableVerticalScroller: NSScroller?
    
    
    @IBAction func hideLayersPanelFromLayersPanel(_ sender : NSControl)
    {
        // check here to make sure  no
        // alerts are open.


        changeVisibilityForLayersPanel(!(fmLayersPanel.isVisible))
        
        
    }
    
    /*@IBAction func openCurrentLayerRowForEditing(_ sender : NSControl)
    {
        //layersTableView?.row(for: <#T##NSView#>)
        if let tableRowView = layersTableView?.rowView(atRow: layersTableView!.selectedRow, makeIfNecessary: false)
        {
            layersTableView?.selectedCell()
        }
    }*/
    
    @IBAction func enterTextFromLayerNameCell(_ sender: Any)
    {
    
      if let textField = sender as? NSTextField {

            let row = self.layersTableView!.row(for: sender as! NSView)
            let col = self.layersTableView!.column(for: sender as! NSView)
            if(col == 0)
            {
                if(row == drawingPage.currentPaperLayerIndex)
                {
                    drawingPage.currentPaperLayer.name = textField.stringValue
                }
          
                self.layersTableView!.reloadData(forRowIndexes: IndexSet.init(integer: row), columnIndexes: IndexSet.init(integer: col))
//            self.data[row][col] = textField.stringValue

//            print("\(row), \(col), \(textField.stringValue)")

//            print("\(data)")
            }
        }
    }
    
    @IBAction func addLayerFromLayersPanel(_ sender : NSControl)
    {
        
        let maxLayerCount = fmDocument.appDelegate!.inkAndLineSettingsManager.maxLayerCount;
        
        if(self.drawingPage.paperLayers.count < maxLayerCount)
        {
            let suffix = self.drawingPage.paperLayers.count + 1;
            let name = "Layer \(suffix)";
            let paperLayerToAdd = PaperLayer.init(frame: self.drawingPage.bounds, name: name, isHidden: false, drawingPage: self.drawingPage)
            
            
            paperLayerToAdd.name = name;
            
            let layerThatHasNameAlready = self.drawingPage.paperLayers.first(where: { paperLayer in
                return (paperLayer.name == name);
            })
            
            if(layerThatHasNameAlready != nil)
            {
                paperLayerToAdd.name = "\(paperLayerToAdd.name)-2"
            }
            
            
            
            self.activePenLayer!.removeFromSuperview();
            self.drawingPage.addSubview(paperLayerToAdd);
            self.drawingPage.addSubview(self.activePenLayer!);
            self.drawingPage.updateDrawingLayersAndActivePenLayer();
            self.drawingPage.paperLayers.append(paperLayerToAdd)
            
            self.updateLayersPanelTable();

            
        }
        else
        {
            let a = NSAlert.init()
            a.messageText = "Limit of \(maxLayerCount) layers."
            a.beginSheetModal(for: layersTableView!.window!, completionHandler: nil)
            
            
        }
        
        
    }
    
    @IBAction func removeLayerFromLayersPanel(_ sender : NSControl)
    {
        let a = NSAlert.init();
        
        a.messageText = "Delete \(self.drawingPage.currentPaperLayer.name)?"
        a.showsSuppressionButton = true
        a.addButton(withTitle: "OK")
        a.addButton(withTitle: "Cancel")
        a.beginSheetModal(for: layersTableView!.window!) { modalResponse in
            
        
            /*
             NSAlertFirstButtonReturn   = 1000,
             NSAlertSecondButtonReturn   = 1001,
             NSAlertThirdButtonReturn   = 1002
             */
        
            // ------------------------
            // For whatever reason, use ModalResponse.alertFirstButtonReturn
            // instead of ModalResponse.OK
            // ------------------------
            if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn
            {
                if(self.drawingPage.paperLayers.count > 1)
                {
                    let isFirst = (self.drawingPage.currentPaperLayerIndex == 0);
                    let isLast = self.drawingPage.currentPaperLayerIndex ==  self.drawingPage.paperLayers.count - 1;
                    let storedPastIndex = self.drawingPage.currentPaperLayerIndex;
                    
                    self.drawingPage.currentPaperLayer.removeFromSuperview();
                    self.drawingPage.paperLayers.remove(at: self.drawingPage.currentPaperLayerIndex);
                    
                    if(isFirst)
                    {
                        self.drawingPage.currentPaperLayerIndex = 0
                    }
                    else if(isLast)
                    {
                        self.drawingPage.currentPaperLayerIndex = self.drawingPage.paperLayers.count - 1
                    }
                    else
                    {
                        self.drawingPage.currentPaperLayerIndex = storedPastIndex;
                    }
                    
                  //  self.layersTableView?.removeRows(at: IndexSet.init(integer: storedPastIndex), withAnimation: NSTableView.AnimationOptions.slideUp)
                    
                    self.updateLayersPanelTable();
                }
                
              
                
            }
            else if (modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn)
            {
              

               
            }
            
        }
        
        updateLayersPanelTable();
    }
    
    
   // @IBOutlet var layersPopUpButton : NSPopUpButton?

    @IBAction func changeCurrentLayer(_ sender : NSControl)
    {
        if(fmDocument.appDelegate?.lineWorkInteractionEntity.lineWorkEntityMode != .idle)
        {
            fmDocument.appDelegate?.lineWorkInteractionEntity.endKeyPress()
        }
        if(drawingPage.currentPaperLayer.hasSelectedDrawables)
        {
            drawingPage.currentPaperLayer.clearOutSelections();
        }

        if let popUpButton = sender as? NSPopUpButton
        {
            if let menuItem = popUpButton.selectedItem
            {
                if(
                (menuItem.tag < drawingPage.paperLayers.count)
                && (drawingPage.paperLayers.isEmpty == false)
                )
                {
                    drawingPage.currentPaperLayerIndex = menuItem.tag
                }
            }
        
        }
        
    }
    
    
    // MARK: NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
   
        return drawingPage.paperLayers.count
    }
    
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        if(drawingPage.currentPaperLayerIndex != layersTableView!.selectedRow)
        {
           // if((layersTableView!.selectedRow > -1)/* && (layersTableView!.selectedRow < layersTableView!.numberOfRows)*/)
           // {
                drawingPage.currentPaperLayerIndex = layersTableView!.selectedRow
           // }
        }
       // if layer selected is not the
       // same as the currentPaperLayer
       
    }
    
    /*
    func tableView(_ tableView: NSTableView, didRemove rowView: NSTableRowView, forRow row: Int)
    {
        
    }
    */
    
    
    /*
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        guard row < drawingPage.paperLayers.count else {
            return ""
        }
        
        return drawingPage.paperLayers[row].name
        
    }*/
    
    
    
    
    // MARK: NSTableViewDelegate
    
    func tableView(_ tableView: NSTableView, didRemove rowView: NSTableRowView, forRow row: Int) {
        
        
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
    
      guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
    
        if(tableColumn!.identifier.rawValue == "layerName")
        {
            cell.textField?.stringValue = drawingPage.paperLayers[row].name
        
            /*
            var txtField : NSTextField = NSTextField.init(frame: NSMakeRect(0, 0, 100, 30))
            txtField.isEditable = true
            txtField.isBordered = true;
            
            txtField.stringValue = drawingPage.paperLayers[row].name
            
            return txtField;*/
        }
        else if(tableColumn!.identifier.rawValue == "numberOfObjects")
        {
            cell.textField?.stringValue = String(drawingPage.paperLayers[row].orderingArray.count)
        }
        else if(tableColumn!.identifier.rawValue == "visible")
        {
                        
            cell.textField?.stringValue = String(!drawingPage.paperLayers[row].isHidden)
            
            let nctSwitch = NCTSwitch.init(frame: cell.frame.insetBy(dx: 2, dy: 2));
            nctSwitch.rightMargin = 10;
            nctSwitch.state = (!drawingPage.paperLayers[row].isHidden).stateValue
            nctSwitch.target = drawingPage.paperLayers[row];
            nctSwitch.action = #selector( drawingPage.paperLayers[row].changeHiddenStateFromLayersPanel(_:) )
            return nctSwitch;
        }
        
        //tableColumn!.identifier.rawValue
    
        return cell

    /*
       // Get an existing cell with the MyView identifier if it exists
        var result =
        tableView.makeView(
        withIdentifier: tableColumn!.identifier,//NSUserInterfaceItemIdentifier(rawValue: "MyView"),
        owner: self)
        
        if (result == nil)
        {
            // Create the new NSTextField with a frame of the {0,0} with the width of the table.
         // Note that the height of the frame is not really relevant, because the row height will modify the height.

            result = NSTextField.init(frame: NSMakeRect(0, 0, 300, 30))
         
         // The identifier of the NSTextField instance is set to MyView.
         // This allows the cell to be reused.
         result!.identifier = tableColumn!.identifier, //NSUserInterfaceItemIdentifier(rawValue: "MyView");
         
         
        
        }

        return result;
    */
 
    }
    /*
     @objc func doubleClickLayersTableRow(_ sender : AnyObject?)
    {
    
    
    }
    */
    func updateLayersPanelTable()
    {
        layersTableView?.reloadData();
        layersTableView?.selectRowIndexes(IndexSet.init(arrayLiteral: drawingPage.currentPaperLayerIndex), byExtendingSelection: false);
    
    }

// MARK: -
// MARK: - MOMENTARY APP MESSAGE INDICATOR

    @IBOutlet var fadingMessageIndicator: NSTextField?
    
   

    
    func fadeInOutMessageIndicatorWithMessage(string:String, duration:CGFloat, messageLevel:Int)
    {
        
        guard fmDocument.appDelegate != nil else
        {
            return;
        }
        
        
        guard fmDocument.appDelegate!.inkAndLineSettingsManager.allowStatusMessagesBecauseOfKeypress else {
            return;
        }

        guard fadingMessageIndicator != nil else {
            return;
        }
    
        if(fmDocument.appDelegate!.inkAndLineSettingsManager.statusMessagesIsOn && !fmDocument.appDelegate!.inkAndLineSettingsManager!.suspendMessageIndicator)
        {
            if(messageLevel <= fmDocument.appDelegate!.inkAndLineSettingsManager.statusMessageMaxmimumPriorityLevel)
            {
                var f = fadingMessageIndicator!.frame;
                f.size.width = fmDocument.docFMWindow.frame.size.width
                f.origin.x = 0;
                f.origin.y = fmDocument.docFMWindow.frame.size.height * 0.67;
                fadingMessageIndicator!.frame = f;
              
                fmDocument.docFMWindow.contentView?.addSubview(fadingMessageIndicator!)
                fadingMessageIndicator!.stringValue = string;
                fadingMessageIndicator!.fadeInOut(durationInSec: duration, removeFromSuperview: true);
                
            }
        }
    }
    
} // END


// MARK: -
// MARK: -
// MARK: NCTPageSizeTitlebarView
class NCTPageSizeTitlebarView: NSView
{
    var pageSizeString : String
    {
        get{
            if(nctDrawingPageController != nil)
            {
                return nctDrawingPageController!.canvasSizeString
            }
            
            return "default"
        
        }
    }
    @IBOutlet var nctDrawingPageController : NCTDrawingPageController?
    
    @IBOutlet var pageSizeSettingsPopover : NSPopover?
    
    
    @IBInspectable var leftMargin : CGFloat = 25;
    
    override func draw(_ dirtyRect: NSRect)
    {
        if(mouseIsInside)
        {
            NSColor.white.setFill()
           // self.bounds.frame();
            
            NSColor.init(calibratedWhite: 0.5, alpha: 0.8).setFill()
            if(isInsideButtonRect)
            {
                NSColor.init(calibratedWhite: 0.8, alpha: 0.8).setFill()
            }
            var buttonBgRect = self.bounds
            buttonBgRect.size.width = 30;
            buttonBgRect.fill();
        }
    
        var rectForCanvasSizeLabel = self.bounds;
        rectForCanvasSizeLabel.size.height /= 2;
        rectForCanvasSizeLabel.origin.x += 5 + leftMargin;
        rectForCanvasSizeLabel.origin.y += rectForCanvasSizeLabel.size.height;
        let canvasSizeLabelString : String = "Canvas Size"
        canvasSizeLabelString.drawStringInsideRectWithSFProFont(fontSize: 12.0, textAlignment: NSTextAlignment.left, fontForegroundColor: (mouseIsInside == false) ? NSColor.gray : .white, rect: rectForCanvasSizeLabel)
        
        
        var rectForCanvasDimensionsLabel = self.bounds;
        rectForCanvasDimensionsLabel.size.height /= 2;
        rectForCanvasDimensionsLabel.origin.x += 5 + leftMargin;
        rectForCanvasDimensionsLabel.origin.y += 3;
        pageSizeString.drawStringInsideRectWithSFProFont(fontSize: 14.0, textAlignment: NSTextAlignment.left, fontForegroundColor: (mouseIsInside == false) ? NSColor.gray : NSColor.white, rect: rectForCanvasDimensionsLabel)
//        pageSizeString.drawStringInsideRectWithMenlo(fontSize: self.bounds.height - 10, textAlignment: NSTextAlignment.left, fontForegroundColor: NSColor.white, rect: self.bounds);
        
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true;
    }
    
   
    func launchPopover(relativeToBounds : NSRect, positioningView: NSView, preferredEdge: NSRectEdge)
    {
        if pageSizeSettingsPopover != nil
        {
           pageSizeSettingsPopover!.close();

        
            NotificationCenter.default.post(name: Notification.Name.init("NCTCloseAnyPopovers"), object: self)
            
            pageSizeSettingsPopover!.show(relativeTo: relativeToBounds, of: positioningView, preferredEdge: preferredEdge)
            
            NotificationCenter.default.post(name: Notification.Name.init("NCTCurrentlyShownPopover"), object: pageSizeSettingsPopover)
            
        }
        
    }
    
    var mouseIsInside : Bool = false;

    var trackingArea : NSTrackingArea = NSTrackingArea();

    var isInsideButtonRect : Bool = false
    override func mouseMoved(with event: NSEvent)
    {
        
        let p = self.convert(event.locationInWindow, from: nil)
        
        var buttonBounds = self.bounds
        buttonBounds.size.width = 30;
        
        if(NSPointInRect(p, buttonBounds))
        {
            isInsideButtonRect = true;
            NSCursor.pointingHand.set();
        }
        else
        {
            isInsideButtonRect = false;
            NSCursor.arrow.set();
        }
        
        self.needsDisplay = true;
    }
    
    override func mouseEntered(with event: NSEvent) {
        mouseIsInside = true;
        
        self.window?.makeFirstResponder(self)

        self.needsDisplay = true;
        
        
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseIsInside = false;
        isInsideButtonRect = false;
        self.needsDisplay = true;
    }
    
    override func mouseDown(with event: NSEvent)
    {

        let pointInView = self.convert(event.locationInWindow, from: nil)
        
        var buttonBounds = self.bounds
        buttonBounds.size.width = 30;
        if(NSPointInRect(pointInView, buttonBounds))
        {
            
            launchPopover(relativeToBounds: self.bounds, positioningView: self, preferredEdge: NSRectEdge.minY)
        }

    }
    
   override func updateTrackingAreas()
    {
        
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved],
                                      owner: self, userInfo: nil)
       
        
        self.addTrackingArea(trackingArea)
        
    }
    
}

// MARK: -
// MARK: NCTExportFramingTitlebarView
class NCTExportFramingTitlebarView: NSView
{

    @IBOutlet var nctDrawingPageController : NCTDrawingPageController?
    
    @IBOutlet var exportFramingSettingsPopover : NSPopover?

    @IBInspectable var leftMargin : CGFloat = 25;

    override func draw(_ dirtyRect: NSRect)
    {
       if(mouseIsInside)
        {
            NSColor.white.setFill()
            //self.bounds.frame();
            
            NSColor.init(calibratedWhite: 0.5, alpha: 0.8).setFill()
            if(isInsideButtonRect)
            {
                NSColor.init(calibratedWhite: 0.8, alpha: 0.8).setFill()
            }
            
            var buttonBgRect = self.bounds
            buttonBgRect.size.width = 30;
            buttonBgRect.fill();
        }
        
        
         var rectForExportSizeLabel = self.bounds;
        rectForExportSizeLabel.size.height /= 2;
        rectForExportSizeLabel.origin.x += 5 + leftMargin;
        rectForExportSizeLabel.origin.y += rectForExportSizeLabel.size.height;
        let onOff = nctDrawingPageController!.exportFrameIsVisible ? " ON - ⌘E" : " OFF - ⌘E"
        let exportSizeLabelString : String = "Export Frame\(onOff)"
        
        let fgColor : NSColor = nctDrawingPageController!.exportFrameIsVisible ? NSColor.green : (mouseIsInside == false) ? NSColor.gray : .white
        
        
        exportSizeLabelString.drawStringInsideRectWithSFProFont(fontSize: 12.0, textAlignment: NSTextAlignment.left, fontForegroundColor: fgColor, rect: rectForExportSizeLabel)
        
        
           var rectForExportFrameDimensionsLabel = self.bounds;
        rectForExportFrameDimensionsLabel.size.height /= 2;
        rectForExportFrameDimensionsLabel.origin.x += 5 + leftMargin;
        rectForExportFrameDimensionsLabel.origin.y += 3;
        if let exportStr = nctDrawingPageController?.exportSizeString
        {
        exportStr.drawStringInsideRectWithSFProFont(fontSize: 14.0, textAlignment: NSTextAlignment.left, fontForegroundColor: (mouseIsInside == false) ? NSColor.gray : NSColor.white, rect: rectForExportFrameDimensionsLabel)
        
        }
        
    }

    var mouseIsInside : Bool = false;

    var trackingArea : NSTrackingArea = NSTrackingArea();


    var isInsideButtonRect : Bool = false
    
    override func mouseMoved(with event: NSEvent)
    {
        
        let p = self.convert(event.locationInWindow, from: nil)
        
        var buttonBounds = self.bounds
        buttonBounds.size.width = 30;
        
        if(NSPointInRect(p, buttonBounds))
        {
            isInsideButtonRect = true;
            NSCursor.pointingHand.set();
        }
        else
        {
            isInsideButtonRect = false;
            NSCursor.arrow.set();
        }
        
        self.needsDisplay = true;
    }
    
    override func mouseEntered(with event: NSEvent) {
        mouseIsInside = true;
        
        self.window?.makeFirstResponder(self)


        self.needsDisplay = true;
        
        
    }
    
 
    
    override func mouseExited(with event: NSEvent) {
        mouseIsInside = false;
        isInsideButtonRect = false;
        self.needsDisplay = true;
    }
    
    override func mouseDown(with event: NSEvent)
    {
        let pointInView = self.convert(event.locationInWindow, from: nil)
        
        var buttonBounds = self.bounds
        buttonBounds.size.width = 30;
        if(NSPointInRect(pointInView, buttonBounds))
        {
            
            launchPopover(relativeToBounds: self.bounds, positioningView: self, preferredEdge: NSRectEdge.minY)
        }
        
    }
    
     func launchPopover(relativeToBounds : NSRect, positioningView: NSView, preferredEdge: NSRectEdge)
    {
        if exportFramingSettingsPopover != nil
        {
           exportFramingSettingsPopover!.close();

        
            NotificationCenter.default.post(name: Notification.Name.init("NCTCloseAnyPopovers"), object: self)
            
            exportFramingSettingsPopover!.show(relativeTo: relativeToBounds, of: positioningView, preferredEdge: preferredEdge)
            
            NotificationCenter.default.post(name: Notification.Name.init("NCTCurrentlyShownPopover"), object: exportFramingSettingsPopover)
            
        }
        
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true;
    }
    
    
    override func updateTrackingAreas()
    {
        
        super.updateTrackingAreas()
        
        
        self.removeTrackingArea(trackingArea)
        
        trackingArea = NSTrackingArea(rect: self.bounds, options:[.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved],
                                      owner: self, userInfo: nil)
        
        
        self.addTrackingArea(trackingArea)
  
        
    }
}
