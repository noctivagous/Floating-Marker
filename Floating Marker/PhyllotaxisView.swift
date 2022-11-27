//
//  PhyllotaxisView.swift
//  Phyllotaxis
//
//  Created by John Pratt on 4/28/19.
//  Copyright © 2019 Noctivagous, Inc. All rights reserved.
//

import Cocoa

class PhyllotaxisView: NSView {

    // Converted from https://bl.ocks.org/jhubley/48406982f6988b626d9527d75a98b062
    // which was converted from https://krazydad.com/tutorials/circles_js/showexample.php?ex=basic_phyllo


    var radius : CGFloat = 500.0
    {
        didSet
        {
            radiusTextField?.setCGFloatValue(radius)
        }
    }

    @IBOutlet var radiusTextField : NSTextField?;
    @IBAction func changeRadius(_ sender : NSControl)
    {
        radius = CGFloat(sender.doubleValue)
    }
    
    @IBOutlet var angleTextField : NSTextField!;
    @IBOutlet var angleSlider : NSSlider!;
    
    @IBOutlet var ratioFactorTextField : NSTextField!;
    @IBOutlet var ratioFactorSlider : NSSlider!;
    
    @IBOutlet var shapeDepositCountSlider : NSSlider!;
    @IBOutlet var shapeDepositCountTextField : NSTextField!;
    
    var scalingPosition : CGFloat = 0.5
    {
        didSet
        {
        
        
            scalingPositionTextField?.doubleValue = Double(scalingPosition)
            scalingPositionSlider?.doubleValue = Double(scalingPosition)
            self.needsDisplay = true;

        }
    }

    @IBOutlet var scalingPositionTextField : NSTextField?
    @IBOutlet var scalingPositionSlider : NSSlider?
    
    @IBAction func changeScalingPosition(_ sender : NSControl)
    {
        scalingPosition = CGFloat(sender.doubleValue)
    }
    
    
    var ratioFactor  : CGFloat = 1
    {
        didSet
        {
            ratioFactorSlider.doubleValue = Double(ratioFactor)
            ratioFactorTextField.doubleValue = Double(ratioFactor)
            self.needsDisplay = true;
        }
    }
    

    
    var shapeDepositCount = 1000
    {
      didSet
      {
        shapeDepositCountSlider.doubleValue = Double(shapeDepositCount)
        shapeDepositCountTextField.doubleValue = Double(shapeDepositCount)
        self.needsDisplay = true;
      }
    }
    
    
    @IBOutlet weak var loadedObjectScaleFactorTextField: NSTextField!
    @IBOutlet weak var loadedObjectScaleFactorSlider: NSSlider!
    
    var loadedObjectScaleFactor : CGFloat = 1 {
     
        didSet
        {
        loadedObjectScaleFactorTextField.doubleValue = Double(loadedObjectScaleFactor)
        loadedObjectScaleFactorSlider.doubleValue = Double(loadedObjectScaleFactor)
        
            self.needsDisplay = true;
        }
        
    }
    
    @IBAction func changeLoadedObjectScaleFactor(_ sender : NSControl)
    {
        loadedObjectScaleFactor = CGFloat(sender.doubleValue)
    }
    

    
    var golden_ratio : CGFloat
    {
        
        get{
            return (sqrt(5) + 1) / 2 - 1;
        }
        
    }
    var angleForRepetitionDegrees : CGFloat = 137.5 // deg2rad(137.5)// CGFloat(golden_ratio * (2 * .pi));
    
        {
        
        didSet
        {
            angleTextField.doubleValue = Double(angleForRepetitionDegrees)
            angleSlider.doubleValue =  Double(angleForRepetitionDegrees);

            self.needsDisplay = true;
        }
        
    }
    /*
    {
        get {
            
        return  PhyllotaxisView.rad2deg(222.4) // CGFloat(golden_ratio * (2 * .pi)); 
        }
    }*/
    
    var circleRadius : CGFloat {
        get
        {
              return   (NSWidth(self.bounds) * 0.45);
        }
        
    }
    
    var shapeMaxWidth : CGFloat {
    
        get
        {
            
            
                return 10
                //shapeDepositCount
                
            
        }
    }
    
    @IBAction func changeRatioFactor(_ sender : NSControl)
    {
        ratioFactor = CGFloat(sender.floatValue)
    }
    
    @IBAction func changeAngle(_ sender : NSControl)
    {
        
        angleForRepetitionDegrees = CGFloat(sender.doubleValue);
        
    }
    /*
 
     2.79 - nine
     34.565
     323.596
     17.6
     152.186981201172
     259.4017
     212.360702
     
     single arm:
     207.287643432617
     263.849975585938
     75.3956527709961
     307.885894775391
     289.092529296875
     
     three arm:
     52.3660659790039
     73.3240280151367
     60.723217010498
     52.3772239685059
     
     four arm:
     70.6651000976562
     300.012237548828
     
     five arm:
     33.9114837646484
     134.45393371582
     255.106033325195
     
     seven arms:
     308.774780273438
     
     nine arm:
     53.054126739502
     
     
     247.898132324219
     
     single spirals:
     326.697845458984
     213.647567749023
     194.746337890625
     301.61

     twelve
     266.751007080078
     
     260.75 - two spiral arms
     

     
     */
  
    
    @IBAction func changeCount(_ sender : NSControl)
    {
        shapeDepositCount = sender.integerValue;
    }
    
  
    @IBAction func changeToPhyllotaxisA(_ sender: NSButton)
    {
    
        angleForRepetitionDegrees = 137.5;
    }

