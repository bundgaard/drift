//
//  NSString_Scraping.h
//  Driftpad
//
//  Created by Devin Chalmers on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Scraping)

- (NSString *)scrapeStringAnchoredBy:(NSString *)anchorString offset:(NSInteger)offset length:(NSInteger)length;

@end
