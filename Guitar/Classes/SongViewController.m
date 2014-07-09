//
//  SongViewController.m
//  Guitar
//
//  Created by Raimund on 30.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "SongViewController.h"
#import "GuitarGLKViewController.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "UIBarButtonItem.h"

@implementation SongViewController

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
    self.title = @"song";
    
    // Set label text
    self.titleLabel.text = _songTitle;
    
    // Set the side bar button
    UIImage *customImage = [UIImage imageNamed:@"header_menu_icon"];
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem styledBarButtonItemWithImage:customImage target:self.revealViewController action:@selector(revealToggle:)];
    
    // Set the navigation bar gesture
    [self.navigationController.navigationBar addGestureRecognizer:self.revealViewController.panGestureRecognizer1];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _highscoreLabel.text = [NSString stringWithFormat:@"%d", [appDelegate getHighscoreForSong:_songTitle]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Set the view gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer2];
}

#pragma mark - Actions

- (IBAction)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[GuitarGLKViewController class]]) {
        GuitarGLKViewController *guitarGLKViewController = segue.destinationViewController;
        //if ([cell isKindOfClass:[CategoryCell class]]) {
        //    CategoryCell *categoryCell = (CategoryCell *)cell;
        //    subCategoryTableViewController.categoryID = categoryCell.categoryID;
        //    subCategoryTableViewController.title = categoryCell.name.text;
        //}
        guitarGLKViewController.songTitle = _songTitle;
    }
}

@end
