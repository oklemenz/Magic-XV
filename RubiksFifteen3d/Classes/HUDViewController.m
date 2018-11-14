//
//  HUDViewController.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#import "HUDViewController.h"
#import "GameViewController.h"
#import "SoundManager.h"

@interface HUDViewController ()

@end

@implementation HUDViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage *buttonImage = [[UIImage imageNamed:@"round_button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(17, 17, 17, 17)];
    UIImage *buttonImageSel = [[UIImage imageNamed:@"round_button_sel.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(17, 17, 17, 17)];
    UIImage *buttonImageDisabled = [[UIImage imageNamed:@"round_button_disabled.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(17, 17, 17, 17)];

    [self.shuffleButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.shuffleButton setBackgroundImage:buttonImageSel forState:UIControlStateHighlighted];
    [self.shuffleButton setTitle:NSLocalizedString(@"Shuffle", @"") forState:UIControlStateNormal];

    [self.gameCenterButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.gameCenterButton setBackgroundImage:buttonImageSel forState:UIControlStateHighlighted];
    [self.gameCenterButton setBackgroundImage:buttonImageDisabled forState:UIControlStateDisabled];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.gameCenterButton setTitle:NSLocalizedString(@"Game Center", @"") forState:UIControlStateNormal];
    } else {
        [self.gameCenterButton setTitle:NSLocalizedString(@"GC", @"") forState:UIControlStateNormal];
    }
    
    [self.solveButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.solveButton setBackgroundImage:buttonImageSel forState:UIControlStateHighlighted];
    [self.solveButton setTitle:NSLocalizedString(@"Solve", @"") forState:UIControlStateNormal];
    
    [self.gyroButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.gyroButton setBackgroundImage:buttonImageSel forState:UIControlStateHighlighted];
    [self.gyroButton setBackgroundImage:buttonImageDisabled forState:UIControlStateDisabled];
    [self.gyroButton setTitle:NSLocalizedString(@"Gyro", @"") forState:UIControlStateNormal];

    [self.soundButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.soundButton setBackgroundImage:buttonImageSel forState:UIControlStateHighlighted];
    [self.soundButton setBackgroundImage:buttonImageDisabled forState:UIControlStateDisabled];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.soundButton setTitle:NSLocalizedString(@"Sound", @"") forState:UIControlStateNormal];
    } else {
        [self.soundButton setTitle:NSLocalizedString(@"FX", @"") forState:UIControlStateNormal];
    }
    
    [self.cameraButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.cameraButton setBackgroundImage:buttonImageSel forState:UIControlStateHighlighted];
    [self.cameraButton setBackgroundImage:buttonImageDisabled forState:UIControlStateDisabled];
    [self.cameraButton setTitle:NSLocalizedString(@"Camera", @"") forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [self setTopBar:nil];
    [self setShuffleButton:nil];
    [self setSolveButton:nil];
    [self setCameraButton:nil];
    [self setGyroButton:nil];
    [self setGameCenterButton:nil];
    [self setBottomBar:nil];
    [self setGyroButton:nil];
    [self setSoundButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (IBAction)cameraTapped:(id)sender {
    [[SoundManager instance] playHUDButtonSound];
    [self.delegate toggleCamera:YES];
}

- (IBAction)shuffleTapped:(id)sender {
    [[SoundManager instance] playHUDButtonSound];
    [self.delegate shuffleGame];
}

- (IBAction)solveTapped:(id)sender {
    [[SoundManager instance] playHUDButtonSound];
    [self.delegate solveGame];
}

- (IBAction)gyroTapped:(id)sender {
    [[SoundManager instance] playHUDButtonSound];
    [self.delegate toggleGyro];
}

- (IBAction)gameCenterTapped:(id)sender {
    [[SoundManager instance] playHUDButtonSound];
    [self.delegate showGameCenter];
}

- (IBAction)soundTapped:(id)sender {
    [[SoundManager instance] playHUDButtonSound];
    [self.delegate toggleSound];
}
@end
