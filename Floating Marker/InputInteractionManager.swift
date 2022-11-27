//
//  InputInteractionManager.swift
//  Floating Marker
//
//  Created by John Pratt on 1/10/21.
//

import Cocoa

class InputInteractionManager: NSObject, NCTKeyEventDelegate
{
    @IBOutlet var curInputDoc : NSTextField?

    @IBOutlet var inkAndLineSettingsManager : InkAndLineSettingsManager?
    @IBOutlet var lineWorkInteractionEntity : LineWorkInteractionEntity?
    @IBOutlet var appDelegate : AppDelegate?
    
    // set by each activePenLayer whenever
    // it sends an event
    var currentInputDocument : FMDocument?
    {
        didSet
        {
            if(oldValue != currentInputDocument)
            {
                self.currentDocumentDidChange()
            }
        }
    }
    
    func currentDocumentDidChange()
    {
        if(currentInputDocument != nil)
        {
            curInputDoc?.stringValue = currentInputDocument!.displayName;
        }
        // reset all drawing states
        // in lineWorkInteractionEntity
    
    }
    

    var keyboardMappingDescriptions : Dictionary<String, AnyObject> = [:];
    
    
    override  func awakeFromNib() {
       // loadKeyboardMappingDescriptionsFromFile()
    }
    
