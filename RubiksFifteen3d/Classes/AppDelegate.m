//
//  AppDelegate.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#import "AppDelegate.h"
#import "RootViewController.h"
#import "GameViewController.h"
#import "HUDViewController.h"
#import "Layer.h"
#import "Scene.h"
#import "CC3EAGLView.h"
#import "UserData.h"
#import "StoreClient.h"
#import "GameCenterClient.h"

@interface AppDelegate ()
@property BOOL shouldRestoreCamera;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching: (UIApplication*) application {
	if (![CCDirector setDirectorType: kCCDirectorTypeDisplayLink]) {
		[CCDirector setDirectorType: kCCDirectorTypeDefault];
    }
    CCTexture2D.defaultAlphaPixelFormat = kCCTexture2DPixelFormat_RGBA8888;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.rootViewController = [RootViewController new];
    self.rootViewController.view.frame = [[UIScreen mainScreen] bounds];
    [self.window addSubview:self.rootViewController.view];
    self.window.rootViewController = self.rootViewController;
	[self.window makeKeyAndVisible];
    
    [UserData instance];
    [StoreClient instance];
    
	self.gameViewController = [GameViewController instance];
    [self.rootViewController addChildViewController:self.gameViewController];
    [self.gameViewController didMoveToParentViewController:self.rootViewController];
    [self.gameViewController setCamera:NO];
    
	CCDirector *director = CCDirector.sharedDirector;
	director.animationInterval = (1.0f / 60.0f);
	director.displayFPS = NO;
	director.openGLView = self.gameViewController.view;
	[director enableRetinaDisplay:YES];
    
	Layer *layer = [Layer node]; //[[Layer alloc] initWithColor:ccc4(0, 0, 255, 255)];
	[layer scheduleUpdate];
    Scene *scene = [Scene scene];
	layer.cc3Scene = scene;
	[self.gameViewController runSceneOnNode:layer];
    [self.gameViewController registerTouchView];
    [self.gameViewController setup];
    
    [[GameCenterClient instance] authenticateLocalPlayer:NO completion:nil];
}

- (void)resumeApp {
    [CCDirector.sharedDirector resume];
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
	[NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(resumeApp) userInfo:nil repeats:NO];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application {
	[CCDirector.sharedDirector purgeCachedData];
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
	[CCDirector.sharedDirector stopAnimation];
    if ([UserData instance].cameraOn) {
        self.shouldRestoreCamera = YES;
        [self.gameViewController toggleCamera:NO];
    }
    [[UserData instance] store];
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
	[CCDirector.sharedDirector startAnimation];
    if (self.shouldRestoreCamera) {
        [self.gameViewController toggleCamera:YES];
        self.shouldRestoreCamera = NO;
    }
}

- (void)applicationWillTerminate:(UIApplication*)application {
	[CCDirector.sharedDirector.openGLView removeFromSuperview];
	[CCDirector.sharedDirector end];
    [[UserData instance] store];
}

- (void)applicationSignificantTimeChange:(UIApplication*)application {
	[CCDirector.sharedDirector setNextDeltaTimeZero:YES];
}

+ (AppDelegate *)instance {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

@end
