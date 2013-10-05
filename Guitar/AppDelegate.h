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

@end