    func loadKeyboardMappingDescriptionsFromFile()
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
                    
                } catch {
                    print("Error reading plist: \(error), format: \(propertyListFormat)")
                }
            }
        }
        else
        {
       
            
        }
    
    }

    func selectorFromKeyEventString(_ keyEventString: String) -> Selector?
    {
//        if let k = keyboardMappingDescriptions[String(event.keyCode)] as? AnyObject
//        {
        
//        }

    
        if(keyboardMappingDescriptions.isEmpty == false)
        {
            // keyboardMappingDescriptions is a dictionary
            // and each key in the dictionary is a key to an individual
             // dictionary.
            
            // the keys of keyboardMappingDescriptions are strings containing the key code for the key pressed
            
            if let keyEventDictionary = keyboardMappingDescriptions[keyEventString] as? Dictionary<String, Any>
            {

                // used for temporarily disabling keyEvents.
                if let isTempDisabled = keyEventDictionary["isTempDisabled"] as? Bool
                {
                    if (isTempDisabled)
                    {
                        return nil
                    }
                }
                
                if let functionForKeyEvent = keyEventDictionary["functionString"] as? String
                {
                    let selectorFromKeyMappingsDict = NSSelectorFromString(functionForKeyEvent)
                    return selectorFromKeyMappingsDict;
                }
            }
    
    
        }
        
   
        
        return nil;
    }

    let numKeysAndTildeDict : Dictionary<Int,Int> = [50:0,18:1,19:2,20:3,21:4,23:5,22:6,26:7,28:8,25:9,29:10];
    let numberPadNumberKeys : Dictionary<Int,Int> = [82:0,83:1,84:2,85:3,86:4,87:5,88:6,89:7,91:8,92:9]
    
    /*
    func adjustKeyboardButtonsToReflectKeyDownState()
    {
         if let currentFMDocument = NSDocumentController.shared.currentDocument as? FMDocument
        {
        }
    
    }*/
    
    // MARK: KEY EVENTS
    
    func flagsChangedFromActiveLayer(event: NSEvent)
    {
        appDelegate?.flagsChangedFromActiveLayer(event: event)
    
    }
    
    func keyDown(with event: NSEvent)
    {
  
   
        
        
        let stringTupleResult = stringsFromKeyEvent(event)
        let keyEventString = stringTupleResult.flagsAndKeyCode
  
        // MARK: Check if in RectangleSelect
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayer && (lineWorkInteractionEntity!.lineWorkEntityMode == .isInRectangleSelect))
        {

            if let selectorK = selectorFromKeyEventString(keyEventString)
            {
                if selectorK == #selector(cartKeyPress)
                {
                    lineWorkInteractionEntity!.lineWorkEntityMode = .idle;
                    lineWorkInteractionEntity?.activePenLayer?.setNeedsDisplay(lineWorkInteractionEntity!.rectangleSelectRect)
                    
                    cartKeyPress()
                    
                    return
                }
             
            }


            lineWorkInteractionEntity!.lineWorkEntityMode = .idle;
                    lineWorkInteractionEntity?.activePenLayer?.setNeedsDisplay(lineWorkInteractionEntity!.rectangleSelectRect)

            
            
            // MARK: RETURN if in RectangleSelect
            return;
        }
        
        
        // MARK: SEND THE KEYDOWN TO THE KEYBOARD PANEL TO CHANGE KEY APPEARANCE
        if let appDelegate = NSApp.delegate as? AppDelegate
        {
            appDelegate.keyDownForKeyboardPanel(event: event)
        }
        
        
        let hasCapslock = (event.modifierFlags.rawValue | NSEvent.ModifierFlags.capsLock.rawValue) == (event.modifierFlags.rawValue);
        
        // MARK: The keyCode is without modifierFlags or has capsLock down.
        if((event.modifierFlags.rawValue == 256)  || hasCapslock )
        {
            if(numKeysAndTildeDict.keys.contains(Int(event.keyCode)) )
            {
                
                // MARK: IS NUMBER KEY TO CHANGE WIDTH PALETTE SEGMENT

                let keyCodeInt = Int(event.keyCode)//.clamped(to: 0...10);
                
                if(numKeysAndTildeDict[keyCodeInt] != nil)
                {
                    inkAndLineSettingsManager?.brushTipWidthPaletteSegmentedControl.selectedSegment = numKeysAndTildeDict[keyCodeInt]!
                    
                }
                
                return;
            }
            
        }
       
        
        /*
        if(event.modifierFlags.contains(NSEvent.ModifierFlags.numericPad))
        {
        
            if(numberPadNumberKeys.keys.contains(Int(event.keyCode)) )
            {
                let keyCodeInt = Int(event.keyCode)
                if(numberPadNumberKeys[keyCodeInt] != nil)
                {
                    inkAndLineSettingsManager?.colorPaletteSegmentedControl.selectedSegment =
                        numberPadNumberKeys[keyCodeInt]! - 1;
                    }
            }
            
        
        }*/

        
        // MARK: inkAndLineSettingsManager.enableGrayscalePaletteKeys
        if(inkAndLineSettingsManager!.usesAlternatePalettes && ((event.modifierFlags.rawValue != 256) || hasCapslock))
        {
            let flagString = appDelegate!.flagsStringFromEvent(event: event)
            
            if(numKeysAndTildeDict.keys.contains(Int(event.keyCode)) )
            {
                let keyCodeInt = Int(event.keyCode)
                
                if(numKeysAndTildeDict[keyCodeInt] != nil)
                {
                    var colorVal : CGFloat = CGFloat(numKeysAndTildeDict[keyCodeInt]!) / 10
                    colorVal.formClamp(to: 0...1.0)

                    // ONLY CONTROL: GRAYSCALE
                    if(flagString == "^")
                    {
                        
                        let color = NSColor.init(white: colorVal, alpha: 1.0) ;
                        
                        inkAndLineSettingsManager?.updateColorWellBasedOnSelectionState(color: color)
                        
                    
                        return;
                    }
                    // TINT
                    else if(flagString == "~")
                    {
                        let color =
                            inkAndLineSettingsManager!.colorBasedOnSelectedOrCurrentStroke.blended(withFraction: colorVal, of: NSColor.white) ?? inkAndLineSettingsManager!.colorBasedOnSelectedOrCurrentStroke
                        inkAndLineSettingsManager?.updateColorWellBasedOnSelectionState(color: color)
                        
                        
                    }
                    // SHADE
                    else if(flagString == "$")
                    {
                        
                        
                        let color =
                            inkAndLineSettingsManager!.colorBasedOnSelectedOrCurrentStroke.blended(withFraction: colorVal, of: NSColor.black) ?? inkAndLineSettingsManager!.colorBasedOnSelectedOrCurrentStroke
                        
                        inkAndLineSettingsManager?.updateColorWellBasedOnSelectionState(color: color)
                        
                    
                    }
                    // TONE
                    else if(flagString == "~$")
                    {
                       
                        let color =
                            inkAndLineSettingsManager!.colorBasedOnSelectedOrCurrentStroke.blended(withFraction: colorVal, of: NSColor.gray) ?? inkAndLineSettingsManager!.colorBasedOnSelectedOrCurrentStroke
                        
                        inkAndLineSettingsManager?.updateColorWellBasedOnSelectionState(color: color)
                        
                    
                    }
                    // BASIC HUES
                    else if(flagString == "^~")
                    {
              
                        let color = NSColor.init(hue: colorVal, saturation: inkAndLineSettingsManager!.basicHuesSaturation, brightness:inkAndLineSettingsManager!.basicHuesBrightness, alpha: 1.0);
                        
                        inkAndLineSettingsManager?.updateColorWellBasedOnSelectionState(color: color)
                        
                    
                    }
                    
                    
                }
            }
            
        }
        
        
    

        
    
        if (keyEventString != "")
        {

            let selectorForInputManager = selectorFromKeyEventString(keyEventString)
            
            if(selectorForInputManager != nil)
            {
                if(self.responds(to: selectorForInputManager))
                {
                    self.perform(selectorForInputManager);
                }
            }
            

        }
        
    
        
    
    }
  /*
    func regularModifierCheckForOnly(event: NSEvent, modiferFlag:NSEvent.ModifierFlags) -> Bool
    {
        var regularModifiers : [NSEvent.ModifierFlags] = [.command,.control,.option,.shift]
        
        if let idx = regularModifiers.firstIndex(of: modiferFlag)
        {
            regularModifiers.remove(at: idx)
        }
     
        
     
        if(event.modifierFlags.contains(modiferFlag))
        {

            for m in regularModifiers
            {
                if(event.modifierFlags.contains(m))
                {
                    return false
                }
            }
            return true;
        }

        
        return false;
    
    }
*/
    func keyUp(with event: NSEvent)
    {
        if let appDelegate = NSApp.delegate as? AppDelegate
        {
            appDelegate.keyUpForKeyboardPanel(event: event)
        
        }
    }

    // MARK: mouse events

    func mouseMoved(with event: NSEvent)
    {
        lineWorkInteractionEntity?.mouseMoved(with: event)
    }
    
    func mouseDown(with event: NSEvent)
    {
     
        lineWorkInteractionEntity!.mouseDown(with: event)

    }
    
    func mouseUp(with event: NSEvent)
    {
        lineWorkInteractionEntity?.mouseUp(with: event)

    }

    func mouseEntered(with event: NSEvent)
    {
        
        lineWorkInteractionEntity?.activePenLayer?.setupCursor()
        
    }
    
    func mouseExited(with event: NSEvent)
    {
    
        if(currentInputDocument != nil)
        {
            if(currentInputDocument!.drawingPage.currentPaperLayer.isCarting)
            {
                currentInputDocument!.drawingPage.currentPaperLayer.cart();
            }
        }
    }
    
    func mouseDragged(with event: NSEvent)
    {
        lineWorkInteractionEntity?.mouseDragged(with: event)
    }

    //MARK: FUNCTIONS FOR KEYS

    @objc func bSplineKeyPress()
    {
        lineWorkInteractionEntity?.bSplineKeyPress()
    
    }

    @objc func roundedBSplineCornerKeyPress()
    {
    
        lineWorkInteractionEntity?.roundedBSplineCornerKeyPress()
    }
    
    @objc func roundedBSplineCornerBowedLineKeyPress()
    {
        lineWorkInteractionEntity?.roundedBSplineCornerBowedLineKeyPress()
    }

    @objc func roundedBSplineCornerBowedLineFacingBKeyPress()
    {
        lineWorkInteractionEntity?.roundedBSplineCornerBowedLineFacingBKeyPress()
    }
    
    @objc func hardBSplineCornerBowedLineKeyPress()
    {
       lineWorkInteractionEntity?.hardBSplineCornerBowedLineKeyPress()
    }
    
    @objc func hardBSplineCornerBowedLineFacingBKeyPress()
    {
       lineWorkInteractionEntity?.hardBSplineCornerBowedLineFacingBKeyPress()
    }
    

    @objc func endKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            if(lineWorkInteractionEntity!.currentPaperLayer!.isCarting)
            {
                lineWorkInteractionEntity!.currentPaperLayer!.cart()
            }
        }
    
        lineWorkInteractionEntity?.endKeyPress()
    
    }

    @objc func hardBSplineCornerKeyPress()
    {
        lineWorkInteractionEntity?.hardBSplineCornerKeyPress()
    
    }
    
    @objc func toggleMarkerPenKeyPress()
    {
    
    
    }

    @objc func stampKeyPress()
    {
       
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity?.stampSelectedObjects()

        
            return
        }
        
        
       lineWorkInteractionEntity?.stampCurrentLine()
    }

    @objc func moveLineIntoShapeKeyPress()
    {
        lineWorkInteractionEntity?.moveLineIntoShapeKeyPress()

    }

    @objc func completeCurrentLineIntoShapeKeyPress()
    {
    
        lineWorkInteractionEntity?.completeCurrentLineIntoShapeKeyPress()
    }

    @objc func dabKeyPress()
    {
        lineWorkInteractionEntity?.dabKeyPress();

    }
    
    @objc func ellipseByTwoAxesKeyPress()
    {
        lineWorkInteractionEntity?.ellipseByTwoAxesKeyPress()
    }
    
    @objc func rectangleByTwoLinesKeyPress()
    {
        lineWorkInteractionEntity?.rectangleByTwoLinesKeyPress()
    }
    
    @objc func shapeInQuadKeyPress()
    {
        lineWorkInteractionEntity?.shapeInQuadKeyPress()
    }
    
    @objc func vanishingPointKeyPress()
    {
    
        lineWorkInteractionEntity?.vanishingPointKeyPress()
    }
    
    @objc func toggleVanishingPointLinesKeyPress()
    {
        inkAndLineSettingsManager?.vanishingPointGuides.toggle()
    }
    
     @objc func toggleVanishingPointLinesSnappingKeyPress()
     {
        inkAndLineSettingsManager?.vanishingPointLinesSnapping.toggle()
        
        if(inkAndLineSettingsManager!.vanishingPointLinesSnapping && inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "PERSPECTIVE:")
        }
     }
    
    
    @objc func clearVanishingPointLinesKeyPress()
    {
        lineWorkInteractionEntity?.clearVanishingPointLines()
    }

    @objc func flipHorizontallyKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity?.currentPaperLayer?.flipHorizontallySelectedDrawables()
        
        }
        
    }
    
    @objc func flipVerticallyKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity?.currentPaperLayer?.flipVerticallySelectedDrawables()
        }
    }
    
    
    // AZIMUTH COUNTERCLOCKWISE:  (MEDIUM), UPPER, LOWER
    @objc func azimuthCounterclockwiseKeyPress()
    {
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.rotateSelectedDrawablesBy(degrees: -5.0)
            return
        }
        
        inkAndLineSettingsManager!.azimuthDegrees =  inkAndLineSettingsManager!.azimuthDegrees + 10
    
    }
    
    @objc func azimuthCounterclockwiseUpperKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.rotateSelectedDrawablesBy(degrees: -15.0)
            
            return
            
        }
        
        inkAndLineSettingsManager!.azimuthDegrees =  inkAndLineSettingsManager!.azimuthDegrees + 45
    
    }
    
   
    @objc func azimuthCounterclockwiseLowerKeyPress()
    {
    
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.rotateSelectedDrawablesBy(degrees: -1.0)
            
            return
            
        }
        
        inkAndLineSettingsManager!.azimuthDegrees =  inkAndLineSettingsManager!.azimuthDegrees + 5
    
    }
    
    // AZIMUTH CLOCKWISE:  (MEDIUM), UPPER, LOWER
    @objc func azimuthClockwiseKeyPress()
    {
    
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.rotateSelectedDrawablesBy(degrees: 5.0)
            
            return
            
        }
        
        
        inkAndLineSettingsManager!.azimuthDegrees = inkAndLineSettingsManager!.azimuthDegrees - 10
    
    }
    
    @objc func azimuthClockwiseUpperKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.rotateSelectedDrawablesBy(degrees: 15.0)
            
            return
        }
        
        
        inkAndLineSettingsManager!.azimuthDegrees = inkAndLineSettingsManager!.azimuthDegrees - 45
    
    }

    @objc func azimuthClockwiseLowerKeyPress()
    {
    
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.rotateSelectedDrawablesBy(degrees: 1.0)
            
            return
            
        }
        
        inkAndLineSettingsManager!.azimuthDegrees = (inkAndLineSettingsManager!.azimuthDegrees - 5)
    
    }

    @objc func strokeScaleIncrementUpperKeyPress()
    {
    
    
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            
            lineWorkInteractionEntity!.currentPaperLayer!.scaleSelectedDrawablesBy(1.5)
            
            return
        }
        
    }
    
    @objc func strokeScaleIncrementLowerKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.scaleSelectedDrawablesBy(1.05)
            
            return
            
        }
    }

    @objc func strokeScaleDecrementLowerKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.scaleSelectedDrawablesBy(0.97)
            
            return
            
        }

    
    }
    
    @objc func strokeScaleDecrementUpperKeyPress()
    {
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.scaleSelectedDrawablesBy(0.5)
            
            return
            
        }
    
    }
    
    @objc func strokeScaleIncrementKeyPress()
    {
    
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.scaleSelectedDrawablesBy(1.1)
            
            return
            
        }
    
        inkAndLineSettingsManager!.currentBrushTipWidth = inkAndLineSettingsManager!.currentBrushTipWidth +
        
        (1 + ((inkAndLineSettingsManager?.currentBrushTipWidth ?? 10) * 0.20))
    
    }

    @objc func strokeScaleDecrementKeyPress()
    {
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.scaleSelectedDrawablesBy(0.9)
            
            return
            
        }
        
        
        inkAndLineSettingsManager!.currentBrushTipWidth = inkAndLineSettingsManager!.currentBrushTipWidth -
        
        (1 + ((inkAndLineSettingsManager?.currentBrushTipWidth ?? 10) * 0.15))
    
    }
    
    
    /*
    
    // Move forward by one step on the width palette.
    @objc func widthPaletteIndexIncrementKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.thickenSelectedDrawables()
            return
        }
        else
        {
        
        }
        
        inkAndLineSettingsManager?.widthPaletteIncrementIndex()
    }
    
    // Move back by one step on the width palette.
    @objc func widthPaletteIndexDecrementKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.thinSelectedDrawables()
            return
        }
        else
        {
        
        }
        
        
        inkAndLineSettingsManager?.widthPaletteDecrementIndex()
    }*/

    
    @objc func strokeWidthIncrementKeyPress()
    {
        
        inkAndLineSettingsManager!.bezierPathStrokeWidth = inkAndLineSettingsManager!.bezierPathStrokeWidth + 0.5;

    }
    
    @objc func strokeWidthDecrementKeyPress()
    {
    
        inkAndLineSettingsManager!.bezierPathStrokeWidth = inkAndLineSettingsManager!.bezierPathStrokeWidth - 0.5;

        
    }
    
    @objc func increaseBasicHuesBrightnessKeyPress()
    {
        if(inkAndLineSettingsManager!.modeForWidthPaletteSegmControl == .basicHuesStrokeColors)
        {
            inkAndLineSettingsManager!.basicHuesBrightness += 0.1;
            
        }
        
    }
    
    @objc func decreaseBasicHuesBrightnessKeyPress()
    {
    
        if(inkAndLineSettingsManager!.modeForWidthPaletteSegmControl == .basicHuesStrokeColors)
        {
            inkAndLineSettingsManager!.basicHuesBrightness -= 0.1;
        
        }
        
    }
    
    @objc func increaseBasicHuesSaturationKeyPress()
    {
        if(inkAndLineSettingsManager!.modeForWidthPaletteSegmControl == .basicHuesStrokeColors)
        {
            inkAndLineSettingsManager?.basicHuesSaturation += 0.1;
            
        }
    }

    @objc func decreaseBasicHuesSaturationKeyPress()
    {
        if(inkAndLineSettingsManager!.modeForWidthPaletteSegmControl == .basicHuesStrokeColors)
        {
            inkAndLineSettingsManager?.basicHuesSaturation -= 0.1;
            
        }

    }
    
    @objc func toggleKeyboardPanelKeyPress()
    {
        // already dealt with because of NSMenuItem
        // calling AppDelegate outlet method, but this is
        // here just in case
        appDelegate!.changeVisibilityForFMKeyboardPanel(!(appDelegate!.fmKeyboardPanel.isVisible))
    }
    
    @objc func togglePaintTrayKeyPress()
    {
        appDelegate!.changeVisibilityForFMPaintFillModeTrayPanel(!(appDelegate!.fmPaintFillModeTrayPanel.isVisible))
    }
    

   @objc func toggleLayersPanelKeyPress()
    {
        if(appDelegate?.currentFMDocument != nil)
        {
            
            appDelegate?.currentFMDocument?.drawingPageController?.changeVisibilityForLayersPanel(!(appDelegate!.currentFMDocument!.drawingPageController!.fmLayersPanel.isVisible))
        }
        
   }
    
    
    @IBAction func pushOrPullRelativeToPaletteFromTitleBar(_ sender : NCTSegmentedControl)
    {
        if(sender.selectedSegment == 0)
        {
            self.pushPaletteToSelectedKeyPress()
        }
        else if(sender.selectedSegment == 1)
        {
            self.pullSelectedToPaletteKeyPress()
        }
        
    }
    
    @objc func pushPaletteToSelectedKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            if(inkAndLineSettingsManager!.usesPushPullRelToPaletteKeys)
            {
                let oldRect = lineWorkInteractionEntity!.currentPaperLayer!.selectionTotalRegionRectExtendedRenderBounds()
                var selected = lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables;
                for i in 0..<selected.count
                {
                    inkAndLineSettingsManager!.aggregatedSettingCurrent.applyToDrawable(fmDrawable: &selected[i])
                }
            
                lineWorkInteractionEntity!.currentPaperLayer!.updateDynamicTreeProxyBoundsForSelectedDrawables()
                lineWorkInteractionEntity!.currentPaperLayer!.redisplaySelectedTotalRegionRect()
                lineWorkInteractionEntity!.currentPaperLayer!.setNeedsDisplay(oldRect)
            }
        }
    }
    
    @objc func pullSelectedToPaletteKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            if(inkAndLineSettingsManager!.usesPushPullRelToPaletteKeys)
            {
                let firstDrawableInSelection = lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables.first!
                
                var selected : [FMDrawable] = [];
                selected.append(contentsOf: lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables)
                lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables.removeAll();
            
              
            
                inkAndLineSettingsManager!.aggregatedSetting = FMDrawableAggregratedSettings.init(fmDrawable: firstDrawableInSelection);
            
                lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawables.append(contentsOf: selected)
            }
        }
    }

    
    @objc func instantExportFrameToDownloadsKeyPress()
    {
        if(appDelegate?.currentFMDocument != nil)
        {
            appDelegate?.currentFMDocument?.instantExportFrameToDownloads(nil)
        }
        
    }

    @objc func instantExportCanvasToDownloadsKeyPress()
    {
        if(appDelegate?.currentFMDocument != nil)
        {
            appDelegate?.currentFMDocument?.instantExportCanvasToDownloads(nil)
        }
    
    }
    
    
    @objc func instantExportSelectedToDownloadsKeyPress()
    {
        if(appDelegate?.currentFMDocument != nil)
        {
            appDelegate?.currentFMDocument?.instantExportSelectedToDownloads(nil)
        }
    
    }
    
    
    
    // MARK: MANIPULATE DRAWING ORDER OF SELECTED DRAWABLES
    
    @objc func selectedDrawablesToFrontKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawablesToFront()
        }
    }
    
    @objc func selectedDrawablesToBackKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawablesToBack()
        }
    }
    
    @objc func selectedDrawablesDownKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawablesDown()
        }
    }
    
    @objc func selectedDrawablesUpKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.selectedDrawablesUp()
        }
        
    }
    
    
    

    // MARK: -
    // MARK: LAYERS
    @objc func layerStepTowardBaseLayerKeyPress()
    {
        currentInputDocument?.drawingPageController?.drawingPage.layerStepTowardBaseLayer()

    }
    
    @objc func layerStepAwayFromBaseLayerKeyPress()
    {
        currentInputDocument?.drawingPageController?.drawingPage.layerStepAwayFromBaseLayer()

    }
    

    
    @objc func layer1KeyPress()
    {
    
        currentInputDocument?.drawingPageController?.drawingPage.currentPaperLayerIndex = 0
        
    }
    
    @objc func layer2KeyPress()
    {
        
        currentInputDocument?.drawingPageController?.drawingPage.currentPaperLayerIndex = 1
    }
    
    @objc func layer3KeyPress()
    {
        
        currentInputDocument?.drawingPageController?.drawingPage.currentPaperLayerIndex = 2
    }
    
    @objc func layer4KeyPress()
    {

        currentInputDocument?.drawingPageController?.drawingPage.currentPaperLayerIndex = 3

    }
    
    @objc func arcByThreePointsKeyPress()
    {
        lineWorkInteractionEntity?.arcByThreePointsKeyPress()
    }

    // MARK: -
    // MARK: UNDO AND REDO
    @objc func undoKeyPress()
    {
        if(self.appDelegate!.fmDocs.isEmpty == false)
        {
          currentInputDocument?.docFMWindow.undoManager?.undo()
        }
        
    }

    @objc func redoKeyPress()
    {
        if(self.appDelegate!.fmDocs.isEmpty == false)
        {
          currentInputDocument?.docFMWindow.undoManager?.redo()
        }
    }
    
    @objc func selectKeyPress()
    {
    
        if(appDelegate!.fmPaintFillModeTrayPanel.isVisible)
        {
            let mouseLocation = NSEvent.mouseLocation
            
            if(
                NSPointInRect(mouseLocation, appDelegate!.fmPaintFillModeTrayPanel.frame))
            {
                appDelegate!.nctColorPickerGridView.selectColorAtCursor();
                return;
            }
            
        }
        
        lineWorkInteractionEntity?.selectKeyPress()
        
    }

    @objc func cartKeyPress()
    {
        lineWorkInteractionEntity?.cartKeyPress()
    
    }

    @objc func deleteSelectedObjectsKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity?.currentPaperLayer!.deleteSelectedDrawables();
        }
    }
    
    @objc func deleteLastStrokeKeyPress()
    {
        
        lineWorkInteractionEntity?.deleteLastStrokeKeyPress()
    }
    
    @objc func deleteAllStrokesKeyPress()
    {
        
        lineWorkInteractionEntity?.deleteAllStrokesKeyPress()
    }

    @objc func toggleAngleSnappingKeyPress()
    {
        inkAndLineSettingsManager?.angleSnapping.toggle()
        
        if(inkAndLineSettingsManager!.angleSnapping && inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "SNAPPING:")
        }
    }

    @objc func brushAngle0DegreesKeyPress()
    {
        inkAndLineSettingsManager?.azimuthDegrees = 0
    }

    @objc func brushAngle45DegreesKeyPress()
    {
        inkAndLineSettingsManager?.azimuthDegrees = 45
    }
    
    @objc func brushAngle90DegreesKeyPress()
    {
        inkAndLineSettingsManager?.azimuthDegrees = 90
    }

    @objc func brushAngle135DegreesKeyPress()
    {
        inkAndLineSettingsManager?.azimuthDegrees = 135
    }
    
    @objc func brushAngle180DegreesKeyPress()
    {
        inkAndLineSettingsManager?.azimuthDegrees = 180
    }
    
    @objc func brushAngle225DegreesKeyPress()
    {
        inkAndLineSettingsManager?.azimuthDegrees = 225
    }
    
    @objc func brushAngle270DegreesKeyPress()
    {
        inkAndLineSettingsManager?.azimuthDegrees = 270
    }
    
    @objc func brushAngle315DegreesKeyPress()
    {
        inkAndLineSettingsManager?.azimuthDegrees = 315
    }
    
    
    @IBAction func brushWidthUpKeyPressAction(_ sender: NSControl)
    {
        self.brushWidthUpKeyPress()
    }
    
    @objc func brushWidthUpKeyPress()
    {
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.moveSelectedRight()
            // -----------------
            // RETURN ENDS THE FUNCTION HERE.
            return
        }
     
        
        var increment = 0.15 * inkAndLineSettingsManager!.currentBrushTipWidth;
        increment = max(inkAndLineSettingsManager!.currentBrushTipWidth + increment, inkAndLineSettingsManager!.currentBrushTipWidth + 1)
        inkAndLineSettingsManager?.increaseStrokeWidthBy(increment)
    
    }

    @IBAction func brushWidthDownKeyPressAction(_ sender: NSControl)
    {
        self.brushWidthDownKeyPress()
    }
    
    @objc func brushWidthDownKeyPress()
    {
        
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.moveSelectedLeft()
            // -----------------
            // RETURN ENDS THE FUNCTION HERE.
            return
        }
        
        let decrement = 0.15 * inkAndLineSettingsManager!.currentBrushTipWidth;
        inkAndLineSettingsManager?.decreaseStrokeWidthBy(decrement)
    
    }

    @IBAction func brushHeightUpKeyPressAction(_ sender: NSControl)
    {
        self.brushHeightUpKeyPress()
    }
    
    @objc func brushHeightUpKeyPress()
    {

       if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.moveSelectedUp()
            return
        }
        
        if(inkAndLineSettingsManager!.heightFactor < 0.1)
        {
            inkAndLineSettingsManager?.heightFactor += 0.01
        }
        else
        {
            inkAndLineSettingsManager?.heightFactor += 0.1;
        }
    }

    @IBAction func brushHeightDownKeyPressAction(_ sender: NSControl)
    {
        self.brushHeightDownKeyPress()
    }
    
    @objc func brushHeightDownKeyPress()
    {
    
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelectionAndModeIsIdle)
        {
            lineWorkInteractionEntity!.currentPaperLayer!.moveSelectedDown()
            return
        }
        
        if(inkAndLineSettingsManager!.heightFactor <= 0.11)
        {
            inkAndLineSettingsManager?.heightFactor -= 0.03;
        }
        else
        {
            inkAndLineSettingsManager?.heightFactor -= 0.1;
        }
        
    }

    @objc func ellipseBrushTipKeyPress()
    {
        inkAndLineSettingsManager?.fmBrushTip = .ellipse
        
    }
    
    @objc func rectangleBrushTipKeyPress()
    {
        inkAndLineSettingsManager?.fmBrushTip = .rectangle
        
    }
    
    @objc func uniformBrushTipKeyPress()
    {
        inkAndLineSettingsManager?.fmBrushTip = .uniform
        
    }
    
    @objc func uniformPathBrushTipKeyPress()
    {
        inkAndLineSettingsManager?.fmBrushTip = .uniformPath
        
    }
    
    @objc func uniformPathBrushTipForThinLineWorkKeyPress()
    {
        inkAndLineSettingsManager?.fmBrushTip = .uniformPath
        inkAndLineSettingsManager?.currentBrushTipWidth = 1.0;
        inkAndLineSettingsManager?.fmInk.representationMode = .inkColorIsStrokeOnly;
    }
    
    @objc func toggleGridSnappingKeyPress()
    {
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = true;
        inkAndLineSettingsManager?.gridSnapping.toggle()
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = false;
                
        if(inkAndLineSettingsManager!.gridSnapping && inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "GRID:")
        }
    }

    @objc func toggleGridVisibilityKeyPress()
    {
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = true;
        inkAndLineSettingsManager?.showGrid.toggle()
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = false;
    }


    @objc func toggleLengthSnappingKeyPress()
    {
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = true;
        inkAndLineSettingsManager?.lengthSnapping.toggle()
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = false;
        
        if(inkAndLineSettingsManager!.lengthSnapping && inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "SNAPPING:")
        }
    }
    
    @objc func togglePathSnappingKeyPress()
    {
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = true;
        inkAndLineSettingsManager?.pathsSnapping.toggle()
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = false;
        
        if(inkAndLineSettingsManager!.pathsSnapping && inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "SNAPPING:")
        }
    }
    
    @objc func toggleAlignmentSnappingKeyPress()
    {
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = true;
        inkAndLineSettingsManager?.alignmentPointLinesSnapping.toggle()
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = false;
    }
    
    @objc func togglePointSnappingKeyPress()
    {
        inkAndLineSettingsManager?.pointsSnapping.toggle()
        
        if(inkAndLineSettingsManager!.pointsSnapping && inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "SNAPPING:")
        }
    }

    
    @objc func replicationModeToggleKeyPress()
    {
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = true;
        inkAndLineSettingsManager?.replicationModeIsOn.toggle()
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = false;
        
        if(inkAndLineSettingsManager!.replicationModeIsOn && inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "REPLICATION:")
        }
    }

    
    @objc func replicateSelectedToggleKeyPress()
    {
        lineWorkInteractionEntity?.replicateSelectedToggleKeyPress();
    
    }

    @objc func toggleLiveCombinatoricsKeyPress()
    {
        
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = true;
        inkAndLineSettingsManager?.combinatoricsModeIsOn.toggle()
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = false;

       
        if(inkAndLineSettingsManager!.combinatoricsModeIsOn && inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "LIVE COMBINATORICS:")
        }
    }
    
    @objc func liveCombinatoricsIsUnionKeyPress()
    {
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = true;
        inkAndLineSettingsManager?.combinatoricsMode = .union
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = false;
    }

    @objc func liveCombinatoricsIsIntersectionKeyPress()
    {
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = true;
        inkAndLineSettingsManager?.combinatoricsMode = .intersection
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = false;
    }
    
    @objc func liveCombinatoricsIsSubtractionKeyPress()
    {
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = true;
        inkAndLineSettingsManager?.combinatoricsMode = .subtraction
        inkAndLineSettingsManager!.allowStatusMessagesBecauseOfKeypress = false;
    }
    
    @objc func intersectionCombinatoricsKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            if(lineWorkInteractionEntity!.currentPaperLayer!.isCarting == false)
            {
                lineWorkInteractionEntity!.currentPaperLayer!.intersectionOfSelectedDrawables()
            }
            else
            {
                inkAndLineSettingsManager?.combinatoricsMode = .intersection
            }
        }
        else
        {
            inkAndLineSettingsManager?.combinatoricsMode = .intersection
            
        }
        
    }
    

    @objc func unionCombinatoricsKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            if(lineWorkInteractionEntity!.currentPaperLayer!.isCarting == false)
            {
                lineWorkInteractionEntity!.currentPaperLayer!.unionSelectedDrawables()
            }
            else
            {
                inkAndLineSettingsManager?.combinatoricsMode = .union
            }
        }
        else
        {
           inkAndLineSettingsManager?.combinatoricsMode = .union
        }
    }
    
    @objc func subtractionCombinatoricsKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            if(lineWorkInteractionEntity!.currentPaperLayer!.isCarting == false)
            {
                lineWorkInteractionEntity!.currentPaperLayer!.differenceOfSelectedDrawables()
            }
            else
            {
                inkAndLineSettingsManager?.combinatoricsMode = .subtraction
            }
        }
        else
        {
            inkAndLineSettingsManager?.combinatoricsMode = .subtraction
        }
    }
    
    @objc func loadedObjectKeyPress()
    {
        lineWorkInteractionEntity?.loadedObjectKeyPress()
        
        inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "LOADED OBJECT:")
        
    }

    @objc func escapeCurrentActivityKeyPress()
    {
        lineWorkInteractionEntity?.escapeCurrentActivityKeyPress()
    }
    
    
    @objc func eraseLastLivePointKeyPress()
    {
        lineWorkInteractionEntity?.eraseLastLivePointKeyPress()
    }

