//
//  GuitarGLKViewController.m
//  Guitar
//
//  Created by Raimund on 02.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "GuitarGLKViewController.h"
#import "AppDelegate.h"
#import "AudioHost.h"

@implementation GuitarGLKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set score to zero
    score = 0;
    state = GAME_STATE_START;
    self.title = @"get ready!";
    
    // Enable amplitude driven
    [[AudioHost sharedInstance] setAmplitudeDriven:YES];
    
    // Initialize context
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    // Initialize shader
    spriteEffect = [[GLKBaseEffect alloc] init];
    backgroundEffect = [[GLKBaseEffect alloc] init];
    
    // Set the frames per second
    self.preferredFramesPerSecond = FRAMES_PER_SECOND;
    
    // Get lefthanded setting
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    isLeftHanded = [appDelegate getLeftHanded];
    
    // Check the context
    if (!_context) {
        NSLog(@"Failed to create ES context");
    }
    
    // Get the view and set the context to the ES context
    GLKView *view = (GLKView *)self.view;
    view.context = _context;
    [EAGLContext setCurrentContext:_context];
    
    // Load sprite texture
    NSError *error;
    spriteTexture = [GLKTextureLoader textureWithCGImage:([UIImage imageNamed:@"sprite"].CGImage) options:nil error:&error];
    if (error) {
        NSLog(@"Couldn't load sprite texture from image: %@", error);
    } else {
        if (spriteTexture != nil) {
            spriteEffect.texture2d0.envMode = GLKTextureEnvModeModulate;
            spriteEffect.texture2d0.target = GLKTextureTarget2D;
            spriteEffect.texture2d0.name = spriteTexture.name;
        }
    }
    
    // Load background texture
    backgroundTexture = [GLKTextureLoader textureWithCGImage:([UIImage imageNamed:@"background"].CGImage) options:nil error:&error];
    if (error) {
        NSLog(@"Couldn't load background texture from image: %@", error);
    } else {
        if (backgroundTexture != nil) {
            backgroundEffect.texture2d0.envMode = GLKTextureEnvModeModulate;
            backgroundEffect.texture2d0.target = GLKTextureTarget2D;
            backgroundEffect.texture2d0.name = backgroundTexture.name;
        }
    }
    
    // Initialize texture regions
    float step = 1.0 / 32;
    [self setTextureRegionFor:v_string.uv1      x:0.0 y:step * 22 width:1.0 height:step];
    [self setTextureRegionFor:v_string.uv2      x:0.0 y:step * 23 width:1.0 height:step];
    [self setTextureRegionFor:v_fretBoard.uv1   x:0.0 y:step * 24 width:1.0 height:step * 8];
    [self setTextureRegionFor:v_fretNut.uv1     x:step * 0 y:0.0 width:step * 1 height:step * 8];
    [self setTextureRegionFor:v_fret.uv1        x:step * 1 y:0.0 width:step * 1 height:step * 8];
    [self setTextureRegionFor:v_fretInlay.uv1   x:step * 2 y:0.0 width:step * 2 height:step * 8];
    [self setTextureRegionFor:v_fretInlay.uv2   x:step * 4 y:0.0 width:step * 2 height:step * 8];
    [self setTextureRegionFor:v_note.uv1        x:step * 6  y:step * 0 width:step * 4 height:step * 4];
    [self setTextureRegionFor:v_note.uv2        x:step * 6  y:step * 0 width:step * 4 height:step * 4];
    [self setTextureRegionFor:v_noteSmall.uv1   x:step * 6  y:step * 4 width:step * 4 height:step * 4];
    [self setTextureRegionFor:v_noteSmall.uv2   x:step * 10 y:step * 4 width:step * 4 height:step * 4];
    [self setTextureRegionFor:v_noteBig.uv1     x:step * 16 y:step * 8 width:step * 4 height:step * 8];
    [self setTextureRegionFor:v_noteBig.uv2     x:step * 20 y:step * 8 width:step * 4 height:step * 8];
    [self setTextureRegionFor:v_chordLeft.uv1   x:step * 0  y:step * 8 width:step * 2 height:step * 8];
    [self setTextureRegionFor:v_chordLeft.uv2   x:step * 8  y:step * 8 width:step * 2 height:step * 8];
    [self setTextureRegionFor:v_chordMiddle.uv1 x:step * 2  y:step * 8 width:step * 4 height:step * 8];
    [self setTextureRegionFor:v_chordMiddle.uv2 x:step * 10 y:step * 8 width:step * 4 height:step * 8];
    [self setTextureRegionFor:v_chordRight.uv1  x:step * 6  y:step * 8 width:step * 2 height:step * 8];
    [self setTextureRegionFor:v_chordRight.uv2  x:step * 14 y:step * 8 width:step * 2 height:step * 8];
    
    // Explosion textures
    int x = 0;
    int y = 16;
    for (int i = 0; i < EXPLOSION_TEXTURE_COUNT; i++) {
        // left, bottom
        explosionTextures[i][0] = step * x;
        explosionTextures[i][1] = step * y;
        // left, top
        explosionTextures[i][2] = step * x;
        explosionTextures[i][3] = step * (y + 3);
        // right, top
        explosionTextures[i][4] = step * (x + 3);
        explosionTextures[i][5] = step * (y + 3);
        // right, bottom
        explosionTextures[i][6] = step * (x + 3);
        explosionTextures[i][7] = step * y;
        x += 3;
        if (i == 9) {
            x = 0;
            y += 3;
        }
    }
    
    // Initalize font
    x = GLYPH_OFFSET_X;
    y = GLYPH_OFFSET_Y;
    for (int i = 0; i < 96; i++) {
        [self setPositionFor:v_glyphs[i].p
                           x:0.0
                           y:0.0
                       width:GLYPH_WIDTH
                      height:GLYPH_HEIGHT];
        [self setTextureRegionFor:v_glyphs[i].uv1
                                x:(float)x / 512
                                y:(float)y / 512
                            width:(float)GLYPH_WIDTH / 512
                           height:(float)GLYPH_HEIGHT / 512];
        x += GLYPH_WIDTH;
        if (x >= GLYPH_OFFSET_X + GLYPHS_PER_ROW * GLYPH_WIDTH) {
            x = GLYPH_OFFSET_X;
            y += GLYPH_HEIGHT;
        }
    }
}

