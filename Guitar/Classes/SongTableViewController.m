//
//  SongTableViewController.m
//  Guitar
//
//  Created by Raimund on 30.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "SongTableViewController.h"
#import "SongViewController.h"
#import "SongCell.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "UIBarButtonItem.h"

@implementation SongTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set title
    self.title = @"songs";

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
                         self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:255.0 / 255 green:204.0 / 255 blue:102.0 / 255 alpha:1.0];
                     }
                     completion:nil];
    
    // Default songs
    _songItems = @[@"one", @"two", @"three", @"four", @"five", @"six", @"seven", @"eight", @"nine"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Refresh table for new scores
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Set the view gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer2];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_songItems count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 88;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"song";
    SongCell *cell = (SongCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Get song title
    NSString *songTitle = [_songItems objectAtIndex:indexPath.row];
    
    // Get highscore for song
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    int score = [appDelegate getHighscoreForSong:songTitle];
    
    // Set cell values
    cell.titleLabel.text = songTitle;
    cell.highscoreLabel.text = [NSString stringWithFormat:@"%d", score];
    
    return cell;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[SongViewController class]]) {
        SongViewController *songViewController = segue.destinationViewController;
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
        if ([cell isKindOfClass:[SongCell class]]) {
            SongCell *songCell = (SongCell *)cell;
            songViewController.songTitle = songCell.titleLabel.text;
        }
    }
}

@end
