//
//  AudioHost.m
//  Guitar
//
//  Created by Raimund on 01.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "AudioHost.h"

@implementation AudioHost

#pragma mark Constructor

+ audioHost
{
    return [[self alloc] initAudioHost];
}

- (id) initAudioHost
{
	if ((self = [self init])) {
        
	}
	return self;
}

#pragma mark Control

- (void)start
{
    // Setup the audio session
    [self setupAudioSession];
    
    // Create the audio processing graph
    [self createAUGraph];
    
    // Initialize the audio processing graph.
    CheckError(AUGraphInitialize(self.processingGraph),
               "Couldn't initialze audio processing graph");
    
    // Start the graph
    CheckError(AUGraphStart(self.processingGraph),
               "Couldn't start audio processing graph");
}

#pragma mark AUGraph

- (void)createAUGraph
{
    // Instantiate an audio processing graph
    CheckError(NewAUGraph(&_processingGraph),
               "Unable to create an AUGraph object");
    NSLog(@"AUGraph created!");
    
    // Specify the common portion of an audio unit's identify, used for all units in the graph
	AudioComponentDescription cd = {};
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
    cd.componentFlags = 0;
	cd.componentFlagsMask = 0;
    
    // Specify the RIO unit and add the RIO unit node to the graph
    AUNode rioNode;
    cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;
	CheckError(AUGraphAddNode(self.processingGraph, &cd, &rioNode),
               "Couldn't add the RIO unit to the audio processing graph");
    
    // Specify the Distortion unit and add the Distortion unit node to the graph
    AUNode distortionNode;
    cd.componentType = kAudioUnitType_Effect;
    cd.componentSubType = kAudioUnitSubType_Distortion;
    CheckError(AUGraphAddNode(self.processingGraph, &cd, &distortionNode),
               "Couldn't add the Distortion unit to the audio processing graph");
    
    // Specify the Sampler units and add the Sampler unit nodes to the graph
    AUNode samplerNode1, samplerNode2, samplerNode3, samplerNode4, samplerNode5;
	cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_Sampler;
	CheckError(AUGraphAddNode(self.processingGraph, &cd, &samplerNode1),
               "Couldn't add the Sampler 1 unit to the audio processing graph");
    CheckError(AUGraphAddNode(self.processingGraph, &cd, &samplerNode2),
               "Couldn't add the Sampler 2 unit to the audio processing graph");
    CheckError(AUGraphAddNode(self.processingGraph, &cd, &samplerNode3),
               "Couldn't add the Sampler 3 unit to the audio processing graph");
    CheckError(AUGraphAddNode(self.processingGraph, &cd, &samplerNode4),
               "Couldn't add the Sampler 4 unit to the audio processing graph");
    CheckError(AUGraphAddNode(self.processingGraph, &cd, &samplerNode5),
               "Couldn't add the Sampler 5 unit to the audio processing graph");
    
    // Specify the Mixer unit and add the Mixer unit node to the graph
    AUNode mixerNode;
    cd.componentType = kAudioUnitType_Mixer;
    cd.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    CheckError(AUGraphAddNode(self.processingGraph, &cd, &mixerNode),
               "Couldn't add the Mixer unit to the audio processing graph");
    
    // Open the audio processing graph
	CheckError(AUGraphOpen(self.processingGraph),
               "Couldn't open the audio processing graph");
    NSLog(@"AUGraph opened!");
    
    // ______                     _      _____ _____
    // | ___ \                   | |    |_   _|  _  |
    // | |_/ /___ _ __ ___   ___ | |_ ___ | | | | | |
    // |    // _ \ '_ ` _ \ / _ \| __/ _ \| | | | | |
    // | |\ \  __/ | | | | | (_) | ||  __/| |_\ \_/ /
    // \_| \_\___|_| |_| |_|\___/ \__\___\___/ \___/
    
    // Obtain the RIO unit instance from its corresponding node
    CheckError(AUGraphNodeInfo(self.processingGraph, rioNode, NULL, &_rioUnit),
               "Couldn't obtain RIO unit from its corresponding node");
    
    // Setup the RIO unit for playback (to hardware?)
	UInt32 oneFlag = 1;
	AudioUnitElement bus0 = 0;
	CheckError(AudioUnitSetProperty(_rioUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output,
                                    bus0,
                                    &oneFlag,
                                    sizeof(oneFlag)),
			   "Couldn't enable RIO output");
	
	// Enable RIO input (from hardware?)
	AudioUnitElement bus1 = 1;
	CheckError(AudioUnitSetProperty(_rioUnit,
									kAudioOutputUnitProperty_EnableIO,
									kAudioUnitScope_Input,
									bus1,
									&oneFlag,
									sizeof(oneFlag)),
			   "Couldn't enable RIO input");
    
    // Setup an ASBD in the iPhone canonical format
    AudioStreamBasicDescription rioASBD;
	memset(&rioASBD, 0, sizeof(rioASBD));
    rioASBD.mSampleRate         = hardwareSampleRate;
    rioASBD.mFormatID           = kAudioFormatLinearPCM;
	/*rioASBD.mFormatFlags        = kAudioFormatFlagsCanonical;
    rioASBD.mBytesPerPacket     = 2;
	rioASBD.mFramesPerPacket    = 1;
    rioASBD.mBytesPerFrame      = rioASBD.mBytesPerPacket * rioASBD.mFramesPerPacket;
	rioASBD.mBitsPerChannel     = 8 * rioASBD.mBytesPerPacket;
	rioASBD.mChannelsPerFrame   = 1;*/
	/*rioASBD.mFormatFlags      = kAudioFormatFlagsCanonical;
	rioASBD.mBytesPerPacket     = 2;
	rioASBD.mFramesPerPacket    = 1;
	rioASBD.mBytesPerFrame      = 2; // = mBytesPerPacket * mFramesPerPacket
	rioASBD.mChannelsPerFrame   = 1;
	rioASBD.mBitsPerChannel     = 16;*/
    /*rioASBD.mFormatFlags      = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
    rioASBD.mBytesPerPacket     = bytesPerSample;
    rioASBD.mFramesPerPacket    = 1;
    rioASBD.mBytesPerFrame      = bytesPerSample * 1; // = mBytesPerPacket * mFramesPerPacket
    rioASBD.mChannelsPerFrame   = 1;
    rioASBD.mBitsPerChannel     = 8 * bytesPerSample;*/
    size_t bytesPerSample       = sizeof(float);
    rioASBD.mFormatFlags        = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked |kAudioFormatFlagIsNonInterleaved;
    rioASBD.mBytesPerPacket     = bytesPerSample;
    rioASBD.mFramesPerPacket    = 1;
    rioASBD.mBytesPerFrame      = rioASBD.mBytesPerPacket * rioASBD.mFramesPerPacket;
    rioASBD.mChannelsPerFrame   = 1;
    rioASBD.mBitsPerChannel     = 8 * bytesPerSample;
    [self printASBD:rioASBD withName:@"RIO unit"];
    
    // Set ASBD for input (microphone) on RIO's output scope (bus 1)
	CheckError(AudioUnitSetProperty(_rioUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    bus1,
                                    &rioASBD,
                                    sizeof(rioASBD)),
			   "Couldn't set ASBD for RIO on output scope / bus 1");
    
	// Set ASBD for output (speaker) on RIO's input scope (bus 0)
	CheckError(AudioUnitSetProperty(_rioUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    bus0,
                                    &rioASBD,
                                    sizeof(rioASBD)),
			   "Couldn't set ASBD for RIO on input scope / bus 0");
 
    // Initialize and start RIO unit
	CheckError(AudioUnitInitialize(_rioUnit),
			   "Couldn't initialize RIO unit");
    NSLog(@"RIO unit initialized!");
	CheckError(AudioOutputUnitStart(_rioUnit),
               "Couldn't start RIO unit");
	NSLog(@"RIO unit started!");
    
    // ______ _     _             _   _
    // |  _  (_)   | |           | | (_)
    // | | | |_ ___| |_ ___  _ __| |_ _  ___  _ __
    // | | | | / __| __/ _ \| '__| __| |/ _ \| '_ \
    // | |/ /| \__ \ || (_) | |  | |_| | (_) | | | |
    // |___/ |_|___/\__\___/|_|   \__|_|\___/|_| |_|
    
    // Obtain the Distortion unit instance from its corresponding node
    CheckError(AUGraphNodeInfo(self.processingGraph, distortionNode, NULL, &_distortionUnit),
               "Couldn't obtain Distortion unit from its corresponding node");
    
    // Set ASBD for Distortion's input scope (bus 0)
    CheckError(AudioUnitSetProperty(_distortionUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    bus0,
                                    &rioASBD,
                                    sizeof(rioASBD)),
               "Couldn't set ASBD for Distortion on input scope / bus 0");
    
    // Set ASBD for Distortion's output scope (bus 0)
    CheckError(AudioUnitSetProperty(_distortionUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    bus0,
                                    &rioASBD,
                                    sizeof(rioASBD)),
               "Couldn't set ASBD for Distortion on output scope / bus 0");
    
    // Get the maximum frames per slices from the RIO unit
    UInt32 maxFPS;
    UInt32 maxFPSSize = sizeof(maxFPS);
    CheckError(AudioUnitGetProperty(_rioUnit,
                                    kAudioUnitProperty_MaximumFramesPerSlice,
                                    kAudioUnitScope_Global,
                                    bus0,
                                    &maxFPS,
                                    &maxFPSSize),
               "Couldn't get the RIO unit's maximum frames per slice");
    
    // Set the struct for the effect state with all FFT variables
    _effectState.rioUnit = _rioUnit;
    _effectState.mNumberFrames = maxFPS;
    _effectState.mFFTNormFactor = 1.0 / (2 * _effectState.mNumberFrames);
    _effectState.mFFTLength = _effectState.mNumberFrames / 2;
    _effectState.mAdjust0DB = 1.5849e-13;
    _effectState.m24BitFracScale = 16777216.0f;
    _effectState.mLog2N = log2(_effectState.mNumberFrames);
    _effectState.mAudioBufferSize = _effectState.mNumberFrames * sizeof(Float32);
    _effectState.mAudioBufferCurrentIndex = 0;
    _effectState.mAudioBuffer = (Float32 *)calloc(_effectState.mNumberFrames, sizeof(Float32));
    _effectState.mDspSplitComplex.realp = (Float32 *)calloc(_effectState.mFFTLength, sizeof(Float32));
    _effectState.mDspSplitComplex.imagp = (Float32 *)calloc(_effectState.mFFTLength, sizeof(Float32));
    _effectState.mSpectrumAnalyse = vDSP_create_fftsetup(_effectState.mLog2N, kFFTRadix2);
    
    // generate the window values and store them in the hamming window buffer    
    _effectState.mHammingWindow = (Float32 *)calloc(_effectState.mNumberFrames, sizeof(Float32));
    vDSP_hamm_window(_effectState.mHammingWindow, _effectState.mNumberFrames, 0);
    
    OSAtomicIncrement32Barrier(&_effectState.mNeedsAudioData);
    
    // Set callback function
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = InputRenderCallback;
	callbackStruct.inputProcRefCon = &_effectState;
    CheckError(AUGraphSetNodeInputCallback(_processingGraph,
                                           distortionNode,
                                           bus0,
                                           &callbackStruct),
               "Couldn't set Distortion input render callback on bus 0");
    
    // Initialize Distortion unit
	CheckError(AudioUnitInitialize(_distortionUnit),
			   "Couldn't initialize Distortion unit");
    NSLog(@"Distortion unit initialized!");
    
    //  _____                       _
    // /  ___|                     | |
    // \ `--.  __ _ _ __ ___  _ __ | | ___ _ __
    //  `--. \/ _` | '_ ` _ \| '_ \| |/ _ \ '__|
    // /\__/ / (_| | | | | | | |_) | |  __/ |
    // \____/ \__,_|_| |_| |_| .__/|_|\___|_|
    //                       | |
    //                       |_|
    
    // Obtain references to all of the Sampler units from their nodes
    CheckError(AUGraphNodeInfo(self.processingGraph, samplerNode1, 0, &_samplerUnit1),
               "Couldn't obtain Sampler 1 unit from its corresponding node");
    CheckError(AUGraphNodeInfo(self.processingGraph, samplerNode2, 0, &_samplerUnit2),
               "Couldn't obtain Sampler 2 unit from its corresponding node");
    CheckError(AUGraphNodeInfo(self.processingGraph, samplerNode3, 0, &_samplerUnit3),
               "Couldn't obtain Sampler 3 unit from its corresponding node");
    CheckError(AUGraphNodeInfo(self.processingGraph, samplerNode4, 0, &_samplerUnit4),
               "Couldn't obtain Sampler 4 unit from its corresponding node");
    CheckError(AUGraphNodeInfo(self.processingGraph, samplerNode5, 0, &_samplerUnit5),
               "Couldn't obtain Sampler 5 unit from its corresponding node");
    
    // ___  ____
    // |  \/  (_)
    // | .  . |___  _____ _ __
    // | |\/| | \ \/ / _ \ '__|
    // | |  | | |>  <  __/ |
    // \_|  |_/_/_/\_\___|_|
    
    // Obtain the Mixer unit instance from its corresponding node
    CheckError(AUGraphNodeInfo(self.processingGraph, mixerNode, NULL, &_mixerUnit),
               "Couldn't obtain Mixer unit from its corresponding node");
    
    // Set the bus count for the mixer
    UInt32 numBuses = 6;
    CheckError(AudioUnitSetProperty(_mixerUnit,
                                    kAudioUnitProperty_ElementCount,
                                    kAudioUnitScope_Input,
                                    0,
                                    &numBuses,
                                    sizeof(numBuses)),
               "Couldn't set the bus count for the Mixer unit");
    
    //  _____                             _   _
    // /  __ \                           | | (_)
    // | /  \/ ___  _ __  _ __   ___  ___| |_ _  ___  _ __  ___
    // | |    / _ \| '_ \| '_ \ / _ \/ __| __| |/ _ \| '_ \/ __|
    // | \__/\ (_) | | | | | | |  __/ (__| |_| | (_) | | | \__ \
    //  \____/\___/|_| |_|_| |_|\___|\___|\__|_|\___/|_| |_|___/
    
    // Connect the Sampler units with the Mixer unit
    CheckError(AUGraphConnectNodeInput(self.processingGraph, samplerNode1, 0, mixerNode, 1),
               "Couldn't connect the Sampler 1 unit with the Mixer unit");
    CheckError(AUGraphConnectNodeInput(self.processingGraph, samplerNode2, 0, mixerNode, 2),
               "Couldn't connect the Sampler 2 unit with the Mixer unit");
    CheckError(AUGraphConnectNodeInput(self.processingGraph, samplerNode3, 0, mixerNode, 3),
               "Couldn't connect the Sampler 3 unit with the Mixer unit");
    CheckError(AUGraphConnectNodeInput(self.processingGraph, samplerNode4, 0, mixerNode, 4),
               "Couldn't connect the Sampler 4 unit with the Mixer unit");
    CheckError(AUGraphConnectNodeInput(self.processingGraph, samplerNode5, 0, mixerNode, 5),
               "Couldn't connect the Sampler 5 unit with the Mixer unit");
    
    // Connect the Distortion with the Mixer
    CheckError(AUGraphConnectNodeInput(self.processingGraph, distortionNode, 0, mixerNode, 0),
               "Couldn't connect the Distortion unit with the Mixer unit");
    
    // Connect the Mixer unit to the RIO unit
    CheckError(AUGraphConnectNodeInput(self.processingGraph, mixerNode, 0, rioNode, 0),
               "Couldn't connect the Mixer unit with the RIO unit");
    
    //  _____                       _  __            _
    // /  ___|                     | |/ _|          | |
    // \ `--.  ___  _   _ _ __   __| | |_ ___  _ __ | |_ ___
    //  `--. \/ _ \| | | | '_ \ / _` |  _/ _ \| '_ \| __/ __|
    // /\__/ / (_) | |_| | | | | (_| | || (_) | | | | |_\__ \
    // \____/ \___/ \__,_|_| |_|\__,_|_| \___/|_| |_|\__|___/
    
    // Load the sound font from file
    NSURL *presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"instruments" ofType:@"sf2"]];
    
    // Initialise the sound font
    [self setDLSOrSoundFontFor:self.samplerUnit1 fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:30]; // Distortion
    [self setDLSOrSoundFontFor:self.samplerUnit2 fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:30]; // Distortion
    [self setDLSOrSoundFontFor:self.samplerUnit3 fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:33]; // Fingered Bass
    [self setDLSOrSoundFontFor:self.samplerUnit4 fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:29]; // Overdrive
    [self setDLSOrSoundFontFor:self.samplerUnit5 fromURL:presetURL bankMSB:kAUSampler_DefaultPercussionBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:0]; // Percussion
    
    // Print out the graph to the console
    CAShow(self.processingGraph);
}

