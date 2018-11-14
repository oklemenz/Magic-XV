//
//  GameCenterClient.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#import "GameCenterClient.h"
#import "GameViewController.h"

@implementation GameCenterClient

@synthesize gameCenterAvailable, authenticated, authenticationErrors, gameCenterError, inAuthentication, playerAlias;

+ (GameCenterClient *)instance {
	static GameCenterClient *_instance;
	@synchronized(self) {
		if (!_instance) {
			_instance = [GameCenterClient new];
		}
	}
	return _instance;
}

- (id)init {
	if ((self = [super init])) {
		reportErrors = [[NSMutableArray alloc] init];
		gameCenterError = NO;
	 	authenticated = NO;
		gameCenterAvailable = [self isGameCenterAvailable];
		if (gameCenterAvailable) {
			[self registerForAuthenticationNotification];
		}
	}
	return self;
}

- (BOOL)isGameCenterAvailable {
	Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
	NSString *reqSysVer = @"4.1";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
	return gcClass && osVersionSupported;
}

- (void)authenticateLocalPlayer:(BOOL)popup completion:(void(^__nullable)())completion {
    static BOOL showPopup;
    showPopup = popup;
	if (gameCenterAvailable) {
		if (!authenticated && !inAuthentication && authenticationErrors < kAuthenticationErrorsMax) {
			inAuthentication = YES;
			[[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError *error) {
				if (error != nil) {
					if (showPopup) {
                        authenticationErrors++;
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Game Center", @"") message:NSLocalizedString(@"Error connecting to Game Center!", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
						[alert show];
					}
					authenticated = NO;
					gameCenterError = YES;
				} else {
					authenticationErrors = 0;
					authenticated = YES;
					playerAlias = [GKLocalPlayer localPlayer].alias;
					[self handleReportErrors];
                    if (completion) {
                        completion();
                    }
				}
				inAuthentication = NO;
                showPopup = NO;
			}];
		}
	}
}

- (void)registerForAuthenticationNotification {
	if (gameCenterAvailable) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(authenticationChanged) name:GKPlayerAuthenticationDidChangeNotificationName object:nil];
	}
}

- (void)authenticationChanged {
	if (gameCenterAvailable) {
		if ([GKLocalPlayer localPlayer].isAuthenticated) {
			[self handleReportErrors];
			authenticated = YES;
			playerAlias = [GKLocalPlayer localPlayer].alias;
		} else {
			authenticated = NO;
			playerAlias = @"";
		}
	}
}

- (void)reportTime:(double)time {
	if (gameCenterAvailable) {
		[self handleReportErrors];
		int64_t bestTime = time;
		NSString *category = @"BEST_TIMES_2";
		GKScore *timeReporter = [[GKScore alloc] initWithCategory:category];
		if (timeReporter) {
			timeReporter.value = bestTime;
			[timeReporter reportScoreWithCompletionHandler:^(NSError *error) {
				if (error != nil) {
					[reportErrors addObject:timeReporter];
					gameCenterError	= YES;
					return;
				}
			}];
		}
	}
}

- (void)handleReportErrors {
	if (gameCenterAvailable && authenticated) {
		if ([reportErrors count] > 0) {
			for (GKScore *time in [NSMutableArray arrayWithArray:reportErrors]) {
				[time reportScoreWithCompletionHandler:^(NSError *error) {
					if (error == nil) {
						[reportErrors removeObject:time];
					}
				}];
			}
		}
	}
}

@end