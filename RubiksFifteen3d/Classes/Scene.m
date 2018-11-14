//
//  Scene.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 24.02.13.
//  Copyright 2013. All rights reserved.
//

#import "Scene.h"
#import "cocos2d.h"
#import "CC3PODResourceNode.h"
#import "CC3ActionInterval.h"
#import "CC3MeshNode.h"
#import "CC3Camera.h"
#import "CC3Light.h"
#import "CC3ShadowVolumes.h"

#import "CCTouchDispatcher.h"
#import "CGPointExtension.h"

#import "AppDelegate.h"
#import "UserData.h"
#import "SoundManager.h"

#define kCameraZoomFactor 20.0
#define kCameraMinLocation 6.2
#define kCameraMaxLocation 200

#define kSliderSwipeFactor 0.01
#define kRotateSwipeFactor 0.6

#define kSpinFrictionFactor 1.0
#define kSpinMinSpeed 6.0
#define kSpinMaxSpeed 500.0

#define kSlideDirectionCW  0
#define kSlideDirectionCCW 1

#define kSliderLeftOffset   0.0
#define kSliderRightOffset  1.625
#define kSliderTopOffset    0.0
#define kSliderBottomOffset 1.625

#define kPanelLeftOffset   -2.4375
#define kPanelUpOffset     -3.25
#define kPanelDelta         1.625

#define kRotationSpeed  0.8
#define kAnimationSpeed 0.1

#define kRotationDistance 10

#define degrees(x) (180 * x / M_PI)
#define random(min, max) (arc4random() % (max - min)) + min

typedef enum FlickMode : NSUInteger {
    kFlickInitial = 0,
    kFlickBegan   = 1,
    kFlickMove    = 2,
    kFlickEnd     = 3
} FlickMode;

typedef NS_OPTIONS(NSUInteger, FifteenSliderIndex) {
    FifteenSliderIndexHorizontalTop    = 0,
    FifteenSliderIndexHorizontalMiddle = 1,
    FifteenSliderIndexHorizontalBottom = 2,
    FifteenSliderIndexVerticalLeft     = 3,
    FifteenSliderIndexVerticalMiddle   = 4,
    FifteenSliderIndexVerticalRight    = 5
};

typedef NS_OPTIONS(NSUInteger, FifteenSliderMaskHorizontal) {
    FifteenSliderMaskHorizontalTop          = (1 << 0), // 1
    FifteenSliderMaskHorizontalMiddle       = (1 << 1), // 2
    FifteenSliderMaskHorizontalBottom       = (1 << 2), // 4
    FifteenSliderMaskHorizontalNone         = 0, // 0
    FifteenSliderMaskHorizontalAll          = FifteenSliderMaskHorizontalTop | FifteenSliderMaskHorizontalMiddle | FifteenSliderMaskHorizontalBottom, // 7
    FifteenSliderMaskHorizontalTopMiddle    = FifteenSliderMaskHorizontalTop | FifteenSliderMaskHorizontalMiddle, // 3
    FifteenSliderMaskHorizontalMiddleBottom = FifteenSliderMaskHorizontalMiddle | FifteenSliderMaskHorizontalBottom, // 6
    FifteenSliderMaskHorizontalTopBottom    = FifteenSliderMaskHorizontalTop | FifteenSliderMaskHorizontalBottom, // 5
};

typedef NS_OPTIONS(NSUInteger, FifteenSliderMaskVertical) {
    FifteenSliderMaskVerticalLeft           = (1 << 3), // 8
    FifteenSliderMaskVerticalMiddle         = (1 << 4), // 16
    FifteenSliderMaskVerticalRight          = (1 << 5), // 32
    FifteenSliderMaskVerticalNone           = 0, // 0
    FifteenSliderMaskVerticalAll            = FifteenSliderMaskVerticalLeft | FifteenSliderMaskVerticalMiddle | FifteenSliderMaskVerticalRight, // 28
    FifteenSliderMaskVerticalLeftMiddle     = FifteenSliderMaskVerticalLeft | FifteenSliderMaskVerticalMiddle, // 12
    FifteenSliderMaskVerticalMiddleRight    = FifteenSliderMaskVerticalMiddle | FifteenSliderMaskVerticalRight, // 24
    FifteenSliderMaskVerticalLeftRight      = FifteenSliderMaskVerticalLeft | FifteenSliderMaskVerticalRight, // 20
};

@interface CC3Node (CustomData)
@property int nodeIndex;
@property(getter = isSliderOut) BOOL sliderOut;
-(BOOL)isHorizontal;
@end

@interface Scene () {
}

@property(nonatomic, strong) CC3Node *mainNode;
@property(nonatomic, strong) CC3Node *spinNode;
@property(nonatomic, strong) CC3Node *pickedNode;
@property(nonatomic, strong) CC3Node *pickedSlider;
@property(nonatomic, strong) CC3Node *panelsNode;

@property(nonatomic) BOOL pickedSliderAssignment;
@property(nonatomic) BOOL pickedSliderMoving;

@property(nonatomic, strong) NSMutableArray *panels;

@property(nonatomic, strong) NSMutableArray *sliders;
@property(nonatomic, strong) NSMutableArray *sliderEnds;
@property(nonatomic, strong) NSMutableArray *sliderPanels;

@property(nonatomic) int horizontalSlidersInMove;
@property(nonatomic) int verticalSlidersInMove;

@property(nonatomic) CC3Vector pickedSliderPreviousLocation;

@property(nonatomic, strong) NSMutableArray *frames;

@property(nonatomic, strong) NSArray *panelPosMoveMatrix;
@property(nonatomic, strong) NSArray *solveMatrix;

@property CGPoint lastTouchEventPoint;
@property struct timeval lastTouchEventTime;
@property CC3Vector spinAxis;
@property GLfloat spinSpeed;
@property CC3Vector cameraMoveStartLocation;
@property FlickMode flickMode;

@property(nonatomic, strong) CMAttitude *referenceAttitude;
@property int referenceAttitudeCount;

@property(nonatomic, copy) void (^fifteenRotateCompletionHandler)();
@property(nonatomic, copy) void (^sliderMoveCompletionHandler)();

@property(getter = isInFifteenRotate) BOOL inFifteenRotate;
@property(getter = isInSliderMove) BOOL inSliderMove;

@property int sliderMoveCount;

@property int shuffleTurnCount;
@property int shuffleTurnIndex;
@property int solveTurnCount;
@property int solveTurnIndex;

@property BOOL faceFront;

@end

@implementation Scene

