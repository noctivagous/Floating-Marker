//
//  NCTUtilities.swift
//  Floating Marker
//
//  Created by John Pratt on 1/13/21.
//

import Cocoa



// MARK: Drawing Strings

extension String
{
    func drawStringInsideRectWithSystemFont(fontSize : CGFloat, textAlignment : NSTextAlignment, fontForegroundColor: NSColor, rect: NSRect)
    {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
        

            let attrs = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: fontSize, weight: NSFont.Weight.bold), NSAttributedString.Key.paragraphStyle: paragraphStyle,
                          NSAttributedString.Key.foregroundColor : fontForegroundColor ]
        
             self.draw(in: rect, withAttributes: attrs)
    }
    
    func drawStringInsideRectWithSFProFont(fontSize : CGFloat, textAlignment : NSTextAlignment, fontForegroundColor: NSColor, rect: NSRect)
    {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
        

            let attrs = [NSAttributedString.Key.font: NSFont.init(name: "SFProDisplay-Thin", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize, weight: NSFont.Weight.bold), NSAttributedString.Key.paragraphStyle: paragraphStyle,
                          NSAttributedString.Key.foregroundColor : fontForegroundColor ]
        
             self.draw(in: rect, withAttributes: attrs)
    }
    
     func drawStringInsideRectWithMenlo(fontSize : CGFloat, textAlignment : NSTextAlignment, fontForegroundColor: NSColor, rect: NSRect)
    {
                let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
        

            let attrs = [NSAttributedString.Key.font: NSFont.init(name: "Menlo-Regular", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize, weight: NSFont.Weight.bold), NSAttributedString.Key.paragraphStyle: paragraphStyle,
                          NSAttributedString.Key.foregroundColor : fontForegroundColor ]
        
             self.draw(in: rect, withAttributes: attrs)
    }

    func drawStringInsideRectWithSFProFontReg(fontSize : CGFloat, textAlignment : NSTextAlignment, fontForegroundColor: NSColor, rect: NSRect)
    {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
        

            let attrs = [NSAttributedString.Key.font: NSFont.init(name: "SFProRounded-Bold", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize, weight: NSFont.Weight.bold), NSAttributedString.Key.paragraphStyle: paragraphStyle,
                          NSAttributedString.Key.foregroundColor : fontForegroundColor ]
        
             self.draw(in: rect, withAttributes: attrs)
    }
    
     func drawStringInsideRectWithPostScriptFont(postScriptName: String, fontSize : CGFloat, textAlignment : NSTextAlignment, fontForegroundColor: NSColor, rect: NSRect)
    {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
        

            let attrs = [NSAttributedString.Key.font: NSFont.init(name: postScriptName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize, weight: NSFont.Weight.bold), NSAttributedString.Key.paragraphStyle: paragraphStyle,
                          NSAttributedString.Key.foregroundColor : fontForegroundColor ]
        
             self.draw(in: rect, withAttributes: attrs)
             
    }

}



 // MARK: ---  RADIANS TO DEGREES
    func rad2deg(_ number: CGFloat) -> CGFloat {
        return number * 180.000000 / CGFloat.pi
    }
    
    // MARK: ---  DEGREES TO RADIANS
    func deg2rad(_ number: CGFloat) -> CGFloat {
        
        return number * CGFloat.pi / 180.000000
    }
    

    // MARK: ---  CLAMPING
    // from https://github.com/kieranb662/CGExtender/blob/master/Sources/CGExtender/Clamping.swift
    extension FloatingPoint {
        public mutating func formClamp(to range: ClosedRange<Self>) {
            self = max(min(self, range.upperBound), range.lowerBound)
        }

        public func clamped(to range: ClosedRange<Self>) -> Self {
            return max(min(self, range.upperBound), range.lowerBound)
        }
    }
    extension BinaryInteger {
        public mutating func formClamp(to range: ClosedRange<Self>) {
            self = max(min(self, range.upperBound), range.lowerBound)
        }
        
        public func clamped(to range: ClosedRange<Self>) -> Self {
            return max(min(self, range.upperBound), range.lowerBound)
        }
    }
    
    
// MARK: MAP VALUES

  // from https://stackoverflow.com/questions/42817020/how-to-interpolate-from-number-in-one-range-to-a-corresponding-value-in-another
    func mapy<T: FloatingPoint>(n:T, start1:T, stop1:T, start2:T, stop2:T) -> T
    {
        return ((n-start1)/(stop1-start1))*(stop2-start2)+start2;
    }
    
    
 
 
 // MARK: TRUNCATION / REDUCE SCALE
 // from https://stackoverflow.com/questions/28652617/easily-truncating-a-double-swift?lq=1
extension Double {
    func reduceScale(to places: Int) -> Double {
        let multiplier = pow(10, Double(places))
        let newDecimal = multiplier * self // move the decimal right
        let truncated = Double(Int(newDecimal)) // drop the fraction
        let originalDecimal = truncated / multiplier // move the decimal back
        return originalDecimal
    }
}

extension CGFloat {
    func reduceScale(to places: Int) -> CGFloat {
        let multiplier = pow(10, CGFloat(places))
        let newDecimal = multiplier * self // move the decimal right
        let truncated = CGFloat(Int(newDecimal)) // drop the fraction
        let originalDecimal = truncated / multiplier // move the decimal back
        return originalDecimal
    }
}

extension CGFloat{

    func percentageString() -> String
    {
        return "\(Int(self * 100))%";
    
    }


}

    
    
/*
 func MapPointToRect(const NSPoint p, const NSRect rect) -> NSPoint
{
	// given a point <p> in 0..1 space, maps it to <rect>
	NSPoint pn;

	pn.x = (p.x * rect.size.width) + rect.origin.x;
	pn.y = (p.y * rect.size.height) + rect.origin.y;

	return pn;
}

func  MapPointFromRectToRect(const NSPoint p, const NSRect srcRect, const NSRect destRect) ->NSPoint
{
	// maps a point <p> in <srcRect> to the same relative location within <destRect>

	return MapPointToRect(MapPointFromRect(p, srcRect), destRect);
}
*/
