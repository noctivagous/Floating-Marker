//
//  NSBezierPath+Utilities.m
//  VectorBrush
//
//  Created by Andrew Finnell on 5/28/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import "NSBezierPath+Utilities.h"


@implementation NSBezierPath (FBUtilities)

- (NSPoint) fb_pointAtIndex:(NSUInteger)index
{
    return [self fb_elementAtIndex:index].point;
}

- (NSBezierElement) fb_elementAtIndex:(NSUInteger)index
{
    NSBezierElement element = {};
    NSPoint points[3] = {};
    element.kind = [self elementAtIndex:index associatedPoints:points];
    switch (element.kind) {
        case NSBezierPathElementMoveTo:
        case NSBezierPathElementLineTo:
        case NSBezierPathElementClosePath:
            element.point = points[0];
            break;
            
        case NSBezierPathElementCurveTo:
            element.controlPoints[0] = points[0];
            element.controlPoints[1] = points[1];
            element.point = points[2];
            break;
    }
    return element;
}

- (NSBezierPath *) fb_subpathWithRange:(NSRange)range
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path fb_copyAttributesFrom:self];
    for (NSUInteger i = 0; i < range.length; i++) {
        NSBezierElement element = [self fb_elementAtIndex:range.location + i];
        if ( i == 0 )
            [path moveToPoint:element.point];
        else
            [path fb_appendElement:element];
    }
    return path;
}

- (void) fb_copyAttributesFrom:(NSBezierPath *)path
{
    [self setLineWidth:[path lineWidth]];
    [self setLineCapStyle:[path lineCapStyle]];
    [self setLineJoinStyle:[path lineJoinStyle]];
    [self setWindingRule:[path windingRule]];
    [self setMiterLimit:[path miterLimit]];
    [self setFlatness:[path flatness]];
}

- (void) fb_appendPath:(NSBezierPath *)path
{
    NSBezierElement previousElement = [self fb_elementAtIndex:[self elementCount] - 1];
    for (NSUInteger i = 0; i < [path elementCount]; i++) {
        NSBezierElement element = [path fb_elementAtIndex:i];
        
        // If the first element is a move to where we left off, skip it
        if ( element.kind == NSBezierPathElementMoveTo ) {
            if ( NSEqualPoints(element.point, previousElement.point) )
                continue;
            else
                element.kind = NSBezierPathElementLineTo; // change it to a line to
        }
        
        [self fb_appendElement:element];
        previousElement = element;
    }
}

- (void) fb_appendElement:(NSBezierElement)element
{
    switch (element.kind) {
        case NSBezierPathElementMoveTo:
            [self moveToPoint:element.point];
            break;
        case NSBezierPathElementLineTo:
            [self lineToPoint:element.point];
            break;
        case NSBezierPathElementCurveTo:
            [self curveToPoint:element.point controlPoint1:element.controlPoints[0] controlPoint2:element.controlPoints[1]];
            break;
        case NSBezierPathElementClosePath:
            [self closePath];
            break;
    }
}

@end