- (void)initializeScene {
	CC3Camera* cam = [CC3Camera nodeWithName:@"Camera"];
    cam.location = [UserData instance].location;
	[self addChild:cam];
    cam.nearClippingDistance = 0.1;

	CC3Light* lamp = [CC3Light nodeWithName:@"Lamp"];
	lamp.location = cc3v(20.0, 20, 100.0);
	lamp.isDirectionalOnly = NO ;
	[cam addChild:lamp];

	[self addContentFromPODFile:@"rubiksFifteen.pod"];
	[self createGLBuffers];
	[self releaseRedundantData];
    
    self.ambientLight = kCCC4FBlackTransparent;
    
    self.mainNode.isTouchEnabled = YES;
    self.mainNode.rotation = kInitialFrontRotation;

    CGFloat gray = 50;
    CC3MeshNode *topFrame = (CC3MeshNode *)[self getNodeNamed: @"GridTopFrame"];
    topFrame.material.diffuseColor = ccc4FFromccc4B(ccc4(gray, gray, gray, 255));
    topFrame.material.ambientColor = topFrame.material.diffuseColor;
    /*CC3MeshNode *bottomFrame = (CC3MeshNode *)[self getNodeNamed: @"GridBottomFrame"];
    bottomFrame.material.diffuseColor = ccc4FFromccc4B(ccc4(gray, gray, gray, 255));
    bottomFrame.material.ambientColor = topFrame.material.diffuseColor;
    [[[[bottomFrame children] objectAtIndex:1] material] texture]
    [[[[bottomFrame children] objectAtIndex:1] material] diffuseColor]
    [[[[bottomFrame children] objectAtIndex:1] material] ambientColor]*/
    
    self.sliders = [NSMutableArray new];
    self.sliderEnds = [NSMutableArray new];
    self.sliderPanels = [NSMutableArray new];
    for (int i = 0; i < 6; i++) {
        CC3Node *slider = [self.mainNode getNodeNamed:[NSString stringWithFormat:@"Slider%i", i+1]];
        slider.nodeIndex = i;
        if (i < 3) {
            slider.location = cc3v(kSliderLeftOffset, slider.location.y, slider.location.z);
        } else {
            slider.location = cc3v(slider.location.x, slider.location.y, kSliderTopOffset);
        }
        [self.sliders addObject:slider];

        CC3Node *sliderEnd1 = [self.mainNode getNodeNamed:[NSString stringWithFormat:@"Slider%iEnd1", i+1]];
        sliderEnd1.isTouchEnabled = YES;
        sliderEnd1.nodeIndex = i;
        sliderEnd1.sliderOut = YES;
        [self.sliderEnds addObject:sliderEnd1];
        CC3MeshNode *sliderEnd1Touch = (CC3MeshNode *)[self.mainNode getNodeNamed:[NSString stringWithFormat:@"Slider%iEnd1Touch", i+1]];
        sliderEnd1Touch.shouldAllowTouchableWhenInvisible = YES;
        sliderEnd1Touch.shouldCastShadowsWhenInvisible = NO;
        sliderEnd1Touch.ambientColor = kCCC4FBlackTransparent;
        sliderEnd1Touch.visible = NO;
        sliderEnd1Touch.material = nil;

        CC3Node *sliderEnd2 = [self.mainNode getNodeNamed:[NSString stringWithFormat:@"Slider%iEnd2", i+1]];
        sliderEnd2.isTouchEnabled = YES;
        sliderEnd2.nodeIndex = i;
        sliderEnd2.sliderOut = NO;
        [self.sliderEnds addObject:sliderEnd2];
        CC3MeshNode *sliderEnd2Touch = (CC3MeshNode *)[self.mainNode getNodeNamed:[NSString stringWithFormat:@"Slider%iEnd2Touch", i+1]];
        sliderEnd2Touch.shouldAllowTouchableWhenInvisible = YES;
        sliderEnd2Touch.shouldCastShadowsWhenInvisible = NO;
        sliderEnd2Touch.ambientColor = kCCC4FBlackTransparent;
        sliderEnd2Touch.visible = NO;
        sliderEnd2Touch.material = nil;
        
        CC3Node *sliderPanels = [self.mainNode getNodeNamed:[NSString stringWithFormat:@"Slider%iPanels", i+1]];
        [self.sliderPanels addObject:sliderPanels];
        
        self.panelsNode = [self.mainNode getNodeNamed:@"Panels"];
    }    

    self.horizontalSlidersInMove = 0;
    self.verticalSlidersInMove = 0;
    
    self.panels = [NSMutableArray new];
    for (int i = 0; i < 17; i++) {
        CC3Node *panel = [self.mainNode getNodeNamed:[NSString stringWithFormat:@"Panel%i", i+1]];
        [self.panels addObject:panel];
    }
    
    self.frames = [NSMutableArray new];
    CC3Node *frameTop = [self.mainNode getNodeNamed:@"FrameTop"];
    [self.frames addObject:frameTop];
    CC3Node *frameBottom = [self.mainNode getNodeNamed:@"FrameBottom"];
    [self.frames addObject:frameBottom];

    self.panelPosMoveMatrix = @[ @{ @"min" :  @(0), @"count" :  @(5), @"step" : @(1) },
                                 @{ @"min" :  @(5), @"count" : @(15), @"step" : @(1) },
                                 @{ @"min" : @(20), @"count" :  @(5), @"step" : @(1) },
                                 @{ @"min" :  @(1), @"count" :  @(5), @"step" : @(5) },
                                 @{ @"min" :  @(2), @"count" :  @(5), @"step" : @(5) },
                                 @{ @"min" :  @(3), @"count" :  @(5), @"step" : @(5) } ];
    
    self.solveMatrix = @[];
}

- (CC3Node *)mainNode {
    if (!_mainNode) {
        _mainNode = [self getNodeNamed: @"RubiksFifteen"];
    }
    return _mainNode;
}

- (CC3Node *)panel:(int)index {
    return self.panels[index];
}

- (CC3Node *)slider:(int)index {
    return self.sliders[index];
}

- (void)setup {
    self.mainNode.rotation = [UserData instance].rotation;
    self.activeCamera.location = [UserData instance].location;
    [self setState];
}

- (void)setState {
    [self iterateSliders:^(int si) {
        CC3Node *slider = ((CC3Node *)self.sliders[si]);
        BOOL state = [[UserData instance].sliderPos[si] boolValue];
        if ([slider isHorizontal]) {
            slider.location = cc3v(state ? kSliderLeftOffset : kSliderRightOffset, slider.location.y, slider.location.z);
        } else {
            slider.location = cc3v(slider.location.x, slider.location.y, state ? kSliderTopOffset : kSliderBottomOffset);
        }
    }];
    for (int i = 0; i < [[UserData instance].panelPos count]; i++) {
        int x = i % 5;
        int z = i / 5;
        int pi = [[UserData instance].panelPos[i] intValue];
        if (pi >= 0) {
            CC3Node *panel = self.panels[pi];
            panel.location = cc3v(kPanelLeftOffset + x * kPanelDelta, panel.location.y, kPanelUpOffset + z * kPanelDelta);
        }
    }
}