    @IBAction func changeToPhyllotaxisB(_ sender: NSButton)
    {
        angleForRepetitionDegrees = 222.4;
    }


    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let centerOfBounds = NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds))
        
        NSColor.black.setFill()
        dirtyRect.fill()
        
        NSColor.black.setStroke();


        drawWhorl(centerOfBounds:centerOfBounds)
        
      //  let b = NSBezierPath();
      //  b.move(to: centerOfBounds)
       // b.lineWidth = 0.5;
       
        
      
        
        
        /*
        let incr : CGFloat = 1 / .pi  * .pi * 2;
        
        for radius : CGFloat in stride(from: 0.0, to: 200, by: 5)
        {
            
        
            for angleInRadians : CGFloat in stride(from: 0.0, to: .pi * 2, by: incr) {
                
                //let degrees = Int(radians * 180 / .pi)
                
                let x = radius * cos(angleInRadians) + centerOfBounds.x;
                let y = radius * sin(angleInRadians) + centerOfBounds.y;
                
                let f = NSBezierPath();
                f.appendArc(withCenter: NSPoint(x: x, y: y), radius: 5, startAngle: 0, endAngle: 360)
                f.stroke();
                
                //print("Degrees: \(degrees), radians: \(radians)")
            }
            
        }*/
        // Degrees: 0, radians: 0.0
        // Degrees: 90, radians: 1.5707963267949
        // Degrees: 180, radians: 3.14159265358979
        // Degrees: 270, radians: 4.71238898038469
        
        
    }
    
    var isTriangle = true;
    
    


    /*
    
     drawable.sendIterationIncrement(incrementEffect:NCTIncrementEffect);

    struct NCTRepetitionStepOperationGroup // or NCTIncrementEffect
    {
        var incrementArray : [String] = ["hueUp","lighten"]
        // other options:
        // thickenStroke, thinStroke, darken, lighten, saturationUp, saturationDown,
        // rotate, scale
        
    }
    
    
    */
    func drawWhorl(centerOfBounds:NSPoint)
    {
        guard shapeDepositCount > 1 else {
            print("shapeDepositCount > 1")
            return
        }
        for i in 1...shapeDepositCount
        {
            
            //  let dot_rad = objectScaleFactor * CGFloat(i);
            let ratio = ratioFactor * CGFloat(i) / CGFloat(shapeDepositCount);
            let angle = CGFloat(i) * deg2rad(angleForRepetitionDegrees);
            let spiralRadius = ratio * circleRadius;
            
            if(spiralRadius > circleRadius)
            {
                break;
            }
            
            let x = centerOfBounds.x + cos(angle) * spiralRadius;
            let y = centerOfBounds.y + sin(angle) * spiralRadius;
            
            let shapeBezierPath = NSBezierPath();
            
            // shapeBezierPath.lineWidth = b.lineWidth + 0.01;
            // shapeBezierPath.line(to: NSPoint(x: x, y: y))
            
            
            if(isTriangle)
            {
                // TRIANGLE
                shapeBezierPath.move(to: NSPoint.zero)
                shapeBezierPath.line(to: NSPoint(x: 10, y: 0))
                shapeBezierPath.line(to: NSPoint(x: 5, y: 10))
                shapeBezierPath.close();
            }
            else
            {
                
                // ROUNDED RECTANGLE
                shapeBezierPath.appendRoundedRect(NSMakeRect(0, 0, 10, 10), xRadius: 2, yRadius: 2)
                
            }
            
            // CIRCLE
            //shapeBezierPath.appendArc(withCenter: NSPoint(x: 0, y: 0), radius: 3, startAngle: 0, endAngle: 360)
            
            let shapeBezierBounds = shapeBezierPath.bounds;
            
            var affineTransformScaleRotate = AffineTransform();
            
            affineTransformScaleRotate.translate(x: -shapeBezierBounds.midX, y: -shapeBezierBounds.midY)
            affineTransformScaleRotate.rotate(byRadians: angle);
            affineTransformScaleRotate.scale( abs(scalingPosition - (loadedObjectScaleFactor * spiralRadius / circleRadius)) )
            affineTransformScaleRotate.translate(x: shapeBezierBounds.midX, y: shapeBezierBounds.midY)
            
            shapeBezierPath.transform(using: affineTransformScaleRotate);
            
            var affineTransformTranslate = AffineTransform();
            affineTransformTranslate.translate(x: x , y: y);
            
            // affineTransformTranslate.translate(x: x - dot_rad / 2, y: y - dot_rad / 2);
            shapeBezierPath.transform(using: affineTransformTranslate);
            
            
            NSColor(calibratedRed: 0.8, green: 0.5, blue: CGFloat(i) / CGFloat(shapeDepositCount), alpha: 1).setFill()
            shapeBezierPath.fill();
            
            NSColor.black.setStroke();
            
            
            shapeBezierPath.stroke();
            //   if (i < 800){fill('#a6cf02');}
            //  else if (i < 1300){fill('#4ba41a');}
            //   else {fill('#229946');}
            
        }
        
    }
    
    override func awakeFromNib()
    {
        setToDefaults()
    }
    
    func setToDefaults()
    {
        radius = 500.0;
        ratioFactor = 1;
        shapeDepositCount = 1000;
        scalingPosition = 0.0;
        angleForRepetitionDegrees = 137.5;
        loadedObjectScaleFactor = 1;
    }
    
    @IBAction func resetSettings(_ sender : NSControl)
    {
        setToDefaults();
    }
}

