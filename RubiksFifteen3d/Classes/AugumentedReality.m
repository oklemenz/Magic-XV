//
//  AugumentedReality.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#import "AugumentedReality.h"

@interface AugumentedReality ()

@end

@implementation AugumentedReality

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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


@end