- (BOOL)multiplePicked {
    return self.pickedSlider && self.multipleTouches;
}

- (void)rotateToFront {
    [self rotateToFront:nil];
}

- (void)rotateToFront:(void (^)())handler {
    self.spinNode = nil;
    self.spinSpeed = 0;
    self.fifteenRotateCompletionHandler = handler;
    self.inFifteenRotate = YES;
    CC3Vector initialCmaeraLocation = !IS_IPHONE_4 ? kInitialCameraLocation1 : kInitialCameraLocation2;
    CCActionInterval *move = [CC3MoveTo actionWithDuration:kRotationSpeed moveTo:initialCmaeraLocation];
    [self.activeCamera runAction:move];
    if (CC3VectorDistance(self.mainNode.rotation, kInitialFrontRotation) > kRotationDistance) {
        CCActionInterval *rotate = [CC3RotateTo actionWithDuration:kRotationSpeed rotateTo:kInitialFrontRotation];
        [self.mainNode runAction:[CCSequence actions:rotate, [CCCallFuncN actionWithTarget:self selector:@selector(rotateFifteenDidEnd:)], nil]];
    } else {
        [self rotateFifteenDidEnd:self.mainNode];
    }
}

- (void)rotateToMiddle {
    [self rotateToMiddle:nil];
}

- (void)rotateToMiddle:(void (^)())handler {
    self.spinNode = nil;
    self.spinSpeed = 0;
    self.fifteenRotateCompletionHandler = handler;
    self.inFifteenRotate = YES;
    CC3Vector initialCmaeraLocation = !IS_IPHONE_4 ? kInitialCameraLocation1 : kInitialCameraLocation2;
    CCActionInterval *move = [CC3MoveTo actionWithDuration:kRotationSpeed moveTo:initialCmaeraLocation];
    [self.activeCamera runAction:move];
    if (CC3VectorDistance(self.mainNode.rotation, kInitialMiddleRotation) > kRotationDistance) {
        CCActionInterval *rotate = [CC3RotateTo actionWithDuration:kRotationSpeed rotateTo:kInitialMiddleRotation];
        [self.mainNode runAction:[CCSequence actions:rotate, [CCCallFuncN actionWithTarget:self selector:@selector(rotateFifteenDidEnd:)], nil]];
    } else {
        [self rotateFifteenDidEnd:self.mainNode];
    }
}

- (void)rotateToBack {
    [self rotateToBack:nil];
}

- (void)rotateToBack:(void (^)())handler {
    self.spinNode = nil;
    self.spinSpeed = 0;
    self.fifteenRotateCompletionHandler = handler;
    self.inFifteenRotate = YES;
    if (CC3VectorDistance(self.mainNode.rotation, kInitialBackRotation) > kRotationDistance) {
        CCActionInterval *rotate = [CC3RotateTo actionWithDuration:kRotationSpeed rotateTo:kInitialBackRotation];
        [self.mainNode runAction:[CCSequence actions:rotate, [CCCallFuncN actionWithTarget:self selector:@selector(rotateFifteenDidEnd:)], nil]];
    } else {
        [self rotateFifteenDidEnd:self.mainNode];
    }
}

- (void)rotateFifteenDidEnd:(CC3Node *)fifteen {
    self.inFifteenRotate = NO;
    if (self.fifteenRotateCompletionHandler) {
        void (^handler)() = self.fifteenRotateCompletionHandler;
        self.fifteenRotateCompletionHandler = nil;
        handler();
    }
}

- (void)startZoomCamera {
    self.cameraMoveStartLocation = self.activeCamera.location;
}

- (void)zoomCameraBy:(CGFloat)aMovement {
    GLfloat camMoveDist = logf(aMovement) * kCameraZoomFactor;
    CC3Vector moveVector = CC3VectorScaleUniform(self.activeCamera.globalForwardDirection, camMoveDist);
    self.activeCamera.location = CC3VectorAdd(self.cameraMoveStartLocation, moveVector);
    if (self.activeCamera.location.z < kCameraMinLocation) {
        self.activeCamera.location = cc3v(0, 0, kCameraMinLocation);
    } else if (activeCamera.location.z > kCameraMaxLocation) {
        self.activeCamera.location = cc3v(0, 0, kCameraMaxLocation);
    }
}

- (void)stopZoomCamera {
}

- (void)rotateZ:(CGFloat)degree andVelocity:(CGFloat)velocity {
    self.spinNode = self.mainNode;
    self.spinAxis = cc3v(0, 0, -velocity);
    self.spinSpeed = velocity * 20 * (velocity > 0 ? 1 : -1);
    [self.spinNode rotateByAngle:-degree aroundAxis:cc3v(0, 0, 1)];
}

- (void)spinRotateZ {
    self.spinNode = self.mainNode;
    self.pickedNode = nil;
}

#pragma mark Updating custom activity

- (void)updateBeforeTransform:(CC3NodeUpdatingVisitor*)visitor {
    [self.delegate updateTimer:visitor.deltaTime];
    if (self.spinNode) {
        GLfloat dt = visitor.deltaTime;
        if (self.spinNode) {
            if (self.spinSpeed > kSpinMinSpeed) {
                GLfloat deltaAngle = self.spinSpeed * dt;
                [self.spinNode rotateByAngle:deltaAngle aroundAxis:self.spinAxis];
                self.spinSpeed -= (deltaAngle * kSpinFrictionFactor);
            } else {
                self.spinNode = nil;
                self.spinSpeed = 0;
            }
        }
    }
    self.faceFront = ((CC3Node *)self.frames[0]).globalLocation.z >= ((CC3Node *)self.frames[1]).globalLocation.z;
    [UserData instance].rotation = self.mainNode.rotation;
    [UserData instance].location = self.activeCamera.location;
}