- (void)setTextureRegionFor:(float *)uv x:(float)x y:(float)y width:(float)width height:(float)height
{
    float vertices[] = {
        x,          y,
        x,          y + height,
        x + width,  y + height,
        x + width,  y
    };
    memcpy(uv, vertices, sizeof(vertices));
}

- (void)setPositionFor:(float *)position x:(float)x y:(float)y width:(float)width height:(float)height
{
    float vertices[] = {
        x,          y,
        x,          y + height,
        x + width,  y + height,
        x + width,  y
    };
    memcpy(position, vertices, sizeof(vertices));
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Set projection
    [self setupView];
    
    // Load the song and get all notes
    [[AudioHost sharedInstance] loadSong:_songTitle];
    stringNotesDict = [[[AudioHost sharedInstance] midiFile] getStringNotes];
    stringNotesSortedKeys = [[stringNotesDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Start playing the song
    [[AudioHost sharedInstance] playSong];
    
    // Set state to run
    state = GAME_STATE_RUN;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Stop playing the song
    [[AudioHost sharedInstance] stopSong];
}

- (void)setupView
{
    // Get view size
    screenWidth = self.view.bounds.size.width;
    screenWidthHalf = screenWidth / 2;
    screenHeight = self.view.bounds.size.height;
    screenHeightHalf = screenHeight / 2;
    
    // Set orthogonal projection matrix
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, screenWidth, screenHeight, 0, 1, -1);
    spriteEffect.transform.projectionMatrix = projectionMatrix;
    backgroundEffect.transform.projectionMatrix = projectionMatrix;
    
    // Set background
    [self setPositionFor:background.p x:-screenWidth * 0.5 y:-screenHeight * 0.5 width:screenWidth * 2 height:screenHeight * 2];
    [self setTextureRegionFor:background.uv1 x:0.0 y:0.0 width:1.0 height:1.0];
    
    // Set explosion size
    float size = 0.4 * screenHeight;
    float sizeHalf = size / 2;
    [self setPositionFor:v_explosion.p x:-sizeHalf y:-sizeHalf width:size height:size];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self setupView];
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(attackAnimation, 0.0, attackAnimation, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self drawView];
}

