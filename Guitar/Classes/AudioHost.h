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
    
    // FFT
    volatile int32_t    mNeedsAudioData;
    volatile int32_t    mHasAudioData;
    FFTSetup            mSpectrumAnalyse;
    DSPSplitComplex     mDspSplitComplex;
    Float32             *mAudioBuffer;
    Float32             mFFTNormFactor;
    Float32             mAdjust0DB;
    Float32             m24BitFracScale;
    UInt32              mNumberFrames;
    UInt32              mFFTLength;
    UInt32              mLog2N;
    UInt32              mAudioBufferSize;
    int32_t             mAudioBufferCurrentIndex;
    
    
    
    // N = number of samples in your buffer
    //int N = _audioSample.capacity();
    Float32             *mHammingWindow;
    // allocate space for a hamming window
    //float* hammingWindow = (float *) malloc(sizeof(float) * N);



} EffectState;

@interface AudioHost : NSObject {
@private
    Float64 hardwareSampleRate;
}

@property (readwrite) AUGraph processingGraph;

@property (readwrite) AudioUnit samplerUnit1;
@property (readwrite) AudioUnit samplerUnit2;
@property (readwrite) AudioUnit samplerUnit3;
@property (readwrite) AudioUnit samplerUnit4;
@property (readwrite) AudioUnit samplerUnit5;
@property (readwrite) AudioUnit distortionUnit;
@property (readwrite) AudioUnit converterUnit;
@property (readwrite) AudioUnit mixerUnit;
@property (readwrite) AudioUnit rioUnit;

@property (readwrite) MIDIFile *midiFile;
@property (assign) EffectState effectState;

+ (id)audioHost;

- (void)start;
- (void)play;
- (BOOL)computeFFT:(int32_t *)outFFTData;
- (UInt32)maxFPS;

@end
