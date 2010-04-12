//
//  NSDateFormatter_GithubDateFormatting.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSDateFormatter_GithubDateFormatting.h"


@implementation NSDateFormatter (GithubDateFormatting)

+ (NSDateFormatter *)githubDateFormatter;
{
	static NSDateFormatter *gGithubDateFormatter = nil;
	if (!gGithubDateFormatter) {
		gGithubDateFormatter = [[NSDateFormatter alloc] init];
		[gGithubDateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss Z"];
	}
	return gGithubDateFormatter;
}

@end
