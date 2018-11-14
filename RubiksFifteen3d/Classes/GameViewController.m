
//
//  GameViewController.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#import "GameViewController.h"
#import "Scene.h"
#import "Layer.h"
#import "AppDelegate.h"
#import "UserData.h"

#import "AugumentedReality.h"
#import "HUDViewController.h"
#import "BackgroundViewController.h"
#import "TouchView.h"
#import "GameCenterClient.h"
#import "SoundManager.h"
#import "StoreClient.h"
#import "RootViewController.h"

#define kDeviceCameraToolbarHeightIPhone4 54.0
#define kDeviceCameraToolbarHeightIPhone5 115.0
#define kDeviceCameraToolbarHeightIPhone6 135.0
#define kDeviceCameraToolbarHeightIPhone6p 155.0

#define kDeviceOrientationNotification @"UIDeviceOrientationDidChangeNotification"
#define degreesToRadian(x) (M_PI * (x) / 180.0)

#define kAlertViewSolved         1
#define kAlertViewBackSolved     2
#define kAlertViewAskForDonation 3

@interface GameViewController () {
	BackgroundViewController *background;
    BOOL isOverlayingBackground;
}

@property CGFloat widthHeightDelta;
@property CGFloat normalWidth;
@property (nonatomic, retain) UIView *blankView;

@property CGFloat hudTopBarOffset;

@property Layer *layer;
@property Scene *scene;

@property (getter = isInShuffle) BOOL inShuffle;
@property (getter = isInSolve) BOOL inSolve;

@property (nonatomic) double timeForDonationPopup;
@property (nonatomic, getter = isDonationPopupActive) BOOL donationPopupActive;

@end

@implementation GameViewController

@synthesize gameView = _gameView;

- (id)init {
    self = [super init];
    if (self) {
        // Orientation change is handled via device orientation notification
        self.supportedInterfaceOrientations = UIInterfaceOrientationMaskPortrait; // UIInterfaceOrientationMaskAll;
        
        // Needed for shadowing
        // self.viewDepthFormat = GL_DEPTH24_STENCIL8_OES;
        
        // Antialiasing
        self.viewPixelSamples = 4;
        NSString *model = [[UIDevice currentDevice] model];
        // Simulator flickers at higher sampling
        if ([model rangeOfString:@"Simulator"].location != NSNotFound) {
            self.viewPixelSamples = 1;
        }
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(deviceOrientationDidChange:)
                                                     name:kDeviceOrientationNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraIsReadyNotification:) name:AVCaptureSessionDidStartRunningNotification object:nil];
        self.timeForDonationPopup = 0;
    }
    return self;
}

- (void)loadView {
    self.ccOrientation = UIDeviceOrientationPortrait;
    self.widthHeightDelta = (self.viewBounds.size.height - self.viewBounds.size.width) / 2.0;
    self.normalWidth = self.viewBounds.size.width;
    self.viewBounds = CGRectMake(-self.widthHeightDelta, 0, self.viewBounds.size.height, self.viewBounds.size.height);
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.hud = [[HUDViewController alloc] initWithNibName:@"HUDViewController_iPad" bundle:nil];
    } else {
        self.hud = [[HUDViewController alloc] initWithNibName:@"HUDViewController_iPhone" bundle:nil];
    }
    self.hud.delegate = self;
    CGPoint center = self.view.center;
    self.hud.view.frame = self.view.frame;
    self.hudTopBarOffset = 0;
    self.hud.topBar.frame = CGRectMake(self.widthHeightDelta, self.hudTopBarOffset, self.normalWidth, self.hud.topBar.frame.size.height);
    self.hud.bottomBar.frame = CGRectMake(self.widthHeightDelta, self.view.bounds.size.height - self.hud.bottomBar.frame.size.height, self.normalWidth, self.hud.bottomBar.frame.size.height);
    self.hud.view.center = center;
    
    if (![[AppDelegate instance] motionManager].isDeviceMotionAvailable ||
        ![[AppDelegate instance] motionManager].isGyroAvailable) {
        self.hud.gyroButton.enabled = NO;
    }
    if (!self.isDeviceCameraAvailable) {
        self.hud.cameraButton.enabled = NO;
    }
    if (![GameCenterClient instance].isGameCenterAvailable) {
        self.hud.gameCenterButton.enabled = NO;
    }
}

