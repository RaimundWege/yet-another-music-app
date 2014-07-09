//
//  AppDelegate.m
//  Guitar
//
//  Created by Raimund on 19.09.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "AppDelegate.h"

#define USER_DEFAULTS_LEFT_HANDED @"left_handed"
#define USER_DEFAULTS_STRING_VOLUME @"string_volume"
#define USER_DEFAULTS_GUITAR_VOLUME @"guitar_volume"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Turn off the idle timer, since this app doesn't rely on constant touch input
	application.idleTimerDisabled = YES;
	
    // Set status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    /*/ Load splash image
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    UIImage *splashImage;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        splashImage = [UIImage imageNamed:@"Default-Portrait.png"];
    } else {
        if ([UIScreen mainScreen].scale == 2.f && height == 568.0f) {
            splashImage = [UIImage imageNamed:@"Default-568h.png"];
        } else {
            splashImage = [UIImage imageNamed:@"Default"];
        }
    }
    
    // Create splash image view with fade out
    UIImageView *splashImageView = [[UIImageView alloc] initWithImage:splashImage];
    
    // In iOS 7 no status bar substract
    NSArray *systemVersion = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    if ([[systemVersion objectAtIndex:0] intValue] >= 7) {
        splashImageView.frame = CGRectMake(0, 0, width, height);
    } else {
        splashImageView.frame = CGRectMake(0, -[UIApplication sharedApplication].statusBarFrame.size.height, width, height);
    }
    
    [self.window.rootViewController.view addSubview:splashImageView];
    [self.window.rootViewController.view bringSubviewToFront:splashImageView];
    [UIView animateWithDuration:1.5f
                          delay:1.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         splashImageView.alpha = .0f;
                         CGFloat x = -60.0f;
                         CGFloat y = -120.0f;
                         splashImageView.frame = CGRectMake(x,
                                                            y,
                                                            splashImageView.frame.size.width - 2 * x,
                                                            splashImageView.frame.size.height - 2 * y);
                     } completion:^(BOOL finished){
                         if (finished) {
                             [splashImageView removeFromSuperview];
                         }
                     }];*/
    
    // Set audio settings
    [[AudioHost sharedInstance] setStringVolume:[self getStringVolume]];
    [[AudioHost sharedInstance] setGuitarVolume:[self getGuitarVolume]];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[AudioHost sharedInstance] stopRIO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[AudioHost sharedInstance] startRIO];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {}

- (void)applicationWillTerminate:(UIApplication *)application {}


#pragma mark - read settings

- (int)getHighscoreForSong:(NSString *)songTitle
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:[NSString stringWithFormat:@"song_%@", songTitle]];
}

- (void)setHighscore:(int)score forSong:(NSString *)songTitle
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:score forKey:[NSString stringWithFormat:@"song_%@", songTitle]];
    [userDefaults synchronize];
}

- (BOOL)getLeftHanded
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:USER_DEFAULTS_LEFT_HANDED];
}

- (void)setLeftHanded:(BOOL)value
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:value forKey:USER_DEFAULTS_LEFT_HANDED];
    [userDefaults synchronize];
}

- (float)getGuitarVolume
{
    return [self getVolumeForKey:USER_DEFAULTS_GUITAR_VOLUME];
}

- (void)setGuitarVolume:(float)volume
{
    return [self setVolume:volume forKey:USER_DEFAULTS_GUITAR_VOLUME];
}

- (float)getStringVolume
{
    return [self getVolumeForKey:USER_DEFAULTS_STRING_VOLUME];
}

- (void)setStringVolume:(float)volume
{
    return [self setVolume:volume forKey:USER_DEFAULTS_STRING_VOLUME];
}

- (float)getVolumeForKey:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    float volume = [userDefaults floatForKey:key];
    return (volume < 0 ? 0.0 : volume > 1.0 ? 1.0 : volume);
}

- (void)setVolume:(float)volume forKey:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:volume forKey:key];
    [userDefaults synchronize];
}

@end
