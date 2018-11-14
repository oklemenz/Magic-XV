//
//  HUDViewController.h
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GameViewController;

@interface HUDViewController : UIViewController

@property (nonatomic, strong) GameViewController *delegate;

@property (strong, nonatomic) IBOutlet UIView *topBar;
@property (strong, nonatomic) IBOutlet UIView *bottomBar;

@property (strong, nonatomic) IBOutlet UIButton *shuffleButton;
@property (strong, nonatomic) IBOutlet UIButton *cameraButton;
@property (strong, nonatomic) IBOutlet UIButton *solveButton;
@property (strong, nonatomic) IBOutlet UIButton *gyroButton;
@property (strong, nonatomic) IBOutlet UIButton *gameCenterButton;
@property (strong, nonatomic) IBOutlet UIButton *soundButton;

- (IBAction)cameraTapped:(id)sender;
- (IBAction)shuffleTapped:(id)sender;
- (IBAction)solveTapped:(id)sender;
- (IBAction)gyroTapped:(id)sender;
- (IBAction)gameCenterTapped:(id)sender;
- (IBAction)soundTapped:(id)sender;

@end
