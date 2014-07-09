//
//  MIDIFile.m
//  Guitar
//
//  Created by Raimund on 01.10.13.
//  Copyright (c) 2013 Raimund Wege. All rights reserved.
//

#import "MIDIFile.h"

#define DEFAULT_BPM 80
#define DEFAULT_STRING_COUNT 6

// Standard tuning
UInt8 const stringNotes[] = {40, 45, 50, 55, 59, 64};

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
        
		if (MusicSequenceFileLoad(_sequence, (__bridge CFURLRef)url, 0, 0) != noErr) {
			return nil;
		}
        
        // Getting the tempo track and set it to default bpm
        MusicTrack tempoTrack;
        MusicSequenceGetTempoTrack(_sequence, &tempoTrack);
        MusicTrackClear(tempoTrack, 0, 1);
        MusicTrackNewExtendedTempoEvent(tempoTrack, 0, DEFAULT_BPM);
	}
	return self;
}

- (MusicTimeStamp)beatsForSeconds:(Float64)seconds
{
	MusicTimeStamp beats = 0;
	MusicSequenceGetBeatsForSeconds(_sequence, 1.0, &beats);
	return beats;
}

- (NSDictionary *)getStringNotes
{
    // Get track count
	UInt32 tracksCount = 0;
	if (MusicSequenceGetTrackCount(_sequence, &tracksCount) != noErr)
		return [[NSDictionary alloc] init];
	
    // Iterate through tracks
	NSMutableDictionary *notesDict = [[NSMutableDictionary alloc] init];
	for (int i = 0; i < tracksCount; i++) {
        
        // Get track
        MusicTrack track = nil;
        if (MusicSequenceGetIndTrack(_sequence, i, &track) != noErr)
            continue;
        
        // Iterate through events
        MusicEventIterator iterator = nil;
        NewMusicEventIterator(track, &iterator);
        while ([self hasNextEvent:iterator]) {
            MusicEventIteratorNextEvent(iterator);
            MusicTimeStamp timestamp = 0;
            MusicEventType eventType = 0;
            const void *eventData = nil;
            UInt32 eventDataSize = 0;
            MusicEventIteratorGetEventInfo(iterator, &timestamp, &eventType, &eventData, &eventDataSize);
            
            // Collect only note messages
            if (eventType == kMusicEventType_MIDINoteMessage) {
                const MIDINoteMessage *noteMessage = (const MIDINoteMessage *)eventData;
                
                // Get all string notes
                if (noteMessage->channel < DEFAULT_STRING_COUNT) {
                    
                    // Get notes for the current timestamp
                    NSArray *oldNoteArray;
                    NSMutableArray *newNoteArray;
                    NSNumber *key = [NSNumber numberWithDouble:timestamp];
                    oldNoteArray = [notesDict objectForKey:key];
                    if (oldNoteArray) {
                        newNoteArray = [oldNoteArray mutableCopy];
                    } else {
                        newNoteArray = [[NSMutableArray alloc] init];
                    }
                    
                    // Calculate string and fret for the note
                    int string = noteMessage->channel;
                    int fret = noteMessage->note - stringNotes[string];
                    
                    // Create an object for the note
                    NSDictionary *noteDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithFloat:timestamp], MIDI_NOTE_TIMESTAMP_KEY,
                                              [NSNumber numberWithFloat:noteMessage->duration], MIDI_NOTE_DURATION_KEY,
                                              [NSNumber numberWithShort:noteMessage->note], MIDI_NOTE_PITCH_KEY,
                                              [NSNumber numberWithInt:i], MIDI_NOTE_TRACK_KEY,
                                              [NSNumber numberWithInt:fret], MIDI_NOTE_FRET_KEY,
                                              [NSNumber numberWithInt:string], MIDI_NOTE_STRING_KEY, nil];
                    
                    // Add the note dict to the new note array
                    [newNoteArray addObject:noteDict];
                    
                    // Save the new note array to the notes dict
                    [notesDict setObject:newNoteArray forKey:key];
                }
            }
        }
        DisposeMusicEventIterator(iterator);
	}
	return notesDict;
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
	
	MusicPlayerSetTime(player, 0.0);
	
	if (MusicPlayerStart(player) != noErr)
		return NO;
	
	checkTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkForEnd:) userInfo:nil repeats:YES];
    
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
	MusicTimeStamp time = 0.0;
	MusicPlayerGetTime(player, &time);
	if (time > sequenceLength) {
		[self stop];
	}
}

- (MusicTimeStamp)getTime
{
	MusicTimeStamp time = 0.0;
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
	MusicTimeStamp len = 0.0;
	
	if (MusicSequenceGetTrackCount(_sequence, &tracks) != noErr)
		return len;
	
	for (UInt32 i = 0; i < tracks; i++) {
		MusicTrack track = NULL;
		MusicTimeStamp trackLen = 0.0;
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