- (void)updateAfterTransform:(CC3NodeUpdatingVisitor*)visitor {
    CMMotionManager *motionManager = [AppDelegate instance].motionManager;
    if (!motionManager.isDeviceMotionActive || !motionManager.isGyroActive) {
        return;
    }
    
    CMDeviceMotion *deviceMotion = [AppDelegate instance].motionManager.deviceMotion;
    CMAttitude *attitude = deviceMotion.attitude;

    if (!attitude) {
        return;
    }
    
    if (!self.referenceAttitude) {
        self.referenceAttitudeCount++;
        if (self.referenceAttitudeCount >= 5) {
            self.referenceAttitude = attitude;
        }
        return;
    }
    
    CMAttitude *originalAttitude = [attitude copy];
    [attitude multiplyByInverseOfAttitude:self.referenceAttitude];
    self.referenceAttitude = originalAttitude;

    CC3Vector rotation = kCC3VectorZero;
    
    CGFloat degree1 = degrees(attitude.pitch) * 2;
    CGFloat degree2 = degrees(attitude.roll) * 2;
    
    switch ([self.delegate ccOrientation]) {
        case UIDeviceOrientationPortrait:
            rotation = CC3VectorMake(degree1, degree2, 0);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            rotation = CC3VectorMake(-degree1, -degree2, 0);
            break;
        case UIDeviceOrientationLandscapeLeft:
            rotation = CC3VectorMake(-degree2, degree1, 0);
            break;
        case UIDeviceOrientationLandscapeRight:
            rotation = CC3VectorMake(degree2, -degree1, 0);
            break;
        default:
            return;
    }
    
    [self.mainNode rotateBy:rotation];
    /*
    NSLog(@"<- %f", self.mainNode.rotation.z);
    rotation.x += self.mainNode.rotation.x;
    rotation.y += self.mainNode.rotation.y;
    rotation.z += self.mainNode.rotation.z;
    self.mainNode.rotation = rotation;*/
}

- (void)toggleGyro:(BOOL)state {
    CMMotionManager *motionManager = [AppDelegate instance].motionManager;
    if (state) {
        if (!motionManager.isDeviceMotionActive) {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
            [motionManager startDeviceMotionUpdates];
            if (!motionManager.isGyroActive) {
                motionManager.gyroUpdateInterval = 1.0 / 60.0;
                [motionManager startGyroUpdates];
            }
        }
    } else if (motionManager.isDeviceMotionActive) {
        [motionManager stopDeviceMotionUpdates];
        [motionManager stopGyroUpdates];
        self.referenceAttitude = nil;
        self.referenceAttitudeCount = 0;
    }
}

#pragma mark Scene opening and closing

- (void)onOpen {
}

- (void)onClose {
}

#pragma mark Handling touch events

- (void)touchEvent:(uint)touchType at:(CGPoint)touchPoint {
    struct timeval now;
    gettimeofday(&now, NULL);
    ccTime dt = (now.tv_sec - self.lastTouchEventTime.tv_sec) +
                (now.tv_usec - self.lastTouchEventTime.tv_usec) / 1000000.0f;
    BOOL reset = YES;
    switch (touchType) {
        case kCCTouchBegan:
            self.flickMode = kFlickBegan;
            [self pickNodeFromTouchEvent:touchType at:touchPoint];
            break;
        case kCCTouchMoved:
            if (self.flickMode == kFlickBegan) {
                self.flickMode = kFlickMove;
            }
            if (self.pickedNode) {
                reset = [self rotateNodeFromSwipeAt:touchPoint interval:dt];
            } else if (self.pickedSlider) {
                reset = [self moveSliderFromSwipeAt:touchPoint interval:dt];
            }
            break;
        case kCCTouchEnded:
            if (self.flickMode == kFlickMove) {
                self.flickMode = kFlickEnd;
            }
            [self touchEnded];
            break;
        default:
            break;
    }
    if (reset) {
        self.lastTouchEventPoint = touchPoint;
        self.lastTouchEventTime = now;
    }
}

- (void)initializeTouchPoint:(CGPoint)touchPoint {
    self.lastTouchEventPoint = touchPoint;
    struct timeval now;
    gettimeofday(&now, NULL);
    self.lastTouchEventTime = now;
}

- (void)touchEnded {
    if (self.pickedSlider) {
        [self gridSlider:self.pickedSlider];
    }
    if (self.pickedNode) {
        self.spinNode = self.pickedNode;
        self.pickedNode = nil;
    }
}

- (void)nodeSelected:(CC3Node *)aNode byTouchEvent:(uint)touchType at:(CGPoint)touchPoint {
    if (!aNode) {
        return;
    }
    if (!self.controlDisabledAll && [aNode isEqual:self.mainNode] && (self.flickMode == kFlickBegan || self.flickMode == kFlickMove)) {
        self.pickedNode = aNode;
        if (self.pickedNode) {
            self.spinNode = nil;
            self.spinSpeed = 0;
            self.flickMode = kFlickInitial;
        }
    } else if (!self.controlDisabledAll && !self.controlDisabled && !self.pickedSlider) {
        BOOL sliderTouched = NO;
        for (CC3Node *sliderEnd in self.sliderEnds) {
            if ([sliderEnd isEqual:aNode]) {
                sliderTouched = YES;
                if ([[UserData instance].sliderPos[sliderEnd.nodeIndex] boolValue] == sliderEnd.isSliderOut) {
                    self.pickedNode = nil;
                    self.pickedSlider = self.sliders[sliderEnd.nodeIndex];
                    self.pickedSliderAssignment = NO;
                    self.pickedSliderMoving = NO;
                    if (self.flickMode == kFlickEnd) {
                        [self moveSlider:self.pickedSlider];
                        self.pickedSlider = nil;
                    }
                    self.flickMode = kFlickInitial;
                    return;
                }
            }
        }
        if (sliderTouched && (self.flickMode == kFlickBegan || self.flickMode == kFlickMove)) {
            self.pickedNode = self.mainNode;
            if (self.pickedNode) {
                self.spinNode = nil;
                self.spinSpeed = 0;
                self.flickMode = kFlickInitial;
            }
        }
    }
}

- (BOOL)rotateNodeFromSwipeAt:(CGPoint)touchPoint interval:(ccTime)dt {
    if (self.pickedNode && !self.inFifteenRotate) {
        CGPoint swipe2d = ccpSub(touchPoint, self.lastTouchEventPoint);
        CGPoint axis2d = ccpPerp(swipe2d);
        CC3Vector axis = CC3VectorAdd(CC3VectorScaleUniform(self.activeCamera.rightDirection, axis2d.x),
                                      CC3VectorScaleUniform(self.activeCamera.upDirection, axis2d.y));
        GLfloat angle = ccpLength(swipe2d) * kRotateSwipeFactor;
        [self.pickedNode rotateByAngle:angle aroundAxis:axis];
        self.spinAxis = axis;
        CGPoint swipeVelocity = ccpSub(touchPoint, self.lastTouchEventPoint);
        self.spinSpeed = (angle / dt) * ccpLength(swipeVelocity) / 50;
        if (self.spinSpeed > kSpinMaxSpeed) {
            self.spinSpeed = kSpinMaxSpeed;
        }
        self.spinNode = nil;
    }
    return YES;
}