- (void)setDLSOrSoundFontFor:(AudioUnit)audioUnit fromURL:(NSURL *)bankURL bankMSB:(UInt8)bankMSB bankLSB:(UInt8)bankLSB withPatch:(int)presetNumber
{
    // Fill out a bank preset data structure
    AUSamplerBankPresetData bpdata;
    bpdata.bankURL  = (__bridge CFURLRef)bankURL;
    bpdata.bankMSB  = bankMSB;
    bpdata.bankLSB  = bankLSB;
    bpdata.presetID = (UInt8)presetNumber;
    
    // Set the kAUSamplerProperty_LoadPresetFromBank property
    CheckError(AudioUnitSetProperty(audioUnit,
                                    kAUSamplerProperty_LoadPresetFromBank,
                                    kAudioUnitScope_Global,
                                    0,
                                    &bpdata,
                                    sizeof(bpdata)), "Couldn't load sound file");
}

#pragma mark Session

- (void)setupAudioSession
{
    // Inititalize audio session and set interruption listener
    CheckError(AudioSessionInitialize(NULL,
                                      NULL,
                                      MyInterruptionListener,
                                      (__bridge void *)self),
               "Couldn't initialize audio session");
    
    // Set audio session category
	UInt32 category = kAudioSessionCategory_PlayAndRecord;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                       sizeof(category),
                                       &category),
               "Couldn't set category on audio session");
    
	// Is audio input available?
	UInt32 ui32PropertySize = sizeof(UInt32);
	UInt32 inputAvailable;
	CheckError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable,
                                       &ui32PropertySize,
                                       &inputAvailable),
			   "Couldn't get current audio input available prop");
	
    // Show an alert if no input device is attached
    if (!inputAvailable) {
		UIAlertView *noInputAlert =
		[[UIAlertView alloc] initWithTitle:@"No audio input"
								   message:@"No audio input device is currently attached"
								  delegate:nil
						 cancelButtonTitle:@"OK"
						 otherButtonTitles:nil];
		[noInputAlert show];
	}
    
	// Inspect the hardware input sample rate
	UInt32 propSize = sizeof (hardwareSampleRate);
	CheckError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
									   &propSize,
									   &hardwareSampleRate),
			   "Couldn't get hardwareSampleRate");
	NSLog(@"hardwareSampleRate = %f", hardwareSampleRate);
    
    // Set audio session active
	CheckError(AudioSessionSetActive(YES),
               "Couldn't set AudioSession active");
}

