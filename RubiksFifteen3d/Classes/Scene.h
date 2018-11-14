//
//  Scene.h
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 24.02.133.
//  Copyright 2013. All rights reserved.
//

#import "CC3Scene.h"
#import <CoreMotion/CoreMotion.h>

#define kInitialFrontRotation  cc3v(60, 25, 10) // cc3v(90,    0,  0)
#define kInitialMiddleRotation cc3v(67.3, -45.3, 43.9)
#define kInitialBackRotation   cc3v(75, -120,  80) // cc3v(90, -180,  0)

#define kInitialCameraLocation1 cc3v(0.0, 0.0, 24.0)
#define kInitialCameraLocation2 cc3v(0.0, 0.0, 20.0)

@protocol SceneDelegate <NSObject>

- (void)updateTimer:(ccTime)delta;
- (void)gameSolved;
- (void)backSolved;
- (ccDeviceOrientation)ccOrientation;

@end

@interface Scene : CC3Scene {
}

@property(nonatomic) id<SceneDelegate> delegate;
@property(getter = isControlDisabled) BOOL controlDisabled;
@property(getter = isControlDisabledAll) BOOL controlDisabledAll;
@property(nonatomic) BOOL multipleTouches;

- (void)setup;

- (void)rotateToFront;
- (void)rotateToFront:(void (^)())handler;
- (void)rotateToMiddle;
- (void)rotateToMiddle:(void (^)())handler;
- (void)rotateToBack;
- (void)rotateToBack:(void (^)())handler;

- (void)moveSlider:(int)sliderIndex complete:(void (^)())handler;
- (void)moveSliders:(int)sliderMask complete:(void (^)())handler;
- (void)moveSlidersToInitialState:(void (^)())handler;
- (void)moveSlidersToState:(int)sliderMask complete:(void (^)())handler;

- (void)initSolve;
- (void)solveNextPanel:(void (^)(int panel, BOOL turn, BOOL done))handler;

- (void)initShuffle;
- (void)shuffleNextPanel:(void (^)(int panel, BOOL turn, BOOL done))handler;

- (void)touchEnded;
- (void)startZoomCamera;
- (void)zoomCameraBy:(CGFloat)aMovement;
- (void)stopZoomCamera;
- (void)rotateZ:(CGFloat)degree andVelocity:(CGFloat)velocity;
- (void)spinRotateZ;

- (void)toggleGyro:(BOOL)state;
- (void)initializeTouchPoint:(CGPoint)touchPoint;

- (BOOL)checkSolved;
- (void)setSolvedFront;
- (void)setSolvedBack;

- (BOOL)multiplePicked;

@end