- (BOOL)moveSliderFromSwipeAt:(CGPoint)touchPoint interval:(ccTime)dt {
    if (self.pickedSlider && !self.inFifteenRotate) {
        
        if (![self checkSliderIsMovable:self.pickedSlider]) {
            [[SoundManager instance] playSliderLockedSound];
            self.pickedSlider = nil;
            return NO;
        }
        
        CGPoint swipe2d = ccpSub(touchPoint, self.lastTouchEventPoint);
        CGPoint axis2d = ccpPerp(swipe2d);
        CC3Vector axis = CC3VectorAdd(CC3VectorScaleUniform(self.activeCamera.rightDirection, axis2d.x),
                                      CC3VectorScaleUniform(self.activeCamera.upDirection, axis2d.y));
        axis = [self.mainNode.transformMatrixInverted transformDirection:axis];
        GLfloat angle = ccpLength(swipe2d) * kSliderSwipeFactor;
        CGPoint swipeVelocity = ccpSub(touchPoint, self.lastTouchEventPoint);
        CGFloat swipeSpeed = (angle / dt) * ccpLength(swipeVelocity) / 50;
        CGFloat gradient = [self calcGradient:axis forSlider:self.pickedSlider.nodeIndex] * kSliderSwipeFactor;
        [self moveSlider:self.pickedSlider by:gradient speed:swipeSpeed];
        return YES;
    }
    return NO;
}

- (CGFloat)calcGradient:(CC3Vector)axis forSlider:(int)sliderIndex {
    CGFloat gradient = fabsf(axis.x) > fabsf(axis.z) ? axis.x : axis.z;
    gradient *= (sliderIndex <= 2 && self.faceFront) | (sliderIndex >= 3 && !self.faceFront) ? -1 : 1;
    return gradient;
}

- (BOOL)checkSliderIsMovable:(CC3Node *)slider {
    BOOL state;
    if (slider.nodeIndex == 0) {
        state = YES;
    } else if (slider.nodeIndex == 2) {
        state = NO;
    } else {
        return YES;
    }
    for (int i = 0; i < 3; i++) {
        if ([[UserData instance].sliderPos[3+i] boolValue] != state) {
            return NO;
        }
    }
    return YES;
}

- (void)startPanelSliderAssignment:(CC3Node *)slider {
    CC3Node *sliderPanels = self.sliderPanels[slider.nodeIndex];
    NSDictionary *panelMove = self.panelPosMoveMatrix[slider.nodeIndex];
    int i = [panelMove[@"min"] intValue];
    for (int c = 0; c < [panelMove[@"count"] intValue]; c++) {
        int pi = [[UserData instance].panelPos[i] intValue];
        if (pi >= 0) {
            CC3Node *panel = self.panels[pi];
            CC3Vector newLocation;
            if ([slider isHorizontal]) {
                newLocation = cc3v(panel.location.x - slider.location.x, panel.location.y, panel.location.z);
            } else {
                newLocation = cc3v(panel.location.x, panel.location.y, panel.location.z - slider.location.z);
            }
            panel.location = newLocation;
            [self.panelsNode removeChild:panel];
            [sliderPanels addChild:panel];
        }
        i += [panelMove[@"step"] intValue];
    }
}

- (void)updatePanelSliderAssignment:(CC3Node *)slider direction:(int)direction {
    NSDictionary *panelMove = self.panelPosMoveMatrix[slider.nodeIndex];
    if (direction == 1) {
        int i = [panelMove[@"min"] intValue] + [panelMove[@"step"] intValue] * ([panelMove[@"count"] intValue] - 1);
        for (int c = [panelMove[@"count"] intValue] - 1; c >= 0; c--) {
            int pi = [[UserData instance].panelPos[i] intValue];
            if (pi >= 0) {
                int iNew = i + [panelMove[@"step"] intValue];
                [UserData instance].panelPos[iNew] = @(pi);
                if (c % 5 == 0) {
                    [UserData instance].panelPos[i] = @(-1);
                }
            }
            i -= [panelMove[@"step"] intValue];
        }
    } else if (direction == -1) {
        int i = [panelMove[@"min"] intValue];
        for (int c = 0; c < [panelMove[@"count"] intValue]; c++) {
            int pi = [[UserData instance].panelPos[i] intValue];
            if (pi >= 0) {
                int iNew = i - [panelMove[@"step"] intValue];
                [UserData instance].panelPos[iNew] = @(pi);
                if (c % 5 == 4) {
                    [UserData instance].panelPos[i] = @(-1);
                }
            }
            i += [panelMove[@"step"] intValue];
        }
    }
}

- (void)endPanelSliderAssignment:(CC3Node *)slider {
    CC3Node *sliderPanels = self.sliderPanels[slider.nodeIndex];
    for (CC3Node *panel in [[sliderPanels children] copy]) {
        CC3Vector newLocation;
        if ([slider isHorizontal]) {
            newLocation = cc3v(panel.location.x + slider.location.x, panel.location.y, panel.location.z);
        } else {
            newLocation = cc3v(panel.location.x, panel.location.y, panel.location.z + slider.location.z);
        }
        panel.location = newLocation;
        [sliderPanels removeChild:panel];
        [self.panelsNode addChild:panel];
    }
}

- (void)moveSlider:(CC3Node *)slider by:(CGFloat)gradient speed:(CGFloat)speed {
    NSArray *sliders = @[slider];
    if (self.multipleTouches && ![slider isHorizontal]) {
        sliders = @[self.sliders[3], self.sliders[4], self.sliders[5]];
    }
    
    if (!self.pickedSliderAssignment) {
        for (CC3Node *aSlider in sliders) {
            if ([aSlider isHorizontal]) {
                if (self.verticalSlidersInMove > 0) {
                    return;
                }
                self.horizontalSlidersInMove++;
            } else {
                if (self.horizontalSlidersInMove > 0) {
                    return;
                }
                self.verticalSlidersInMove++;
            }
            [self startPanelSliderAssignment:aSlider];
        }
        self.pickedSliderAssignment = YES;
    }
    
    BOOL sliderMoved = NO;
    
    for (CC3Node *aSlider in sliders) {
        CC3Vector axis = [aSlider isHorizontal] ? cc3v(gradient, 0, 0) : cc3v(0, 0, gradient);
        CC3Vector newLocation = CC3VectorAdd(aSlider.location, axis);
        if ([aSlider isHorizontal]) {
            if (newLocation.x < kSliderLeftOffset) {
                newLocation = cc3v(kSliderLeftOffset, newLocation.y, newLocation.z);
            } else if (newLocation.x > kSliderRightOffset) {
                newLocation = cc3v(kSliderRightOffset, newLocation.y, newLocation.z);
            }
        } else {
            if (newLocation.z < kSliderTopOffset) {
                newLocation = cc3v(newLocation.x, newLocation.y, kSliderTopOffset);
            } else if (newLocation.z > kSliderBottomOffset) {
                newLocation = cc3v(newLocation.x, newLocation.y, kSliderBottomOffset);
            }
        }
        if (aSlider == slider && !CC3VectorsAreEqual(aSlider.location, self.pickedSliderPreviousLocation)) {
            self.pickedSliderPreviousLocation = aSlider.location;
        }
        if (!CC3VectorsAreEqual(aSlider.location, newLocation)) {
            aSlider.location = newLocation;
            sliderMoved = YES;
        }
    }
    
    if (sliderMoved && !self.pickedSliderMoving) {
        [[SoundManager instance] playStartSliderMoveSound];
        self.pickedSliderMoving = YES;
    }
}

