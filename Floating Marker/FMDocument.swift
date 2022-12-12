//
//  Document.swift
//  Floating Marker
//
//  Created by John Pratt on 1/10/21.
//

import Cocoa
import WebKit


// MARK: FMContentViewController

class FMContentViewController : NSViewController
{
    @IBOutlet var fmDocument : FMDocument!;
    
    
    var viewDidAppearFirstTime : Bool = false;
    override func viewDidAppear()
    {
        if(viewDidAppearFirstTime == false)
        {
            fmDocument.windowVisibleHasBeenMadeVisibleFirstTime = true
            viewDidAppearFirstTime = true;
        }
        
 
    }

  
    
}

// MARK: FMWindow

class FMWindow : NSWindow
{
    @IBOutlet var fmDocument : FMDocument?
    
    @IBOutlet var leftTitlebarView : NSView?
    @IBOutlet var rightTitlebarView : NSView?
    
    
    @IBOutlet var magnificationComboBox : NSComboBox?

    var titlebarViewCurrentDrawingSettingsLabelTextField : NSTextField?
    var titlebarViewCurrentStrokeColorWell : NSColorWell?;

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool)
    {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        
        
        
    }

    override func awakeFromNib()
    {
        
        self.tabbingMode = .disallowed;
        
        if(rightTitlebarView != nil)
        {
            let rightSideTitlebarViewController = NSTitlebarAccessoryViewController.init()
            rightTitlebarView!.translatesAutoresizingMaskIntoConstraints = false
            rightSideTitlebarViewController.layoutAttribute = NSLayoutConstraint.Attribute.trailing
            
            
            rightSideTitlebarViewController.view = rightTitlebarView!
            self.addTitlebarAccessoryViewController(rightSideTitlebarViewController)
        }
        
        if( leftTitlebarView != nil)
        {
            let leftSideTitlebarViewController = NSTitlebarAccessoryViewController.init()
            leftTitlebarView!.translatesAutoresizingMaskIntoConstraints = false
            leftSideTitlebarViewController.layoutAttribute = NSLayoutConstraint.Attribute.leading
            
            
            leftSideTitlebarViewController.view = leftTitlebarView!
            self.addTitlebarAccessoryViewController(leftSideTitlebarViewController)
        
        
        }
/*
            // ---------------------------------------------
        // MARK: button For DocumentSize Popover
        let titlebarViewControllerForDocumentSize = NSTitlebarAccessoryViewController.init()
        let buttonForDocumentSizePopover = NSButton();
        buttonForDocumentSizePopover.frame = NSMakeRect(0, 0, 100, 30)
        buttonForDocumentSizePopover.title = "8.5\" x 11\"";
        buttonForDocumentSizePopover.target = self;
        buttonForDocumentSizePopover.action = #selector(self.documentSizeTitlebarPopover)
        titlebarViewControllerForDocumentSize.view = buttonForDocumentSizePopover
        buttonForDocumentSizePopover.translatesAutoresizingMaskIntoConstraints = false
        titlebarViewControllerForDocumentSize.layoutAttribute = NSLayoutConstraint.Attribute.leading;

        self.addTitlebarAccessoryViewController(titlebarViewControllerForDocumentSize)


        
        // ---------------------------------------------
        // MARK: Current Marker Settings Label
        let titlebarViewControllerForCurrentMarkerSettings = NSTitlebarAccessoryViewController.init()
        let currentMarkerSettingsTextField = NSTextField();
        currentMarkerSettingsTextField.stringValue = "10pt rectangle marker 45°"
        currentMarkerSettingsTextField.frame = NSMakeRect(0, 0, 180, 100)

        titlebarViewCurrentDrawingSettingsLabelTextField = currentMarkerSettingsTextField;
        titlebarViewControllerForCurrentMarkerSettings.view = currentMarkerSettingsTextField;
        titlebarViewControllerForCurrentMarkerSettings.layoutAttribute = NSLayoutConstraint.Attribute.trailing
        self.addTitlebarAccessoryViewController(titlebarViewControllerForCurrentMarkerSettings)


        // ---------------------------------------------
        // MARK: Color well for Current Stroke Color
        
        let titlebarViewControllerForStrokeColorWell = NSTitlebarAccessoryViewController.init()
        let currentStrokeColorWell = NSColorWell();
        currentStrokeColorWell.frame = NSMakeRect(0, 0, 30, 30)
        currentStrokeColorWell.color = NSColor.green;
        currentStrokeColorWell.target = self;
        currentStrokeColorWell.action = #selector(self.changeCurrentStrokeColor)
        titlebarViewControllerForStrokeColorWell.view = currentStrokeColorWell;
//        titlebarViewCurrentStrokeColorWell = currentStrokeColorWell;
        titlebarViewControllerForStrokeColorWell.layoutAttribute = NSLayoutConstraint.Attribute.trailing
        
        self.addTitlebarAccessoryViewController(titlebarViewControllerForStrokeColorWell)
       */
        
        magnificationComboBox?.removeAllItems()
        magnificationComboBox?.addItems(withObjectValues: [0.25,0.5,1.0,1.5,2.0,2.5,3.0,4.0])


    }

    @objc func documentSizeTitlebarPopover(_ sender : NSControl)
    {
    
    }


    @objc func changeCurrentStrokeColor(_ sender : NSControl)
    {
    
    }
    

   @IBAction @objc func changeDrawingScrollViewMagnification(_ sender : NSComboBox?)
    {
        
      self.fmDocument?.drawingScrollView.magnification = sender!.cgfloatValue();
    }
    
    @IBAction @objc func resetDrawingScrollViewMagnification(_ sender : NSControl)
    {
      self.fmDocument?.drawingScrollView.magnification = 1.0;
    }
    
    @IBOutlet var currentPaperLayerPopUpButton : NSPopUpButton?
    
    @IBAction @objc func changeCurrentPaperLayer(_ sender: NSPopUpButton?)
    {
    
    }
    
    @IBOutlet var azimuthCircularSlider : NCTAngularCircularSlider?
    
    
}

class FMDocument: NSDocument, NSWindowDelegate {

//    @IBOutlet var fmKeyboardPanel : FMInteriorPanel!;

    @IBOutlet var drawingPageController : NCTDrawingPageController?;

    var fileWasOpened : Bool = false

  

    
    var windowVisibleHasBeenMadeVisibleFirstTime : Bool = false
    {
        didSet
        {
            if((oldValue == false) && (windowVisibleHasBeenMadeVisibleFirstTime == true))
            {
               fmWindowVisibleForFirstTime();
            }
        }
    }
    
    func fmWindowVisibilityChanged(_ flag : Bool)
    {
        if(self.fileWasOpened == false)
        {
        
        }
        
        if(flag == true)
        {
            windowVisibleHasBeenMadeVisibleFirstTime = true;
        }
        
    }
    
    
    var appDelegate : AppDelegate?
    {
        return NSApp.delegate as? AppDelegate;
    }
    
    // MARK: fmWindowVisibleForFirstTime()
    func fmWindowVisibleForFirstTime()
    {
       if let appDelegate = NSApp.delegate as? AppDelegate
       {
            let screenThatWindowIsOn = docFMWindow.screen;
         //   let screenHeight : CGFloat = screenThatWindowIsOn?.frame.height ?? 1000.0;
    

            docFMWindow.setSizeOfWindow(width: appDelegate.newDocumentWidth - appDelegate.windowPadding, height: screenThatWindowIsOn!.visibleFrame.height - appDelegate.inkSettingsPanel.frame.height - 10)


        
//        Swift.print(appDelegate.inkSettingsPanel.frame.origin.y)
//        Swift.print((appDelegate.inkSettingsPanel.screen?.frame.topLeft().y ?? 0) - 25)
//        Swift.print(appDelegate.inkSettingsPanel.frame.height + 80)
//
        if(
        appDelegate.inkSettingsPanel.frame.origin.y  >
            
            (
            ( (appDelegate.inkSettingsPanel.screen?.frame.topLeft().y ?? 0) - 25)
            
            - (appDelegate.inkSettingsPanel.frame.height + 80)
            )
            
            )
   
        {
        
            docFMWindow.positionAtTopLeftOfScreen(xPadding: 5, yPadding:  appDelegate.inkSettingsPanel.frame.size.height + 10)
            
            //            docFMWindow.positionWithTopLeftBias(nextTo: appDelegate.inkSettingsPanel, locationNumber: NCTWindowRelativePosition.bottomMiddle, paddingAwayFromEdge: 5, matchingHeightOfWindow: false, matchingWidthOfWindow: false)
            
            let dCount = CGFloat(NSDocumentController.shared.documents.count)
            
            if(dCount > 1.0)
            {
                docFMWindow.translateHorizontal(dCount * 2)
                docFMWindow.translateVertical(dCount * -15)
                
            }
            
            
        }

            
            //appDelegate.repositionAccessoryPanelsForFMDocumentWindow(self.docFMWindow);
            
            
            
       }
    
    
    }