// MARK: PATHS:

    @objc func joinPathsKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            lineWorkInteractionEntity!.joinSelectedPaths();
        }
        
        
    }
    
    @objc func separateSubpathsKeyPress()
    {
        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            lineWorkInteractionEntity!.separateSubpaths()
        }
    }

// MARK: KEYBOARD KEYS



    //MARK: ---INK AND LINE SETTINGS
    //MARK:  THICKNESS PALETTE


    @objc func thicknessPaletteKeyPress()
    {
        // only one function to accommodate all keys
        // on the top row for numbers and tilde.
        // ---> uses the info
        // entry in the dictionary
        // (called currentKeyPressDictionary, global in this class)
        // to determine which paletteKey to press
    
    }


    @objc func strokeWidthPaletteShiftRightKeyPress()
    {
    
    
    }

    @objc func strokeWidthPaletteShiftLeftKeyPress()
    {
    
    
    }



    @objc func strokeWidthCoefficientUpKeyPress()
    {
    
    
    }

    @objc func strokeWidthCoefficientDownKeyPress()
    {
    
    
    }


 
     @objc func shadingShapesModeToggleKeyPress()
    {
        inkAndLineSettingsManager?.shadingShapesModeIsOn.toggle();
        
    }

    

    @objc func onlyStrokeKeyPress()
    {
    
        inkAndLineSettingsManager?.fmRepresentationMode = .inkColorIsStrokeOnly

       if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
        lineWorkInteractionEntity?.currentPaperLayer?.makeSelectedOnlyStroke()
        // inkAndLineSettingsManager?.updateSelectedRepresentationMode()
            return
        }
        
    }
    
    @objc func onlyFillKeyPress()
    {
        inkAndLineSettingsManager?.fmRepresentationMode = .inkColorIsFillOnly

        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            lineWorkInteractionEntity?.currentPaperLayer!.makeSelectedOnlyFill()
           // inkAndLineSettingsManager?.updateSelectedRepresentationMode()
            return
        }
    
    }
    
    @objc func fillStrokeKeyPress()
    {
    
        inkAndLineSettingsManager?.fmRepresentationMode = inkAndLineSettingsManager!.representationModeForStrokeAndFill()

        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            lineWorkInteractionEntity?.currentPaperLayer!.makeSelectedFillStroke()
//            inkAndLineSettingsManager?.updateSelectedRepresentationMode()
            return
        }



    }
    
    @objc func fillStrokeSplitKeyPress()
    {
        inkAndLineSettingsManager?.fmRepresentationMode = .inkColorIsStrokeWithSeparateFill

        if(lineWorkInteractionEntity!.thereIsCurrentPaperLayerWithSelection)
        {
            lineWorkInteractionEntity?.currentPaperLayer!.makeSelectedFillStrokeSplit()
          //  inkAndLineSettingsManager?.updateSelectedRepresentationMode()
            return
        }


    
    }
    
    @objc func noisingOfLinesToggleKeyPress()
    {
        lineWorkInteractionEntity?.inkAndLineSettingsManager?.noisingOfLinesIsOn.toggle();
        
        if( inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "NOISING OF LINES:")
        }
    }

    @objc func moveSelectionAnchorPointKeyPress()
    {
        lineWorkInteractionEntity?.moveSelectionAnchorPointKeyPress()
    }
    
    @objc func movePermanentAnchorPointKeyPress()
    {
        lineWorkInteractionEntity?.movePermanentAnchorPointKeyPress()
    }

    @objc func rectangleSelectKeyPress()
    {
        lineWorkInteractionEntity?.rectangleSelect();
    
    }

    @objc func groupKeyPress()
    {
        lineWorkInteractionEntity?.currentPaperLayer?.groupSelectedDrawables();
    }

    @objc func ungroupKeyPress()
    {
        lineWorkInteractionEntity?.currentPaperLayer?.ungroupSelectedDrawables();
    }


    // MARK: CORNER ROUNDING

    @objc func switchRoundedCornerKeyPress()
    {
        var rawVal = inkAndLineSettingsManager!.cornerRoundingType.rawValue + 1;
        if(rawVal > 2)
        {
            rawVal = 0;
        }
        inkAndLineSettingsManager!.cornerRoundingType = NCTCornerRoundingType.init(rawValue: rawVal) ?? .bSpline
        
        if( inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "CORNER ROUNDING:")
        }
        
        
    }
