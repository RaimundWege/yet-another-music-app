//
//  AudioHost.m
//  Guitar
//
//  Created by Raimund on 01.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "AudioHost.h"

#define HIGH_PASS_FILTER 0.95

@implementation AudioHost

#pragma mark Constructor

+ sharedInstance
{
    static AudioHost *sharedAudioHost;
    
    @synchronized(self)
    {
        if (!sharedAudioHost) {
            sharedAudioHost = [[AudioHost alloc] initAudioHost];
            [sharedAudioHost startAudioGraph];
        }
    }
    
    return sharedAudioHost;
}

- (id) initAudioHost
{
	if ((self = [self init])) {
        
	}
	return self;
}

#pragma mark Control

- (void)startAudioGraph
{
    // Setup the audio session
    [self setupAudioSession];
    
    // Create the audio processing graph
    [self createAUGraph];
    
    // Initialize the audio processing graph.
    CheckError(AUGraphInitialize(_processingGraph),
               "Couldn't initialze audio processing graph");
    
    // Start the graph
    CheckError(AUGraphStart(_processingGraph),
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
    cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;
	CheckError(AUGraphAddNode(_processingGraph, &cd, &_rioNode),
               "Couldn't add the RIO unit to the audio processing graph");
    
    // Specify the Distortion unit and add the Distortion unit node to the graph
    cd.componentType = kAudioUnitType_Effect;
    cd.componentSubType = kAudioUnitSubType_Distortion;
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_distortionNode),
               "Couldn't add the Distortion unit to the audio processing graph");
    
    // Specify the String units and add the String unit nodes to the graph
    cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_Sampler;
	CheckError(AUGraphAddNode(_processingGraph, &cd, &_stringE2Node),
               "Couldn't add the String E2 unit to the audio processing graph");
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_stringA2Node),
               "Couldn't add the String A2 unit to the audio processing graph");
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_stringD3Node),
               "Couldn't add the String D3 unit to the audio processing graph");
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_stringG3Node),
               "Couldn't add the String G3 unit to the audio processing graph");
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_stringH3Node),
               "Couldn't add the String H3 unit to the audio processing graph");
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_stringE4Node),
               "Couldn't add the String E4 unit to the audio processing graph");
    
    // Specify the String Mixer unit and add the String Mixer unit node to the graph
    cd.componentType = kAudioUnitType_Mixer;
    cd.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_stringMixerNode),
               "Couldn't add the String Mixer unit to the audio processing graph");
    
    // Specify the Sampler units and add the Sampler unit nodes to the graph
	cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_Sampler;
	CheckError(AUGraphAddNode(_processingGraph, &cd, &_keyboardSamplerNode),
               "Couldn't add the Keayboard Sampler unit to the audio processing graph");
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_distortionSamplerNode),
               "Couldn't add the Distortion Sampler unit to the audio processing graph");
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_bassSamplerNode),
               "Couldn't add the Bass Sampler unit to the audio processing graph");
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_overdriveSamplerNode),
               "Couldn't add the Overdrive Sampler unit to the audio processing graph");
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_percussionSamplerNode),
               "Couldn't add the Percussion Sampler unit to the audio processing graph");
    
    // Specify the Master Mixer unit and add the Mixer unit node to the graph
    cd.componentType = kAudioUnitType_Mixer;
    cd.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    CheckError(AUGraphAddNode(_processingGraph, &cd, &_masterMixerNode),
               "Couldn't add the Master Mixer unit to the audio processing graph");
    
    // Open the audio processing graph
	CheckError(AUGraphOpen(_processingGraph),
               "Couldn't open the audio processing graph");
    NSLog(@"AUGraph opened!");
    
    // ______                     _      _____ _____
    // | ___ \                   | |    |_   _|  _  |
    // | |_/ /___ _ __ ___   ___ | |_ ___ | | | | | |
    // |    // _ \ '_ ` _ \ / _ \| __/ _ \| | | | | |
    // | |\ \  __/ | | | | | (_) | ||  __/| |_\ \_/ /
    // \_| \_\___|_| |_| |_|\___/ \__\___\___/ \___/
    
    // Obtain the RIO unit instance from its corresponding node
    CheckError(AUGraphNodeInfo(_processingGraph, _rioNode, NULL, &_rioUnit),
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
    
    // Setup the ASBD to the Mac OS X canonical format
    AudioStreamBasicDescription rioASBD;
	memset(&rioASBD, 0, sizeof(rioASBD));
    size_t bytesPerSample       = sizeof(float);
    rioASBD.mSampleRate         = hardwareSampleRate;
    rioASBD.mFormatID           = kAudioFormatLinearPCM;
    rioASBD.mFormatFlags        = (kAudioFormatFlagIsFloat |
                                   kAudioFormatFlagIsPacked |
                                   kAudioFormatFlagIsNonInterleaved);
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
    CheckError(AUGraphNodeInfo(_processingGraph, _distortionNode, NULL, &_distortionUnit),
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
    
    // Set the maximum frames per slices for the RIO unit
    UInt32 maxFPS = 8192;
    UInt32 maxFPSSize = sizeof(maxFPS);
    CheckError(AudioUnitSetProperty(_rioUnit,
                                    kAudioUnitProperty_MaximumFramesPerSlice,
                                    kAudioUnitScope_Global,
                                    bus0,
                                    &maxFPS,
                                    maxFPSSize),
               "Couldn't set the RIO unit's maximum frames per slice");
    
    // Get the maximum frames per slices from the RIO unit
    CheckError(AudioUnitGetProperty(_rioUnit,
                                    kAudioUnitProperty_MaximumFramesPerSlice,
                                    kAudioUnitScope_Global,
                                    bus0,
                                    &maxFPS,
                                    &maxFPSSize),
               "Couldn't get the RIO unit's maximum frames per slice");
    NSLog(@"RIO unit's maximum frames per slice: %u", (unsigned int)maxFPS);
    
    // Set the struct for the effect state and all FFT variables
    _ris.rioUnit = _rioUnit;
    _ris.isAmplitudeDriven = NO;
    numberFrames = maxFPS;
    minFrequency = hardwareSampleRate / 1350;
    maxFrequency = hardwareSampleRate / 80;
    hammingWindow = (Float32 *)calloc(numberFrames, sizeof(Float32));
    _ris.audioBuffer = (Float32 *)calloc(numberFrames, sizeof(Float32));
    _ris.audioBufferSize = numberFrames * sizeof(Float32);
    _ris.audioBufferCurrentIndex = 0;
    
    // Cepstrum
    cepstrumFFTLength = numberFrames / 2;
    cepstrumLog2N = log2(numberFrames);
    cepstrumFFTNormFactor = 1.0 / (2 * numberFrames);
    cepstrumAnalyse = vDSP_create_fftsetup(cepstrumLog2N, kFFTRadix2);
    cepstrumSplitComplex.realp = (Float32 *)calloc(cepstrumFFTLength, sizeof(Float32));
    cepstrumSplitComplex.imagp = (Float32 *)calloc(cepstrumFFTLength, sizeof(Float32));
    
    // Auto Correlation
    autoCorrelationTwiceFFTLength = numberFrames * 2;
    autoCorrelationTwiceLog2N = log2(autoCorrelationTwiceFFTLength);
    autoCorrelationAnalyse = vDSP_create_fftsetup(autoCorrelationTwiceLog2N, kFFTRadix2);
    autoCorrelationSplitComplexFW.realp = (Float32 *)calloc(autoCorrelationTwiceFFTLength, sizeof(Float32));
    autoCorrelationSplitComplexFW.imagp = (Float32 *)calloc(autoCorrelationTwiceFFTLength, sizeof(Float32));
    autoCorrelationSplitComplexBW.realp = (Float32 *)calloc(autoCorrelationTwiceFFTLength, sizeof(Float32));
    autoCorrelationSplitComplexBW.imagp = (Float32 *)calloc(autoCorrelationTwiceFFTLength, sizeof(Float32));
    
    // Initialize window function buffer
    vDSP_hamm_window(hammingWindow, numberFrames, 0);
    
    // Set callback function
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = InputRenderCallback;
	callbackStruct.inputProcRefCon = &_ris;
    CheckError(AUGraphSetNodeInputCallback(_processingGraph,
                                           _distortionNode,
                                           bus0,
                                           &callbackStruct),
               "Couldn't set Distortion input render callback on bus 0");
    
    // Initialize Distortion unit
	CheckError(AudioUnitInitialize(_distortionUnit),
			   "Couldn't initialize Distortion unit");
    NSLog(@"Distortion unit initialized!");
    
    //  _____ _        _               _____                       _
    // /  ___| |      (_)             /  ___|                     | |
    // \ `--.| |_ _ __ _ _ __   __ _  \ `--.  __ _ _ __ ___  _ __ | | ___ _ __
    //  `--. \ __| '__| | '_ \ / _` |  `--. \/ _` | '_ ` _ \| '_ \| |/ _ \ '__|
    // /\__/ / |_| |  | | | | | (_| | /\__/ / (_| | | | | | | |_) | |  __/ |
    // \____/ \__|_|  |_|_| |_|\__, | \____/ \__,_|_| |_| |_| .__/|_|\___|_|
    //                          __/ |                       | |
    //                         |___/                        |_|
    
    // Obtain references to all of the String Sampler units from their nodes
    CheckError(AUGraphNodeInfo(_processingGraph, _stringE2Node, 0, &_stringE2Unit),
               "Couldn't obtain String E2 Sampler unit from its corresponding node");
    CheckError(AUGraphNodeInfo(_processingGraph, _stringA2Node, 0, &_stringA2Unit),
               "Couldn't obtain String A2 Sampler unit from its corresponding node");
    CheckError(AUGraphNodeInfo(_processingGraph, _stringD3Node, 0, &_stringD3Unit),
               "Couldn't obtain String D3 Sampler unit from its corresponding node");
    CheckError(AUGraphNodeInfo(_processingGraph, _stringG3Node, 0, &_stringG3Unit),
               "Couldn't obtain String G3 Sampler unit from its corresponding node");
    CheckError(AUGraphNodeInfo(_processingGraph, _stringH3Node, 0, &_stringH3Unit),
               "Couldn't obtain String H3 Sampler unit from its corresponding node");
    CheckError(AUGraphNodeInfo(_processingGraph, _stringE4Node, 0, &_stringE4Unit),
               "Couldn't obtain String E4 Sampler unit from its corresponding node");
    
    //  _____ _        _              ___  ____
    // /  ___| |      (_)             |  \/  (_)
    // \ `--.| |_ _ __ _ _ __   __ _  | .  . |___  _____ _ __
    //  `--. \ __| '__| | '_ \ / _` | | |\/| | \ \/ / _ \ '__|
    // /\__/ / |_| |  | | | | | (_| | | |  | | |>  <  __/ |
    // \____/ \__|_|  |_|_| |_|\__, | \_|  |_/_/_/\_\___|_|
    //                          __/ |
    //                         |___/
    
    // Obtain the Mixer unit instance from its corresponding node
    CheckError(AUGraphNodeInfo(_processingGraph, _stringMixerNode, NULL, &_stringMixerUnit),
               "Couldn't obtain String Mixer unit from its corresponding node");
    
    // Set the bus count for the String Mixer
    UInt32 numStringMixerBuses = 6;
    CheckError(AudioUnitSetProperty(_stringMixerUnit,
                                    kAudioUnitProperty_ElementCount,
                                    kAudioUnitScope_Input,
                                    0,
                                    &numStringMixerBuses,
                                    sizeof(numStringMixerBuses)),
               "Couldn't set the bus count for the String Mixer unit");
    
    //  _____                       _
    // /  ___|                     | |
    // \ `--.  __ _ _ __ ___  _ __ | | ___ _ __
    //  `--. \/ _` | '_ ` _ \| '_ \| |/ _ \ '__|
    // /\__/ / (_| | | | | | | |_) | |  __/ |
    // \____/ \__,_|_| |_| |_| .__/|_|\___|_|
    //                       | |
    //                       |_|
    
    // Obtain references to all of the Sampler units from their nodes
    CheckError(AUGraphNodeInfo(_processingGraph, _keyboardSamplerNode, 0, &_keyboardSamplerUnit),
               "Couldn't obtain Keyboard Sampler unit from its corresponding node");
    CheckError(AUGraphNodeInfo(_processingGraph, _distortionSamplerNode, 0, &_distortionSamplerUnit),
               "Couldn't obtain Distortion Sampler unit from its corresponding node");
    CheckError(AUGraphNodeInfo(_processingGraph, _bassSamplerNode, 0, &_bassSamplerUnit),
               "Couldn't obtain Bass Sampler unit from its corresponding node");
    CheckError(AUGraphNodeInfo(_processingGraph, _overdriveSamplerNode, 0, &_overdriveSamplerUnit),
               "Couldn't obtain Overdrive Sampler unit from its corresponding node");
    CheckError(AUGraphNodeInfo(_processingGraph, _percussionSamplerNode, 0, &_percussionSamplerUnit),
               "Couldn't obtain Percussion Sampler unit from its corresponding node");
    
    // ___  ___          _             ___  ____
    // |  \/  |         | |            |  \/  (_)
    // | .  . | __ _ ___| |_ ___ _ __  | .  . |___  _____ _ __
    // | |\/| |/ _` / __| __/ _ \ '__| | |\/| | \ \/ / _ \ '__|
    // | |  | | (_| \__ \ ||  __/ |    | |  | | |>  <  __/ |
    // \_|  |_/\__,_|___/\__\___|_|    \_|  |_/_/_/\_\___|_|
    
    
    // Obtain the Mixer unit instance from its corresponding node
    CheckError(AUGraphNodeInfo(_processingGraph, _masterMixerNode, NULL, &_masterMixerUnit),
               "Couldn't obtain Master Mixer unit from its corresponding node");
    
    // Set the bus count for the Master Mixer
    UInt32 numMasterMixerBuses = 7;
    CheckError(AudioUnitSetProperty(_masterMixerUnit,
                                    kAudioUnitProperty_ElementCount,
                                    kAudioUnitScope_Input,
                                    0,
                                    &numMasterMixerBuses,
                                    sizeof(numMasterMixerBuses)),
               "Couldn't set the bus count for the Master Mixer unit");
    
    // Set ASBD for Mixer's output scope (bus 0)
    CheckError(AudioUnitSetProperty(_masterMixerUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    bus0,
                                    &rioASBD,
                                    sizeof(rioASBD)),
               "Couldn't set ASBD for Master Mixer on output scope / bus 0");
    
    //  _____                             _   _
    // /  __ \                           | | (_)
    // | /  \/ ___  _ __  _ __   ___  ___| |_ _  ___  _ __  ___
    // | |    / _ \| '_ \| '_ \ / _ \/ __| __| |/ _ \| '_ \/ __|
    // | \__/\ (_) | | | | | | |  __/ (__| |_| | (_) | | | \__ \
    //  \____/\___/|_| |_|_| |_|\___|\___|\__|_|\___/|_| |_|___/
    
    // Connect the String units output with the String Mixer unit input on buses 0 to 5
    CheckError(AUGraphConnectNodeInput(_processingGraph, _stringE2Node, 0, _stringMixerNode, 0),
               "Couldn't connect the String E2 Sampler unit with the Master Mixer unit");
    CheckError(AUGraphConnectNodeInput(_processingGraph, _stringA2Node, 0, _stringMixerNode, 1),
               "Couldn't connect the String A2 Sampler unit with the Master Mixer unit");
    CheckError(AUGraphConnectNodeInput(_processingGraph, _stringD3Node, 0, _stringMixerNode, 2),
               "Couldn't connect the String D3 Sampler unit with the Master Mixer unit");
    CheckError(AUGraphConnectNodeInput(_processingGraph, _stringG3Node, 0, _stringMixerNode, 3),
               "Couldn't connect the String G3 Sampler unit with the Master Mixer unit");
    CheckError(AUGraphConnectNodeInput(_processingGraph, _stringH3Node, 0, _stringMixerNode, 4),
               "Couldn't connect the String H3 Sampler unit with the Master Mixer unit");
    CheckError(AUGraphConnectNodeInput(_processingGraph, _stringE4Node, 0, _stringMixerNode, 5),
               "Couldn't connect the String E4 Sampler unit with the Master Mixer unit");
    
    // Connect the String Mixer unit output with the Master Mixer unit input on bus 0
    CheckError(AUGraphConnectNodeInput(_processingGraph, _stringMixerNode, 0, _masterMixerNode, 0),
               "Couldn't connect the String Mixer unit with the Master Mixer unit");
    
    // Connect the Sampler units output with the Master Mixer unit input on buses 1 to 5
    CheckError(AUGraphConnectNodeInput(_processingGraph, _keyboardSamplerNode, 0, _masterMixerNode, 1),
               "Couldn't connect the Keyboard Sampler unit with the Master Mixer unit");
    CheckError(AUGraphConnectNodeInput(_processingGraph, _distortionSamplerNode, 0, _masterMixerNode, 2),
               "Couldn't connect the Distortion Sampler unit with the Master Mixer unit");
    CheckError(AUGraphConnectNodeInput(_processingGraph, _bassSamplerNode, 0, _masterMixerNode, 3),
               "Couldn't connect the Bass Sampler unit with the Master Mixer unit");
    CheckError(AUGraphConnectNodeInput(_processingGraph, _overdriveSamplerNode, 0, _masterMixerNode, 4),
               "Couldn't connect the Overdrive Sampler unit with the Master Mixer unit");
    CheckError(AUGraphConnectNodeInput(_processingGraph, _percussionSamplerNode, 0, _masterMixerNode, 5),
               "Couldn't connect the Percussion Sampler unit with the Master Mixer unit");
    
    // Connect the Distortion unit output with the MasterMixer unit input on bus 6
    CheckError(AUGraphConnectNodeInput(_processingGraph, _distortionNode, 0, _masterMixerNode, 6),
               "Couldn't connect the Distortion unit with the Master Mixer unit");
    
    // Connect the Master Mixer unit output to the RIO unit bus 0 (output scope)
    CheckError(AUGraphConnectNodeInput(_processingGraph, _masterMixerNode, 0, _rioNode, 0),
               "Couldn't connect the Master Mixer unit with the RIO unit");
    
    //  _____                       _  __            _
    // /  ___|                     | |/ _|          | |
    // \ `--.  ___  _   _ _ __   __| | |_ ___  _ __ | |_ ___
    //  `--. \/ _ \| | | | '_ \ / _` |  _/ _ \| '_ \| __/ __|
    // /\__/ / (_) | |_| | | | | (_| | || (_) | | | | |_\__ \
    // \____/ \___/ \__,_|_| |_|\__,_|_| \___/|_| |_|\__|___/
    
    // Load the sound font from file
    NSURL *presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"instruments" ofType:@"sf2"]];
    
    // Initialize the units with a soundfont
    [self setDLSOrSoundFontFor:_stringE2Unit fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:30]; // Distortion
    [self setDLSOrSoundFontFor:_stringA2Unit fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:30]; // Distortion
    [self setDLSOrSoundFontFor:_stringD3Unit fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:30]; // Distortion
    [self setDLSOrSoundFontFor:_stringG3Unit fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:30]; // Distortion
    [self setDLSOrSoundFontFor:_stringH3Unit fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:30]; // Distortion
    [self setDLSOrSoundFontFor:_stringE4Unit fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:30]; // Distortion
    [self setDLSOrSoundFontFor:_keyboardSamplerUnit fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:30]; // Distortion
    [self setDLSOrSoundFontFor:_distortionSamplerUnit fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:30]; // Distortion
    [self setDLSOrSoundFontFor:_bassSamplerUnit fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:33]; // Fingered Bass
    [self setDLSOrSoundFontFor:_overdriveSamplerUnit fromURL:presetURL bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:29]; // Overdrive
    [self setDLSOrSoundFontFor:_percussionSamplerUnit fromURL:presetURL bankMSB:kAUSampler_DefaultPercussionBankMSB bankLSB:kAUSampler_DefaultBankLSB withPatch:0]; // Percussion
    
    // Print out the graph to the console
    CAShow(_processingGraph);
}

