//
//  Layer.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 24.02.13.
//  Copyright 2013. All rights reserved.
//

#import "Layer.h"
#import "Scene.h"

@interface CC3Layer (TemplateMethods)

- (BOOL)handleTouch:(UITouch*)touch ofType:(uint)touchType;

@end

@implementation Layer

- (void)initializeControls {
    self.isTouchEnabled = YES;
}

#pragma mark Updating layer

- (void)onOpenCC3Layer {
}

- (void)onCloseCC3Layer {
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
	[self handleTouch:touch ofType:kCCTouchMoved];
}

- (void)update:(ccTime)dt {
    [super update:dt];
}

- (void)zoomCamera:(UIPinchGestureRecognizer *)gesture {
    if (self.touchCount != 2 || ((Scene *)self.cc3Scene).multipleTouches) {
        return;
    }
	switch (gesture.state) {
		case UIGestureRecognizerStateBegan:
            self.zoomStart = YES;
            [(Scene *)self.cc3Scene touchEnded];
            [(Scene *)self.cc3Scene startZoomCamera];
			break;
		case UIGestureRecognizerStateChanged:
            if (self.zoomStart && gesture.scale != 0) {
                [(Scene *)self.cc3Scene zoomCameraBy:gesture.scale];
            }
			break;
		case UIGestureRecognizerStateEnded:
            self.zoomStart = NO;
			[(Scene *)self.cc3Scene stopZoomCamera];
			break;
		default:
			break;
	}
}

- (void)rotateNode:(UIRotationGestureRecognizer *)gesture {
    if (self.touchCount != 2 || ((Scene *)self.cc3Scene).multipleTouches) {
        return;
    }
    CGFloat degree = gesture.rotation * (180 / M_PI);
	switch (gesture.state) {
		case UIGestureRecognizerStateBegan:
            [(Scene *)self.cc3Scene touchEnded];
			break;
		case UIGestureRecognizerStateChanged:
            [(Scene *)self.cc3Scene rotateZ:degree andVelocity:gesture.velocity];
            gesture.rotation = 0;
			break;
		case UIGestureRecognizerStateEnded:
			[(Scene *)self.cc3Scene spinRotateZ];
			break;
		default:
			break;
	}    
}

- (void)moveMultiple:(NSSet *)touches {
    Scene *scene = (Scene *)self.cc3Scene;
    if (self.touchCount != 3 && !scene.multipleTouches) {
        return;
    }
    int type = 0;
    if (self.touchCount != 3 || (self.multiTouchLead && ![touches containsObject:self.multiTouchLead])) {
        type = kCCTouchEnded;
    } else {
        for (UITouch *touch in touches) {
            if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
                type = kCCTouchEnded;
                break;
            }
        }
    }
    if (type != kCCTouchEnded) {
        scene.multipleTouches = YES;
    }
    if (scene.multiplePicked) {
        if (type != kCCTouchEnded) {
            type = kCCTouchMoved;
        }
        for (UITouch *touch in touches) {
            if (!self.multiTouchLead) {
                self.multiTouchLead = touch;
                [scene initializeTouchPoint:[self convertTouchToNodeSpace:touch]];
            }
            [self handleTouch:self.multiTouchLead ofType:type];
            break;
        }
    } else if (type != kCCTouchMoved) {
        for (UITouch *touch in touches) {
            [self handleTouch:touch ofType:type];
        }
    }
    if (type == kCCTouchEnded) {
        self.multiTouchLead = nil;
        scene.multipleTouches = NO;
    }
}

@end