- (UIView *)gameView {
    if ([UserData instance].cameraOn) {
        return self.picker.view;
    }
    if (!self.blankView) {
        self.blankView = [[UIView alloc] initWithFrame:self.view.bounds];
        self.blankView.backgroundColor = [UIColor clearColor];
    }
    return self.blankView;
}

- (void)registerTouchView {
    self.layer = (Layer *)self.controlledNode;
    self.scene = (Scene *)(self.layer).cc3Scene;
    ((TouchView *)self.hud.view).touchView = self.view;
    ((TouchView *)self.hud.view).cc3Layer = self.layer;
}

- (void)setup {
    [self.scene setup];
    self.scene.delegate = self;
    [self setSound];
    [self setGyro];
    [self setCamera:YES];
    if ([UserData instance].isInPlay) {
        [self updateTimer:0.0];
    }
}

- (void)setCamera:(BOOL)animated {
    if (self.inTransition) {
        return;
    }
    if ([UserData instance].cameraOn) {
        if (self.isDeviceCameraAvailable) {
            self.inTransition = YES;
            [self.view removeFromSuperview];
            [self.hud.view removeFromSuperview];
            [self.picker.view addSubview:[self getFadeCover:^{
                self.inTransition = NO;
            } fadeOut:YES]];
            [self.picker.view addSubview:self.view];
            [self.picker.view addSubview:self.hud.view];
            [self setIsOverlayingDeviceCamera:YES];
        } else {
            [UserData instance].cameraOn = NO;
        }
    } else {
        if (animated) {
            self.inTransition = YES;
            UIView *fadeCover = [self getFadeCover:^() {
                [self setIsOverlayingDeviceCamera:NO];
                [self.picker.view removeFromSuperview];
                [self.view removeFromSuperview];
                [self.hud.view removeFromSuperview];
                [self.gameView addSubview:self.view];
                // Add HUD not as child but as sibling to prevent flickering during rotation
                [self.gameView addSubview:self.hud.view];
                [self.parentViewController.view addSubview:self.gameView];
                self.inTransition = NO;
            } fadeOut:NO];
            [self.picker.view insertSubview:fadeCover belowSubview:self.view];
        } else {
            [self setIsOverlayingDeviceCamera:NO];
            [self.picker.view removeFromSuperview];
            [self.view removeFromSuperview];
            [self.hud.view removeFromSuperview];
            [self.gameView addSubview:self.view];
            [self.gameView addSubview:self.hud.view];
            [self.parentViewController.view addSubview:self.gameView];
        }
    }
}

- (void)toggleCamera:(BOOL)animated {
    if (self.inTransition) {
        return;
    }
    [UserData instance].cameraOn = ![UserData instance].cameraOn;
    [self setCamera:animated];
}

- (void)setGyro {
    [self.scene toggleGyro:[UserData instance].gyroOn];
}

- (void)toggleGyro {
    [UserData instance].gyroOn = ![UserData instance].gyroOn;
    [self setGyro];
}

- (void)setSound {
    if (![UserData instance].soundOn) {
        [[SoundManager instance] stopSound];
    }
}

- (void)toggleSound {
    [UserData instance].soundOn = ![UserData instance].soundOn;
    [self setSound];
}

- (void)showGameCenter {
    if ([UserData instance].cameraOn) {
        self.shouldRestoreCamera = YES;
        [self toggleCamera:NO];
    }
    [self showLeaderboard];
}

- (void)gameCenterEnded {
    if (self.shouldRestoreCamera) {
        [self toggleCamera:YES];
    }
    self.shouldRestoreCamera = NO;
}

- (void)showLeaderboard {
    if ([GameCenterClient instance].gameCenterAvailable) {
        if ([GameCenterClient instance].authenticated) {
            [self openLeaderboard];
        } else {
            [[GameCenterClient instance] authenticateLocalPlayer:YES completion:^{
                [self openLeaderboard];
            }];
        }
    }
}

- (void)openLeaderboard {
    [[GameCenterClient instance] handleReportErrors];
    GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];
    if (leaderboardController) {
        leaderboardController.leaderboardDelegate = self;
        NSString *category = @"BEST_TIMES_2";
        leaderboardController.category = category;
        [self presentViewController:leaderboardController animated:YES completion:^{
        }];
    }
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController {
    [self deviceOrientationDidChange:nil];
    [viewController dismissViewControllerAnimated:YES completion:^{
        [viewController.view removeFromSuperview];
        [[GameViewController instance] gameCenterEnded];
    }];
}