- (void)drawView
{
    glEnable(GL_BLEND);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    // Draw explosions
    [self drawExplosions];
    
    // Draw explosions
    [self drawExplosions];
    
    // Draw clouds
    [self drawClouds];
    
    // Change blending
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Draw current frequency and note
    [self drawText:[NSString stringWithFormat:@"FREQUENCY %.0f / MIDI %.0f", currentFrequency, currentNote] withColor:GLKVector4Make(1.0, 1.0, 1.0, 1.0) x:10 y:10];
    
    // Draw last compare
    if (lastCompare) {
        [self drawText:lastCompare withColor:GLKVector4Make(1.0, 1.0, 1.0, 1.0) x:10 y:30];
    }
    
    // Save score after song
    if (state == GAME_STATE_RUN) {
        if (![[AudioHost sharedInstance] isSongPlaying]) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            float oldScore = [appDelegate getHighscoreForSong:_songTitle];
            if (score > oldScore) {
                [appDelegate setHighscore:score forSong:_songTitle];
                gameOverText = @"YOU ARE THE BEST!";
            } else {
                gameOverText = @"NICE TRY :C";
            }
            state = GAME_STATE_END;
        }
    } else if (state == GAME_STATE_END) {
        [self drawText:gameOverText withColor:GLKVector4Make(1.0, 1.0, 1.0, 1.0) x:screenWidthHalf - (([gameOverText length] * GLYPH_WIDTH) / 2) y:screenHeightHalf - (GLYPH_HEIGHT / 2)];
    }
    
    glDisable(GL_BLEND);
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
}

- (int)getRandomNumberBetween:(int)from to:(int)to
{
    return (int)from + arc4random() % (to - from + 1);
}

- (void)drawExplosions
{
    // Change blending
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Check if new explosion animation needed
    BOOL detectEvenPercussion = [[AudioHost sharedInstance] detectEvenPercussion];
    BOOL detectOddPercussion = [[AudioHost sharedInstance] detectOddPercussion];
    if (detectEvenPercussion || detectOddPercussion) {
        for (int i = 0; i < EXPLOSION_COUNT; i++) {
            if (explosions[i].life <= 0) {
                explosions[i].x = [self getRandomNumberBetween:screenWidth * 0.3 to:screenWidth * 0.6];
                explosions[i].y = [self getRandomNumberBetween:screenHeight * 0.3 to:screenHeight * 0.6];
                explosions[i].life = EXPLOSION_LIFE;
                explosions[i].color = GLKVector4Make(0.5, 0.5, 0.5, 0.5);
                break;
            }
        }
    }
    
    // Animate explosions
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_explosion.p);
    for (int i = 0; i < EXPLOSION_COUNT; i++) {
        if (explosions[i].life > 0) {
            spriteEffect.constantColor = explosions[i].color;
            spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(explosions[i].x, explosions[i].y, 0.0);
            [spriteEffect prepareToDraw];
            int texture = EXPLOSION_TEXTURE_COUNT - (explosions[i].life / EXPLOSION_TEXTURE_FACTOR);
            if (texture >= 0 && texture < EXPLOSION_TEXTURE_COUNT) {
                glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &explosionTextures[texture][0]);
                glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
            }
            explosions[i].life--;
        }
    }
}

- (void)drawClouds
{
    glBlendFunc(GL_ONE, GL_ONE);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &background.p);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &background.uv1);
    float x = sinf(GLKMathDegreesToRadians(animation)) * screenWidthHalf;
    float y = cosf(GLKMathDegreesToRadians(animation)) * screenHeightHalf;
    backgroundEffect.constantColor = GLKVector4Make(1.0, 0.3, 0.0, 0.5);
    backgroundEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(x, y, 0.0);
    [backgroundEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    backgroundEffect.constantColor = GLKVector4Make(0.0, 0.3, 1.0, 0.5);
    backgroundEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(-x, -y, 0.0);
    [backgroundEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

- (void)drawText:(NSString *)text withColor:(GLKVector4)color x:(float)x y:(float)y
{
    int len = [text length];
    for (int i = 0; i < len; i++) {
        int c = [text characterAtIndex:i] - ' ';
        if (c < 0 || c > GLYPH_COUNT - 1)
            continue;
        spriteEffect.constantColor = color;
        spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(x, y, 0.0);
        [spriteEffect prepareToDraw];
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_glyphs[c].p);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_glyphs[c].uv1);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        x += GLYPH_WIDTH;
    }
}

