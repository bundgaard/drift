//
//  GEGistStore.m
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GEGistStore.h"


@implementation GEGistStore

+ (GEGistStore *)sharedStore;
{
	static GEGistStore *gSharedStore = nil;
	@synchronized(self) {
		if (!gSharedStore) {
			gSharedStore = [[GEGistStore alloc] init];
			gSharedStore.name = @"Driftpad";
			gSharedStore.forceReplace = NO;
			gSharedStore.storeType = NSSQLiteStoreType;
		}
	}
	return gSharedStore;
}

@end
