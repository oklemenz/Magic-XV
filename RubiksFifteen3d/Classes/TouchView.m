//
//  TouchView.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#import "TouchView.h"
#import "Layer.h"

@implementation TouchView

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setMultipleTouchEnabled:YES];
    
    UIPinchGestureRecognizer *zoomCameraGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomCamera:)];
    zoomCameraGesture.delegate = self;
    [self addGestureRecognizer:zoomCameraGesture];
    
    UIRotationGestureRecognizer *rotateNodeGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateNode:)];
    rotateNodeGesture.delegate = self;
    [self addGestureRecognizer:rotateNodeGesture];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.cc3Layer.touchCount = (int)[event allTouches].count;
    if ([event allTouches].count == 1) {
        [self.touchView touchesBegan:touches withEvent:event];
    } else {
        [self.cc3Layer moveMultiple:[event allTouches]];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    self.cc3Layer.touchCount = (int)[event allTouches].count;
    if ([event allTouches].count == 1) {
        [self.touchView touchesMoved:touches withEvent:event];
    } else {
        [self.cc3Layer moveMultiple:[event allTouches]];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.cc3Layer.touchCount = (int)[event allTouches].count;
    if ([event allTouches].count == 1) {
        [self.touchView touchesEnded:touches withEvent:event];
    } else {
        [self.cc3Layer moveMultiple:[event allTouches]];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.cc3Layer.touchCount = (int)[event allTouches].count;
    if ([event allTouches].count == 1) {
        [self.touchView touchesCancelled:touches withEvent:event];
    } else {
        [self.cc3Layer moveMultiple:[event allTouches]];
    }
}

- (void)zoomCamera:(UIPinchGestureRecognizer *)gesture {
    [self.cc3Layer zoomCamera:gesture];
}

- (void)rotateNode:(UIRotationGestureRecognizer *)gesture {
    [self.cc3Layer rotateNode:gesture];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