    override init() {
        super.init()
        
        Bundle.main.loadNibNamed("SavePanels", owner: self, topLevelObjects: nil)
        
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool
    {
        return true
    }

    override var windowNibName: NSNib.Name? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return NSNib.Name("FMDocument")
    }


    // MARK: ------ FILE DATA
    // MARK: data(ofType typeName: String)

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
        
        if(typeName == "com.noctivagous.floating-marker")
        {
            generateXMLDoc()
            let dataToReturn : Data? = xmlDoc.xmlString(options: [XMLNode.Options.nodePrettyPrint, XMLNode.Options.nodeCompactEmptyElement]).data(using: String.Encoding.utf8)
            
            if(dataToReturn != nil)
            {
                return dataToReturn!
            }
        }
    
    
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
    
    

    // MARK: read(from data: Data, ofType typeName: String)
    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override read(from:ofType:) instead.
        // If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
       // Swift.print(typeName)
        if(typeName == "com.noctivagous.floating-marker")
        {
            fileWasOpened = true
            // takes the data from the file
            // and tries to unarchive it
     
            do {
            
                //Swift.print(String.init(data: data, encoding: String.Encoding.utf8))
               
                self.loadedXMLDoc = try XMLDocument.init(data: data, options: XMLNode.Options.init())
            
                // -----------
                // The next step is that the windows will load
                // and windowControllerDidLoadNib() will be called.
                // It is here where fileWasOpened will be checked
                // and acted on accordingly.
                // setUpDocumentLoadedFromFile() will be called inside windowControllerDidLoadNib()
                // -----------
                
            } catch {

                
                throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
                
                
            }
            
            
            
        }
        else
        {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        
//
    }

    func loadDocumentFromData(data:Data)
    {
        
        
    
    }
    

    deinit {
        NotificationCenter.default.removeObserver(self)
        
    }
  

  
    
    // this is called when the DrawingDocument (subclass of NSDocument)
    // has its window controller load.  NSDocument has a window controller built-in
    override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
        
       // docFMWindow.allowsConcurrentViewDrawing = true;
        
        drawingScrollView.scrollerStyle = NSScroller.Style.legacy;
        drawingScrollView.contentView.postsBoundsChangedNotifications = true;
        
        NotificationCenter.default.addObserver(self, selector: #selector(boundsDidChange(notification:)), name: NSView.boundsDidChangeNotification, object: drawingScrollView.contentView)
    
        self.docFMWindow.delegate = self;
        
        drawingScrollView.addObserver(self, forKeyPath: "magnification", options: [.new,.old], context: nil)
       
        inputInteractionManager = (NSApp.delegate as? AppDelegate)?.inputInteractionManager
        lineWorkInteractionEntity = (NSApp.delegate as? AppDelegate)?.lineWorkInteractionEntity
        inkAndLineSettingsManager = (NSApp.delegate as? AppDelegate)?.inkAndLineSettingsManager
        
        
        
            
            
            if(self.fileWasOpened == false)
            {
                self.setUpBlankDocument()
            }
            else
            {
                
                self.setUpDocumentLoadedFromFile();
            }
            
            if(self.showSVGDebugWindow)
            {
                self.makeSVGWindowFullscreenOnSecondScreen()
            }
            
            
     
        
        
        
        
    }
    
    @objc func boundsDidChange( notification : Notification)
    {

        drawingPage.activePenLayer.adjustCurrentPointDuringScroll();
    }
  
  

// MARK: Begin nib obj
    @IBOutlet var drawingScrollView : NSScrollView!
// MARK: Accessory windows

    @IBOutlet var docFMWindow: FMWindow!;

    

    
    // MARK: DRAWING BOARD
	@IBOutlet var drawingBoard : DrawingBoard! // inherits from NSView.
							            // is the embedded documentView for NSScrollView
  						                // It holds the drawingPage (layers), surrounds it with
						                // horizontal and vertical margins.

    
// MARK: Managers instantiated in nib

/*
    @IBOutlet var inkAndLineSettingsManager : InkAndLineSettingsManager!
    @IBOutlet var inputInteractionManager : InputInteractionManager!
    @IBOutlet var lineWorkInteractionEntity : LineWorkInteractionEntity!
*/



    override  func awakeFromNib() {
             //   inputInteractionManager.currentInputDocument = self;

    }

    var drawingPage : DrawingPage
    {
        return drawingPageController!.drawingPage!
    }
    
    var activePenLayer : ActivePenLayer
    {
        return drawingPageController!.activePenLayer!
    }
    

// MARK: set up blank doc
    func setUpBlankDocument()
    {
      
        self.sharedSetupForNewAndOpenedDocs();
        
        drawingPageController!.setUpBlankDocument()
        drawingPageController!.setUpDrawingBoardForBlankDocument()
        
        drawingPageController!.centerPermanentAnchorPoint();
        
        drawingPageController!.loadCurrentAppSettingsIntoDrawing()
        
        drawingPageController!.updateLayersPanelTable();
    }
    
    func setUpDocumentLoadedFromFile()
    {
        self.sharedSetupForNewAndOpenedDocs();
        
        self.drawingPageController!.setUpDrawingBoardAndPageFromXML()
        // self.docFMWindow.setIsVisible(true)
        /*
         DispatchQueue.main.async
         {*/
        self.drawingPageController!.setUpLayersFromXML()
        
        self.drawingPageController!.drawingPage.updateDrawingLayersAndActivePenLayer()
        
        self.drawingPageController!.setUpDocumentLoadedFromFile()
        
        self.drawingPageController!.loadCurrentAppSettingsIntoDrawing()
        
        self.drawingPageController!.drawingBoard.needsDisplay = true;
        
        
        self.drawingPageController!.updateLayersPanelTable();
        // }
        /*
         DispatchQueue.main.async
         {
         
         
         }*/
        
        
    }
    
    func sharedSetupForNewAndOpenedDocs()
    {
        self.drawingPageController!.inputInteractionManager = inputInteractionManager;
        self.drawingPageController!.lineWorkInteractionEntity = lineWorkInteractionEntity;
        self.drawingPageController!.inkAndLineSettingsManager = inkAndLineSettingsManager;
    }
    

  

    
    var inputInteractionManager : InputInteractionManager?
    var lineWorkInteractionEntity: LineWorkInteractionEntity?
    var inkAndLineSettingsManager: InkAndLineSettingsManager?

    // MARK: --- Menu Actions
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        guard let action = menuItem.action else {
            fatalError("Unexpected MenuItem configuration")
        }
        