- (void)setDLSOrSoundFontFor:(AudioUnit)audioUnit fromURL:(NSURL *)bankURL bankMSB:(UInt8)bankMSB bankLSB:(UInt8)bankLSB withPatch:(int)presetNumber
{
    // Fill out a bank preset data structure
    AUSamplerBankPresetData bpdata;
    bpdata.bankURL  = (__bridge CFURLRef)bankURL;
    bpdata.bankMSB  = bankMSB;
    bpdata.bankLSB  = bankLSB;
    bpdata.presetID = (UInt8)presetNumber;
    
    // Load sound file
    CheckError(AudioUnitSetProperty(audioUnit,
                                    kAUSamplerProperty_LoadPresetFromBank,
                                    kAudioUnitScope_Global,
                                    0,
                                    &bpdata,
                                    sizeof(bpdata)),
               "Couldn't load sound file");
}

#pragma mark Session

- (void)setupAudioSession
{
    // Inititalize audio session and set interruption listener
    CheckError(AudioSessionInitialize(nil,
                                      nil,
                                      AudioHostInterruptionListener,
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
    
    // Set the hardware input sample rate
    UInt32 hardwareSampleRateSize = sizeof(hardwareSampleRate);
    hardwareSampleRate = 44100; //22050;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate,
                                       hardwareSampleRateSize,
                                       &hardwareSampleRate),
               "Couldn't set hardware sample rate");
    
	// Inspect the current hardware sample rate
	CheckError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
									   &hardwareSampleRateSize,
									   &hardwareSampleRate),
			   "Couldn't get current hardware sample rate");
	NSLog(@"hardwareSampleRate = %f", hardwareSampleRate);
    
    // Set audio session active
	CheckError(AudioSessionSetActive(YES),
               "Couldn't set AudioSession active");
}

