//
//  AppDelegate.h
//  Guitar
//
//  Created by Raimund on 19.09.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioHost.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) AudioHost *audioHost;

- (int)getHighscoreForSong:(NSString *)songTitle;
- (void)setHighscore:(int)score forSong:(NSString *)songTitle;

- (BOOL)getLeftHanded;
- (void)setLeftHanded:(BOOL)value;

- (float)getGuitarVolume;
- (void)setGuitarVolume:(float)volume;

- (float)getStringVolume;
- (void)setStringVolume:(float)volume;

@end
