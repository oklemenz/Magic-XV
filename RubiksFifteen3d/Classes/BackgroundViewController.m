//
//  BackgroundViewController.m
//  RubiksFifteen3d
//
//  Created by Klemenz, Oliver on 05.12.12.
//
//

#import "BackgroundViewController.h"

@interface BackgroundViewController ()

@end

@implementation BackgroundViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.jpg"]];
        self.view.contentMode = UIViewContentModeScaleAspectFill;
        self.view.frame = self.view.bounds;
    }
    return self;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) uiOrientation {
    return NO;
}

- (void)willRotateToInterfaceOrientation: (UIInterfaceOrientation) uiOrientation duration:(NSTimeInterval)duration {
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
