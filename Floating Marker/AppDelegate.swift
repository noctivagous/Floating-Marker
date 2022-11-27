//
//  AppDelegate.swift
//  Floating Marker
//
//  Created by John Pratt on 1/10/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var appHasLaunched : Bool = false;
    
    
    @IBOutlet var windowMenu : NSMenu?

    // MARK: PANELS AND MANAGERS
    @IBOutlet var inkSettingsPanel : NSPanel!;
    @IBOutlet var drawingSettingsPanel : NSPanel!;
//    @IBOutlet var colorPalettePanel : NSPanel!
    @IBOutlet var inputInteractionManager : InputInteractionManager!;
    @IBOutlet var lineWorkInteractionEntity : LineWorkInteractionEntity!;
    @IBOutlet var inkAndLineSettingsManager : InkAndLineSettingsManager!;

    // MARK: --- FMDOCS
    
    var fmDocs : [FMDocument]
    {
        get{
            var arrayOfFMDocs : [FMDocument] = [];
            for doc in NSDocumentController.shared.documents
            {
                if let fmDoc = doc as? FMDocument
                {
                    arrayOfFMDocs.append(fmDoc)
                }
            }
        
            return arrayOfFMDocs;
        
        }
    }
    
    var currentFMDocument : FMDocument?
    {
        if let currentFMDocToReturn = NSDocumentController.shared.currentDocument as? FMDocument
        {
            return currentFMDocToReturn;
        }
        
        return nil;
    }
        
        
    
    

    // MARK: --- KEYBOARD PANEL
    @IBOutlet var fmKeyboardPanel : FMInteriorPanel!;
    @IBOutlet var fmPaintFillModeTrayPanel : FMPaintFillModeTrayPanel!;
    @IBOutlet var nctColorPickerGridView : NCTColorPickerGridView!;
    var showKeyboardPanelOnNewlyOpenedDocs : Bool = true;
    var firstDocHasBeenOpened : Bool = false;

   // @IBOutlet var externalKeyboardPanel: NSWindow!
  //  @IBOutlet var backgroundBoxForKeyboard : NSBox!
    
    /*
    @IBOutlet var capsLockKey : KeyboardButton!;
    @IBOutlet var shiftKeyLeft : KeyboardButton!;
    @IBOutlet var shiftKeyRight : KeyboardButton!;
    @IBOutlet var commandKeyLeft : KeyboardButton!;
    @IBOutlet var commandKeyRight : KeyboardButton!;
    @IBOutlet var optionKeyLeft : KeyboardButton!;
    @IBOutlet var optionKeyRight : KeyboardButton!;
    @IBOutlet var controlKey : KeyboardButton!;
    @IBOutlet var functionKey : KeyboardButton!;
    */
    @IBOutlet var keyboardPopover : NSPopover?
    @IBOutlet var keyboardPopoverButtonName : NSTextField!;
    @IBOutlet var keyboardPopoverButtonDescription : NSTextView!;
    @IBOutlet var keyboardPopoverButtonImageView : NSImageView!;
    
    var keyboardMappingDescriptions : Dictionary<String, AnyObject> = [:];
    var registeredButtonKeyCodesToButtonObjects : Dictionary<Int,KeyboardButton> = Dictionary()
   
   
    var flagsKeys : [KeyboardButton] = [];
    
    var flagKeyWasOn : Bool = false;
    
    
    @IBOutlet var representationModeTitlebarView : NSView?
    @IBOutlet var pushAndPullRelToPaletteTitlebarView : NSView?
    
    override func awakeFromNib()
    {
    
        baseFMKeyboardPanelSize = fmKeyboardPanel.frame.size;
    
        documentCopyFormatNCTSegmCont?.selectedSegment = 1;
        instantExportFormatNCTSegmCont?.selectedSegment = 1;
        
        if(representationModeTitlebarView != nil)
        {
            let representationModeTitlebarViewController = NSTitlebarAccessoryViewController.init()
            representationModeTitlebarView!.translatesAutoresizingMaskIntoConstraints = false
            representationModeTitlebarViewController.layoutAttribute = NSLayoutConstraint.Attribute.trailing
            
            
            representationModeTitlebarViewController.view = representationModeTitlebarView!
            inkSettingsPanel.addTitlebarAccessoryViewController(representationModeTitlebarViewController)
        }
        
        if(pushAndPullRelToPaletteTitlebarView != nil)
        {
            let pushAndPullRelToPaletteTitlebarViewController = NSTitlebarAccessoryViewController.init()
            pushAndPullRelToPaletteTitlebarView!.translatesAutoresizingMaskIntoConstraints = false
            pushAndPullRelToPaletteTitlebarViewController.layoutAttribute = NSLayoutConstraint.Attribute.leading
            
            
            pushAndPullRelToPaletteTitlebarViewController.view = pushAndPullRelToPaletteTitlebarView!
            inkSettingsPanel.addTitlebarAccessoryViewController(pushAndPullRelToPaletteTitlebarViewController)
        }
        
    
//        NotificationCenter.default.addObserver(self, selector:  #selector(receiveIdentificationInfoFromKeyboardButton),
//                                               name: NSNotification.Name(rawValue: "ButtonIdentificationNotification"), object: nil)
        
    }


    func makeMainFMDocumentTheKeyWindow()
    {
        if(currentFMDocument != nil)
        {
            currentFMDocument!.docFMWindow.makeKey();
        }
    }
    
    /*
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        return nil;
    }*/
    
    // MARK: ---  APPLICATION DELEGATE NOTIFICATIONS
    func applicationDidFinishLaunching(_ notification: Notification)
    {
    
        NSWindow.allowsAutomaticWindowTabbing = false
        
        // Prevents the panel from accepting undo and redo
        // keystrokes when they become key.  They are made key
        // automatically currently by the nct segmented controls.
        inkSettingsPanel.undoManager?.disableUndoRegistration()
        drawingSettingsPanel.undoManager?.disableUndoRegistration()
        fmKeyboardPanel.undoManager?.disableUndoRegistration()
        fmPaintFillModeTrayPanel.undoManager?.disableUndoRegistration()
        
        //fmAppDefaults.plist
        
        //UserDefaults.reg
        
        
        /*
        
        let timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { timer in
            
            print( self.windowMenu)
            
            if let m3 = self.windowMenu?.item(withTitle: "Move Window to Left Side of Screen")
            {
                self.windowMenu?.removeItem(m3)
            }
            
            if let m4 = self.windowMenu?.item(withTitle: "Move Window to Right Side of Screen")
            {
                self.windowMenu?.removeItem(m4)
                
                
            }
            
            if let m5 = self.windowMenu?.item(withTitle: "Tile Window to Left of Screen")
            {
                self.windowMenu?.removeItem(m5)
                
                
            }
            
            
        }
        */
        
    }
    func applicationWillFinishLaunching(_ notification: Notification) {

        UserDefaults.standard.set(false, forKey: "NSFullScreenMenuItemEverywhere")

        
        NSColorPanel.shared.showsAlpha = true;
        NSColorPanel.shared.appearance = NSAppearance(named: NSAppearance.Name.darkAqua);
        
        NSFontPanel.shared.appearance =  NSAppearance(named: NSAppearance.Name.darkAqua);
        
        setUpKeyboardButtons()
        
        keyboardPopover!.behavior = NSPopover.Behavior.transient
        keyboardPopover!.animates = false;

        
       // DispatchQueue.main.async
       // {
            self.inkAndLineSettingsManager.compileListOfPanelBoxes();
            self.loadKeyboardDescriptionsFromFile();
            
            guard let mainScreen = NSScreen.main else { return }

            if(mainScreen.frame.width < 1920)
            {
                self.arrangeApplicationPanels(percentage:1.0,limitToHD: true);
            }
            else if(mainScreen.frame.width >= 1920)
            {
                self.arrangeApplicationPanels(percentage:0.85,limitToHD: true);
            }
            
            
            
            self.appHasLaunched = true;
            
            
     //   }
                
        //inputInteractionManager.loadKeyboardMappingDescriptionsFromFile()

        
         /*
       Bundle.main.loadNibNamed("ExternalKeyboardView", owner: self, topLevelObjects: nil)
        
        
        externalKeyboardPanel.contentAspectRatio = NSMakeSize(externalKeyboardPanel.frame.size.width, externalKeyboardPanel.frame.size.height - externalKeyboardPanel.titlebarHeight);
      */
        // original implementation, 10-2-20
      // https://stackoverflow.com/questions/59590699/how-to-detect-caps-lock-status-on-macos-with-swift-without-a-window
//   NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: flagsChangedFromActiveLayer)
      
        
        /*
        // https://stackoverflow.com/questions/5993633/how-to-get-keyboard-state-in-objective-c-without-referring-to-nsevent
            CGEventFlags theFlags;
        theFlags = CGEventSourceFlagsState(kCGEventSourceStateHIDSystemState);
        if( kCGEventFlagMaskCommand & theFlags ){
            NSLog(@"Uh huh!");
        }
        */
        
        
        // https://stackoverflow.com/questions/5994656/how-to-tell-if-a-modifier-key-is-down-during-drop-on-dock
        // check if caps lock key is on:
        /*if(NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.capsLock))
        {
            capsLockKey.showButtonDown = true;
            capsLockKey.showButtonHighlighted = true;
            capsLockKey.needsDisplay = true;
            
        }
        */
        

      //  NotificationCenter.default.addObserver(self, selector: #selector(keyboardPanelDidResize(notification:)), name: NSWindow.didResizeNotification, object: externalKeyboardPanel);
        
        
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        
        // for first document
        // capture the mouse point
        // and set the current point of
        // the activePenLayer to that mouse point
        resetAppearanceOfAllKeys(nil)
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        
        // turn off any drawing
        // taking place in the front most document
        self.endAnyCartingOrLiveTransformations();
        
        resetAppearanceOfAllKeys(nil)

        
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        
 
    }

    func applicationWillTerminate(_ aNotification: Notification) {

        // save preferences
        // for InkSettingsManager
        // to UserDefaults

    }
   
    func endAnyCartingOrLiveTransformations()
    {
    
        if(lineWorkInteractionEntity.lineWorkEntityMode != .idle)
        {
            self.inputInteractionManager.endKeyPress()
            
        }
        
        guard let currentPaperLayer = lineWorkInteractionEntity.currentPaperLayer else { return }
        
        if(currentPaperLayer.isCarting)
        {
            currentPaperLayer.cart();
        }
        
    }
 
   
    func loadKeyboardDescriptionsFromFile()
    {
        
        
        var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
        // var plistData: [String: AnyObject] = [:] //Our data
        
        if let plistPath: String = Bundle.main.path(forResource: "keyboardMappingsDescriptions", ofType: "plist") //the path of the data
        {
            if let plistXML = FileManager.default.contents(atPath: plistPath)
            {
                do {//convert the data to a dictionary and handle errors.
                    
                    keyboardMappingDescriptions =
                        try (PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListFormat)
                                as? [String:AnyObject])!
                    
                    self.inputInteractionManager.keyboardMappingDescriptions = keyboardMappingDescriptions;
                    
                } catch {
                    print("Error reading plist: \(error), format: \(propertyListFormat)")
                }
            }
        }
        else
        {
            
            
        }
    }
    
    
    
    // MARK: SWITCHING FROM ONE DOCUMENT TO ANOTHER
    // Called from the document that had its window become key.
    // Certain properties that are not retrieved but instead
    // reflect the state of the document need to be updated.
    func updatePanelsAfterDocumentWindowDidBecomeKey(fmDocument : FMDocument)
    {
        inkAndLineSettingsManager.loadDocumentSpecificSettingsForCurrentDocument();
        
    }

  
   var baseFMKeyboardPanelSize : NSSize = NSMakeSize(300, 400);
   
        
    func changeVisibilityForFMKeyboardPanel(_ visible:Bool)
    {
        if(visible == false)
        {
            var pFrame = fmKeyboardPanel.frame

            pFrame.size.height = 10;
            fmKeyboardPanel.setFrame(pFrame, display: true, animate: true)
        
            fmKeyboardPanel.setIsVisible(visible)
        }
        else
        {
            fmKeyboardPanel.parent?.removeChildWindow(fmKeyboardPanel);
            currentFMDocument?.docFMWindow.addChildWindow(fmKeyboardPanel, ordered: NSWindow.OrderingMode.above)
            fmKeyboardPanel.positionToWindowAccordingToConfiguration();
            
            var pFrame = fmKeyboardPanel.frame
            var pFrame2 = pFrame;
             pFrame2.size.height = 10;
            fmKeyboardPanel.setFrame(pFrame2, display: false)
          
            pFrame.size.height = baseFMKeyboardPanelSize.height;
            fmKeyboardPanel.setFrame(pFrame, display: true, animate: true)
                        fmKeyboardPanel.setIsVisible(visible)

            
        }
    }
    
    func changeVisibilityForFMPaintFillModeTrayPanel(_ visible:Bool)
    {
        if(visible == false)
        {
            
            if let topLeftPt = fmPaintFillModeTrayPanel.parent?.frame.topLeft()
            {
                var collapsedFrame = fmPaintFillModeTrayPanel.frame
                collapsedFrame.size.height = 10;
                collapsedFrame.origin.y = topLeftPt.y - 40;
                fmPaintFillModeTrayPanel.setFrame(collapsedFrame, display: true, animate: true)
            }
            
            fmPaintFillModeTrayPanel.setIsVisible(false)
        }
        else
        {
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
            
           fmPaintFillModeTrayPanel.setFrame(fFrame, display: true)
            var s = nctColorPickerGridView.frame.size;
           s.height =  nctColorPickerGridView.opacitySlider!.frame.size.height;
           nctColorPickerGridView.setFrameSize(s)
          
          
           /*var s2 = nctColorPickerGridView.opacitySlider!.frame.size
           s2.height -= 10;
           nctColorPickerGridView.opacitySlider!.setFrameSize(s2)
           */
        }
    
    
        for doc in fmDocs
        {
            // label:KEEPDOC_AND_APPSYNCed
            doc.drawingPageController?.paintFillModeTrayBox.fillColor = visible ? .lightGray : .clear;
            
        }
                
    }
    
   

    func moveKeyboardPanelAndGridColorPickerPanelToFMDocumentWindow(fmDocument:FMDocument)
    {
        // FMKEYBOARDPANEL
        var visibility = fmKeyboardPanel.isVisible;
        
        if((firstDocHasBeenOpened == false) && showKeyboardPanelOnNewlyOpenedDocs)
        {
            firstDocHasBeenOpened = true;
            visibility = true;
        }
        
        // FMKEYBOARDPANEL
        fmKeyboardPanel.parent?.removeChildWindow(fmKeyboardPanel);
        fmDocument.docFMWindow.addChildWindow(fmKeyboardPanel, ordered: NSWindow.OrderingMode.above)
        fmKeyboardPanel.positionToWindowAccordingToConfiguration();
        fmKeyboardPanel.setIsVisible(visibility)


        // FMGRIDCOLORPICKERPANEL
        let visibility2 = fmPaintFillModeTrayPanel.isVisible;
        
        fmPaintFillModeTrayPanel.parent?.removeChildWindow(fmPaintFillModeTrayPanel);
        fmDocument.docFMWindow.addChildWindow(fmPaintFillModeTrayPanel, ordered: NSWindow.OrderingMode.above)
        fmPaintFillModeTrayPanel.positionToWindowAccordingToConfiguration();
        fmPaintFillModeTrayPanel.setIsVisible(visibility2)
        

        
    }

    // MARK: SETUP OF APPLICATION
    
    var newDocumentWidth : CGFloat = 500.0;
    let windowPadding : CGFloat = 5.0;

    func arrangeApplicationPanels(percentage:CGFloat, limitToHD:Bool)
    {
        // ---------------
        // When fmWindowVisibleForFirstTime()
        // is called inside FMDocument, this is
        // when the document is sized.
        // ---------------
        guard let mainScreen = NSScreen.main else { return }
       
        // ----
        // Establish maxAppFrameSize, and this is for
        // the frame of the inkSettingsPanel, the documents,
        // and the drawing settings panel.
        // maxAppFrameSize accommodates the CoV of the person
        // instead of the default width of the screen.
        // ----
        
        var visibleFrameWidth = mainScreen.visibleFrame.width;
        
        // prevents overly wide window setup on ultra-wide monitors
        if(limitToHD && (visibleFrameWidth > 1920))
        {
            visibleFrameWidth = 1920;
        }
        
        let maxAppFrameSize : NSSize = NSMakeSize(percentage * visibleFrameWidth - windowPadding, mainScreen.visibleFrame.height);
        

        inkSettingsPanel.setWidthOfWindow(maxAppFrameSize.width - windowPadding)
       
        inkSettingsPanel.positionAtTopLeftOfScreen(xPadding: windowPadding, yPadding: windowPadding);
       

        drawingSettingsPanel.setHeightOfWindow(maxAppFrameSize.height - inkSettingsPanel.frame.height - (20))
        drawingSettingsPanel.setFrameTopLeftPoint(NSMakePoint(inkSettingsPanel.frame.maxX - drawingSettingsPanel.frame.width, inkSettingsPanel.frame.origin.y - windowPadding))

        newDocumentWidth = inkSettingsPanel.frame.width - drawingSettingsPanel.frame.width - windowPadding;

    }
    
    @IBAction func orderAllWindowsToMaxScreen(_ sender: NSMenuItem)
    {
        self.orderAllWindowsToPercentage(percentage: 1.0,limitToHD:false);
    }
    
    @IBAction func orderAllWindowsToEightFivePercentOfScreen(_ sender: NSMenuItem)
    {
        self.orderAllWindowsToPercentage(percentage: 0.85,limitToHD:false);
    }
    
    func orderAllWindowsToPercentage(percentage: CGFloat, limitToHD:Bool)
    {
        inkSettingsPanel.setIsVisible(true)
        drawingSettingsPanel.setIsVisible(true)
        self.arrangeApplicationPanels(percentage: percentage,limitToHD:limitToHD);
        
        reorderFMDocumentWindowLocations()
    
    }
    
    func reorderFMDocumentWindowLocations()
    {
        var counter : CGFloat = 0;
        for doc in NSDocumentController.shared.documents
        {
            if let fmDoc = doc as? FMDocument
            {
                fmDoc.docFMWindow.setIsVisible(true)
                fmDoc.docFMWindow.setWidthOfWindow(newDocumentWidth)
                fmDoc.docFMWindow.setFrameTopLeftPoint(NSMakePoint( windowPadding + (counter * 2), inkSettingsPanel.frame.minY - (counter * 5) - windowPadding ))
                counter += 1.0;
            }
            
        }
    }
    
    @IBAction func showInkSettingsPanel(_ sender : NSMenuItem)
    {
        inkSettingsPanel.toggleVisibility()
    }
    
    @IBAction func showLineKeySettingsPanel(_ sender : NSMenuItem)
    {
        drawingSettingsPanel.toggleVisibility()
    }
    