- (int)drawNumber:(int)number withColor:(GLKVector4)color x:(float)x y:(float)y
{
    int c = GLYPH_NUMBER_INDEX + number % 10;
    if (number < 10) {
        [self drawGlyph:c withColor:color x:x y:y];
    } else {
        x = [self drawNumber:number / 10 withColor:color x:x y:y];
        [self drawGlyph:c withColor:color x:x y:y];
    }
    return x + GLYPH_WIDTH;
}

- (void)drawGlyph:(int)c withColor:(GLKVector4)color x:(float)x y:(float)y
{
    spriteEffect.constantColor = color;
    spriteEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(x, y, 0.0);
    [spriteEffect prepareToDraw];
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &v_glyphs[c].p);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &v_glyphs[c].uv1);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

- (void)update
{
    // Get current position of the song
    currentTime = [[AudioHost sharedInstance] getSongTime];
    
    // Background animation
    animation += 0.5;
    
    // Attack animation
    if ([[AudioHost sharedInstance] detectAttack]) {
        attackAnimation = 0.5;
    }
    attackAnimation = 0.95 * attackAnimation;
    
    // Check frequency detection
    float frequency = [[AudioHost sharedInstance] computeAutoCorrelation];
    if (frequency > 0) {
        
        // Calculate compare time limit and midi note
        currentFrequency = frequency;
        currentNote = (12 * log2f(frequency / MIDI_STANDARD_PITCH)) + MIDI_NUMBER_OFFSET;
        float minTime = currentTime - COMPARE_TIME_LIMIT;
        float maxTime = currentTime + COMPARE_TIME_LIMIT;
        
        // Save the best note between the limits
        NSNumber *bestNoteKey;
        int bestNote;
        float bestNoteTimestamp = MAXFLOAT;
        float bestNoteDifference = MAXFLOAT;
        
        // Iterate over the notes and compare them against the detected frequency
        for (int i = expectedNoteStart; i < [stringNotesSortedKeys count]; i++) {
            NSNumber *key = [stringNotesSortedKeys objectAtIndex:i];
            float timestamp = [key floatValue];
            
            // Min Time
            if (timestamp <= minTime) {
                expectedNoteStart = i;
                continue;
            }
            
            // Max Time
            if (timestamp >= maxTime) {
                break;
            }
            
            // Check only notes that are not currently evaluated
            if (![evaluatedNotes containsObject:key]) {
                
                // Get lowest note
                NSArray *noteArray = [stringNotesDict objectForKey:key];
                int note = INT_MAX;
                for (NSDictionary *noteDict in noteArray) {
                    note = MIN(note, [[noteDict valueForKey:MIDI_NOTE_PITCH_KEY] intValue]);
                }
                
                // If power chord substract one octave
                if ([noteArray count] > 1) {
                    note = note - 12;
                }
                
                // Compare notes
                float noteDifference = ABS(currentNote - note);
                if (noteDifference < bestNoteDifference) {
                    float noteTimestamp = (COMPARE_TIME_LIMIT - ABS(currentTime - timestamp)) / COMPARE_TIME_LIMIT;
                    if (noteTimestamp < bestNoteTimestamp) {
                        bestNote = note;
                        bestNoteKey = key;
                        bestNoteDifference = noteDifference;
                        bestNoteTimestamp = noteTimestamp;
                    }
                }
            }
        }
        
        // Evaluate
        if (bestNoteKey) {
            lastCompare = [NSString stringWithFormat:@"GUITAR %.0f / %d MIDI (%2.f DIFFERENCE)", currentNote, bestNote, bestNoteDifference];
            if (bestNoteDifference < COMPARE_NOTE_DIFFERENCE && bestNoteTimestamp <= 1) {
                [evaluatedNotes addObject:bestNoteKey];
                float scoreFactor = 0.5 * cosf(GLKMathDegreesToRadians(bestNoteTimestamp * 180)) + 0.5;
                score += COMPARE_NOTE_SCORE * scoreFactor;
                self.title = [NSString stringWithFormat:@"score: %d", score];
            }
        }
    }
}

@end
