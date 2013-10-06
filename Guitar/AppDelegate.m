//
//  AppDelegate.m
//  Guitar
//
//  Created by Raimund on 19.09.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Turn off the idle timer, since this app doesn't rely on constant touch input
	application.idleTimerDisabled = YES;
	
    // Create AudioHost and start it
    _audioHost = [AudioHost audioHost];
    [_audioHost start];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {}

- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application {}

- (void)applicationWillTerminate:(UIApplication *)application {}

@end