- (void)gridSlider:(CC3Node *)slider {
    NSArray *sliders = @[slider];
    if (self.multipleTouches && ![slider isHorizontal]) {
        sliders = @[self.sliders[3], self.sliders[4], self.sliders[5]];
    }

    if (self.pickedSliderMoving) {

        for (CC3Node *aSlider in sliders) {
            BOOL state = [[UserData instance].sliderPos[aSlider.nodeIndex] boolValue];
            BOOL newState = state;
            
            CC3Vector targetLocation;
            if ([aSlider isHorizontal]) {
                //if (aSlider.location.x < (kSliderLeftOffset + kSliderRightOffset) / 2.0f) {
                if (aSlider.location.x < self.pickedSliderPreviousLocation.x || aSlider.location.x == kSliderLeftOffset) {
                    targetLocation = cc3v(kSliderLeftOffset, aSlider.location.y, aSlider.location.z);
                    newState = YES;
                } else {
                    targetLocation = cc3v(kSliderRightOffset, aSlider.location.y, aSlider.location.z);
                    newState = NO;
                }
            } else {
                //if (aSlider.location.z < (kSliderTopOffset + kSliderBottomOffset) / 2.0f) {
                if (aSlider.location.z < self.pickedSliderPreviousLocation.z || aSlider.location.z == kSliderTopOffset) {
                    targetLocation = cc3v(aSlider.location.x, aSlider.location.y, kSliderTopOffset);
                    newState = YES;
                } else {
                    targetLocation = cc3v(aSlider.location.x, aSlider.location.y, kSliderBottomOffset);
                    newState = NO;
                }
            }
            
            if (state != newState) {
                [UserData instance].sliderPos[aSlider.nodeIndex] = @(newState);
                [self updatePanelSliderAssignment:aSlider direction:newState ? -1 : 1];
            }

            CCActionInterval *moveTo = [CC3MoveTo actionWithDuration:kAnimationSpeed moveTo:targetLocation];
            [aSlider runAction:[CCSequence actions:moveTo, [CCCallFuncN actionWithTarget:self selector:@selector(moveSliderDidEnd:)], nil]];
        }
        if ([self checkSolved]) {
            [self.delegate gameSolved];
        }
        if ([self checkMagicSquare]) {
            [self.delegate backSolved];
        }
    } else if (self.pickedSliderAssignment) {
        for (CC3Node *aSlider in sliders) {
            [self moveSliderDidEnd:aSlider];
        }
    }
    self.pickedSlider = nil;
}

- (BOOL)checkSolved {
    BOOL solved;
    for (int c = 0; c < 4; c++) {
        solved = YES;
        int offset = 0;
        int dx = 0;
        int dy = 0;
        switch (c) {
            case 0: dx = 0; dy = 0;
                break;
            case 1: dx = 4; dy = 0;
                break;
            case 2: dx = 0; dy = 5;
                break;
            case 3: dx = 4; dy = 5;
                break;
        }
        for (int i = 0; i < 20; i++) {
            int pi = i - offset;
            if (i % 5 == 4-dx) {
                pi = -1;
                offset++;
            }
            if ([[UserData instance].panelPos[i+dy] intValue] != pi) {
                solved = NO;
                break;
            }
        }
        if (solved) {
            break;
        }
    }
    return solved;
}

- (BOOL)checkMagicSquare {
    // Rows
    for (int i = 0; i < 3; i++) {
        int sum = 0;
        for (int j = 0; j < 3; j++) {
            sum += [[UserData instance].panelPos[6 + j + 5 * i] intValue] + 1;
        }
        if (sum != 15) {
            return NO;
        }
    }
    // Columns
    for (int i = 0; i < 3; i++) {
        int sum = 0;
        for (int j = 0; j < 3; j++) {
            sum += [[UserData instance].panelPos[6 + i + 5 * j] intValue] + 1;
        }
        if (sum != 15) {
            return NO;
        }
    }    
    // Digaonals
    int sum = 0;
    for (int i = 0; i < 3; i++) {
        sum += [[UserData instance].panelPos[6 + i + 5 * i] intValue] + 1;
    }
    if (sum != 15) {
        return NO;
    }
    sum = 0;
    for (int i = 0; i < 3; i++) {
        sum += [[UserData instance].panelPos[8 - i + 5 * i] intValue] + 1;
    }
    if (sum != 15) {
        return NO;
    }    
    return YES;
}

- (void)moveSliderDidEnd:(CC3Node *)slider {
    [self endPanelSliderAssignment:slider];
    if ([slider isHorizontal]) {
        self.horizontalSlidersInMove--;
    } else {
        self.verticalSlidersInMove--;
    }
    void (^handler)() = self.sliderMoveCompletionHandler;
    if (self.horizontalSlidersInMove == 0 && self.verticalSlidersInMove == 0) {
        [[SoundManager instance] playEndSliderMoveSound];
        self.pickedSliderAssignment = NO;
        self.pickedSliderMoving = NO;
        if (self.sliderMoveCompletionHandler) {
            self.sliderMoveCompletionHandler = nil;            
        }
    }
    if (handler) {
        handler();
    }
}

- (BOOL)moveSlider:(CC3Node *)slider {
    if (![self checkSliderIsMovable:slider]) {
        return NO;
    }
    
    if ([slider isHorizontal]) {
        if (self.verticalSlidersInMove > 0) {
            return NO;
        }
        self.horizontalSlidersInMove++;
    } else {
        if (self.horizontalSlidersInMove > 0) {
            return NO;
        }
        self.verticalSlidersInMove++;
    }
    
    [self startPanelSliderAssignment:slider];
    [[SoundManager instance] playStartSliderMoveSound];
    
    CC3Vector targetLocation;
    if ([[UserData instance].sliderPos[slider.nodeIndex] boolValue]) {
        if ([slider isHorizontal]) {
            targetLocation = cc3v(kSliderRightOffset, slider.location.y, slider.location.z);
        } else {
            targetLocation = cc3v(slider.location.x, slider.location.y, kSliderBottomOffset);
        }
    } else {
        if ([slider isHorizontal]) {
            targetLocation = CC3VectorMake(kSliderLeftOffset, slider.location.y, slider.location.z);
        } else {
            targetLocation = cc3v(slider.location.x, slider.location.y, kSliderTopOffset);
        }
    }
    
    CCActionInterval *moveTo = [CC3MoveTo actionWithDuration:kAnimationSpeed moveTo:targetLocation];
    [slider runAction:[CCSequence actions:moveTo, [CCCallFuncN actionWithTarget:self selector:@selector(moveSliderDidEnd:)], nil]];

    BOOL newState = ![[UserData instance].sliderPos[slider.nodeIndex] boolValue];
    [UserData instance].sliderPos[slider.nodeIndex] = @(newState);
    [self updatePanelSliderAssignment:slider direction:newState ? -1 : 1];
    return YES;
}

