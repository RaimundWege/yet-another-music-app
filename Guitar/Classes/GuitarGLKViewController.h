//
//  GuitarGLKViewController.h
//  Guitar
//
//  Created by Raimund on 02.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "AudioHost.h"

@interface GuitarGLKViewController : GLKViewController {
@private
    float currentTime;
    AudioHost *ah;
    NSArray *notes;
    int32_t *l_fftData;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong) GLKBaseEffect *effect;

@end
