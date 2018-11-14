//
//  GameViewController.h
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CC3UIViewController.h"
#import "Scene.h"
#import <GameKit/GameKit.h>

@class HUDViewController;

@interface GameViewController : CC3DeviceCameraOverlayUIViewController <SceneDelegate, UIAlertViewDelegate,
    GKLeaderboardViewControllerDelegate>

@property(nonatomic, strong) HUDViewController *hud;
@property(nonatomic, strong) UIView *gameView;

@property BOOL inTransition;
@property ccDeviceOrientation ccOrientation;
@property BOOL shouldRestoreCamera;

- (void)registerTouchView;
- (void)setup;

- (void)setCamera:(BOOL)animated;
- (void)toggleCamera:(BOOL)animated;
- (void)setGyro;
- (void)toggleGyro;
- (void)setSound;
- (void)toggleSound;
- (void)showGameCenter;

- (void)shuffleGame;
- (void)solveGame;

- (void)storeEnded;
- (void)gameCenterEnded;

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController;

+ (GameViewController *)instance;

@end
