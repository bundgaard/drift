//
//  GEGistStore.h
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CCoreDataManager.h"

@interface GEGistStore : CCoreDataManager {

}

+ (GEGistStore *)sharedStore;

@end
