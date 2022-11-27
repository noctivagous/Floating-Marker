//
//  KeyboardMappingsManager.swift
//  SVDraw
//
//  Created by John Pratt on 12/5/18.
//  Copyright © 2018 Noctivagous, Inc. All rights reserved.
//

import Cocoa

class KeyboardMappingsManager: NSObject
{
 
   
    var dictionaryOfButtonsAndEventCodes : [String:String]!;
    
    
    let appDelegate : AppDelegate = NSApp.delegate as! AppDelegate
 //   var buttonNamesAndObjectsFromAppDelegate : Dictionary<String,KeyboardButton>?
    
    var lastPressedStringForKeyUp = ""
    
    @IBOutlet var drawingDocument : FMDocument!;
//    @IBOutlet var stateMachine : StateMachine?
//    @IBOutlet var drawingEntityManager : DrawingEntityManager!
//    @IBOutlet var layersManager : LayersManager!
//    @IBOutlet var panelsController : PanelsController!
//    @IBOutlet var entityConfigurationController : EntityConfigurationController!
    
    
    override init() {
        super.init()
        
        
    }
    /*
    //called by processEventForActiveLayerInReceiveDrawingState
    func buttonNameForKeyCode(_ keyEvent:NSEvent) -> String?
    {
        
        
        // MATCH KEYCODE TO KEYBOARDBUTTON VIEW OBJECT
        // SO THAT THE VIEW OBJECT CAN SHOW ONSCREEN THAT IT HAS BEEN
        // PRESSED OR RELEASED
        
        // all keycodes processed have to be in dictionary
        //  and have retrievable keyboardbuttonviewobject
        // if keyCode is in dictionary
        
        var flagsAndKeyCode : String = ""
        
        /*
         "@" for Command
         “^” for Control
         “~” for Option
         “$” for Shift
         “#” for numeric keypad
         */
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.command))
        {
            flagsAndKeyCode.append("@")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.control))
        {
            flagsAndKeyCode.append("^")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.option))
        {
            flagsAndKeyCode.append("~")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.shift))
        {
            flagsAndKeyCode.append("$")
        }
        
        flagsAndKeyCode.append(String(keyEvent.keyCode))
        
        // keyUp does not send the same modifierFlags as keydown
        lastPressedStringForKeyUp = flagsAndKeyCode
        
        if(keyEvent.type == .keyDown)
        {
            
            
            //print(appDelegate.keyboardMappingDescriptions[flagsAndKeyCode] ?? "error no key found \(flagsAndKeyCode)")
            
            
            
            
            //print(dictionaryOfButtonsAndEventCodes[dictString] ?? "error no key found \(dictString)")
            
            // if the string for the key code sequence has
            // a corresponding button name in the dictionary
            
            if let buttonName : String = dictionaryOfButtonsAndEventCodes[flagsAndKeyCode]
           {
           /* if let descriptionDictForEventCodeWithFlagString : Dictionary<String, String> =
                appDelegate.keyboardMappingDescriptions[flagsAndKeyCode] as? Dictionary<String,String>
            {

                if let buttonName : String = descriptionDictForEventCodeWithFlagString[flagsAndKeyCode]
                {*/
                
               
                    
                    if let buttonFromRawKeyCode : KeyboardButton = appDelegate.registeredButtonKeyCodesToButtonObjects[Int(keyEvent.keyCode)]
                    {
                       
                        buttonFromRawKeyCode.showButtonHighlighted = true
                        buttonFromRawKeyCode.showButtonDown = true
                        buttonFromRawKeyCode.needsDisplay = true
                        
                    }
                    
                    return buttonName;
                    
               // }
            }
            
        }
        else if(keyEvent.type == .keyUp)
        {
            
            
            print("KEYUP getButtonViewForKeyCodeAndMakeItDisplayKeyPressStatus lastPressed: \(lastPressedStringForKeyUp)")
            // use lastPressedStringForKeyUp
            // because keyUp does not send modifierFlags
            // that occur on keyDown.
            
            
            if let buttonFromRawKeyCode : KeyboardButton = appDelegate.registeredButtonKeyCodesToButtonObjects[Int(keyEvent.keyCode)]
            {
                
                
                
                buttonFromRawKeyCode.showButtonHighlighted = false
                buttonFromRawKeyCode.showButtonDown = false
                buttonFromRawKeyCode.needsDisplay = true
                
                
                
            }
            
            if let buttonName : String = dictionaryOfButtonsAndEventCodes[lastPressedStringForKeyUp]
            {
/*
            if let descriptionDictForEventCodeWithFlagString : Dictionary<String, String> =
                appDelegate.keyboardMappingDescriptions[lastPressedStringForKeyUp] as? Dictionary<String,String>
            {

                if let buttonName : String = descriptionDictForEventCodeWithFlagString[lastPressedStringForKeyUp]
                {
             */   

                    if let buttonFromRawKeyCode : KeyboardButton = appDelegate.registeredButtonKeyCodesToButtonObjects[Int(keyEvent.keyCode)]
                    {
                      
                    
                            
                            buttonFromRawKeyCode.showButtonHighlighted = false
                            buttonFromRawKeyCode.showButtonDown = false
                            buttonFromRawKeyCode.needsDisplay = true
                            
                     
                        
                    }
                    
                    return buttonName;
                //}
            }
            else
            {
                if let buttonFromRawKeyCode : KeyboardButton = appDelegate.registeredButtonKeyCodesToButtonObjects[Int(keyEvent.keyCode)]
                {
                    
                    
                    
                    buttonFromRawKeyCode.showButtonHighlighted = false
                    buttonFromRawKeyCode.showButtonDown = false
                    buttonFromRawKeyCode.needsDisplay = true
                    
                    
                    
                }
            }
            
        }
        
        return nil;
        
    }
    
    
    func getButtonViewForKeyCodeAndMakeItDisplayKeyPressStatus(_ keyEvent:NSEvent) -> KeyboardButton?
    {
        //print("processButtonEvent \(keyEvent.keyCode)")
        
        // MATCH KEYCODE TO KEYBOARDBUTTON VIEW OBJECT
        // SO THAT THE VIEW OBJECT CAN SHOW ONSCREEN THAT IT HAS BEEN
        // PRESSED OR RELEASED
        
        // all keycodes processed have to be in dictionary
        //  and have retrievable keyboardbuttonviewobject
        // if keyCode is in dictionary
        
        var dictString : String = ""
        
        /*
         "@" for Command
         “^” for Control
         “~” for Option
         “$” for Shift
         “#” for numeric keypad
         */
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.command))
        {
            dictString.append("@")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.control))
        {
            dictString.append("^")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.option))
        {
            dictString.append("~")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.shift))
        {
            dictString.append("$")
        }
        
        dictString.append(String(keyEvent.keyCode))
        
        // keyUp does not send the same modifierFlags as keydown
        lastPressedStringForKeyUp = dictString
        
        print("key event to look up: \(dictString) getButtonViewForKeyCodeAndMakeItDisplayKeyPressStatus")
        if(keyEvent.type == .keyDown)
        {
            
            
            //print(dictionaryOfButtonsAndEventCodes[dictString] ?? "error no key found \(dictString)")
            
            
            //print(appDelegate.keyboardMappingDescriptions[dictString] ?? "error no key found \(dictString)")
            
            
        }
    
             if(keyEvent.type == .keyDown)
             {
                
                //print(dictionaryOfButtonsAndEventCodes[dictString] ?? "error no key found \(dictString)")
                
                
                //print(appDelegate.keyboardMappingDescriptions[dictString] ?? "error no key found \(dictString)")
              
              
              
              //  if let buttonName : String = dictionaryOfButtonsAndEventCodes[dictString]
              //  {
                    /*
                    if let buttonObj : KeyboardButton = buttonNamesAndObjectsFromAppDelegate![buttonName]
                    {
                    
                        buttonObj.showButtonHighlighted = true
                        buttonObj.showButtonDown = true
                        buttonObj.needsDisplay = true
                     
                        
                        return buttonObj
                        
                    }*/
               // }
                
            }
            else if(keyEvent.type == .keyUp)
            {
                print("KEYUP getButtonViewForKeyCodeAndMakeItDisplayKeyPressStatus")
                // use lastPressedStringForKeyUp
                // because keyUp does not send modifierFlags
                // that occur on keyDown.
           
                // if let buttonName : String = dictionaryOfButtonsAndEventCodes[lastPressedStringForKeyUp]
               // {
                    
                    /*
                   if let buttonObj : KeyboardButton = buttonNamesAndObjectsFromAppDelegate![buttonName]
                   {
                        buttonObj.showButtonHighlighted = false
                        buttonObj.showButtonDown = false
                        buttonObj.needsDisplay = true
                    
                        return buttonObj
                   }*/
                    
               // }
    
            }
            
    
        
  
        return nil
        
    }
    
    @objc func handleKeyPress(note:Notification)
    {
      //  let f = note.userInfo
     
        print("handleKeyPress")
        
        // send to processButtonEvent after notification unpacked
    }
    
    
    // MARK: ---  NON-DRAWING BUTTONS
    func processKeyDownForNonDrawingButtonName(_ buttonName : String, event: NSEvent) -> Bool
    {
        
        if(self.dictionaryOfButtonsAndEventCodes.values.contains(buttonName))
        {
            
            //print("------- processKeyDownForNonDrawingButtonName \(buttonName)" )
            
            if(buttonName == "PlaceOnPaletteKey")
            {
                
                panelsController.placeOnPaletteKey(panelsController.paletteKeySettingsSummarySetToKeyButton)
                return true
            }
   
                
            else if(buttonName == "PlacePaletteKeyOntoObject")
            {
                
                panelsController.paletteKeyOntoObject(panelsController.paletteKeySettingsSummaryDeriveFromKeyButton);
                return true
            }
            
            else if(buttonName.hasPrefix("Layer"))
            {
                //
            
                return true
            }
            
            else if(buttonName == "InsertPointOnPath")
            {
            
                layersManager.processInsertPointOnPath();
                
                return true;
                
            }
            else if(buttonName == "InsertLineTo")
            {
                
                layersManager.processInsertLineTo();
                
                return true
            }
            else if(buttonName == "InsertCurveTo")
            {
                 // if done manually, use the calculated point normal to set the
                // two control point positions.
                    layersManager.processInsertCurveTo();
                  return true
            }
            else if(buttonName == "DeletePathPoint")
            {
            
                  layersManager.processDeletePathPoint();
                  return true;
                  
            }
       
                
            else if(buttonName == "ExternalKeyboard")
            {
                appDelegate.showHideExternalKeyboard();
               // print("PARAMETERSPANEL")
             //   panelsController.processParametersPanelButton()
                
                return true
            }
           
            else if(buttonName == "DrawingMediaInteriorPanel")
            {
                panelsController.processDrawingMediaInteriorPanelButton()
                
                return true
            }
            else if(buttonName == "PaletteKeysInteriorPanel")
            {
                panelsController.processPaletteKeysInteriorPanelButton()
                
                return true
            }
            else if(buttonName == "TextModeInteriorPanel")
            {
                panelsController.processTextModeInteriorPanelButton()
                return true;
            }
            else if(buttonName == "InteractiveAlignmentInteriorPanel")
            {
                panelsController.processInteractiveAlignmentInteriorPanelButton()
                
                return true
            }
           
        
            else if(buttonName == "End")
            {

             
                
                if(layersManager.currentDrawingLayerIsCarting)
                {
                    layersManager.currentDrawingLayer.endCarting();
                
                }
                else if(layersManager.currentDrawingLayer.scalingIsOn)
                {
                    layersManager.currentDrawingLayer.endScalingOperation();
                    
                }

                else if(layersManager.currentDrawingLayer.rotateIsOn)
                {
                    layersManager.currentDrawingLayer.endRotateOperation()
                }
                
                else if(
                (layersManager.currentDrawingLayer.hasSelectedDrawables) &&
                (drawingEntityManager.currentDrawingEntity.isInLinearDrawing == false))
                {
                    layersManager.currentDrawingLayer.clearOutSelections();
                }
                
                drawingEntityManager?.processEndButtonForDrawingEntity(drawableOperation: "none")
                
                
                return true;
                
            }
            else if(buttonName == "AnchorPointIsolated")
            {
                        
              if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing
              &&
            (drawingEntityManager.currentDrawingEntity.usesFreeAnchorButton)
            )
              {
                drawingEntityManager?.processFreeAnchorButtonForDrawingEntity()
              }
              else
              {

                if(drawingEntityManager!.drawWithReplication)
                  {
                    drawingEntityManager!.processFreeAnchorButtonForReplication();
                  }


                layersManager.processAnchorPointIsolatedButton();
                
                }
                return true
            }
            else if(buttonName == "Anchor")
            {
            
              if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing
              &&
            (drawingEntityManager.currentDrawingEntity.usesAnchorButton)
            )
              {
                drawingEntityManager?.processAnchorButtonForDrawingEntity()
              }
              else
              {
                  if(drawingEntityManager!.drawWithReplication)
                  {
                    drawingEntityManager!.processAnchorButtonForReplication()
                  }
              
                layersManager.processAnchorPointButton();
              }
                
              return true
            }
            
            else if(buttonName == "ConnectSelection")
            {
                
                layersManager.processConnectSelection();
                
                
                return true
            }
            else if(buttonName == "StrokeInspect")
            {
                
                drawingEntityManager.processStrokeInspect();
                
                
                return true
            }
            else if(buttonName == "FillInspect")
            {
                
                drawingEntityManager.processFillInspect();
                
                
                return true
            }
            else if(buttonName == "Escape")
            {
                if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing)
                {
                    drawingEntityManager.processEscapeButtonForDrawingEntity()
                }
                layersManager.processEscapeButtonForDeselection();
              
                return true
            }
            else if(buttonName == "RemoveLastSegment")
            {
                drawingEntityManager?.processRemoveLastLineSegmentForDrawingEntity()
                return true
            }
            else if(buttonName == "LineshapeToggle")
            {
                drawingEntityManager?.processLineShapeToggleButtonForDrawingEntities();
                
                return true
            }
            else if(buttonName == "Union")
            {
            
                  if(drawingEntityManager.drawWithCombinatorics)
                   {
                     drawingEntityManager.combinatoricsDrawingMode = .union;
                   }
                   else
                   {
                     layersManager.processUnionButton()
                
                    }
                
                
                return true
            }
            else if(buttonName == "Subtraction")
            {
            
                   if(drawingEntityManager.drawWithCombinatorics)
                   {
                        drawingEntityManager.combinatoricsDrawingMode = .subtraction;
                   }
                   else
                   {
                        layersManager.processDifferenceButton()
                
                    }
                
                
                
                return true
            }
            else if(buttonName == "Intersection")
            {
            
                   if(drawingEntityManager.drawWithCombinatorics)
                   {
                        drawingEntityManager.combinatoricsDrawingMode = .intersection;
                   }
                   else
                   {
                        layersManager.processIntersectionButton()
                    }

                
                return true
            }
            else if(buttonName == "Delete")
            {
                layersManager.processDeleteButton()
                
                return true
            }
            else if(buttonName == "RectangleSelect")
            {
                layersManager.processRectangleSelectButton()
                
                return true
            }
            else if(buttonName == "Select")
            {
                if(drawingEntityManager!.currentDrawingEntity.isInLinearDrawing
                && drawingEntityManager!.currentDrawingEntity.usesTabButton)
                {
                    drawingEntityManager!.currentDrawingEntity.processTabButton();
                }
                layersManager.processSelectButton()
                
                return true
            }
            else if(buttonName == "SelectOne")
            {
                layersManager.processSelectOneButton()
                
                return true
            }
            else if(buttonName == "SelectShadingShape")
            {
                layersManager.processSelectShadingShapeButton();
                
                return true
            }
            else if(buttonName == "Carting")
            {
                if(
                drawingEntityManager!.currentDrawingEntity.isInLinearDrawing  &&
                drawingEntityManager.currentDrawingEntity.usesCartingSpacebar)
                {
                    drawingEntityManager.currentDrawingEntity.processCartingSpacebar();
                }
                else
                {
                    layersManager.processCartingButton()
                }
                
                return true
            }
            else if(buttonName == "CartingBySelectOne")
            {
                layersManager.processCartingBySelectOneButton()
                
                return true
            }
            else if(buttonName == "StampUp")
            {
                if(drawingEntityManager!.currentDrawingEntity.isInLinearDrawing  &&
                drawingEntityManager.currentDrawingEntity.usesStampUpButton
                )
                {
                    drawingEntityManager?.processStampUpButtonForDrawingEntity();
                }
                else
                {
                    layersManager.processStampUpButton()
                }
                return true
            }
            else if(buttonName == "Stamp")
            {
                if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing &&
                drawingEntityManager.currentDrawingEntity.usesStampButton)
                 {
                    drawingEntityManager?.processStampButtonForDrawingEntity();
                    //drawingEntityManager.currentDrawingEntity.processStampButton()
                 }
                 else
                 {
                    layersManager.processStampButton()
                 }
                 
                /*layersManager.processStampButton()*/
                
            
                
                return true
            }
            else if(buttonName.hasPrefix("ScaleUp"))
            {
                var scalingFactor : CGFloat = 1.1;
                if(buttonName.contains("Upper"))
                {
                    scalingFactor = 1.5
                }
                else if(buttonName.contains("Lower"))
                {
                    scalingFactor = 1.25
                }
               
                 if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing && drawingEntityManager.drawWithReplication)
                 {
                    drawingEntityManager.replicationConfigurationViewController.processScaleUpForCount();
                 }
                 else if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing && drawingEntityManager.currentDrawingEntity.usesScaleUpAndScaleDownButtons)
                 {
                    if(buttonName.contains("Upper"))
                    {
                        drawingEntityManager.currentDrawingEntity.processScaleUpUpperButton()
                    }
                    else if(buttonName.contains("Lower"))
                    {
                        drawingEntityManager.currentDrawingEntity.processScaleUpLowerButton()
                    }
                    else
                    {
                        drawingEntityManager.currentDrawingEntity.processScaleUpButton()
                    }
                 }
                 else
                 {
                    layersManager.processScaleUpButton(factor:scalingFactor)
                 }
                
                return true
            }
            
            else if(buttonName.hasPrefix("ScaleDown"))
            {
            
                var scalingFactor : CGFloat = 0.9;
                
                if(buttonName.contains("Upper"))
                {
                    scalingFactor = 0.5
                }
                else if(buttonName.contains("Lower"))
                {
                    scalingFactor = 0.97
                }
                 if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing && drawingEntityManager.drawWithReplication)
                 {
                    drawingEntityManager.replicationConfigurationViewController.processScaleDownForCount();
                 }

                 else if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing && drawingEntityManager.currentDrawingEntity.usesScaleUpAndScaleDownButtons)
                 {
                    if(buttonName.contains("Upper"))
                    {
                        drawingEntityManager.currentDrawingEntity.processScaleDownUpperButton()
                    }
                    else if(buttonName.contains("Lower"))
                    {
                        drawingEntityManager.currentDrawingEntity.processScaleDownLowerButton()
                    }
                    else
                    {
                        drawingEntityManager.currentDrawingEntity.processScaleDownButton()
                    }
                 }
                 else
                 {
                    layersManager.processScaleDownButton(factor:scalingFactor)
                 }
                
                return true
            }
            else if
                (
                    
                    (buttonName == "RotateCounterClockwise") ||
                    (buttonName == "RotateCounterUpper") ||
                    (buttonName == "RotateCounterLower")
                
                )
            {
                /*
                if(drawingEntityManager.currentDrawingEntity.acceptsRotateCWAndRotateCCW)
                {
                    drawingEntityManager.currentDrawingEntity.processRotateCCW
                }
                 */
                
                var degrees : CGFloat = 1.0;
                
                if(buttonName == "RotateCounterClockwise")
                {
                    degrees = 5.0;
                }
                else if(buttonName == "RotateCounterUpper")
                {
                    degrees = 15.0;
                }
                else if(buttonName == "RotateCounterLower")
                {
                    degrees = 1.0;
                }
                    
                    
                if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing &&
                    drawingEntityManager.currentDrawingEntity.usesRotateCounterclockwiseAndClockwiseButtons)
                {
                    drawingEntityManager.processRotateCounterClockwiseButton(degrees: degrees)
                }
                else
                {
                    layersManager.processRotateCounterClockwiseButton(degrees: degrees)
                }
                return true
            }
            else if(
                
                (buttonName == "RotateClockwise") ||
                (buttonName == "RotateClockwiseUpper") ||
                (buttonName == "RotateClockwiseLower")
                
                )
            {
                /*
                 if(drawingEntityManager.currentDrawingEntity.acceptsRotateCWAndRotateCCW)
                 {
                 drawingEntityManager.currentDrawingEntity.processRotateCW
                 }
                 */

                var degrees : CGFloat = 1.0;
                
                if(buttonName == "RotateClockwise")
                {
                    degrees = 5.0;
                }
                else if(buttonName == "RotateClockwiseUpper")
                {
                    degrees = 15.0;
                }
                else if(buttonName == "RotateClockwiseLower")
                {
                    degrees = 1.0;
                }
                
                if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing &&
                drawingEntityManager.currentDrawingEntity.usesRotateCounterclockwiseAndClockwiseButtons)
                {
                    drawingEntityManager.processRotateClockwiseButton(degrees: degrees)
                }
                else
                {
                    layersManager.processRotateClockwiseButton(degrees: degrees)
                }
                
                return true
            }
            else if(buttonName == "YawClockwise")
            {
                layersManager.processYawClockwise()
                
                return true
            }
            else if(buttonName == "YawCounterClockwise")
            {
                layersManager.processYawCounterClockwise()
                
                return true
            }
            else if(buttonName == "PitchClockwise")
            {
                layersManager.processPitchClockwise()
                
                return true
            }
            else if(buttonName == "PitchCounterClockwise")
            {
                layersManager.processPitchCounterClockwise()
                
                return true
            }
            else if(buttonName == "RollClockwise")
            {
                layersManager.processRollClockwise()
                
                return true
            }
            else if(buttonName == "RollCounterClockwise")
            {
                layersManager.processRollCounterClockwise()
                
                return true
            }
                
            else if(buttonName == "ArrowDown")
            {
                
                 if(drawingEntityManager!.currentDrawingEntity.isInLinearDrawing  && drawingEntityManager.currentDrawingEntity.usesArrowKeys)
                 {
                    drawingEntityManager.currentDrawingEntity.processDownArrowButton();
                 }
                
                layersManager.processArrowDown()
                
                return true
            }
            else if(buttonName == "ArrowUp")
            {
                if(drawingEntityManager!.currentDrawingEntity.isInLinearDrawing  && drawingEntityManager.currentDrawingEntity.usesArrowKeys)
                {
                    drawingEntityManager.currentDrawingEntity.processUpArrowButton();
                }
                
                layersManager.processArrowUp()
                
                return true
            }
            else if(buttonName == "ArrowRight")
            {
                if(drawingEntityManager!.currentDrawingEntity.isInLinearDrawing  && drawingEntityManager.currentDrawingEntity.usesArrowKeys)
                {
                    drawingEntityManager.currentDrawingEntity.processRightArrowButton();
                }
                
                
                layersManager.processArrowRight()
                
                return true
            }
            else if(buttonName == "ArrowLeft")
            {
                if(drawingEntityManager!.currentDrawingEntity.isInLinearDrawing  && drawingEntityManager.currentDrawingEntity.usesArrowKeys)
                {
                    drawingEntityManager.currentDrawingEntity.processLeftArrowButton();
                }
                
                layersManager.processArrowLeft()
                
                return true
            }
            else if(buttonName == "FlipHorizontally")
            {
                
                layersManager.processFlipHorizontally()
                
                return true
            }
            else if(buttonName == "FlipVertically")
            {
                layersManager.processFlipVertically()
                
                return true
            }

            else if(buttonName == "LoadObject")
            {
                layersManager.processLoadObject()
                
                return true
            }
            else if(buttonName == "UseLoadedObject")
            {
                layersManager.processUseLoadedObject()
                
                return true
            }
            else if(buttonName == "Configure")
            {
                entityConfigurationController.processConfigure()
                
                return true
            }
            else if(buttonName == "MoreOpaque")
            {
                
            }
            else if(buttonName == "LessOpaque")
            {
                
            }
            else if(buttonName == "Thin")
            {
                
                panelsController.processThin()
                
                /*
                if((drawingEntityManager.currentDrawingEntity.isInLinearDrawing))
                {
                    drawingEntityManager.processThin()
                }
                else
                {
                    panelsController.processThin()
                }*/
                
                 return true
            }
            else if(buttonName == "Thicken")
            {
                  panelsController.processThicken()
                
                /*
                    if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing)
                    {
                        drawingEntityManager.processThicken()
                    }
                    else
                    {
                        panelsController.processThicken()
                    }
                 */
                
                 return true
            }
            else if(buttonName == "SaturationMore")
            {
                if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing)
                {
                    drawingEntityManager.processSaturationMore()
                }
                else
                {
                    panelsController.processSaturationMore()
                }
                
                 return true
            }
            else if(buttonName == "SaturationLess")
            {
                if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing)
                {
                    drawingEntityManager.processSaturationLess()
                }
                else
                {
                    panelsController.processSaturationLess()
                }
                
                 return true
            }
            else if(buttonName == "Lighten")
            {
                if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing)
                {
                    drawingEntityManager.processLighten()
                }
                else
                {
                    panelsController.processLighten()
                }
                
                 return true
            }
            else if(buttonName == "Darken")
            {
                if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing)
                {
                    drawingEntityManager.processDarken()
                }
                else
                {
                    panelsController.processDarken()
                }
                
                 return true
            }
            else if(buttonName == "HueRotateCCW")
            {
                if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing)
                {
                    drawingEntityManager.processHueRotateCCW()
                }
                else
                {
                    panelsController.processHueRotateCCW()
                }
                
                 return true
            }
            else if(buttonName == "HueRotateCW")
            {
                if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing)
                {
                    drawingEntityManager.processHueRotateCW()
                }
                else
                {
                    panelsController.processHueRotateCW()
                }
                
                return true
            }
            else if(buttonName == "ObjToFront")
            {
                layersManager.processObjectToFront()
                
                return true
            }
            else if(buttonName == "ObjToBack")
            {
                layersManager.processObjectToBack()
                
                return true
            }
            else if(buttonName == "ObjUp")
            {
                layersManager.processObjectUp()
                
                return true
            }
            else if(buttonName == "ObjDown")
            {
                layersManager.processObjectDown()
                
                return true
            }
            else if(buttonName == "Group")
            {
                layersManager.processGroup();
                
                return true
            }
            else if(buttonName == "Ungroup")
            {
                layersManager.processUngroup();
                
                return true
            }
            else if( buttonName.contains("PaletteKey") && (!buttonName.contains("PaletteKeyGroup")) )
            {
                
                let keyNumber = buttonName.last!
                
                panelsController.processPaletteKey(keyNumber: Int(String(keyNumber)) ?? 1);
                
            }
            else if(buttonName.contains("PaletteKeyGroup"))
            {
                
                let keyNumber = buttonName.last!
                
                panelsController.processPaletteKeyGroup(keyNumber: Int(String(keyNumber)) ?? 1);
                
            }
            else if(buttonName == "Clear")
            {
            
               if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing)
               {
                 drawingEntityManager?.processClearButtonForDrawingEntity()
               }
               else
               {
                 layersManager.processClearButton();
               }
               
            }
            else if(buttonName == "InspectSelected")
            {
               if(drawingEntityManager.currentDrawingEntity.isInLinearDrawing)
               {
                    if(drawingEntityManager.currentDrawingEntity.usesReturnButton)
                    {
                        drawingEntityManager.currentDrawingEntity.processReturnButton()
                    }
                    else
                    {
                        drawingEntityManager.processEndButtonForDrawingEntity(drawableOperation: "none");
                    }
               }
               else if(layersManager.currentDrawingLayerIsCarting)
               {
                    layersManager.currentDrawingLayer.endCarting();
               }
               else
               {
               
                layersManager.processInspectSelected();
               }
               
               return true
            }
            else if(buttonName == "ShadingShapesModeOnOff")
            {
               
               drawingEntityManager.shadingShapesModeIsOn = !drawingEntityManager.shadingShapesModeIsOn;
               
               return true
            }
            else if(buttonName == "GridSnapping")
            {
                drawingEntityManager.processGridSnapping();
                return true
            }
            else if(buttonName == "ToggleGridVisibility")
            {
                drawingEntityManager.processGridVisibilityToggle();
                return true
            }
            else if(buttonName == "LengthSnapping")
            {
                drawingEntityManager.processLengthSnapping();
                return true
            }
            else if(buttonName == "AngleSnapping")
            {
                drawingEntityManager.processAngleSnapping();
                return true
            }
            else if(buttonName == "PathSnapping")
            {
                drawingEntityManager.processPathSnapping();
                return true
            }
            else if(buttonName == "PointSnapping")
            {
                drawingEntityManager.processPointSnapping();
                return true
            }
            else if(buttonName == "EdgeSnapping")
            {
                drawingEntityManager.processEdgeSnapping();
                return true
            }
            else if(buttonName == "RoundedCorner")
            {
                drawingEntityManager.processRoundedCorner();
                return true
            }
             else if(buttonName == "DrawWithCombinatorics")
            {
                drawingEntityManager.drawWithCombinatorics.toggle();
                return true;
            }
            
            else if(buttonName == "FillToggle")
            {
                panelsController.processFillToggle();
                return true
            }
            else if(buttonName == "StrokeToggle")
            {
                panelsController.processStrokeToggle();
                return true
            }
            else if(buttonName == "ZoomIn")
            {
                layersManager.processZoomIn();
                return true
            }
            else if(buttonName == "ZoomOut")
            {
                layersManager.processZoomOut();
                return true
            }
            else if(buttonName == "ActualSize")
            {
                layersManager.processActualSize();
                return true
            }
            else if(buttonName == "InspectBasic")
            {
                panelsController.processInspectBasic();
                return true
            }
            else if(buttonName == "InspectSize")
            {
                panelsController.processInspectSize();
                return true
            }
            else if(buttonName == "ExportSelectedPopover")
            {
                
                drawingDocument.exportSelectedDrawablesPopover(nil);
                return true
            
            }
            else if(buttonName == "ExportSelected")
            {
                
                drawingDocument.exportSelectedDrawables(nil);
                return true
                
            }
            else if(buttonName == "TextMode")
            {
                
                drawingEntityManager.textModeIsOn.toggle();
                return true
                
            }
            
            else if(buttonName == "LiveScale")
            {
                
                layersManager.processLiveScale(uniformFromCenter: !drawingEntityManager.liveScaleKeyActsNonUniform );
                return true
                
            }
            else if(buttonName == "LiveScaleUniformFromCenter")
            {
                
                layersManager.processLiveScale(uniformFromCenter: drawingEntityManager.liveScaleKeyActsNonUniform );
                return true
                
            }
            else if(buttonName == "LiveShear")
            {
                
                layersManager.processLiveShear();
                
                return true
                
            }
            
            else if(buttonName == "LiveRotate")
            {
                layersManager.processLiveRotate(uniformFromCenter:false);
                return true
            }
            
          
            else if(buttonName == "LiveRotate3D")
            {
                layersManager.processLiveRotate3D(uniformFromCenter: true)
                return true
            }

            else if(buttonName == "Derive")
            {
                drawingEntityManager.processDerive();
                return true
            }
            else if(buttonName == "DeriveAll")
            {
                drawingEntityManager.processDeriveAll();
                return true
            }
            else if(buttonName == "Apply")
            {
                drawingEntityManager.processApply();
                return true
            }
            else if( buttonName.hasPrefix("Op") && (buttonName.count <= 4) )
            {
        
                drawingEntityManager.executeDrawingScript(number: Int(String(buttonName.dropFirst(2))) ?? 1);
                
                
            }
     
          
        }
        
     
        return false
    }
    
    
    
    func processButtonEvent(_ keyEvent:NSEvent) -> KeyboardButton?
    {
        //print("processButtonEvent \(keyEvent.keyCode)")
    
        // MATCH KEYCODE TO KEYBOARDBUTTON VIEW OBJECT
        // SO THAT THE VIEW OBJECT CAN SHOW ONSCREEN THAT IT HAS BEEN
        // PRESSED OR RELEASED
        
        // all keycodes processed have to be in dictionary
        //  and have retrievable keyboardbuttonviewobject
        // if keyCode is in dictionary
        
        var dictString : String = ""
        
        /*
         "@" for Command
         “^” for Control
         “~” for Option
         “$” for Shift
         “#” for numeric keypad
         */
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.command))
        {
            dictString.append("@")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.control))
        {
            dictString.append("^")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.option))
        {
            dictString.append("~")
        }
        
        if(keyEvent.modifierFlags.contains(NSEvent.ModifierFlags.shift))
        {
            dictString.append("$")
        }
        
        dictString.append(String(keyEvent.keyCode))
        // keyUp does not send modifierFlags
        
        
        if(keyEvent.type == .keyDown)
        {
            print("\(keyEvent.keyCode) KEYDOWN characters: \(keyEvent.characters!) \(dictString)")
            lastPressedStringForKeyUp = dictString
        }
        
        if(keyEvent.type == .keyDown)
        {
           // if let buttonName : String = dictionaryOfButtonsAndEventCodes[dictString]
           // {
                /*
                print("processButtonEvent KEYDOWN buttonName \(buttonName)")
                if let buttonObj : KeyboardButton = buttonNamesAndObjectsFromAppDelegate![buttonName]
                {
                    print("if let buttonObj KEYDOWN FOUND: \(buttonObj.buttonName)")
                    buttonObj.showButtonHighlighted = true
                    buttonObj.showButtonDown = true
                    buttonObj.needsDisplay = true
                    
                    return buttonObj
                }*/
           // }
            
        }
        else if(keyEvent.type == .keyUp)
        {
            
          //  if let buttonName : String = dictionaryOfButtonsAndEventCodes[lastPressedStringForKeyUp]
            //{
                /*
                print("processButtonEvent KEYUP buttonName \(buttonName)")
                if let buttonObj : KeyboardButton = buttonNamesAndObjectsFromAppDelegate![buttonName]
                {
                    print("if let buttonObj KEYUP FOUND: \(buttonObj.buttonName)")
                    buttonObj.showButtonHighlighted = false
                    buttonObj.showButtonDown = false
                    buttonObj.needsDisplay = true
                    
                    return buttonObj
                }*/
         //   }
            
        }
        
        return nil
    
    }
    
    

    
    override func awakeFromNib() {
      
        dictionaryOfButtonsAndEventCodes = appDelegate.dictionaryOfButtonsAndEventCodes;
        
        NotificationCenter.default.addObserver(self, selector:  #selector(handleKeyPress),
                                               name: NSNotification.Name(rawValue: "ButtonDown"), object: nil)

        NotificationCenter.default.addObserver(self, selector:  #selector(handleKeyPress),
                                               name: NSNotification.Name(rawValue: "ButtonUp"), object: nil)

        for buttonName in dictionaryOfButtonsAndEventCodes.values
        {

          NotificationCenter.default.addObserver(self, selector:  #selector(handleKeyPress),
                                                 name: NSNotification.Name(rawValue: buttonName), object: nil)

        }
        
        
    
      
        
        
    }
    
    */
    // insert dictionary here
    // with buttonName : eventCode .
    // this serves as the keyboard map
    // and awakeFromNib iterates through
    // the dictionary's keys to observe
    // the buttonpresses that occur that
    // send notifications
    
    // when the event code is hit by the keyboard,
    // it triggers the button, which is registered
    // in the DrawingEntityManager
    
    
    /*
     example:      "@^T" = Command-Control-Shift-t
     example:     "@$#5" = Command-Shift-Numpad 5
     
    "@" for Command
    “^” for Control
    “~” for Option
    “$” for Shift
    
     */
    
    var dictionaryOfButtonsAndEventCodesLeftHanded : [String:String] =
        [:];
    
  
  
    func buttonIsDrawingButton(_ buttonName : String) -> Bool
    {
        

        return false;
    }
    
    
}

 
 
