//
//  SoundManager.h
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 24.02.13.
//  Copyright 2013. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimpleAudioEngine.h"
#import "CDXPropertyModifierAction.h"
#import "UserData.h"

@interface SoundManager : NSObject {
	CDSoundSource *fifteenMoveSound;
	CDSoundSource *sliderMoveSound;
	
	SimpleAudioEngine *soundEngine;
	CDXPropertyModifierAction* faderAction;
	CCActionManager *actionManager;
}

@property (nonatomic, retain, readonly) UserData *userData;
@property BOOL fifteenMoveSoundPlaying;
@property BOOL sliderMoveSoundSoundPlaying;

- (void)startSliderMoveSound;
- (void)stopSliderMoveSound;

- (void)playStartSliderMoveSound;
- (void)playEndSliderMoveSound;
- (void)playSliderLockedSound;
- (void)playHUDButtonSound;

- (void)stopSound;

+ (SoundManager *)instance;

@end
