//
//  GEGistService.h
//  Driftpad
//
//  Created by Devin Chalmers on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kDriftNotificationUpdateGistsSucceeded;
extern NSString *kDriftNotificationUpdateGistsFailed;

extern NSString *kDriftNotificationUpdatedGist;

extern NSString *kDriftNotificationLoginSucceeded;
extern NSString *kDriftNotificationLoginFailed;

@class GEGist;

@interface GEGistService : NSObject {

}

+ (GEGistService *)sharedService;

- (void)clearCredentials;
- (BOOL)hasCredentials;

- (void)loginUserWithUsername:(NSString *)username token:(NSString *)token;
- (void)listGistsForCurrentUser;
- (void)fetchGist:(GEGist *)gist;
- (void)pushGist:(GEGist *)gist;

@end
