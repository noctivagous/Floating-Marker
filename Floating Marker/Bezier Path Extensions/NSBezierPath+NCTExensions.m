//
//  NSBezierPath+NSBezierPath_NCTExensions.h
//  Floating Marker
//
//  Created by John Pratt on 1/23/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

NSRect CentreRectInRect(const NSRect r, const NSRect cr)
{
	// centres <r> over <cr>, returning a rect the same size as <r>

	NSRect nr;

	nr.size = r.size;

	nr.origin.x = NSMinX(cr) + ((cr.size.width - r.size.width) / 2.0);
	nr.origin.y = NSMinY(cr) + ((cr.size.height - r.size.height) / 2.0);

	return nr;
}

NSRect CentreRectOnPoint(const NSRect inRect, const NSPoint p)
{
	// relocates the rect so its centre is at p. Does not change the rect's size

	NSRect r = inRect;

	r.origin.x = p.x - (inRect.size.width * 0.5);
	r.origin.y = p.y - (inRect.size.height * 0.5);
	return r;
}

CGFloat LineLength(const NSPoint a, const NSPoint b)
{
	return hypot(b.x - a.x, b.y - a.y);
}

NSPoint Interpolate(const NSPoint a, const NSPoint b, const CGFloat proportion)
{
	NSPoint p;

	p.x = a.x + ((b.x - a.x) * proportion);
	p.y = a.y + ((b.y - a.y) * proportion);
	return p;
}

static void CGPathCallback(void *info, const CGPathElement *element) {
    NSBezierPath *bezierPath = (__bridge NSBezierPath *)info;
    CGPoint *points = element->points;
    switch(element->type) {
        case kCGPathElementMoveToPoint: [bezierPath moveToPoint:points[0]]; break;
        case kCGPathElementAddLineToPoint: [bezierPath lineToPoint:points[0]]; break;
        case kCGPathElementAddQuadCurveToPoint: {
            NSPoint qp0 = bezierPath.currentPoint, qp1 = points[0], qp2 = points[1], cp1, cp2;
            CGFloat m = (2.0 / 3.0);
            cp1.x = (qp0.x + ((qp1.x - qp0.x) * m));
            cp1.y = (qp0.y + ((qp1.y - qp0.y) * m));
            cp2.x = (qp2.x + ((qp1.x - qp2.x) * m));
            cp2.y = (qp2.y + ((qp1.y - qp2.y) * m));
            [bezierPath curveToPoint:qp2 controlPoint1:cp1 controlPoint2:cp2];
            break;
        }
        case kCGPathElementAddCurveToPoint: [bezierPath curveToPoint:points[2] controlPoint1:points[0] controlPoint2:points[1]]; break;
        case kCGPathElementCloseSubpath: [bezierPath closePath]; break;
    }
}

@implementation NSBezierPath (BezierPathWithCGPath)

#pragma mark -
#pragma mark - getting the outline of a stroked path
- (NSBezierPath*)strokedPath
{
	// returns a path representing the stroked edge of the receiver, taking into account its current width and other
	// stroke settings. This works by converting to a quartz path and using the similar system function there.

	// this creates an offscreen graphics context to support the CG function used, but the context itself does not
	// need to actually draw anything, therefore a simple 1x1 bitmap is used and reused for this context.

	NSBezierPath* path = nil;
	NSGraphicsContext* ctx = nil;
	static NSBitmapImageRep* rep = nil;

	if (rep == nil) {
		rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
													  pixelsWide:1
													  pixelsHigh:1
												   bitsPerSample:8
												 samplesPerPixel:3
														hasAlpha:NO
														isPlanar:NO
												  colorSpaceName:NSCalibratedRGBColorSpace
													 bytesPerRow:4
													bitsPerPixel:32];
	}

	ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];

	NSAssert(ctx != nil, @"no context for -strokedPath");

	[NSGraphicsContext saveGraphicsState];
		[NSGraphicsContext setCurrentContext:ctx];

	CGContextRef context = [self setQuartzPath];

	path = self;

	if (context) {
		CGContextReplacePathWithStrokedPath(context);
		path = [NSBezierPath bezierPathWithPathFromContext:context];
	}

	[NSGraphicsContext restoreGraphicsState];
		return path;
}

