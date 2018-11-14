//
//  Layer.h
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 24.02.13.
//  Copyright 2013. All rights reserved.
//

#import "CC3Layer.h"

@interface Layer : CC3Layer {
}

@property (nonatomic) BOOL zoomStart;
@property (nonatomic) int touchCount;
@property (nonatomic, retain) UITouch *multiTouchLead;

- (void)zoomCamera:(UIPinchGestureRecognizer *)gesture;
- (void)rotateNode:(UIRotationGestureRecognizer *)gesture;
- (void)moveMultiple:(NSSet *)touches;

@end