        switch action {
        case #selector(cut(_:)), #selector(copy(_:)),
        #selector(instantExportSelectedToDownloads(_:)),
        #selector(copySelectedObjects(_:)),
        #selector(exportUsingSelectedObjects(_:)):/*,
             #selector(exportUsingSelectedRectangleAsCrop(_:)),
             #selector(exportSelectedDrawablesPopover(_:)):
             */
            
            return self.drawingPage.currentPaperLayer.hasSelectedDrawables
        
        
        default:
            return true
        }
    }
    
    
    // MARK: COPYING AND PASTING
    
        
    @IBAction func cut(_ sender: AnyObject?) {
        
        if(self.drawingPage.currentPaperLayer.hasSelectedDrawables)
        {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects(self.drawingPage.currentPaperLayer.selectedDrawables)
            
            self.drawingPage.currentPaperLayer.cutOperationForSelectedDrawables()
            
        }
        
    }
    
    @IBAction func copy(_ sender: AnyObject?) {
        if(self.drawingPage.currentPaperLayer.hasSelectedDrawables)
        {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects(self.drawingPage.currentPaperLayer.selectedDrawables)
        

            let epsData = self.drawingPage.currentPaperLayer.imageDataFromSelectedDrawables(type: "eps", croppingRectangle: nil, includeBackground:false)
            pasteboard.setData(epsData, forType: NSPasteboard.PasteboardType(rawValue: "com.adobe.encapsulated-postscript"))
            
            let pdfData = self.drawingPage.currentPaperLayer.imageDataFromSelectedDrawables(type: "pdf", croppingRectangle: nil, includeBackground:false)
            let pdfImg = NSImage(data: pdfData)
            pdfImg?.addRepresentation(NSBitmapImageRep(data: (pdfImg?.tiffRepresentation)!)!);
            //Swift.print(pdfImg!.representations)
            
            //let svgData =
            // "public.svg-image"
            
            pasteboard.setData((pdfImg?.representations[0] as! NSPDFImageRep).pdfRepresentation, forType: NSPasteboard.PasteboardType.pdf)
            
            let imageOfView : NSImage? = NSImage(data: pdfData)
            
            let tiffRepresentation = imageOfView?.tiffRepresentation(using: NSBitmapImageRep.TIFFCompression.none, factor: 0)
            
            if(tiffRepresentation != nil)
            {
                pasteboard.setData(tiffRepresentation, forType: NSPasteboard.PasteboardType.tiff)
            }
            
        }
        
        
    }
    
    @IBAction func paste(_ sender: AnyObject?) {
        let pasteboard = NSPasteboard.general
        
        self.depositFromPasteboard(pasteboard: pasteboard)
        
    }
    
    
     func depositFromPasteboard(pasteboard:NSPasteboard)
    {
        let objectClassesForReading : [AnyClass] = [FMDrawable.self, FMStroke.self,
                                  FMImageDrawable.self, FMShapeKeyDrawable.self,]
        



        if let pasteboardTypeThatIsAvailable : NSPasteboard.PasteboardType = pasteboard.availableType(from: appDelegate!.supportedFileTypesForPasteboard)
        {
            Swift.print("pasteboardTypeThatIsAvailable : \(pasteboardTypeThatIsAvailable)")
            
            
            
            let pointForPaste = drawingPage.currentPaperLayer.mousePointInLayerOutsideOfEventStream()

            let currentPaperLayer = drawingPage.currentPaperLayer


            // or self.drawingPage.currentPaperLayer.middleOfDocumentRect
            
            // MARK: PASTING FMDRAWABLES
            if(pasteboard.canReadObject(forClasses: objectClassesForReading, options: nil))
            {
            
                
                if let arrayOfPasteboardDrawables = pasteboard.readObjects(forClasses: objectClassesForReading, options: nil)
                {
                    
                    
                    arrayOfPasteboardDrawables.forEach { (Any) in
                        
                    }
                    
                    if(arrayOfPasteboardDrawables.isEmpty == false)
                    {
                        //Swift.print("arrayOfPasteboardDrawables.isEmpty == false \(arrayOfPasteboardDrawables)")
                       
                            do{
                                try currentPaperLayer.addDrawablesForPaste(drawablesArray: arrayOfPasteboardDrawables as! [FMDrawable])
                            }
                            catch{
                            
                            }
                    
                    }
                        
                    else
                    {
                        Swift.print("readObjects for drawable classes \(arrayOfPasteboardDrawables)")
                        
                    }
                    
                    
                }
            }
            // MARK: PASTING TIFF
            else if(pasteboardTypeThatIsAvailable == NSPasteboard.PasteboardType.tiff)
            {
                let tiffData = pasteboard.data(forType: pasteboardTypeThatIsAvailable)
                
                let imageDrawable = FMImageDrawable(data: tiffData!, atPoint:pointForPaste)
                
                do {
                    try currentPaperLayer.addDrawablesForPaste(drawablesArray:[imageDrawable])
                } catch  {
                    Swift.print(error);
                }
                
                
                
                // Image
            }
             
         }
    }

    // MARK: -
    // MARK: EXPORT FUNCTIONS AND IBACTIONS
    
    @IBOutlet var exportPopover : NSPopover!;
    
    @IBOutlet var exportSavePanelAccessoryView : NSView!
    @IBOutlet var exportSavePanelDPIContainingView : NSView!
    @IBOutlet var exportSavePanelDPITextField : NSTextField!
    @IBOutlet var exportSavePanelFileTypePopUpButton : NSPopUpButton!
    @IBOutlet var exportSavePanelLZWCompressionCheckbox : NSButton!
    @IBOutlet var exportSavePanelJPEGControlsContainer : NSView!
    @IBOutlet var exportSavePanelJPEGProgressiveCheckbox : NSButton!
    @IBOutlet var exportSavePanelJPEGSlider : NSSlider!
    @IBOutlet var exportSavePanelIncludeBackgroundColorCheckbox : NSButton!
    
    
     


