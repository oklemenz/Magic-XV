//
//  AppDelegate.h
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CC3UIViewController.h"
#import <CoreMotion/CoreMotion.h>

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define IS_IPHONE_4  (SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5  (SCREEN_MAX_LENGTH < 667.0)
#define IS_IPHONE_6  (SCREEN_MAX_LENGTH < 736.0)
#define IS_IPHONE_6P (SCREEN_MAX_LENGTH >= 736.0)

@class RootViewController;
@class GameViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) RootViewController *rootViewController;
@property (nonatomic, strong) GameViewController *gameViewController;

@property (nonatomic, strong) CMMotionManager *motionManager;

+ (AppDelegate *)instance;

@end
