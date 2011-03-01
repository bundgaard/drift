//
//  CKeychain.h
//  Driftpad
//
//  Created by Devin Chalmers on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CKeychain : NSObject {
    
}

+ (NSString *) passwordForKey:(NSString *)aKey;
+ (void) savePassword:(NSString *)password forKey:(NSString *)aKey;

@end