/*
 @IBAction func showColorPalettePanel(_ sender : NSMenuItem)
    {
        colorPalettePanel.toggleVisibility()
    }
  */
  
    func repositionAccessoryPanelsForFMDocumentWindow(_ window : NSWindow)
    {
    
    }

// MARK: --- DOCUMENT COPY FORMAT SETTING
    // Selected segment is set up in awakeFromNib:
    @IBOutlet var documentCopyIncludeBackgroundCheckbox : NSButton?
    @IBOutlet var documentCopyFormatNCTSegmCont : NCTSegmentedControl?
    
    var documentCopyIncludeBackground : Bool = true
    {
        didSet
        {
            documentCopyIncludeBackgroundCheckbox?.state = documentCopyIncludeBackground.stateValue
        }
    }

    @IBAction func changeDocumentCopyIncludeBackground(_ sender : NSButton)
    {
        documentCopyIncludeBackground = sender.boolFromState
    }
    
    
    var currentDocumentCopyFormat : String = "SVG"
    {
        didSet
        {
                
        }
    }

    
    @IBAction func changeDocumentPasteboardCopyingFormat(_ sender : NCTSegmentedControl)
    {
        let s = sender.currentSegmentLabelString
        if (s != "")
        {
            currentDocumentCopyFormat = s;
        }
        else
        {
            currentDocumentCopyFormat = "PDF"
            sender.selectedSegment = 0;
        }
        
    }

