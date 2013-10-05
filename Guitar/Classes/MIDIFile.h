//
//  MIDIFile.h
//  Guitar
//
//  Created by Raimund on 01.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import <AudioToolbox/MusicPlayer.h>

extern NSString *const MIDINoteTimestampKey;
extern NSString *const MIDINoteDurationKey;
extern NSString *const MIDINotePitchKey;
extern NSString *const MIDINoteTrackIndexKey;
extern NSString *const MIDINoteFretKey;
extern NSString *const MIDINoteStringKey;

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
- (NSArray *)notes;
- (NSArray *)notesForTrack:(int)inTrackIndex;

- (MusicTimeStamp)getTime;

- (BOOL)play;
- (BOOL)stop;

@end
