//
//  TQGameplay.h
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 3/6/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "TQGameDataStructure.h"

/** @defgroup gameplay Gameplay
 *  @brief Central mechanism for managing and executing gameplay rules (e.g. score, lives etc)
 *  @{
 */

typedef NSString* TQGameplayEvent;

#define EVT_OBJ_HIT @"EVT_OBJ_HIT"
#define EVT_OBJ_MISSED @"EVT_OBJ_MISSED"
#define EVT_OBJ_ENTERED @"EVT_OBJ_ENTERED"
#define EVT_OBJ_EXITED @"EVT_OBJ_EXITED"
// touch related events
#define EVT_OBJ_TOUCHED @"EVT_OBJ_TOUCHED"
#define EVT_OBJ_HELD @"EVT_OBJ_HELD"
#define EVT_OBJ_RELEASED @"EVT_OBJ_RELEASED"
// result of rules evaluation
#define EVT_OBJ_EVALUATED @"EVT_OBJ_EVALUATED"
#define EVT_OBJ_IGNORED @"EVT_OBJ_IGNORED"
// some extra custom events
#define EVT_OBJ_CUSTOM1 @"EVT_OBJ_CUSTOM1"
#define EVT_OBJ_CUSTOM2 @"EVT_OBJ_CUSTOM2"
#define EVT_OBJ_CUSTOM3 @"EVT_OBJ_CUSTOM3"
#define EVT_OBJ_CUSTOM4 @"EVT_OBJ_CUSTOM4"
#define EVT_OBJ_CUSTOM5 @"EVT_OBJ_CUSTOM5"

typedef uint TQGameplayState;

#define GAME_INIT       0
#define GAME_PLAYING    1
#define GAME_PAUSED     2
#define GAME_TIMEUP     3
#define GAME_VICTORY    4
#define GAME_OVER       5
#define GAME_NOLIFE     6
#define GAME_QUIT       7
#define GAME_EDITING    8
#define GAME_LOADING    9
// special playing modes (e.g. loading gun etc, cutscene etc)
#define GAME_PLAYING2   10
#define GAME_PLAYING3   11
#define GAME_PLAYING4   12
#define GAME_PLAYING5   13
// some extra custom states
#define GAME_STATE1     14
#define GAME_STATE2     15
#define GAME_STATE3     16
#define GAME_STATE4     17
#define GAME_STATE5     18

@protocol TQGameplayObject
- (NSString *)objClass;
- (NSString *)objSubclass;
@end

@class TQGameplayRule;
@class TQGameplayController;
@class TQGameplayScheduledEvent;

@protocol TQGameplayDelegate <NSObject>
@required
- (void)onGameStateChanged:(TQGameplayController*)gameplay fromState:(TQGameplayState)old_state toState:(TQGameplayState)new_state;
@optional
- (void)onGameCountUp:(TQGameplayController*)gameplay withSecondsElapsed:(int)secondsElapsed;
- (void)onGameCountDown:(TQGameplayController*)gameplay withSecondsLeft:(int)secondsLeft;
- (void)onGameScheduledEvent:(TQGameplayController*)gameplay forEvent:(TQGameplayScheduledEvent *)event;
- (void)onGameScoreChanged:(TQGameplayController*)gameplay withScore:(int)score;
- (void)onGameLivesChanged:(TQGameplayController*)gameplay withLives:(int)lives;
@end

@interface TQGameplayController : NSObject {
	int score_, minScore_;
	int lives_, maxLives_;
    uint countdown_;
    uint secondsInt_;
    float secondsFloat_;
    float timeDilation_;
    TQGameplayState state_;
    
    id<TQGameplayDelegate> delegate_;
	
	NSMutableArray *rules_;
	NSMutableDictionary *rulekeys_;
    NSMutableDictionary *scheduledEventsId_;
    NSMutableDictionary *scheduledEventsTime_;
}

/** score */
@property (nonatomic, assign) int score, minScore;

/** lives */
@property (nonatomic, assign) int lives, maxLives;