/*
    @objc func arcCornerRoundingKeyPress()
    {
        inkAndLineSettingsManager!.cornerRoundingType = .arc
    }

    @objc func bSplineCornerRoundingKeyPress()
    {
        inkAndLineSettingsManager!.cornerRoundingType = .bSpline
    }

    @objc func bevelCornerRoundingKeyPress()
    {
        inkAndLineSettingsManager!.cornerRoundingType = .bevel
    }
*/

    @IBAction func stepDownCornerRoundingLength(_ sender : NSControl)
    {
        stepDownCornerRoundingLengthKeyPress()
        
                
    

    }
    
    @IBAction func stepUpCornerRoundingLength(_ sender : NSControl)
    {
        stepUpCornerRoundingLengthKeyPress()
        


    }

    @objc func stepUpCornerRoundingLengthKeyPress()
    {
        if(inkAndLineSettingsManager!.cornerRounding < 5)
        {
            inkAndLineSettingsManager!.cornerRounding = 5
        }
        else
        {
            inkAndLineSettingsManager!.cornerRounding = inkAndLineSettingsManager!.cornerRounding + 10;
        }
        
                        
        if( inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "CORNER ROUNDING:")
        }
    }

    @objc func stepDownCornerRoundingLengthKeyPress()
    {
        if((inkAndLineSettingsManager!.cornerRounding - 5) < 5)
        {
            inkAndLineSettingsManager!.cornerRounding = 5;
        }
        else
        {
            inkAndLineSettingsManager!.cornerRounding = inkAndLineSettingsManager!.cornerRounding - 10;
        }
        
            if( inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand)
        {
            inkAndLineSettingsManager!.jumpToPanelBoxAfterRelevantCommand(panelBoxNamed: "CORNER ROUNDING:")
        }
    }
    
    
