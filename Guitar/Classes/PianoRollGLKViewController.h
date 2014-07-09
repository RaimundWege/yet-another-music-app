//
//  GameGLKViewController.h
//  Guitar
//
//  Created by Raimund on 04.11.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "GuitarGLKViewController.h"



@interface PianoRollGLKViewController : GuitarGLKViewController {
@private
    
    // Strings
    float stringHeight;

    // Frets
    int fretCount;
    float fretWidth;
    float fretTranslation;
    float fretHeight;
    
    // Zoom
    float zoomAnimation;
    float zoomTimestamp;
    float zoomScale;
    float zoomTranslation;
    int toFretStart;
    int toFretEnd;
    int fromZoomScale;
    int fromZoomTranslation;    
    int toZoomScale;
    int toZoomTranslation;
}

@end