// MARK: --- INSTANT EXPORT FORMAT SETTING
    // Selected segment is set up in awakeFromNib:
    @IBOutlet var instantExportIncludeBackgroundCheckbox : NSButton?

    var instantExportIncludeBackground : Bool = true
    {
        didSet
        {
            instantExportIncludeBackgroundCheckbox?.state = instantExportIncludeBackground.stateValue;
        }
    }
    
    @IBAction func changeInstantExportIncludeBackground(_ sender : NSButton)
    {
        instantExportIncludeBackground = sender.boolFromState
    }


    @IBOutlet var instantExportFormatNCTSegmCont : NCTSegmentedControl?
    var instantExportFormat : String = "SVG"

    @IBAction func changeInstantExportFormat(_ sender : NCTSegmentedControl)
    {
        let s = sender.currentSegmentLabelString
        if (s != "")
        {
            instantExportFormat = s;
        }
        else
        {
            instantExportFormat = "PDF"
            sender.selectedSegment = 0;
        }
        
    }



// MARK: --- KEYBOARD PANEL
   
//    @objc func receiveIdentificationInfoFromKeyboardButton (note : NSNotification)
//    {
    func setUpKeyboardButtons()
    {
        for view in fmKeyboardPanel.contentView!.subviews
        {

            if let keyboardButtonObj : KeyboardButton = view as? KeyboardButton
            {
                keyboardButtonObj.appDelegate = self
                
                // if(keyboardButtonObj.buttonName.isEmpty == false)
                // {
                //   print(keyboardButtonObj.buttonName)
                // }
                if(keyboardButtonObj.keyCode != -1)
                {
                    registeredButtonKeyCodesToButtonObjects[keyboardButtonObj.keyCode] = keyboardButtonObj;
                }
                
            }
            
        }
        
        resetAppearanceOfAllKeys(nil)
        
    
    }
    
    
   
    
    var currentKeyboardPopoverKeyCode : Int = -1;
   
    func showPopoverForKeyboardButton(keyboardButton : KeyboardButton)
    {
        if(keyboardPopover == nil)
        {
            return;
        }
    
        keyboardPopover!.close();
        if(keyboardButton.usesPopover)
        {
            // keyboardPopoverButtonName.stringValue = keyboardButton
            
            let keyCodeString = String(keyboardButton.currentFlagsAndKeyCode);
            
            
            if let dict : Dictionary<String, AnyObject> = keyboardMappingDescriptions[keyCodeString] as? Dictionary
            {
                self.loadDictionaryIntoKeyboardButtonPopover(dict: dict,keyboardButton:keyboardButton)
            
            }// END if let dict : Dictionary<String, String> = keyboardMappingDescriptions[keyCodeString] as? Dictionary
            else
            {
            
                // Load the keyboard info without modifier keys
                if let dict : Dictionary<String, AnyObject> = keyboardMappingDescriptions[String(keyboardButton.keyCode)] as? Dictionary
                {
                    self.loadDictionaryIntoKeyboardButtonPopover(dict: dict,keyboardButton:keyboardButton)

                }
                else
                {
                    // If here is no dictionary, but a key is present
                    // this is the default information filled in.
                    keyboardPopoverButtonName.stringValue = "Key: \(self.lastFlagsStringConverted)\(keyboardButton.buttonName)";
                    keyboardPopoverButtonName.textColor = NSColor.white;
                    keyboardPopoverButtonName.backgroundColor! = NSColor.darkGray;
                    keyboardPopoverButtonName.drawsBackground = true;
                    keyboardPopoverButtonDescription.string = "Description not yet included for \(self.lastFlagsStringConverted)\(keyboardButton.buttonName)."
                }
            }
            
            
            NotificationCenter.default.post(name: Notification.Name.init("NCTCloseAnyPopovers"), object: self)
            keyboardPopover?.show(relativeTo: keyboardButton.frame, of: keyboardButton.window!.contentView!, preferredEdge: NSRectEdge.maxY);
            
            NotificationCenter.default.post(name: Notification.Name.init("NCTCurrentlyShownPopover"), object: keyboardPopover)
            
        }// END if(keyboardButton.usesPopover)
    } // END func showPopover...
    
    
    func loadDictionaryIntoKeyboardButtonPopover(dict: Dictionary<String, AnyObject>, keyboardButton: KeyboardButton)
    {
        
        
        if let name = dict["name"] as? String
        {
            currentKeyboardPopoverKeyCode = keyboardButton.keyCode
            
            keyboardPopoverButtonName.stringValue = name;
            keyboardPopoverButtonName.textColor = keyboardButton.fontForegroundColor;
            keyboardPopoverButtonName.backgroundColor! = keyboardButton.buttonBackgroundColor;
            keyboardPopoverButtonName.drawsBackground = true;
            //keyboardPopoverButtonName.needsDisplay = true;
        }
        else
        {
            
            keyboardPopoverButtonName.stringValue = "Key: \(self.lastFlagsStringConverted)\(keyboardButton.buttonName)";
            keyboardPopoverButtonName.textColor = NSColor.white;
            keyboardPopoverButtonName.backgroundColor! = NSColor.darkGray;
            keyboardPopoverButtonName.drawsBackground = true;
        }
        
        if let description = dict["description"] as? String
        {
            keyboardPopoverButtonDescription.string = description
        }
        else
        {
            
            keyboardPopoverButtonDescription.string = "Description not yet included for \(self.lastFlagsStringConverted)\(keyboardButton.buttonName)."
            
            /*
             if dict["functionString"] != nil
             {
             if(inputInteractionManager.selectorFromKeyEventString(lastFlagsString.appending(String(keyboardButton.keyCode))) != nil)
             {
             
             }
             else
             {
             
             }
             }*/
            
        }
        
        if let buttonBackgroundImageString = dict["buttonBackgroundImage"] as? String
        {
            if let buttonBackgroundImage = NSImage.init(named: buttonBackgroundImageString)
            {
                keyboardPopoverButtonImageView.image = buttonBackgroundImage
                
            }
            else
            {
                keyboardPopoverButtonImageView.image = nil;
                
            }
            
            
            
        }
        else
        {
            keyboardPopoverButtonImageView.image = nil;
            
        }
        
    
    }
    
 
    
    var lastFlagsString : String = "";
    
    
    var lastFlagsStringConverted : String
    {
        get{
           var stringToReturn = lastFlagsString;
           stringToReturn = stringToReturn.replacingOccurrences(of: "@", with: "⌘")
           stringToReturn = stringToReturn.replacingOccurrences(of: "~", with: "⌥")
           stringToReturn = stringToReturn.replacingOccurrences(of: "$", with: "⇧")
           
           
           return stringToReturn;
           
        
        }
    }
    
    func keyDownForKeyboardPanel(event: NSEvent)
    {
        if let buttonFromRawKeyCode = registeredButtonKeyCodesToButtonObjects[Int(event.keyCode)]
        {
            buttonFromRawKeyCode.showButtonHighlighted = true
            buttonFromRawKeyCode.showButtonDown = true
            buttonFromRawKeyCode.needsDisplay = true
        }
    }
    
    func keyUpForKeyboardPanel(event: NSEvent)
    {
        if let buttonFromRawKeyCode = registeredButtonKeyCodesToButtonObjects[Int(event.keyCode)]
        {
            buttonFromRawKeyCode.showButtonHighlighted = false
            buttonFromRawKeyCode.showButtonDown = false
            buttonFromRawKeyCode.needsDisplay = true
        }
    }
    
    
    
    // also called by each KeyboardButton
    // by way of inputInteractionManager
    func flagsChangedFromActiveLayer(event: NSEvent)
    {
        
        
        var didHitFlagKey = false;
     
        var allFlagsString : String = ""
        
        /*
         "@" for Command
         “^” for Control
         “~” for Option
         “$” for Shift
         “#” for numeric keypad
         "C" for caps lock
         */

        
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.command))
        {
            allFlagsString.append("@")
        }
        
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.control))
        {
            allFlagsString.append("^")
        }
        
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.option))
        {
            allFlagsString.append("~")
        }
        
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.shift))
        {
            allFlagsString.append("$")
        }

        if( /* (event.modifierFlags.contains(NSEvent.ModifierFlags.capsLock) && */ (event.keyCode == 57)
        /*&&
        (lineWorkInteractionEntity.lineWorkEntityMode == .isInRectangleSelect)*/
        )
        {
            allFlagsString.append("C")
            // An exception because
            // caps lock key functions as
            // if a key was pressed, but is
            // treated as a modifier key and only
            // activated with flagsChanged.
            // 57 is caps lock keycode, as shown below,
            // which can be used for changing appearnce of keyboard key
            inputInteractionManager.rectangleSelectKeyPress();
            
        }
        
        
        // MARK: ---  CHANGE THE MODIFIER BUTTONS' APPEARANCE IN RESPONSE TO FLAGS

        // Caps lock
        // https://developer.apple.com/library/archive/qa/qa1519/_index.html
        if(event.keyCode == 57) // 57 is caps lock keycode
        {

            // function key
            if(event.modifierFlags.contains(NSEvent.ModifierFlags.function))
            {
                
            }
            else
            {
            
            }

            // caps lock on
            if(event.modifierFlags.contains(NSEvent.ModifierFlags.capsLock))
            {
         
         
//                capsLockKey.showButtonHighlighted = true
//                capsLockKey.showButtonDown = true
//                capsLockKey.needsDisplay = true
                
                
            
           }
           else
           {
                
                // caps lock off
//                capsLockKey.showButtonHighlighted = false
//                capsLockKey.showButtonDown = false
//                capsLockKey.needsDisplay = true
           }
            
        
        }
        
       
        
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.shift))
        {
           /* shiftKeyLeft.showButtonHighlighted = true
            shiftKeyLeft.showButtonDown = true
            shiftKeyLeft.needsDisplay = true
            
            shiftKeyRight.showButtonHighlighted = true
            shiftKeyRight.showButtonDown = true;
            shiftKeyRight.needsDisplay = true;
            */
            didHitFlagKey = true;
        }
        else
        {
           /*shiftKeyLeft.showButtonHighlighted = false
            shiftKeyLeft.showButtonDown = false
            shiftKeyLeft.needsDisplay = true
            
            shiftKeyRight.showButtonHighlighted = false
            shiftKeyRight.showButtonDown = false;
            shiftKeyRight.needsDisplay = true;
            */
        }
        
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.option))
        {
          /*
            optionKeyLeft.showButtonHighlighted = true;
            optionKeyLeft.showButtonDown = true
            optionKeyLeft.needsDisplay = true;
            
            optionKeyRight.showButtonHighlighted = true;
            optionKeyRight.showButtonDown = true;
            optionKeyRight.needsDisplay = true;
            */
            didHitFlagKey = true;
        }
        else
        {
            /*
            optionKeyLeft.showButtonHighlighted = false;
            optionKeyLeft.showButtonDown = false
            optionKeyLeft.needsDisplay = true;
            
            optionKeyRight.showButtonHighlighted = false;
            optionKeyRight.showButtonDown = false;
            optionKeyRight.needsDisplay = true;
            */
        }
        
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.command))
        {
            /*
            commandKeyLeft.showButtonHighlighted = true;
            commandKeyLeft.showButtonDown = true
            commandKeyLeft.needsDisplay = true
            
            commandKeyRight.showButtonHighlighted = true;
            commandKeyRight.showButtonDown = true;
            commandKeyRight.needsDisplay = true;
            */
            didHitFlagKey = true;
            
        }
        else
        {
            /*
            commandKeyLeft.showButtonHighlighted = false;
            commandKeyLeft.showButtonDown = false
            commandKeyLeft.needsDisplay = true
            
            commandKeyRight.showButtonHighlighted = false;
            commandKeyRight.showButtonDown = false;
            commandKeyRight.needsDisplay = true;
            */
        }

        if(event.modifierFlags.contains(NSEvent.ModifierFlags.control))
        {
            /*
            controlKey.showButtonHighlighted = true;
            controlKey.showButtonDown = true;
            controlKey.needsDisplay = true;
            */
            didHitFlagKey = true;
            
        }
        else
        {
            /*
            controlKey.showButtonHighlighted = false;
            controlKey.showButtonDown = false;
            controlKey.needsDisplay = true;
            */
        }
        
        /*
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.function))
        {
            
            functionKey.showButtonHighlighted = true;
            functionKey.showButtonDown = true;
            functionKey.needsDisplay = true;
            
            didHitFlagKey = true;
            
        }
        else
        {
            functionKey.showButtonHighlighted = false;
            functionKey.showButtonDown = false;
            functionKey.needsDisplay = true;
            
        }*/
        

     

        // No flags are active,
        // but they were active before.
        
        if(flagKeyWasOn && (didHitFlagKey == false))
        {
          
            // clear any highlighted or button down
            
            for key : KeyboardButton in registeredButtonKeyCodesToButtonObjects.values
            {
                
                if((key.showButtonHighlighted == true) || (key.showButtonDown == true))
                {
                    key.showButtonHighlighted = false;
                    key.showButtonDown = false;
                    key.needsDisplay = true;
                    
                    
                }
     
            }

            changeAllKeysBasedOnFlagsString(allFlagsString)
            
        }
        // some flags are active
        else if(didHitFlagKey)
        {
            
            changeAllKeysBasedOnFlagsString(allFlagsString)
            
        }
        /*
        else
        {
            changeAllKeysBasedOnFlagsString(allFlagsString)
        }*/
        
        /*
       
        print(flagsAndKeyCode);
        
        if let descriptionDictForEventCodeWithFlagString : Dictionary<String, String> =
            self.keyboardMappingDescriptions[flagsAndKeyCode] as? Dictionary<String,String>
        {
            if let name = descriptionDictForEventCodeWithFlagString["name"]
            {
                key.buttonText = name;
                key.needsDisplay = true;
                //registeredButtonKeyCodesToButtonObjects
            }
        }
        */

        
        
     
        
        
        
        flagKeyWasOn = didHitFlagKey;
        
        lastFlagsString = allFlagsString;
        
    }
    
    
    @IBAction func resetAppearanceOfAllKeys(_ sender: NSControl?    )
    {
    
            DispatchQueue.main.async
            {
    
                for key : KeyboardButton in self.registeredButtonKeyCodesToButtonObjects.values
                {
                    /*
                    // skip over caps lock key
                    if(key == self.capsLockKey)
                    {
                        continue;
                    }
                    */
                    
                    if((key.showButtonHighlighted == true) || (key.showButtonDown == true))
                    {
//                        print(key.buttonName)
                        key.showButtonHighlighted = false;
                        key.showButtonDown = false;
                        key.needsDisplay = true;
                        
                        
                    }
                    
                }
                
                /*
                for flagKey : KeyboardButton in self.flagsKeys
                {
                    if((flagKey.showButtonHighlighted == true) || (flagKey.showButtonDown == true))
                    {
                        flagKey.showButtonHighlighted = false;
                        flagKey.showButtonDown = false;
                        flagKey.needsDisplay = true;
                        
                        
                    }
                }*/
        
        
                self.changeAllKeysBasedOnFlagsString("");
                
                
            }// END 'DispatchQueue.main.async'
    }
    
    
    func changeAllKeysBasedOnFlagsString(_ allFlagsString : String)
    {
    
        // IF ENABLED EXTRA usesAlternatePalettes
        if(inkAndLineSettingsManager.usesAlternatePalettes)
        {
            switch allFlagsString {
            case "^":
                inkAndLineSettingsManager.modeForWidthPaletteSegmControl = .grayscaleStrokeColors
            case "$":
                inkAndLineSettingsManager.modeForWidthPaletteSegmControl = .shadesOfCurrentStrokeColor
            case "~":
                inkAndLineSettingsManager.modeForWidthPaletteSegmControl = .tintsOfCurrentStrokeColor
            case "~$":
                inkAndLineSettingsManager.modeForWidthPaletteSegmControl = .tonesOfCurrentStrokeColor
              case "^~":
                inkAndLineSettingsManager.modeForWidthPaletteSegmControl = .basicHuesStrokeColors
              
            default:
                inkAndLineSettingsManager.modeForWidthPaletteSegmControl = .strokeWidths
                
                break;
            }
            
            if( (allFlagsString == "^") || (lastFlagsString == "^")
                    || (allFlagsString == "$") || (lastFlagsString == "$")
                    || (allFlagsString == "~") || (lastFlagsString == "~")
            )
            {
                
                inkAndLineSettingsManager.brushTipWidthPaletteSegmentedControl.needsDisplay = true;
            }
            
        } // END if(inkAndLineSettingsManager.usesAlternatePalettes)
        
    
        for keyboardButton : KeyboardButton in registeredButtonKeyCodesToButtonObjects.values
        {
        
            /*
            // skip over caps lock key
            if(keyboardButton == capsLockKey)
            {
                continue;
            }*/
        
         
            let flagsAndKeyCode = "\(allFlagsString)\(keyboardButton.keyCode)"
            
            
            if let descriptionDictForEventCodeWithFlagString : Dictionary<String, AnyObject> =
                self.keyboardMappingDescriptions[flagsAndKeyCode] as? Dictionary<String,AnyObject>
            {
            
                // used for temporarily disabling keys.
                if let isTempDisabledString = descriptionDictForEventCodeWithFlagString["isTempDisabled"] as? Bool
                {
                    if (isTempDisabledString)
                    {
                        continue
                    }
                }
            
                if let name = descriptionDictForEventCodeWithFlagString["name"]  as? String
                {
                    keyboardButton.buttonText = name;
                    
                    if let buttonBackgroundColorString = descriptionDictForEventCodeWithFlagString["buttonBackgroundColor"]
                    {
                        let rgbArray = buttonBackgroundColorString.components(separatedBy: ",")
                        
                        if(rgbArray.count == 3)
                        {
                            
                            let bgColor = NSColor(calibratedRed: CGFloat(Float(rgbArray[0]) ?? 255) / 255.0, green: CGFloat(Float(rgbArray[1])  ?? 255) / 255.0, blue: CGFloat(Float(rgbArray[2])  ?? 255) / 255.0, alpha: 1.0)
                            
                            keyboardButton.buttonBackgroundColor = bgColor;
                            
                        }
                        
                        
                    }
                    
                    
                    if let isDrawingButtonBool = descriptionDictForEventCodeWithFlagString["isDrawingButton"] as? Bool
                    {
                        keyboardButton.isDrawingButton = isDrawingButtonBool;
                    
                    }
                    else
                    {
                        keyboardButton.isDrawingButton = false
                    }


                    if let buttonFontColorString = descriptionDictForEventCodeWithFlagString["buttonFontColor"] as? String
                    {
                        let rgbArray = buttonFontColorString.components(separatedBy: ",")
                        
                        if(rgbArray.count == 3)
                        {
                            
                            let fontColor = NSColor(calibratedRed: CGFloat(Float(rgbArray[0]) ?? 255) / 255.0, green: CGFloat(Float(rgbArray[1])  ?? 255) / 255.0, blue: CGFloat(Float(rgbArray[2])  ?? 255) / 255.0, alpha: 1.0)
                            
                            keyboardButton.fontForegroundColor = fontColor;
                            
                        }
                        
                    }
                    
                    
                    if let buttonBackgroundImageNameString = descriptionDictForEventCodeWithFlagString["buttonBackgroundImage"] as? String
                    {
                        if let buttonBackgroundImage = NSImage.init(named: buttonBackgroundImageNameString)
                        {
                            keyboardButton.buttonBackgroundImage = buttonBackgroundImage;
                            
                        }
                        else
                        {
                            keyboardButton.buttonBackgroundImage = nil
                        }
                    }
                    else
                    {
                        keyboardButton.buttonBackgroundImage = nil
                    }
                    
                    keyboardButton.needsDisplay = true;
             
                }
            }
            /*
             else if let descriptionDictForEventCodeWithFlagString : Dictionary<String, String> =
                self.keyboardMappingDescriptions["\(keyboardButton.keyCode)"] as? Dictionary<String,String>
            {
                if let name = descriptionDictForEventCodeWithFlagString["name"]
                {
                    keyboardButton.buttonText = name;
                    keyboardButton.needsDisplay = true;
                    //registeredButtonKeyCodesToButtonObjects
                }
            }
            */
            keyboardButton.currentFlagsAndKeyCode = flagsAndKeyCode;
            
        }
        
        if(keyboardPopover!.isShown)
        {
            if let keyboardButtonForPopover : KeyboardButton = registeredButtonKeyCodesToButtonObjects[currentKeyboardPopoverKeyCode]
            {
                showPopoverForKeyboardButton(keyboardButton: keyboardButtonForPopover);
            }
         
        }
        
        /*
         let keyCodesWithCorrespondingFlags : [String] = dictionaryOfButtonsAndEventCodes.keys.filter { $0.contains(allFlagsString) }
         
         keyCodesWithCorrespondingFlags.forEach { ( eventCodeWithFlagsString ) in
         
         if let descriptionDictForEventCodeWithFlagString : Dictionary<String, String> =
         self.keyboardMappingDescriptions[eventCodeWithFlagsString] as? Dictionary<String,String>
         {
             if let name = descriptionDictForEventCodeWithFlagString["name"]
             {
                print("name");
                //registeredButtonKeyCodesToButtonObjects
             }
         }
         
         }
         */
    }
    
    func flagsStringFromEvent(event : NSEvent) -> String
    {
       var allFlagsString : String = ""
        
        /*
         "@" for Command
         “^” for Control
         “~” for Option
         “$” for Shift
         “#” for numeric keypad
         "C" for caps lock
         */

        
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.command))
        {
            allFlagsString.append("@")
        }
        
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.control))
        {
            allFlagsString.append("^")
        }
        
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.option))
        {
            allFlagsString.append("~")
        }
        
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.shift))
        {
            allFlagsString.append("$")
        }

        if(event.modifierFlags.contains(NSEvent.ModifierFlags.capsLock))
        {
            allFlagsString.append("C")
        }
        
        return allFlagsString;
        
    }
    
    // MARK: ---  Popover Delegate
    
    func popoverWillShow(_ notification: Notification) {
        
        
    }
    
    func popoverDidClose(_ notification: Notification) {
        keyboardPopoverButtonName.stringValue = "No Name Yet";
        keyboardPopoverButtonName.textColor = NSColor.white;
        keyboardPopoverButtonName.drawsBackground = false;
        keyboardPopoverButtonDescription.string = "No Description Yet";
        
    }
    
    
    // MARK: --- Menu Actions
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        guard let action = menuItem.action else {
            fatalError("Unexpected MenuItem configuration")
        }
        
        switch action {
    
         case #selector(makeDrawingActualSize(_:)), #selector(zoomIntoDrawing(_:)), #selector(zoomOutOfDrawing(_:)), #selector(toggleInteriorKeyboardPanel(_:)):
         
            return ((NSDocumentController.shared.currentDocument as? FMDocument) != nil)
        
        default:
            return true
        }
    }
    
    @IBAction func toggleInteriorKeyboardPanel(_ sender : NSMenuItem)
    {
        
        self.changeVisibilityForFMKeyboardPanel(!fmKeyboardPanel.isVisible)
       
        resetAppearanceOfAllKeys(nil);
       
    }
    
        
    @IBAction func toggleInteriorGridColorPickerPanel(_ sender : NSMenuItem)
    {
        
        changeVisibilityForFMPaintFillModeTrayPanel(!fmPaintFillModeTrayPanel.isVisible)

    }
    
    @IBAction func makeDrawingActualSize(_ sender : NSMenuItem)
    {
    
        if let currentFMDocument = NSDocumentController.shared.currentDocument as? FMDocument
        {
            currentFMDocument.drawingScrollView.magnification = 1.0;
        }
        
    }
    
    @IBAction func zoomIntoDrawing(_ sender : NSMenuItem)
    {
        if let currentFMDocument = NSDocumentController.shared.currentDocument as? FMDocument
        {
        currentFMDocument.drawingScrollView.magnification = currentFMDocument.drawingScrollView.magnification + 0.1
        }
    }

    @IBAction func zoomOutOfDrawing(_ sender : NSMenuItem)
    {
        if let currentFMDocument = NSDocumentController.shared.currentDocument as? FMDocument
        {
        currentFMDocument.drawingScrollView.magnification = currentFMDocument.drawingScrollView.magnification - 0.1
        }
    }
    @IBAction func showHelp(_ sender : NSMenuItem)
    {
        let url = NSURL(string:"http://noctivagous.com/fmkr/docs/")!
        NSWorkspace.shared.open(url as URL)

    }

    
    // MARK: SUPPORTED FILE TYPES FOR PASTEBOARD
    // --------------------------------------------------------
    // The order of this array determines the order of preference for what is received.
    // if rtfd is in the array before rtf and both are on the pasteboard, rtfd will be sent by the pasteboard.
    // --------------------------------------------------------
    // MARK: supportedFileTypesForPasteboard
    var supportedFileTypesForPasteboard :  [NSPasteboard.PasteboardType] =
        [
        NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmdrawable"),
        NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmstroke"),
        NSPasteboard.PasteboardType.init("com.noctivagous.floating-marker.fmshapekeydrawable"),
        NSPasteboard.PasteboardType.tiff, NSPasteboard.PasteboardType("public.jpeg"),NSPasteboard.PasteboardType("com.compuserve.gif"),
         NSPasteboard.PasteboardType.png, NSPasteboard.PasteboardType.rtfd,
         NSPasteboard.PasteboardType.rtf,
         NSPasteboard.PasteboardType.string,
         NSPasteboard.PasteboardType.fileURL,
    ]
    
    // NSPasteboard.PasteboardType.string is the same as NSPasteboard.PasteboardType("public.utf8-plain-text")
    // other UTI's: ["public.tiff","public.jpeg","com.compuserve.gif","public.png",
    
    // MARK: imageFileTypes
    let imageFileTypes = ["public.tiff","public.jpeg","com.compuserve.gif",NSPasteboard.PasteboardType.png.rawValue,"com.adobe.encapsulated-postscript",
                          NSPasteboard.PasteboardType.pdf.rawValue]
    
    // MARK: textDocumentFileTypes
    let textDocumentFileTypes = [NSPasteboard.PasteboardType.rtfd.rawValue,
                                 NSPasteboard.PasteboardType.rtf.rawValue,
                                 NSPasteboard.PasteboardType.string.rawValue,
                                 // NSPasteboard.PasteboardType.string is the same as NSPasteboard.PasteboardType("public.utf8-plain-text")
        "public.plain-text" // different from public.utf8-plain-text,
    ]
    
    
    var supportedDragDestinationTypes :  [NSPasteboard.PasteboardType] = [
        NSPasteboard.PasteboardType("com.adobe.encapsulated-postscript"),
        NSPasteboard.PasteboardType.pdf,]
        
  
    // MARK: SHADING SHAPES
    func shadingShapesFromBaseXMLElement(baseXMLElement:XMLElement) -> [FMDrawable]?
    {
        do {
            
            let shadingShapesXPathArrayResult = try baseXMLElement.nodes(forXPath: ".//fmkr:ShadingShapesArray")
            
            if(shadingShapesXPathArrayResult.isEmpty)
            {
                return nil;
            }
            
            if let shadingShapesXMLBaseNodes = shadingShapesXPathArrayResult[0].children
            {

                var shadingShapesArrayToReturn : [FMDrawable] = [];
                for shadingShapeXMLNode in shadingShapesXMLBaseNodes
                {
                    
                    if let fmDrawable = fmDrawableFromBaseXMLElement(baseXMLElement: shadingShapeXMLNode as! XMLElement)
                    {shadingShapesArrayToReturn.append(fmDrawable)}
                    
                }
                return shadingShapesArrayToReturn


            }

            
            
        } catch
        {
        
        }
    
        return nil
    }
  
    func fmDrawableFromBaseXMLElement(baseXMLElement:XMLElement) -> FMDrawable?
    {
        guard baseXMLElement.name != nil else {
            return nil;
        }
    
        var fmDrawableToReturn : FMDrawable?
        
        do
        {
            
            // MARK: IMAGE
            if(baseXMLElement.name! == "image")
            {
                
                //guard let imageNode = childOfGNode as? XMLElement else { return  }
                
                let imageDrawable = FMImageDrawable.init(baseXMLElement: baseXMLElement, svgPath: "")
                fmDrawableToReturn = imageDrawable
                
                
                
            }
            // MARK: GROUP
            else if(baseXMLElement.name! == "g")
            {
                let groupDrawble = GroupDrawable.init(baseXMLElement: baseXMLElement, svgPath: "")
                fmDrawableToReturn = groupDrawble;
            
            }
            // MARK: PATH
            else if(baseXMLElement.name! == "path")
            {
                
                let pathNode = baseXMLElement
                
                if(pathNode.childCount > 0 )
                {
                    
                    // MARK: Find out if path is FMStroke
                    let fmStrokeNodesArray = try pathNode.nodes(forXPath: "fmkr:FMStroke")
                    
                    
                    if(fmStrokeNodesArray.isEmpty == false)
                    {
                        // print("found fmkr:FMStroke")
                        
                        //if let fmStrokeXMLElement = fmStrokeNodesArray.first! as? XMLElement
                        //{
                        
                        // MARK: path points (d)
                        
                        if let dContents = pathNode.attribute(forName: "d")?.stringValue
                        {
                            
                            
                            
                            let fmStroke = FMStroke.init(baseXMLElement: pathNode, svgPath: dContents)
                            fmDrawableToReturn = fmStroke
                            
                            
                        }
                        
                        
                        //}
                        
                    }
                    
                    // MARK: Find out if path is FMDrawable
                    else
                    {
                        let fmDrawableNodesArray = try pathNode.nodes(forXPath: "fmkr:FMDrawable")
                        if(fmDrawableNodesArray.isEmpty == false)
                        {
                            //                                        print("found fmkr:FMDrawable")
                            let dNode =  try pathNode.nodes(forXPath: "@d")
                            if(dNode.isEmpty == false)
                            {
                                if let dContents = dNode.first?.stringValue
                                {
                                    let fmDrawable = FMDrawable.init(baseXMLElement: pathNode,svgPath: dContents);
                                    fmDrawableToReturn = fmDrawable
                                }
                            }
                        }
                        
                        // MARK: There were children of the path, but unrecognized, so make generic FMDrawable
                        else
                        {
                            let dNode =  try pathNode.nodes(forXPath: "@d")
                            if(dNode.isEmpty == false)
                            {
                                if let dContents = dNode.first?.stringValue
                                {
                                    let fmDrawable = FMDrawable.init(baseXMLElement: baseXMLElement, svgPath: dContents);
                                    fmDrawableToReturn = fmDrawable
                                    
                                }
                            }
                        }
                    }
                    //                                print(fmStrokeNodesArray)
                    
                    
                    
                    
                    
                }
                
                
                // MARK: CHILD COUNT IS 0, so a generic FMDrawable is made
                
                else
                {
                    
                    let dNode =  try baseXMLElement.nodes(forXPath: "@d")
                    if(dNode.isEmpty == false)
                    {
                        if let s = dNode.first?.stringValue
                        {
                            let fmDrawable = FMDrawable.init(baseXMLElement: baseXMLElement, svgPath: s);
                            fmDrawableToReturn = fmDrawable
                        }
                    }
                    
                }
                
                
                
            }
        }
        
        catch
        {
            
        }
        
        return fmDrawableToReturn;
    }
            
}// END app delegate

