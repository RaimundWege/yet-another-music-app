//
//  SongViewController.h
//  Guitar
//
//  Created by Raimund on 30.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SongViewController : UIViewController

@property (readwrite) NSString *songTitle;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *highscoreLabel;

- (IBAction)goBack:(id)sender;

@end
