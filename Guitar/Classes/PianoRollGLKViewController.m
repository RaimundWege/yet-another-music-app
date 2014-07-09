//
//  GameGLKViewController.m
//  Guitar
//
//  Created by Raimund on 04.11.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "PianoRollGLKViewController.h"

#define FRET_MAX 22

@implementation PianoRollGLKViewController

static GLKVector3 stringColors[6];
static GLKVector3 chordColor;
static GLKVector3 chordNoteColor;
static GLKVector3 whiteColor;

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
    
    // Set colors for objects
    stringColors[0] = GLKVector3Make(255.0 / 255.0, 255.0 / 255.0, 000.0 / 255.0);
    stringColors[1] = GLKVector3Make(255.0 / 255.0, 127.0 / 255.0, 000.0 / 255.0);
    stringColors[2] = GLKVector3Make(255.0 / 255.0, 000.0 / 255.0, 000.0 / 255.0);
    stringColors[3] = GLKVector3Make(000.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0);
    stringColors[4] = GLKVector3Make(000.0 / 255.0, 127.0 / 255.0, 255.0 / 255.0);
    stringColors[5] = GLKVector3Make(000.0 / 255.0, 000.0 / 255.0, 255.0 / 255.0);
    chordColor = GLKVector3Make(192.0 / 255.0, 192.0 / 255.0, 192.0 / 255.0);
    chordNoteColor = GLKVector3Make(0.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0);
    whiteColor = GLKVector3Make(1.0, 1.0, 1.0);
    
    // Set fret resolution
    fromZoomScale = FRET_MAX;
    fromZoomTranslation = 0;
    toFretStart = 0;
    toFretEnd = FRET_MAX;
    toZoomScale = fromZoomScale;
    toZoomTranslation = fromZoomTranslation;
    zoomAnimation = 0.0;
    zoomTimestamp = 0.0;
}

- (void)setupView
{
    [super setupView];
    
    // Set size for strings
    stringHeight = screenHeight / 30.0;
    
    // Set size for fret board
    fretCount = FRET_MAX; // UIDeviceOrientationIsPortrait(self.interfaceOrientation) ? 12 : 22;
    fretWidth = screenWidth / zoomScale;
    fretTranslation = fretWidth * zoomTranslation;
    fretHeight = stringHeight * 6.0;
    
    // Set position for strings, notes and chords
    [self setPositionFor:v_string.p         x:0.0 y:0.0 width:1.0 height:stringHeight];
    [self setPositionFor:v_noteSmall.p      x:0.0 y:0.0 width:1.0 height:stringHeight];
    [self setPositionFor:v_noteBig.p        x:0.0 y:0.0 width:1.0 height:fretHeight];
    [self setPositionFor:v_chordLeft.p      x:0.0 y:0.0 width:0.5 height:fretHeight];
    [self setPositionFor:v_chordMiddle.p    x:0.0 y:0.0 width:1.0 height:fretHeight];
    [self setPositionFor:v_chordRight.p     x:0.0 y:0.0 width:0.5 height:fretHeight];

    // Set position for fret objects
    float fretHeightDivededBy8 = fretHeight / 8;
    [self setPositionFor:v_fretBoard.p      x:0.0                       y:0.0 width:screenWidth                 height:fretHeight];
    [self setPositionFor:v_fretNut.p        x:-fretHeightDivededBy8 / 2 y:0.0 width:fretHeightDivededBy8        height:fretHeight];
    [self setPositionFor:v_fret.p           x:-fretHeightDivededBy8 / 2 y:0.0 width:fretHeightDivededBy8        height:fretHeight];
    [self setPositionFor:v_fretInlay.p      x:-fretHeightDivededBy8     y:0.0 width:fretHeightDivededBy8 * 2    height:fretHeight];
}