static void MyInterruptionListener(void *inUserData, UInt32 inInterruptionState)
{
	printf("Interrupted! inInterruptionState=%ld\n", inInterruptionState);
	AudioHost *audioHost = (__bridge AudioHost *)inUserData;
    switch (inInterruptionState) {
        case kAudioSessionBeginInterruption:
            printf("Begin interruption\n");
            CheckError(AudioOutputUnitStop(audioHost.rioUnit),
                       "Couldn't stop RIO unit");
            break;
        case kAudioSessionEndInterruption:
            printf("End interruption\n");
            CheckError(AudioSessionSetActive(YES),
                       "Couldn't set audio session active");
            CheckError(AudioUnitInitialize(audioHost.rioUnit),
                       "Couldn't initialize RIO unit");
            CheckError(AudioOutputUnitStart(audioHost.rioUnit),
                       "Couldn't start RIO unit");
            break;
        default:
            break;
    };
}

#pragma mark Callback

OSStatus InputRenderCallback(void                       *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp       *inTimeStamp,
                             UInt32                     inBusNumber,
                             UInt32 					inNumberFrames,
                             AudioBufferList			*ioData)
{
	EffectState *es = (EffectState *)inRefCon;
    
	// just copy samples
	UInt32 bus1 = 1;
	CheckError(AudioUnitRender(es->rioUnit,
                               ioActionFlags,
                               inTimeStamp,
                               bus1,
                               inNumberFrames,
                               ioData),
			   "Couldn't render from RIO unit");
	
    //Float32 *buffer1 = (Float32 *)ioData->mBuffers[0].mData;
    //UInt32 *buffer2 = (UInt32 *)ioData->mBuffers[0].mData;
    //printf("%f %i\n", buffer1[511], (unsigned int)buffer2[511]);
    
    //        _                                        _        _
    //       | |                                      (_)      | |
    //  _ __ | | __ _  ___ ___   _ __ ___   __ _  __ _ _  ___  | |__   ___ _ __ ___
    // | '_ \| |/ _` |/ __/ _ \ | '_ ` _ \ / _` |/ _` | |/ __| | '_ \ / _ \ '__/ _ \
    // | |_) | | (_| | (_|  __/ | | | | | | (_| | (_| | | (__  | | | |  __/ | |  __/
    // | .__/|_|\__,_|\___\___| |_| |_| |_|\__,_|\__, |_|\___| |_| |_|\___|_|  \___|
    // | |                                        __/ |
    // |_|                                       |___/
    
    // Grab audio data
    if (es->mNeedsAudioData) {
        if (es->mAudioBufferSize < ioData->mBuffers[0].mDataByteSize) {
        } else {
            UInt32 bytesToCopy = MIN(ioData->mBuffers[0].mDataByteSize, es->mAudioBufferSize - es->mAudioBufferCurrentIndex);
            memcpy(es->mAudioBuffer + es->mAudioBufferCurrentIndex, ioData->mBuffers[0].mData, bytesToCopy);
            es->mAudioBufferCurrentIndex += bytesToCopy / sizeof(Float32);
            if (es->mAudioBufferCurrentIndex >= es->mAudioBufferSize / sizeof(Float32)) {
                OSAtomicIncrement32Barrier(&es->mHasAudioData);
                OSAtomicDecrement32Barrier(&es->mNeedsAudioData);
            }
        }
    }
    
	return noErr;
}

