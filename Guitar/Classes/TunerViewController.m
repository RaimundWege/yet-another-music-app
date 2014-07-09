//
//  TunerViewController.m
//  Guitar
//
//  Created by Raimund on 30.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "TunerViewController.h"
#import "AudioHost.h"
#import "SWRevealViewController.h"
#import "UIBarButtonItem.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@implementation TunerViewController

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
    self.title = @"tuner";
    
    // Disable amplitude driven
    [[AudioHost sharedInstance] setAmplitudeDriven:NO];
    
    // Set note names
    //notes = [NSArray arrayWithObjects:@"c", @"c#", @"d", @"d#", @"e", @"f", @"f#", @"g", @"g#", @"a", @"a#", @"h", nil];
    notes = [NSArray arrayWithObjects:@"a", @"a#", @"h", @"c", @"c#", @"d", @"d#", @"e", @"f", @"f#", @"g", @"g#", nil];
    
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
                         self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:204.0 / 255 green:255.0 / 255 blue:102.0 / 255 alpha:1.0];
                     }
                     completion:nil];
    
    // Set the anchor point of the needle to the middle of the bottom
    [self setAnchorPoint:CGPointMake(0.5, 1.0) forView:_needleImageView];
    needleFrame = _needleImageView.frame;
    
    // Initialize a timer for note and needle updates
    [NSTimer scheduledTimerWithTimeInterval:0.2
									 target:self
								   selector:@selector(refreshTuner:)
								   userInfo:nil
									repeats:YES];
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y);
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    CGPoint position = view.layer.position;
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Set the view gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer2];
}

- (void)refreshTuner:(NSTimer *)timer
{
    float f = [[AudioHost sharedInstance] computeAutoCorrelation];
    if (f > 0.0) {
        if (f > 80.0) {
            frequency = (frequency * 0.3 + f * 0.7);
            float linear = log2f(frequency / 440.0) / log2f(2.0) + 4.0;
            float octave = floorf(linear);
            float cents = 1200 * (linear - octave);
            float noteIndex = fmodf(floorf(cents / 100), 12);
            cents -= noteIndex * 100;
            if (cents > 50) {
                cents -= 100;
                if (++noteIndex > 11) noteIndex -= 12;
            }
            NSString *note = [notes objectAtIndex:noteIndex];
            
            // animate the view
            [UIView animateWithDuration:0.15
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 _noteLabel.text = [NSString stringWithFormat:@"%@", note];
                                 _noteLabel.textColor = ABS(cents) < 5 ? [UIColor greenColor] : [UIColor redColor];
                                 _frequencyLabel.text = [NSString stringWithFormat:@"%.2f Hz", frequency];
                                 _centLabel.text = [NSString stringWithFormat:@"%i Cent", (int)cents];
                                 _needleImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, DEGREES_TO_RADIANS(cents));
                             }
                             completion:nil];
        } else {
            frequency = 0.0;
            
            // animate the view
            [UIView animateWithDuration:0.5
                                  delay:1.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 _noteLabel.text = @"note";
                                 _noteLabel.textColor = [UIColor blackColor];
                                 _frequencyLabel.text = @"frequency";
                                 _centLabel.text = @"cent";
                                 _needleImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, DEGREES_TO_RADIANS(0.0));
                             }
                             completion:nil];
        }
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    CGPoint oldCenter = [_needleImageView center];
    [_needleImageView setTransform:CGAffineTransformIdentity];
    [_needleImageView setFrame:needleFrame];
    
    // restore previous center and rotation
    [_needleImageView setCenter:oldCenter];
    [_needleImageView setTransform:CGAffineTransformRotate(CGAffineTransformIdentity, (DEGREES_TO_RADIANS(0.0)))];
}

@end