- (void)drawView
{
    [super drawView];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    // Draw guitar
    [self drawGuitar];
    
    // Save the last note to bundle same informations
    BOOL chordActive = NO;
    float lastTime = 0.0;
    float lastY = 0.0;
    float lastAlpha = 0.0;
    int lastE2 = -1;
    int lastA2 = -1;
    int lastD3 = -1;
    int lastG3 = -1;
    int lastH3 = -1;
    int lastE4 = -1;
    int lastMin = INT_MAX;
    int lastMax = INT_MIN;
    
    // Save zoom informations
    int minFretInSpace = FRET_MAX;
    int maxFretInSpace = 0;
    
    // Draw notes
    for (NSNumber *key in [stringNotesSortedKeys reverseObjectEnumerator]) {
        float timestamp = [key floatValue]; // * 100;
        float time = (timestamp - currentTime);
        
        // Hold note on the fretboard for a short time
        time *= ANIMATION_SPEED;
        if (time >= -fretHeight && time <= (screenHeight * 8)) {
            float y = 0.0;
            float alpha = 1.0;
            
            // Assign y and alpha for time domains
            if (time < 0) {
                y = (screenHeight - fretHeight); // Note is on fret board
                alpha = 1.0;
            } else if (time <= (screenHeight * 0.5) - fretHeight) {
                y = (screenHeight - fretHeight) - time; // Note is shortly before fretboard
                alpha = 1.0;
            } else if (time <= (screenHeight * 1.5) - fretHeight) {
                float degree = ((time - ((screenHeight * 0.5) - fretHeight)) / screenHeight) * 90;
                float factor = sinf(GLKMathDegreesToRadians(degree));
                y = screenHeightHalf - (factor * screenHeightHalf); // Note is speeding up
                alpha = 1.0;
            } else if (time <= (screenHeight * 2.0) - fretHeight) {
                y = 0.0; // Note is just fading in
                alpha = 1.0 - (time - ((screenHeight * 1.5)  - fretHeight)) / ((screenHeight * 0.5) - fretHeight);
            } else {
                y = 0.0; // Note is invisible
                alpha = 0.0;
            }
            
            // Get string notes
            int e2 = -1;
            int a2 = -1;
            int d3 = -1;
            int g3 = -1;
            int h3 = -1;
            int e4 = -1;
            int minFret = INT_MAX;
            int maxFret = INT_MIN;
            NSArray *noteArray = [stringNotesDict objectForKey:key];
            for (NSDictionary *noteDict in noteArray) {
                int fret = [[noteDict valueForKey:MIDI_NOTE_FRET_KEY] intValue];
                int string = [[noteDict valueForKey:MIDI_NOTE_STRING_KEY] intValue];
                minFret = (fret == 0 ? minFret : MIN(minFret, fret));
                maxFret = MAX(maxFret, fret);
                if (string == 0) {
                    e2 = fret;
                } else if (string == 1) {
                    a2 = fret;
                } else if (string == 2) {
                    d3 = fret;
                } else if (string == 3) {
                    g3 = fret;
                } else if (string == 4) {
                    h3 = fret;
                } else if (string == 5) {
                    e4 = fret;
                }
            }
            minFretInSpace = MIN(minFretInSpace, minFret);
            maxFretInSpace = MAX(maxFretInSpace, maxFret);
            
            // Draw old chord notes
            if (chordActive) {
                if (([noteArray count] == 1) ||
                    (lastTime - time > fretHeight) ||
                    (lastE2 != e2 || lastA2 != a2 || lastD3 != d3 || lastG3 != g3 || lastH3 != h3 || lastE4 != e4)) {
                    [self drawSmallNoteOnString:0 inFret:lastE2 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
                    [self drawSmallNoteOnString:1 inFret:lastA2 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
                    [self drawSmallNoteOnString:2 inFret:lastD3 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
                    [self drawSmallNoteOnString:3 inFret:lastG3 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
                    [self drawSmallNoteOnString:4 inFret:lastH3 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
                    [self drawSmallNoteOnString:5 inFret:lastE4 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
                    chordActive = NO;
                }
            }
            
            // Draw note or chord if they are visible
            if (alpha > 0.0) {
                if ([noteArray count] == 1) {
                    
                    // This is only one note
                    NSDictionary *noteDict = [noteArray objectAtIndex:0];
                    int fret = [[noteDict valueForKey:MIDI_NOTE_FRET_KEY] intValue];
                    int string = [[noteDict valueForKey:MIDI_NOTE_STRING_KEY] intValue];
                    [self drawBigNoteOnString:string inFret:fret y:y alpha:alpha];
                    
                } else {
                    
                    // This is a chord
                    chordActive = YES;
                    if (time > 0.0) {
                        [self drawLayerFrom:minFret toFret:maxFret inColor:chordColor y:y alpha:alpha];
                    }
                }
            }
            
            // Save values
            lastTime = time;
            lastY = y;
            lastAlpha = alpha;            
            lastE2 = e2;
            lastA2 = a2;
            lastD3 = d3;
            lastG3 = g3;
            lastH3 = h3;
            lastE4 = e4;
            lastMin = minFret;
            lastMax = maxFret;
        }
    }
    
    // Draw old chord notes
    if (chordActive) {
        [self drawSmallNoteOnString:0 inFret:lastE2 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
        [self drawSmallNoteOnString:1 inFret:lastA2 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
        [self drawSmallNoteOnString:2 inFret:lastD3 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
        [self drawSmallNoteOnString:3 inFret:lastG3 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
        [self drawSmallNoteOnString:4 inFret:lastH3 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
        [self drawSmallNoteOnString:5 inFret:lastE4 fromFret:lastMin toFret:lastMax y:lastY alpha:lastAlpha];
    }
    
    // Check zoom informations
    if (zoomTimestamp <= currentTime) {
        zoomTimestamp = currentTime + (screenHeight / ANIMATION_SPEED); // next check after one screen height
        fromZoomScale = toZoomScale;
        fromZoomTranslation = toZoomTranslation;
        toFretStart = minFretInSpace;
        toFretEnd = maxFretInSpace;
        if (toFretEnd <= 9) {
            toFretStart = 0;
            toFretEnd = 9;
        } else {
            if (toFretEnd <= 12) {
                toFretStart = 0;
                toFretEnd = 12;
            } else if (toFretEnd <= 15) {
                toFretStart = (toFretStart < 3 ? 0 : 3);
                toFretEnd = 15;
            } else if (toFretEnd <= 17) {
                toFretStart = (toFretStart < 3 ? 0 : toFretStart < 5 ? 3 : 5);
                toFretEnd = 17;
            } else if (toFretEnd <= 19) {
                toFretStart = (toFretStart < 3 ? 0 : toFretStart < 5 ? 3 : toFretStart < 7 ? 5 : 7);
                toFretEnd = 19;
            } else {
                toFretStart = (toFretStart < 3 ? 0 : toFretStart < 5 ? 3 : toFretStart < 7 ? 5 : toFretStart < 9 ? 7 : 9);
                toFretEnd = 22;
            }
        }
        toZoomScale = (toFretEnd - toFretStart) + 1;
        toZoomTranslation = toFretStart - 1;
    }
    
    // Animate zoom
    zoomAnimation = (zoomTimestamp - currentTime) / (screenHeight / ANIMATION_SPEED);
    float toFactor = (cosf(GLKMathDegreesToRadians(zoomAnimation * 180)) + 1) / 2;
    float fromFactor = 1.0 - toFactor;
    zoomScale = (fromFactor * fromZoomScale) + (toFactor * toZoomScale);
    zoomTranslation = (fromFactor * fromZoomTranslation) + (toFactor * toZoomTranslation);
    fretWidth = screenWidth / zoomScale;
    fretTranslation = fretWidth * zoomTranslation;

    glDisable(GL_BLEND);
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
}

- (void)drawGuitar
{
    // Set white light color
    spriteEffect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    
    // Draw board
    spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0, screenHeight - fretHeight, 0.0);
    [spriteEffect prepareToDraw];
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_fretBoard.p);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_fretBoard.uv1);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    // Draw nut
    spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation((!isLeftHanded ? 0.0 - fretTranslation : screenWidth + fretTranslation), screenHeight - fretHeight, 0.0);
    [spriteEffect prepareToDraw];
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_fretNut.p);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_fretNut.uv1);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    // Draw frets and inlays
    for (int i = 0; i <= fretCount; i++) {
        float x = !isLeftHanded ? (i * fretWidth) - fretTranslation : (screenWidth + fretTranslation) - i * fretWidth;
        if (i != 0) {
            spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(x, screenHeight - fretHeight, 0.0);
            [spriteEffect prepareToDraw];
            glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_fret.p);
            glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_fret.uv1);
            glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        }
        if (i == 3 || i == 5 || i == 7 || i == 9 || i == 12 || i == 15 || i == 17 || i == 19 || i == 21) {
            x += (((fretWidth / 2)) * (isLeftHanded ? 1 : -1));
            spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(x, screenHeight - fretHeight, 0.0);
            [spriteEffect prepareToDraw];
            glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_fretInlay.p);
            glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, (i != 7 && i != 12 ? &v_fretInlay.uv1 : &v_fretInlay.uv2));
            glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
            
            // Set fret name
            [self drawNumber:i withColor:GLKVector4Make(1.0, 1.0, 1.0, 1.0) x:x - (GLYPH_WIDTH / (i < 10 ? 2 : 1)) y:(screenHeight - fretHeight) - GLYPH_HEIGHT];
        }
    }
    
    // Draw strings
    for (int i = 0; i < 6; i++) {
        spriteEffect.constantColor = GLKVector4MakeWithVector3(stringColors[i], 1.0);
        spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0, screenHeight - (stringHeight * (i + 1)), 0.0);
        spriteEffect.transform.modelviewMatrix = GLKMatrix4Scale(spriteEffect.transform.modelviewMatrix, screenWidth, 1.0, 1.0);
        [spriteEffect prepareToDraw];
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_string.p);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_string.uv1);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    }
}

