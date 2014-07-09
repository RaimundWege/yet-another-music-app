//
//  SettingsViewController.h
//  Guitar
//
//  Created by Raimund on 30.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISwitch *leftHandedSwitch;
@property (weak, nonatomic) IBOutlet UISlider *stringVolumeSlider;
@property (weak, nonatomic) IBOutlet UISlider *guitarVolumeSlider;

- (IBAction)stringVolumeChanged:(UISlider *)sender;
- (IBAction)guitarVolumeChanged:(UISlider *)sender;

@end
