//
//  TQGameAudio.h
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 3/31/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCActionInterval.h"
#import "CocosDenshion.h"
#import "CDAudioManager.h"
#import "SimpleAudioEngine.h"

/** @defgroup audio Audio
 *  @brief Audio engine and service
 *  @{
 */

typedef enum {
	AUDIOCTRL_NOOP = 0,
	AUDIOCTRL_PLAY,
	AUDIOCTRL_STOP,
	AUDIOCTRL_PAUSE,
	AUDIOCTRL_RESUME
} kTQGameAudioControl;

/**
 *  @brief A powerful sound engine to manage the audio effects and background music.
 *  @details It is more much more powerful than CocosDension's SimpleSoundEngine.
 */
@interface TQGameAudio : CDAudioManager {
    /** Audio sources for background musics */
	NSMutableDictionary *longAudioSources_;
    /** Sound buffer manager */
    CDBufferManager *bufferManager_;
    /** The sound effects that have been registered to objects */
    NSMutableDictionary *registeredSoundEffects_;
	
    /** Whether the sound engine should perform power metering */
	BOOL meteringEnabled_;
    /** Float array internally used to store average power level for each channel */
	float *powerLevelAverage_;
    /** Float array internally used to store maximum power level for each channel */
    float *powerLevelMax_;
	
	/** The kTQGameAudioControl value that is triggered when background music is muted */
	kTQGameAudioControl bgmMutedControl_;
    /** The filename of current background music */
    NSString *currentBgmFile_;
    /** The last kTQGameAudioControl value */
    kTQGameAudioControl lastControl_;
    /** Mute control for background music */
    BOOL muteBackgroundMusic_;
    /** Mute control for sound effect */
    BOOL muteSoundEffect_;
    /** Volume control for background music */
    float backgroundMusicVolume_;
    /** Volume control for sound effect (0.0 <= value <= 1.0) */
    float soundEffectVolume_;
}

/** The filename of current background music */
@property (nonatomic, readonly) NSString *currentBgmFile;
/** The last kTQGameAudioControl value */
@property (nonatomic, readonly) kTQGameAudioControl lastControl;
/** Mute control for background music */
@property (nonatomic, assign) BOOL muteBackgroundMusic;
/** Mute control for sound effect */
@property (nonatomic, assign) BOOL muteSoundEffect;
/** Volume control for background music */
@property (nonatomic, assign) float backgroundMusicVolume;
/** Volume control for sound effect (0.0 <= value <= 1.0) */
@property (nonatomic, assign) float soundEffectVolume;

/**
 * Get shared singleton instance. Instantiate if not exist.
 */
+ (TQGameAudio *)sharedAudio;

/**
 * Get shared singleton instance. Return nil if not exist.
 * Use this method when it is not necessary to instantiate and start up the sound engine.
 */
+ (TQGameAudio *)sharedAudioOptional;

/**
 * Get shared singleton instance. Instantiate if not exist.
 *  @deprecated Deprecated. Use TQGameAudio::sharedAudio: instead
 */
+ (TQGameAudio *)sharedInstance;

/**
 * Get shared singleton instance. Return nil if not exist.
 * Use this method when it is not necessary to instantiate and start up the sound engine.
 *  @deprecated Deprecated. Use TQGameAudio::sharedAudioOptional: instead
 */
+ (TQGameAudio *)sharedInstanceOptional;

/**
 * Load a background music file
 *  @param bgmfile The filename of the background music
 *  @return The loaded music in the form of CDLongAudioSource object
 */
- (CDLongAudioSource *)audioBackgroundLoad:(NSString *)bgmfile;

/**
 * Play background music
 *  @param bgmfile The filename of the music to play
 *  @param fade The amount of cross-fading between current song to the new song in seconds
 */
- (void)audioBackgroundPlay:(NSString *)bgmfile crossfade:(float)fade;

/**
 * Control background music playback
 *  @param audioControl The kTQGameAudioControl enum value that dictates which action to do
 *  @param fade The amount of fading (in or out depending on control value) in seconds
 */
- (void)audioBackgroundControl:(kTQGameAudioControl)audioControl fade:(float)fade;

/**
 * Get background music duration
 *  @return The duration in seconds
 */
- (NSTimeInterval)audioBackgroundDuration;

/**
 * Jump the playback of background music to a specific time offset
 *  @param time The time offset to jump to in seconds (and a fraction of)
 */
- (void)audioBackgroundGotoTimeOffset:(NSTimeInterval)time;

/**
 * Preload a sound effect
 *  @param fxfile The filename of the sound effect
 *  @return Boolean value indicating if the preloading was successful or not
 */
- (BOOL)audioEffectPreload:(NSString *)fxfile;

/**
 * Play a sound effect
 *  @param fxfile The filename of the sound effect
 *  @return The sound effect id
 */
- (ALuint)audioEffectPlay:(NSString *)fxfile;

/**
 * Play a sound effect
 *  @param fxfile The filename of the sound effect
 *  @param checkplaying YES to make sure the sound does not play if it's already played
 *  @return The sound effect id
 */
- (ALuint)audioEffectPlay:(NSString *)fxfile onlyWhenNotPlaying:(BOOL)checkplaying;

/**
 * Stop a sound effect
 *  @param effectId The sound effect id from audioEffectPlay: method
 */
- (void)audioEffectStop:(ALuint)effectId;

/**
 * Stop all sound effects
 */
- (void)audioEffectStopAll;

/**
 * Register sound effect for specific object, so that you don't have to store the sound file name to trigger later
 *  @param fxfile The filename of the sound effect
 *  @param object The object to attach the sound effect to
 */
- (void)registerSoundEffect:(NSString *)fxfile forObject:(const void*)object;

/**
 * Trigger registered sound effect for specific object
 *  @param object The object to trigger the sound effect
 *  @return The sound effect id
 */
- (ALuint)triggerSoundEffectForObject:(const void*)object;

/**
 * Enable metering for reading audio power level
 * @param enable YES/TRUE to enable, NO/FALSE to disable
 */
- (void)enableMetering:(BOOL)enable;

/**
 * Get current average power level for specific channel
 */
- (float)averagePowerLevelForChannel:(uint)channel;

/**
 * Get current maximum power level for specific channel
 */
- (float)maxPowerLevelForChannel:(uint)channel;

/**
 * Purge loaded background music data that are not currently in use (for memory low warning)
 */
- (void)purgeIdleBackgroundMusicData;

@end

@interface TQAudioFadeAction : CCActionInterval {
	CDLongAudioSourceFader *fader_;
	float lastSetValue_;
}

+ (id)actionWithDuration:(ccTime)t andFader:(CDLongAudioSourceFader *)fader;

- (id)initWithDuration:(ccTime)t andFader:(CDLongAudioSourceFader *)fader;

@end

@interface CDSoundEngine (TumeriQ)

/**
 * Check if the sound with specific soundId is playing or not
 *  @return TRUE if the sound is playing, FALSE otherwise
 */
- (BOOL)isSoundPlaying:(int)soundId;

@end

/** @} */ // end of audio

