//
//  TabulatureGLKViewController.m
//  Guitar
//
//  Created by Raimund on 04.11.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "TabulatureGLKViewController.h"

#define ANIMATION_WINDOW 1.5

@implementation TabulatureGLKViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)setupView
{
    [super setupView];
    
    // Set size for strings
    stringHeight = screenHeight / 8.0;
    stringHeightHalf = stringHeight / 2;
    stringHeightQuarter = stringHeightHalf / 2;
    
    // Set size for fret board
    fretHeight = stringHeight * 6.0;
    fretHeightHalf = fretHeight / 2;
    
    // Set position for all objects
    [self setPositionFor:v_string.p         x:0.0 y:0.0 width:screenWidth height:stringHeight];
    [self setPositionFor:v_fretBoard.p      x:0.0 y:0.0 width:screenWidth height:fretHeight];
    float fretHeightDivededBy8 = fretHeight / 8;
    [self setPositionFor:v_fretNut.p        x:-fretHeightDivededBy8 / 2 y:0.0 width:fretHeightDivededBy8 height:fretHeight];
    [self setPositionFor:v_note.p           x:-stringHeightHalf y:-stringHeightHalf width:stringHeight height:stringHeight];
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
    
    // Draw notes
    for (NSNumber *key in [stringNotesSortedKeys reverseObjectEnumerator]) {
        float timestamp = [key floatValue];
        float time = (timestamp - currentTime);
        
        // Hold note on the nut for a short time
        time *= ANIMATION_SPEED;
        time = (time >= -0.25 && time < 0.0 ? 0.0 : time);
        if (time >= 0.0 && time <= screenWidth + stringHeight) {

            // Get string notes
            NSArray *noteArray = [stringNotesDict objectForKey:key];
            for (NSDictionary *noteDict in noteArray) {
                int fret = [[noteDict valueForKey:MIDI_NOTE_FRET_KEY] intValue];
                int string = [[noteDict valueForKey:MIDI_NOTE_STRING_KEY] intValue];
                float x = time;
                float y = (screenHeightHalf + fretHeightHalf) - stringHeightHalf - (string * stringHeight);
                if (isLeftHanded) {
                    x = screenWidth - x;
                }
                
                // Draw note
                spriteEffect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
                spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(x, y, 0.0);
                [spriteEffect prepareToDraw];
                glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_note.p);
                glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_note.uv1);
                glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
                
                // Draw text on note
                NSString *noteText = [NSString stringWithFormat:@"%d", fret];
                float noteTextX = x - ([noteText length] * (GLYPH_WIDTH / 2));
                float noteTextY = y - GLYPH_HEIGHT / 2;
                [self drawText:noteText withColor:GLKVector4Make(0.0, 0.0, 0.0, 1.0) x:noteTextX y:noteTextY];
                
                // Draw glossy effect on note
                spriteEffect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 0.5);
                spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(x, y, 0.0);
                [spriteEffect prepareToDraw];
                glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_note.p);
                glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_note.uv2);
                glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
            }
        }
    }
    
    glDisable(GL_BLEND);
    glDisableVertexAttribArray(GLKVertexAttribPosition);
}

- (void)drawGuitar
{
    // Set white light color
    spriteEffect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    
    // Draw board
    float y = screenHeightHalf - fretHeightHalf;
    spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0, y, 0.0);
    [spriteEffect prepareToDraw];
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_fretBoard.p);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_fretBoard.uv1);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    // Draw nut
    if (isLeftHanded) {
        spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(screenWidth, y, 0.0);
        [spriteEffect prepareToDraw];
    }
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_fretNut.p);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_fretNut.uv1);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    // Draw strings
    for (int i = 0; i < 6; i++) {
        spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0, y, 0.0);
        [spriteEffect prepareToDraw];
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_string.p);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_string.uv1);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        y += stringHeight;
    }
}

@end
