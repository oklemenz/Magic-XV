//
//  SoundManager.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 24.02.13.
//  Copyright 2013. All rights reserved.
//

#import "SoundManager.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation SoundManager

+ (SoundManager *)instance {
	static SoundManager *_instance;
	@synchronized(self) {
		if (!_instance) {
			_instance = [SoundManager new];
		}
	}
	return _instance;
}

- (id)init {
	if ((self = [super init])) {

		soundEngine = [SimpleAudioEngine sharedEngine];
		[[CDAudioManager sharedManager] setResignBehavior:kAMRBStopPlay autoHandle:YES];
		actionManager = [CCActionManager sharedManager];
		soundEngine.effectsVolume = 1.0f;

		[soundEngine preloadEffect:@"fifteen_move.caf"];
		[soundEngine preloadEffect:@"slider_move.caf"];
		[soundEngine preloadEffect:@"start_slider_move.caf"];
		[soundEngine preloadEffect:@"end_slider_move.caf"];
        [soundEngine preloadEffect:@"slider_locked.caf"];
		[soundEngine preloadEffect:@"hud_button.caf"];
		
		fifteenMoveSound = [soundEngine soundSourceForFile:@"fifteen_move.caf"];
		fifteenMoveSound.gain = 0.0f;
		sliderMoveSound = [soundEngine soundSourceForFile:@"slider_move.caf"];
		sliderMoveSound.gain = 0.0f;
	}
	return self;
}

- (void)startFifteenMoveSound {
	if ([UserData instance].isSoundOn && !self.fifteenMoveSoundPlaying) {
		[[CCActionManager sharedManager] removeAllActionsFromTarget:fifteenMoveSound];
		fifteenMoveSound.looping = YES;
		[fifteenMoveSound play];
		[CDXPropertyModifierAction fadeSoundEffect:0.25f finalVolume:1.0f curveType:kIT_Linear shouldStop:NO effect:fifteenMoveSound];
		self.fifteenMoveSoundPlaying = YES;
	}
}

- (void)stopFifteenMoveSound {
	if (self.fifteenMoveSoundPlaying) {
		[[CCActionManager sharedManager] removeAllActionsFromTarget:fifteenMoveSound];
		[CDXPropertyModifierAction fadeSoundEffect:0.5f finalVolume:0.0f curveType:kIT_Linear shouldStop:YES effect:fifteenMoveSound];
		self.fifteenMoveSoundPlaying = NO;
	}
}

- (void)startSliderMoveSound {
	if ([UserData instance].isSoundOn && !self.sliderMoveSoundSoundPlaying) {
		[[CCActionManager sharedManager] removeAllActionsFromTarget:sliderMoveSound];
		sliderMoveSound.looping = YES;
		[sliderMoveSound play];
		[CDXPropertyModifierAction fadeSoundEffect:0.25f finalVolume:1.0f curveType:kIT_Linear shouldStop:NO effect:sliderMoveSound];
		self.sliderMoveSoundSoundPlaying = YES;
	}
}

- (void)stopSliderMoveSound {
	if (self.sliderMoveSoundSoundPlaying) {
		[[CCActionManager sharedManager] removeAllActionsFromTarget:sliderMoveSound];
		[CDXPropertyModifierAction fadeSoundEffect:0.25f finalVolume:0.0f curveType:kIT_Linear shouldStop:YES effect:sliderMoveSound];
		self.sliderMoveSoundSoundPlaying = NO;
	}
}

- (void)playStartSliderMoveSound {
	if ([UserData instance].isSoundOn) {
		[soundEngine playEffect:@"start_slider_move.caf"];
	}
}

- (void)playEndSliderMoveSound {
	if ([UserData instance].isSoundOn) {
		[soundEngine playEffect:@"end_slider_move.caf"];
	}
}

- (void)playSliderLockedSound {
	if ([UserData instance].isSoundOn) {
		[soundEngine playEffect:@"slider_locked.caf"];
	}
}

- (void)playHUDButtonSound {
	if ([UserData instance].isSoundOn) {
		[soundEngine playEffect:@"hud_button.caf"];
	}
}

- (void)stopSound {
    [self stopFifteenMoveSound];
    [self stopSliderMoveSound];
}

- (void)dealloc {
	[actionManager removeAllActionsFromTarget:fifteenMoveSound];
	[actionManager removeAllActionsFromTarget:sliderMoveSound];
	[actionManager removeAllActionsFromTarget:[[CDAudioManager sharedManager] audioSourceForChannel:kASC_Left]];
	[actionManager removeAllActionsFromTarget:[CDAudioManager sharedManager].soundEngine];
	[SimpleAudioEngine end];
	soundEngine = nil;
}

@end