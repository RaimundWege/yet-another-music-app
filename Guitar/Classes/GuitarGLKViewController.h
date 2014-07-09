//
//  GuitarGLKViewController.h
//  Guitar
//
//  Created by Raimund on 02.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "AudioHost.h"

// Values for character picking in sprite texture
#define GLYPH_OFFSET_X 224
#define GLYPH_OFFSET_Y 0
#define GLYPHS_PER_ROW 16
#define GLYPH_COUNT 96
#define GLYPH_WIDTH 16
#define GLYPH_HEIGHT 20
#define GLYPH_NUMBER_INDEX 16

// Animation parameter
#define FRAMES_PER_SECOND 60
#define ATTACK_ANIMATION_INTENSITY 0.5
#define ANIMATION_SPEED 100

// Explosion parameter
#define EXPLOSION_COUNT 30
#define EXPLOSION_LIFE 60
#define EXPLOSION_TEXTURE_COUNT 20
#define EXPLOSION_TEXTURE_FACTOR (EXPLOSION_LIFE / EXPLOSION_TEXTURE_COUNT)

// Compare parameter
#define COMPARE_TIME_LIMIT 0.5
#define COMPARE_NOTE_DIFFERENCE 0.5
#define COMPARE_NOTE_SCORE 100
#define MIDI_STANDARD_PITCH 440 // 440 Hz
#define MIDI_NUMBER_OFFSET 69 // MIDI Note A4 (440 Hz)

// Game parameter
#define GAME_STATE_START 0
#define GAME_STATE_RUN 1
#define GAME_STATE_SAVE 2
#define GAME_STATE_END 3

typedef struct {
    GLfloat p[8];
    GLfloat uv1[8];
    GLfloat uv2[8];
} VertexStruct;

typedef struct {
    int x;
    int y;
    int life;
    GLKVector4 color;
} ParticleStruct;

@interface GuitarGLKViewController : GLKViewController {
@private
    
    int score;
    float state;
    float animation;
    float attackAnimation;
    float currentFrequency;
    float currentNote;
    NSString *gameOverText;
    NSString *lastCompare;
    VertexStruct background;
    ParticleStruct explosions[30];
    float explosionTextures[20][8];
    
@public
    
    float currentTime;
    float screenWidth;
    float screenWidthHalf;
    float screenHeight;
    float screenHeightHalf;
    
    BOOL isLeftHanded;

    // Texture regions
    VertexStruct v_string;
    VertexStruct v_fretBoard;
    VertexStruct v_fretNut;
    VertexStruct v_fret;
    VertexStruct v_fretInlay;
    VertexStruct v_note;
    VertexStruct v_noteSmall;
    VertexStruct v_noteBig;
    VertexStruct v_chordLeft;
    VertexStruct v_chordMiddle;
    VertexStruct v_chordRight;
    VertexStruct v_glyphs[96];
    VertexStruct v_explosion;
    
    NSDictionary *stringNotesDict;
    NSArray *stringNotesSortedKeys;
    NSMutableSet *evaluatedNotes;
    int expectedNoteStart;
    
    GLKTextureInfo *spriteTexture;
    GLKTextureInfo *backgroundTexture;
    
    GLKBaseEffect *spriteEffect;
    GLKBaseEffect *backgroundEffect;
}

@property (strong, nonatomic) EAGLContext *context;

@property (readwrite) NSString *songTitle;

- (void)setTextureRegionFor:(float *)uv x:(float)x y:(float)y width:(float)width height:(float)height;
- (void)setPositionFor:(float *)position x:(float)x y:(float)y width:(float)width height:(float)height;

- (void)drawView;
- (void)drawText:(NSString *)text withColor:(GLKVector4)color x:(float)x y:(float)y;
- (int)drawNumber:(int)number withColor:(GLKVector4)color x:(float)x y:(float)y;
- (void)setupView;

@end
