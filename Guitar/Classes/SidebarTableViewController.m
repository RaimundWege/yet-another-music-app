//
//  SidebarTableViewController.m
//  Guitar
//
//  Created by Raimund on 30.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "SidebarTableViewController.h"
#import "SWRevealViewController.h"

@implementation SidebarTableViewController

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

    // correct iOS 7 design
    //NSArray *systemVersion = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    //if ([[systemVersion objectAtIndex:0] intValue] >= 7) {
    //    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    //}
    // correct white bottom line to black
    //self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    //self.tableView.separatorColor = [UIColor blackColor];
    
    _menuItems = @[@"songs", @"tuner", @"settings"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_menuItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [self.menuItems objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //cell.contentView.backgroundColor = [UIColor colorWithRed:(28.0 / 256.0) green:(114.0 / 256.0) blue:(197.0 / 256.0) alpha:1.0];
    
    return cell;
}

#pragma mark - Segue

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Configure the destination view controller:
    if ([segue isKindOfClass:[SWRevealViewControllerSegue class]]) {
        SWRevealViewControllerSegue *swSegue = (SWRevealViewControllerSegue *)segue;
        swSegue.performBlock = ^(SWRevealViewControllerSegue *rvcSegue, UIViewController *svc, UIViewController *dvc) {
            UINavigationController *navController = (UINavigationController *)self.revealViewController.frontViewController;
            [navController setViewControllers:@[dvc] animated:NO];
            [self.revealViewController setFrontViewPosition: FrontViewPositionLeft animated:YES];
        };
    }
}

@end