static void AudioHostInterruptionListener(void *inUserData, UInt32 inInterruptionState)
{
	printf("Interrupted in state=%ld\n", inInterruptionState);
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

- (void)startRIO
{
    CheckError(AudioUnitInitialize(_rioUnit),
               "Couldn't initialize RIO unit");
    CheckError(AudioOutputUnitStart(_rioUnit),
               "Couldn't start RIO unit");
}

- (void)stopRIO
{
    CheckError(AudioOutputUnitStop(_rioUnit),
               "Couldn't stop RIO unit");
}

#pragma mark Callback

OSStatus InputRenderCallback(void                       *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp       *inTimeStamp,
                             UInt32                     inBusNumber,
                             UInt32 					inNumberFrames,
                             AudioBufferList			*ioData)
{
    RenderInputState *es = (RenderInputState *)inRefCon;
    
	// Just copy samples
	UInt32 bus1 = 1;
	CheckError(AudioUnitRender(es->rioUnit,
                               ioActionFlags,
                               inTimeStamp,
                               bus1,
                               inNumberFrames,
                               ioData),
			   "Couldn't render from RIO unit");
    
    // Remove DC component
    Float32 *samples = (Float32 *)ioData->mBuffers[0].mData;
    for (int i = 0; i < inNumberFrames; i++) {
        Float32 xCurr = samples[i];
		samples[i] = samples[i] - es->x + (HIGH_PASS_FILTER * es->y);
        es->x = xCurr;
        es->y = samples[i];
	}
    
    // Detect decibel
    Float32 maxAmplitude = -MAXFLOAT;
    for (int i = 0; i < inNumberFrames; i++) {
        maxAmplitude = fmaxf(maxAmplitude, fabsf(samples[i]));
    }
    maxAmplitude = 20 * log10f(maxAmplitude);
    if (maxAmplitude > -25.0) {
        if (maxAmplitude > es->maxAmplitude + 3.0) {
            if (!es->detectAttack) {
                OSAtomicIncrement32Barrier(&es->detectAttack);
            }
        }
    } else if ((maxAmplitude - es->maxAmplitude) < -10.0) {
        if (!es->detectMute) {
            OSAtomicIncrement32Barrier(&es->detectMute);
        }
    }
    
    // Grab audio data
    if (es->needsAudioData) {
        if (es->audioBufferSize >= ioData->mBuffers[0].mDataByteSize) {
            UInt32 bytesToCopy = MIN(ioData->mBuffers[0].mDataByteSize, es->audioBufferSize - es->audioBufferCurrentIndex);
            memcpy(es->audioBuffer + es->audioBufferCurrentIndex, ioData->mBuffers[0].mData, bytesToCopy);
            es->audioBufferCurrentIndex += bytesToCopy / sizeof(Float32);
            if (es->audioBufferCurrentIndex >= es->audioBufferSize / sizeof(Float32)) {
                OSAtomicIncrement32Barrier(&es->hasAudioData);
                OSAtomicDecrement32Barrier(&es->needsAudioData);
            }
        }
    } else {
        if (!es->isAmplitudeDriven || es->detectAttack) {
            if (!es->hasAudioData) {
                OSAtomicIncrement32Barrier(&es->needsAudioData);
            }
        }
    }
    
    es->maxAmplitude = maxAmplitude;
    
	return noErr;
}

#pragma mark MIDI

void MyMIDINotifyProc(const MIDINotification *message, void *refCon)
{
    printf("MIDI Notify, messageId=%ld\n", message->messageID);
}

static void StringMIDIReadProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon)
{
    AudioUnit audioUnit = (AudioUnit)refCon;
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
    for (int i = 0; i < pktlist->numPackets; i++) {
        Byte midiStatus = packet->data[0];
        Byte midiCommand = midiStatus >> 4;
        if (midiCommand == 0x09) {
            Byte note = packet->data[1] & 0x7F;
            Byte velocity = packet->data[2] & 0x7F;
            int noteNumber = ((int)note) % 12;
            switch (noteNumber) {
                case 0:
                    printf("C");
                    break;
                case 1:
                    printf("C#");
                    break;
                case 2:
                    printf("D");
                    break;
                case 3:
                    printf("D#");
                    break;
                case 4:
                    printf("E");
                    break;
                case 5:
                    printf("F");
                    break;
                case 6:
                    printf("F#");
                    break;
                case 7:
                    printf("G");
                    break;
                case 8:
                    printf("G#");
                    break;
                case 9:
                    printf("A");
                    break;
                case 10:
                    printf("Bb");
                    break;
                case 11:
                    printf("B");
                    break;
                default:
                    printf("?");
                    break;
            }
            MusicDeviceMIDIEvent(audioUnit, midiStatus, note, velocity, 0);
            printf(": %i (%i)\n", note, velocity);
        }
        packet = MIDIPacketNext(packet);
    }
}

