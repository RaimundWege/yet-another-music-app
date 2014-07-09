//
//  UIFlatBarButtonItem.h
//  vhs
//
//  Created by Raimund on 09.08.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem(StyledButton)

+ (UIBarButtonItem *)styledBarButtonItemWithImage:(UIImage *)image target:(id)target action:(SEL)action;

@end
