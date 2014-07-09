//
//  SettingsViewController.m
//  Guitar
//
//  Created by Raimund on 30.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "AudioHost.h"
#import "SWRevealViewController.h"
#import "UIBarButtonItem.h"

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set title
    self.title = @"settings";
    
    // Set the side bar button
    UIImage *customImage = [UIImage imageNamed:@"header_menu_icon"];
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem styledBarButtonItemWithImage:customImage target:self.revealViewController action:@selector(revealToggle:)];
    
    // Set the navigation bar gesture
    [self.navigationController.navigationBar addGestureRecognizer:self.revealViewController.panGestureRecognizer1];
    
    // Set the navigationbar color
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:102.0 / 255 green:255.0 / 255 blue:204.0 / 255 alpha:1.0];
                     }
                     completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Load settings
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [_leftHandedSwitch setOn:[appDelegate getLeftHanded]];
    _stringVolumeSlider.value = [appDelegate getStringVolume];
    _guitarVolumeSlider.value = [appDelegate getGuitarVolume];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Set the view gesture
    //[self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer2];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Save settings
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setLeftHanded:[_leftHandedSwitch isOn]];
    [appDelegate setStringVolume:_stringVolumeSlider.value];
    [appDelegate setGuitarVolume:_guitarVolumeSlider.value];
}

- (void)viewDidUnload
{
    [self setLeftHandedSwitch:nil];
    [self setStringVolumeSlider:nil];
    [self setGuitarVolumeSlider:nil];
    
    [super viewDidUnload];
}

#pragma mark Actions

- (IBAction)stringVolumeChanged:(UISlider *)sender
{
    [[AudioHost sharedInstance] setStringVolume:[sender value]];
}

- (IBAction)guitarVolumeChanged:(UISlider *)sender
{
    [[AudioHost sharedInstance] setGuitarVolume:[sender value]];
}

@end