- (void)gameSolved {
    if ([UserData instance].inPlay) {
        [UserData instance].inPlay = NO;
        [[GameCenterClient instance] reportTime:[UserData instance].time];
        NSString *time = [self getTime];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Congratulation", @"") message:
                                  [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"You solved Magic Fifteen in", @""), time] delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:NSLocalizedString(@"Game Center", @""), nil];
        alertView.tag = kAlertViewSolved;
        [alertView show];
        [UserData instance].time = 0;
    }
}

- (void)backSolved {
    if ([UserData instance].inPlay) {
        NSString *time = [self getTime];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Congratulation", @"") message:
                                  [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"You solved the back side of Magic Fifteen in", @""), time] delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        alertView.tag = kAlertViewBackSolved;
        [alertView show];
    }
}

- (NSString *)getTime {
    int h = [UserData instance].time / 3600;
    int m = ((int)([UserData instance].time / 60)) % 60;
    int s = ((int)[UserData instance].time) % 60;
    NSString *time = @"";
    NSString *separator = @"";
    if (h == 1) {
        time = [NSString stringWithFormat:@"%@%@ %i %@", time, separator, h, NSLocalizedString(@"Hour", @"")];
        separator = @",";
    } else if (h > 1) {
        time = [NSString stringWithFormat:@"%@%@ %i %@", time, separator, h, NSLocalizedString(@"Hours", @"")];
        separator = @",";
    }
    if (m == 1) {
        time = [NSString stringWithFormat:@"%@%@ %i %@", time, separator, m, NSLocalizedString(@"Minute", @"")];
        separator = @",";
    } else if (m > 1) {
        time = [NSString stringWithFormat:@"%@%@ %i %@", time, separator, m, NSLocalizedString(@"Minutes", @"")];
        separator = @",";
    }
    if (s == 1) {
        time = [NSString stringWithFormat:@"%@%@ %i %@", time, separator, s, NSLocalizedString(@"Second", @"")];
        separator = @",";
    } else if (s > 1) {
        time = [NSString stringWithFormat:@"%@%@ %i %@", time, separator, s, NSLocalizedString(@"Seconds", @"")];
        separator = @",";
    }
    time = [time stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return time;
}

- (void)showAskForDonation {
    if (!self.isDonationPopupActive) {
        self.timeForDonationPopup = 0;
        self.donationPopupActive = YES;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Do you like the game \"Magic Fifteen\"?", @"") message:[NSString stringWithFormat:NSLocalizedString(@"Help to make the game better with a donation!", @""), time] delegate:self cancelButtonTitle:NSLocalizedString(@"Remind me later", @"") otherButtonTitles:NSLocalizedString(@"I'd like to donate", @""), NSLocalizedString(@"Don't ask me again", @""), nil];
        alertView.tag = kAlertViewAskForDonation;
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kAlertViewSolved) {
        [self.hud.shuffleButton setTitle:NSLocalizedString(@"Shuffle", @"") forState:UIControlStateNormal];
        if (buttonIndex != alertView.cancelButtonIndex) {
            [self showGameCenter];
        }
    } else if (alertView.tag == kAlertViewAskForDonation) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            [[UserData instance] increaseDonationTime];
            self.donationPopupActive = NO;
        } else if (buttonIndex == 1) {
            [[StoreClient instance] showDonations];
        } else if (buttonIndex == 2) {
            [UserData instance].donationTime = 0;
            self.donationPopupActive = NO;
        }
    }
}

- (void)storeEnded {
    self.donationPopupActive = NO;
}

- (void)shuffleGame {
    if ([UserData instance].inPlay) {
        [UserData instance].inPlay = NO;
        [self.hud.shuffleButton setTitle:NSLocalizedString(@"Shuffle", @"") forState:UIControlStateNormal];
        return;
    }
    if (self.inSolve) {
        self.inSolve = NO;
    }
    if (self.inShuffle) {
        self.inShuffle = NO;
        return;
    }
    self.inShuffle = YES;
    [self.hud.shuffleButton setTitle:NSLocalizedString(@"Stop", @"") forState:UIControlStateNormal];
    self.scene.controlDisabled = YES;
    self.hud.solveButton.enabled = NO;
    [self.scene rotateToFront:^{
        [self.scene initShuffle];
        [self shuffleGameTurn];
    }];
}

