//
//  NSBezierPath+NCTExtensions.h
//  Floating Marker
//
//  Created by John Pratt on 1/23/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

CGFloat LineLength(const NSPoint a, const NSPoint b);

NSPoint Interpolate(const NSPoint a, const NSPoint b, const CGFloat proportion);

NSRect CentreRectInRect(const NSRect r, const NSRect cr);

NSRect CentreRectOnPoint(const NSRect inRect, const NSPoint p);

#pragma mark -


@interface NSBezierPath (BezierPathWithCGPath)
- (NSBezierPath*)strokedPath;
- (NSBezierPath*)strokedPathWithStrokeWidth:(CGFloat)width;
+ (NSBezierPath*)bezierPathWithPathFromContext:(CGContextRef)context;
+ (NSBezierPath*)bezierPathWithCGPath:(CGPathRef)path;
+ (NSBezierPath *)JNS_bezierPathWithCGPath:(CGPathRef)cgPath;
- (NSBezierPath*)bezierPathWithFragmentedLineSegments:(CGFloat)flatness;
@end



NS_ASSUME_NONNULL_END
