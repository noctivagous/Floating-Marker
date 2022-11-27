//
//  PaperLayer.swift
//  Floating Marker
//
//  Created by John Pratt on 1/10/21.
//

import Cocoa
import PencilKit
import Accelerate



class PaperLayer: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        
    }
    
    
    
    
    required init?(coder decoder: NSCoder) {
        super.init(coder:decoder)
        self.wantsLayer = true
    }
    
    init(frame:NSRect, name:String,isHidden:Bool,drawingPage:DrawingPage) {
        super.init(frame: frame)
        self.name = name
        self.isHidden = isHidden
        self.currentDrawingPage = drawingPage;
    }
    
    var name : String = "Default"

    @objc func changeHiddenStateFromLayersPanel(_ sender : NSSwitch)
    {
        self.isHidden = !(sender.state.boolValue)
        
    }



    var inkAndLineSettingsManager : InkAndLineSettingsManager?
    {
        get{
            return currentDrawingPage?.drawingPageController?.inkAndLineSettingsManager
        }
        
        
    }

    #if DEBUG
    var showPaperLayersDebug : Bool = false;
    #endif
    
    var selectedFMDrawables : [FMDrawable] = [];

    var pkDrawing : PKDrawing = PKDrawing()

    var pkDrawingImage : NSImage = NSImage()
    
    func remakePKDrawingImage()
    {
    
    //    pkDrawingImage = pkDrawing.image(from: self.bounds, scale: 1.0)
    
    /*self.enclosingScrollView!.magnification*/
      
    }
    
    
    var redisplayFMDrawableUnionedRect : NSRect = .zero;
  
    @objc func redisplayFMDrawableOnMainThreadFromBgCompletion()
    {
        self.lineWorkInteractionEntity!.isProcessingDeposit = false;
        self.lineWorkInteractionEntity!.replicationConfigurationViewController!.replicationDrawableLiveUnitOfReplicImage = nil;
        self.lineWorkInteractionEntity!.activePenLayer?.setNeedsDisplay(self.lineWorkInteractionEntity!.replicationConfigurationViewController!.calculatedRepetitionBoundsForReplicatedDrawableImg);
        self.setNeedsDisplay(self.redisplayFMDrawableUnionedRect)
    
    }

    // MARK: -
    // MARK: LOADING OF ORDERING ARRAY INTO DYNAMIC TREE
    func loadOrderingArrayIntoDynamicTree()
    {
        
        self.dynamicTreeIsInUse = false;

        DispatchQueue.main.async
        {
            self.dynamicTree = DynamicTree();
            
            for drawable in self.orderingArray
            {
                drawable.drawingOrderIndex = self.orderingArray.firstIndex(where: {$0 === drawable})!
                drawable.treeProxy = self.dynamicTree.createProxy(aabb: drawable.renderBounds(), item: drawable)
            }
            
            self.dynamicTreeIsInUse = true;
            
        }
    
    }
    
    // For stamping operations
    func basicAddDrawable(drawable: FMDrawable)
    {
        if(self.isHidden)
        {
            self.isHidden.toggle()
        }
        
        
        
        self.reindexOrderingArrayDrawables()
        
        orderingArray.append(drawable)
        
        if(dynamicTreeIsInUse)
        {
            drawable.drawingOrderIndex = orderingArray.firstIndex(where: {$0 === drawable})!
            drawable.treeProxy = dynamicTree.createProxy(aabb: drawable.renderBounds(), item: drawable)
        }
        //print("added: \(drawable)")
        //print(drawable.drawingOrderIndex)
        
        self.setNeedsDisplay(drawable.renderBounds().insetBy(dx: -5, dy: -5))
        

    }
    
    // MARK: UPDATE DRAWABLE FOR DYNAMIC TREE
    func updateDrawableForDynamicTree(_ drawable : FMDrawable, oldRect: NSRect)
    {
        if(self.dynamicTreeIsInUse)
        {
            _ = dynamicTree.moveProxy(index: drawable.treeProxy, aabb: drawable.renderBounds())
            
            self.setNeedsDisplay(drawable.renderBounds().union(oldRect));
        }
    }
    
    
    
    // MARK: -
    // MARK: ADD DRAWABLES
    
    func addFMDrawable(_ fmDrawable : FMDrawable, doBackgroundThread : Bool)
    {
        
        self.setNeedsDisplay(fmDrawable.renderBounds())
        
        if let fmStroke = fmDrawable as? FMStroke
        {
            fmStroke.setToIsFinished();
            
            
            if(inkAndLineSettingsManager!.connectLivePathToPaths && fmStroke.fmInk.isUniformPathThatIsStrokeOnly)
            {
                // if either fmStroke.lastPKCGPoint or fmStroke.firstPKCGPoint
                // overlaps the
                // first or last point of the first found
                // drawable on the layer,
                // append the fmStroke (possibly by reversing
                // the already-deposited path first)
                // to the already-deposited path.
                // then, return this function (after making an undo operation setup).
                // check if first point overlaps terminal point
                // of an object on the page.
                let drawableFirstOrLastPointDoesOverlapWithTerminalPoint =  { () -> (didHit: Bool, pointHitType: PointHitType, hitDrawable: FMDrawable, isFirstPoint:Bool,didCloseThePath:Bool) in
                    
                    let pForTest = fmStroke.pointAtIndex(0);
                    print("test: \(pForTest)")
                    let hitTestResult = self.fmDrawableDoesHaveOverlappingTerminal(fmDrawableToTest: fmStroke)
                    
                    //self.hitTestForObjectStrokePoints(boundsForQuery: (self.enclosingScrollView?.documentVisibleRect)!, pointForHitTest: fmStroke.pointAtIndex(0));
                    
                    
                    
                    var didHit = false;
                    if((hitTestResult.pointHitType == BeginningPointHit) || (hitTestResult.pointHitType == EndPointHit))
                    {
                        didHit = true;
                    }
                    else
                    {
                        print(" didHit \(didHit) pointHitType \(hitTestResult.pointHitType)");
                    }
                    
                    
                    return (didHit, hitTestResult.pointHitType, hitTestResult.hitDrawable ?? FMDrawable(),hitTestResult.didHitFirstTerminal,hitTestResult.didCloseThePath );
                }
                
                
                let firstOrLastPointDoesOverlapTuple = drawableFirstOrLastPointDoesOverlapWithTerminalPoint();
                
                if(firstOrLastPointDoesOverlapTuple.didHit)
                {
                    
                    
                    if(firstOrLastPointDoesOverlapTuple.pointHitType == BeginningPointHit)
                    {
                        if(firstOrLastPointDoesOverlapTuple.isFirstPoint)
                        { firstOrLastPointDoesOverlapTuple.hitDrawable.reversePath();
                        }
                        firstOrLastPointDoesOverlapTuple.hitDrawable.appendThroughOmitFirstMoveToOfIncomingPath(incomingPath: fmStroke);
                        
                        
                        
                        
                    }
                    
                    if(firstOrLastPointDoesOverlapTuple.pointHitType == EndPointHit)
                    {
                        
                        if(firstOrLastPointDoesOverlapTuple.isFirstPoint == false)
                        { firstOrLastPointDoesOverlapTuple.hitDrawable.reversePath();
                        }
                        // print(firstPointDoesOverlap.pointHitType)
                        firstOrLastPointDoesOverlapTuple.hitDrawable.appendThroughOmitFirstMoveToOfIncomingPath(incomingPath: fmStroke);
                        
                        
                        
                    }
                    
                    
                    if(firstOrLastPointDoesOverlapTuple.didCloseThePath)
                    {
                        firstOrLastPointDoesOverlapTuple.hitDrawable.close();
                    }
                    
                    
                    
                    
                    
                    if(dynamicTreeIsInUse)
                    {
                        _ = dynamicTree.moveProxy(index: firstOrLastPointDoesOverlapTuple.hitDrawable.treeProxy, aabb: firstOrLastPointDoesOverlapTuple.hitDrawable.renderBounds())
                    }
                    
                    self.setNeedsDisplay(firstOrLastPointDoesOverlapTuple.hitDrawable.renderBounds().insetBy(dx: -5, dy: -5))
                    
                    return;
                    
                }// END if(firstOrLastPointDoesOverlapTuple.didHit)
                
            }
            //END if(fmStroke.fmInk.isUniformPathThatIsStrokeOnly)
        }
        
        
        // MARK: ADDITION TO THE STORAGE
        // MARK: SET UP UNDO
        let undoManager : UndoManager = self.parentDocument!.undoManager!
        
        undoManager.registerUndo(withTarget: self) { (self) in
            self.removeDrawable(fmDrawable)
        }
        
        undoManager.setActionName("Draw \(fmDrawable.shapeName)")
        
        if(undoManager.isUndoing)
        {
            undoManager.setActionName("Delete \(fmDrawable.shapeName)")
        }
        
        
        
        orderingArray.append(fmDrawable)
        self.reindexOrderingArrayDrawables()


        if(dynamicTreeIsInUse)
        {
            fmDrawable.drawingOrderIndex = orderingArray.firstIndex(where: {$0 === fmDrawable})!
            fmDrawable.treeProxy = dynamicTree.createProxy(aabb: fmDrawable.renderBounds(), item: fmDrawable)
        }
        self.setNeedsDisplay(fmDrawable.renderBounds().insetBy(dx: -5, dy: -5))
        
        
        
        
        if(inkAndLineSettingsManager!.showAllControlPoints)
        {
            self.setNeedsDisplay(fmDrawable.controlPointsBoundsForBSpline().union(fmDrawable.renderBounds()))
        }
        else
        {
            self.setNeedsDisplay(fmDrawable.renderBounds().insetBy(dx: -15, dy: -15))
        }
        
        
        if let fmStroke = fmDrawable as? FMStroke
        {
            
            doProcessingOfFMStroke(fmStroke : fmStroke, doBackgroundThread: doBackgroundThread)
            
        }// END if let fmStroke == fmDrawable
        
        
        
        
        
    }


    func doProcessingOfFMStroke(fmStroke : FMStroke, doBackgroundThread : Bool)
    {
        let oldRect = fmStroke.renderBounds();
          
            let distForInterpToUse : CGFloat = (fmStroke.fmInk.brushTip.isUniform) ? self.inkAndLineSettingsManager!.distanceForUniformFinalInterpolation : self.inkAndLineSettingsManager!.distanceForOvalAndChiselFinalInterpolation
            
            let simplificationToleranceToUse = (fmStroke.fmInk.brushTip.isUniform) ?
             inkAndLineSettingsManager!.finalSimplificationToleranceForUniform : inkAndLineSettingsManager!.finalSimplificationToleranceForOvalAndChisel
             
            
             
            if(doBackgroundThread)
            {
                //let drawingPage = self.superview as? DrawingPage
            
                fmStroke.assembleFinalBezierPathOnBackgroundThread(distanceForInterpolation: distForInterpToUse, simplificationTolerance:simplificationToleranceToUse)
                { (finishedFMStroke) in
                    
                    finishedFMStroke.needsReprocessing = false;
                    finishedFMStroke.isFinished = true;
                    
                    //drawingPage?.drawingPageController?.fmDocument.updateSVGPreviewLive();
                    repl: if(self.inkAndLineSettingsManager!.replicationModeIsOn)
                    {

                        let arrayOfReplicated = self.lineWorkInteractionEntity!.replicationConfigurationViewController!.replicatedFMDrawable(finishedFMStroke as FMDrawable, replicationMode: self.inkAndLineSettingsManager!.replicationMode)
                        
                        var doUnion = false;
                        
                        guard arrayOfReplicated.isEmpty == false
                        else {
                            break repl
                        }
                    
                    
                        if((arrayOfReplicated.count > 1) && (arrayOfReplicated[0].hasClose) )
                        {
                            if(pathsIntersect(path1: arrayOfReplicated[0], path2: arrayOfReplicated[1]))
                            {
                                doUnion = true;
                            }
                        }
                        
                        if(doUnion)
                        {
                            var p = NSBezierPath();
                            p.append(arrayOfReplicated[0])
                            
                            for i in 1..<arrayOfReplicated.count
                            {
                                p = p.fb_union(arrayOfReplicated[i])
                             
                            }
                            
                            finishedFMStroke.removeAllPoints();
                            finishedFMStroke.append(p);
                            
                        }
                        else
                        {
                            finishedFMStroke.removeAllPoints();

                            arrayOfReplicated.forEach
                            {
                                fmDrawable in
                                
                                finishedFMStroke.append(fmDrawable);
                            }
                        }
                       
                       
                        
                    }
                    
                    
                    self.redisplayFMDrawableUnionedRect = NSUnionRect(oldRect, finishedFMStroke.renderBounds());
                    self.performSelector(onMainThread: #selector(self.redisplayFMDrawableOnMainThreadFromBgCompletion), with: nil, waitUntilDone: false)
                    
                }
                
                
            }
            else
            {
                
//                DispatchQueue.main.async
//                {
                
                    fmStroke.isFinished = true;
                        fmStroke.needsReprocessing = false;

                    fmStroke.makeFMStrokeFinalSegmentBased(distanceForInterpolation:distForInterpToUse, uniformTipSimplificationTolerance: simplificationToleranceToUse, tip:fmStroke.fmInk.brushTip)
                    
                    // ----
                    // uniform is simplified in makeFMStrokeFinalSegmentBased(
                    // ----
                    if(fmStroke.fmInk.brushTip.isUniform == false)
                    {
                        fmStroke.reducePointsOfPathForNonUniform(simplificationTolerance: self.inkAndLineSettingsManager!.finalSimplificationToleranceForOvalAndChisel);
                    }
                    self.setNeedsDisplay(fmStroke.bounds)
                    
                   // if let drawingPage = self.superview as? DrawingPage
                   // {
                       // drawingPage.drawingPageController?.fmDocument.updateSVGPreviewLive();
                   // }
                    
//                }
            }
                
    
            if(fmStroke.fmInk.gkPerlinNoiseWithAmplitude != nil)
            {
                self.inkAndLineSettingsManager!.noiseConfigurationViewController!.updateSeedIfNeeded()
            }
    }
    
    func replicateDrawablesAndAddToLayer(drawables:[FMDrawable])
    {
        let r = replicateDrawables(drawables: drawables)
        
        do {
            try self.addDrawablesForPaste(drawablesArray: r, actionName: "Replicate")

        } catch  {
            
        }
    }
    
    func replicateDrawables(drawables:[FMDrawable]) -> [FMDrawable]
    {
        
        var drawablesToReturn : [FMDrawable] = [];
        
        
        for drawableToReplicate in drawables
        {
            let arrayOfReplicated = self.lineWorkInteractionEntity!.replicationConfigurationViewController!.replicatedFMDrawable(drawableToReplicate as FMDrawable, replicationMode: self.inkAndLineSettingsManager!.replicationMode)
            
            
            
            if((inkAndLineSettingsManager!.replicationOutputIsSingleDrawable == false) || (drawableToReplicate is FMImageDrawable))
            {
            
                drawablesToReturn.append(contentsOf: arrayOfReplicated)
                continue;
            }
            
            
            var doUnion = false;
            
            
            // only union FMStrokes because other shapes may have too many points.
            if((drawableToReplicate is FMStroke) && (arrayOfReplicated[0].hasClose) && (arrayOfReplicated.count > 1))
            {
                if(pathsIntersect(path1: arrayOfReplicated[0], path2: arrayOfReplicated[1]))
                {
                    doUnion = true;
                }
            }
            
            if(doUnion)
            {
                var p = NSBezierPath();
                p.append(arrayOfReplicated[0])
                
                for i in 1..<arrayOfReplicated.count
                {
                    p = p.fb_union(arrayOfReplicated[i])
                    
                }
                
                drawableToReplicate.removeAllPoints();
                drawableToReplicate.append(p);
                
            }
            else
            {
                arrayOfReplicated.forEach
                {
                    fmDrawable in
                    drawableToReplicate.append(fmDrawable);
                }
            }
            
        }
        
        
        
        
        return drawablesToReturn;
        
    }
    
        // MARK: ---  ADD DRAWABLE TO DRAWINGLAYER
    
    func addDrawablesForCutUndo(_ drawablesToAdd : [FMDrawable])
    {
   
      
        for drawable in drawablesToAdd
        {
            #if DEBUG
            assert(drawable.elementCount > 0)
            #endif
           
            orderingArray.append(drawable)
            if(dynamicTreeIsInUse)
            {
                drawable.drawingOrderIndex = orderingArray.firstIndex(where: {$0 === drawable})!
                drawable.treeProxy = dynamicTree.createProxy(aabb: drawable.renderBounds(), item: drawable)
            }
            
            self.setNeedsDisplay(drawable.renderBounds())
        }
        
        reindexOrderingArrayDrawables()
        
        
        self.makeArrayTheSelectedDrawables(arrayToMakeSelected: drawablesToAdd)
        
    
        let undoManager : UndoManager = self.parentDocument!.undoManager!
 
            // for redo
            let dA = drawablesToAdd
        
            undoManager.registerUndo(withTarget: self) { (self) in

            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects(dA)
            self.makeArrayTheSelectedDrawables(arrayToMakeSelected: dA)
      
            self.cutOperationForSelectedDrawables()
            
            }
        
    }
    
    func addDrawableByUnion(_ drawable : FMDrawable, toLastDrawnOnly:Bool)
    {
    
        if let fmStroke = drawable as? FMStroke
        {
            doProcessingOfFMStroke(fmStroke : fmStroke, doBackgroundThread: false)
            
            
        }// END if let fmStroke == fmDrawable
        

        
        var layerDrawablesToBeReplacedByUnion : [FMDrawable] = [];
        
        let boundsOfDrawableBeingAdded = drawable.renderBounds();
        
        let unionResult : NSBezierPath  = NSBezierPath();
        
        var doUnion = false;
        
        var arrayOfLayerDrawablesThatOverlapWithDrawable : [FMDrawable] = [];
        
        var affectedSelectedDrawables : Bool = false;
        
        var didUnion = false;
        
        if(selectedDrawables.isEmpty == false)
        {
            arrayOfLayerDrawablesThatOverlapWithDrawable = selectedDrawables;
            affectedSelectedDrawables = true;
            
        }
        else if(toLastDrawnOnly == false)
        {
            if(self.dynamicTreeIsInUse)
            {
                arrayOfLayerDrawablesThatOverlapWithDrawable = dynamicTree.queryToGetArray(aabb: boundsOfDrawableBeingAdded)
                
            }
            else
            {
                
                arrayOfLayerDrawablesThatOverlapWithDrawable = orderingArray.filter { (fmDrawable) -> Bool in
                    NSIntersectsRect(fmDrawable.renderBounds(), boundsOfDrawableBeingAdded)
                }
                
            }
            
            arrayOfLayerDrawablesThatOverlapWithDrawable.sort(by: { $0.drawingOrderIndex < $1.drawingOrderIndex })
            
            guard arrayOfLayerDrawablesThatOverlapWithDrawable.isEmpty == false else
            {
                self.addFMDrawable(drawable, doBackgroundThread: true)
                
                return
            }
        }
        else
        {
            guard orderingArray.isEmpty == false else { return; }
            
            arrayOfLayerDrawablesThatOverlapWithDrawable.append(orderingArray.last!)
        }
        
        
        unionResult.append(drawable);
        
        var aggSettings : FMDrawableAggregratedSettings = .init(fmDrawable: drawable);
        
        arrayOfLayerDrawablesThatOverlapWithDrawable.forEach { (drawable) in
            
            var unionResult2 = NSBezierPath()
            
            if(pathsIntersect(path1: unionResult, path2: drawable))
            //if((unionResult.allIntersections(with: drawable).count > 0) || NSContainsRect(unionResult.bounds, drawable.renderBounds()))
            {
            
                
                if((doUnion == false) && inkAndLineSettingsManager!.receiverDeterminesStyle)
                {
                
                    aggSettings = FMDrawableAggregratedSettings.init(fmDrawable: drawable)
                      

                }
            
                doUnion = true;
                unionResult2 = drawable.fb_union(unionResult)
                unionResult.removeAllPoints()
                unionResult.append(unionResult2)
                
                
                          
                layerDrawablesToBeReplacedByUnion.append(drawable);
            }
         
            
            
        }
        
        //   makeArrayTheSelectedDrawables(arrayToMakeSelected: finalSelected);
        
        
        if(doUnion)
        {
        
            if(affectedSelectedDrawables)
            {
                clearOutSelections()
            }
            
            var d = FMDrawable()
            
           
            
            aggSettings.applyToDrawable(fmDrawable: &d)

            
            d.append(unionResult)
            d.windingRule = NSBezierPath.WindingRule.evenOdd
         
            for a in layerDrawablesToBeReplacedByUnion
            {
                self.removeDrawable(a)
            }
            
           // self.deleteSelectedDrawables()
            self.addFMDrawable(d, doBackgroundThread: true)
            
            if(affectedSelectedDrawables)
            {
                makeArrayTheSelectedDrawables(arrayToMakeSelected: [d])
            }
            
            didUnion = true;
        }
        else
        {
            self.addFMDrawable(drawable, doBackgroundThread: true)
            //self.basicAddDrawable(drawable: drawable);
        }
        
        if((didUnion == false) && inkAndLineSettingsManager!.depositIfNoOverlap)
        {
            addFMDrawable(drawable, doBackgroundThread: true)
            
        }
        
        if((didUnion == false) && (inkAndLineSettingsManager!.depositIfNoOverlap == false))
        {
            flashObjectsOnLayerForCombinatoricsWarning(selectedDrawables, autoreverse: true,duration: 0.17,fillColor:NSColor.red.withAlphaComponent(0.5))

            
        }
        
    }
 
    
    // divides shapes underneath by path
    func addDrawableByDivision(_ drawable : FMDrawable)
    {
    
    }
    
    func addDrawableBySubtraction(_ drawable : FMDrawable)
    {
    
        if let fmStroke = drawable as? FMStroke
        {
            doProcessingOfFMStroke(fmStroke : fmStroke, doBackgroundThread: false)
        }// END if let fmStroke == fmDrawable


        var drawablesToDelete : [FMDrawable] = [];
        
        // make new array
        // containing what selected drawables
        // intersect in terms of bounds rect,
        // then check for path segment intersection
        
        var doSubtraction : Bool = false
   
        let boundsOfDrawableForSubtraction = drawable.renderBounds();
       
        var arrayOfLayerDrawablesThatOverlapWithDrawable : [FMDrawable] = [];
        
        var affectedSelectedDrawables : Bool = false;
        
        if(selectedDrawables.isEmpty == false)
        {
            arrayOfLayerDrawablesThatOverlapWithDrawable = selectedDrawables;
            affectedSelectedDrawables = true;
        }
        else
        {
            if(self.dynamicTreeIsInUse)
            {
                arrayOfLayerDrawablesThatOverlapWithDrawable = dynamicTree.queryToGetArray(aabb: boundsOfDrawableForSubtraction)
                
            }
            else
            {
                
                arrayOfLayerDrawablesThatOverlapWithDrawable = orderingArray.filter { (fmDrawable) -> Bool in
                    NSIntersectsRect(fmDrawable.renderBounds(), boundsOfDrawableForSubtraction)
                }
                
            }
            arrayOfLayerDrawablesThatOverlapWithDrawable.sort(by: { $0.drawingOrderIndex < $1.drawingOrderIndex })
        }
        
       // let drawableCharacteristics = drawable.drawableCharacteristics();
        
        var didSubtraction : Bool = false
        
        let subtractionResult = NSBezierPath()
        
        var aggSettings : FMDrawableAggregratedSettings = FMDrawableAggregratedSettings.init(fmDrawable: drawable);
        
        for d in arrayOfLayerDrawablesThatOverlapWithDrawable
        {
            var subtractionResult2 = NSBezierPath()
            
            subtractionResult.removeAllPoints();
            subtractionResult.append(drawable)
            
            
            
            if(pathsIntersect(path1: subtractionResult, path2: d))
            //if((subtractionResult.allIntersections(with: d).count > 0) || NSContainsRect(subtractionResult.bounds, d.bounds))
            {
                
                if((doSubtraction == false) && inkAndLineSettingsManager!.receiverDeterminesStyle)
                {
                    aggSettings = FMDrawableAggregratedSettings.init(fmDrawable: d)
                }
                
                doSubtraction = true
                
                subtractionResult2 = d.fb_difference(subtractionResult)
                subtractionResult.removeAllPoints()
                subtractionResult.append(subtractionResult2)
                
                if(doSubtraction && (subtractionResult.elementCount > 0) )
                {
                    
                    if(affectedSelectedDrawables)
                    {
                        clearOutSelections()
                    }
                    
                    let d2Drawable = FMDrawable()
                    
                    
                    
                    d2Drawable.append(subtractionResult)
           
           
                    if(inkAndLineSettingsManager!.receiverDeterminesStyle == false)
                    {
                        aggSettings = FMDrawableAggregratedSettings.init(fmDrawable: drawable)
                    }
                    
                    
                  
                    
                    drawablesToDelete.append(d)
                    
                    
                    // SUBTRACTED RESULT ARRAY
                    var subtractedResultArray : [FMDrawable] = [];
                    
                    // SEPARATE SUBTRACTION PIECES
                    if(inkAndLineSettingsManager!.separateSubtractionPieces)
                    {
                        // --------
                        // if there is more than one subpath
                        if(d2Drawable.countSubPathsNCT() > 1)
                        {
                            let baseShapeForSubtractedResult = FMDrawable();
                        
                            let subpaths = d2Drawable.subPathsNCT();
                            
                            // --------
                            // BASE SHAPE CARRIES SUBPATHS
                            // THAT SIT INSIDE IT.
                            baseShapeForSubtractedResult.append(subpaths[0])
                            subtractedResultArray.append(baseShapeForSubtractedResult);
                            
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

                    
                            }// END for subpath in d2.subPathsNCT()
                        }
                        else
                        {
                            // d2.countSubPathsNCT() was not greater
                            // than 1 after checking that separateSubtractionPieces
                            // is turned on.
                            let sResult = FMDrawable();
                            sResult.append(d2Drawable)
                            subtractedResultArray.append(sResult)
                        }
                        
                    }
                    else
                    {
                            let sResult = FMDrawable();
                            sResult.append(d2Drawable)
                            subtractedResultArray.append(sResult)
                    }
                
                    for subtractedResultDrawable in subtractedResultArray
                    {
                        var sResult = FMDrawable();
                        sResult.append(subtractedResultDrawable)
                        
                        aggSettings.applyToDrawable(fmDrawable: &sResult)

                        self.addFMDrawable(sResult, doBackgroundThread: true)
                    }
                
                    if(affectedSelectedDrawables)
                    {
                        makeArrayTheSelectedDrawables(arrayToMakeSelected: subtractedResultArray)
                    }
                    
                    didSubtraction = true;
                 }
                
                
            }

        }
        
        removeArrayOfDrawables(drawablesToDelete);
                
                
        if((didSubtraction == false) && inkAndLineSettingsManager!.depositIfNoOverlap)
        {
        
         
            
            addFMDrawable(drawable, doBackgroundThread: true)
            
        }
        
        if((didSubtraction == false) && (inkAndLineSettingsManager!.depositIfNoOverlap == false))
        {
            flashObjectsOnLayerForCombinatoricsWarning(selectedDrawables, autoreverse: true,duration: 0.17,fillColor:NSColor.red.withAlphaComponent(0.5))

            
        }
    }
    
    func addDrawableByIntersection(_ drawable : FMDrawable)
    {
    
        if let fmStroke = drawable as? FMStroke
        {
            doProcessingOfFMStroke(fmStroke : fmStroke, doBackgroundThread: false)
        }// END if let fmStroke == fmDrawable
        
        

         var drawablesToDelete : [FMDrawable] = [];
        
        // make new array
        // containing what selected drawables
        // intersect in terms of bounds rect,
        // then check for path segment intersection
        
        var doIntersection : Bool = false
   
        var aggSettings : FMDrawableAggregratedSettings = FMDrawableAggregratedSettings.init(fmDrawable: drawable);
   
        let boundsOfDrawableForIntersection = drawable.renderBounds();
        
        var arrayOfLayerDrawablesThatOverlapWithDrawable : [FMDrawable] = [];
       
        var affectedSelectedDrawables : Bool = false;
        
        if(selectedDrawables.isEmpty == false)
        {
            arrayOfLayerDrawablesThatOverlapWithDrawable = selectedDrawables;
            affectedSelectedDrawables = true;
        }
        else
        {
            if(self.dynamicTreeIsInUse)
            {
                arrayOfLayerDrawablesThatOverlapWithDrawable = dynamicTree.queryToGetArray(aabb: boundsOfDrawableForIntersection)
                
            }
            else
            {
                
                arrayOfLayerDrawablesThatOverlapWithDrawable = orderingArray.filter { (fmDrawable) -> Bool in
                    NSIntersectsRect(fmDrawable.renderBounds(), boundsOfDrawableForIntersection)
                }
                
            }
            
            
            arrayOfLayerDrawablesThatOverlapWithDrawable.sort(by: { $0.drawingOrderIndex < $1.drawingOrderIndex })
            
        }
        
       
        let intersectionResult = NSBezierPath()
        
        var didIntersection : Bool = false;
        
        for d in arrayOfLayerDrawablesThatOverlapWithDrawable
        {
            var intersectionResult2 = NSBezierPath()
            
            intersectionResult.removeAllPoints();
            intersectionResult.append(drawable)
 
            
 
            if(pathsIntersect(path1: intersectionResult, path2: d))
            //if(intersectionResult.allIntersections(with: d).count > 0)
            {
                
                
               
                if((doIntersection == false) && inkAndLineSettingsManager!.receiverDeterminesStyle)
                {
                    aggSettings = FMDrawableAggregratedSettings.init(fmDrawable: drawable)
                }
            
                doIntersection = true
                intersectionResult2 = d.fb_intersect(intersectionResult)
                intersectionResult.removeAllPoints()
                intersectionResult.append(intersectionResult2)
                
                if(doIntersection && (intersectionResult.elementCount > 0) )
                {
                    if(affectedSelectedDrawables)
                    {
                        clearOutSelections()
                    }
                    
                    var d2Drawable = FMDrawable()
                    d2Drawable.append(intersectionResult)
                    
                    
                    aggSettings.applyToDrawable(fmDrawable: &d2Drawable)
                    
                    drawablesToDelete.append(d)
                    
                    self.addFMDrawable(d2Drawable, doBackgroundThread: true)
                    
                    if(affectedSelectedDrawables)
                    {
                        makeArrayTheSelectedDrawables(arrayToMakeSelected: [d])
                    }
                    
                    didIntersection = true
                }
                
                
            }

        }
        
        removeArrayOfDrawables(drawablesToDelete);
        
        if((didIntersection == false) && inkAndLineSettingsManager!.depositIfNoOverlap)
        {
            addFMDrawable(drawable, doBackgroundThread: true)
                    
        }
        
        if((didIntersection == false) && (inkAndLineSettingsManager!.depositIfNoOverlap == false))
        {
            flashObjectsOnLayerForCombinatoricsWarning(selectedDrawables, autoreverse: true,duration: 0.17,fillColor:NSColor.red.withAlphaComponent(0.5))

            
        }

     
    }
    
    func addDrawableAsShadingShape(_ drawableToActAsShadingShape : FMDrawable)
    {
        
        // If there are no selected drawables,
        // search the tree for all drawables intersecting the bounds of the shading drawable
        if((self.hasSelectedDrawables == false))
        {
       
            var drawablesToReceiveShadingShape : [FMDrawable] = [];
            
            if(self.dynamicTreeIsInUse)
            {
                drawablesToReceiveShadingShape = dynamicTree.queryToGetArray(aabb: drawableToActAsShadingShape.renderBounds())
                
            }
            else
            {
                
                drawablesToReceiveShadingShape = orderingArray.filter { (fmDrawable) -> Bool in
                    NSIntersectsRect(fmDrawable.renderBounds(), drawableToActAsShadingShape.renderBounds())
                }
                
            }
            
            
            if((drawablesToReceiveShadingShape.isEmpty == false) )
            {
                var rectForDrawingLayerUpdate = NSRect.zero;
                
                // set to actsAsShadingShape
                drawableToActAsShadingShape.actsAsShadingShape = true;
                //drawableToActAsShadingShape.actsAsShadingShapeDictionary = inkAndLineSettingsManager!.currentShadingShapeSettingsAsDictionary;
                
                for d in drawablesToReceiveShadingShape
                {
                    let copyOfDrawableForShadingShape = drawableToActAsShadingShape.copy() as! FMDrawable
                    
                    if let fmStroke = copyOfDrawableForShadingShape as? FMStroke
                    {
                        doProcessingOfFMStroke(fmStroke : fmStroke, doBackgroundThread: true)
                    }
                    
                    d.shadingShapesArray!.append(copyOfDrawableForShadingShape);
                    rectForDrawingLayerUpdate = (rectForDrawingLayerUpdate != NSRect.zero) ? rectForDrawingLayerUpdate.union(d.renderBounds()) : d.renderBounds();
                    
                }
                
                self.setNeedsDisplay(rectForDrawingLayerUpdate);
                inkAndLineSettingsManager!.drawingLayerDidDepositShadingShape(self);
                
            }
            
        }
        // if there are selected drawables, only
        // embed the shading shapes into them
        else if(self.hasSelectedDrawables)
        {
            
            // set to actsAsShadingShape
            drawableToActAsShadingShape.actsAsShadingShape = true;
            // apply shadingShape
            //drawableToActAsShadingShape.actsAsShadingShapeDictionary = inkAndLineSettingsManager!.currentShadingShapeSettingsAsDictionary;
            
        
            
            for d in selectedDrawables
            {
                
                if(d.bounds.intersects(drawableToActAsShadingShape.renderBounds()))
                {
                
                   let copyOfDrawableForShadingShape = drawableToActAsShadingShape.copy() as! FMDrawable
                    
                    if let fmStroke = copyOfDrawableForShadingShape as? FMStroke
                    {
                        doProcessingOfFMStroke(fmStroke : fmStroke, doBackgroundThread: true)
                    }
                    
                    
                    d.shadingShapesArray!.append(copyOfDrawableForShadingShape);
                    self.setNeedsDisplay(d.renderBounds());
                    
                    
                }
                
                //print(firstSelectedDrawable.shadingShapesDictionary)
            }
            
            self.redisplaySelectedTotalRegionRect();
            
            inkAndLineSettingsManager!.drawingLayerDidDepositShadingShape(self);
            
        }
        
        
    }
    
    // MARK: -
    // MARK: PATH OPERATIONS()
    
    func separateSubpaths()
    {
        if(self.selectedDrawables.count > 1)
        {
            /*
            for d in selectedDrawables
            {
                // let outsideSubpathsArray = layerDrawable.extractAnySubpathsWithNoOverlapWithTheInitialPath();
            }*/
        }
    }
    
    func joinSelectedPaths()
    {
        if(self.selectedDrawables.count > 1)
        {

            let theDrawable = selectedDrawables[0];
            let oldRect = theDrawable.renderBounds();
            
            selectedDrawables.removeFirst();
            //var drawablesToRemove : [FMDrawable] = [];
            
            for i in 0..<selectedDrawables.count
            {
                theDrawable.append(selectedDrawables[i])
                //drawablesToRemove.append(selectedDrawables[i])
            }

            let a = selectedDrawables;
            clearOutSelections();
            removeArrayOfDrawables(a);
            
            
            
            updateDrawableForDynamicTree(theDrawable, oldRect: oldRect);
            self.setNeedsDisplay(oldRect.union(theDrawable.renderBounds()));
            
            makeArrayTheSelectedDrawables(arrayToMakeSelected: [theDrawable]);
            
        }
    
    }

    // MARK: -
    // MARK: DRAW()
    
    override func draw(_ dirtyRect: NSRect)
    {
        /*
        guard self.enclosingScrollView != nil else {

           fatalError("self.enclosingScrollView == nil")
           
        }
        */
        
    
        //NSColor.green.setFill()
        //self.bounds.insetBy(dx: 10, dy: 10).frame()
    
    // This view is not flipped because that is not
    // necessary for drawing the image, but all of
    // the strokes inside pkDrawing are flipped.
    
    // pkDrawingImage.draw(at: dirtyRect.origin, from: dirtyRect, operation: NSCompositingOperation.sourceOver, fraction: 1.0)


//        var lastIntervaledPointAngle : CGFloat = 0;

//        var angleIsDecreasing : Bool = false;

        let drawAllControlPointsSetting : Bool? = self.inkAndLineSettingsManager?.showAllControlPoints
        
        var arrayOfFMDrawablesToDisplay : [FMDrawable] = [];
        if(dynamicTreeIsInUse)
        {
            arrayOfFMDrawablesToDisplay = dynamicTree.queryToGetArray(aabb: dirtyRect)
            
        }
        else if(dynamicTreeIsInUse == false)
        {
            
            arrayOfFMDrawablesToDisplay = orderingArray.filter { (fmDrawable) -> Bool in
                NSIntersectsRect(fmDrawable.renderBounds(), dirtyRect)
            }
            
            
        }
        
        for fmDrawable in arrayOfFMDrawablesToDisplay
        {
            
            var renderBounds = fmDrawable.renderBounds()
            
            if(drawAllControlPointsSetting != nil)
            {
                if(drawAllControlPointsSetting!)
                {
                    renderBounds = fmDrawable.controlPointsBoundsForBSpline().union(renderBounds);
                }
            }
            
            
            fmDrawable.display();
            
            if(drawAllControlPointsSetting != nil)
            {
                if(drawAllControlPointsSetting!)
                {
                    fmDrawable.displayControlPoints();
                }
            }
            
            if(fmDrawable.isBeingCarted)
            {
                if let img = NSImage.init(named: NSImage.Name.init(stringLiteral: "carting_symbol_medium"))
                {
                    // img.draw(in: fmDrawable.renderBounds())
                    
                    var r = NSMakeRect(0, 0, 100, 100)
                    if((r.width >= renderBounds.width) && (r.height >= renderBounds.height))
                    {
                        let length = max(renderBounds.width, renderBounds.height)
                        r.size.width = length
                        r.size.height = length
                    }
                    
                    r = CentreRectInRect(r, renderBounds)
                    
                    
                    img.draw(in: r, from: .zero, operation: NSCompositingOperation.sourceOver, fraction: 0.3)
                    
                    if(inkAndLineSettingsManager != nil)
                    {
                        if(inkAndLineSettingsManager!.combinatoricsModeIsOn || inkAndLineSettingsManager!.unionWithLastDrawnShapeForDrawing)
                        {
                            let p2 = NSBezierPath();
                            p2.move(to: r.topMiddle())
                            p2.line(to: r.middleRight())
                            p2.line(to: r.bottomMiddle())
                            p2.line(to: r.middleLeft())
                            p2.close();
                            NSColor.orange.withAlphaComponent(0.2).setFill()
                            p2.fill()
                            
                            //r.fill();
                        }
                    }
                    //                    var r = NSMakeRect(0, 0, 52, 52)
                    //                    img.draw(at: fmDrawable.renderBounds().centroid(), from: NSMakeRect(0, 0, 10, 10), operation: NSCompositingOperation.sourceOver, fraction: 1.0)
                    //                    img.draw(in: fmDrawable.renderBounds())
                }
            }
            
            
            
        }
        
        
        #if DEBUG
        if(showPaperLayersDebug)
        {
            let debugInfoLine = "\(self.name) : \(orderingArray.count) obj."
            
            if let p = self.superview as? DrawingPage
            {
                
                if let i = p.paperLayers.firstIndex(of: self)
                {
                
                    let r = NSMakeRect(10, CGFloat(i) * 23, 3000, 25)
                    debugInfoLine.drawStringInsideRectWithMenlo(fontSize: 15, textAlignment: NSTextAlignment.left, fontForegroundColor: NSColor.white, rect: r)
                    
                }
                else
                {
//                    print(p.paperLayers)
                    
                    
                }
            }
        
        
        }
        #endif
        
       /*
        for stroke in pkDrawing.strokes
        {
            var a1Points : [NSPoint] = [];
            var a2Points : [NSPoint] = [];
            var aNormalPoints : [NSPoint] = [];
            
            var b1Points : [NSPoint] = [];
            var b2Points : [NSPoint] = [];
            var bNormalPoints : [NSPoint] = [];
        
            
        
        
            let path = stroke.path
         
         //   for pkPoint in path.interpolatedPoints(by: PKStrokePath.InterpolatedSlice.Stride.parametricStep(stepSizeA))
         
            var counter = 0;
            let strokePath = NSBezierPath();
            
            let outlinePath1 = NSBezierPath();
            let outlinePath2green = NSBezierPath();
            let outlinePath3yellow = NSBezierPath();
            let outlinePath4brown = NSBezierPath();
            
             let outlinePath5Midpoint1Teal = NSBezierPath();
            let outlinePath6Midpoint2Pink = NSBezierPath();
            
            let normalsPointPath = NSBezierPath();
            let rightmostPointPath = NSBezierPath();
            let leftmostPointPath = NSBezierPath();
            
            let bendBrushStamps = NSBezierPath();


//             var arrayOfDots : [[Double]] = [];
             
             
            var location :  NSPoint = .zero
            //let distance :CGFloat = 2;
            var lastStampPath : NSBezierPath?;
            
            var unionedPath : NSBezierPath = NSBezierPath();
            
            let distanceBetweenLoopPoints : CGFloat = 1.0;
            
            var lastPoint : NSPoint = NSPoint.zero


            for pkPoint in path.interpolatedPoints(by: .distance(distanceBetweenLoopPoints))
            {
                    
            /*
                let location = pkPoint.location.unflipInsideBounds(boundsForUnflipping: self.bounds)
               // let r = NSRect.init(origin: location, size: CGSize.init(width: 1.25 * pkPoint.size.width, height: 1.15 *  0.35 * pkPoint.size.width )).unflipInsideBounds(boundsForUnflipping: self.bounds))
                
                //.centerOnPoint(pkPoint.location
                
                stroke.ink.color.setFill();
                
               //r.fill();
                let p = NSBezierPath();
                p.appendRotatedOvalAtCenterPoint(angleDegrees: -rad2deg(pkPoint.azimuth), centerPoint: location, width:  pkPoint.size.width, height: 0.35 * pkPoint.size.width)
                
               // let r2 = NSMakeRect(location.x,location.y, pkPoint.size.width,   0.35 * pkPoint.size.width).centerOnPoint(location)
                
                //let rp = NSBezierPath()
                //rp.appendRect(r2)
                
                //p.appendPathRotatedAboutCenterPoint(path: rp, angleDegrees: -rad2deg(pkPoint.azimuth), centerPoint: location)
                
                p.fill();
                
                
                /*
                let ff = NSBezierPath();
                ff.move(to: location)
                ff.line(to: location.offsetBy(x: 10, y: 10));
                ff.move(to: location)
                ff.line(to: location.offsetBy(x: -10, y: -10));
                NSColor.orange.setStroke();
                ff.stroke()
                */
                
                //print(point)
                */
        
            location = pkPoint.location//.unflipInsideBounds(boundsForUnflipping: self.bounds)
               // let r = NSRect.init(origin: location, size: CGSize.init(width: 1.25 * pkPoint.size.width, height: 1.15 *  0.35 * pkPoint.size.width )).unflipInsideBounds(boundsForUnflipping: self.bounds))
                
                //.centerOnPoint(pkPoint.location
                
                let slopeDegrees = NSBezierPath.lineAngleDegreesFrom(point1: lastPoint, point2: location);
                
            
                
                
                stroke.ink.color.setFill()//.withAlphaComponent(0.2).setFill()
                
                let brushWidth = pkPoint.size.width;
            
         
               if(lastPoint == .zero)
               {
                    lastPoint = location
               }
                
               if((NSPoint.distanceBetween(lastPoint, location)) > distanceBetweenLoopPoints)
               {
               
//                let lineAngleRadians = NSBezierPath.lineAngleRadiansFrom(point1: lastPoint, point2: location)
                
//                let midP = lastPoint.midpoint(pointB: location)
                    
              
                    let d = (NSPoint.distanceBetween(lastPoint, location)) + 1;
            
                 for r in stride(from: 1, to: d, by: distanceBetweenLoopPoints / 2.0)
                {
//                    let x = (r * cos(lineAngleRadians)) + lastPoint.x
//                    let y = (r * sin(lineAngleRadians)) + lastPoint.y


                    let interpolatedPoint = (vDSP.linearInterpolate([lastPoint.x.double(),lastPoint.y.double()], [location.x.double(),location.y.double()], using: Double(r / d)))
                    
                    let interpolatedNSPoint = NSPoint(x: CGFloat(interpolatedPoint[0]), y: CGFloat(interpolatedPoint[1]))
                
                let midP = interpolatedNSPoint // NSPoint(x: x, y: y)

                               
                    let rotatedBrush = NSBezierPath();
                    let baseRect = NSMakeRect(0,0, brushWidth,  0.35 * brushWidth).centerOnPoint(midP)
                    
                    let baseRectPath = NSBezierPath()
                    
                    baseRectPath.appendOval(in: baseRect)
                    //baseRectPath.appendRect(baseRect)
                    
//                    NSColor.green.setFill()
                    rotatedBrush.appendPathRotatedAboutCenterPoint(path: baseRectPath, angleDegrees: rad2deg(pkPoint.azimuth), centerPoint: midP)
                    rotatedBrush.fill();


               
               
                }
               

               }// END if
               
                   
               // r.fill();
      
                  
               // MARK: P.FILL
                  //  p.fill()
                
                
                lastPoint = location

                
                /*
                if(unionedPath.isEmpty)
                {
                    unionedPath.append(p)
                }
                else
                {
                
                unionedPath = unionedPath.wfUnion(with: p)// unionedPath.fb_union(p)
                }
                */
                
                
                
                /*

                a1Points.append(p.pointAtIndex(0))
                a2Points.append(p.pointAtIndex(3))

                b1Points.append(p.pointAtIndex(1))
                b2Points.append(p.pointAtIndex(2))

                
                if(counter == 0)
                {
                outlinePath1.move(to: p.pointAtIndex(0))
                outlinePath2green.move(to: p.pointAtIndex(1))
                 outlinePath3yellow.move(to: p.pointAtIndex(2))
                    outlinePath4brown.move(to: p.pointAtIndex(3))

                    outlinePath5Midpoint1Teal.move(to: p.pointAtIndex(1).midpoint(pointB: p.pointAtIndex(2)))
                    outlinePath6Midpoint2Pink.move(to: p.pointAtIndex(3).midpoint(pointB: p.pointAtIndex(0)))
                }
                outlinePath1.line(to: p.pointAtIndex(0))
                outlinePath2green.line(to: p.pointAtIndex(1))
                outlinePath3yellow.line(to: p.pointAtIndex(2))
                outlinePath4brown.line(to: p.pointAtIndex(3))

            outlinePath5Midpoint1Teal.line(to: p.pointAtIndex(1).midpoint(pointB: p.pointAtIndex(2)))
            
            
                    outlinePath6Midpoint2Pink.line(to: p.pointAtIndex(3).midpoint(pointB: p.pointAtIndex(0)) )
            */
            

            
                /*
                let outerRightPoint = NSPoint.pointWithGreatestDistanceFromReferencePoint(referencePoint: location, pointArray:
                
                if(counter == 0)
                {
                    normalsPointPath.move(to: location)

                }
                else
                {
                normalsPointPath.line(to: outerRightPoint)
                }
                */
                
                
                /*
                
                // MARK: ----HULL APPROACH
                let bL = p.pointAtIndex(0).hullPoint()
                let bR = p.pointAtIndex(1).hullPoint()
                
                let tR = p.pointAtIndex(2).hullPoint()
                let tL = p.pointAtIndex(3).hullPoint()
                
                
                arrayOfDots.append([bL[0],bL[1]])
                arrayOfDots.append([bR[0],bR[1]])
                arrayOfDots.append([tR[0],tR[1]])
                arrayOfDots.append([tL[0],tL[1]])
                */

              //  arrayOfDots.append([location.x.double(),location.y.double()])
                
                
              
               
               // p.fill();
               
                 if(counter == 0)
                {
                    strokePath.move(to: location)
                }
                else
                {
                    strokePath.line(to: location)

                }
                
                
             
                /*
                let ang = (floor (NSBezierPath.lineAngleDegreesFrom(point1: lastPoint, point2: location)))
                
                // MARK: drawAngles
                let drawAngles = true
                if(drawAngles)
                {
                   
                
                    if((counter.quotientAndRemainder(dividingBy: 1).remainder == 0)
                    
                    )
                    {
                        let angStr = "\(ang)"
                       // angStr.drawStringInsideRectWithMenlo(fontSize: 8, textAlignment: NSTextAlignment.right, fontForegroundColor: angleIsDecreasing ? NSColor.red : NSColor.white, rect: NSMakeRect(location.x, location.y, 30, 10))
                        // print(floor(rad2deg(-pkPoint.azimuth) + 360 ))
                        
                        if((ang > lastIntervaledPointAngle) && angleIsDecreasing)
                        {
                                bendBrushStamps.append(p)
                                
                                angleIsDecreasing = false
                        }
                         else if((ang < lastIntervaledPointAngle) && (angleIsDecreasing == false))
                        {
                            bendBrushStamps.append(p)
                            angleIsDecreasing = true
                        }
                        
                        lastIntervaledPointAngle = ang;
                        
                        
                        normalsPointPath.move(to: location)
                        
                        let sP = NSBezierPath.secondPointFromAngleAndLength(firstPoint: location, angleDegrees: ang + 90, length: brushWidth / 2 + 5)
                        
                        normalsPointPath.line(to: sP)
                        
                        if(counter != 0)
                        {
                        aNormalPoints.append(sP)
                        }
                        
                        normalsPointPath.move(to: location)

                        let sP2 = NSBezierPath.secondPointFromAngleAndLength(firstPoint: location, angleDegrees: ang - 90, length: brushWidth / 2 + 5)
                        
                        bNormalPoints.append(sP2)

                        
                        normalsPointPath.line(to: sP2)
                        
                        
                        if(counter == 0)
                        {
                        rightmostPointPath.move(to: location)
                        }
                        
                        let rightmostPoint = NSPoint.pointWithLeastDistanceFromReferencePoint( referencePoint : sP, pointArray :             [p.pointAtIndex(0),
            p.pointAtIndex(1),
             p.pointAtIndex(2),
             p.pointAtIndex(3),
                p.pointAtIndex(1).midpoint(pointB: p.pointAtIndex(2)),
                p.pointAtIndex(3).midpoint(pointB: p.pointAtIndex(0))
                ], normalLength:brushWidth + 5)
                
                                        rightmostPointPath.move(to: sP)

                rightmostPointPath.line(to: rightmostPoint)

                        
                        
                        
                    }
                }
                
              
                /*
                // MARK: stamp at same angle
                if(ang == floor(360 - rad2deg(pkPoint.azimuth) ) )
                {
                                  let fff = NSMakeRect(0, 0, 40, 40).centerOnPoint(location)

                    bendBrushStamps.append(p)
                  //NSColor.green.setFill();
                   // fff.fill();
                   // p.fill()
                }
                
                if(counter == 0)
                {
                    bendBrushStamps.append(p)
                }
                */
                
                
                
                
                /*
                
                if( floor (NSBezierPath.lineAngleDegreesFrom(point1: lastPoint, point2: location)) ==  floor(rad2deg(-pkPoint.azimuth) + 360 ) )
                {
                  let fff = NSMakeRect(0, 0, 4, 4).centerOnPoint(location)
                    NSColor.green.setFill();
                    fff.fill();
                        

                   //print(floor (NSBezierPath.lineAngleDegreesFrom(point1: lastPoint, point2: location)) ==  floor(rad2deg(-pkPoint.azimuth)))
                }
                */
                
               
               /*
               if(
               floor(rad2deg(Slope(a: lastPoint, b: location))) == floor(rad2deg(-pkPoint.azimuth)))
               {
                    let fff = NSMakeRect(0, 0, 4, 4).centerOnPoint(location)
                    NSColor.green.setFill();
                    fff.fill();
               }
                
                // MARK: drawZeroSlope
                let drawZeroSlope = false
                if(drawZeroSlope)
                {
                if(floor((location.y - lastPoint.y) / (lastPoint.x - location.x)) == 0)
                {
                
                    let fff = NSMakeRect(0, 0, 4, 4).centerOnPoint(location)
                    NSColor.white.setFill();
                    fff.fill();
                }
                
                }
                
                */
                
                lastPoint = location

               // NSColor.brown.setFill()
              //  NSMakeRect(0,0,3,3).centerOnPoint(location).fill()

                counter += 1;
                
                lastStampPath = p
                
            } // END for loop
            
            bendBrushStamps.append(lastStampPath!)
            
            //strokePath.stroke()


            /*

           // MARK: ------ hull approach
             var convexHullPath = NSBezierPath();
             let useConvexHull = true
             
             var bP : [[Double]] = []
             
             arrayOfDots.append(contentsOf: strokePath.buildupModePoints())
             
             arrayOfDots.append(contentsOf: outlinePath1.buildupModePoints())
             
             arrayOfDots.append(contentsOf: outlinePath2green.buildupModePoints())
             
             arrayOfDots.append(contentsOf: outlinePath3yellow.buildupModePoints())
             
             arrayOfDots.append(contentsOf: outlinePath4brown.buildupModePoints())
             
             if(useConvexHull)
             {
            let h = Hull(concavity: 2)
            if let hull = h.hull(arrayOfDots, nil) as? [[Double]]
            {
                let moveToPoint = NSMakePoint(CGFloat(hull[0][0]), CGFloat(hull[0][1]))
            convexHullPath.move(to: moveToPoint)
            let hullCount = hull.count;
                
                for i in 1..<hullCount
                {
                    let lineToPoint = NSMakePoint(CGFloat(hull[i][0]), CGFloat(hull[i][1]))
                    convexHullPath.line(to: lineToPoint)
                }
            }

            convexHullPath.close();
            
            arrayOfDots.removeAll()
            NSColor.black.setStroke()
            convexHullPath.stroke()
            
            }
            */
            
    
            // MARK: contructPath
            let contructPath = true;
            if(contructPath)
            {
                let constructPath1 = NSBezierPath();
                constructPath1.append(outlinePath2green)
                constructPath1.appendThroughOmitFirstMoveToOfIncomingPath(incomingPath: outlinePath1.reversed)
                constructPath1.close()
                
                
                let constructPath2 = NSBezierPath();
                constructPath2.append(outlinePath3yellow)
                constructPath2.appendThroughOmitFirstMoveToOfIncomingPath(incomingPath: outlinePath4brown.reversed)
                constructPath2.close()
                
                
                NSColor.blue.setStroke();
                
                //   NSColor.orange.setStroke();
                //   outlinePath2green.stroke();
                //             NSColor.red.setStroke();
                //            outlinePath3yellow.appendThroughOmitFirstMoveToOfIncomingPath(incomingPath: outlinePath4brown.reversed)
                //
                // outlinePath3yellow.close()
                //
                NSColor.purple.setStroke();
                
                NSColor.purple.withAlphaComponent(0.5).setFill()
                constructPath1.fill();
                constructPath2.fill();
                
                // NSColor.green.setFill()
                bendBrushStamps.fill()
            }
            
            // MARK: strokeOutlinePaths
            
            let strokeOutlinePaths = false;
            if(strokeOutlinePaths)
            {
                let strokeMainOutlines = true;
                if(strokeMainOutlines)
                {
                    
                    NSColor.systemIndigo.setStroke()
                    outlinePath1.stroke();
                    
                    NSColor.brown.setStroke();
                    outlinePath4brown.stroke();
                    
                    
                    NSColor.green.setStroke();
                    outlinePath2green.stroke();
                    
                    NSColor.yellow.setStroke()
                    outlinePath3yellow.stroke();
                    
                }
            
            /*
            NSColor.systemTeal.setStroke();
            outlinePath5Midpoint1Teal.stroke()
            
            
            NSColor.systemPink.setStroke()
            outlinePath6Midpoint2Pink.stroke()
            */
            
                NSColor.white.setStroke()
                normalsPointPath.lineWidth = 2;
                normalsPointPath.stroke()
                
                strokePath.stroke()
                
                
                NSColor.black.setStroke()
                rightmostPointPath.lineWidth = 3;
                rightmostPointPath.stroke()
                
                */
               
              // MARK: END for pkPoint
            } // END for pkPoint
            
            NSColor.white.setStroke()
            
            unionedPath.stroke();
          
            /*
          
            NSColor.red.setStroke()
            let a1 = NSBezierPath()
            a1.lineWidth = 3;
            a1.appendPoints( &a1Points , count: a1Points.count)
            a1.stroke()
            
            let a2 = NSBezierPath()
            a2.lineWidth = 3;
            a2.appendPoints( &a2Points , count: a2Points.count)
            a2.stroke()
        
        
            
            
            
            var resultingArray = pointArrayFromSmallestDistances(normalsPointArray: aNormalPoints, collectionOfPointArrays: [a1Points,a2Points,b1Points,b2Points],normalLength: 1000)
            
            NSColor.green.setStroke();
            let rA = NSBezierPath()
            rA.lineWidth = 3.0;
            rA.appendPoints( &resultingArray , count: resultingArray.count)
            //rA.stroke()
            
            
            
            
            
            NSColor.blue.setStroke()
            let b1 = NSBezierPath()
            b1.lineWidth = 3;
            b1.appendPoints( &b1Points , count: b1Points.count)
           // b1.stroke()
            
            let b2 = NSBezierPath()
            b2.lineWidth = 3;
            b2.appendPoints( &b2Points , count: b2Points.count)
          //  b2.stroke()
            
    
       
                     var resultingBArray = pointArrayFromSmallestDistances(normalsPointArray: bNormalPoints, collectionOfPointArrays: [a1Points,a2Points,b1Points,b2Points],normalLength: 1000)
            
            NSColor.green.setStroke();
            let rAb = NSBezierPath()
            rAb.lineWidth = 3.0;
            rAb.appendPoints( &resultingBArray , count: resultingBArray.count)
            //rAb.stroke()
            
            
            let r222 = NSBezierPath();
            r222.append(rA)
            r222.appendThroughOmitFirstMoveToOfIncomingPath(incomingPath: rAb.reversed)
            r222.lineWidth = 2;
           // r222.stroke()
           // NSColor.green.withAlphaComponent(0.4).setFill()
            NSColor.green.setFill()
            r222.fill()
            
                NSColor.orange.setStroke()
            let aN = NSBezierPath()
            aN.appendPoints( &aNormalPoints , count: aNormalPoints.count)
            aN.stroke()
            
                                NSColor.orange.setStroke()

            let bN = NSBezierPath()
            bN.appendPoints( &bNormalPoints , count: bNormalPoints.count)
          //  bN.stroke()
            
            */
            
          // MARK: END for stroke in pkDrawing.strokes
        }// END for stroke in pkDrawing.strokes
        */
       
       
       
       
       
        // ------------
        // ------------ DEBUG
        /*
        for (i,s) in pkDrawing.strokes.enumerated()
        {
            NSColor.blue.setFill()
            s.renderBounds.unflipInsideBounds(boundsForUnflipping: self.bounds).frame()
            let st = "\(i)"
            st.drawStringInsideRectWithMenlo(fontSize: 10, textAlignment: .left, fontForegroundColor: .black, rect: s.renderBounds.unflipInsideBounds(boundsForUnflipping: self.bounds))
        }*/
        // ------------ DEBUG
        // ------------
        
        
    }// END draw:
    
    
    func pointArrayFromSmallestDistances(normalsPointArray: [NSPoint], collectionOfPointArrays:[[NSPoint]], normalLength:CGFloat) -> [NSPoint]
    {
        var resultingPointArray : [NSPoint] = []
        
        for point in normalsPointArray
        {
        
            var pointToAppend = point;
            
            var i = 0;
            
            var xArray : [NSPoint] = [];
            
            for passedArray in collectionOfPointArrays
            {
            
                xArray.append( NSPoint.pointWithLeastDistanceFromReferencePoint(referencePoint: point, pointArray: passedArray, normalLength:normalLength) )
                
                i += 1;
                
            }
            
            pointToAppend = NSPoint.pointWithLeastDistanceFromReferencePoint(referencePoint: point, pointArray: xArray, normalLength:normalLength)
            
            resultingPointArray.append(pointToAppend)
        }
    
        return resultingPointArray;
    }
    
    override var isFlipped: Bool
    {
        return true
    }
 
 
 
     func flashAllVisibleObjects(duration:CGFloat)
    {
        // turn on flash bool, redraw visibledocumentRect
        // Timer
        // turn off flash bool, redraw visible documentRect
        
        // alternatively: use coreanimation to flash layer.
    
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.5
        animation.autoreverses = true;
        animation.duration = CFTimeInterval(duration)
        self.layer?.add(animation, forKey: "opacity");
        
    }
    
    /*
    override var description: String
    {
        return "\(self.name) \(self.frame) \(self.arrayOfFMDrawables.count)"
    }*/
    
        // MARK: -
     // MARK: DRAWABLES DATA STORAGE AND SELECTION
     // MARK: dynamicTree

    var dynamicTreeIsInUse : Bool = false;
    
    var dynamicTree : DynamicTree<FMDrawable> = DynamicTree()
   
    // MARK: orderingArray
    var orderingArray : [FMDrawable] = []
    {
        didSet
        {
            self.currentDrawingPage?.drawingPageController?.updateLayersPanelTable();
        
        }
    
    }
    
    
    // MARK: selectedDrawables
    //var prohibitSelectionBecauseOfReprocessing : Bool = false;
    //var selectedDrawablesNeedReprocessing : Bool = false;
    
    var selectedDrawables : Array<FMDrawable> = []
    {
        didSet
        {
            currentDrawingPage?.drawingPageController?.selectedObjectsBox.isHidden = selectedDrawables.isEmpty
            if(selectedDrawables.isEmpty == false)
            {
                currentDrawingPage?.drawingPageController?.selectedObjectsLabel.stringValue =
                     "selected: \(selectedDrawables.count)"
            }
           
            
        }
    }
    
    var selectedDrawablesDeepCopy : Array<FMDrawable>
    {
        get
        {
            var selectedDrawablesCopied : Array<FMDrawable> = [];
            
            for (_, drawable) in selectedDrawables.enumerated()
            {
                selectedDrawablesCopied.append(drawable.copy() as! FMDrawable)
            }
            
            return selectedDrawablesCopied;
        }
    
    }
    
    func deepCopyOfDrawables(drawables:[FMDrawable]) -> [FMDrawable]
    {
         var drawablesCopied : Array<FMDrawable> = [];
            
            for (_, drawable) in drawables.enumerated()
            {
                drawablesCopied.append(drawable.copy() as! FMDrawable)
            }
            
            return drawablesCopied;
    
    }
    
    
    var outlineSelectedTotalRegionRect : Bool = false;
    

    
    var hasSelectedDrawables : Bool {
     
        get {
           return !selectedDrawables.isEmpty
        }
        
    }
    
    // MARK: SELECTION FUNCTIONS
    
     func selectionTotalRegionRectExtendedRenderBounds() -> NSRect
    {
        var totalRegionRect : NSRect = .zero
        
        for i in stride(from: 0, to: selectedDrawables.count, by: 1)
        {
            if(totalRegionRect.isEmpty)
            {
                totalRegionRect = selectedDrawables[i].renderBounds()
            }
            else
            {
                totalRegionRect = totalRegionRect.union(selectedDrawables[i].renderBounds())
                
            }
        }
        
        return totalRegionRect
        
    }
    
    func selectionTotalRegionRectStandardBounds() -> NSRect
    {
        var totalRegionRect : NSRect = .zero
        
        for i in stride(from: 0, to: selectedDrawables.count, by: 1)
        {
            if(totalRegionRect.isEmpty)
            {
                totalRegionRect = selectedDrawables[i].bounds
            }
            else
            {
                totalRegionRect = totalRegionRect.union(selectedDrawables[i].bounds)
                
            }
        }
        
        return totalRegionRect
        
    }
    
    
    func updateDynamicTreeProxyBoundsForSelectedDrawables()
    {
        if(dynamicTreeIsInUse)
        {
            for drawable in self.selectedDrawables
            {
                
                _ = dynamicTree.moveProxy(index: drawable.treeProxy, aabb: drawable.renderBounds())
                
            }
        }
    }
    
    func redisplaySelectedTotalRegionRect()
    {
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds())
    }
    
    // MARK: CARTING, OFFSET CGVECTORS
    var draggedOffsetCGVectors : Array<CGVector> = []
    var lockpointOffsetCGVector : CGVector = CGVector();
    
    var isInDragging : Bool = false
    
    var isCarting: Bool = false
    {
        
        didSet{
        
            currentDrawingPage?.drawingPageController?.cartingModeBox.isHidden = !isCarting
            currentDrawingPage?.activePenLayer.setupCursor();
        /*
            if(isCarting == true)
            {
            
              self.layersManager?.stateMachine.currentOverallState = "carting"
            }
            else
            {
              self.layersManager?.stateMachine.currentOverallState = "receiveDrawing"
            }
            
            self.layersManager?.cartingDidChange();
            */
            
            //print("isCarting \(isCarting)")
        }
        
    }
    
    var isUsingSelectRectangle : Bool = false
    
    var initialMouseDragged: Bool = true
    var initialMouseDownPoint : NSPoint = NSPoint.zero
    
    var stateArray : Array<String> = []
    
    var hitSelectedObjectForDrag : FMDrawable!
    
    
    
    var justCarted: Bool  = false
    {
        
        didSet{
         // print("justCarted \(justCarted)")
        }
        
    }
    var tabJustSelected: Bool = false
    {
        
        didSet{
           // print("tabJustSelected \(tabJustSelected)")
        }
        
    }
    
    // MARK: SCALING AND ROTATION VARIABLES
    
    var anchorPointForIncrementTransform = NSNotFoundPoint
    var anchorPointOffset = CGVector.zero
    
    var referenceRectPath : NSBezierPath!;
    var referenceRectWidth : CGFloat = 0;
    var referenceRectHeight : CGFloat = 0;
    
    // MARK: --- scaling
    var scalingIsOn: Bool = false
    var scalingOperationType : String = "scale";
    var scalingControlPointForScaling : NSPoint = .zero;
    var scalingReferencePoint : NSPoint = .zero;
    var scalingLineOriginPoint : NSPoint = .zero;
    var scalingLineEndPoint : NSPoint = .zero;
    var scalingOctant = 1;
    var scalingLinePath : NSBezierPath = NSBezierPath();
    
    var shearEdge: String = "top";
    var shearStartAngleRadians: CGFloat = 0;
    var lastShearAngle: CGFloat = 0;
    var shearAngle: CGFloat = 0;
    
    
    var lastScale : CGFloat = 0.0;
    var lastScaleX : CGFloat = 0.0;
    var lastScaleY : CGFloat = 0.0;
    
    // MARK: --- rotation
        
    var rotateIsOn: Bool = false
    var rotationIs3D : Bool = false
    var rotateReferencePoint: NSPoint = NSPoint.zero
    var rotateLineStartPoint: NSPoint = NSPoint.zero
    var rotateLineEndPoint: NSPoint = NSPoint.zero
    var rotateStartingDegrees: CGFloat = 0;
    var lastRotate: CGFloat = 0;
    var lastRotateEndPoint : NSPoint = NSPoint.zero
    var rotateLinePath: NSBezierPath = NSBezierPath();
    var rotateType: Int32 = 0;
    var rotateQuadrant: Int32 = 0;
    var rotateControlPointForPivot: NSPoint = NSPoint.zero
    
    
    // MARK: ---  INCREMENT ROTATION AND SCALING
    
    func rotateSelectedDrawablesBy(degrees:CGFloat)
    {
        
        if(self.hasSelectedDrawables)
        {

            var pointForRotation = NSPoint.zero
            var pointLocation = FMDrawable.TransformPoint.center
        
     
            if(self.selectedDrawables.count > 1)
            {
                let totalRegionRect = self.selectionTotalRegionRectExtendedRenderBounds()
                pointForRotation = NSMakePoint(totalRegionRect.midX, totalRegionRect.midY)
                pointLocation = FMDrawable.TransformPoint.passedParameter
            
            }
            else if(self.selectedDrawables.count < 2)
            {
                pointForRotation = selectedDrawables.first!.centroid;
                pointLocation = FMDrawable.TransformPoint.passedParameter

                
            }
            
            /*
            
            // Graphite Glider
            if(self.layersManager?.drawingEntityManager?.doInstantAnchorPointOnIncrementTransform ?? false)
            {
                if(((self.layersManager!.activeLayer.isShowingLockPoint)) && (self.anchorPointForIncrementTransform == NSNotFoundPoint) && (self.isCarting == false))
                {
                    self.anchorPointForIncrementTransform = (self.layersManager!.activeLayer.currentLockPoint)
                }
            }
            */
            
            if(self.anchorPointForIncrementTransform != NSNotFoundPoint)
            {
                pointForRotation = anchorPointForIncrementTransform
                pointLocation = FMDrawable.TransformPoint.passedParameter
            }
            
            
            //self.rotateObjectsOnLayer(self.selectedDrawablesDeepCopy, startRad: 0, endRad: deg2rad(degrees))
        
            
            let oldRegionRect = self.selectionTotalRegionRectExtendedRenderBounds()
            
            // bounding box of selected drawables
            self.selectedDrawables.forEach { (drawable) in
                    drawable.rotateFrom(pointLocation: pointLocation, point: pointForRotation, angle: degrees)
                    
                if let stroke = drawable as? FMStroke
                {
                    // ROTATE EVERY BRUSH TIP
                    stroke.rotateBrushTips(degrees: degrees)
                }
                    
                if(dynamicTreeIsInUse)
                {
                    _ = dynamicTree.moveProxy(index: drawable.treeProxy, aabb: drawable.renderBounds())
                }
            }
        
            
            if((self.anchorPointForIncrementTransform == NSNotFoundPoint) && (pointLocation == FMDrawable.TransformPoint.passedParameter))
            {
                anchorPointForIncrementTransform = pointForRotation
                
            }
            
            
            if(self.isCarting)
            {
                self.refreshForTransformByIncrement()
            }
            
          
            
            self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldRegionRect).insetBy(dx: -10, dy: -10))
            
            /*
            // Graphite Glider
            if(layersManager!.panelsController.sizeInspectionPopover.isShown)
            {
                layersManager!.panelsController.updateXYInspectSize();
                layersManager!.panelsController.updateWidthHeightInspectSize();
            }
            */
            
        }
        else
        {
          
          /* REVISIT
            if((self.layersManager?.activeLayer.isShowingLockPoint)!)
            {
                let drawableUnderneath = self.layersManager?.activeLayer.lockPointDrawable
                self.makeArrayTheSelectedDrawables(arrayToMakeSelected: [drawableUnderneath!])
                self.rotateSelectedDrawablesBy(degrees: degrees)
            }
            else
            {*/
                let mousePoint = self.mousePointInLayerOutsideOfEventStream()
                let hitTestResult = self.runHitTestOnAllObjects(point: mousePoint)
                if(hitTestResult.didHitObj)
                {
                    self.makeArrayTheSelectedDrawables(arrayToMakeSelected: [hitTestResult.hitDrawable!])
                    anchorPointForIncrementTransform = mousePoint
                    self.rotateSelectedDrawablesBy(degrees: degrees)
                    
                }
           //] }
            
            
        }
        
    }
    
    func scaleSelectedDrawablesBy(_ scale:CGFloat)
    {
        //print("scaleSelectedDrawablesBy \(scale)")
        if(self.hasSelectedDrawables)
        {
            var pointForScale = NSPoint.zero
            var pointLocation = FMDrawable.TransformPoint.center
            
            
            if(self.selectedDrawables.count > 1)
            {
                let totalRegionRect = self.selectionTotalRegionRectExtendedRenderBounds()
                pointForScale = NSMakePoint(totalRegionRect.midX, totalRegionRect.midY)
                pointLocation = FMDrawable.TransformPoint.passedParameter
                
            }
            else if(self.selectedDrawables.count < 2)
            {
                pointForScale = selectedDrawables.first!.centroid;
                pointLocation = FMDrawable.TransformPoint.passedParameter
            }
            
            /* REVISIT
            if(self.layersManager?.drawingEntityManager?.doInstantAnchorPointOnIncrementTransform ?? false)
            {
                if(((self.layersManager?.activeLayer.isShowingLockPoint)!) && (self.anchorPointForIncrementTransform == NSNotFoundPoint) && (self.isCarting == false))
                {
                    self.anchorPointForIncrementTransform = (self.layersManager!.activeLayer.currentLockPoint)
                }
            }
            */
            
            if(self.anchorPointForIncrementTransform != NSNotFoundPoint)
            {
                pointForScale = anchorPointForIncrementTransform
                pointLocation = FMDrawable.TransformPoint.passedParameter
            }
            


            let oldRegionRect = self.selectionTotalRegionRectExtendedRenderBounds()
            
            self.selectedDrawables.forEach { (drawable) in
                drawable.scaleFrom(pointLocation: pointLocation, point: pointForScale, scale: scale,
                                   doScaleLineWidth: false /*layersManager!.doScaleLineWidth*/)
                
                if(dynamicTreeIsInUse)
                {
                    _ = dynamicTree.moveProxy(index: drawable.treeProxy, aabb: drawable.renderBounds())
                }
            }
            
            if(self.anchorPointForIncrementTransform == NSNotFoundPoint)
            {
                anchorPointForIncrementTransform = pointForScale
                
            }
            
            if(self.isCarting)
            {
                self.refreshForTransformByIncrement()
            }
            
            // bounding box of selected drawables
            self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldRegionRect).insetBy(dx: -10, dy: -10))
            
            /*
            //Graphite Glider
            if(layersManager!.panelsController.sizeInspectionPopover.isShown)
            {
                layersManager!.panelsController.updateXYInspectSize();
                layersManager!.panelsController.updateWidthHeightInspectSize();
            }
            */
            
        }
        else
        {
           /* REVISIT if((self.layersManager?.activeLayer.isShowingLockPoint ?? false))
            {
                let drawableUnderneath = self.layersManager?.activeLayer.lockPointDrawable
                self.makeArrayTheSelectedDrawables(arrayToMakeSelected: [drawableUnderneath!])
                self.scaleSelectedDrawablesBy(scale)
            }
            else
            {*/
                let mousePoint = self.mousePointInLayerOutsideOfEventStream()
                let hitTestResult = self.runHitTestOnAllObjects(point: mousePoint)
                if(hitTestResult.didHitObj)
                {
                    self.makeArrayTheSelectedDrawables(arrayToMakeSelected: [hitTestResult.hitDrawable!])
                    anchorPointForIncrementTransform = mousePoint
                    self.scaleSelectedDrawablesBy(scale)
                    
                }
            //}
        }
    }
    
   func flipHorizontallySelectedDrawables()
   {
        
   
   }
   
   func flipVerticallySelectedDrawables()
   {
   
   }
   
   
   
    // MARK: --- SCALING AND ROTATION
    
     func mousePointInLayerOutsideOfEventStream() -> NSPoint
    {
        let pointInWindow = self.window!.mouseLocationOutsideOfEventStream
        
        return self.convert(pointInWindow, from: nil)
        
    }
    
    func startScalingOperation(uniformFromCenter:Bool, operationType: String)
    {
        let drawingLayerPoint = self.mousePointInLayerOutsideOfEventStream();
        
        scalingIsOn = true;
        scalingOperationType = operationType;
        
        lastScale = 1.0;
        
//       GraphiteGlider: remakeArrayOfSelectedObjectsLineWidth();
        
        if((self.rotateIsOn == true) && ( operationType == "scale" ))
        {
            scalingReferencePoint = rotateReferencePoint;
            scalingLineOriginPoint = rotateLineStartPoint
            
            scalingLineEndPoint = rotateLineEndPoint;
            
            //let drawingLayerPoint = self.mousePointInLayerOutsideOfEventStream();
       
       
        }
       
        else
        {
            if((self.rotateIsOn == true) && ( operationType != "scale" ))
            {
                self.endRotateOperation();
            }
            
           
           scalingReferencePoint = drawingLayerPoint;
            
      
            /*
             
             var scalingOctant = 1;
             var scalingLinePath : NSBezierPath = NSBezierPath();
             var arrayOfSelectedObjectsOriginalDimensions : [NSRect] = [];
             var originalTotalRegionRectForSelectedObjectsOriginalDimensions : NSRect = .zero;
            
             */
            
            let boundsForXform = self.selectionTotalRegionRectStandardBounds()
            
           
            let minX = boundsForXform.minX;
            let maxX = boundsForXform.maxX;
            let minY = boundsForXform.minY;
            let maxY = boundsForXform.maxY;
            let midX = boundsForXform.midX;
            let midY = boundsForXform.midY;
            
            let x = drawingLayerPoint.x;
            let y = drawingLayerPoint.y;

            
            /*
             ---- FOR RECTANGLES THAT HAVE BEEN ROTATED
          
            if(selectedDrawables.count == 1)
            {
                minX = selectedDrawables[0].bottomLeftPt.x;
                maxX = selectedDrawables[0].bottomRightPt.x;
                minY = selectedDrawables[0].bottomRightPt.y;
                maxY = selectedDrawables[0].topRightPt.y;
                midX = selectedDrawables[0].horizontallyNormalizedBoundsOfRectPath.midX;
                midY = selectedDrawables[0].horizontallyNormalizedBoundsOfRectPath.midY;
             //   boundsForXform = selectedDrawables[0].horizontallyNormalizedBoundsOfRectPath;
               
                
                // rotate point in negative degrees of rotation
            }
           */
            
        
            if(operationType == "scale")
            {
             
                // octant1 - top left
                if(
                    ( x < minX )  &&
                        ( y > maxY )
                    )
                {
                    // opposite is bottom right
                    scalingLineOriginPoint = NSMakePoint(maxX, minY);
                    
                    if(selectedDrawables.count == 1)
                    {
                        scalingLineOriginPoint = selectedDrawables[0].bottomRightPt;
                    }
                    
                    scalingOctant = 1;
                    
                }
                    
                // octant2 - top middle
                else if
                    (
                        ( x > minX )  &&
                            ( x < maxX ) &&
                            ( y > maxY )
                    )
                {
                    
                    // opposite is bottom middle
                    scalingLineOriginPoint = NSMakePoint(midX, minY);
                    scalingOctant = 2;
                    
              
                    if(selectedDrawables.count == 1)
                    {
                        scalingLineOriginPoint = selectedDrawables[0].bottomMiddlePt;
                        
                    }
                   
                }
                    
                    // octant3 - top right
                else if
                    (
                          ( x > maxX )  &&
                            ( y > maxY )
                    )
                {
                    
                    // opposite is bottom left
                    scalingLineOriginPoint = NSMakePoint(minX, minY);
                    
                    if(selectedDrawables.count == 1)
                    {
                        scalingLineOriginPoint = selectedDrawables[0].bottomLeftPt;
                    }
                    
                    scalingOctant = 3;
                }
                    // octant4 - middle right
                else if
                    (
                        ( x > maxX )  &&
                            ( y < maxY )  &&
                            ( y > minY )
                    )
                {
                    
                    // opposite is middle left
                    scalingLineOriginPoint = NSMakePoint(minX, midY);
                    
                    if(selectedDrawables.count == 1)
                    {
                        scalingLineOriginPoint = selectedDrawables[0].middleLeftPt;
                    }
                    
                    scalingOctant = 4;
                }
                    // octant5 - bottom right
                else if
                    (
                        ( x > maxX )  &&
                            ( y < minY )
                    )
                {
                    // opposite is top left
                    scalingLineOriginPoint = NSMakePoint(minX, maxY);
                    
                    if(selectedDrawables.count == 1)
                    {
                        scalingLineOriginPoint = selectedDrawables[0].topLeftPt;
                    }
                    
                    scalingOctant = 5;
                }
                    // octant6 - bottom middle
                else if
                    (
                        ( y < minY )  &&
                            ( x > minX )  &&
                            ( x < maxX )
                    )
                {
                    // opposite is top middle
                    scalingLineOriginPoint = NSMakePoint(midX, maxY);
                    
                    if(selectedDrawables.count == 1)
                    {
                        scalingLineOriginPoint = selectedDrawables[0].topMiddlePt;
                    }
                    
                    scalingOctant = 6;
                    
                }
                    // octant7 - bottom  left
                else if
                    (
                        ( x < minX )  &&
                            ( y < minY )
                    )
                {
                    // opposite is top right
                    scalingLineOriginPoint = NSMakePoint(maxX, maxY);
                    
                    if(selectedDrawables.count == 1)
                    {
                        scalingLineOriginPoint = selectedDrawables[0].topRightPt;
                    }
                    
                    
                    scalingOctant = 7;
                    
                    
                }
                    // octant8 - middle left
                else if
                    (
                        ( x < minX )  &&
                            ( y > minY )  &&
                            ( y < maxY )
                    )
                {
                    // opposite is middle right
                    scalingLineOriginPoint = NSMakePoint(maxX, midY);
                    
                    if(selectedDrawables.count == 1)
                    {
                        scalingLineOriginPoint = selectedDrawables[0].middleRightPt;
                    }
                    
                    
                    scalingOctant = 8;
                }
                else
                {
                    scalingLineOriginPoint = NSMakePoint(midX, midY);
                    scalingOctant = 9;
                    
                }
            }
            
         
            
            if(selectedDrawables.count == 1)
            {
                /*
                var pointRotationTransform = AffineTransform();
                pointRotationTransform.translate(x: midX, y: midY)
                pointRotationTransform.rotate(byDegrees: selectedDrawables[0].rotationCalculated)
                pointRotationTransform.translate(x: -midX, y: -midY)
                scalingLineOriginPoint = pointRotationTransform.transform(scalingLineOriginPoint)*/
            }
            
            if(anchorPointForIncrementTransform != NSNotFoundPoint)
            {
              
                scalingLineOriginPoint = anchorPointForIncrementTransform;
                scalingOctant = 9;
            }
            
            if(((uniformFromCenter == true) && (anchorPointForIncrementTransform == NSNotFoundPoint)) || (scalingOperationType == "shear") )
            {
                scalingLineOriginPoint = NSMakePoint(midX, midY);
                scalingOctant = 9;
                
            }
            
            scalingLineEndPoint = drawingLayerPoint;
            
            if(operationType == "shear")
            {
                scalingLineOriginPoint = NSMakePoint(midX, midY);
                scalingReferencePoint = drawingLayerPoint;
                
                shearStartAngleRadians = NSBezierPath.lineAngleRadiansFrom(point1: scalingLineOriginPoint, point2: scalingLineEndPoint);
                
                lastShearAngle = shearStartAngleRadians;
                
                
                let shearQuadrant = NSBezierPath.quadrantFrom(point1: scalingLineOriginPoint, point2: scalingReferencePoint, counterclockwiseOffsetDegrees: 45)
                
                
                
                if(shearQuadrant == 1)
                {
                    shearEdge = "bottom"; // 0 - bottom, 1- left, 2 - top, 3 - right
                    
                }
                if(shearQuadrant == 2)
                {
                    shearEdge = "top"; // 0 - bottom, 1- left, 2 - top, 3 - right
                    
                }
                if(shearQuadrant == 3)
                {
                    shearEdge = "right"; // 0 - bottom, 1- left, 2 - top, 3 - right
                    
                }
                if(shearQuadrant == 4)
                {
                    shearEdge = "left"; // 0 - bottom, 1- left, 2 - top, 3 - right
                    
                }
                
            }
            
        }// end if rotate is not on

     
        
        referenceRectPath = NSBezierPath();
        referenceRectPath.move(to: scalingLineEndPoint);
        referenceRectPath.line(to: scalingReferencePoint);
        scalingLinePath.append(referenceRectPath);
        
        scalingLinePath.appendRect(self.selectionTotalRegionRectStandardBounds());
        scalingLinePath.move(to: scalingLineOriginPoint);
        scalingLinePath.line(to: scalingLineEndPoint);
        
        referenceRectWidth = abs( scalingLineOriginPoint.x - scalingReferencePoint.x);
        
        referenceRectHeight = abs( scalingLineOriginPoint.y - scalingReferencePoint.y);
        
        
        
        self.setNeedsDisplay(scalingLinePath.bounds)
        
        
    }
    
  
    
    func endScalingOperation()
    {
        scalingIsOn = false;
        
        lastScale = 0.0;
       
        // if no other transform operation is going on.
        if(self.rotateIsOn == false)
        {
            // settings shared by transform operations should be removed
            // if no other transform operation is going on
         //    arrayOfSelectedObjectsLineWidth.removeAll();
         //   originalTotalRegionRectForSelectedObjectsOriginalDimensions = NSZeroRect;
            

        }
        else
            // other transform operations are going on
        {
            self.endRotateOperation();
            
        }
  
        if(scalingLinePath.isEmpty == false)
        {
            self.setNeedsDisplay(scalingLinePath.bounds);
        }
        
        scalingLinePath.removeAllPoints();
        referenceRectPath.removeAllPoints();
        
        self.scalingLineOriginPoint = NSZeroPoint;
        self.scalingLineEndPoint = NSZeroPoint;
        
    }
    
    func liveRotate(uniformFromCenter:Bool, rotationIs3D: Bool)
    {
        if(self.hasSelectedDrawables)
        {
            if(self.rotateIsOn == false)
            {
                if(self.isCarting)
                {
                    self.endCarting();
                }
                else if(((self.isCarting) == false) && self.justCarted)
                {
                    self.justCarted = false;
                }
                
                
                self.startRotateOperation(uniformFromCenter:uniformFromCenter, rotationIs3D: rotationIs3D);
                
                
            }
            else
            {
                self.endRotateOperation();
                
                if(self.justCarted)
                {
                    self.startCarting();
                }
                
            }
            
        }
        
    }
    
     func startRotateOperation(uniformFromCenter:Bool, rotationIs3D: Bool)
    {
        rotateIsOn = true;
        self.rotationIs3D = rotationIs3D;
        
        let totalRegionRect = self.selectionTotalRegionRectStandardBounds();
        
        
         // if scaling is on, settings were already made
        if((self.scalingIsOn == true) && ( scalingOperationType == "scale" ))
        {
            
            rotateReferencePoint = scalingReferencePoint;
            rotateLineStartPoint = scalingLineOriginPoint;
            rotateLineEndPoint = scalingLineEndPoint;
            
            /*
             let drawingLayerPoint = self.mousePointInLayerOutsideOfEventStream();
             
             rotateReferencePoint = drawingLayerPoint;
             rotateLineStartPoint = NSMakePoint(totalRegionRect.midX, totalRegionRect.midY);
             */
            
         
            
            
        }
       
        else
        {
         
            if((self.scalingIsOn == true) && ( scalingOperationType != "scale" ))
            {
                self.endScalingOperation();
                
            }
            
            let drawingLayerPoint = self.mousePointInLayerOutsideOfEventStream();
            rotateReferencePoint = drawingLayerPoint;
            
            
            let centerPointOfTotalRegion = NSMakePoint(totalRegionRect.midX, totalRegionRect.midY);
            
            rotateLineStartPoint = centerPointOfTotalRegion
            
            if(self.selectedDrawables.count == 1)
            {
                rotateLineStartPoint = selectedDrawables.first!.centroid
            }
            
            
            if(anchorPointForIncrementTransform != NSNotFoundPoint)
            {
                
                rotateLineStartPoint = anchorPointForIncrementTransform;
                
            }
            
            rotateLineEndPoint = drawingLayerPoint;
            
            rotateLinePath.appendRect(totalRegionRect)
            rotateLinePath.move(to: rotateLineStartPoint)
            rotateLinePath.line(to: rotateLineEndPoint)
            
            
            
            
            self.setNeedsDisplay(rotateLinePath.bounds)
            
            
        }
        
        rotateStartingDegrees = NSBezierPath.lineAngleDegreesFrom(point1: rotateLineStartPoint, point2: rotateLineEndPoint)
        lastRotate = rotateStartingDegrees;
        lastRotateEndPoint = scalingLineEndPoint;
        
    }
    
    
    func endRotateOperation()
    {
        rotateIsOn = false;

        
        // if no other transform operations are taking place.
        if(scalingIsOn == false)
            // settings shared by transform operations should be removed
            // if no other transform operation is going on
        {
            
            
        }
        else
            // other transform operations are going on
        {
            self.endScalingOperation()
        }
        
        
        if(rotateLinePath.isEmpty == false)
        {
            self.setNeedsDisplay(rotateLinePath.bounds)
        }
        
        rotateLinePath.removeAllPoints()
        
        rotateLineStartPoint = NSZeroPoint
        rotateLineEndPoint = NSZeroPoint
        
      
        lastRotate = 0;
    }

  
    func executeRotateOperationFromMouseMoved(_ event : NSEvent)
    {
        var updateRectFromPreviousBounds = NSZeroRect;
        
        // scaling execute from mouse moved
        // takes place before rotate execute from mouse moved
        if(self.scalingIsOn)
        {
            updateRectFromPreviousBounds = rotateLinePath.bounds;
        }
        else
        {
            updateRectFromPreviousBounds = rotateLinePath.bounds;
        }
        
        
        updateRectFromPreviousBounds = updateRectFromPreviousBounds.insetBy(dx: -15.0, dy: -15.0)
        
      
        let pointInView = self.convert(event.locationInWindow, from: nil);
        
        rotateLineEndPoint = pointInView;
        
        if(self.scalingIsOn)
        {
            rotateLineEndPoint = scalingLineEndPoint
        }
        
        rotateLinePath.removeAllPoints();
        
        
        let totalRegionRect = self.selectionTotalRegionRectStandardBounds()
        rotateLinePath.appendRect(totalRegionRect)
        rotateLinePath.move(to: rotateLineStartPoint);
        rotateLinePath.line(to: rotateLineEndPoint);
        
        let pathForMovingRect = NSBezierPath();
        pathForMovingRect.move(to: rotateLineStartPoint);
        pathForMovingRect.line(to: rotateLineEndPoint);
        
        // let liveLineRectWidth =  rotateLineEndPoint.x - rotateLineStartPoint.x;
        
       // let liveLineRectHeight =  rotateLineEndPoint.y - rotateLineStartPoint.y;
        
        
        let angleInDegrees = NSBezierPath.lineAngleDegreesFrom(point1: rotateLineStartPoint, point2: rotateLineEndPoint)
        
        
        
        /*
         float angleClockwiseRadians = atan2(liveLineRectHeight, liveLineRectWidth);
         if(angleClockwiseRadians < 0)
         angleClockwiseRadians += (2 * 3.14159265);
         float angleInDegrees = angleClockwiseRadians * (180 / 3.14159265);

        */
        
        if(rotationIs3D == false)
        {
        
            for d in selectedDrawables
            {
                let transform = NSAffineTransform();
                
                var initialX : CGFloat = 0;
                var initialY : CGFloat = 0;
                
                initialX = rotateLineStartPoint.x;
                initialY = rotateLineStartPoint.y;
                
                transform.translateX(by: initialX, yBy: initialY)
                transform.rotate(byDegrees: angleInDegrees - lastRotate)
                transform.translateX(by: -1 * initialX, yBy: -1 * initialY)
                
                
                d.transform(using: transform as AffineTransform)
                
                if(dynamicTreeIsInUse)
                {
                    _ = dynamicTree.moveProxy(index:  d.treeProxy, aabb:  d.bounds)
                }
                
            }
        
        }
        else
        {
            /*
            for d in selectedDrawables
            {

                var pitchDegrees : CGFloat = 0;
                pitchDegrees = ((rotateLineEndPoint.x - lastRotateEndPoint.x) / rotateReferencePoint.x) * 360
                
                d.transform3D(axis: "pitch", pointForRotation: rotateLineStartPoint, increment: pitchDegrees)
                
                var yawDegrees : CGFloat = 0;
                yawDegrees = ((rotateLineEndPoint.y - lastRotateEndPoint.y) / rotateReferencePoint.y) * 360
                d.transform3D(axis: "yaw", pointForRotation: rotateLineStartPoint, increment: yawDegrees)
                
                
                d.transform3D(axis: "roll", pointForRotation: rotateLineStartPoint, increment: angleInDegrees - lastRotate)
                
                let imageDrawable = d as? ImageDrawable
                if imageDrawable != nil
                {
                    imageDrawable?.alterImageAccordingToNewQuadCorners();
                }
            
                
                _ = dynamicTree.moveProxy(index:  d.treeProxy, aabb:  d.bounds)
                
                
            }
            */
            
        }
        
        lastRotate = angleInDegrees;
        lastRotateEndPoint = rotateLineEndPoint;
        
        self.setNeedsDisplay(NSUnionRect(rotateLinePath.bounds, updateRectFromPreviousBounds))
        
        /*
        [selectedObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        
        NCTSheetLayerObject *sLO = obj;
        
        NSAffineTransform *transform = [NSAffineTransform transform];
        
        
            
        float initialX;
        float initialY;
        
        initialX = rotateLineStartPoint.x;
        initialY = rotateLineStartPoint.y;
        
        
        [transform translateXBy:initialX yBy:initialY];
        [transform rotateByDegrees:angleInDegrees-lastRotate];
        [transform translateXBy:-initialX yBy:-initialY];
        
        
        
        [sLO transformUsingAffineTransform:transform];
        [sLO updateRotationByDegreesWithDiff:angleInDegrees-lastRotate];
        
        }];
        
      
        */
        
        
        
    }
    
    func executeScalingOperationFromMouseMoved(_ event : NSEvent)
    {
        
        var updateRectFromPreviousBounds = NSZeroRect;
       
       // scaling execution takes place before
        // rotate execution
        if(self.rotateIsOn == false)
        {
            updateRectFromPreviousBounds = scalingLinePath.bounds;
        }
        else
        {
         
            updateRectFromPreviousBounds = scalingLinePath.bounds;
        }
 
            
            updateRectFromPreviousBounds = updateRectFromPreviousBounds.insetBy(dx: -15.0, dy: -15.0)
        
        
            let pointInView = self.convert(event.locationInWindow, from: nil);
        
        
            scalingLineEndPoint = pointInView
    
            if(self.rotateIsOn)
            {
                //scalingLineEndPoint = rotateLineEndPoint
            }
        
            scalingLinePath.removeAllPoints();
        
            let totalRegionRect = self.selectionTotalRegionRectStandardBounds();
        
            scalingLinePath.appendRect(totalRegionRect);
            scalingLinePath.move(to: scalingLineOriginPoint);
            scalingLinePath.line(to: scalingLineEndPoint);
        
            let pathForMovingRect :NSBezierPath = NSBezierPath();
            pathForMovingRect.move(to: scalingLineOriginPoint);
            pathForMovingRect.move(to: scalingLineEndPoint);
        
         //   let liveLineRectWidth : CGFloat =  abs((scalingLineOriginPoint.x - scalingLineEndPoint.x) * 2);
        
         //   let liveLineRectHeight : CGFloat =  abs((scalingLineOriginPoint.y - scalingLineEndPoint.y) * 2);
        
            //
            let scaleFactorFromLineRatio =
                    CGFloat(FBDistanceBetweenPoints(scalingLineOriginPoint, point2: scalingLineEndPoint) /
                    FBDistanceBetweenPoints(scalingLineOriginPoint, point2: scalingReferencePoint))
        
        
            /*
            // same as above
                hypot(scalingLineOriginPoint.x - scalingLineEndPoint.x, scalingLineOriginPoint.y - scalingLineEndPoint.y)
                    / hypot(scalingLineOriginPoint.x - scalingReferencePoint.x, scalingLineOriginPoint.y - scalingReferencePoint.y)
                */
     
            let scaleFactor = 1 + scaleFactorFromLineRatio - lastScale
            //print(scaleFactor);
            //   let scaleFactorForWidth : CGFloat = (liveLineRectWidth / referenceRectWidth)/2;
        
            // let scaleFactorForHeight : CGFloat  = (liveLineRectHeight / referenceRectHeight)/2;
        
        
            for /*(index,*/ drawable/*)*/ in selectedDrawables//.enumerated()
            {
                let transform = NSAffineTransform();
                
                let initialX = scalingLineOriginPoint.x;
                let initialY = scalingLineOriginPoint.y;
                
                transform.translateX(by: initialX, yBy: initialY);
              
                if(scalingOperationType == "scale")
                {
                    
                    if(scalingOctant == 2)
                    {
                        transform.scaleX(by: 1, yBy: scaleFactor)
                    }
                    else if(scalingOctant == 6)
                    {
                        transform.scaleX(by: 1, yBy: scaleFactor)
                    }
                    else if(scalingOctant == 4)
                    {
                        transform.scaleX(by: scaleFactor, yBy: 1)
                    }
                    else if(scalingOctant == 8)
                    {
                        transform.scaleX(by: scaleFactor, yBy: 1)
                    }
                    else
                    {
                        
                        transform.scaleX(by: scaleFactor, yBy: scaleFactor)

                    }
                }
                else if (scalingOperationType == "shear")
                {
                    
                     var transformStruct = transform.transformStruct;
                    
                     let angleInRad = NSBezierPath.lineAngleRadiansFrom(point1: scalingLineOriginPoint, point2: scalingLineEndPoint)
                 
                     if((shearEdge == "bottom") || (shearEdge == "top"))  // 0 - bottom, 1- left, 2 - top, 3 - right)
                     {
                        transformStruct.m21 = tan(lastShearAngle - angleInRad);  // x shear
                     }
                     else if((shearEdge == "left") || (shearEdge == "right"))  // 0 - bottom, 1- left, 2 - top, 3 - right)
                     {
                        transformStruct.m12 = tan(lastShearAngle - angleInRad);  // y shear
                     }
                 
                     lastShearAngle = angleInRad;
                
                
                     transform.transformStruct = transformStruct
                    
                }
                
                transform.translateX(by: -1 * initialX, yBy: -1 * initialY);
                
                drawable.transform(using: transform as AffineTransform)
                
                /*
                 take newWidth, and
                 current width of just-transformed drawable
                 */
         
                // Graphite Glider
                //if(layersManager!.doScaleLineWidth)
                //{
                    
                    
//                    drawable.lineWidth = arrayOfSelectedObjectsLineWidth[index] * scaleFactor
                    
                //}
                
                if(dynamicTreeIsInUse)
                {
                    _ = dynamicTree.moveProxy(index: drawable.treeProxy, aabb: drawable.renderBounds())
                }
            
            }

        self.setNeedsDisplay(scalingLinePath.bounds.union(updateRectFromPreviousBounds).union(self.selectionTotalRegionRectExtendedRenderBounds().insetBy(dx: -5, dy: -5)))
        
      
        lastScale = scaleFactorFromLineRatio
        
    }
    
  
    
    // scalingKeyWasPressed
    func liveScale(uniformFromCenter:Bool, operationType: String)
    {
        if(self.hasSelectedDrawables)
        {
            if(self.scalingIsOn == false)
            {
                if(self.isCarting)
                {
                    self.endCarting();
                }
                else if(((self.isCarting) == false) && self.justCarted)
                {
                    self.justCarted = false;
                }
                
                if(rotateIsOn && (operationType != "scale"))
                {
                    self.endRotateOperation();
                }
   
                self.startScalingOperation(uniformFromCenter:uniformFromCenter, operationType: operationType);
                
                
            }
            else
            {
                self.endScalingOperation();
             
              
                if(rotateIsOn && (operationType != "scale"))
                {
                    self.endRotateOperation();
                }
                
                if(operationType != scalingOperationType)
                {
                    self.startScalingOperation(uniformFromCenter:uniformFromCenter, operationType: operationType);
                }
            }
            
        }
   
    }
    
 
    
    
      // MARK: ---  SELECTING, CARTING KEY PRESSES
    // -section
   /* func selectShadingShapeAtCursor()
    {
        if(self.justCarted)
        {
           self.justCarted = false
        }
        
        if(self.scalingIsOn)
        {
            self.endScalingOperation()
        }
        
        if(self.rotateIsOn)
        {
            self.endRotateOperation();
        }
        
        if(self.isCarting)
        {
            self.endCarting();
        }
        
        
        // equivalent to creating mouseDown
        // for regular shapes, but there is no
        // mousedown for shading shapes selection
        // GraphiteGlider: let didHitShadingShape = self.runHitTestForShadingShapeSelectionArrayOnAllObjects(point: self.mousePointInLayerOutsideOfEventStream());
        
                
        if(selectedDrawables.count > 0)
        {
            tabJustSelected = true
            
        }
        
    }
    */
    
    
    func selectAtCursor()
    {
        
        if(self.justCarted)
        {
           self.justCarted = false
        }
        
        if(self.scalingIsOn)
        {
            self.endScalingOperation()
        }
        
        if(self.rotateIsOn)
        {
            self.endRotateOperation();
        }
        
        if(self.isCarting)
        {
            self.endCarting();
        }
        
        
        let w : NSWindow = self.window!
        let p : NSPoint = w.mouseLocationOutsideOfEventStream
        
        let eventPressure = 0.7111
        
        
        let event = NSEvent.mouseEvent(with: .leftMouseDown, location: p, modifierFlags: NSEvent.ModifierFlags.shift, timestamp: ProcessInfo().systemUptime, windowNumber: (self.window?.windowNumber)!, context: nil, eventNumber: 199, clickCount: 1, pressure: Float(eventPressure))
        
    
   
        self.mouseDown(with: event!)
        
        
        if(selectedDrawables.count > 0)
        {
            tabJustSelected = true
            
        }
        
        
    }
    
    
    func cart()
    {
 
        //if(self.stateArray.contains("control points") == false)
        //{
            let processInfo = ProcessInfo()
            let point : NSPoint = self.window!.mouseLocationOutsideOfEventStream
            

            // if spacebar is carting, the person wants to end carting.
            // then, set the bool that it just carted.
            // then, send mouseUp, which normally happens with a mouse,
            // which is when the drawinglayer clears the cgvectors for dragging
            // for the next time.
            if(self.isCarting)
            {
                self.endCarting();
            }
            else // carting is not on, so
                // either spacebar (carting button) should pick up immediately what is
                // underneath the cursor,
                //  or it should serve as start carting
            {
                if((selectedDrawables.count > 0) && self.justCarted)
                {
                    self.startCarting();
                    
                    if(self.scalingIsOn)
                    {
                        self.endScalingOperation();
                    }
                    
                    if(self.rotateIsOn)
                    {
                        self.endRotateOperation();
                    }
                    
                    // artificial hit selected object, then use mouse drag
                    hitSelectedObjectForDrag = selectedDrawables.first
                    
                   
                    
                    let mouseDragged : NSEvent = NSEvent.mouseEvent(with: .leftMouseDragged, location: point, modifierFlags: NSEvent.ModifierFlags(rawValue: 0), timestamp: processInfo.systemUptime, windowNumber: self.window!.windowNumber, context: nil, eventNumber: 200, clickCount: 1, pressure: 1.0)!
                    
                    self.mouseDragged(with: mouseDragged)
                    
                    
                }
                else if((selectedDrawables.count > 0))
                {
                    
                    self.startCarting();
                    
                    if(self.scalingIsOn)
                    {
                        self.endScalingOperation();
                    }
                    
                    if(self.rotateIsOn)
                    {
                        self.endRotateOperation();
                    }
                    
                    // artificial hit selected object, then use mouse drag
                    hitSelectedObjectForDrag = selectedDrawables.first
                    
                   
                    
                    let mouseDragged : NSEvent = NSEvent.mouseEvent(with: .leftMouseDragged, location: point, modifierFlags: NSEvent.ModifierFlags(rawValue: 0), timestamp: processInfo.systemUptime, windowNumber: self.window!.windowNumber, context: nil, eventNumber: 200, clickCount: 1, pressure: 1.0)!
                    
                    self.mouseDragged(with: mouseDragged)
                    
                    // [self setTabJustSelected:NO];
                }
                else
                {
                    let selectionMouseEvent : NSEvent = NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: NSEvent.ModifierFlags(rawValue: 0), timestamp: processInfo.systemUptime, windowNumber: self.window!.windowNumber, context: nil, eventNumber: 200, clickCount: 1, pressure: 1.0)!
                    
                    self.mouseDown(with: selectionMouseEvent)
                    
                    if(selectedDrawables.isEmpty == false)
                    {
                        self.startCarting()
                        self.isCarting = true
                        
                        self.tabJustSelected = false
                    }
                    
                }
                
            }
            
            //NSLog(@"%i",[self isCarting]);
            
            
            
       // }
        
    }
    
    
    func startCarting()
    {
        
        
        self.isCarting = true
        self.justCarted = false
 
        var totalRegionRect : NSRect = .zero
        
        for i in stride(from: 0, to: selectedDrawables.count, by: 1)
        {
            if(totalRegionRect.isEmpty)
            {
               totalRegionRect = selectedDrawables[i].renderBounds()
            }
            else
            {
                totalRegionRect = totalRegionRect.union(selectedDrawables[i].renderBounds())
                
            }
            
            var cartingRect = NSMakeRect(0, 0, 100, 100)
            cartingRect = CentreRectInRect(cartingRect, selectedDrawables[i].renderBounds())
            totalRegionRect = totalRegionRect.union(cartingRect)


            selectedDrawables[i].isBeingCarted = true
        }
        
        self.setNeedsDisplay(totalRegionRect)

        lineWorkInteractionEntity?.currentLayerDidStartCarting()
        
    }
    
    func endCarting()
    {
        self.justCarted = true
        self.isCarting = false
        
        
        let point : NSPoint = self.window!.mouseLocationOutsideOfEventStream
        
        let processInfo = ProcessInfo()
        
        let mouseUp = NSEvent.mouseEvent(with: NSEvent.EventType.leftMouseUp, location: point, modifierFlags: NSEvent.ModifierFlags.init(rawValue: 0), timestamp: processInfo.systemUptime, windowNumber: self.window!.windowNumber, context: nil, eventNumber: 199, clickCount: 1, pressure: 0.71111)

        self.mouseUp(with: mouseUp!)

        
        var totalRegionRect : NSRect = .zero
        
        for i in stride(from: 0, to: selectedDrawables.count, by: 1)
        {
            if(totalRegionRect.isEmpty)
            {
                totalRegionRect = selectedDrawables[i].renderBounds()
            }
            else
            {
                totalRegionRect = totalRegionRect.union(selectedDrawables[i].renderBounds())
                
            }

            
            var cartingRect = NSMakeRect(0, 0, 100, 100)
            cartingRect = CentreRectInRect(cartingRect, selectedDrawables[i].renderBounds())
            totalRegionRect = totalRegionRect.union(cartingRect)

            
            selectedDrawables[i].isBeingCarted = false
        }
        
        self.setNeedsDisplay(totalRegionRect)

        lineWorkInteractionEntity?.currentLayerDidEndCarting();
        
    }
    
  
    
    // MARK: MOUSE EVENTS
    override func mouseDown(with event: NSEvent)
    {

        initialMouseDragged = true;
        
        let mousePoint : NSPoint = self.convert(event.locationInWindow, from: nil);
        
        initialMouseDownPoint = mousePoint;
        
        
        let flags = event.modifierFlags;
        var shiftKey = false
        if(flags.contains(.shift))
        {
            shiftKey = true;
        }
        

        var objectHit : Bool = false;
        
        
        if((self.isCarting == true))
        {
            self.cart();
        }
        else if((self.isCarting == false) && (self.stateArray.contains("control points") == false))
        //(selectedControlPointsByPartcode.isEmpty) ) //
        {
            if(selectedDrawables.count > 0) // if selected objects are in the array
            {
                var hitSelectedObj :FMDrawable?
                
                let hitTestReturnTuple = runHitTestOnAllObjects(point: mousePoint)
                
                // go through all selected objects and check
                // for whether a selected object was clicked
                selectedDrawables.sort(by: { $0.drawingOrderIndex > $1.drawingOrderIndex })
                
                for drawable in selectedDrawables
                {
                    let hitResult = drawable.hitTestForClickBasedOnStrokeOrFillState(point:mousePoint);
                    
                    if(hitResult.didHit)
                    {
                        
                        objectHit = true;
                        hitSelectedObj = drawable;
                        
                        // send the object the mouseDown event
                       // drawable.mouseDown(event:event);
                        
                        hitSelectedObjectForDrag = hitSelectedObj;
                        
                        break;
                    }
                    
                }// end for
 
                
                // check for any object that sits on top of
                // selected object.  otherwise,
                // objects that overlap a selected object will not be hit
                // and the selected object will be hit instead
                if((hitTestReturnTuple.didHitObj == true) && objectHit
                    && (hitTestReturnTuple.hitDrawable!.drawingOrderIndex > hitSelectedObj!.drawingOrderIndex))
                {
               
                            //hitSelectedObj = hitTestReturnTuple.hitDrawable
                            objectHit = false
            

                 
                }
            

                
                if((objectHit == true)  && (shiftKey) )
                    // a selected object was hit
                    // and shift key was down
                {
                    
                    /*
                    var selectionRemoveUpdate : NSRect =
                        (hitSelectedObj?.bounds)!;
                    selectionRemoveUpdate.size.width += 8;
                    selectionRemoveUpdate.size.height += 8;
                    selectionRemoveUpdate.origin.x -= 4;
                    selectionRemoveUpdate.origin.y -= 4;
                   */
                    
                    let selectionRemoveUpdate : NSRect = (hitSelectedObj?.renderBounds())!
                    
                    
                    hitSelectedObj?.isSelected = false
                   
                    if let index = selectedDrawables.firstIndex(of:hitSelectedObj!)
                    {
                        selectedDrawables.remove(at: index)
                        
                        lineWorkInteractionEntity?.currentLayerDidDeselectASingleObject()
                    }
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DeselectedSingleObject"), object: NSDocumentController.shared.currentDocument, userInfo: [self:"drawing layer"])
                    
                    self.setNeedsDisplay(selectionRemoveUpdate)
                    
                }
                else if((objectHit == false) && (shiftKey))
                    // no selected object was hit
                    // but check if other objects were hit
                    // because of NSShiftKeyMask
                {
                    objectHit =
                        self.runHitTestForSelectionArrayOnAllObjects(point: mousePoint)
                    
                    
                }
                else if((objectHit == false) && (event.pressure != 0.71111))
                    // we use .71111 to indicate that the event came from
                    //  keydown and not the mouse
                    
                    // no selected object was hit
                    // but select other object
                    // possibly
                {
                    self.clearOutSelections();
                    objectHit = self.runHitTestForSelectionArrayOnAllObjects(point: mousePoint)
                    
                }
                
            }
            
            else if((selectedDrawables.count == 0) || (shiftKey) )
                // if no selected objects
                // are in the array
            {
                
                
                objectHit = self.runHitTestForSelectionArrayOnAllObjects(point: mousePoint)
            }
            
            
            // we use .71111 to indicate that the event came from
            //  keydown and not the mouse
            if(objectHit == false && (event.pressure != 0.71111))
                // mousedown but none of
                // the selected objects were
                // hit and no other objects were hit,
                // so clear out the selections array
            {
                
                self.clearOutSelections()
                
            }
            
            
        }
          
      
    }
    
    
     override func mouseUp(with event: NSEvent)
     {
        
            if(isInDragging == true)
            {
                guard self.parentDocument != nil else {
                    fatalError("no parent document for layer")
                }


                let undoManager : UndoManager = self.parentDocument!.undoManager!
                
                if(undoManager.isRedoing == false)
                {
                    undoManager.registerUndo(withTarget: self) { (self) in
                        
                        print("undo")
                        /*
                        var updateRect = self.selectionTotalRegionRectExtendedRenderBounds()
                        for (index, selected) in self.selectedDrawables.enumerated()
                        {
                            if(index < self.draggedOffsetCGVectors.count)
                            {
                                selected.nctTranslateBy(vector: CGVector.init(dx: 10, dy: 10))
                               updateRect = updateRect.union(selected.renderBounds())
                                //selected.nctTranslateBy(vector:self.draggedOffsetCGVectors[index])
                            }
                        }
                     
                        self.setNeedsDisplay(updateRect)*/
                    }
                    
                    undoManager.setActionName("Drag/Cart Objects")
                }
            
                draggedOffsetCGVectors.removeAll()
                anchorPointOffset = CGVector.zero
                lockpointOffsetCGVector = CGVector.zero;
            }
            
            isInDragging = false;
            
            initialMouseDragged = true;
            
            
        
    }

  
    func shouldReceiveMouseMoved() -> Bool
    {
        return (self.isCarting || self.rotateIsOn || self.scalingIsOn)
    }
  
    override func mouseMoved(with event: NSEvent) {
        

        // sent from tool controller if self is carting
        if(self.isCarting)
        {

            DispatchQueue.main.async
            {
                
                self.mouseDragged(with: event)
            }
            
        }
        
     
        
  
        if(self.scalingIsOn)
        {
            DispatchQueue.main.async
            {
                
                
                self.executeScalingOperationFromMouseMoved(event);
            }
        }
        
        if(self.rotateIsOn)
        {
          
           DispatchQueue.main.async
            {
                
                self.executeRotateOperationFromMouseMoved(event);
                
           }
        }
        
        
        
    }
    
    override func mouseDragged(with event: NSEvent)
    {
        
        isInDragging = true;
        
        let mousePt : NSPoint = self.convert(event.locationInWindow, from: nil)
        
        /*
         // Graphite Glider
         if(layersManager!.drawingEntityManager!.snapWhileCarting && (selectedDrawables.count > 0) && (self.isUsingSelectRectangle == false) )
         {
         let snappingPoint = snappingPointforCarting(mousePt);
         
         if(snappingPoint != mousePt)
         {
         mousePt = snappingPoint
         //    self.layersManager?.activeLayer.currentLockPoint = mousePt;
         //      self.layersManager?.activeLayer.isShowingLockPoint = true;
         }
         else
         {
         
         }
         
         
         }*/
        
        
        
        
        
        // let mouseDraggingPoint = mousePt;
        
        // the mouse had just been clicked,
        // so create drag vectors for every object in the selected obj array.
        // if there is a lockpoint visible, make a drag vector for that.
        if (initialMouseDragged && (selectedDrawables.count > 0) && (self.isUsingSelectRectangle == false))
        {
            
            
            if((selectedDrawables.count > 1) && (selectedDrawables.first == hitSelectedObjectForDrag))
            {
                if let index = selectedDrawables.firstIndex(of:hitSelectedObjectForDrag!) {
                    selectedDrawables.remove(at: index)
                }
                
                selectedDrawables.insert(hitSelectedObjectForDrag, at: 0)
                
            }
            
            //  print(selectedDrawables.count)
            for selected in selectedDrawables
            {
                
                var constantDragVectorForObj : CGVector = CGVector();
                let boundsRectForObj : NSRect = selected.renderBounds();
                constantDragVectorForObj.dx = mousePt.x - boundsRectForObj.origin.x;
                constantDragVectorForObj.dy = mousePt.y - boundsRectForObj.origin.y;
                
                draggedOffsetCGVectors.append(constantDragVectorForObj)
                
            }
            
            
            if(anchorPointForIncrementTransform != NSNotFoundPoint)
            {
                anchorPointOffset.dx = mousePt.x - anchorPointForIncrementTransform.x
                anchorPointOffset.dy = mousePt.y - anchorPointForIncrementTransform.y
            }
            
            
            initialMouseDragged = false;
            
        }
        
        if((selectedDrawables.count > 0) && (self.isUsingSelectRectangle == false))
        {
            
            // mouse point after initial drag has
            // new implication because it is now about
            // adjusting after the first drag
            
            
            var newUpdateRect : NSRect = NSRect.zero;
            
            for (index, drawable) in selectedDrawables.enumerated()
            {
                
                let boundsForObject = drawable.renderBounds();
                newUpdateRect = NSUnionRect(newUpdateRect, drawable.renderBounds());
                
                var dragTransform : AffineTransform = AffineTransform()
                
                let dragOffsetVector : CGVector = draggedOffsetCGVectors[index];
                
                dragTransform.translate(x:mousePt.x - boundsForObject.origin.x - dragOffsetVector.dx,
                                        y: mousePt.y - boundsForObject.origin.y - dragOffsetVector.dy)
                
                
                drawable.transform(using: dragTransform)
                
                if(dynamicTreeIsInUse)
                {
                    _ = dynamicTree.moveProxy(index: drawable.treeProxy, aabb: drawable.renderBounds())
                }
                
                
            }
            
            
            
            /*
             Graphite Glider
             if(layersManager!.panelsController.sizeInspectionPopover.isShown)
             {
             layersManager!.panelsController.updateXYInspectSize();
             
             }
             */
            
            
            if(anchorPointForIncrementTransform != NSNotFoundPoint)
            {
                var anchorPointDragTransform : AffineTransform = AffineTransform()
                
                
                anchorPointDragTransform.translate(x:mousePt.x - anchorPointForIncrementTransform.x - anchorPointOffset.dx,
                                                   y: mousePt.y - anchorPointForIncrementTransform.y - anchorPointOffset.dy)
                
                anchorPointForIncrementTransform = anchorPointDragTransform.transform(anchorPointForIncrementTransform)
                
                
            }
            
            
            let magnification = self.enclosingScrollView!.magnification
            var bufferMargin : CGFloat = 68.0;
            
            
            
            if(magnification < 1)
            {
                bufferMargin = bufferMargin * ( 1/magnification);
            }
            
            newUpdateRect.size.height += bufferMargin;
            newUpdateRect.size.width += bufferMargin;
            newUpdateRect.origin.x -= bufferMargin / 2;
            newUpdateRect.origin.y -= bufferMargin / 2;
            
            self.setNeedsDisplay(newUpdateRect)
            
        }
        
        
    }
    

      
  

 

    // MARK: SELECTIONS
    
    func makeSelectedDrawablesFromRect(_ rect : NSRect)
    {
        // current documentRect
        // run query from dynamic tree for
        // makeArrayTheSelectedDrawables(array)
        
        var rectForProcessing = NSMakeRect(rect.minX, rect.minY, rect.width, rect.height);
        
        if(rectForProcessing.size.width < 0)
        {
            rectForProcessing.size.width = -1 * rectForProcessing.size.width
            rectForProcessing.origin.x = rectForProcessing.origin.x - rectForProcessing.size.width
        }
        
        if(rectForProcessing.size.height < 0)
        {
            rectForProcessing.size.height = -1 * rectForProcessing.size.height
            rectForProcessing.origin.y = rectForProcessing.origin.y - rectForProcessing.size.height
            
        }
        
        var resultingSelection : [FMDrawable] = []


        if(dynamicTreeIsInUse)
        {
            var fmDrawablesInRectBounds = dynamicTree.queryToGetArray(aabb: rectForProcessing)
            
            fmDrawablesInRectBounds.sort(by: { $0.drawingOrderIndex > $1.drawingOrderIndex })
            
            
            
            for drawable in fmDrawablesInRectBounds
            {
                
                if(drawable.intersectsRect2(rectForProcessing))
                {
                    resultingSelection.append(drawable)
                }
                
            }
        }
        else
        {
                resultingSelection = orderingArray.filter { (fmDrawable) -> Bool in
                    fmDrawable.intersectsRect2(rectForProcessing)
                }
                
        }
        self.makeArrayTheSelectedDrawables(arrayToMakeSelected: resultingSelection)
        
    }
    
    
    func makeArrayTheSelectedDrawables( arrayToMakeSelected:[FMDrawable])
    {
    
        self.clearOutSelections()
        
        var updateRectForDrawable : NSRect = .zero
        
        for drawable in arrayToMakeSelected
        {
            if(updateRectForDrawable.isEmpty)
            {
                updateRectForDrawable = drawable.renderBounds()
            }
            else
            {
               updateRectForDrawable = updateRectForDrawable.union(drawable.renderBounds())
            }
            
            selectedDrawables.append(drawable)
            drawable.isSelected = true
            
            
        }
        
        if(arrayToMakeSelected.isEmpty == false)
        {
            lineWorkInteractionEntity?.currentLayerDidSelectObjects()
        }
        
        self.setNeedsDisplay(updateRectForDrawable)
        
    }
    
    
    func clearOutSelections()
    {
    
       
    
        if(rotateIsOn)
        {
            endRotateOperation();
        }
        
        if(scalingIsOn)
        {
            endScalingOperation();
        }
        
        if(isCarting)
        {
            cart()
        }
        
       
        
        var updateRectForDeselected : NSRect = .zero
        for drawable in self.selectedDrawables
        {
            drawable.isSelected = false

            if let fmStroke = drawable as? FMStroke
            {
                if(fmStroke.needsReprocessing)
                {
                    self.doProcessingOfFMStroke(fmStroke: fmStroke, doBackgroundThread: true);
                }
            }

            updateRectForDeselected = updateRectForDeselected.unionProtectFromZeroRect(drawable.renderBounds())

        }

        self.setNeedsDisplay(updateRectForDeselected.insetBy(dx: -10, dy: -10))
           
        self.selectedDrawables.removeAll()
        
        

        let oldAnchorPoint = anchorPointForIncrementTransform;
        
        anchorPointForIncrementTransform = NSNotFoundPoint
        anchorPointOffset = CGVector.zero

        if(oldAnchorPoint != NSNotFoundPoint)
        {
            let r = NSMakeRect(0, 0, 20, 20);
            
            self.setNeedsDisplay(r.centerOnPoint(oldAnchorPoint))
        }


        lineWorkInteractionEntity?.currentLayerDidDeselectAllObjects()


        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SelectionsClearedOut"),
                                        object: NSDocumentController.shared.currentDocument,
        userInfo: [self:"paperLayer"])
        
    }
    
    
    
    func applyColorToSelectedDrawablesTargetTrait(color : NSColor)
    {
    
        for drawable in selectedDrawables
        {
            drawable.fmInk.mainColor = color;
        }
    
        redisplaySelectedTotalRegionRect();
        
    }

    func thickenLineWidthOfSelectedDrawables()
    {
    
        let oldRect = self.selectionTotalRegionRectExtendedRenderBounds()
        
        for drawable in selectedDrawables
        {
            drawable.lineWidth = min(inkAndLineSettingsManager!.maxStrokeWidth,drawable.lineWidth + 1.0)
        }
        
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldRect).insetBy(dx: -5.0, dy: -5.0))
        
    }
    
    func thinLineWidthOfSelectedDrawables()
    {
    
        let oldRect = self.selectionTotalRegionRectExtendedRenderBounds()
    
        for drawable in selectedDrawables
        {
            drawable.lineWidth = max(0.5,drawable.lineWidth - 1.0)
        }
    
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldRect).insetBy(dx: -5.0, dy: -5.0))
    }
    
    func thinSelectedDrawables()
    {
    
        let oldRect = self.selectionTotalRegionRectExtendedRenderBounds()
    
        for drawable in selectedDrawables
        {
            if let fmStroke = drawable as? FMStroke
            {
                if(fmStroke.fmInk.representationMode == .inkColorIsStrokeOnly)
                {
                    fmStroke.lineWidth = max(0.5,fmStroke.lineWidth - 1.0)
                    
                }
                else
                {
                    
                    fmStroke.thinFMStrokePoints(by:1.0)
                    
                    if(fmStroke.fmInk.brushTip.isUniform == false)
                    {
                        fmStroke.isFinished = false;
                        fmStroke.needsReprocessing = true;
                    }
                    
                    if(fmStroke.fmInk.brushTip.isUniform)
                    {
                        doProcessingOfFMStroke(fmStroke: fmStroke, doBackgroundThread: true)
                    }
                    
                }
            }
            else
            {
                drawable.lineWidth = max(0.5,drawable.lineWidth - 1.0)
            }
        
        }
    
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldRect).insetBy(dx: -5.0, dy: -5.0))
    }
    
    func thickenSelectedDrawables()
    {
        let oldRect = self.selectionTotalRegionRectExtendedRenderBounds()
        
        for drawable in selectedDrawables
        {
            if let fmStroke = drawable as? FMStroke
            {
                if(fmStroke.fmInk.representationMode == .inkColorIsStrokeOnly)
                {
                    fmStroke.lineWidth = min(inkAndLineSettingsManager!.maxStrokeWidth,fmStroke.lineWidth + 1.0)

                }
                else
                {
                    fmStroke.thickenFMStrokePoints(by:1.0)
                    
                    if(fmStroke.fmInk.brushTip != .uniform)
                    {
                        fmStroke.isFinished = false;
                        fmStroke.needsReprocessing = true;
                    }
                    
                    if(fmStroke.fmInk.brushTip.isUniform)
                    {
                        doProcessingOfFMStroke(fmStroke: fmStroke, doBackgroundThread: true)
                    }
                }
            }
            else
            {
                drawable.lineWidth = min(inkAndLineSettingsManager!.maxStrokeWidth,drawable.lineWidth + 1.0)
            }
            
            
            
        }
        
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldRect).insetBy(dx: -5.0, dy: -5.0))

    }
    
    
    func makeSelectedBasedOnRepMode(repMode: RepresentationMode)
    {
        switch repMode {
        case .inkColorIsStrokeOnly:
            makeSelectedOnlyStroke()
        case .inkColorIsFillOnly:
            makeSelectedOnlyFill()
        case .inkColorIsStrokeAndFill:
            makeSelectedFillStroke()
        case .inkColorIsStrokeWithSeparateFill:
            makeSelectedFillStrokeSplit()
        }
    
    }
    
    func makeSelectedOnlyStroke()
    {
        let oldRect = self.selectionTotalRegionRectExtendedRenderBounds()
        
        for drawable in selectedDrawables
        {
            drawable.fmInk.representationMode = .inkColorIsStrokeOnly
        }
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldRect))
        
    }
    
    func makeSelectedOnlyFill()
    {
        let oldRect = self.selectionTotalRegionRectExtendedRenderBounds()
        
        for drawable in selectedDrawables
        {
            drawable.fmInk.representationMode = .inkColorIsFillOnly
        }
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldRect))
            
    }
    
    func makeSelectedFillStroke()
    {
        let oldRect = self.selectionTotalRegionRectExtendedRenderBounds()
        
        for drawable in selectedDrawables
        {
            drawable.fmInk.representationMode = .inkColorIsStrokeAndFill
        }
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldRect))
        
    }
    
    func makeSelectedFillStrokeSplit()
    {
        let oldRect = self.selectionTotalRegionRectExtendedRenderBounds()
        
        for drawable in selectedDrawables
        {
            drawable.fmInk.representationMode = .inkColorIsStrokeWithSeparateFill
        }
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldRect))
        
    }
    
    // MARK: ---  STAMPING
    
    func stampByUnion()
    {
        if(self.hasSelectedDrawables)
        {
            
            let stampDrawable : FMDrawable = selectedDrawables[0].copy() as! FMDrawable;
            
            var layerDrawablesToBeReplacedByUnion : [FMDrawable] = [];
            
            var aggSettings = FMDrawableAggregratedSettings.init(fmDrawable:stampDrawable);
            
            let boundsOfDrawableBeingStamped = stampDrawable.renderBounds();
            
            let stampUnionResult : NSBezierPath  = NSBezierPath();
            
            var doStampUnion = false;
            
            var layerDrawablesThatOverlapWithStampDrawable : [FMDrawable] = []
            
            if(self.dynamicTreeIsInUse)
            {
                layerDrawablesThatOverlapWithStampDrawable = dynamicTree.queryToGetArray(aabb: boundsOfDrawableBeingStamped)
            }
            else
            {
                
                layerDrawablesThatOverlapWithStampDrawable = orderingArray.filter { (fmDrawable) -> Bool in
                    NSIntersectsRect(fmDrawable.renderBounds(), boundsOfDrawableBeingStamped)
                }
                
            }
            
            if(layerDrawablesThatOverlapWithStampDrawable.isEmpty == false)
            {
                
                // Remove the stamp drawable from the query results
                // because it will be returned when the tree is queried with those bounds.
                if let indexOfStampDrawable = layerDrawablesThatOverlapWithStampDrawable.firstIndex(where: {$0 === selectedDrawables[0]})
                {
                    layerDrawablesThatOverlapWithStampDrawable.remove(at: indexOfStampDrawable)
                }
                
                layerDrawablesThatOverlapWithStampDrawable.sort(by: { $0.drawingOrderIndex < $1.drawingOrderIndex })
                
                
                var stampUnionResultTemp = NSBezierPath()
                
                stampUnionResult.append(stampDrawable)
                
                layerDrawablesThatOverlapWithStampDrawable.forEach { (layerDrawable) in
                    
                    if(pathsIntersect(path1: layerDrawable, path2: stampDrawable))
                    {
                        if((doStampUnion == false) && (inkAndLineSettingsManager!.receiverDeterminesStyle))
                        {
                            aggSettings = FMDrawableAggregratedSettings.init(fmDrawable: layerDrawable);
                        }
                        
                        doStampUnion = true;
                        
                        stampUnionResultTemp = stampUnionResult.fb_union(layerDrawable)
                        stampUnionResult.removeAllPoints()
                        stampUnionResult.append(stampUnionResultTemp)
                        
                        layerDrawablesToBeReplacedByUnion.append(layerDrawable);
                    }
                    
                }
                
                if(doStampUnion)
                {
                    var d = FMDrawable()
                    d.append(stampUnionResult)
                    d.windingRule = NSBezierPath.WindingRule.nonZero
                    
                    
                    
                    
                    for a in layerDrawablesToBeReplacedByUnion
                    {
                        self.removeDrawable(a)
                    }
                    
                 
                    
                    aggSettings.applyToDrawable(fmDrawable: &d)
                    
                    
                    self.basicAddDrawable(drawable:d)
                    
                    
                }
                else if(inkAndLineSettingsManager!.depositIfNoOverlap)
                {
                    self.stamp(onTop: true, forceRegularStamping: true)
                }
                else
                {
                    flashObjectsOnLayerForCombinatoricsWarning(selectedDrawables, autoreverse: true,duration: 0.17,fillColor:NSColor.red.withAlphaComponent(0.5))
                }
                
            }
            else if(inkAndLineSettingsManager!.depositIfNoOverlap)
            {
                self.stamp(onTop: true, forceRegularStamping: true)
            }
            else
            {
                flashObjectsOnLayerForCombinatoricsWarning(selectedDrawables, autoreverse: true,duration: 0.17,fillColor:NSColor.red.withAlphaComponent(0.5))
            }

            
        }
    }
    
    func stampBySubtraction()
    {
        if(self.hasSelectedDrawables)
        {
            
            let stampDrawable : FMDrawable = selectedDrawables[0].copy() as! FMDrawable;
            
            let boundsOfDrawableBeingStamped = stampDrawable.renderBounds();
            
            var aggSettings = FMDrawableAggregratedSettings.init(fmDrawable:stampDrawable);
            
            var doStampSubtraction = false;
            
            var layerDrawablesThatOverlapWithStampDrawable : [FMDrawable] = [];
            if(self.dynamicTreeIsInUse)
            {
                layerDrawablesThatOverlapWithStampDrawable = dynamicTree.queryToGetArray(aabb: boundsOfDrawableBeingStamped)
            }
            else
            {
                
                layerDrawablesThatOverlapWithStampDrawable = orderingArray.filter { (fmDrawable) -> Bool in
                    NSIntersectsRect(fmDrawable.renderBounds(), boundsOfDrawableBeingStamped)
                }
                
            }
            
            
            if(layerDrawablesThatOverlapWithStampDrawable.isEmpty == false)
            {
                
                // Remove the stamp drawable from the query results
                // because it will be returned when the tree is queried with those bounds.
                if let indexOfStampDrawable = layerDrawablesThatOverlapWithStampDrawable.firstIndex(where: {$0 === selectedDrawables[0]})
                {
                    layerDrawablesThatOverlapWithStampDrawable.remove(at: indexOfStampDrawable)
                }
                
                layerDrawablesThatOverlapWithStampDrawable.sort(by: { $0.drawingOrderIndex < $1.drawingOrderIndex })
                
                
                var stampSubtractionResultTemp = NSBezierPath()
                
                
                for (index, layerDrawable) in layerDrawablesThatOverlapWithStampDrawable.enumerated()
                {
                    
                    if(pathsIntersect(path1: layerDrawable, path2: stampDrawable))
                    {
                        
                        if((doStampSubtraction == false) && (inkAndLineSettingsManager!.receiverDeterminesStyle))
                        {
                            aggSettings = FMDrawableAggregratedSettings.init(fmDrawable: layerDrawable);
                        }
                
                        stampSubtractionResultTemp = layerDrawable.fb_difference(stampDrawable)
                        
                        if(stampSubtractionResultTemp.isEmpty == false)
                        {
                            let oldBoundsRect = layerDrawable.renderBounds();
                            layerDrawable.removeAllPoints()
                            layerDrawable.append(stampSubtractionResultTemp);
                            
                            
                            aggSettings.applyToDrawable(fmDrawable: &layerDrawablesThatOverlapWithStampDrawable[index])
                            
                            
                            if(inkAndLineSettingsManager!.separateSubtractionPieces)
                            {
                                let outsideSubpathsArray = layerDrawable.extractAnySubpathsWithNoOverlapWithTheInitialPath();
                                if(outsideSubpathsArray.isEmpty == false)
                                {
                                    for i in 0..<outsideSubpathsArray.count
                                    {
                                        var fmdrawable = outsideSubpathsArray[i]
                                        
                                        let theAggForSubPath = FMDrawableAggregratedSettings.init(fmDrawable: layerDrawable);
                                        theAggForSubPath.applyToDrawable(fmDrawable: &fmdrawable)
                                        basicAddDrawable(drawable: fmdrawable)
                                    }
 
                                }
                                    
                                
                                
                            }
                            
                            
                            if(dynamicTreeIsInUse)
                            {
                                updateDrawableForDynamicTree(layerDrawable, oldRect: oldBoundsRect)
                            }
                            
                           
                            
                            doStampSubtraction = true;
                        }
                        
                    }
                    
                }
                
                
                if(doStampSubtraction)
                {
                
                    
                }
                else if(inkAndLineSettingsManager!.depositIfNoOverlap)
                {
                    self.stamp(onTop: true, forceRegularStamping: true)
                }
                else
                {
                    flashObjectsOnLayerForCombinatoricsWarning(selectedDrawables, autoreverse: true,duration: 0.17,fillColor:NSColor.red.withAlphaComponent(0.5))
                }
                
                
                
            }
            else if(inkAndLineSettingsManager!.depositIfNoOverlap)
            {
                self.stamp(onTop: true, forceRegularStamping: true)
            }
            else
            {
                flashObjectsOnLayerForCombinatoricsWarning(selectedDrawables, autoreverse: true,duration: 0.17,fillColor:NSColor.red.withAlphaComponent(0.5))
            }

            
        }// END  if(self.hasSelectedDrawables)
        
    }
    
    func stampByIntersection()
    {
        if(self.hasSelectedDrawables)
        {
            
            let stampDrawable : FMDrawable = selectedDrawables[0].copy() as! FMDrawable;
            
            let boundsOfDrawableBeingStamped = stampDrawable.renderBounds();
            
            var aggSettings = FMDrawableAggregratedSettings.init(fmDrawable:stampDrawable);
            
            var doStampIntersection = false;
            
            var layerDrawablesThatOverlapWithStampDrawable : [FMDrawable] = [];
            if(self.dynamicTreeIsInUse)
            {
                layerDrawablesThatOverlapWithStampDrawable = dynamicTree.queryToGetArray(aabb: boundsOfDrawableBeingStamped)
            }
            else
            {
                
                layerDrawablesThatOverlapWithStampDrawable = orderingArray.filter { (fmDrawable) -> Bool in
                    NSIntersectsRect(fmDrawable.renderBounds(), boundsOfDrawableBeingStamped)
                }
                
            }
            
            
            if(layerDrawablesThatOverlapWithStampDrawable.isEmpty == false)
            {
                
                // Remove the stamp drawable from the query results
                // because it will be returned when the tree is queried with those bounds.
                if let indexOfStampDrawable = layerDrawablesThatOverlapWithStampDrawable.firstIndex(where: {$0 === selectedDrawables[0]})
                {
                    layerDrawablesThatOverlapWithStampDrawable.remove(at: indexOfStampDrawable)
                }
                
                layerDrawablesThatOverlapWithStampDrawable.sort(by: { $0.drawingOrderIndex < $1.drawingOrderIndex })
                
                
                var stampIntersectionResultTemp = NSBezierPath()
                
                
                  for (index, layerDrawable) in layerDrawablesThatOverlapWithStampDrawable.enumerated()
                {

                    
                    if(pathsIntersect(path1: layerDrawable, path2: stampDrawable))
                    {
                        if((doStampIntersection == false) && inkAndLineSettingsManager!.receiverDeterminesStyle)
                        {
                            aggSettings = FMDrawableAggregratedSettings.init(fmDrawable: layerDrawable);
                        }
                        
                        stampIntersectionResultTemp = layerDrawable.fb_intersect(stampDrawable)
                        
                        if(stampIntersectionResultTemp.isEmpty == false)
                        {
                            let oldBoundsRect = layerDrawable.renderBounds();
                            layerDrawable.removeAllPoints()
                            layerDrawable.append(stampIntersectionResultTemp);
                            aggSettings.applyToDrawable(fmDrawable: &layerDrawablesThatOverlapWithStampDrawable[index])
                            if(dynamicTreeIsInUse)
                            {
                                updateDrawableForDynamicTree(layerDrawable, oldRect: oldBoundsRect)
                            }
                            doStampIntersection = true;
                        }
                        
                    }
                    
                }
                
                
                if(doStampIntersection)
                {
                    /*
                     let d = Drawable()
                     d.append(stampIntersectionResult)
                     //d.windingRule = NSBezierPath.WindingRule.evenOdd
                     
                     if(d.hasLineShape)
                     {
                     d.hasLineShape = false
                     }
                     
                     
                     
                     
                     for a in layerDrawablesToBeReplacedByIntersection
                     {
                     self.removeDrawable(a)
                     }
                     
                     
                     
                     
                     self.basicAddDrawable(drawable:d)
                     */
                    
                }
                else if(inkAndLineSettingsManager!.depositIfNoOverlap)
                {
                    self.stamp(onTop: true, forceRegularStamping: true)
                }
                else
                {
                    flashObjectsOnLayerForCombinatoricsWarning(selectedDrawables, autoreverse: true,duration: 0.17,fillColor:NSColor.red.withAlphaComponent(0.5))
                }

                
                
                
            }
            else if(inkAndLineSettingsManager!.depositIfNoOverlap)
            {
                self.stamp(onTop: true, forceRegularStamping: true)
            }
        }// END  if(self.hasSelectedDrawables)
        
    }
    
    func stamp(onTop:Bool, forceRegularStamping:Bool)
    {
        if((self.selectedDrawables.isEmpty == false) )//&& (self.isCarting))
        {
            
            self.reindexOrderingArrayDrawables()
            
            let selectedDrawablesSortedByIndex =
                selectedDrawables.sorted(by: {$0.drawingOrderIndex < $1.drawingOrderIndex })
            
            var indexForInsertion : Int = selectedDrawablesSortedByIndex.first!.drawingOrderIndex
        
            if(onTop == false)
            {
                indexForInsertion = selectedDrawablesSortedByIndex.last!.drawingOrderIndex + 1;
                
                if(indexForInsertion < 0)
                {
                    indexForInsertion = 0;
                }
            }
            
        
            if(forceRegularStamping == false)
            {
                if(inkAndLineSettingsManager!.combinatoricsModeIsOn)
                {
                    if(inkAndLineSettingsManager!.combinatoricsMode == .union)
                    { stampByUnion()}
                    else if(inkAndLineSettingsManager!.combinatoricsMode == .subtraction)
                    { stampBySubtraction() }
                    else if(inkAndLineSettingsManager!.combinatoricsMode == .intersection)
                    {stampByIntersection()}
                    
                    return;
                }
            }
           
            
            var drawablesForPasteUndo : [FMDrawable] = [];
            
            for drawable in selectedDrawablesSortedByIndex
            {
                let drawableStampCopy = drawable.copy() as! FMDrawable
                
                
                drawablesForPasteUndo.append(drawableStampCopy);
                
                orderingArray.insert(drawableStampCopy, at: indexForInsertion)
               
                indexForInsertion += 1
                
       
                 
                //orderingArray.append(drawableStampCopy)
                
                drawableStampCopy.drawingOrderIndex = orderingArray.firstIndex(where: {$0 === drawableStampCopy})!
                drawableStampCopy.treeProxy = dynamicTree.createProxy(aabb: drawable.renderBounds(), item: drawableStampCopy)
                
                
                self.setNeedsDisplay(drawableStampCopy.renderBounds())
                
            
             
              let undoManager : UndoManager = self.parentDocument!.undoManager!
            
            
            undoManager.registerUndo(withTarget: self) { (self) in
                
                self.removeArrayOfDrawables(drawablesForPasteUndo)
                
            }
            
            undoManager.setActionName("Stamp Shape(s)")
            
            if(undoManager.isUndoing)
            {
                undoManager.setActionName("Delete Shapes")
            }
            
            
           }
            self.reindexOrderingArrayDrawables()
            
            
          
            
        }
        
    }
    
 
    
     // MARK: ---  TRANSLATE SELECTED OBJECTS BY ARROW KEYS
    
    func moveSelectedUpdates(affineTransform: AffineTransform)//diff: CGVector)
    {
        
        if(self.isCarting)
        {
            // because refreshForTransformByIncrement
            // works by artifically calling mouseDragged,
            // the anchorPointForIncrementTransform is not
            // altered because it depends on mouse movement
            // to alter it using mouseDragged.
            self.refreshForTransformByIncrement()
        }
            // therefore, here is a direct manipulation
            // of the anchorPointOffset
            if(anchorPointForIncrementTransform != NSNotFoundPoint)
            {

               anchorPointForIncrementTransform = affineTransform.transform(anchorPointForIncrementTransform)
           
            }
            
            
       
    }

    func moveSelectedBy(degrees:CGFloat, distance:CGFloat)
    {
        if(self.hasSelectedDrawables)
        {
            let oldTotalRect : NSRect = self.selectionTotalRegionRectExtendedRenderBounds()
         
            let radians :CGFloat = deg2rad(degrees)
            
         
            let affineTransform = AffineTransform(translationByX: distance * cos(radians), byY: distance * sin(radians));
            
            for drawable in self.selectedDrawables
            {
                drawable.transform(using: affineTransform)
                
                if(dynamicTreeIsInUse)
                {
                    _ = dynamicTree.moveProxy(index: drawable.treeProxy, aabb: drawable.renderBounds())
                }
            }
            if(oldTotalRect != NSRect.zero)
            {
                self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldTotalRect))
            }
            
            /*
            //Graphite Glider
            if(layersManager!.panelsController.sizeInspectionPopover.isShown)
            {
                layersManager!.panelsController.updateXYInspectSize();
             
            }
            */
            
            moveSelectedUpdates(affineTransform: affineTransform);
        
        
        }
    
    }
    
    func moveSelectedLeft()
    {
        if(selectedDrawables.isEmpty == false)
        {
            let oldTotalRect : NSRect = self.selectionTotalRegionRectExtendedRenderBounds()
         
            let affineTransform = AffineTransform(translationByX: -1.0, byY: 0);
            for drawable in self.selectedDrawables
            {
                drawable.transform(using: affineTransform)
                if(dynamicTreeIsInUse)
                {
                    _ = dynamicTree.moveProxy(index: drawable.treeProxy, aabb: drawable.renderBounds())
                }
            }
            if(oldTotalRect != NSRect.zero)
            {
                self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldTotalRect))
            }
            
            /*
            //Graphite Glider
            if(layersManager!.panelsController.sizeInspectionPopover.isShown)
            {
                layersManager!.panelsController.updateXYInspectSize();
             
            }
            */
            
            moveSelectedUpdates(affineTransform: affineTransform);
        }
    }

    func moveSelectedRight()
    {
        if(selectedDrawables.isEmpty == false)
        {
            let oldTotalRect : NSRect = self.selectionTotalRegionRectExtendedRenderBounds()
            
            let affineTransform = AffineTransform(translationByX: 1.0, byY: 0)
            for drawable in self.selectedDrawables
            {
                drawable.transform(using: affineTransform)
                if(dynamicTreeIsInUse)
                {
                    _ = dynamicTree.moveProxy(index: drawable.treeProxy, aabb: drawable.renderBounds())
                }
            }
            if(oldTotalRect != NSRect.zero)
            {
                self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldTotalRect))
            }
            /*
            //Graphite Glider
             
            if(layersManager!.panelsController.sizeInspectionPopover.isShown)
            {
                layersManager!.panelsController.updateXYInspectSize();
             
            }
            */
            
            moveSelectedUpdates(affineTransform: affineTransform);
        }
    }

    func moveSelectedUp()
    {
        if(selectedDrawables.isEmpty == false)
        {
            let oldTotalRect : NSRect = self.selectionTotalRegionRectExtendedRenderBounds()
            let affineTransform = AffineTransform(translationByX: 0, byY: -1.0)
            for drawable in self.selectedDrawables
            {
                drawable.transform(using: affineTransform)
                if(dynamicTreeIsInUse)
                {
                    _ = dynamicTree.moveProxy(index: drawable.treeProxy, aabb: drawable.renderBounds())
                }
            }
            if(oldTotalRect != NSRect.zero)
            {
                self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldTotalRect))
            }
            
            /*
            Graphite Glider
            if(layersManager!.panelsController.sizeInspectionPopover.isShown)
            {
                layersManager!.panelsController.updateXYInspectSize();
             
            }
            */
            
            moveSelectedUpdates(affineTransform: affineTransform);
        }
    }

    func moveSelectedDown()
    {
        if(selectedDrawables.isEmpty == false)
        {
            let oldTotalRect : NSRect = self.selectionTotalRegionRectExtendedRenderBounds()
            let affineTransform = AffineTransform(translationByX: 0, byY: 1.0)
            for drawable in self.selectedDrawables
            {
                drawable.transform(using: affineTransform)
                if(dynamicTreeIsInUse)
                {
                    _ = dynamicTree.moveProxy(index: drawable.treeProxy, aabb: drawable.renderBounds())
                }
            }
            if(oldTotalRect != NSRect.zero)
            {
                self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds().union(oldTotalRect))
            }
            
            /*
            // Graphite Glider
            if(layersManager!.panelsController.sizeInspectionPopover.isShown)
            {
                layersManager!.panelsController.updateXYInspectSize();
             
            }
            */
            
             moveSelectedUpdates(affineTransform: affineTransform);
        }
    }


    // MARK: --- HIT TEST
    
    func fmDrawableDoesHaveOverlappingTerminal(fmDrawableToTest:FMDrawable) -> (didHit: Bool, didHitFirstTerminal: Bool, hitPoint: NSPoint, pointHitType: PointHitType, hitDrawable: FMDrawable?,didCloseThePath:Bool )
    {
        
        let boundsForQuery = fmDrawableToTest.renderBounds()
        
        // search all drawables within the documentVisibleRect
        var fmDrawablesInQueryRectBounds : [FMDrawable] = [];
        
        if(dynamicTreeIsInUse)
        {
            fmDrawablesInQueryRectBounds = dynamicTree.queryToGetArray(aabb: boundsForQuery)
        }
        else
        {
            fmDrawablesInQueryRectBounds = orderingArray.filter { (fmDrawable) -> Bool in
                NSIntersectsRect(fmDrawable.renderBounds(), boundsForQuery)
            }
        }
        
        
        fmDrawablesInQueryRectBounds.sort(by: { $0.drawingOrderIndex > $1.drawingOrderIndex });
        
       // print("\(fmDrawablesInQueryRectBounds.count) candidates for hit test")
        //var hitFirstTerminal : Bool = false;
        // in every drawable in the documentVisibleRect
        
       
        
        for drawable in fmDrawablesInQueryRectBounds
        {
            for (index, pointForHitTest) in [fmDrawableToTest.firstPoint(),fmDrawableToTest.lastPoint()].enumerated()
            {
                
                var rectToTestFirstPoint : NSRect = NSRect.init(origin: .zero, size: CGSize.init(width: 6, height: 6));
                var rectToTestLastPoint : NSRect = NSRect.init(origin: .zero, size: CGSize.init(width: 6, height: 6));
                rectToTestFirstPoint = rectToTestFirstPoint.centerOnPoint(drawable.firstPoint())
                rectToTestLastPoint = rectToTestLastPoint.centerOnPoint(drawable.lastPoint())
                
                
                
                let didHitFirst = NSPointInRect(pointForHitTest, rectToTestFirstPoint)
                let didHitLast = NSPointInRect(pointForHitTest, rectToTestLastPoint)
                
                if(didHitLast && didHitFirst  && (drawable.hasClose == false) )
                {
                    return (true,(index == 0 ? true : false), pointForHitTest,BeginningPointHit,drawable,true)
                }
                
                if(didHitFirst)
                {
                    return (true,(index == 0 ? true : false), pointForHitTest,BeginningPointHit,drawable,false)
                }
                
                if(didHitLast)
                {
                    return (true,(index == 0 ? true : false), pointForHitTest,EndPointHit,drawable,false)
                }

                
            }
        }// end for drawable in a
        
        
        
        
        return (false,false, .zero, PointHitType.init(0),nil,false)
        
        
    }
    
    
    
    
    // MARK: ---  MANIPULATE DRAWING ORDER OF SELECTED DRAWABLES
    
    func selectedDrawablesToFront()
    {
        
        
        for drawable in self.selectedDrawables.reversed()
        {
            if let indexOfDraToRemove = orderingArray.firstIndex(where: {$0 === drawable})
            {
                orderingArray.remove(at: indexOfDraToRemove)
            }
            orderingArray.append(drawable)
        
        }
        
        self.reindexOrderingArrayDrawables()
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds())
    }
    
    func selectedDrawablesToBack()
    {
        for drawable in self.selectedDrawables
        {
            if let indexOfDraToRemove = orderingArray.firstIndex(where: {$0 === drawable})
            {
                orderingArray.remove(at: indexOfDraToRemove)
            }
            
            orderingArray.insert(drawable, at: 0)
            
        }
        
        self.reindexOrderingArrayDrawables()
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds())
    }
    
    func selectedDrawablesDown()
    {
        for drawable in self.selectedDrawables
        {
            if let indexOfDraToRemove = orderingArray.firstIndex(where: {$0 === drawable})
            {
                orderingArray.remove(at: indexOfDraToRemove)
                
                if((indexOfDraToRemove - 1) > 0)
                {
                    orderingArray.insert(drawable, at: indexOfDraToRemove - 1)
                }
                else
                {
                    orderingArray.insert(drawable, at: 0)
                }

            }
            
        }
        
        self.reindexOrderingArrayDrawables()
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds())

    }
    
    func selectedDrawablesUp()
    {
        
        for drawable in self.selectedDrawables
        {
            if let indexOfDraToRemove = orderingArray.firstIndex(where: {$0 === drawable})
            {
                orderingArray.remove(at: indexOfDraToRemove)
                
                if((indexOfDraToRemove + 1) < (orderingArray.count - 1))
                {
                    orderingArray.insert(drawable, at: indexOfDraToRemove + 1)
                }
                else
                {
                    orderingArray.append(drawable)
                }
                
            }
            

        }
        
        self.reindexOrderingArrayDrawables()
        self.setNeedsDisplay(self.selectionTotalRegionRectExtendedRenderBounds())

    }
    

    
    
    
    func refreshForTransformByIncrement()
    {
        let point = self.window!.mouseLocationOutsideOfEventStream
        let mouseUp : NSEvent! = NSEvent.mouseEvent(with: NSEvent.EventType.leftMouseUp, location: point, modifierFlags: NSEvent.ModifierFlags.init(rawValue: 0), timestamp: ProcessInfo.processInfo.systemUptime , windowNumber: self.window!.windowNumber, context: nil, eventNumber: 199, clickCount: 1, pressure: 71111)
        
        self.mouseUp(with: mouseUp)
        
        // artificial hit selected object, then use mouse drag
        hitSelectedObjectForDrag = self.selectedDrawables.first!
        let mouseDragged : NSEvent! = NSEvent.mouseEvent(with: NSEvent.EventType.leftMouseDragged, location: point, modifierFlags: NSEvent.ModifierFlags.init(rawValue: 0), timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: self.window!.windowNumber, context: nil, eventNumber: 200, clickCount: 1, pressure: 1.0)
        self.mouseDragged(with: mouseDragged)
    
    }
    
      
    // MARK: ---  GROUP/UNGROUP SELECTED DRAWABLES

    func groupSelectedDrawables()
    {
    
        if(selectedDrawables.count > 1)
        {
                    
            // group the entire selected and make that drawable the sole selected drawable
            let groupDrawable = GroupDrawable(array: self.selectedDrawables)
            
            // replace with addDrawableForGrouping
            self.basicAddDrawable(drawable: groupDrawable)
            
            self.deleteSelectedDrawablesForCutOperation()
           /*
            let undoManager : UndoManager = (self.window?.undoManager!)!
            
            // for redo
            let dA = drawablesToAdd
            
            undoManager.registerUndo(withTarget: self) { (self) in
                */
            
            //    self.makeArrayTheSelectedDrawables(arrayToMakeSelected: dA)
                
              //  self.addDrawablesForCutUndo(self.selectedDrawables)
                
            
            self.makeArrayTheSelectedDrawables(arrayToMakeSelected: [groupDrawable])
        }
        
    }
    

    func ungroupSelectedDrawables()
    {
        if self.hasSelectedDrawables
        {
            var groupIsPresentInSelected : (isPresent : Bool, arrayOfSelectedToGroup : [FMDrawable]) = (false,[]);
            
            
            // Check if a group exists in the selectedDrawables
            // because if so it will be ungrouped.
            for d in self.selectedDrawables
            {
               if(d.className == "Floating_Marker.GroupDrawable")
               {
                    groupIsPresentInSelected.isPresent = true
                    groupIsPresentInSelected.arrayOfSelectedToGroup.append(d)
                
               }
            }
         
            if(groupIsPresentInSelected.isPresent == true) // there is something to ungroup
            {
               
                for drawable in groupIsPresentInSelected.arrayOfSelectedToGroup
                {
                    #if DEBUG
                    assert(drawable.elementCount > 0)
                    #endif
                    
                    orderingArray.append(drawable)
                    drawable.drawingOrderIndex = orderingArray.firstIndex(where: {$0 === drawable})!
                   
                    if(dynamicTreeIsInUse)
                    {
                        drawable.treeProxy = dynamicTree.createProxy(aabb: drawable.renderBounds(), item: drawable)
                    }
                    
                    self.setNeedsDisplay(drawable.renderBounds())
                }
                
                reindexOrderingArrayDrawables()
                
                
                
            }
            
        }// END if self.hasSelectedDrawables
    }
    
    
    // MARK: ADDING, REMOVAL, REINDEXING OF FMDRAWABLES
    
    func reindexOrderingArrayDrawables()
    {
        for i in orderingArray.indices
        {
            
            orderingArray[i].drawingOrderIndex = i
            
        }
        
    }
    
    // MARK: HIT TEST FUNCTIONS
    
     func runHitTestOnAllObjects(point : NSPoint) -> (didHitObj : Bool, hitDrawable: FMDrawable?, wasStroke: Bool, wasShadingShape: Bool)
    {
        var fmDrawablesInClipRectBounds : [FMDrawable] = [];
    
        if(self.dynamicTreeIsInUse)
        {
             fmDrawablesInClipRectBounds = dynamicTree.queryToGetArray(aabb: (self.enclosingScrollView?.documentVisibleRect)!)
        }
        else
        {
            
            fmDrawablesInClipRectBounds = orderingArray.filter { (fmDrawable) -> Bool in
                NSIntersectsRect(fmDrawable.renderBounds(), self.enclosingScrollView!.documentVisibleRect)
            }
            
        }
        
        fmDrawablesInClipRectBounds.sort(by: { $0.drawingOrderIndex > $1.drawingOrderIndex })
        
        for drawableToCheck in fmDrawablesInClipRectBounds
        {
            
            let hitResult = drawableToCheck.hitTestForClickBasedOnStrokeOrFillState(point:point)
            if(hitResult.didHit)
            // if the object was hit
            {
                return (true, drawableToCheck,hitResult.wasStroke, hitResult.wasShadingShape)
            }
            
        }
        
        
        return (false, nil, false, false)
        
    }
  
 
    func runHitTestForSelectionArrayOnAllObjects(point : NSPoint) -> Bool
    {
  
        var objectHit : Bool = false;

        var fmDrawablesInClipRectBounds : [FMDrawable] = [];
        
        
        if(dynamicTreeIsInUse)
        {
            fmDrawablesInClipRectBounds = dynamicTree.queryToGetArray(aabb: self.enclosingScrollView!.documentVisibleRect)
            
            fmDrawablesInClipRectBounds.sort(by: { $0.drawingOrderIndex > $1.drawingOrderIndex })

        }
        else
        {
            fmDrawablesInClipRectBounds = orderingArray.filter { (fmDrawable) -> Bool in
                NSIntersectsRect(fmDrawable.renderBounds(), self.enclosingScrollView!.documentVisibleRect)
            }
            
            fmDrawablesInClipRectBounds.reverse()

        }
        
        
        for drawableToCheck in fmDrawablesInClipRectBounds
        {
       
            let hitResult = drawableToCheck.hitTestForClickBasedOnStrokeOrFillState(point:point);
            
          
                
            if(hitResult.didHit)
               // if the object was hit
                // add it to the selected objects array
                // and set it "selected"
            {
                
                    // make sure that if it is an
                // fmStroke hit that it doesn't need
                // reprocessing from thicken or thin.
                if let fmStroke = drawableToCheck as? FMStroke
                {
                    guard fmStroke.needsReprocessing == false else {
                        return false;
                    }
                }
                
                drawableToCheck.isSelected = true
            
//                print("----")
//                print("wasShadingShape \(hitResult.wasShadingShape)")
//                print("wasStroke \(hitResult.wasStroke)")
                
                
                selectedDrawables.append(drawableToCheck)
                lineWorkInteractionEntity?.currentLayerDidSelectObjects()
                
                var updateRectForObj : NSRect = drawableToCheck.renderBounds()
                updateRectForObj.size.width += 10;
                updateRectForObj.size.height += 10;
                updateRectForObj.origin.x -= 5;
                updateRectForObj.origin.y -= 5;
                self.setNeedsDisplay(updateRectForObj)
                
                objectHit = true;
                break;
            }
     
        }
 
        
        if(objectHit && (selectedDrawables.count == 1))
        {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NCTSelectedFirstObject"), object: NSDocumentController.shared.currentDocument!, userInfo: [self :"drawingLayer"])
        }
        else if(objectHit && (selectedDrawables.count > 1))
        {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NCTSelectedObjectPartOfSelectionThatIsMoreThanOneObject"), object: NSDocumentController.shared.currentDocument!, userInfo: [self :"drawingLayer"])
        }
     


        return objectHit;
        
}

    func runHitTestForShadingShapeSelectionArrayOnAllObjects(point : NSPoint) -> Bool
    {
  
        var objectHit : Bool = false;

        var fmDrawablesInClipRectBounds : [FMDrawable] = [];
        
        
        if(dynamicTreeIsInUse)
        {
            fmDrawablesInClipRectBounds = dynamicTree.queryToGetArray(aabb: self.enclosingScrollView!.documentVisibleRect)
        }
        else
        {
            fmDrawablesInClipRectBounds = orderingArray.filter { (fmDrawable) -> Bool in
                NSIntersectsRect(fmDrawable.renderBounds(), self.enclosingScrollView!.documentVisibleRect)
            }
        }
        
        fmDrawablesInClipRectBounds.sort(by: { $0.drawingOrderIndex > $1.drawingOrderIndex })
        
        for drawableToCheck in fmDrawablesInClipRectBounds
        {
       
            let hitResult = drawableToCheck.hitTestForClickBasedOnStrokeOrFillState(point:point);
            if(hitResult.didHit)
               // if the object was hit
                // add it to the selected objects array
                // and set it "selected"
            {
                drawableToCheck.isSelected = true
                
                
                selectedDrawables.append(drawableToCheck)
                lineWorkInteractionEntity?.currentLayerDidSelectObjects()
                
                var updateRectForObj : NSRect = drawableToCheck.renderBounds()
                updateRectForObj.size.width += 10;
                updateRectForObj.size.height += 10;
                updateRectForObj.origin.x -= 5;
                updateRectForObj.origin.y -= 5;
                self.setNeedsDisplay(updateRectForObj)
                
                objectHit = true;
                break;
            }
     
        }
 
        
        if(objectHit && (selectedDrawables.count == 1))
        {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NCTSelectedFirstObject"), object: NSDocumentController.shared.currentDocument!, userInfo: [self :"drawingLayer"])
        }
        else if(objectHit && (selectedDrawables.count > 1))
        {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NCTSelectedObjectPartOfSelectionThatIsMoreThanOneObject"), object: NSDocumentController.shared.currentDocument!, userInfo: [self :"drawingLayer"])
        }
     


        return objectHit;
        
}

    // MARK: -- SVG FOR CROP
    
    func svgGNodeForCrop(croppingRectanglePx:NSRect) -> XMLElement
    {
        var drawablesForCrop : [FMDrawable] = [];
        
        if(self.dynamicTreeIsInUse)
        {
            drawablesForCrop = dynamicTree.queryToGetArray(aabb: croppingRectanglePx)
            
        }
        else
        {
            
            drawablesForCrop = orderingArray.filter { (fmDrawable) -> Bool in
                NSIntersectsRect(fmDrawable.renderBounds(), croppingRectanglePx)
            }
            
        }
        
        
        let tempDrawingLayer = PaperLayer(frame: self.frame)
        //tempDrawingLayer.showGrid = false;
        for drawable in drawablesForCrop.reversed()
        {
            let drawableCopy = drawable.copy() as! FMDrawable;
            
            if(drawableCopy.isBeingInspected)
            {
                drawableCopy.isBeingInspected = false;
            }
            
            if(drawableCopy.isSelected)
            {
                drawableCopy.isSelected = false;
            }
            
            tempDrawingLayer.orderingArray.append(drawableCopy)
            
            drawableCopy.drawingOrderIndex = tempDrawingLayer.orderingArray.firstIndex(where: {$0 === drawableCopy})!
            drawableCopy.treeProxy = tempDrawingLayer.dynamicTree.createProxy(aabb: drawableCopy.renderBounds(), item: drawableCopy)
            
        }
        
        tempDrawingLayer.reindexOrderingArrayDrawables()
        
        for d in tempDrawingLayer.orderingArray
        {
            let a = AffineTransform.init(translationByX: -1 * croppingRectanglePx.origin.x, byY: -1 * croppingRectanglePx.origin.y)
            d.transform(using: a)
        }
        
        tempDrawingLayer.selectedDrawables.removeAll()
        tempDrawingLayer.selectedDrawables.append(contentsOf: tempDrawingLayer.orderingArray)
        
        return tempDrawingLayer.xmlElementGForSelectedDrawables() as! XMLElement;
        
    }

  // MARK: ---  Image Capture of Drawing Layer
    
    func imageDataFromSelectedDrawables(type:String, croppingRectangle:NSRect?, includeBackground:Bool) -> Data
    {
        
        /*
        for d in selectedDrawables
        {
          d.isSelected = false
        }*/
        
        
        /*
        var wasShowingGrid = false;
        if(layersManager.showGrid == true)
        {
            layersManager.showGrid = false;
            wasShowingGrid = true;
        }
        */

        let tempDrawingLayer = PaperLayer(frame: self.frame)
        //tempDrawingLayer.showGrid = false;
        for drawable in self.selectedDrawables.reversed()
        {
            let drawableCopy = drawable.copy() as! FMDrawable;
            
            if(drawableCopy.isBeingInspected)
            {
                drawableCopy.isBeingInspected = false;
            }
            
            if(drawableCopy.isSelected)
            {
                drawableCopy.isSelected = false;
            }
            
            tempDrawingLayer.orderingArray.append(drawableCopy)
            
            drawableCopy.drawingOrderIndex = tempDrawingLayer.orderingArray.firstIndex(where: {$0 === drawableCopy})!
            drawableCopy.treeProxy = tempDrawingLayer.dynamicTree.createProxy(aabb: drawableCopy.renderBounds(), item: drawableCopy)

        }
        
        tempDrawingLayer.reindexOrderingArrayDrawables()
        
        
        var data : Data = Data.init();
        
        if(type == "pdf")
        {
            data = tempDrawingLayer.dataWithPDF(inside: self.selectionTotalRegionRectExtendedRenderBounds())
        }
        else if(type == "eps")
        {
            data = tempDrawingLayer.dataWithEPS(inside: self.selectionTotalRegionRectExtendedRenderBounds())
        }
        else if(type == "svg")
        {
            if let rootXMLElement = currentDrawingPage?.drawingPageController?.fmDocument.svgRootElement
            {
                var selectedTotalRegionRectExtended = self.selectionTotalRegionRectExtendedRenderBounds();
                
                for d in tempDrawingLayer.orderingArray
                {
                    let a = AffineTransform.init(translationByX: -1 * selectedTotalRegionRectExtended.origin.x, byY: -1 * selectedTotalRegionRectExtended.origin.y)
                    d.transform(using: a)
                }
                
                selectedTotalRegionRectExtended.origin.x = 0
                selectedTotalRegionRectExtended.origin.y = 0
                
                rootXMLElement.addAttribute(XMLNode.attribute(withName: "width", stringValue: "\(selectedTotalRegionRectExtended.size.width)") as! XMLNode)
                
                
                rootXMLElement.addAttribute(XMLNode.attribute(withName: "height", stringValue: "\(selectedTotalRegionRectExtended.size.height)") as! XMLNode)
                
                tempDrawingLayer.selectedDrawables.removeAll()
                tempDrawingLayer.selectedDrawables.append(contentsOf: tempDrawingLayer.orderingArray)
                
                if(includeBackground && (currentDrawingPage != nil))
                {
                    let bgColorStr = currentDrawingPage!.defaultBackgroundColor.xmlRGBAttributeStringContent()
                    let bgFill = XMLElement.init(name: "rect")
                    bgFill.setAttributesAs(["width":"100%","height":"100%","fill":bgColorStr])
                    
                    rootXMLElement.addChild(bgFill)
                }
                
                rootXMLElement.addChild(tempDrawingLayer.xmlElementGForSelectedDrawables())
                let xmlDoc = XMLDocument.init(rootElement: rootXMLElement)
                
                data = xmlDoc.xmlData;
                
                
            }
            else
            {
                print("Export SVG Selected Drawables: No access to currentDrawingPage within PaperLayer")
            }
        
        }
        
        /*
        for d in selectedDrawables
        {
            d.isSelected = true
        }*/
        
        /*
        if(wasShowingGrid == true)
        {
            showGrid = true;
        }
        */
        
        return data;
        
    }
    
    
    
    func imgFromRect(rectForCapture : NSRect) -> NSImage
    {
        // from https://stackoverflow.com/questions/3251261/how-do-i-take-a-screenshot-of-an-nsview
        
        let viewToCapture = self.window!.contentView!
        let rep = viewToCapture.bitmapImageRepForCachingDisplay(in: viewToCapture.bounds)!
        viewToCapture.cacheDisplay(in: viewToCapture.bounds, to: rep)
        
        let img = NSImage(size: viewToCapture.bounds.size)
        img.addRepresentation(rep)
        
        return img;
        
    }

    
    
    // MARK: PASTE, CUT, COPY
    
    func addDrawablesForPaste(drawablesArray : [FMDrawable], actionName:String = "Paste") throws
    {
        let undoManager : UndoManager = self.parentDocument!.undoManager!
        
        let drawablesForPasteUndo = drawablesArray
        undoManager.registerUndo(withTarget: self) { (self) in

            self.removeDrawablesForPasteUndo(drawablesArray: drawablesForPasteUndo)
            
        }
        
        
        undoManager.setActionName("\(actionName) Shape(s)")
        
        if(undoManager.isUndoing)
        {
            //    undoManager.setActionName("Delete \(drawable.shapeName)")
        }
        
        self.reindexOrderingArrayDrawables()
        
        for drawable in drawablesArray
        {
            
            #if DEBUG
            assert(drawable.elementCount > 0)
            #endif
            
            orderingArray.append(drawable)
            drawable.drawingOrderIndex = orderingArray.firstIndex(where: {$0 === drawable})!
            
            if(dynamicTreeIsInUse)
            {
                drawable.treeProxy = dynamicTree.createProxy(aabb: drawable.renderBounds(), item: drawable)
            }
            
            self.setNeedsDisplay(drawable.renderBounds())
            
        }
        
        self.makeArrayTheSelectedDrawables(arrayToMakeSelected: drawablesArray)
        
    }
    
    func removeDrawablesForPasteUndo(drawablesArray : [FMDrawable])
    {
        // prepare the undoManager
        let undoManager : UndoManager = self.parentDocument!.undoManager!
        
        
        // undo cut shapes
        let drawablesToRestoreByUndo = self.selectedDrawables // for clarity below
        undoManager.registerUndo(withTarget: self) { (self) in
            
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            
            do {
                try self.addDrawablesForPaste(drawablesArray: drawablesToRestoreByUndo);
            } catch  {
                print(error);
            }
           
            
            
            
            
            self.makeArrayTheSelectedDrawables(arrayToMakeSelected: drawablesToRestoreByUndo)
            
        }
        
        
        let textForUndo = (self.selectedDrawables.count > 1) ? "Paste Shapes" : "Paste Shape" //\(selectedDrawables.first?.shapeName)"
        
        // delete the drawables
        deleteSelectedDrawablesForCutOperation()
        
        undoManager.setActionName(textForUndo)
        
    }
    
    
    func cutOperationForSelectedDrawables()
    {
        
        // prepare the undoManager
        let undoManager : UndoManager = self.parentDocument!.undoManager!

        
        // undo cut shapes
        let drawablesToRestoreByUndo = self.selectedDrawables // for clarity below
        undoManager.registerUndo(withTarget: self) { (self) in
            
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            
            self.addDrawablesForCutUndo(drawablesToRestoreByUndo)
            
            self.makeArrayTheSelectedDrawables(arrayToMakeSelected: drawablesToRestoreByUndo)
            
        }
        
        let textForUndo = (self.selectedDrawables.count > 1) ? "Cut Shapes" : "Cut \(self.selectedDrawables.first!.shapeName)"
        
        // delete the drawables
        deleteSelectedDrawablesForCutOperation()
    
        undoManager.setActionName(textForUndo)
        
    }
    
    func deleteSelectedDrawablesForCutOperation()
    {
        let selectedDrawablesToDelete = selectedDrawables
        
        for d in selectedDrawablesToDelete
        {
            let boundsOfDrawable = d.renderBounds()
            if(dynamicTreeIsInUse)
            {
                dynamicTree.destroyProxy(index: d.treeProxy)
            }
            if let indexOfDrawableToRemove = orderingArray.firstIndex(where: {$0 === d})
            {
                orderingArray.remove(at: indexOfDrawableToRemove)
            }
            
            self.setNeedsDisplay(boundsOfDrawable)
            
        }
        
        reindexOrderingArrayDrawables()
        
        self.clearOutSelections()
        
    }
    
    
    
    func deleteSelectedDrawables()
    {
       if(self.isCarting)
       {
           cart();
       }
       
      // let selectedDrawablesDeepCopy1 = self.selectedDrawablesDeepCopy;
      
      self.removeArrayOfDrawables(selectedDrawables)
      
      /*
       for d in selectedDrawables
       {
            self.removeDrawable(d)
       }
       */
       self.clearOutSelections()
        

       
      // flashObjectsOnLayerForCombinatoricsWarning(selectedDrawablesDeepCopy1);
       
    }
    
     
    func removeDrawable(_ drawable : FMDrawable)
    {
        
        let undoManager : UndoManager = self.parentDocument!.undoManager!

        
        undoManager.registerUndo(withTarget: self) { (self) in
            self.addFMDrawable(drawable, doBackgroundThread: true)

        }
        
        undoManager.setActionName("Delete \(drawable.shapeName)")
        
        if(undoManager.isUndoing)
        {
            undoManager.setActionName("Draw \(drawable.shapeName)")
        }
  
        
        let boundsOfDrawable = drawable.renderBounds()
        if(dynamicTreeIsInUse)
        {
            dynamicTree.destroyProxy(index: drawable.treeProxy)
        }
        
        if let indexOfDraToRemove = orderingArray.firstIndex(where: {$0 === drawable})
        {
            orderingArray.remove(at: indexOfDraToRemove)
        }
        
        reindexOrderingArrayDrawables()
        
        self.setNeedsDisplay(boundsOfDrawable.insetBy(dx: -10, dy: -10))
        
        
    
    }

    func removeArrayOfDrawables(_ drawablesToRemove : [FMDrawable])
    {
        
        let undoManager : UndoManager = self.parentDocument!.undoManager!

        let dTR = deepCopyOfDrawables(drawables: drawablesToRemove)
        undoManager.registerUndo(withTarget: self) { (self) in
        
            do {
                try self.addDrawablesForPaste(drawablesArray: dTR);
            } catch  {
                print(error);
            }
            
        }
        
        undoManager.setActionName("Delete Drawables")
        
        if(undoManager.isUndoing)
        {
            undoManager.setActionName("Draw Drawables")
        }
  
        var updateRectForRemoved = NSRect.zero;
        for d in drawablesToRemove
        {
            if(updateRectForRemoved == NSRect.zero)
            {
                updateRectForRemoved = d.renderBounds()
            }
            else
            {
                updateRectForRemoved = updateRectForRemoved.union(d.renderBounds())
            }
            
            if(dynamicTreeIsInUse)
            {
                dynamicTree.destroyProxy(index: d.treeProxy)
            }
            if let indexOfDraToRemove = orderingArray.firstIndex(where: {$0 === d})
            {
                orderingArray.remove(at: indexOfDraToRemove)
            }
            
            if let indexOfDraToRemove = orderingArray.firstIndex(where: {$0 === d})
            {
              orderingArray.remove(at: indexOfDraToRemove)
            }
        }
        
        reindexOrderingArrayDrawables()
        
        self.setNeedsDisplay(updateRectForRemoved)
        
        
        currentDrawingPage?.drawingPageController?.fmDocument.updateSVGPreviewLive();

        
    
    }
    
    
    func flashObjectsOnLayerForCombinatoricsWarning(_ drawables : [FMDrawable], autoreverse:Bool, duration: CGFloat, fillColor:NSColor?)
    {
        
        let shapeLayers = self.shapeLayersFromDrawables(drawables, color: fillColor)
        
        for s in shapeLayers
        {
            self.layer!.addSublayer(s);
        }
        
        
        for s in shapeLayers
        {
            
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0.0
            animation.toValue = 0.5
            animation.autoreverses = autoreverse;
            animation.duration = CFTimeInterval(duration)//0.10
            
            animation.delegate = LayerRemover(for:s);
            
            s.add(animation, forKey: "fade");
            
            
        }
        
        
        
    }
    
    func shapeLayersFromDrawables(_ drawables : [FMDrawable], color: NSColor?) -> [CAShapeLayer]
    {
        var shapeLayers : [CAShapeLayer] = [];
    
        for d in drawables
        {
            
            let shapeLayer = CAShapeLayer();
            //shapeLayer.contentsScale = self.enclosingScrollView!.magnification;
           // shapeLayer.bounds = self.convertToLayer(<#T##rect: NSRect##NSRect#>)
            
            shapeLayer.path = d.cgPath;
            shapeLayer.fillColor = (color != nil) ? color!.cgColor : d.fmInk.mainColor.cgColor;
            /*
            for why the layer actually disappears using .forward
            https://stackoverflow.com/questions/10602505/iphone-remove-calayer-when-animation-stop-calayer-flash-before-disappear?rq=1
             */
            shapeLayer.fillMode = .forwards
            shapeLayer.opacity = 0.0;
            shapeLayer.strokeColor = d.fmInk.mainColor.cgColor
            
            shapeLayer.lineWidth = d.lineWidth;
            //shapeLayer.lineCap = CAShapeLayerLineCap.ra
            shapeLayers.append(shapeLayer);
        }
    
        return shapeLayers;
        
    }
   
    
    
    // MARK: COMBINATORICS, POST-DEPOSIT
    
    func unionSelectedDrawables()
    {
        var finalSelected : [FMDrawable] = [];
        
        var leaveUntouchedDrawables : [FMDrawable] = [];
        
        let unionResult = NSBezierPath()
       
        unionResult.append(selectedDrawables[0])
        
        var doUnion : Bool = false
      
        var aggSettings : FMDrawableAggregratedSettings = FMDrawableAggregratedSettings.init(fmDrawable: selectedDrawables[0])
      
      
        for i in stride(from: 1, to: selectedDrawables.count, by: 1)
        {
            var unionResult2 = NSBezierPath()
        
            
            if(pathsIntersect(path1: unionResult, path2: selectedDrawables[i]))
            //if(unionResult.bounds.intersects(selectedDrawables[i].bounds) )
            {
                if((doUnion == false) && (inkAndLineSettingsManager!.receiverDeterminesStyle))
                {
                    aggSettings = FMDrawableAggregratedSettings.init(fmDrawable: selectedDrawables[i]);
                }
                
                doUnion = true;
                unionResult2 = selectedDrawables[i].fb_union(unionResult)
                unionResult.removeAllPoints()
                unionResult.append(unionResult2)
                
                finalSelected.append(selectedDrawables[i])
                
               
            }
            else
            {
               leaveUntouchedDrawables.append(selectedDrawables[i])
            }
            
            
        }
        
        //   makeArrayTheSelectedDrawables(arrayToMakeSelected: finalSelected);
  
        
        if(doUnion)
        {
            var d = FMDrawable.init()
            aggSettings.applyToDrawable(fmDrawable: &d)

            d.append(unionResult)
            d.windingRule = NSBezierPath.WindingRule.evenOdd
            
            // Graphite Glider
            //if(d.hasLineShape)
            //{
            //    d.hasLineShape = false
            //}
          
            //d.applyDrawableCharacteristics(selectedDrawables.last!.drawableCharacteristics())
          
            self.deleteSelectedDrawables()
            self.addFMDrawable(d, doBackgroundThread: true)
        }
        else
        {
            flashObjectsOnLayerForCombinatoricsWarning(selectedDrawables, autoreverse: true,duration: 0.17,fillColor:NSColor.red.withAlphaComponent(0.5))
        }

    }

    func intersectionOfSelectedDrawables()
    {
        
        var leaveUntouchedDrawables : [FMDrawable] = [];
        
        // make new array
        // containing what selected drawables
        // intersect in terms of bounds rect,
        // then check for path segment intersection
        
        var doIntersection : Bool = false
        var aggSettings : FMDrawableAggregratedSettings = FMDrawableAggregratedSettings.init(fmDrawable: selectedDrawables[0])
       // let drawableCharacteristics = selectedDrawables[0].drawableCharacteristics();
        
       
        let intersectionResult = NSBezierPath()
        intersectionResult.append(selectedDrawables[0])
        
        for i in stride(from: 1, to: selectedDrawables.count, by: 1)
        {
            var intersectionResult2 = NSBezierPath()
            
        

            if(pathsIntersect(path1: intersectionResult, path2: selectedDrawables[i]))
            //if(intersectionResult.allIntersections(with: selectedDrawables[i]).count > 0)
            {
            
                if((doIntersection == false) && (inkAndLineSettingsManager!.receiverDeterminesStyle))
                {
                    aggSettings = FMDrawableAggregratedSettings.init(fmDrawable: selectedDrawables[i]);
                }
                
                
                doIntersection = true
                intersectionResult2 = selectedDrawables[i].fb_intersect(intersectionResult)
                intersectionResult.removeAllPoints()
                intersectionResult.append(intersectionResult2)


                
            }
            else
            {
                leaveUntouchedDrawables.append(selectedDrawables[i])
            }
            
        }
        
    
        // remove leaveUntouchedDrawables from selectedDrawables
      //  selectedDrawables = selectedDrawables.filter { !leaveUntouchedDrawables.contains($0) }

        
        if(doIntersection && (intersectionResult.elementCount > 0) )
        {
            var d = FMDrawable.init()
            d.append(intersectionResult)
            aggSettings.applyToDrawable(fmDrawable: &d)
            self.deleteSelectedDrawables()
           // Graphite Glider
           // if(d.hasLineShape)
            //{
            //    d.hasLineShape = false
            //}
     
            //d.applyDrawableCharacteristics(drawableCharacteristics)
     
            self.addFMDrawable(d, doBackgroundThread: true)
        }
        else
        {
            flashObjectsOnLayerForCombinatoricsWarning(selectedDrawables, autoreverse: true,duration: 0.17,fillColor:NSColor.red.withAlphaComponent(0.5))
        }
       
        
      
    }
    
    func differenceOfSelectedDrawables()
    {
        // last drawable selected will be the
        // subject of subtraction
     
        var leaveUntouchedDrawables : [FMDrawable] = [];
        
        
        var doDifference = false;
        var aggSettings : FMDrawableAggregratedSettings = FMDrawableAggregratedSettings.init(fmDrawable: selectedDrawables[0])
        
        let differenceResult = NSBezierPath()
        differenceResult.append(selectedDrawables[0])
        
       // let drawableCharacteristics = selectedDrawables[0].drawableCharacteristics();
        
    
        // mutable
        for i in stride(from: 0, to: selectedDrawables.count, by: 1)
        {
            var differenceResult2 = NSBezierPath()
   


            if(pathsIntersect(path1: differenceResult, path2: selectedDrawables[i]))
            //if((differenceResult.allIntersections(with: selectedDrawables[i]).count > 0) || selectedDrawables[i].bounds.contains(differenceResult.bounds))
            {
            
                if((doDifference == false) && (inkAndLineSettingsManager!.receiverDeterminesStyle))
                {
                    aggSettings = FMDrawableAggregratedSettings.init(fmDrawable: selectedDrawables[i]);
                }
                
                doDifference = true;
                differenceResult2 = selectedDrawables[i].fb_difference(differenceResult)
                differenceResult.removeAllPoints()
                differenceResult.append(differenceResult2);
                

            }
            else
            {
                leaveUntouchedDrawables.append(selectedDrawables[i])
            }
            
        }
        
        
        // remove leaveUntouchedDrawables from selectedDrawables
        //  selectedDrawables = selectedDrawables.filter { !leaveUntouchedDrawables.contains($0) }
        
        if((doDifference) && (differenceResult.elementCount > 0))
        {
            var d = FMDrawable.init()
            d.append(differenceResult)
            aggSettings.applyToDrawable(fmDrawable: &d)
            self.deleteSelectedDrawables()
           // if(d.hasLineShape)
           // {
           //     d.hasLineShape = false
           // }
       
           // d.applyDrawableCharacteristics(drawableCharacteristics);
       
            d.windingRule = NSBezierPath.WindingRule.evenOdd
            self.addFMDrawable(d, doBackgroundThread: true)

            
        }
        else
        {
            flashObjectsOnLayerForCombinatoricsWarning(selectedDrawables, autoreverse: true,duration: 0.17,fillColor:NSColor.red.withAlphaComponent(0.5))
        }
        
    }
    
    
 
    // MARK: OUTSIDE OBJECTS
    var lineWorkInteractionEntity : LineWorkInteractionEntity?
    {
        get{
        
            return currentDrawingPage?.drawingPageController?.lineWorkInteractionEntity
        }
    }
    
    var currentDrawingPage : DrawingPage?
    
     
     var parentDocument : FMDocument?
    {
        get {
        
            return self.currentDrawingPage?.drawingPageController?.fmDocument
        
        
        }
    }
            
            
    // MARK: XML ELEMENT
    func xmlElement(includeFMKRTags:Bool) -> XMLElement
    {
        
        let paperLayerGNode = XMLElement.init(name: "g")
//        paperLayerGNode.setAttributesAs(["class" : "PaperLayer","name" : paperLayer.name, "isHidden" : (paperLayer.isHidden ? "true" : "false")])

        if(includeFMKRTags)
        {
            paperLayerGNode.addAttribute(XMLNode.attribute(withName: "fmkr:groupType", stringValue: "PaperLayer") as! XMLNode)
            paperLayerGNode.addAttribute(XMLNode.attribute(withName: "fmkr:name", stringValue: self.name) as! XMLNode)
            paperLayerGNode.addAttribute(XMLNode.attribute(withName: "fmkr:isHidden", stringValue: (self.isHidden ? "true" : "false") )as! XMLNode)
        }
        
        if(self.isHidden)
        {
            paperLayerGNode.addAttribute(XMLNode.attribute(withName: "visibility", stringValue: "hidden") as! XMLNode)
        }
        
        var xmlChildren : [XMLElement] = [];
        for fmDrawable in orderingArray
        {
        
            xmlChildren.append(contentsOf: fmDrawable.xmlElements(includeFMKRTags:includeFMKRTags))
        }

        paperLayerGNode.setChildren(xmlChildren)

        return paperLayerGNode;
        
    }
    
    func xmlElementGForSelectedDrawables() -> XMLNode
    {
            let paperLayerGNode = XMLElement.init(name: "g")

        if(selectedDrawables.isEmpty == false)
        {
    
        
        var xmlChildren : [XMLElement] = [];
        for fmDrawable in selectedDrawables
        {
            
            xmlChildren.append(contentsOf: fmDrawable.xmlElements(includeFMKRTags:false))
        }
        
        paperLayerGNode.setChildren(xmlChildren)
        }
        
        
        return paperLayerGNode;

    }
    
 
}

/* from https://stackoverflow.com/questions/17688440/how-to-remove-a-layer-when-its-animation-completes/50948519#:~:text=When%20you%20create%20the%20animation,group%20all%20your%20animations%20together.
*/

class LayerRemover: NSObject, CAAnimationDelegate {
    private weak var layer: CALayer?

    init(for layer: CALayer) {
        self.layer = layer
        super.init()
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    
        
        layer?.removeFromSuperlayer()
    }
    
    
}
