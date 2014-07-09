//
//  MIDIFile.h
//  Guitar
//
//  Created by Raimund on 01.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import <AudioToolbox/MusicPlayer.h>

#define MIDI_NOTE_TIMESTAMP_KEY @"ts"
#define MIDI_NOTE_DURATION_KEY @"dr"
#define MIDI_NOTE_PITCH_KEY @"pt"
#define MIDI_NOTE_TRACK_KEY @"tk"
#define MIDI_NOTE_FRET_KEY @"fr"
#define MIDI_NOTE_STRING_KEY @"st"

@interface MIDIFile : NSObject {
@private
	MusicPlayer player;
	MusicTimeStamp sequenceLength;
	NSTimer *checkTimer;
}

@property (nonatomic, readonly) MusicSequence sequence;
@property (nonatomic, readonly) BOOL isPlaying;

+ (id)fileWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path;

- (MusicTimeStamp)beatsForSeconds:(Float64)seconds;
- (NSDictionary *)getStringNotes;
- (MusicTimeStamp)getTime;

- (BOOL)play;
- (BOOL)stop;

@end