+ (NSBezierPath*)bezierPathWithPathFromContext:(CGContextRef)context
{
	// given a context, this converts its current path to an NSBezierPath. It is the inverse to the -setQuartzPath method.

	NSAssert(context != nil, @"no context for bezierPathWithPathFromContext");

	CGPathRef cp = CGContextCopyPath(context);
	NSBezierPath* bp = [self bezierPathWithCGPath:cp];
	CGPathRelease(cp);

	return bp;
}

- (CGContextRef)setQuartzPath
{
	// converts the path to a CGPath and adds it as the current context's path. It also copies the current line width
	// and join and cap styles, etc. to the context.

    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];

	NSAssert(context != nil, @"no context for setQuartzPath");

	if (context)
		[self setQuartzPathInContext:context
						   isNewPath:YES];

	return context;
}

#pragma mark -
#pragma mark - converting to and from Core Graphics paths

- (CGPathRef)newQuartzPath
{
	CGMutablePathRef mpath = [self newMutableQuartzPath];
	CGPathRef path = CGPathCreateCopy(mpath);
	CGPathRelease(mpath);

	// the caller is responsible for releasing the returned value when done

	return path;
}

- (CGMutablePathRef)newMutableQuartzPath
{
	NSInteger i, numElements;

	// If there are elements to draw, create a CGMutablePathRef and draw.

	numElements = [self elementCount];
	if (numElements > 0) {
		CGMutablePathRef path = CGPathCreateMutable();
		NSPoint points[3];

		for (i = 0; i < numElements; i++) {
			switch ([self elementAtIndex:i
						associatedPoints:points]) {
                case NSBezierPathElementMoveTo:
				CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
				break;

                case NSBezierPathElementLineTo:
				CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
				break;

                case NSBezierPathElementCurveTo:
				CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
					points[1].x, points[1].y,
					points[2].x, points[2].y);
				break;

                case NSBezierPathElementClosePath:
				CGPathCloseSubpath(path);
				break;

			default:
				break;
			}
		}

		// the caller is responsible for releasing this ref when done

		return path;
	}

	return nil;
}

- (void)setQuartzPathInContext:(CGContextRef)context isNewPath:(BOOL)np
{
	NSAssert(context != nil, @"no context for [NSBezierPath setQuartzPathInContext:isNewPath:]");

	CGPathRef cp = [self newQuartzPath];

	if (np)
		CGContextBeginPath(context);

	CGContextAddPath(context, cp);
	CGPathRelease(cp);

	CGContextSetLineWidth(context, [self lineWidth]);
	CGContextSetLineCap(context, (CGLineCap)[self lineCapStyle]);
	CGContextSetLineJoin(context, (CGLineJoin)[self lineJoinStyle]);
	CGContextSetMiterLimit(context, [self miterLimit]);

	CGFloat lengths[16];
	CGFloat phase;
	NSInteger count;

	[self getLineDash:lengths
				count:&count
				phase:&phase];
	CGContextSetLineDash(context, phase, lengths, count);
}

- (NSBezierPath*)strokedPathWithStrokeWidth:(CGFloat)width
{
	CGFloat savedLineWidth = [self lineWidth];

	[self setLineWidth:width];
	NSBezierPath* newPath = [self strokedPath];
	[self setLineWidth:savedLineWidth];

	return newPath;
}


