//
//  TQGameAudio.mm
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 3/31/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import "TQGameAudio.h"
#import "cocos2d.h"

@interface TQGameAudio (Private)
- (void)_audioBackgroundFadeOut:(float)fade thenStop:(BOOL)stop;
- (void)_audioBackgroundFadeIn:(float)fade;
@end

@implementation TQGameAudio
@synthesize currentBgmFile = currentBgmFile_, lastControl = lastControl_;
@synthesize muteBackgroundMusic = muteBackgroundMusic_, muteSoundEffect = muteSoundEffect_;
@synthesize backgroundMusicVolume = backgroundMusicVolume_, soundEffectVolume = soundEffectVolume_;

static TQGameAudio *sharedTQGameAudio = nil;

+ (TQGameAudio *)sharedAudio {
    if (sharedTQGameAudio == nil) {
        sharedTQGameAudio = [[super allocWithZone:NULL] init];
    }
    return sharedTQGameAudio;
}

+ (TQGameAudio *)sharedAudioOptional {
    return sharedTQGameAudio;
}

+ (TQGameAudio *)sharedInstance {
    return [self sharedAudio];
}

+ (TQGameAudio *)sharedInstanceOptional {
    return [self sharedAudioOptional];
}

+ (id)allocWithZone:(NSZone *)zone {    
    return [[self sharedInstance] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)init {
	self = [super init:kAMM_FxPlusMusicIfNoOtherAudio];
	if (self) {
		longAudioSources_ = [[NSMutableDictionary alloc] init];
		powerLevelAverage_ = new float[10];
		powerLevelMax_ = new float[10];
		bufferManager_ = [[CDBufferManager alloc] initWithEngine:soundEngine];
        backgroundMusic = nil;
        currentBgmFile_ = nil;
        registeredSoundEffects_ = [[NSMutableDictionary alloc] init];
        backgroundMusicVolume_ = 1.0f;
        soundEffectVolume_ = 1.0f;
        
        // for memory warning
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purgeIdleBackgroundMusicData) 
                                                     name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	}
	return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release {}

- (id)autorelease {
    return self;
}

- (void)dealloc {
	delete powerLevelMax_;
	delete powerLevelAverage_;
	[backgroundMusic release];
	[longAudioSources_ release];
    [registeredSoundEffects_ release];
    [currentBgmFile_ release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark Volume and mute controls

- (void)setBackgroundMusicVolume:(float)backgroundMusicVolume {
    backgroundMusicVolume_ = MAX(0.0f, MIN(1.0f, backgroundMusicVolume));
    backgroundMusic.volume = backgroundMusicVolume_;
}

- (void)setSoundEffectVolume:(float)soundEffectVolume {
    soundEffectVolume_ = MAX(0.0f, MIN(1.0f, soundEffectVolume));
    soundEngine.masterGain = soundEffectVolume_;
}

- (void)setMute:(BOOL)muteValue {
	if (muteValue != _mute) {
		_mute = muteValue;
        [self setMuteBackgroundMusic:_mute];
        [self setMuteSoundEffect:_mute];
	}
}

- (void)setMuteBackgroundMusic:(BOOL)muteBackgroundMusic {
    if (muteBackgroundMusic != muteBackgroundMusic_) {
        muteBackgroundMusic_ = muteBackgroundMusic;
		for (NSString *sourceName in longAudioSources_) {
			CDLongAudioSource *audioSource = (CDLongAudioSource *)[longAudioSources_ objectForKey:sourceName];
			audioSource.mute = muteBackgroundMusic_;
		}
		if (!muteBackgroundMusic_) {
			[self audioBackgroundControl:bgmMutedControl_ fade:0.0];
            bgmMutedControl_ = AUDIOCTRL_NOOP;
		}
    }
}

- (void)setMuteSoundEffect:(BOOL)muteSoundEffect {
    if (muteSoundEffect != muteSoundEffect_) {
        muteSoundEffect_ = muteSoundEffect;
		[soundEngine setMute:muteSoundEffect_];
    }
}

#pragma mark Background Music

- (CDLongAudioSource *)audioBackgroundLoad:(NSString *)bgmfile {
	CDLongAudioSource *audioSource = [longAudioSources_ objectForKey:bgmfile];
	if (!audioSource) {
		audioSource = [[CDLongAudioSource alloc] init];
		[audioSource load:bgmfile];
		[audioSource setNumberOfLoops:-1]; // infinite looping
		[longAudioSources_ setObject:audioSource forKey:bgmfile];
		[audioSource autorelease];
	}
	return audioSource;
}

- (void)audioBackgroundPlay:(NSString *)bgmfile crossfade:(float)fade {
	CDLongAudioSource *audioSource = [self audioBackgroundLoad:bgmfile];
	if (audioSource != backgroundMusic) {
		if (backgroundMusic) {
			[self audioBackgroundControl:AUDIOCTRL_STOP fade:fade];
			backgroundMusic.audioSourcePlayer.meteringEnabled = NO;
			[backgroundMusic release];
		}
		backgroundMusic = [audioSource retain];
		if (meteringEnabled_) {
			backgroundMusic.audioSourcePlayer.meteringEnabled = YES;
		}
        [currentBgmFile_ release];
        currentBgmFile_ = [bgmfile copy];
	}
    if (![backgroundMusic isPlaying] || muteBackgroundMusic_) {
        [self audioBackgroundControl:AUDIOCTRL_PLAY fade:fade];
    }
}

- (void)audioBackgroundControl:(kTQGameAudioControl)audioControl fade:(float)fade {
    if (muteBackgroundMusic_) {
        // since it's muted so don't do anything
        bgmMutedControl_ = audioControl;
        return;
    }
	switch (audioControl) {
		case AUDIOCTRL_PLAY:
			[backgroundMusic rewind];
			[backgroundMusic play];
			if (fade > 0.0) {
                backgroundMusic.volume = 0.0f;
				[self _audioBackgroundFadeIn:fade];
			}
            else {
                backgroundMusic.volume = backgroundMusicVolume_;
            }
			break;
		case AUDIOCTRL_STOP:
			if (fade > 0.0) {
				[self _audioBackgroundFadeOut:fade thenStop:YES];
			}
			else {
				[backgroundMusic stop];
			}
			break;
		case AUDIOCTRL_PAUSE:
			if (fade > 0.0) {
				[self _audioBackgroundFadeOut:fade thenStop:NO];
			}
			else {
				[backgroundMusic pause];
			}
			break;
		case AUDIOCTRL_RESUME:
			[backgroundMusic resume];
			if (fade > 0.0) {
				[self _audioBackgroundFadeIn:fade];
			}
            else {
                backgroundMusic.volume = backgroundMusicVolume_;
            }
			break;
		default:
			// do nothing
			break;
	}
    lastControl_ = audioControl;
}

- (NSTimeInterval)audioBackgroundDuration {
    return backgroundMusic.audioSourcePlayer.duration;
}

- (void)audioBackgroundGotoTimeOffset:(NSTimeInterval)time {
    backgroundMusic.audioSourcePlayer.currentTime = time;
}

- (void)_audioBackgroundFadeOut:(float)fade thenStop:(BOOL)stop {
	__block CDLongAudioSource *fadeOutSource = [backgroundMusic retain];
    if (fadeOutSource) {
        CDLongAudioSourceFader* fadeOut = [[CDLongAudioSourceFader alloc] init:fadeOutSource interpolationType:kIT_Linear 
                                                                      startVal:fadeOutSource.volume endVal:0.0f];
        CCActionInterval *fadeOutAction = [TQAudioFadeAction actionWithDuration:fade andFader:fadeOut];
        if (stop) {
            fadeOutAction = [CCSequence actions:fadeOutAction,
                             [CCCallBlock actionWithBlock:^{
                if ((self.lastControl != AUDIOCTRL_PLAY && self.lastControl != AUDIOCTRL_RESUME)
                    || self.backgroundMusic != fadeOutSource) {
                    // only stop if there is no play/resume command or if the current bgm has changed file
                    [fadeOutSource stop];
                    [fadeOutSource release];
                }
            }], nil];
        }
        [[CCDirector sharedDirector].actionManager addAction:fadeOutAction target:fadeOutSource paused:NO];
        [fadeOut release];
    }
}

- (void)_audioBackgroundFadeIn:(float)fade {
	CDLongAudioSource *fadeInSource = backgroundMusic;
    if (fadeInSource) {
        CDLongAudioSourceFader* fadeIn = [[CDLongAudioSourceFader alloc] init:fadeInSource interpolationType:kIT_Linear 
                                                                     startVal:0.0f endVal:backgroundMusicVolume_];
        TQAudioFadeAction *fadeInAction = [TQAudioFadeAction actionWithDuration:fade andFader:fadeIn];				
        [[CCDirector sharedDirector].actionManager addAction:fadeInAction target:fadeInSource paused:NO];				
        [fadeIn release];
    }
}

#pragma mark Sound Effect

- (BOOL)audioEffectPreload:(NSString *)fxfile {
    return ([bufferManager_ bufferForFile:fxfile create:YES] != kCDNoBuffer);
}

- (ALuint)audioEffectPlay:(NSString *)fxfile {
    return [self audioEffectPlay:fxfile onlyWhenNotPlaying:NO];
}

- (ALuint)audioEffectPlay:(NSString *)fxfile onlyWhenNotPlaying:(BOOL)checkplaying {
    int soundId = [bufferManager_ bufferForFile:fxfile create:YES];
	if (soundId != kCDNoBuffer) {
        if (!checkplaying || ![soundEngine isSoundPlaying:soundId]) {
            return [soundEngine playSound:soundId sourceGroupId:0 pitch:1 pan:0 gain:1 loop:false];
        }
	} 
    return CD_MUTE;
}

- (void)audioEffectStop:(ALuint)effectId {
	[soundEngine stopSound:effectId];
}

- (void)audioEffectStopAll {
	[soundEngine stopAllSounds];
}

- (void)registerSoundEffect:(NSString *)fxfile forObject:(const void*)object {
    [self audioEffectPreload:fxfile];
    [registeredSoundEffects_ setObject:fxfile forKey:[NSValue valueWithPointer:object]];
}

- (ALuint)triggerSoundEffectForObject:(const void*)object {
    NSString *fxfile = [registeredSoundEffects_ objectForKey:[NSValue valueWithPointer:object]];
    if (fxfile) {
        return [self audioEffectPlay:fxfile];
    }
    else {
        return 0;
    }
}

#pragma mark Power Metering

- (void)enableMetering:(BOOL)enable {
	if (enable != meteringEnabled_) {
		meteringEnabled_ = enable;
		backgroundMusic.audioSourcePlayer.meteringEnabled = enable;
		if (enable) {
			[[CCDirector sharedDirector].scheduler scheduleSelector:@selector(tick:) forTarget:self interval:0 paused:NO];
		}
		else {
			[[CCDirector sharedDirector].scheduler unscheduleSelector:@selector(tick:) forTarget:self];
		}
	}
}

- (float)averagePowerLevelForChannel:(uint)channel {
	if (channel >= backgroundMusic.audioSourcePlayer.numberOfChannels) {
		return 0.0f;
	}
	return powerLevelAverage_[channel];
}

- (float)maxPowerLevelForChannel:(uint)channel {
	if (channel >= backgroundMusic.audioSourcePlayer.numberOfChannels) {
		return 0.0f;
	}
	return powerLevelMax_[channel];
}

- (void)tick:(ccTime)dt {
	AVAudioPlayer *player = backgroundMusic.audioSourcePlayer;
	if (![player isPlaying]) {
		return;
	}

	float filterSmooth = 0.2f;
	if (powerLevelMax_ && powerLevelAverage_) {
		[player updateMeters];
		double peakPowerForChannel = 0.f, avgPowerForChannel = 0.f;
		for (uint i = 0; i < player.numberOfChannels; ++i) {
			//	convert the -160 to 0 dB to [0..1] range
			peakPowerForChannel = pow(10, (0.05 * [player peakPowerForChannel:i]));
			avgPowerForChannel = pow(10, (0.05 * [player averagePowerForChannel:i]));
			powerLevelMax_[i] = filterSmooth * peakPowerForChannel + (1.0 - filterSmooth) * powerLevelMax_[i];
			powerLevelAverage_[i] = filterSmooth * avgPowerForChannel + (1.0 - filterSmooth) * powerLevelAverage_[i];
		}		
	}
}

- (void)purgeIdleBackgroundMusicData {
    id currentBgmKey = nil;
    for (id key in longAudioSources_) {
        if ([longAudioSources_ objectForKey:key] == backgroundMusic) {
            currentBgmKey = key;
            break;
        }
    }
    [longAudioSources_ removeAllObjects];
    if (currentBgmKey) {
        [longAudioSources_ setObject:backgroundMusic forKey:currentBgmKey];
    }
}

@end

@implementation TQAudioFadeAction

+ (id)actionWithDuration:(ccTime)t andFader:(CDLongAudioSourceFader *)fader {
	return [[[self alloc] initWithDuration:t andFader:fader] autorelease];
}	

- (id)initWithDuration:(ccTime)t andFader:(CDLongAudioSourceFader *)fader {
	self = [super initWithDuration: t];
	if (self) {	
		if (fader_) {
			[fader_ release];
		}	
		fader_ = [fader retain];
		lastSetValue_ = [fader_ _getTargetProperty];
	}
	return self;
}	

- (void)dealloc {
	[fader_ release];
	[super dealloc];
}	

- (id)copyWithZone:(NSZone*)zone {
	TQAudioFadeAction *copy = [[[self class] allocWithZone:zone] initWithDuration:[self duration] andFader:fader_];
	return copy;
}

- (void)update:(ccTime)t {
	//Check if modified property has been externally modified and if so bail out
	if ([fader_ _getTargetProperty] != lastSetValue_) {
		[[CCDirector sharedDirector].actionManager removeAction:self];
		return;
	}	
	[fader_ modify:t];
	lastSetValue_ = [fader_ _getTargetProperty];
}

@end

@implementation CDSoundEngine (TumeriQ)

- (BOOL)isSoundPlaying:(int)soundId {
    ALuint buffer = _buffers[soundId].bufferId;
    
    for (int sourceIndex = 0; sourceIndex < sourceTotal_; sourceIndex++) {
        ALint buffer2 = 0;
        ALuint source = _sources[sourceIndex].sourceId;
        alGetSourcei(source, AL_BUFFER, &buffer2);
        if (buffer == buffer2) {
            ALint state;
            alGetSourcei(source, AL_SOURCE_STATE, &state);
            if (state == AL_PLAYING) {
                return YES;
            }	
        }
    }
    return NO;
}

@end