- (void)shuffleGameTurn {
    if (!self.inShuffle) {
        self.scene.controlDisabled = NO;
        self.hud.solveButton.enabled = YES;
        [self.hud.shuffleButton setTitle:NSLocalizedString(@"Shuffle", @"") forState:UIControlStateNormal];
        return;
    }
    [self.scene shuffleNextPanel:^(int panel, BOOL turn, BOOL done) {
        if (!done) {
            if (turn) {
                [self.scene rotateToBack:^{
                    [self shuffleGameTurn];
                }];
            } else {
                [self shuffleGameTurn];
            }
        } else {
            [self.scene rotateToFront:^{
                if (self.inShuffle) {
                    [UserData instance].inPlay = YES;
                    [UserData instance].time = 0.0;
                    [self updateTimer:0.0];
                }
                self.inShuffle = NO;
                self.scene.controlDisabled = NO;
                self.hud.solveButton.enabled = YES;
            }];
        }
    }];
}

- (void)updateTimer:(ccTime)delta {
    if ([UserData instance].inPlay) {
        [UserData instance].time += delta;
        int h = [UserData instance].time / 3600;
        int m = ((int)([UserData instance].time / 60)) % 60;
        int s = ((int)[UserData instance].time) % 60;
        NSString *formattedTime = [NSString stringWithFormat:@"%u:%02u:%02u", h, m, s];
        [self.hud.shuffleButton setTitle:formattedTime forState:UIControlStateNormal];
    }
    if (!self.isDonationPopupActive) {
        self.timeForDonationPopup += delta;
        if (![UserData instance].donated && [UserData instance].donationTime > 0 &&
            self.timeForDonationPopup >= [UserData instance].donationTime) {
            [self showAskForDonation];
        }
    }
}

- (void)solveGame {
    if ([UserData instance].inPlay) {
        [UserData instance].inPlay = NO;
        [self.hud.shuffleButton setTitle:NSLocalizedString(@"Shuffle", @"") forState:UIControlStateNormal];
    }
    if (self.inShuffle) {
        self.inShuffle = NO;
    }
    if (self.inSolve) {
        self.inSolve = NO;
        return;
    }
    self.inSolve = YES;
    [self.hud.solveButton setTitle:NSLocalizedString(@"Stop", @"") forState:UIControlStateNormal];
    self.scene.controlDisabled = YES;
    self.hud.shuffleButton.enabled = NO;
    [self.scene rotateToFront:^{
        if (![self.scene checkSolved]) {
            [self.scene initSolve];
            [self solveGameTurn];
        } else {
            self.inSolve = NO;
            self.scene.controlDisabled = NO;
            self.hud.shuffleButton.enabled = YES;
            [self.hud.solveButton setTitle:NSLocalizedString(@"Solve", @"") forState:UIControlStateNormal];
        }
    }];
}

- (void)solveGameTurn {
    if (!self.inSolve) {
        self.scene.controlDisabled = NO;
        self.hud.shuffleButton.enabled = YES;
        [self.hud.solveButton setTitle:NSLocalizedString(@"Solve", @"") forState:UIControlStateNormal];
        return;
    }
    [self.scene solveNextPanel:^(int panel, BOOL turn, BOOL done) {
        if (!done) {
            if (turn) {
                [self.scene moveSlidersToInitialState:^{
                    self.scene.controlDisabledAll = YES;
                    [self.scene rotateToMiddle:^{
                        [self.scene setSolvedBack];
                        [self.scene rotateToBack:^{
                            self.scene.controlDisabledAll = NO;
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
                                [self solveGameTurn];
                            });
                        }];
                    }];
                }];
            } else {
                [self solveGameTurn];
            }
        } else {
            [self.scene moveSlidersToInitialState:^{
                self.scene.controlDisabledAll = YES;
                [self.scene rotateToMiddle:^{
                    [self.scene setSolvedFront];
                    [self.scene rotateToFront:^{
                        self.scene.controlDisabledAll = NO;
                        self.inSolve = NO;
                        self.scene.controlDisabled = NO;
                        self.hud.shuffleButton.enabled = YES;
                        [self.hud.solveButton setTitle:NSLocalizedString(@"Solve", @"") forState:UIControlStateNormal];
                    }];
                }];
            }];
        }
    }];
}

