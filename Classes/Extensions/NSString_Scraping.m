//
//  NSString_Scraping.m
//  Driftpad
//
//  Created by Devin Chalmers on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString_Scraping.h"


@implementation NSString (Scraping)

- (NSString *)scrapeStringAnchoredBy:(NSString *)anchorString offset:(NSInteger)offset length:(NSInteger)length;
{
	NSRange anchorRange = [self rangeOfString:anchorString];
	
	if (anchorRange.location == NSNotFound)
		return nil;
	
	if (anchorRange.location + anchorRange.length + offset + length >= self.length)
		return nil;
	
	NSRange scrapeRange = NSMakeRange(anchorRange.location + anchorRange.length + offset, length);
	return [self substringWithRange:scrapeRange];
}

@end
