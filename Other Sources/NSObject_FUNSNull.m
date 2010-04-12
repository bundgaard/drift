//
//  NSObject_FUNSNull.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSObject_FUNSNull.h"


@implementation NSObject (FUNSNull)

- (id)objectOrNil;
{
	// NSNull, I hate you so fucking much
	if (self == [NSNull null])
		return nil;
	
	return self;
}

@end