/** the delegate object that will handle event callbacks (weak reference) */
@property (nonatomic, assign) id<TQGameplayDelegate> delegate;

/** the state of the gameplay */
@property (nonatomic, assign) TQGameplayState state;

/** time dilation factor, normal is 1.0f, set 0.0 < value < 1.0 for slower time, set > 1.0 for faster time, set <= 0.0 to stop time. */
@property (nonatomic, assign) float timeDilation;

/** time elapsed in integer */
@property (nonatomic, assign) uint secondsInt;

/** time elapsed in float */
@property (nonatomic, readonly) float secondsFloat;

/** countdown total time */
@property (nonatomic, assign) uint countdown;

/**
 * Initialize gameplay controller with specific minimum score and maximum lives
 */
- (id)initWithMinScore:(int)minScore andMaxLives:(int)maxLives;

/**
 * Initialize gameplay controller with specific minimum score, maximum lives and countdown
 */
- (id)initWithMinScore:(int)minScore andMaxLives:(int)maxLives andCountDown:(uint)seconds;

/**
 * Initialize gameplay controller with maximum lives and countdown only
 */
- (id)initWithMaxLives:(int)maxLives andCountDown:(uint)seconds;

/**
 * Create and add new rule to gameplay controller
 *  @param ruleName The string containing the rule name for your later reference
 *  @param event The event that will trigger this rule
 *  @param objClass The object class that will execute this rule
 *  @param objSubclass The object subclass that will execute this rule
 *  @param deltaScore The amount of score to add or substract from current gameplay score if this rule is executed
 *  @param deltaLives The amount of lives to add or substract from current gameplay score if this rule is executed
 *  @param priority The priority of this rule in the trigger stack, higher priority will execute first
 *  @return The newly-created TQGameplayRule object
 */
- (TQGameplayRule *)addRuleWithName:(NSString *)ruleName
						 forEvent:(TQGameplayEvent)event
					  andObjClass:(NSString *)objClass 
				   andObjSubclass:(NSString *)objSubclass
					andDeltaScore:(int)deltaScore
					andDeltaLives:(int)deltaLives
					 withPriority:(uint)priority;

/**
 * Add rule to gameplay controller
 *  @param rule The TQGameplayRule object to add
 */
- (void)addRule:(TQGameplayRule *)rule;

/**
 * Load TQGameplayRule object from a plist file. Each entry in the plist is in the format of:
 *  ruleName (Dictionary):
 *  - event (String) - mandatory
 *  - objClass (String) - mandatory
 *  - objSubclass (String) - optional, default to nil
 *  - deltaScore (Integer) - optional, default to 0
 *  - deltaLives (Integer) - optional, default to 0
 *  - priority (UInteger) - optional, default to 0
 * @param plistFile The plist filename
 * @return NSArray containing the loaded TQGameplayRule objects
 */
- (NSArray *)loadRulesFromPlistFile:(NSString *)plistFile;

/**
 * Remove rule from gameplay controller
 *  @param rule The TQGameplayRule object to remove
 */
- (void)removeRule:(TQGameplayRule *)rule;

/**
 * Remove all rules from gameplay controller
 */
- (void)removeAllRules;

/**
 * Trigger a gameplay event to evaluate related rules
 *  @param event The GAMEPLAY_EVENT to trigger
 *  @param object The object to evaluate
 *  @return The gameplay rule that fulfills the event & object combination, if any, NULL if none
 */
- (TQGameplayRule *)triggerGameplayEvent:(TQGameplayEvent)event onObject:(id<TQGameplayObject>)object;

/**
 * Schedule an event to be triggered at specific time
 *  @param seconds The number of seconds into the gameplay when the event will be triggered
 *  @param data The custom data to be passed to the delegate's onGameScheduledEvent:withData: method
 *  @return Event id
 */
- (NSString *)scheduleEventAtTime:(uint)seconds withData:(id<NSObject>)data;

/**
 * Unschedule an event
 *  @param eventId The event id returned by scheduleEventAtTime:withData: method
 */
