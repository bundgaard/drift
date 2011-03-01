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

extern NSString *kDriftNotificationUpdateGistSucceeded;
extern NSString *kDriftNotificationUpdateGistFailed;

extern NSString *kDriftNotificationLoginSucceeded;
extern NSString *kDriftNotificationLoginFailed;

@class GEGist;

@interface GEGistService : NSObject {

}

+ (GEGistService *)sharedService;

- (void)clearCredentials;
- (BOOL)hasCredentials;

@property (nonatomic, assign) BOOL anonymous;

@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *password;

@property (readonly) NSDictionary *anonymousUser;

- (void)loginUserWithUsername:(NSString *)username password:(NSString *)password;
- (void)loginAnonymously;

- (void)listGistsForCurrentUser;

- (void)fetchGist:(GEGist *)gist;
- (void)pushGist:(GEGist *)gist;

@end