- (void)drawBigNoteOnString:(int)string inFret:(int)fret y:(float)y alpha:(float)alpha
{
    if (string >= 0) {
        if (fret > 0) {
            
            // Draw note
            float noteLeft = 0.0;
            if (!isLeftHanded) {
                noteLeft = fretWidth * (fret - 1);
                noteLeft -= fretTranslation;
            } else {
                noteLeft = screenWidth - (fretWidth * fret);
                noteLeft += fretTranslation;
            }
            spriteEffect.constantColor = GLKVector4MakeWithVector3(stringColors[string], alpha);
            spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(noteLeft, y, 0.0);
            spriteEffect.transform.modelviewMatrix = GLKMatrix4Scale(spriteEffect.transform.modelviewMatrix, fretWidth, 1.0, 1.0);
            [spriteEffect prepareToDraw];
            glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_noteBig.p);
            glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_noteBig.uv1);
            glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
            spriteEffect.constantColor = GLKVector4MakeWithVector3(whiteColor, alpha);
            [spriteEffect prepareToDraw];
            glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_noteBig.uv2);
            glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
            
        } else {
            
            // Draw string
            spriteEffect.constantColor = GLKVector4MakeWithVector3(stringColors[string], alpha);
            spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0, y + ((5 - string) * stringHeight), 0.0);
            spriteEffect.transform.modelviewMatrix = GLKMatrix4Scale(spriteEffect.transform.modelviewMatrix, screenWidth, 1.0, 1.0);
            [spriteEffect prepareToDraw];
            glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_string.p);
            glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_string.uv2);
            glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        }
    }
}