- (UIView *)getFadeCover:(void (^)())complete fadeOut:(BOOL)fadeOut {
    UIView *coverView = [[UIView alloc] initWithFrame:self.view.bounds];
    coverView.alpha = fadeOut ? 1.0 : 0.0;
    coverView.backgroundColor = [UIColor blackColor];
    int waitTime = fadeOut ? 2.0 : 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, waitTime * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        [UIView animateWithDuration:1.0 animations:^{
            coverView.alpha = fadeOut ? 0.0 : 1.0;
        } completion:^(BOOL finished) {
            [coverView removeFromSuperview];
            if (complete) {
                complete();
            }
        }];
    });
    return coverView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)uiOrientation duration:(NSTimeInterval)duration {
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	switch (orientation) {
		case UIDeviceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
		case UIDeviceOrientationLandscapeLeft:
		case UIDeviceOrientationLandscapeRight:
			self.ccOrientation = (ccDeviceOrientation)orientation;
			break;
		default:
			return;
	}
    [UIView animateWithDuration:0.5 animations:^{
        switch (self.ccOrientation) {
            case UIDeviceOrientationPortrait:
                self.view.transform = CGAffineTransformIdentity;
                self.hud.view.transform = CGAffineTransformIdentity;
                self.hud.topBar.frame = CGRectMake(self.widthHeightDelta, self.hudTopBarOffset, self.normalWidth, self.hud.topBar.frame.size.height);
                self.hud.bottomBar.frame = CGRectMake(self.widthHeightDelta, self.view.bounds.size.height - self.hud.bottomBar.frame.size.height, self.normalWidth, self.hud.bottomBar.frame.size.height);
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                self.view.transform = CGAffineTransformMakeRotation(degreesToRadian(180));
                self.hud.view.transform = CGAffineTransformMakeRotation(degreesToRadian(180));
                self.hud.topBar.frame = CGRectMake(self.widthHeightDelta, self.hudTopBarOffset, self.normalWidth, self.hud.topBar.frame.size.height);
                self.hud.bottomBar.frame = CGRectMake(self.widthHeightDelta, self.view.bounds.size.height - self.hud.bottomBar.frame.size.height, self.normalWidth, self.hud.bottomBar.frame.size.height);
                break;
            case UIDeviceOrientationLandscapeLeft:
                self.view.transform = CGAffineTransformMakeRotation(degreesToRadian(90));
                self.hud.view.transform = CGAffineTransformMakeRotation(degreesToRadian(90));
                self.hud.topBar.frame = CGRectMake(0, self.widthHeightDelta + self.hudTopBarOffset, self.view.frame.size.height, self.hud.topBar.frame.size.height);
                self.hud.bottomBar.frame = CGRectMake(0, self.view.bounds.size.height - self.hud.bottomBar.frame.size.height - self.widthHeightDelta, self.view.frame.size.height, self.hud.bottomBar.frame.size.height);
                break;
            case UIDeviceOrientationLandscapeRight:
                self.view.transform = CGAffineTransformMakeRotation(degreesToRadian(-90));
                self.hud.view.transform = CGAffineTransformMakeRotation(degreesToRadian(-90));
                self.hud.topBar.frame = CGRectMake(0, self.widthHeightDelta + self.hudTopBarOffset, self.view.frame.size.height, self.hud.topBar.frame.size.height);
                self.hud.bottomBar.frame = CGRectMake(0, self.view.bounds.size.height - self.hud.bottomBar.frame.size.height - self.widthHeightDelta, self.view.frame.size.height, self.hud.bottomBar.frame.size.height);
                break;
        }
    }];
    [self adjustCameraZoom];
}

- (BOOL)isOverlayingBackground {
    return isOverlayingBackground;
}

- (void)setIsOverlayingBackground:(BOOL)aBool {
	if (aBool != self.isOverlayingBackground) {
        BOOL nodeRunning = controlledNode_.isRunning;
        if (nodeRunning) [controlledNode_ onExit];
        isOverlayingBackground = aBool;
        if(aBool) {
            [self.parentViewController presentViewController:self.background animated:NO completion:nil];
        } else {
            [self dismissViewControllerAnimated: NO completion:nil];
        }
        if (nodeRunning) [controlledNode_ onEnter];
	}
}

- (BackgroundViewController *)background {
	if (!background) background = [self newBackground];
	return background;
}