#pragma mark MIDI

void MyMIDINotifyProc(const MIDINotification *message, void *refCon)
{
    printf("MIDI Notify, messageId=%ld\n", message->messageID);
}

static void MyMIDIReadProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon)
{
    AudioUnit audioUnit = (AudioUnit)refCon;
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
    for (int i = 0; i < pktlist->numPackets; i++) {
        Byte midiStatus = packet->data[0];
        Byte midiCommand = midiStatus >> 4;
        if (midiCommand == 0x09) {
            Byte note = packet->data[1] & 0x7F;
            Byte velocity = packet->data[2] & 0x7F;
            NSString *noteType;
            int noteNumber = ((int)note) % 12;
            switch (noteNumber) {
                case 0:
                    noteType = @"C";
                    break;
                case 1:
                    noteType = @"C#";
                    break;
                case 2:
                    noteType = @"D";
                    break;
                case 3:
                    noteType = @"D#";
                    break;
                case 4:
                    noteType = @"E";
                    break;
                case 5:
                    noteType = @"F";
                    break;
                case 6:
                    noteType = @"F#";
                    break;
                case 7:
                    noteType = @"G";
                    break;
                case 8:
                    noteType = @"G#";
                    break;
                case 9:
                    noteType = @"A";
                    break;
                case 10:
                    noteType = @"Bb";
                    break;
                case 11:
                    noteType = @"B";
                    break;
                default:
                    break;
            }
            MusicDeviceMIDIEvent(audioUnit, midiStatus, note, velocity, 0);
            NSLog(@"%@: %i - %i", noteType, noteNumber, velocity);
        }
        packet = MIDIPacketNext(packet);
    }
}

