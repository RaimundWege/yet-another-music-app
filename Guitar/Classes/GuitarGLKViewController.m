//
//  GuitarGLKViewController.m
//  Guitar
//
//  Created by Raimund on 02.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "GuitarGLKViewController.h"
#import "AppDelegate.h"

#define clamp(min, x, max) ((x < min) ? min : (x > max) ? max : x)

static GLKVector4 stringColors[6];
static GLKVector4 fretGridColor;
static GLKVector4 chordColor;

static int fretCount;

static float fretWidth;
static float fretMargin;
static float fretBoardHeight;
static float fretGridWidth;

static float stringHeight;

@implementation GuitarGLKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.effect = [[GLKBaseEffect alloc] init];
    self.preferredFramesPerSecond = 30;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    ah = appDelegate.audioHost;
    [ah play];
    notes = [ah.midiFile notesForTrack:3];
    
    fftLength = ah.maxFPS / 2;
    fftData = (SInt32 *)(realloc(fftData, sizeof(SInt32) * fftLength));
    l_fftData = (int32_t *)malloc(sizeof(int32_t) * fftLength);
    
    stringHeight = 0.03;
    
    fretCount = 12;
    fretWidth = 2. / fretCount;
    fretGridWidth = 0.01;
    fretMargin = fretWidth / 4;
    fretBoardHeight = stringHeight * 6;
    
    stringColors[0] = GLKVector4Make(255.0 / 255.0, 255.0 / 255.0, 000.0 / 255.0, 1.0f);
    stringColors[1] = GLKVector4Make(255.0 / 255.0, 127.0 / 255.0, 000.0 / 255.0, 1.0f);
    stringColors[2] = GLKVector4Make(255.0 / 255.0, 000.0 / 255.0, 000.0 / 255.0, 1.0f);
    stringColors[3] = GLKVector4Make(000.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0f);
    stringColors[4] = GLKVector4Make(000.0 / 255.0, 127.0 / 255.0, 255.0 / 255.0, 1.0f);
    stringColors[5] = GLKVector4Make(000.0 / 255.0, 000.0 / 255.0, 255.0 / 255.0, 1.0f);
    fretGridColor = GLKVector4Make(0.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0, 0.5f);
    chordColor = GLKVector4Make(0.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0f);
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //        +1.0 y
    //
    //          |
    // -1.0 x --+-- +1.0 x
    //          |
    //
    //        -1.0 y
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);

    [self drawStrings];
    [self drawStringMargin];
    [self drawFrets];
    
    //[self drawNote:2 inFret:3 a:y - 0.3];
    //[self drawNote:4 inFret:5 a:y];
    //[self drawNote:1 inFret:9 a:y - 0.7];
    //[self drawChord:3 toFret:5 a:y - 0.5];
    
	for (NSDictionary *note in notes) {
		float timestamp = [[note valueForKey:MIDINoteTimestampKey] floatValue];
		//int pitch = [[note valueForKey:MIDINotePitchKey] intValue] - 36; // cover only 4 octaves
		//float duration = [[note valueForKey:MIDINoteDurationKey] floatValue];
		//int trackIndex = [[note valueForKey:MIDINoteTrackIndexKey] intValue];
		int fret = [[note valueForKey:MIDINoteFretKey] intValue];
        int string = [[note valueForKey:MIDINoteStringKey] intValue];
        [self drawNote:string inFret:fret a:(timestamp - currentTime) - 1];
	}
    
    glDisable(GL_BLEND);
    glDisableVertexAttribArray(GLKVertexAttribPosition);
}

- (void)drawStrings
{
    for (int i = 0; i < 6; i++) {
        float translate = stringHeight * i;
        float vertices[] = {
            -1.00, -1.00 + translate,
            +1.00, -1.00 + translate,
            -1.00, -1.00 + translate + stringHeight,
            +1.00, -1.00 + translate + stringHeight
        };
        self.effect.useConstantColor = GL_TRUE;
        self.effect.constantColor = stringColors[i];
        [self.effect prepareToDraw];
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
}

- (void)drawStringMargin
{
    for (int i = 0; i < 7; i++) {
        float translate = stringHeight * i;
        float vertices[] = {
            -1.00, -1.00 + translate,
            +1.00, -1.00 + translate
        };
        self.effect.useConstantColor = GL_TRUE;
        self.effect.constantColor = fretGridColor;
        [self.effect prepareToDraw];
        glEnable(GL_LINE_SMOOTH);
        glLineWidth(3.0);
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
        glDrawArrays(GL_LINE_STRIP, 0, 2);
    }
}

- (void)drawFrets
{
    float fretGridWidthHalf = fretGridWidth / 2;
    for (int i = 0; i <= fretCount; i++) {
        float translate = fretWidth * i;
        float vertices[] = {
            -1.00 - fretGridWidthHalf + translate, -1.00,
            -1.00 + fretGridWidthHalf + translate, -1.00,
            -1.00 - fretGridWidthHalf + translate, +1.00,
            -1.00 + fretGridWidthHalf + translate, +1.00
        };
        self.effect.useConstantColor = GL_TRUE;
        self.effect.constantColor = fretGridColor;
        [self.effect prepareToDraw];
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
}

- (void)drawNote:(int)note inFret:(int)fret a:(float)a
{
    float noteLeft = -1. + (fretWidth * fret) + fretMargin;
    float noteRight = -1. + (fretWidth * (fret + 1)) - fretMargin;
    float vertices[] = {
        noteLeft,   a,                      // unten links
        noteRight,  a,                      // unten rechts
        noteLeft,   a + fretBoardHeight,    // oben links
        noteRight,  a + fretBoardHeight     // oben rechts
    };
    self.effect.useConstantColor = GL_TRUE;
    self.effect.constantColor = stringColors[note];
    [self.effect prepareToDraw];
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)drawChord:(int)fretStart toFret:(int)fretEnd a:(float)a
{
    float chordLeft = -1. + fretWidth * fretStart + fretMargin;
    float chordRight = -1. + fretWidth * (fretEnd + 1) - fretMargin;
    float vertices[] = {
        chordLeft,  a,                      // unten links
        chordRight, a,                      // unten rechts
        chordLeft,  a + fretBoardHeight,    // oben links
        chordRight, a + fretBoardHeight     // oben rechts
    };
    self.effect.useConstantColor = GL_TRUE;
    self.effect.constantColor = chordColor;
    [self.effect prepareToDraw];
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)update
{
    currentTime = [ah.midiFile getTime];
    
    if ([ah computeFFT:l_fftData]) {
        //NSLog(@"compute");
        
        
        /*memmove(fftData, l_fftData, sizeof(Float32) * fftLength);
        float dominantFrequency = 0;
		int bin = -1;
		for (int i = 0; i < fftLength; i += 2) {
			float curFreq = [self magnitudeSquaredX:fftData[i] andY:fftData[i+1]];
			if (curFreq > dominantFrequency) {
				dominantFrequency = curFreq;
				bin = (i + 1) / 2;
			}
		}
        NSLog(@"compute %i", bin);*/
    }
}

- (float)magnitudeSquaredX:(SInt32)x andY:(SInt32)y
{
	return ((x * x) + (y * y));
}

@end