- (BackgroundViewController *)newBackground {
    BackgroundViewController *backgroundVC = [BackgroundViewController new];
    backgroundVC.view.frame = self.view.superview.bounds;
    backgroundVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    backgroundVC.view.alpha = 1.0;
    self.view.alpha = 0.5;
    [backgroundVC.view addSubview:self.view];
    [backgroundVC.view addSubview:self.hud.view];
    return backgroundVC;
}

- (void)setIsOverlayingDeviceCamera:(BOOL)aBool {
	if (aBool != self.isOverlayingDeviceCamera) {
		if (!aBool || self.isDeviceCameraAvailable) {
			BOOL nodeRunning = controlledNode_.isRunning;
			if (nodeRunning) [controlledNode_ onExit];
			[self willChangeIsOverlayingDeviceCamera];
			isOverlayingDeviceCamera = aBool;
			if(aBool) {
				[self.parentViewController presentViewController:self.picker animated:NO completion:nil];
                /*[self removeFromParentViewController];
                 [self.picker addChildViewController:self];
                 [self didMoveToParentViewController:self.picker];*/
			} else {
				[self dismissViewControllerAnimated: NO completion:nil];
                /*[self removeFromParentViewController];
                 [[AppDelegate instance].rootViewController addChildViewController:self];
                 [self didMoveToParentViewController:[AppDelegate instance].rootViewController];*/
			}
			[self didChangeIsOverlayingDeviceCamera];
			if (nodeRunning) [controlledNode_ onEnter];
		}
	}
}

- (UIImagePickerController *)newDeviceCameraPicker {
	UIImagePickerController *newPicker = nil;
	if (self.isDeviceCameraAvailable) {
		newPicker = [AugumentedReality new];
		newPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
		newPicker.delegate = nil;
        
        //Add view as sub-view to prevent camera zooming
        [newPicker.view addSubview:self.view];
        //Add HUD not as child but as sibling to prevent flickering during rotation
        [newPicker.view addSubview:self.hud.view];
        
        //Adding empty camera overlay to prevent green focus square
        newPicker.cameraOverlayView = [[UIView alloc] initWithFrame:self.view.bounds];
        
		// Hide the camera and navigation controls, force full screen,
		// and scale the device camera image to cover the full screen
		newPicker.showsCameraControls = NO;
		newPicker.navigationBarHidden = YES;
		newPicker.toolbarHidden = YES;
		newPicker.wantsFullScreenLayout = YES;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat toolbarHeight = kDeviceCameraToolbarHeightIPhone4;
        if (IS_IPHONE_5) {
            toolbarHeight = kDeviceCameraToolbarHeightIPhone5;
        } else if (IS_IPHONE_6) {
            toolbarHeight = kDeviceCameraToolbarHeightIPhone6;
        } else if (IS_IPHONE_6P) {
            toolbarHeight = kDeviceCameraToolbarHeightIPhone6p;
        }
		CGFloat deviceCameraScaleup = screenHeight / (screenHeight - (toolbarHeight * [[UIScreen mainScreen] scale]));
		newPicker.cameraViewTransform = CGAffineTransformScale(newPicker.cameraViewTransform, deviceCameraScaleup, deviceCameraScaleup);
    }
	return newPicker;
}

- (void)cameraIsReadyNotification:(NSNotification *)notification {
    [self adjustCameraZoom];
}

- (void)adjustCameraZoom {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat toolbarHeight = kDeviceCameraToolbarHeightIPhone4;
        if (IS_IPHONE_5) {
            toolbarHeight = kDeviceCameraToolbarHeightIPhone5;
        } else if (IS_IPHONE_6) {
            toolbarHeight = kDeviceCameraToolbarHeightIPhone6;
        } else if (IS_IPHONE_6P) {
            toolbarHeight = kDeviceCameraToolbarHeightIPhone6p;
        }
        CGFloat deviceCameraScaleup = screenHeight / (screenHeight - (toolbarHeight * [[UIScreen mainScreen] scale]));
        self.picker.cameraViewTransform = CGAffineTransformScale(self.picker.cameraViewTransform, deviceCameraScaleup, deviceCameraScaleup);
    });
}

+ (GameViewController *)instance {
    static GameViewController *instance = nil;
    
    @synchronized(self) {
        if (!instance) {
            instance = [GameViewController new];
        }
        return instance;
    }
}

@end
