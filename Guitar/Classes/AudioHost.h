//
//  AudioHost.h
//  Guitar
//
//  Created by Raimund on 01.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import <AudioToolbox/MusicPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "MIDIFile.h"

#include <libkern/OSAtomic.h>

typedef struct {
    AudioUnit rioUnit;
    BOOL isAmplitudeDriven;
    Float32 maxAmplitude;
    Float32 x;
    Float32 y;
    
    // General
    volatile int32_t needsAudioData;
    volatile int32_t hasAudioData;
    volatile int32_t detectAttack;
    volatile int32_t detectMute;
    
    // Audio buffer
    Float32 *audioBuffer;
    UInt32  audioBufferSize;
    UInt32  audioBufferCurrentIndex;
} RenderInputState;

typedef struct {
    AudioUnit percussionSamplerUnit;
    
    // General
    volatile int32_t detectEvenNote;
    volatile int32_t detectOddNote;
} PercussionState;

@interface AudioHost : NSObject {
@private
    Float64 hardwareSampleRate;
    
    // Hamming
    Float32         *hammingWindow;
    
    // Frequency
    UInt32          numberFrames;
    UInt32          minFrequency;
    UInt32          maxFrequency;
    
    // Cepstrum
    FFTSetup        cepstrumAnalyse;
    DSPSplitComplex cepstrumSplitComplex;
    Float32         cepstrumFFTNormFactor;
    UInt32          cepstrumFFTLength;
    UInt32          cepstrumLog2N;

    // AutoCorrelation
    FFTSetup        autoCorrelationAnalyse;
    DSPSplitComplex autoCorrelationSplitComplexFW;
    DSPSplitComplex autoCorrelationSplitComplexBW;
    UInt32          autoCorrelationTwiceFFTLength;
    UInt32          autoCorrelationTwiceLog2N;    
}

@property (readwrite) AUGraph processingGraph;

@property (readwrite) AUNode stringE2Node;
@property (readwrite) AUNode stringA2Node;
@property (readwrite) AUNode stringD3Node;
@property (readwrite) AUNode stringG3Node;
@property (readwrite) AUNode stringH3Node;
@property (readwrite) AUNode stringE4Node;
@property (readwrite) AUNode keyboardSamplerNode;
@property (readwrite) AUNode distortionSamplerNode;
@property (readwrite) AUNode bassSamplerNode;
@property (readwrite) AUNode overdriveSamplerNode;
@property (readwrite) AUNode percussionSamplerNode;
@property (readwrite) AUNode distortionNode;
@property (readwrite) AUNode stringMixerNode;
@property (readwrite) AUNode masterMixerNode;
@property (readwrite) AUNode rioNode;

@property (readwrite) AudioUnit stringE2Unit;
@property (readwrite) AudioUnit stringA2Unit;
@property (readwrite) AudioUnit stringD3Unit;
@property (readwrite) AudioUnit stringG3Unit;
@property (readwrite) AudioUnit stringH3Unit;
@property (readwrite) AudioUnit stringE4Unit;
@property (readwrite) AudioUnit keyboardSamplerUnit;
@property (readwrite) AudioUnit distortionSamplerUnit;
@property (readwrite) AudioUnit bassSamplerUnit;
@property (readwrite) AudioUnit overdriveSamplerUnit;
@property (readwrite) AudioUnit percussionSamplerUnit;
@property (readwrite) AudioUnit distortionUnit;
@property (readwrite) AudioUnit stringMixerUnit;
@property (readwrite) AudioUnit masterMixerUnit;
@property (readwrite) AudioUnit rioUnit;

@property (readwrite) MIDIFile *midiFile;
@property (assign) RenderInputState ris;
@property (assign) PercussionState ps;

+ (id)sharedInstance;

- (BOOL)isSongPlaying;
- (void)loadSong:(NSString *)song;
- (void)playSong;
- (void)stopSong;
- (float)getSongTime;

- (void)startRIO;
- (void)stopRIO;

- (BOOL)detectAttack;
- (BOOL)detectMute;
- (BOOL)detectEvenPercussion;
- (BOOL)detectOddPercussion;

- (float)computeCepstrum;
- (float)computeAutoCorrelation;

- (UInt32)maxFPS;

- (void)setAmplitudeDriven:(BOOL)enable;
- (void)setStringVolume:(AudioUnitParameterValue)volume;
- (void)setGuitarVolume:(AudioUnitParameterValue)volume;

void CheckError(OSStatus error, const char *operation);

@end