// MARK: JUMP TO SECTION

    @objc func jumpToDrawingSettingsSectionKeyPress()
    {
        inkAndLineSettingsManager?.jumpBarPopUpButton?.performClick(nil);
        appDelegate?.resetAppearanceOfAllKeys(nil);
    }
    
    // MARK: Export Frame

    @objc func exportFrameToggleKeyPress()
    {
    
        lineWorkInteractionEntity?.exportFrameToggleKeyPress()
    
    }
    @objc func adjustExportFrameCornerKeyPress()
    {
        lineWorkInteractionEntity?.adjustExportFrameCornerKeyPress()
    
    }

    @objc func adjustExportFrameCenterKeyPress()
    {
        lineWorkInteractionEntity?.adjustExportFrameCenterKeyPress()
    
    }
    

// MARK: STRING FROM KEY EVENT

// keyUp does not send the same modifierFlags as keydown
var lastPressedStringForKeyUp = ""

func stringsFromKeyEvent(_ keyEvent : NSEvent) -> (flagsString:String,flagsAndKeyCode:String)
{
        var flagsAndKeyCode : String = "";
        var flagsString : String = "";
        /*
         "@" for Command
         “^” for Control
         “~” for Option
         “$” for Shift
         “#” for numeric keypad
         */
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.command))
        {
            flagsString.append("@")
            flagsAndKeyCode.append("@")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.control))
        {
            flagsString.append("^")
            flagsAndKeyCode.append("^")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.option))
        {
            flagsString.append("~")
            flagsAndKeyCode.append("~")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.shift))
        {
            flagsString.append("$")
            flagsAndKeyCode.append("$")
        }

    /*
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.capsLock))
        {
            flagsString.append("C")
            flagsAndKeyCode.append("C")
        }*/
        
        flagsAndKeyCode.append(String(keyEvent.keyCode))
        
        // keyUp does not send the same modifierFlags as keydown
        lastPressedStringForKeyUp = flagsAndKeyCode
        
        return (flagsString, flagsAndKeyCode)
        

}


}// END class
