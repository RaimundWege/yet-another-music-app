//
//  UIFlatBarButtonItem.m
//  vhs
//
//  Created by Raimund on 09.08.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "UIBarButtonItem.h"

@implementation UIBarButtonItem(StyledButton)

+ (UIBarButtonItem *)styledBarButtonItemWithImage:(UIImage *)image target:(id)target action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return [[self alloc] initWithCustomView:button];
}

@end