static void PercussionMIDIReadProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon)
{
    PercussionState *ps = (PercussionState *)refCon;
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
    for (int i = 0; i < pktlist->numPackets; i++) {
        Byte midiStatus = packet->data[0];
        Byte midiCommand = midiStatus >> 4;
        if (midiCommand == 0x09) {
            Byte note = packet->data[1] & 0x7F;
            Byte velocity = packet->data[2] & 0x7F;
            if (velocity > 0) {
                int noteNumber = ((int)note) % 2;
                switch (noteNumber) {
                    case 0:
                        printf("even");
                        if (!ps->detectEvenNote) {
                            OSAtomicIncrement32Barrier(&ps->detectEvenNote);
                        }
                        break;
                    case 1:
                        printf("odd");
                        if (!ps->detectOddNote) {
                            OSAtomicIncrement32Barrier(&ps->detectOddNote);
                        }
                        break;
                    default:
                        printf("?");
                        break;
                }
            }
            MusicDeviceMIDIEvent(ps->percussionSamplerUnit, midiStatus, note, velocity, 0);
            printf(": %i (%i)\n", note, velocity);
        }
        packet = MIDIPacketNext(packet);
    }
}

#pragma mark Helpers

// If error is nonzero, prints error message and exits program
void CheckError(OSStatus error, const char *operation)
{
	if (error == noErr)
        return;
	
    // see if it appears to be a 4-char-code
    char str[20] = {};
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else {
        // no, format it as an integer
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
    return numberFrames;
}

- (float)computeCepstrum
{
    float frequency = -1.0;
    
    if (_ris.hasAudioData) {
        
        // Multiply samples with hamming window
        vDSP_vmul(_ris.audioBuffer,
                  1,
                  hammingWindow,
                  1,
                  _ris.audioBuffer,
                  1,
                  numberFrames);
        
        // Generate a split complex vector from the real data into odds and evens
        vDSP_ctoz((COMPLEX *)_ris.audioBuffer,
                  2,
                  &cepstrumSplitComplex,
                  1,
                  cepstrumFFTLength);
        
        // Perform forward FFT
        vDSP_fft_zrip(cepstrumAnalyse,
                      &cepstrumSplitComplex,
                      1,
                      cepstrumLog2N,
                      kFFTDirection_Forward);
        
        // Normalize values
        vDSP_vsmul(cepstrumSplitComplex.realp,
                   1,
                   &cepstrumFFTNormFactor,
                   cepstrumSplitComplex.realp,
                   1,
                   cepstrumFFTLength);
        vDSP_vsmul(cepstrumSplitComplex.imagp,
                   1,
                   &cepstrumFFTNormFactor,
                   cepstrumSplitComplex.imagp,
                   1,
                   cepstrumFFTLength);
        
        // Get absolute values
        vDSP_zvabs(&cepstrumSplitComplex,
                   1,
                   cepstrumSplitComplex.realp,
                   1,
                   cepstrumFFTLength);
        
        // Get log of absolute values for passing to inverse FFT for cepstrum
        for (int i = 0; i < cepstrumFFTLength; i++) {
            cepstrumSplitComplex.realp[i] = logf(cepstrumSplitComplex.realp[i]);
        }
        
        // Perform the invere FFT
        vDSP_fft_zrip(cepstrumAnalyse,
                      &cepstrumSplitComplex,
                      1,
                      cepstrumLog2N,
                      kFFTDirection_Inverse);
        
        // Normalize values
        vDSP_vsmul(cepstrumSplitComplex.realp,
                   1,
                   &cepstrumFFTNormFactor,
                   cepstrumSplitComplex.realp,
                   1,
                   cepstrumFFTLength);
        vDSP_vsmul(cepstrumSplitComplex.imagp,
                   1,
                   &cepstrumFFTNormFactor,
                   cepstrumSplitComplex.imagp,
                   1,
                   cepstrumFFTLength);
        
        // Get absolute values
        vDSP_zvabs(&cepstrumSplitComplex,
                   1,
                   cepstrumSplitComplex.realp,
                   1,
                   cepstrumFFTLength);
        
        // Find Frequency
        int f = 0;
        float max = 0.0;
        for (int i = minFrequency; i < maxFrequency; i++) {
            if (max < cepstrumSplitComplex.realp[i]) {
                max = cepstrumSplitComplex.realp[i];
                f = i;
            }
        }
        frequency = (hardwareSampleRate / f) / 2;
        
        // Audio can be overwritten with new audio
        OSAtomicDecrement32Barrier(&_ris.hasAudioData);
        _ris.audioBufferCurrentIndex = 0;
    }
    
    return frequency;
}

- (float)computeAutoCorrelation
{
    float frequency = -1.0;
    
    if (_ris.hasAudioData) {
        
        // Filling split complex buffers with zeros
        vDSP_vclr(autoCorrelationSplitComplexFW.realp, 1, autoCorrelationTwiceFFTLength);
		vDSP_vclr(autoCorrelationSplitComplexFW.imagp, 1, autoCorrelationTwiceFFTLength);
        vDSP_vclr(autoCorrelationSplitComplexBW.realp, 1, autoCorrelationTwiceFFTLength);
		vDSP_vclr(autoCorrelationSplitComplexBW.imagp, 1, autoCorrelationTwiceFFTLength);
        
        // Multiply samples with hamming window
        vDSP_vmul(_ris.audioBuffer,
                  1,
                  hammingWindow,
                  1,
                  _ris.audioBuffer,
                  1,
                  numberFrames);
        
        // Generate a split complex vector from the real data into odds and evens
        vDSP_ctoz((COMPLEX *)_ris.audioBuffer,
                  2,
                  &autoCorrelationSplitComplexFW,
                  1,
                  cepstrumFFTLength);
        
        // Perform forward FFT
        vDSP_fft_zip(autoCorrelationAnalyse,
                     &autoCorrelationSplitComplexFW,
                     1,
                     autoCorrelationTwiceLog2N,
                     kFFTDirection_Forward);
        
		// Get FFT squared magnitudes
		vDSP_zvmags(&autoCorrelationSplitComplexFW,
                    1,
                    autoCorrelationSplitComplexBW.realp,
                    1,
                    autoCorrelationTwiceFFTLength);
        vDSP_zvmags(&autoCorrelationSplitComplexFW,
                    1,
                    autoCorrelationSplitComplexBW.imagp,
                    1,
                    autoCorrelationTwiceFFTLength);
        
        // Zero out the nyquist value
        autoCorrelationSplitComplexBW.imagp[0] = 0.0;
        
		// Perform inverse FFT
		vDSP_fft_zip(autoCorrelationAnalyse,
                     &autoCorrelationSplitComplexBW,
                     1,
                     autoCorrelationTwiceLog2N,
                     kFFTDirection_Inverse);
        
        // Find frequency
        BOOL flag = NO;
        int f = 0;
        float max = -1.0;
        for (int i = 0; i < maxFrequency; i++) {
            if (autoCorrelationSplitComplexBW.realp[i] < 0 || autoCorrelationSplitComplexBW.imagp[i] < 0) {
                flag = YES;
            }
            if (flag) {
                if (max < autoCorrelationSplitComplexBW.realp[i]) {
                    max = autoCorrelationSplitComplexBW.realp[i];
                    f = i;
                }
                if (max < autoCorrelationSplitComplexBW.imagp[i]) {
                    max = autoCorrelationSplitComplexBW.imagp[i];
                    f = i;
                }
            }
        }
        frequency = (hardwareSampleRate / f) / 2;
        
        // Audio buffer can be overwritten with new audio
        OSAtomicDecrement32Barrier(&_ris.hasAudioData);
        _ris.audioBufferCurrentIndex = 0;
    }
    
    return frequency;
}

#pragma mark Functions

- (BOOL)isSongPlaying
{
    return [_midiFile isPlaying];
}

- (void)loadSong:(NSString *)song
{
    // Get a string to the path of the MIDI file which should be located in the Resources folder
    NSString *midiFilePath = [[NSBundle mainBundle] pathForResource:song ofType:@"mid"];
    _midiFile = [MIDIFile fileWithPath:midiFilePath];
    if (_midiFile) {
        MusicSequenceSetAUGraph(_midiFile.sequence, _processingGraph);
        
        // Obtain the Keyboard track and connect it
        MusicTrack keyboardTrack;
        MusicSequenceGetIndTrack(_midiFile.sequence, 7, &keyboardTrack);
        MusicTrackSetDestNode(keyboardTrack, _keyboardSamplerNode);
        
        // Obtain the Distortion track and connect it
        MusicTrack distortionTrack;
        MusicSequenceGetIndTrack(_midiFile.sequence, 8, &distortionTrack);
        MusicTrackSetDestNode(distortionTrack, _distortionSamplerNode);
        
        // Obtain the Bass track and connect it
        MusicTrack bassTrack;
        MusicSequenceGetIndTrack(_midiFile.sequence, 9, &bassTrack);
        MusicTrackSetDestNode(bassTrack, _bassSamplerNode);
        
        // Connect the Percussion track and connect it
        _ps.percussionSamplerUnit = _percussionSamplerUnit;
        [self connectPercussionNode:_percussionSamplerNode withPercussionState:&_ps andTrack:10 fromSequence:_midiFile.sequence];
        
        // Obtain the Overdrive track and connect it
        MusicTrack overdriveTrack;
        MusicSequenceGetIndTrack(_midiFile.sequence, 11, &overdriveTrack);
        MusicTrackSetDestNode(overdriveTrack, _overdriveSamplerNode);
        
        // Connect each String track and connect it
        [self connectStringNode:_stringE2Node withUnit:_stringE2Unit andTrack:1 fromSequence:_midiFile.sequence];
        [self connectStringNode:_stringA2Node withUnit:_stringA2Unit andTrack:2 fromSequence:_midiFile.sequence];
        [self connectStringNode:_stringD3Node withUnit:_stringD3Unit andTrack:3 fromSequence:_midiFile.sequence];
        [self connectStringNode:_stringG3Node withUnit:_stringG3Unit andTrack:4 fromSequence:_midiFile.sequence];
        [self connectStringNode:_stringH3Node withUnit:_stringH3Unit andTrack:5 fromSequence:_midiFile.sequence];
        [self connectStringNode:_stringE4Node withUnit:_stringE4Unit andTrack:6 fromSequence:_midiFile.sequence];
    }
}

- (void)playSong
{
    [_midiFile play];
}

- (void)stopSong
{
    [_midiFile stop];
}

- (float)getSongTime
{
    return [_midiFile getTime];
}

- (void)connectStringNode:(AUNode)node withUnit:(AudioUnit)unit andTrack:(UInt32)inTrackIndex fromSequence:(MusicSequence)sequence
{
    MIDIClientRef client;
    MusicTrack track;
    
    // Obtain the String track
    CheckError(MusicSequenceGetIndTrack(sequence, inTrackIndex, &track),
               "Couldn't find the String track");
    
    // Connect the String node with the track
    CheckError(MusicTrackSetDestNode(track, node),
               "Couldn't connect the String node with the track");
    
    // Create a MIDI client for the Track
    CheckError(MIDIClientCreate((__bridge CFStringRef)[NSString stringWithFormat:@"Track %i Client", (unsigned int)inTrackIndex],
                                MyMIDINotifyProc,
                                NULL,
                                &client),
               "Couldn't create a MIDI client for the track");
    
    // Create a virtual endpoint
    MIDIEndpointRef endpoint;
    CheckError(MIDIDestinationCreate(client,
                                     (__bridge CFStringRef)[NSString stringWithFormat:@"Track %i Endpoint", (unsigned int)inTrackIndex],
                                     StringMIDIReadProc,
                                     unit,
                                     &endpoint),
               "Couldn't create a virtual endpoint");
    
    // Set the endpoint of the track to be the virtual endpoint
    CheckError(MusicTrackSetDestMIDIEndpoint(track, endpoint),
               "Couldn't set the endpoint of the track");
}

- (void)connectPercussionNode:(AUNode)node withPercussionState:(PercussionState *)ps andTrack:(UInt32)inTrackIndex fromSequence:(MusicSequence)sequence
{
    MIDIClientRef client;
    MusicTrack track;
    
    // Obtain the Percussion track
    CheckError(MusicSequenceGetIndTrack(sequence, inTrackIndex, &track),
               "Couldn't find the Percussion track");
    
    // Connect the Percussion node with the track
    CheckError(MusicTrackSetDestNode(track, node),
               "Couldn't connect the Percussion node with the track");
    
    // Create a MIDI client for the Track
    CheckError(MIDIClientCreate((__bridge CFStringRef)[NSString stringWithFormat:@"Track %i Client", (unsigned int)inTrackIndex],
                                MyMIDINotifyProc,
                                NULL,
                                &client),
               "Couldn't create a MIDI client for the track");
    
    // Create a virtual endpoint
    MIDIEndpointRef endpoint;
    CheckError(MIDIDestinationCreate(client,
                                     (__bridge CFStringRef)[NSString stringWithFormat:@"Track %i Endpoint", (unsigned int)inTrackIndex],
                                     PercussionMIDIReadProc,
                                     ps,
                                     &endpoint),
               "Couldn't create a virtual endpoint");
    
    // Set the endpoint of the track to be the virtual endpoint
    CheckError(MusicTrackSetDestMIDIEndpoint(track, endpoint),
               "Couldn't set the endpoint of the track");
}

#pragma mark Settings

- (void)setAmplitudeDriven:(BOOL)enable
{
    _ris.isAmplitudeDriven = enable;
}

- (BOOL)detectAttack
{
    BOOL result = _ris.detectAttack;
    if (_ris.detectAttack) {
        OSAtomicDecrement32Barrier(&_ris.detectAttack);
    }
    return result;
}

- (BOOL)detectMute
{
    BOOL result = _ris.detectMute;
    if (_ris.detectMute) {
        OSAtomicDecrement32Barrier(&_ris.detectMute);
    }
    return result;
}

- (BOOL)detectEvenPercussion
{
    BOOL result = _ps.detectEvenNote;
    if (_ps.detectEvenNote) {
        OSAtomicDecrement32Barrier(&_ps.detectEvenNote);
    }
    return result;
}

- (BOOL)detectOddPercussion
{
    BOOL result = _ps.detectOddNote;
    if (_ps.detectOddNote) {
        OSAtomicDecrement32Barrier(&_ps.detectOddNote);
    }
    return result;
}

- (void)setStringVolume:(AudioUnitParameterValue)volume
{
    CheckError(AudioUnitSetParameter(_stringMixerUnit,
                                     kMultiChannelMixerParam_Volume,
                                     kAudioUnitScope_Output,
                                     0,
                                     volume,
                                     0),
               "Couldn't set the output volume for String Mixer unit");
}

- (void)setGuitarVolume:(AudioUnitParameterValue)volume
{
    CheckError(AudioUnitSetParameter(_masterMixerUnit,
                                     kMultiChannelMixerParam_Volume,
                                     kAudioUnitScope_Input,
                                     6,
                                     volume,
                                     0),
               "Couldn't set the output volume for String Mixer unit");
}

@end