- (void)drawSmallNoteOnString:(int)string inFret:(int)fret fromFret:(int)fretStart toFret:(int)fretEnd y:(float)y alpha:(float)alpha
{
    if (fret > 0) {
        
        // Draw note
        float noteLeft = 0.0;
        if (!isLeftHanded) {
            noteLeft = fretWidth * (fret - 1);
            noteLeft -= fretTranslation;
        } else {
            noteLeft = screenWidth - (fretWidth * fret);
            noteLeft += fretTranslation;
        }
        spriteEffect.constantColor = GLKVector4MakeWithVector3(stringColors[string], alpha);
        spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(noteLeft, y + ((5 - string) * stringHeight), 0.0);
        spriteEffect.transform.modelviewMatrix = GLKMatrix4Scale(spriteEffect.transform.modelviewMatrix, fretWidth, 1.0, 1.0);
        [spriteEffect prepareToDraw];
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_noteSmall.p);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_noteSmall.uv1);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        spriteEffect.constantColor = GLKVector4MakeWithVector3(whiteColor, alpha);
        [spriteEffect prepareToDraw];
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_noteSmall.uv2);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        
    } else if (fret == 0) {
        
        // Draw string
        float stringLeft = 0.0;
        if (!isLeftHanded) {
            stringLeft = fretWidth * (fretStart - 1);
            stringLeft -= fretTranslation;
        } else {
            stringLeft = screenWidth - (fretWidth * fretEnd);
            stringLeft += fretTranslation;
        }
        float frets = (float)(fretEnd - (fretStart - 1));
        spriteEffect.constantColor = GLKVector4MakeWithVector3(stringColors[string], alpha);
        spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(stringLeft, y + ((5 - string) * stringHeight), 0.0);
        spriteEffect.transform.modelviewMatrix = GLKMatrix4Scale(spriteEffect.transform.modelviewMatrix, frets * fretWidth, 1.0, 1.0);
        [spriteEffect prepareToDraw];
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_string.p);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_string.uv2);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    }
}

