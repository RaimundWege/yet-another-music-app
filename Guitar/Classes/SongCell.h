//
//  SongCell.h
//  Guitar
//
//  Created by Raimund on 06.11.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SongCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *highscoreLabel;

@end
