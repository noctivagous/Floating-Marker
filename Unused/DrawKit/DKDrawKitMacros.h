/**
 @author Contributions from the community; see CONTRIBUTORS.md
 @date 2005-2016
 @copyright MPL2; see LICENSE.txt
*/

//#import <Cocoa/Cocoa.h>
#include <tgmath.h>

// pinning a value between a lower and upper limit

#define LIMIT(value, min, max) (((value) < (min)) ? (min) : (((value) > (max)) ? (max) : (value)))

// converting from radians to degrees

#define DEGREES_TO_RADIANS(d) ((d)*0.0174532925199432958)
#define RADIANS_TO_DEGREES(r) ((r)*57.29577951308232)

// some useful angular constants

#define FIFTEEN_DEGREES (0.261799387799)
#define NINETY_DEGREES M_PI_2
#define FORTYFIVE_DEGREES M_PI_4
#define HALF_PI M_PI_2

// exception safe save/restore of the current graphics context

#define SAVE_GRAPHICS_CONTEXT \
	@try {                    \
		[NSGraphicsContext saveGraphicsState];
#define RESTORE_GRAPHICS_CONTEXT                  \
	}                                             \
	@finally                                      \
	{                                             \
		[NSGraphicsContext restoreGraphicsState]; \
	}