- (void)moveSlider:(int)sliderIndex complete:(void (^)())handler {
    self.sliderMoveCompletionHandler = handler;
    [self moveSlider:self.sliders[sliderIndex]];
}

- (void)moveSliders:(int)sliderMask complete:(void (^)())handler {
    [self moveHorizontalSliders:sliderMask complete:^{
        [self moveVerticalSliders:sliderMask complete:handler];
    }];
}

- (void)moveHorizontalSliders:(int)sliderMask complete:(void (^)())handler {
    if (sliderMask & FifteenSliderMaskHorizontalTop) {
        [self moveHorizontalTopSlider:^{
            if (sliderMask & FifteenSliderMaskHorizontalBottom) {
                [self moveHorizontalBottomSlider:^{
                    if (sliderMask & FifteenSliderMaskHorizontalMiddle) {
                        [self moveHorizontalMiddleSlider:handler];
                    } else {
                        handler();
                    }
                }];
            } else if (sliderMask & FifteenSliderMaskHorizontalMiddle) {
                [self moveHorizontalMiddleSlider:handler];
            } else {
                handler();
            }
        }];
    } else if (sliderMask & FifteenSliderMaskHorizontalBottom) {
        [self moveHorizontalBottomSlider:^{
            if (sliderMask & FifteenSliderMaskHorizontalMiddle) {
                [self moveHorizontalMiddleSlider:handler ];
            } else {
                handler();
            }
        }];
    } else if (sliderMask & FifteenSliderMaskHorizontalMiddle) {
        [self moveHorizontalMiddleSlider:handler];
    } else {
        handler();
    }
}

- (void)moveHorizontalTopSlider:(void (^)())handler {
    [self moveVerticalSlidersToState:FifteenSliderMaskVerticalAll complete:^{
        Scene *scene = self;
        self.sliderMoveCompletionHandler = ^() {
            scene.sliderMoveCount--;
            if (scene.sliderMoveCount == 0) {
                scene.inSliderMove = NO;
                scene.sliderMoveCompletionHandler = nil;
                if (handler) {
                    handler();
                }
            }
        };
        self.inSliderMove = YES;
        if ([self moveSlider:self.sliders[FifteenSliderIndexHorizontalTop]]) {
            self.sliderMoveCount++;
        }
        if (self.sliderMoveCount == 0) {
            self.inSliderMove = NO;
            self.sliderMoveCompletionHandler = nil;
            if (handler) {
                handler();
            }
        }
    }];
}

- (void)moveHorizontalMiddleSlider:(void (^)())handler {
    Scene *scene = self;
    self.sliderMoveCompletionHandler = ^() {
        scene.sliderMoveCount--;
        if (scene.sliderMoveCount == 0) {
            scene.inSliderMove = NO;
            scene.sliderMoveCompletionHandler = nil;
            if (handler) {
                handler();
            }
        }
    };
    self.inSliderMove = YES;
    if ([self moveSlider:self.sliders[FifteenSliderIndexHorizontalMiddle]]) {
        self.sliderMoveCount++;
    }
    if (self.sliderMoveCount == 0) {
        self.inSliderMove = NO;
        self.sliderMoveCompletionHandler = nil;
        if (handler) {
            handler();
        }
    }
}

- (void)moveHorizontalBottomSlider:(void (^)())handler {
    [self moveVerticalSlidersToState:FifteenSliderMaskVerticalNone complete:^{
        Scene *scene = self;
        self.sliderMoveCompletionHandler = ^() {
            scene.sliderMoveCount--;
            if (scene.sliderMoveCount == 0) {
                scene.inSliderMove = NO;
                scene.sliderMoveCompletionHandler = nil;
                if (handler) {
                    handler();
                }
            }
        };
        self.inSliderMove = YES;
        if ([self moveSlider:self.sliders[FifteenSliderIndexHorizontalBottom]]) {
            self.sliderMoveCount++;
        }
        if (self.sliderMoveCount == 0) {
            self.inSliderMove = NO;
            self.sliderMoveCompletionHandler = nil;
            if (handler) {
                handler();
            }
        }
    }];
}

- (void)moveVerticalSliders:(int)sliderMask complete:(void (^)())handler {
    Scene *scene = self;
    self.sliderMoveCompletionHandler = ^() {
        scene.sliderMoveCount--;
        if (scene.sliderMoveCount == 0) {
            scene.inSliderMove = NO;
            scene.sliderMoveCompletionHandler = nil;
            if (handler) {
                handler();
            }
        }
    };
    self.inSliderMove = YES;
    if (sliderMask & FifteenSliderMaskVerticalLeft) {
        if ([self moveSlider:self.sliders[FifteenSliderIndexVerticalLeft]]) {
            self.sliderMoveCount++;
        }
    }
    if (sliderMask & FifteenSliderMaskVerticalMiddle) {
        if ([self moveSlider:self.sliders[FifteenSliderIndexVerticalMiddle]]) {
            self.sliderMoveCount++;
        }
    }
    if (sliderMask & FifteenSliderMaskVerticalRight) {
        if ([self moveSlider:self.sliders[FifteenSliderIndexVerticalRight]]) {
            self.sliderMoveCount++;
        }
    }
    if (self.sliderMoveCount == 0) {
        self.inSliderMove = NO;
        self.sliderMoveCompletionHandler = nil;
        if (handler) {
            handler();
        }
    }
}

- (void)moveSlidersToInitialState:(void (^)())handler {
    [self moveSlidersToState:FifteenSliderMaskHorizontalAll | FifteenSliderMaskVerticalAll complete:handler];
}

- (void)moveSlidersToState:(int)sliderMask complete:(void (^)())handler {
    [self moveHorizontalSlidersToState:sliderMask complete:^{
        [self moveVerticalSlidersToState:sliderMask complete:handler];
    }];
}

