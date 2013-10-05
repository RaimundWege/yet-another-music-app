//
//  MIDIFile.m
//  Guitar
//
//  Created by Raimund on 01.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "MIDIFile.h"

@interface MIDIFile ()

- (void)checkForEnd:(NSTimer *)timer;
- (BOOL)hasNextEvent:(MusicEventIterator)iterator;
- (MusicTimeStamp)getSequenceLength:(MusicSequence)aSequence;

@end

NSString *const MIDINoteTimestampKey = @"ts";
NSString *const MIDINoteDurationKey = @"dr";
NSString *const MIDINotePitchKey = @"pt";
NSString *const MIDINoteTrackIndexKey = @"tk";
NSString *const MIDINoteFretKey = @"fr";
NSString *const MIDINoteStringKey = @"st";

//int const stringNotes[] = {64, 69, 74, 79, 83, 88};
int const stringNotes[] = {52, 57, 62, 67, 71, 76};

@implementation MIDIFile

@dynamic isPlaying;

+ (id)fileWithPath:(NSString *)path
{
	return [[self alloc] initWithPath:path];
}

- (id)initWithPath:(NSString *)path
{
	self = [super init];
	if (self) {
		NSURL *url = [NSURL fileURLWithPath:path];
		
		NewMusicSequence(&_sequence);

		if (MusicSequenceFileLoad(_sequence, (__bridge CFURLRef)url, 0, kMusicSequenceLoadSMF_ChannelsToTracks) != noErr) {
			return nil;
		}
        
        // Getting the tempo track and set it to 80 bpm
        MusicTrack tempoTrack;
        MusicSequenceGetTempoTrack(_sequence, &tempoTrack);
        MusicTrackClear(tempoTrack, 0, 1);
        MusicTrackNewExtendedTempoEvent(tempoTrack, 0, 80.0);
	}
	return self;
}

- (MusicTimeStamp)beatsForSeconds:(Float64)seconds
{
	MusicTimeStamp beats = 0;
	MusicSequenceGetBeatsForSeconds(_sequence, 1.0f, &beats);
	return beats;
}

- (NSArray *)notes
{
	UInt32 tracksCount = 0;
	
	if (MusicSequenceGetTrackCount(_sequence, &tracksCount) != noErr)
		return nil;
	
	NSMutableArray *notes = [[NSMutableArray alloc] init];
	for (UInt32 i = 0; i < tracksCount; i++) {
        NSArray *trackNotes = [self notesForTrack:i];
        if (trackNotes) {
            [notes addObjectsFromArray:trackNotes];
        }
	}
	return notes;
}

- (NSArray *)notesForTrack:(int)inTrackIndex
{
    MusicTrack track = NULL;
    
    if (MusicSequenceGetIndTrack(_sequence, inTrackIndex, &track) != noErr)
        return nil;
    
	NSMutableArray *notes = [[NSMutableArray alloc] init];    
    
    MusicEventIterator iterator = NULL;
    NewMusicEventIterator(track, &iterator);
    while ([self hasNextEvent:iterator]) {
        MusicEventIteratorNextEvent(iterator);
        MusicTimeStamp timestamp = 0;
        MusicEventType eventType = 0;
        const void *eventData = NULL;
        UInt32 eventDataSize = 0;
        MusicEventIteratorGetEventInfo(iterator, &timestamp, &eventType, &eventData, &eventDataSize);
        if (eventType == kMusicEventType_MIDINoteMessage) {
            const MIDINoteMessage *noteMessage = (const MIDINoteMessage *)eventData;
            
            if (noteMessage->note < stringNotes[0])
                NSLog(@"Note %i is not playable on a guitar in standard tuning", noteMessage->note);
            
            int idealString = 0;
            for (int i = 1; i < 6; i++) {
                if (noteMessage->note < stringNotes[i])
                    break;
                idealString = i;
            }
            
            NSDictionary *note = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithFloat:timestamp], MIDINoteTimestampKey,
                                  [NSNumber numberWithFloat:noteMessage->duration], MIDINoteDurationKey,
                                  [NSNumber numberWithShort:noteMessage->note], MIDINotePitchKey,
                                  [NSNumber numberWithInt:inTrackIndex], MIDINoteTrackIndexKey,
                                  [NSNumber numberWithInt:idealString], MIDINoteFretKey,
                                  [NSNumber numberWithInt:noteMessage->note - stringNotes[idealString]], MIDINoteStringKey, nil];
            [notes addObject:note];
        }
    }
    DisposeMusicEventIterator(iterator);
	return notes;
}

- (BOOL)play
{
	if (!player) {
		NewMusicPlayer(&player);
		MusicPlayerSetSequence(player, _sequence);
		MusicPlayerPreroll(player);
	} else {
		if (self.isPlaying) {
			[self stop];
			return NO;
		}
	}
	
	sequenceLength = [self getSequenceLength:_sequence];
	
	MusicPlayerSetTime(player, 0.0f);
	
	if (MusicPlayerStart(player) != noErr)
		return NO;
	
	checkTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(checkForEnd:) userInfo:nil repeats:YES];
    
	return YES;
}

- (BOOL)stop
{
	if (!self.isPlaying)
		return NO;
	
	[checkTimer invalidate];
	
	[self willChangeValueForKey:@"isPlaying"];
	MusicPlayerStop(player);
	[self didChangeValueForKey:@"isPlaying"];
	
	return YES;
}

- (BOOL)isPlaying
{
	Boolean playing = NO;
	MusicPlayerIsPlaying(player, &playing);
	return (BOOL)playing;
}

- (void)checkForEnd:(NSTimer *)timer
{
	MusicTimeStamp time = 0.0f;
	MusicPlayerGetTime(player, &time);
	if (time > sequenceLength) {
		[self stop];
	}
}

- (MusicTimeStamp)getTime
{
	MusicTimeStamp time = 0.0f;
	MusicPlayerGetTime(player, &time);
    return time;
}

- (BOOL)hasNextEvent:(MusicEventIterator)iterator
{
	Boolean hasNext = NO;
	MusicEventIteratorHasNextEvent(iterator, &hasNext);
	return (BOOL)hasNext;
}

- (MusicTimeStamp)getSequenceLength:(MusicSequence)aSequence
{
	UInt32 tracks;
	MusicTimeStamp len = 0.0f;
	
	if (MusicSequenceGetTrackCount(_sequence, &tracks) != noErr)
		return len;
	
	for (UInt32 i = 0; i < tracks; i++) {
		MusicTrack track = NULL;
		MusicTimeStamp trackLen = 0;
		
		UInt32 trackLenLen = sizeof(trackLen);
		
		MusicSequenceGetIndTrack(_sequence, i, &track);
		MusicTrackGetProperty(track, kSequenceTrackProperty_TrackLength, &trackLen, &trackLenLen);
		
		if (len < trackLen) {
			len = trackLen;
        }
	}
	
	return len;
}

- (void)finalize
{
	DisposeMusicPlayer(player);
	DisposeMusicSequence(_sequence);
	[super finalize];
}

@end