/*

   @IBAction func exportSelectedDrawablesPopover(_ sender: AnyObject?)
    {
        if(layersManager.currentDrawingLayerHasSelectedDrawables)
        {
            if let instantExportPopoverView = exportPopover.contentViewController?.view as? InstantExportPopoverView
            {
                
                let totalSelectionRect = layersManager.currentDrawingLayer.selectionTotalRegionRectStandardBounds();
                
                self.exportPopover.close()
            
                let convRect =  layersManager.currentDrawingLayer.convert(totalSelectionRect, to: layersManager.currentDrawingLayer.window!.contentView!)
                
                NotificationCenter.default.post(name: Notification.Name.init("NCTCloseAnyPopovers"), object: self)
                self.exportPopover.show(relativeTo: convRect, of: layersManager.currentDrawingLayer.window!.contentView!, preferredEdge: NSRectEdge.maxY)
                NotificationCenter.default.post(name: Notification.Name.init("NCTCurrentlyShownPopover"), object: self.exportPopover)
                
                instantExportPopoverView.loadSelectedFromLayer(layersManager.currentDrawingLayer);
                
            }
            
        }
    }
    
    @IBAction func exportUsingSelectedRectangleAsCrop(_ sender: AnyObject?)
    {
        // if there are multiple rectangles selected (multiple drawables in
        // the selected array), multiple files will be exported.
        
        // For each rectangle, it will use the bounds, regardless of whether the drawable
        // is a rectangle.
        
        // drawingLayer find all objects that sit inside or overlap frame
        // drawingManager.currentDrawingLayer.selectedObjectsInsideFrame(rect:firstSelectObject.bounds);
    }
    */
    
    @IBAction func exportUsingEntireCanvas(_ sender: AnyObject?)
     {
        self.exportImageFromFMDocument(isSelectedDrawablesOnCurrentLayer: false, croppingRectangle: nil,fileNameSuffix:"_entireCanvas");

     }

     @IBAction func exportUsingExportFrame(_ sender: AnyObject?)
     {
         self.exportImageFromFMDocument(isSelectedDrawablesOnCurrentLayer: false, croppingRectangle: drawingPageController!.exportFrame,fileNameSuffix:"_exportFrame");
     }

  
    var includeBackgroundForInstantExport : Bool
    {
        get
        {
            return appDelegate?.instantExportIncludeBackgroundCheckbox?.boolFromState ?? false;
        }
    }

    var fileTypeForInstantExport : String
    {
        get
        {
            return appDelegate?.instantExportFormat ?? "PDF"
        }
    }

    var isSandboxedApp : Bool = true;
     
     
    @IBAction func instantExportFrameToDownloads(_ sender: AnyObject?)
     {
        
        
        let fileManager = FileManager.default
        
        var desktopURL:URL!
        if(isSandboxedApp)
        {
            // https://stackoverflow.com/questions/9553390/how-do-i-get-the-users-home-directory-in-a-sandboxed-app
            let pw = getpwuid(getuid())
            let home = pw?.pointee.pw_dir
            let homePath = FileManager.default.string(withFileSystemRepresentation: home!, length: Int(strlen(home!)))
            let sandboxedDesktopURL = homePath + "/Downloads/"
            desktopURL = URL.init(fileURLWithPath: sandboxedDesktopURL)
        }
        else
        {
            desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first
        }

        
    
        if desktopURL != nil
        {
        
            let suffix = "_instantExportFrame"
            let formatter = DateFormatter()
        formatter.dateFormat = "_yyyy-MMMdd_h-mma-ss"
            let dateString = formatter.string(from: Date())
            let fileNameForInstantExportWithoutFileExtension = "\(self.displayName!)\(suffix)" + dateString
            
            var fileURL = desktopURL.appendingPathComponent(fileNameForInstantExportWithoutFileExtension)
            
            let fileExtension = self.exportSavePanelFileTypePopUpButton.selectedItem!.title;
            fileURL.appendPathExtension("\(fileExtension.lowercased())")
            
            //Swift.print(fileURL.path)
            
            saveToURLUsingSettings(url: fileURL, filetypeForExport: fileExtension, settingsDictionary: ["fileFormat": fileTypeForInstantExport], includesBackground: includeBackgroundForInstantExport, isSelectedDrawablesOnCurrentLayer: false, croppingRectangle: drawingPageController!.exportFrame)
            
            
        }
        
         return
     }

    @IBAction func instantExportCanvasToDownloads(_ sender: AnyObject?)
     {
        let fileManager = FileManager.default
        
        var desktopURL:URL!
        if(isSandboxedApp)
        {
            // https://stackoverflow.com/questions/9553390/how-do-i-get-the-users-home-directory-in-a-sandboxed-app
            let pw = getpwuid(getuid())
            let home = pw?.pointee.pw_dir
            let homePath = FileManager.default.string(withFileSystemRepresentation: home!, length: Int(strlen(home!)))
            let sandboxedDesktopURL = homePath + "/Downloads/"
            desktopURL = URL.init(fileURLWithPath: sandboxedDesktopURL)
        }
        else
        {
            desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first
        }

        
    
        if desktopURL != nil
        {
        
            let suffix = "_instantExportCanvas"
            let formatter = DateFormatter()
        formatter.dateFormat = "_yyyy-MMMdd_h-mma-ss"
            let dateString = formatter.string(from: Date())
            let fileNameForInstantExportWithoutFileExtension = "\(self.displayName!)\(suffix)" + dateString
            
            var fileURL = desktopURL.appendingPathComponent(fileNameForInstantExportWithoutFileExtension)
            
            let fileExtension = fileTypeForInstantExport;
            //self.exportSavePanelFileTypePopUpButton.selectedItem!.title;
            fileURL.appendPathExtension("\(fileExtension.lowercased())")
            
            Swift.print("instant export canvas: " + fileURL.path);
            
            saveToURLUsingSettings(url: fileURL, filetypeForExport: fileExtension, settingsDictionary: ["fileFormat":fileTypeForInstantExport], includesBackground: includeBackgroundForInstantExport, isSelectedDrawablesOnCurrentLayer: false, croppingRectangle: drawingPage.bounds)
            
            
        }
        
         return
     }

     @IBAction func instantExportSelectedToDownloads(_ sender: AnyObject?)
     {
     
        Swift.print("instantExportSelectedToDownloads");
     
        guard drawingPage.currentPaperLayer.hasSelectedDrawables else {
            return;
        }
     
        let fileManager = FileManager.default
        
        var desktopURL:URL!
        if(isSandboxedApp)
        {
            // https://stackoverflow.com/questions/9553390/how-do-i-get-the-users-home-directory-in-a-sandboxed-app
            let pw = getpwuid(getuid())
            let home = pw?.pointee.pw_dir
            let homePath = FileManager.default.string(withFileSystemRepresentation: home!, length: Int(strlen(home!)))
            let sandboxedDesktopURL = homePath + "/Downloads/"
            desktopURL = URL.init(fileURLWithPath: sandboxedDesktopURL)
        }
        else
        {
            desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first
        }

        
    
        if desktopURL != nil
        {
        
            let suffix = "_instantExport"
            let formatter = DateFormatter()
        formatter.dateFormat = "_yyyy-MMMdd_h-mma-ss"
            let dateString = formatter.string(from: Date())
            let fileNameForInstantExportWithoutFileExtension = "\(self.displayName!)\(suffix)" + dateString
            
            var fileURL = desktopURL.appendingPathComponent(fileNameForInstantExportWithoutFileExtension)
            
            let fileExtension = fileTypeForInstantExport;
            
            fileURL.appendPathExtension("\(fileExtension.lowercased())")

           // Swift.print(fileURL.path)
            
            
            Swift.print("instantExportSelectedToDownloads: " + fileURL.absoluteString);
            
            saveToURLUsingSettings(url: fileURL, filetypeForExport: fileExtension.lowercased(), settingsDictionary: ["fileFormat":fileTypeForInstantExport], includesBackground: includeBackgroundForInstantExport, isSelectedDrawablesOnCurrentLayer: true, croppingRectangle: drawingPageController!.exportFrame)
            
            
        }
        
         return
     }
    
    
    /*
    @IBAction func instantExportSettings(_ sender: AnyObject?)
    {
        let instantExportSettingsAlert = NSAlert.init()
        instantExportSettingsAlert.accessoryView = exportSavePanelAccessoryView;
        instantExportSettingsAlert.messageText = "Settings for Instant Export to Desktop.  These are the same as the \"Save File...\" window at any time."
        //instantExportSettingsAlert.runModal();
        instantExportSettingsAlert.beginSheetModal(for: self.windowControllers[0].window!, completionHandler: nil)
        
        
    
    
    }*/
     
     // MARK: Export using selected
    @IBAction func exportUsingSelectedObjects(_ sender: AnyObject?)
    {
        
        self.exportImageFromFMDocument(isSelectedDrawablesOnCurrentLayer: true, croppingRectangle: nil,fileNameSuffix:"_selection");
      
    }
    
    // MARK: SAVE TO URL
    func saveToURLUsingSettings(url:URL, filetypeForExport:String, settingsDictionary:Dictionary<String,Any>, includesBackground:Bool, isSelectedDrawablesOnCurrentLayer:Bool,croppingRectangle: NSRect?)
    {
        
        Swift.print("saveToURLUsingSettings:" + url.absoluteString + " " + filetypeForExport);
        
        //Swift.print(urlForSaving.path)
        //let fileFormat = settingsDictionary["fileFormat"]
    
        var pdfData : Data!

        let filetypeForExportLowercased = filetypeForExport.lowercased();

        if(filetypeForExportLowercased == "svg")
        {
            var svgData : Data!

            do {
                if(isSelectedDrawablesOnCurrentLayer)
                {
                    
                    svgData = self.drawingPage.currentPaperLayer.imageDataFromSelectedDrawables(type: "svg", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                else
                {
                    
                    svgData = self.drawingPage.imageDataFromCroppingRect(type: "svg", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                
                // urlForSaving.appendPathExtension("svg")
                
                try svgData.write(to: url)
                
            }
            catch
            {
                let alert = NSAlert()
                alert.messageText = "The SVG file could not be saved. NCTVGS. \(url.path)"
                alert.runModal()
            }
            
        }
        if(filetypeForExportLowercased == "pdf")
        {

            do {
                
                if(isSelectedDrawablesOnCurrentLayer)
                {
                    pdfData = self.drawingPage.currentPaperLayer.imageDataFromSelectedDrawables(type: "pdf", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                else
                {
                    pdfData = self.drawingPage.imageDataFromCroppingRect(type: "pdf", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                
                // urlForSaving.appendPathExtension("pdf")
                
                try pdfData.write(to: url)
                
            } catch  {
                let alert = NSAlert()
                
                alert.messageText = "The PDF file could not be saved. NCTVGS."
                alert.runModal()
            }
        }
        if(filetypeForExportLowercased == "eps")
        {
            do {
                var epsData : Data!
                
                if(isSelectedDrawablesOnCurrentLayer)
                {
                    epsData = self.drawingPage.currentPaperLayer.imageDataFromSelectedDrawables(type: "eps", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                else
                {
                    epsData = self.drawingPage.imageDataFromCroppingRect(type: "eps", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                
                
                // urlForSaving.appendPathExtension("eps")
                try epsData.write(to: url)
            } catch  {
                let alert = NSAlert()
                alert.messageText = "The EPS file could not be saved. NCTVGS."
                alert.runModal()
            }
        }
        else if(filetypeForExportLowercased == "tiff")
        {
            do {
                
                
                if(isSelectedDrawablesOnCurrentLayer)
                {
                    pdfData = self.drawingPage.currentPaperLayer.imageDataFromSelectedDrawables(type: "pdf", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                else
                {
                    pdfData = self.drawingPage.imageDataFromCroppingRect(type: "pdf", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                let pdfImageRep : NSPDFImageRep = NSPDFImageRep(data: pdfData)!
                let factor : CGFloat = CGFloat(self.exportSavePanelDPITextField.integerValue) / 72.0

                // urlForSaving.appendPathExtension("tiff")
                
                let sizeForScaledImage = pdfImageRep.size.applying(CGAffineTransform(scaleX: factor, y: factor))
                // dlet sizeForScaledImage = pdfImageRep.size
                let scaledImage : NSImage = NSImage(size: sizeForScaledImage, flipped: false,
                                                    drawingHandler: { (rectForDrawing) -> Bool in
                                                        
                                                        pdfImageRep.draw(in: rectForDrawing)
                                                        
                                                        
                                                        return true;
                                                    })
                
                if let bitmapRepresentation : NSBitmapImageRep = NSBitmapImageRep(data: scaledImage.tiffRepresentation!)
                {
                    bitmapRepresentation.size = pdfImageRep.size
                    bitmapRepresentation.pixelsHigh = Int(ceil(sizeForScaledImage.height))
                    bitmapRepresentation.pixelsWide = Int(ceil(sizeForScaledImage.width))
                    
                    
                    
                    
                    let tiffCompressionMethod : NSBitmapImageRep.TIFFCompression = self.exportSavePanelLZWCompressionCheckbox.integerValue > 1 ? NSBitmapImageRep.TIFFCompression.lzw :  NSBitmapImageRep.TIFFCompression.none;
                    
                    
                    if let tiffData = bitmapRepresentation.representation(using: NSBitmapImageRep.FileType.tiff, properties: [NSBitmapImageRep.PropertyKey.compressionMethod : tiffCompressionMethod ])
                    {
                        try tiffData.write(to: url)
                    }
                }
                
            } catch  {
                let alert = NSAlert()
                alert.messageText = "The TIFF file could not be saved. NCTVGS."
                alert.runModal()
            }
        }
        else if(filetypeForExportLowercased == "png")
        {
            do {
                
                
                if(isSelectedDrawablesOnCurrentLayer)
                {
                    pdfData = self.drawingPage.currentPaperLayer.imageDataFromSelectedDrawables(type: "pdf", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                else
                {
                    pdfData = self.drawingPage.imageDataFromCroppingRect(type: "pdf", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                let pdfImageRep : NSPDFImageRep = NSPDFImageRep(data: pdfData)!
                let factor : CGFloat = CGFloat(self.exportSavePanelDPITextField.integerValue) / 72.0

                // urlForSaving.appendPathExtension("png")
                
                let sizeForScaledImage = pdfImageRep.size.applying(CGAffineTransform(scaleX: factor, y: factor))
                // dlet sizeForScaledImage = pdfImageRep.size
                let scaledImage : NSImage = NSImage(size: sizeForScaledImage, flipped: false,
                                                    drawingHandler: { (rectForDrawing) -> Bool in
                                                        
                                                        pdfImageRep.draw(in: rectForDrawing)
                                                        
                                                        
                                                        return true;
                                                    })
                
                let bitmapRepresentation : NSBitmapImageRep = NSBitmapImageRep(data: scaledImage.tiffRepresentation!)!
                bitmapRepresentation.size = pdfImageRep.size
                bitmapRepresentation.pixelsHigh = Int(ceil(sizeForScaledImage.height))
                bitmapRepresentation.pixelsWide = Int(ceil(sizeForScaledImage.width))
                
                if let pngData = bitmapRepresentation.representation(using: NSBitmapImageRep.FileType.png, properties: [NSBitmapImageRep.PropertyKey.interlaced : NSNumber(booleanLiteral: false)])
                {
                    try pngData.write(to: url)
                }
                
            } catch
            {
                let alert = NSAlert()
                alert.messageText = "The PNG file could not be saved. NCTVGS."
                alert.runModal()
            }
        }
        else if((filetypeForExportLowercased == "jpeg") || (filetypeForExportLowercased == "jpg") )
        {
            do {
                
                
                if(isSelectedDrawablesOnCurrentLayer)
                {
                    pdfData = self.drawingPage.currentPaperLayer.imageDataFromSelectedDrawables(type: "pdf", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                else
                {
                    pdfData = self.drawingPage.imageDataFromCroppingRect(type: "pdf", croppingRectangle: croppingRectangle, includeBackground:includesBackground)
                }
                
                let pdfImageRep : NSPDFImageRep = NSPDFImageRep(data: pdfData)!
                let factor : CGFloat = CGFloat(self.exportSavePanelDPITextField.integerValue) / 72.0

                // urlForSaving.appendPathExtension("jpg")
                
                let sizeForScaledImage = pdfImageRep.size.applying(CGAffineTransform(scaleX: factor, y: factor))
                // dlet sizeForScaledImage = pdfImageRep.size
                let scaledImage : NSImage = NSImage(size: sizeForScaledImage, flipped: false,
                                                    drawingHandler: { (rectForDrawing) -> Bool in
                                                        
                                                        pdfImageRep.draw(in: rectForDrawing)
                                                        
                                                        
                                                        return true;
                                                    })
                
                let bitmapRepresentation : NSBitmapImageRep = NSBitmapImageRep(data: scaledImage.tiffRepresentation!)!
                bitmapRepresentation.size = pdfImageRep.size
                bitmapRepresentation.pixelsHigh = Int(ceil(sizeForScaledImage.height))
                bitmapRepresentation.pixelsWide = Int(ceil(sizeForScaledImage.width))
                
                let isProgressive : Bool = self.exportSavePanelJPEGProgressiveCheckbox.integerValue > 0 ? true : false;
                
                if let jpgData = bitmapRepresentation.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [ NSBitmapImageRep.PropertyKey.progressive : NSNumber(booleanLiteral: isProgressive),
                                                                                                                          NSBitmapImageRep.PropertyKey.compressionFactor :
                                                                                                                            NSNumber(value: self.exportSavePanelJPEGSlider.floatValue)])
                {
                    try jpgData.write(to: url)
                }
                
            } catch
            {
                let alert = NSAlert()
                alert.messageText = "The JPG file could not be saved. NCTVGS."
                alert.runModal()
            }
        }
        
    }
    
    func exportImageFromFMDocument(isSelectedDrawablesOnCurrentLayer:Bool, croppingRectangle: NSRect?,fileNameSuffix:String)
    {
        // run a sheet with a preview NSView of
        // selected drawables and textfields with
        // dimensions of the bounding box.
        // the sheet allows for resizing bounding box
        // to specific dimensions.  the "next" button
        // then loads the save window sheet with file format options.
        
        let savePanel = NSSavePanel();
        
        // CILanczosScaleTransform for CoreImage scaling
        
        // The relation between points and pixels is expressed by passing a NSSize (in points) to the initialiser and to explicitly set the
        // pixel dimensions for the representation.
        // https://stackoverflow.com/questions/23626526/how-to-convert-pdf-to-nsimage-and-change-the-dpi
        
        let suffix = fileNameSuffix //isSelectedDrawablesOnCurrentLayer ? "_selection" : "_entirecanvas"
        let formatter = DateFormatter()
        formatter.dateFormat = "_yyyy-MMMdd_h-mma-ss"
        let dateString = formatter.string(from: Date())
        savePanel.nameFieldStringValue = "\(self.displayName!)\(suffix)" + dateString
        
        savePanel.canCreateDirectories = true;
        
        //GRAPHITE GLIDER:
        self.changeFileType(self.exportSavePanelFileTypePopUpButton)
        //GRAPHITE GLIDER:
        savePanel.accessoryView = exportSavePanelAccessoryView;
      
        
      
        savePanel.beginSheetModal(for: self.windowControllers[0].window!) { (modalResponse) in
        
            if(modalResponse == NSApplication.ModalResponse.OK)
            {
            
                if(savePanel.url != nil)
                {
                    
                    let fileExtension = self.exportSavePanelFileTypePopUpButton.selectedItem!.title;
                    
                    var url = savePanel.url!
                    url.appendPathExtension("\(fileExtension.lowercased())")
                    
                    
                
                    self.saveToURLUsingSettings(url:url,filetypeForExport: fileExtension.lowercased(), settingsDictionary:["fileFormat": self.exportSavePanelFileTypePopUpButton.selectedItem!.title],includesBackground: self.exportSavePanelIncludeBackgroundColorCheckbox.boolFromState, isSelectedDrawablesOnCurrentLayer: isSelectedDrawablesOnCurrentLayer, croppingRectangle: croppingRectangle)
                }
                
                
            }
            
        }
       
       
       
    }

    @IBAction func changeFileType(_ sender : NSPopUpButton)
    {
        if((sender.selectedItem?.title == "PDF") || (sender.selectedItem?.title == "EPS"))
        {
            exportSavePanelDPIContainingView.isHidden = true;
        }
        else
        {
            
            exportSavePanelDPIContainingView.isHidden = false;
        }
        
        if(sender.selectedItem?.title == "JPEG")
        {
            exportSavePanelJPEGControlsContainer.isHidden = false;
        }
        else
        {
            exportSavePanelJPEGControlsContainer.isHidden = true;
        }
        
        if(sender.selectedItem?.title == "TIFF")
        {
            exportSavePanelLZWCompressionCheckbox.isHidden = false;
        }
        else
        {
            exportSavePanelLZWCompressionCheckbox.isHidden = true;
        }
        
        if(sender.selectedItem?.title == "SVG")
        {
            
        }
        
    }
    

    @IBAction func copyExportFrame(_ sender: AnyObject?)
    {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let includeBackground = appDelegate?.documentCopyIncludeBackgroundCheckbox?.boolFromState ?? false
        
        
        if(appDelegate!.currentDocumentCopyFormat == "PDF")
        {
            
            let pdfData = self.drawingPage.imageDataFromCroppingRect(type: "pdf", croppingRectangle: drawingPageController!.exportFrame, includeBackground:includeBackground)
            let pdfImg = NSImage(data: pdfData)
            pasteboard.setData((pdfImg?.representations[0] as! NSPDFImageRep).pdfRepresentation, forType: NSPasteboard.PasteboardType.pdf)
        }
        else if(appDelegate!.currentDocumentCopyFormat == "SVG")
        {
            let svgData = self.drawingPage.imageDataFromCroppingRect(type: "svg", croppingRectangle: drawingPageController!.exportFrame, includeBackground:includeBackground)
            pasteboard.setData(svgData, forType: NSPasteboard.PasteboardType.init("public.svg-image"))
            pasteboard.setData(svgData, forType: NSPasteboard.PasteboardType.string)
        }
        else if(appDelegate!.currentDocumentCopyFormat == "TIFF")
        {
            
            let pdfData = self.drawingPage.imageDataFromCroppingRect(type: "pdf", croppingRectangle: drawingPageController!.exportFrame, includeBackground:includeBackground)
            let tiffImg : NSImage? = NSImage(data: pdfData)
            
            let tiffRepresentation = tiffImg?.tiffRepresentation(using: NSBitmapImageRep.TIFFCompression.none, factor: 0)
            
            if(tiffRepresentation != nil)
            {
                pasteboard.setData(tiffRepresentation, forType: NSPasteboard.PasteboardType.tiff)
            }
        }
    }
    
    @IBAction func copySelectedObjects(_ sender: AnyObject?)
    {
        
        guard self.drawingPage.currentPaperLayer.hasSelectedDrawables else {
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let includeBackground = appDelegate?.documentCopyIncludeBackgroundCheckbox?.boolFromState ?? false
        
        
        if(appDelegate!.currentDocumentCopyFormat == "PDF")
        {
            let pdfData = self.drawingPage.currentPaperLayer.imageDataFromSelectedDrawables(type: "pdf", croppingRectangle: nil, includeBackground:includeBackground)
            let pdfImg = NSImage(data: pdfData)
            pasteboard.setData((pdfImg?.representations[0] as! NSPDFImageRep).pdfRepresentation, forType: NSPasteboard.PasteboardType.pdf)
        }
        else if(appDelegate!.currentDocumentCopyFormat == "SVG")
        {
            let svgData = self.drawingPage.currentPaperLayer.imageDataFromSelectedDrawables(type: "svg", croppingRectangle: nil, includeBackground: includeBackground)
            pasteboard.setData(svgData, forType: NSPasteboard.PasteboardType.init("public.svg-image"))
            pasteboard.setData(svgData, forType: NSPasteboard.PasteboardType.string)
        }
        else if(appDelegate!.currentDocumentCopyFormat == "TIFF")
        {
            
            let pdfData = self.drawingPage.currentPaperLayer.imageDataFromSelectedDrawables(type: "pdf", croppingRectangle: nil, includeBackground:includeBackground)
            let tiffImg : NSImage? = NSImage(data: pdfData)
            
            let tiffRepresentation = tiffImg?.tiffRepresentation(using: NSBitmapImageRep.TIFFCompression.none, factor: 0)
            
            if(tiffRepresentation != nil)
            {
                pasteboard.setData(tiffRepresentation, forType: NSPasteboard.PasteboardType.tiff)
            }
        }
        
    }
    
    @IBAction func copyCanvas(_ sender: AnyObject?)
    {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let includeBackground = appDelegate?.documentCopyIncludeBackgroundCheckbox?.boolFromState ?? false
        
        if(appDelegate!.currentDocumentCopyFormat == "PDF")
        {
            
            let pdfData = self.drawingPage.imageDataFromCroppingRect(type: "pdf", croppingRectangle: drawingPage.bounds, includeBackground:includeBackground)
            let pdfImg = NSImage(data: pdfData)
            pasteboard.setData((pdfImg?.representations[0] as! NSPDFImageRep).pdfRepresentation, forType: NSPasteboard.PasteboardType.pdf)
        }
        else if(appDelegate!.currentDocumentCopyFormat == "SVG")
        {
            let svgData = self.drawingPage.imageDataFromCroppingRect(type: "svg", croppingRectangle: drawingPage.bounds, includeBackground:includeBackground)
            pasteboard.setData(svgData, forType: NSPasteboard.PasteboardType.init("public.svg-image"))
            pasteboard.setData(svgData, forType: NSPasteboard.PasteboardType.string)
        }
        else if(appDelegate!.currentDocumentCopyFormat == "TIFF")
        {
            
            let pdfData = self.drawingPage.imageDataFromCroppingRect(type: "pdf", croppingRectangle: drawingPage.bounds, includeBackground:includeBackground)
            let tiffImg : NSImage? = NSImage(data: pdfData)
            
            let tiffRepresentation = tiffImg?.tiffRepresentation(using: NSBitmapImageRep.TIFFCompression.none, factor: 0)
            
            if(tiffRepresentation != nil)
            {
                pasteboard.setData(tiffRepresentation, forType: NSPasteboard.PasteboardType.tiff)
            }
        }
    }


    // MARK: -
    // MARK: ZOOM
 
    @IBAction func makeScrollViewActualSize(_ sender: Any)
    {
    
            self.drawingScrollView.magnification = 1.0;

    }
    
    // MARK: -
    // MARK: WINDOW DELEGATE METHODS
    var selfIsCurrentDocument : Bool = false
    {
        didSet
        {
        

            if(selfIsCurrentDocument == true)
            {
                inputInteractionManager?.currentInputDocument = self;
                
                if(appDelegate != nil)
                {
                    DispatchQueue.main.async {
                        self.appDelegate!.moveKeyboardPanelAndGridColorPickerPanelToFMDocumentWindow(fmDocument:self)
                        self.appDelegate!.updatePanelsAfterDocumentWindowDidBecomeKey(fmDocument: self)
                        
                        
                    }
                    
                    
                }
                
                DispatchQueue.main.async {
                    self.updateSelfToReflectPanelsWithDocumentSpecificSettings();
                }
            }
        }
    }
    
    func updateSelfToReflectPanelsWithDocumentSpecificSettings()
    {
        if(appDelegate != nil)
        {
            appDelegate?.inkAndLineSettingsManager.suspendMessageIndicator = true
            
            appDelegate?.inkAndLineSettingsManager.showGrid = drawingPage.showGrid
            appDelegate?.inkAndLineSettingsManager.gridSnapping = drawingPage.gridSnapping;
            appDelegate?.inkAndLineSettingsManager.gridSnappingType = drawingPage.gridSnappingType;
            appDelegate?.inkAndLineSettingsManager.gridSnappingEdgeLength = drawingPage.gridSnappingEdgeLength;
            appDelegate?.inkAndLineSettingsManager.gridColor = drawingPage.gridColor;
            appDelegate?.inkAndLineSettingsManager.backgroundColor = drawingPage.defaultBackgroundColor;
            
            appDelegate?.inkAndLineSettingsManager.suspendMessageIndicator = false;
        }
    }
    
    func windowWillClose(_ notification: Notification)
    {
        svgDebugWindow.close();
    }
    
    
    func windowDidBecomeMain(_ notification: Notification)
    {
        if(notification.object as? FMWindow == self.docFMWindow)
        {
            self.selfIsCurrentDocument = true;
        }
    }
    
    func windowDidResignMain(_ notification: Notification)
    {
        if(notification.object as? FMWindow == self.docFMWindow)
        {
            self.selfIsCurrentDocument = false;
        }
    }

    func windowDidBecomeKey(_ notification: Notification)
    {
    
     
    }
    
    func windowDidResignKey(_ notification: Notification)
    {
    
        if(appDelegate!.lineWorkInteractionEntity.lineWorkEntityMode != .idle)
        {
            appDelegate!.inputInteractionManager.endKeyPress()
        }
        
        if(drawingPage.currentPaperLayer.isCarting)
        {
            drawingPage.currentPaperLayer.cart();
        }

    }

    func windowDidEndLiveResize(_ notification: Notification) {
        if(notification.object as? FMWindow == self.docFMWindow)
        {
            
            appDelegate?.fmKeyboardPanel.positionToWindowAccordingToConfiguration();
            appDelegate?.fmPaintFillModeTrayPanel.positionToWindowAccordingToConfiguration();
            drawingPageController?.fmLayersPanel.positionToWindowAccordingToConfiguration()
            
        }
        
    }
    
    func windowDidResize(_ notification: Notification) {
        if(notification.object as? FMWindow == self.docFMWindow)
        {
            appDelegate?.fmKeyboardPanel.positionToWindowAccordingToConfiguration();
            appDelegate?.fmPaintFillModeTrayPanel.positionToWindowAccordingToConfiguration();
            drawingPageController?.fmLayersPanel.positionToWindowAccordingToConfiguration()
        }
    }
    

    // MARK: -
    // titlebar layerspanel button, firstResponder
    @IBAction func changeVisibilityForLayersPanel(_ sender: AnyObject?)
    {
        drawingPageController?.changeVisibilityForLayersPanel(!(drawingPageController!.fmLayersPanel.isVisible))
    }
    
    
    // MARK: -

    // MARK: NOTIFICATIONS OBSERVATION, for magnification
    
      override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let keyPathString = keyPath
        {
            if(keyPathString == "magnification")
            {
                DispatchQueue.main.async {
                    
                    if let oldVal = change?[NSKeyValueChangeKey.oldKey] as? CGFloat,
                       let newVal = change?[NSKeyValueChangeKey.newKey] as? CGFloat
                    {
                    
                       if(oldVal < newVal)
                       {
                         self.activePenLayer.redrawCursorBezierPath();
                         
                       }
                    }
                    
//                    Swift.print(self.drawingScrollView.magnification)

                    self.docFMWindow.magnificationComboBox?.floatValue = Float(self.drawingScrollView.magnification);
                    
                }
                
                
                DispatchQueue.main.async {
                    
                    self.activePenLayer.setupCursor();
                    self.activePenLayer.resetCursorRects();
                }
                
                
                
            }
        }
        
    }// END observeValue
    
    
    // MARK: SVG DEBUG WINDOW

    var showSVGDebugWindow : Bool = true;
    var updateSVGPreviewLiveIsOn : Bool = true;
    //var updateSVGTextViewLiveIsOn : Bool = true;
    
    var updateExportedSVGNSTextView : Bool = true;
    
    @IBOutlet var svgDebugWindow : NSWindow!
    
    func makeSVGWindowFullscreenOnSecondScreen()
    {
        if(NSScreen.screens.count > 1)
        {
            svgDebugWindow.setIsVisible(true)
            svgDebugWindow.setFrame(NSScreen.screens[1].frame, display: true);
            updateSVGPreviewLive();
        }
    }
    
    
    @IBOutlet var svgOutputNSTextView : NSTextView?
    @IBOutlet var svgOutputByteCountLabel : NSTextField?
    @IBOutlet var svgWebView : WKWebView?
    @IBOutlet var exportedSVGXMLNSTextView : NSTextView?
    @IBOutlet var exportedSVGWebView  : WKWebView?
    @IBAction func generateSVGForTextView(_ sender : NSControl)
    {
     updateSVGPreviewLive()
//       generateSVGPreview()

    }
    
    func updateSVGPreviewLive()
    {
        if(updateSVGPreviewLiveIsOn)
        {
            DispatchQueue.main.async {
                
                self.generateXMLDoc();
                
              
                 
                
                self.svgOutputNSTextView!.string = self.xmlDoc.xmlString(options: [XMLNode.Options.nodePrettyPrint, XMLNode.Options.nodeCompactEmptyElement] )
                self.svgWebView?.loadHTMLString(self.xmlDoc.xmlString, baseURL: nil)
             self.svgOutputByteCountLabel?.stringValue = String(Double(self.svgOutputNSTextView!.string.utf8.count) / 1024.0) + " K";
                
                
                if(self.updateExportedSVGNSTextView)
                {
                    
                    let exportedSVGXMLDoc = self.exportedSVGDoc(includeBackground: true)
                    self.exportedSVGXMLNSTextView!.string = exportedSVGXMLDoc.xmlString(options: [XMLNode.Options.nodePrettyPrint, XMLNode.Options.nodeCompactEmptyElement] )
                    self.exportedSVGWebView?.loadHTMLString(exportedSVGXMLDoc.xmlString, baseURL: nil)

                    self.svgOutputByteCountLabel!.stringValue = self.svgOutputByteCountLabel!.stringValue + " ---- " + String(Double(self.exportedSVGXMLNSTextView!.string.utf8.count) / 1024.0) + " K";
                    
                }
                
        
            }
        }
        
    }
    
    func generateSVGPreview()
    {
      generateXMLDoc();
        svgOutputNSTextView!.string = xmlDoc.xmlString(options: [XMLNode.Options.nodePrettyPrint, XMLNode.Options.nodeCompactEmptyElement])
        
        
        svgOutputByteCountLabel?.stringValue = String(Double(svgOutputNSTextView!.string.utf8.count) / 1024.0) + " K";
        
        svgWebView?.setFrameSize(drawingPageController!.canvasSizePxComputed)
        svgWebView?.loadHTMLString(xmlDoc.xmlString, baseURL: nil)
    }
    
    var xmlDoc : XMLDocument = XMLDocument.init();
    var loadedXMLDoc : XMLDocument?

    func exportedSVGDoc(includeBackground:Bool) -> XMLDocument
    {
        let rootSVGElement : XMLElement = XMLElement.init(name: "svg")

        rootSVGElement.addNamespace(XMLNode.namespace(withName: "", stringValue: "http://www.w3.org/2000/svg") as! XMLNode)
        rootSVGElement.addNamespace(XMLNode.namespace(withName: "svg", stringValue: "http://www.w3.org/2000/svg") as! XMLNode)
         rootSVGElement.addNamespace(XMLNode.namespace(withName: "xlink", stringValue: "http://www.w3.org/1999/xlink") as! XMLNode)
        
        
        let w = drawingPageController!.canvasWidthForCurrentUnits
        let h = drawingPageController!.canvasHeightForCurrentUnits
        let units = drawingPageController!.canvasUnitsString
         rootSVGElement.attributes = [
            XMLNode.attribute(withName: "width", stringValue: "\(w)\(units)") as! XMLNode,
            
            XMLNode.attribute(withName: "height", stringValue: "\(h)\(units)")  as! XMLNode,
            
            ]
        
        let svgDoc = XMLDocument.init(rootElement: rootSVGElement);
        svgDoc.version = "1.0"
        svgDoc.characterEncoding = "UTF-8"
        svgDoc.isStandalone = true;
        
             // MARK: -
        // MARK: SVG DOCUMENT
        
        if(includeBackground)
        {
        let bgColorStr = drawingPageController!.drawingPage.defaultBackgroundColor.xmlRGBAttributeStringContent()
        let bgFill = XMLElement.init(name: "rect")
        bgFill.setAttributesAs(["width":"100%","height":"100%","fill":bgColorStr])

        rootSVGElement.addChild(bgFill)
        }
        
        let drawingPageGNode = XMLElement.init(name: "g")

        for paperLayer in drawingPage.paperLayers
        {
           drawingPageGNode.addChild(paperLayer.xmlElement(includeFMKRTags:false))
        }
        
        rootSVGElement.addChild(drawingPageGNode)
        
        return svgDoc;
    }
    
    func exportCroppedSVG(includeBackground:Bool,croppingRectanglePx:NSRect, croppingRectangleWithUnits:NSRect,croppingRectangleUnits:String) -> XMLDocument?
    {
    
        let rootSVGElement = self.svgRootElement;
        
        
        rootSVGElement.attributes = [
            XMLNode.attribute(withName: "width", stringValue: "\(croppingRectangleWithUnits.size.width)\(croppingRectangleUnits)") as! XMLNode,
            
            XMLNode.attribute(withName: "height", stringValue: "\(croppingRectangleWithUnits.size.height)\(croppingRectangleUnits)")  as! XMLNode,
            
        ]
        
        Swift.print("exportCroppedSVG: " + rootSVGElement.description);
        
        let svgDoc = XMLDocument.init(rootElement: rootSVGElement);
        svgDoc.version = "1.0"
        svgDoc.characterEncoding = "UTF-8"
        svgDoc.isStandalone = true;
        
        if(includeBackground)
        {
            let bgColorStr = drawingPageController!.drawingPage.defaultBackgroundColor.xmlRGBAttributeStringContent()
            let bgFill = XMLElement.init(name: "rect")
            bgFill.setAttributesAs(["width":"100%","height":"100%","fill":bgColorStr])
            
            rootSVGElement.addChild(bgFill)
        }
       
        let drawingPageGNode = XMLElement.init(name: "g")
        
        for paperLayer in drawingPage.paperLayers
        {
            let gNode = paperLayer.svgGNodeForCrop(croppingRectanglePx: croppingRectanglePx)
            drawingPageGNode.addChild(gNode)
        }
        
        rootSVGElement.addChild(drawingPageGNode)
        
        return svgDoc;
       
    
    }
    
    func generateXMLDoc()
    {
        let rootSVGElement : XMLElement = XMLElement.init(name: "svg")

        rootSVGElement.addNamespace(XMLNode.namespace(withName: "", stringValue: "http://www.w3.org/2000/svg") as! XMLNode)
        rootSVGElement.addNamespace(XMLNode.namespace(withName: "svg", stringValue: "http://www.w3.org/2000/svg") as! XMLNode)
        
        rootSVGElement.addNamespace(XMLNode.namespace(withName: "fmkr", stringValue: "http://www.noctivagous.com/fmkr/") as! XMLNode)

        rootSVGElement.addNamespace(XMLNode.namespace(withName: "xlink", stringValue: "http://www.w3.org/1999/xlink") as! XMLNode)
        
        
        
        //let w = String( Int(drawingPage.frame.size.width) )
        //let h = String(Int(drawingPage.frame.size.height))
        let w = drawingPageController!.canvasWidthForCurrentUnits
        let h = drawingPageController!.canvasHeightForCurrentUnits
        let units = drawingPageController!.canvasUnitsString
         rootSVGElement.attributes = [
            XMLNode.attribute(withName: "width", stringValue: "\(w)\(units)") as! XMLNode,
            
            XMLNode.attribute(withName: "height", stringValue: "\(h)\(units)")  as! XMLNode
            ]
        
        // add  <rect id="fmkr:DrawingPage" width="100%" height="100%" fill="[fillcolor]"/>
        // for background color later.
        //rootSVGElement.addAttribute(XMLNode.attribute(withName: "fill", stringValue: self.drawingPage.defaultBackgroundColor.xmlRGBAttributeStringContent()) as! XMLNode)
        
       // rootSVGElement.addAttribute(XMLNode.attribute(withName: "viewPort", stringValue: "20,20") as! XMLNode)
        
        xmlDoc = XMLDocument.init(rootElement: rootSVGElement);
        xmlDoc.version = "1.0"
        xmlDoc.characterEncoding = "UTF-8"
        xmlDoc.isStandalone = true;
        
      // MARK:-
      // MARK: DOCUMENT DEFS
        let defsXMLElement = XMLElement.init(name: "defs")
        rootSVGElement.addChild(defsXMLElement)
        


        defsXMLElement.setAttributesAs(["fmkr:Defs":"DocumentInformation"])
        
        let fmkrAppInfoXMLElement = XMLElement.init(name: "fmkr:FloatingMarker")
        fmkrAppInfoXMLElement.setAttributesAs(["version" : "1.0"])
        defsXMLElement.addChild(fmkrAppInfoXMLElement)

        let drawingBoardXMLElement = XMLElement.init(name: "fmkr:DrawingBoardSettings")
        drawingBoardXMLElement.setAttributesAs(["margin": "\(drawingPageController!.drawingBoardMargin)"])
        defsXMLElement.addChild(drawingBoardXMLElement)
        
        let drawingPageXMLElement = drawingPage.drawingPageSettingsXMLElement()
        drawingBoardXMLElement.addChild(drawingPageXMLElement)
       
        let drawingPageGNode = XMLElement.init(name: "g")
        drawingPageGNode.addAttribute(XMLNode.attribute(withName: "fmkr:groupType", stringValue: "DrawingPage") as! XMLNode)
        drawingPageGNode.addAttribute(XMLNode.attribute(withName: "fmkr:currentPaperLayerIndex", stringValue: "\(drawingPage.currentPaperLayerIndex)") as! XMLNode);

        // MARK: -
        // MARK: SVG DOCUMENT
           let bgColorStr = drawingPageController!.drawingPage.defaultBackgroundColor.xmlRGBAttributeStringContent()
        let bgFill = XMLElement.init(name: "rect")
        bgFill.setAttributesAs(["width":"100%","height":"100%","fill":bgColorStr,"fmkr:RectType":"DrawingPageBackground"])

        rootSVGElement.addChild(bgFill)
                
        for paperLayer in drawingPage.paperLayers
        {
           drawingPageGNode.addChild(paperLayer.xmlElement(includeFMKRTags:true))
        }
        
        rootSVGElement.addChild(drawingPageGNode)

       // rootSVGElement.addChild(self.documentInfoXMLElement())
        
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
    /*
    func documentInfoXMLElement() -> XMLElement
    {
        let documentInfoXMLElement = XMLElement.init(name: "fmkr:DocumentInformation")
    
    
        return documentInfoXMLElement;
    }
    */
    

}