static void ConvertPathApplierFunction(void* info, const CGPathElement* element)
{
    NSBezierPath* np = (__bridge NSBezierPath*)info;

    CGPoint *points = element->points;
    
	switch (element->type) {
	case kCGPathElementMoveToPoint:
		[np moveToPoint:*(NSPoint*)element->points];
		break;

	case kCGPathElementAddLineToPoint:
		[np lineToPoint:*(NSPoint*)element->points];
		break;

            /*
	case kCGPathElementAddQuadCurveToPoint:
		[np curveToPoint:NSPointFromCGPoint(element->points[1])
			controlPoint1:NSPointFromCGPoint(element->points[0])
			controlPoint2:NSPointFromCGPoint(element->points[0])];
		break;
*/
            //NCTVGS replacement
        case kCGPathElementAddQuadCurveToPoint: {
            NSPoint qp0 = np.currentPoint, qp1 = points[0], qp2 = points[1], cp1, cp2;
            CGFloat m = (2.0 / 3.0);
            cp1.x = (qp0.x + ((qp1.x - qp0.x) * m));
            cp1.y = (qp0.y + ((qp1.y - qp0.y) * m));
            cp2.x = (qp2.x + ((qp1.x - qp2.x) * m));
            cp2.y = (qp2.y + ((qp1.y - qp2.y) * m));
            [np curveToPoint:qp2 controlPoint1:cp1 controlPoint2:cp2];
            break;
        }
            
	case kCGPathElementAddCurveToPoint:
		[np curveToPoint:NSPointFromCGPoint(element->points[2])
			controlPoint1:NSPointFromCGPoint(element->points[0])
			controlPoint2:NSPointFromCGPoint(element->points[1])];
		break;

	case kCGPathElementCloseSubpath:
		[np closePath];
		break;

	default:
		break;
	}
}


+ (NSBezierPath*)bezierPathWithCGPath:(CGPathRef)path
{
	// given a CGPath, this converts it to the equivalent NSBezierPath by using a custom apply function

	NSAssert(path != nil, @"CG path was nil in bezierPathWithCGPath");

	NSBezierPath* newPath = [self bezierPath];
    CGPathApply(path, (__bridge void * _Nullable)(newPath), ConvertPathApplierFunction);
	return newPath;
}

+ (NSBezierPath *)JNS_bezierPathWithCGPath:(CGPathRef)cgPath {
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];
    CGPathApply(cgPath, (__bridge void *)bezierPath, CGPathCallback);
    return bezierPath;
}

- (NSBezierPath*)bezierPathWithFragmentedLineSegments:(CGFloat)flatness
{
	// this is only really useful as a step in the roughened stroke processing. It takes a path and for any line elements in the path, it breaks them up into
	// much shorter lengths by interpolation.

	NSBezierPath* newPath = [NSBezierPath bezierPath];
	NSInteger i, m, k, j;
	NSBezierPathElement element;
	NSPoint ap[3];
	NSPoint fp, pp;
	CGFloat len, t;

	fp = pp = NSZeroPoint; // shut up, stupid warning

	m = [self elementCount];

	for (i = 0; i < m; ++i) {
		element = [self elementAtIndex:i
					  associatedPoints:ap];

		switch (element) {
		case NSBezierPathElementMoveTo:
			fp = pp = ap[0];
			[newPath moveToPoint:fp];
			break;

		case NSBezierPathElementLineTo:
            
			len = LineLength(pp, ap[0]);
			k = ceil(len / flatness);

			if (k <= 0.0)
				continue;

			//NSLog(@"inserting %d fragments", k );

			for (j = 0; j < k; ++j) {
				t = ((j + 1) * flatness) / len;
				NSPoint np = Interpolate(pp, ap[0], t);
				[newPath lineToPoint:np];
			}
			pp = ap[0];
			break;

		case NSBezierPathElementCurveTo:
			[newPath curveToPoint:ap[2]
					controlPoint1:ap[0]
					controlPoint2:ap[1]];
			pp = ap[2];
			break;

		case NSBezierPathElementClosePath:
			[newPath closePath];
			pp = fp;
			break;

		default:
			break;
		}
	}

	return newPath;
}

@end


NS_ASSUME_NONNULL_END