- (void)unscheduleEventById:(NSString *)eventId;

/**
 * Get all scheduled events
 */
- (NSArray *)getAllScheduledEvents;

/**
 * Clear all scheduled events
 */
- (void)clearAllScheduledEvents;

/**
 * Tick method
 */
- (void)update:(ccTime)dt;

/**
 * Reset current score and lives to minScore and maxLives respectively
 */
- (void)resetScoreAndLives;

/**
 * Reset gameplay, which reset the following parameters: score, lives, elapsed time.
 * Special note: all rules and scheduled events remain
 */
- (void)reset;

/**
 * Start the gameplay
 */
- (void)start;

/**
 * Pause / resume the gameplay
 */
- (void)pause:(BOOL)shouldPause;

/**
 * Quit the gameplay
 */
- (void)quit;

/**
 * Suspend / continue the scheduler
 */
- (void)suspend:(BOOL)shouldSuspend;

/**
 * Manually trigger Game Over event
 */
- (void)triggerGameOver;

/**
 * Manually trigger Victory event
 */
- (void)triggerVictory;

/**
 * Clean up. Should be called before releasing
 */
- (void)cleanup;

@end

typedef BOOL(^RuleCallback)(TQGameplayRule *, TQGameplayEvent, id<TQGameplayObject>);

@interface TQGameplayRule : NSObject {
	NSString *name_;
	
	TQGameplayEvent triggerEvent_, returnEvent_;
	NSString *reqObjClass_, *reqObjSubclass_;	
	int deltaScore_, deltaLives_;
	int priority_;

	RuleCallback validator_;
    SEL triggerAction_;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int deltaScore, deltaLives, priority;
@property (nonatomic, copy) TQGameplayEvent returnEvent;
@property (nonatomic, readonly) TQGameplayEvent triggerEvent;
@property (nonatomic, copy) RuleCallback validator;
@property (nonatomic, assign) SEL triggerAction;

+ (TQGameplayRule *)ruleWithName:(NSString *)ruleName
					  forEvent:(TQGameplayEvent)event
					andObjClass:(NSString *)objClass 
				 andObjSubclass:(NSString *)objSubclass
				  andDeltaScore:(int)deltaScore
				  andDeltaLives:(int)deltaLives
                    andPriority:(int)priority;

+ (TQGameplayRule *)ruleWithName:(NSString *)ruleName
					  forEvent:(TQGameplayEvent)event
					andObjClass:(NSString *)objClass 
				 andObjSubclass:(NSString *)objSubclass
					andCallback:(RuleCallback)callback DEPRECATED_ATTRIBUTE;

+ (TQGameplayRule *)ruleWithName:(NSString *)ruleName
                        forEvent:(TQGameplayEvent)event
                     andObjClass:(NSString *)objClass
                  andObjSubclass:(NSString *)objSubclass
                     andValidator:(RuleCallback)validator;

+ (TQGameplayRule *)ruleWithName:(NSString *)ruleName
                        forEvent:(TQGameplayEvent)event
                     andObjClass:(NSString *)objClass
                  andObjSubclass:(NSString *)objSubclass
                     andTriggerAction:(SEL)triggerAction;

- (id)initWithName:(NSString *)ruleName
			 forEvent:(TQGameplayEvent)event 
		andObjClass:(NSString *)objClass 
	 andObjSubclass:(NSString *)objSubclass
	  andDeltaScore:(int)deltaScore
	  andDeltaLives:(int)deltaLives
        andPriority:(int)priority;

- (BOOL)evaluateForEvent:(TQGameplayEvent)event andObject:(id<TQGameplayObject>)object;

@end

@interface TQGameplayScheduledEvent : NSObject {
    uint time_;
    id<NSObject> data_;
}
@property (nonatomic, readonly) uint time;
@property (nonatomic, readonly) id<NSObject> data;

- (id)initWithTime:(uint)time andData:(id<NSObject>)data;
- (NSString *)getId;

@end

/** @} */ // end of gameplay