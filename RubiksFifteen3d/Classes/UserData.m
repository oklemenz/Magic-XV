//
//  UserData.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 24.02.13.
//  Copyright 2013. All rights reserved.
//

#import "UserData.h"
#import "Scene.h"
#import "AppDelegate.h"

#define kDonationTimeValue 5 * 60;

@implementation UserData

- (id)init {
    self = [super init];
    if (self) {
        [self load];
    }
    return self;
}

- (void)reset {
    _cameraOn = NO;
    _gyroOn = NO;
    _soundOn = NO;
    _time = 0;
    _rotation = kInitialFrontRotation;
    _location = !IS_IPHONE_4 ? kInitialCameraLocation1 : kInitialCameraLocation2;
    
    _donated = NO;
    _donationTime = kDonationTimeValue;
    
    _sliderPos = [NSMutableArray arrayWithCapacity:6];
    for (int i = 0; i < 6; i++) {
        _sliderPos[i] = @(YES);
    }
    _panelPos = [NSMutableArray arrayWithCapacity:25];
    int offset = 0;
    for (int i = 0; i < 25; i++) {
        int pi = i - offset;
        if (i % 5 == 4 || i >= 21) {
            pi = -1;
            offset++;
        }
        _panelPos[i] = @(pi);
    }
}

- (void)load {
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    if ([data integerForKey:@"init"] == 1) {
        _cameraOn = [[data valueForKey:@"camera"] boolValue];
        _gyroOn = [[data valueForKey:@"gyro"] boolValue];
        _soundOn = [[data valueForKey:@"sound"] boolValue];
        _inPlay = [[data valueForKey:@"play"] boolValue];
        NSDictionary *rotationDict = [data valueForKey:@"rotation"];
        _rotation = CC3VectorMake([rotationDict[@"x"] doubleValue], [rotationDict[@"y"] doubleValue], [rotationDict[@"z"] doubleValue]);
        NSDictionary *locationDict = [data valueForKey:@"location"];
        _location = CC3VectorMake([locationDict[@"x"] doubleValue], [locationDict[@"y"] doubleValue], [locationDict[@"z"] doubleValue]);
        _donated = [[data valueForKey:@"donated"] boolValue];
        _donationTime = [[data valueForKey:@"donationTime"] doubleValue];
        _time = [[data valueForKey:@"time"] doubleValue];
        _sliderPos = [[data valueForKey:@"slider"] mutableCopy];
        _panelPos = [[data valueForKey:@"panel"] mutableCopy];
    } else {
        [self reset];
        [self store];
    }
}

- (void)store {
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
	[data setInteger:1 forKey:@"init"];
    [data setValue:[NSNumber numberWithBool:_cameraOn] forKey:@"camera"];
    [data setValue:[NSNumber numberWithBool:_gyroOn] forKey:@"gyro"];
    [data setValue:[NSNumber numberWithBool:_soundOn] forKey:@"sound"];
    [data setValue:[NSNumber numberWithBool:_inPlay] forKey:@"play"];
    [data setValue:@{ @"x" : @(_rotation.x), @"y" : @(_rotation.y), @"z" : @(_rotation.z)} forKey:@"rotation"];
    [data setValue:@{ @"x" : @(_location.x), @"y" : @(_location.y), @"z" : @(_location.z)} forKey:@"location"];
    [data setValue:[NSNumber numberWithBool:_donated] forKey:@"donated"];
    [data setValue:[NSNumber numberWithDouble:_donationTime] forKey:@"donationTime"];
    [data setValue:[NSNumber numberWithDouble:_time] forKey:@"time"];
    [data setValue:_sliderPos forKey:@"slider"];
    [data setValue:_panelPos forKey:@"panel"];
    [data synchronize];
}

- (void)mock {
    /*
    _panelPos = [@[ @(0),  @(1),  @(2),  @(3), @(-1),
                    @(4),  @(5),  @(6),  @(7), @(-1),
                    @(8),  @(9), @(10), @(11), @(-1),
                    @(12), @(13), @(14), @(15), @(-1),
                    @(16), @(-1), @(-1), @(-1), @(-1)] mutableCopy];
    _sliderPos = [@[@(YES), @(YES), @(YES), @(YES), @(YES), @(YES)] mutableCopy];
    */
    
    /*
    _panelPos = [@[@(-1),  @(0),  @(1),  @(2),  @(3),
                   @(-1),  @(4),  @(5),  @(6),  @(7),
                   @(-1),  @(8),  @(9), @(10), @(11),
                   @(-1), @(12), @(13), @(14), @(15),
                   @(-1), @(-1), @(-1), @(-1), @(16)] mutableCopy];
    _sliderPos = [@[@(NO), @(NO), @(NO), @(YES), @(YES), @(YES)] mutableCopy];
    */
    
    /*
    _panelPos = [@[@(16), @(-1), @(-1), @(-1), @(-1),
                   @(0),  @(1),  @(2),  @(3), @(-1),
                   @(4),  @(5),  @(6),  @(7), @(-1),
                   @(8),  @(9), @(10), @(11), @(-1),
                   @(12), @(13), @(14), @(15), @(-1)] mutableCopy];
    _sliderPos = [@[@(YES), @(YES), @(YES), @(NO), @(NO), @(NO)] mutableCopy];
    */
    
    /*
    _panelPos = [@[@(-1), @(-1), @(-1), @(-1), @(16),
                   @(-1),  @(0),  @(1),  @(2),  @(3),
                   @(-1),  @(4),  @(5),  @(6),  @(7),
                   @(-1),  @(8),  @(9), @(10), @(11),
                   @(-1), @(12), @(13), @(14), @(15)] mutableCopy];
    _sliderPos = [@[@(NO), @(NO), @(NO), @(NO), @(NO), @(NO)] mutableCopy];
    */

    /*
    _panelPos = [@[@(12), @(11), @(10),  @(9), @(-1),
                   @(13),  @(5),  @(6),  @(1), @(-1),
                   @(14),  @(0),  @(4),  @(8), @(-1),
                   @(15),  @(7),  @(2),  @(3), @(-1),
                   @(16), @(-1), @(-1), @(-1), @(-1)] mutableCopy];
    _sliderPos = [@[@(YES), @(YES), @(YES), @(YES), @(YES), @(YES)] mutableCopy];
    */
}

+ (UserData *)instance {
    static UserData *instance;
    @synchronized(self) {
        if (!instance) {
            instance = [UserData new];
        }
        return instance;
    }
}

- (void)increaseDonationTime {
    self.donationTime += kDonationTimeValue;
}

@end