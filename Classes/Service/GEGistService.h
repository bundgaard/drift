//
//  GEGistService.h
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CCompletionTicket.h"

extern NSString *kDriftNotificationUpdatedGists;
extern NSString *kDriftNotificationUpdatedGist;
extern NSString *kDriftNotificationLoginSucceeded;
extern NSString *kDriftNotificationLoginFailed;

@class GEGist;

@interface GEGistService : NSObject <CCompletionTicketDelegate> {

}

+ (GEGistService *)sharedService;

- (BOOL)hasCredentials;

- (void)loginUserWithUsername:(NSString *)username token:(NSString *)token;
- (void)listGistsForCurrentUser;
- (void)fetchGist:(GEGist *)gist;
- (void)pushGist:(GEGist *)gist;

@end
