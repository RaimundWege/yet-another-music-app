//
//  TunerViewController.h
//  Guitar
//
//  Created by Raimund on 30.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TunerViewController : UIViewController {
@private
    NSArray *notes;
    float frequency;
    CGRect needleFrame;
}

@property (weak, nonatomic) IBOutlet UILabel *noteLabel;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *centLabel;
@property (weak, nonatomic) IBOutlet UIImageView *needleImageView;

- (void)refreshTuner:(NSTimer *)timer;

@end
