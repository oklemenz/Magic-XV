//
//  GameCenterClient.h
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#define kAuthenticationErrorsMax 3

#import <Foundation/Foundation.h>

@interface GameCenterClient : NSObject <UIApplicationDelegate> {

	NSMutableArray *reportErrors;

	BOOL gameCenterAvailable;
	BOOL gameCenterAvailableFreeVersion;
	BOOL authenticated;
	int authenticationErrors;
	BOOL gameCenterError;
	BOOL inAuthentication;
	
	NSString *playerAlias;
}

@property BOOL gameCenterAvailable;
@property BOOL authenticated;
@property int authenticationErrors;
@property BOOL gameCenterError;
@property BOOL inAuthentication;

@property (nonatomic, retain, readonly, nullable) NSString *playerAlias;

+ (nullable GameCenterClient *)instance;

- (BOOL)isGameCenterAvailable;
- (void)authenticateLocalPlayer:(BOOL)popup completion:(void(^__nullable)())completion;
- (void)registerForAuthenticationNotification;
- (void)authenticationChanged;

- (void)reportTime:(double)time;
	
- (void)handleReportErrors;

@end