- (void)moveHorizontalSlidersToState:(int)sliderMask complete:(void (^)())handler {
    BOOL stateTop    = sliderMask & FifteenSliderMaskHorizontalTop    ? YES : NO;
    BOOL stateMiddle = sliderMask & FifteenSliderMaskHorizontalMiddle ? YES : NO;
    BOOL stateBottom = sliderMask & FifteenSliderMaskHorizontalBottom ? YES : NO;
    
    if (stateTop != [[UserData instance].sliderPos[FifteenSliderIndexHorizontalTop] boolValue]) {
        [self moveHorizontalTopSlider:^{
            if (stateBottom != [[UserData instance].sliderPos[FifteenSliderIndexHorizontalBottom] boolValue]) {
                [self moveHorizontalBottomSlider:^{
                    if (stateMiddle != [[UserData instance].sliderPos[FifteenSliderIndexHorizontalMiddle] boolValue]) {
                        [self moveHorizontalMiddleSlider:^{
                            handler();
                        }];
                    } else {
                        handler();
                    }
                }];
            } else if (stateMiddle != [[UserData instance].sliderPos[FifteenSliderIndexHorizontalMiddle] boolValue]) {
                [self moveHorizontalMiddleSlider:^{
                    handler();
                }];
            } else {
                handler();
            }
        }];
    } else if (stateBottom != [[UserData instance].sliderPos[FifteenSliderIndexHorizontalBottom] boolValue]) {
        [self moveHorizontalBottomSlider:^{
            if (stateMiddle != [[UserData instance].sliderPos[FifteenSliderIndexHorizontalMiddle] boolValue]) {
                [self moveHorizontalMiddleSlider:^{
                    handler();
                }];
            } else {
                handler();
            }
        }];
    } else if (stateMiddle != [[UserData instance].sliderPos[FifteenSliderIndexHorizontalMiddle] boolValue]) {
        [self moveHorizontalMiddleSlider:^{
            handler();
        }];
    } else {
        handler();
    }
}

- (void)moveVerticalSlidersToState:(int)sliderMask complete:(void (^)())handler {
    Scene *scene = self;
    self.sliderMoveCompletionHandler = ^() {
        scene.sliderMoveCount--;
        if (scene.sliderMoveCount == 0) {
            scene.inSliderMove = NO;
            scene.sliderMoveCompletionHandler = nil;
            if (handler) {
                handler();
            }
        }
    };
    self.inSliderMove = YES;
    BOOL state = sliderMask & FifteenSliderMaskVerticalLeft ? YES : NO;
    if (state != [[UserData instance].sliderPos[FifteenSliderIndexVerticalLeft] boolValue]) {
        if ([self moveSlider:self.sliders[FifteenSliderIndexVerticalLeft]]) {
            self.sliderMoveCount++;
        }
    }
    state = sliderMask & FifteenSliderMaskVerticalMiddle ? YES : NO;
    if (state != [[UserData instance].sliderPos[FifteenSliderIndexVerticalMiddle] boolValue]) {
        if ([self moveSlider:self.sliders[FifteenSliderIndexVerticalMiddle]]) {
            self.sliderMoveCount++;
        }
    }
    state = sliderMask & FifteenSliderMaskVerticalRight ? YES : NO;
    if (state != [[UserData instance].sliderPos[FifteenSliderIndexVerticalRight] boolValue]) {
        if ([self moveSlider:self.sliders[FifteenSliderIndexVerticalRight]]) {
            self.sliderMoveCount++;
        };
    }
    if (self.sliderMoveCount == 0) {
        self.inSliderMove = NO;
        self.sliderMoveCompletionHandler = nil;
        if (handler) {
            handler();
        }
    }
}

- (void)iterateSliders:(void (^)(int si))handler {
    for (int i = 0; i < 6; i++) {
        handler(i);
    }
}

- (void)iteratePanels:(void (^)(int pi))handler {
    for (int i = 0; i < 17; i++) {
        handler(i);
    }
}

- (void)initShuffle {
    self.shuffleTurnCount = random(30, 60);
    self.shuffleTurnIndex = 0;
}

- (void)shuffleNextPanel:(void (^)(int panel, BOOL turn, BOOL done))handler {
    if (self.shuffleTurnIndex < self.shuffleTurnCount) {
        int sliderMask = random(1, 64);
        BOOL turn = self.shuffleTurnIndex == self.shuffleTurnCount / 2;
        self.shuffleTurnIndex++;
        [self moveSliders:sliderMask complete:^{
            handler(self.shuffleTurnIndex, turn, NO);
        }];
    } else {
        handler(self.shuffleTurnIndex, NO, YES);
    }
}

- (void)initSolve {
    self.solveTurnCount = random(10, 30);
    self.solveTurnIndex = 0;
}

- (void)solveNextPanel:(void (^)(int panel, BOOL turn, BOOL done))handler {
    if (self.solveTurnIndex < self.solveTurnCount) {
        int sliderMask = random(1, 64);
        BOOL turn = self.solveTurnIndex == self.solveTurnCount / 2;
        self.solveTurnIndex++;
        [self moveSliders:sliderMask complete:^{
            handler(self.solveTurnIndex, turn, NO);
        }];
    } else {
        handler(self.solveTurnIndex, NO, YES);
    }
}

- (void)setSolvedFront {
    [UserData instance].panelPos = [@[ @(0),  @(1),  @(2),  @(3), @(-1),
                                       @(4),  @(5),  @(6),  @(7), @(-1),
                                       @(8),  @(9), @(10), @(11), @(-1),
                                      @(12), @(13), @(14), @(15), @(-1),
                                      @(16), @(-1), @(-1), @(-1), @(-1)] mutableCopy];
    [UserData instance].sliderPos = [@[@(YES), @(YES), @(YES), @(YES), @(YES), @(YES)] mutableCopy];
    [self setState];
}

- (void)setSolvedBack {
    [UserData instance].panelPos = [@[@(12), @(11), @(10),  @(9), @(-1),
                                      @(13),  @(5),  @(6),  @(1), @(-1),
                                      @(14),  @(0),  @(4),  @(8), @(-1),
                                      @(15),  @(7),  @(2),  @(3), @(-1),
                                      @(16), @(-1), @(-1), @(-1), @(-1)] mutableCopy];
    [UserData instance].sliderPos = [@[@(YES), @(YES), @(YES), @(YES), @(YES), @(YES)] mutableCopy];
    [self setState];
}

@end

@implementation CC3Node (CustomData)

- (void)set {
    if (!self.userData) {
        self.userData = (void *)CFBridgingRetain([@{} mutableCopy]);
    }
}

- (void)setNodeIndex:(int)nodeIndex {
    [self set];
    return [((NSArray *)self.userData) setValue:@(nodeIndex) forKey:@"nodeIndex"];
}

- (void)setSliderOut:(BOOL)sliderOut {
    [self set];
    return [((NSArray *)self.userData) setValue:@(sliderOut) forKey:@"sliderOut"];
}

- (int)nodeIndex {
    return [[((NSArray *)self.userData) valueForKey:@"nodeIndex"] intValue];
}

- (BOOL)isSliderOut {
    return [[((NSArray *)self.userData) valueForKey:@"sliderOut"] boolValue];
}

- (BOOL)isHorizontal {
    return self.nodeIndex < 3;
}

@end