#pragma mark Helpers

static void CheckError(OSStatus error, const char *operation)
{
	if (error == noErr)
        return;
	
    // If error is nonzero, prints error message and exits program.
    char str[20] = {}; // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else { // no, format it as an integer
		sprintf(str, "%d", (int)error);
    }
    
	fprintf(stderr, "Error: %s (%s)\n", operation, str);
	exit(1);
}

- (void)printASBD:(AudioStreamBasicDescription)asbd withName:(NSString *)name
{
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig(asbd.mFormatID);
    bcopy(&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    NSLog(@"%@ ASBD", name);
    NSLog(@"  Sample Rate:         %10.0f",    asbd.mSampleRate);
    NSLog(@"  Format ID:           %10s",      formatIDString);
    NSLog(@"  Format Flags:        %10lu",     asbd.mFormatFlags);
    NSLog(@"  Bytes per Packet:    %10lu",     asbd.mBytesPerPacket);
    NSLog(@"  Frames per Packet:   %10lu",     asbd.mFramesPerPacket);
    NSLog(@"  Bytes per Frame:     %10lu",     asbd.mBytesPerFrame);
    NSLog(@"  Channels per Frame:  %10lu",     asbd.mChannelsPerFrame);
    NSLog(@"  Bits per Channel:    %10lu",     asbd.mBitsPerChannel);
}

#pragma mark Fast Fourier Transformation

- (UInt32)maxFPS
{
    return _effectState.mNumberFrames;
}

- (BOOL)computeFFT:(int32_t *)outFFTData
{
    if (_effectState.mHasAudioData) {
        
        // Multiply samples with hamming window
        vDSP_vmul(_effectState.mAudioBuffer,
                  1,
                  _effectState.mHammingWindow,
                  1,
                  _effectState.mAudioBuffer,
                  1,
                  _effectState.mNumberFrames);
        
        /*printf("start\n");
        for (int i = 0; i < _effectState.mNumberFrames; i++) {
			printf("%f\n", _effectState.mAudioBuffer[i]);
		}*/
        
        // Generate a split complex vector from the real data / split data (1- 16) into odds and evens
        vDSP_ctoz((COMPLEX *)_effectState.mAudioBuffer,
                  2,
                  &_effectState.mDspSplitComplex,
                  1,
                  _effectState.mFFTLength);
        
        vDSP_fft_zrip(_effectState.mSpectrumAnalyse,
                      &_effectState.mDspSplitComplex,
                      1,
                      _effectState.mLog2N,
                      kFFTDirection_Forward);
        vDSP_vsmul(_effectState.mDspSplitComplex.realp,
                   1,
                   &_effectState.mFFTNormFactor,
                   _effectState.mDspSplitComplex.realp,
                   1,
                   _effectState.mFFTLength);
        vDSP_vsmul(_effectState.mDspSplitComplex.imagp,
                   1,
                   &_effectState.mFFTNormFactor,
                   _effectState.mDspSplitComplex.imagp,
                   1,
                   _effectState.mFFTLength);
        
        // ABS
        vDSP_zvabs(&_effectState.mDspSplitComplex,
                   1,
                   _effectState.mDspSplitComplex.realp,
                   1,
                   _effectState.mFFTLength);
        
        // Get log of absolute values for passing to inverse FFT for cepstrum
        for (int i = 0; i < _effectState.mFFTLength; i++) {
            _effectState.mDspSplitComplex.realp[i] = logf(_effectState.mDspSplitComplex.realp[i]);
        }
        
        // Perform the invere FFT
        vDSP_fft_zrip(_effectState.mSpectrumAnalyse,
                      &_effectState.mDspSplitComplex,
                      1,
                      _effectState.mLog2N,
                      kFFTDirection_Inverse);
        /*vDSP_vsmul(_effectState.mDspSplitComplex.realp,
                   1,
                   &_effectState.mFFTNormFactor,
                   _effectState.mDspSplitComplex.realp,
                   1,
                   _effectState.mFFTLength);
        vDSP_vsmul(_effectState.mDspSplitComplex.imagp,
                   1,
                   &_effectState.mFFTNormFactor,
                   _effectState.mDspSplitComplex.imagp,
                   1,
                   _effectState.mFFTLength);*/
        
        // ABS
        vDSP_zvabs(&_effectState.mDspSplitComplex,
                   1,
                   _effectState.mDspSplitComplex.realp,
                   1,
                   _effectState.mFFTLength);
        
        float m1 = 44100.0 / 700;
        float m2 = 44100.0 / 70;
        
        //printf("start\n");
        float max = 0.0;
        int fx = 0;
        for (int i = 0; i < _effectState.mFFTLength; i++) {
            if (i > m1 && i < m2 && max < _effectState.mDspSplitComplex.realp[i]) {
                max = _effectState.mDspSplitComplex.realp[i];
                fx = i;
            }
        }
        printf("%f\n", (44100.0 / fx) / 2);
        
        OSAtomicDecrement32Barrier(&_effectState.mHasAudioData);
        OSAtomicIncrement32Barrier(&_effectState.mNeedsAudioData);
        _effectState.mAudioBufferCurrentIndex = 0;
        return YES;
        
    } else if (_effectState.mNeedsAudioData == 0) {
        OSAtomicIncrement32Barrier(&_effectState.mNeedsAudioData);
    }
    
    return NO;
}

- (float)MagnitudeSquaredX:(float)x andY:(float)y
{
	return ((x * x) + (y * y));
}

#pragma mark Functions

- (void)play
{
    // Get a string to the path of the MIDI file which should be located in the Resources folder
    NSString *midiFilePath = [[NSBundle mainBundle] pathForResource:@"offspring" ofType:@"mid"];
    _midiFile = [MIDIFile fileWithPath:midiFilePath];
    if (_midiFile) {
        MusicSequenceSetAUGraph(_midiFile.sequence, self.processingGraph);
        
        // Obtain the tracks
        MusicTrack t1, t2, t3, t4, t5;
        MusicSequenceGetIndTrack(_midiFile.sequence, 0, &t1);
        MusicSequenceGetIndTrack(_midiFile.sequence, 1, &t2);
        MusicSequenceGetIndTrack(_midiFile.sequence, 2, &t3);
        MusicSequenceGetIndTrack(_midiFile.sequence, 3, &t4);
        MusicSequenceGetIndTrack(_midiFile.sequence, 4, &t5);
        
        AUNode n1, n2, n3, n4, n5;
        AUGraphGetIndNode(self.processingGraph, 2, &n1);
        AUGraphGetIndNode(self.processingGraph, 3, &n2);
        AUGraphGetIndNode(self.processingGraph, 4, &n3);
        AUGraphGetIndNode(self.processingGraph, 5, &n4);
        AUGraphGetIndNode(self.processingGraph, 6, &n5);
        
        MusicTrackSetDestNode(t1, n1);
        MusicTrackSetDestNode(t2, n2);
        MusicTrackSetDestNode(t3, n3);
        MusicTrackSetDestNode(t4, n4);
        MusicTrackSetDestNode(t5, n5);
        
        /*/ Create a client
        MIDIClientRef virtualMidi;
        CheckError(MIDIClientCreate(CFSTR("Virtual Client"), MyMIDINotifyProc, NULL, &virtualMidi),
                   "Couldn't create MIDIClient");
        
        // Create a virtual endpoint
        MIDIEndpointRef virtualEndpoint;
        CheckError(MIDIDestinationCreate(virtualMidi, (CFStringRef)@"Virtual Destination", MyMIDIReadProc, self.samplerUnit4, &virtualEndpoint),
                   "Couldn't create a virtual endpoint");
        
        // Set the endpoint of the track 4 to be our virtual endpoint
        MusicTrackSetDestMIDIEndpoint(t4, virtualEndpoint);*/
        
        // Start the song
        //[_midiFile play];
    }
}

@end