- (void)drawLayerFrom:(int)fretStart
               toFret:(int)fretEnd
              inColor:(GLKVector3)color
                    y:(float)y
                alpha:(float)alpha
{
    // Left
    float layerLeft = 0.0;
    if (!isLeftHanded) {
        layerLeft = fretWidth * (fretStart - 1);
        layerLeft -= fretTranslation;
    } else {
        layerLeft = screenWidth - (fretWidth * fretEnd);
        layerLeft += fretTranslation;
    }
    spriteEffect.constantColor = GLKVector4MakeWithVector3(color, alpha);
    spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(layerLeft, y, 0.0);
    spriteEffect.transform.modelviewMatrix = GLKMatrix4Scale(spriteEffect.transform.modelviewMatrix, fretWidth, 1.0, 1.0);
    [spriteEffect prepareToDraw];
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, v_chordLeft.p);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, v_chordLeft.uv1);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    spriteEffect.constantColor = GLKVector4MakeWithVector3(whiteColor, alpha);
    [spriteEffect prepareToDraw];
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, v_chordLeft.uv2);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    // Middle
    layerLeft += fretWidth / 2;
    float frets = fretEnd - fretStart;
    if (frets > 0) {
        spriteEffect.constantColor = GLKVector4MakeWithVector3(chordColor, alpha);
        spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(layerLeft, y, 0.0);
        spriteEffect.transform.modelviewMatrix = GLKMatrix4Scale(spriteEffect.transform.modelviewMatrix, frets * fretWidth, 1.0, 1.0);
        [spriteEffect prepareToDraw];
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, v_chordMiddle.p);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, v_chordMiddle.uv1);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        spriteEffect.constantColor = GLKVector4MakeWithVector3(whiteColor, alpha);
        [spriteEffect prepareToDraw];
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, v_chordMiddle.uv2);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    }
    
    // Right
    layerLeft += fretWidth * frets;
    spriteEffect.constantColor = GLKVector4MakeWithVector3(chordColor, alpha);
    spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(layerLeft, y, 0.0);
    spriteEffect.transform.modelviewMatrix = GLKMatrix4Scale(spriteEffect.transform.modelviewMatrix, fretWidth, 1.0, 1.0);
    [spriteEffect prepareToDraw];
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, v_chordRight.p);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, v_chordRight.uv1);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    spriteEffect.constantColor = GLKVector4MakeWithVector3(whiteColor, alpha);
    [spriteEffect prepareToDraw];
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, v_chordRight.uv2);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

@end
