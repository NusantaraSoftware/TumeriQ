//
//  TQGameplay.m
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 3/6/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import "TQGameplay.h"
#import "cocos2d.h"

@interface TQGameplayController (Private)
- (void)setState:(TQGameplayState)state;
@end

@implementation TQGameplayController
@synthesize score = score_, lives = lives_, minScore = minScore_, maxLives = maxLives_;
@synthesize delegate = delegate_, state = state_, secondsInt = secondsInt_, secondsFloat = secondsFloat_, timeDilation = timeDilation_, countdown = countdown_;

- (id)init {
	self = [super init];
	if (self) {
		rules_ = [[NSMutableArray alloc] init];
		rulekeys_ = [[NSMutableDictionary alloc] init];
        scheduledEventsId_ = [[NSMutableDictionary alloc] init];
        scheduledEventsTime_ = [[NSMutableDictionary alloc] init];
        minScore_ = 0;
        maxLives_ = 0;
	}
	return self;
}

- (id)initWithMinScore:(int)minScore andMaxLives:(int)maxLives {
    return [self initWithMinScore:minScore andMaxLives:maxLives andCountDown:0];
}

- (id)initWithMaxLives:(int)maxLives andCountDown:(uint)seconds {
    return [self initWithMinScore:0 andMaxLives:maxLives andCountDown:seconds];
}

- (id)initWithMinScore:(int)minScore andMaxLives:(int)maxLives andCountDown:(uint)seconds {
    assert(maxLives > 0);
    self = [self init];
    minScore_ = minScore;
    maxLives_ = maxLives;
    countdown_ = seconds;
    [self reset];
    return self;
}

- (void)dealloc {
    [self cleanup];
	[rules_ release];
	[rulekeys_ release];
    [scheduledEventsId_ release];
    [scheduledEventsTime_ release];
	[super dealloc];
}

- (TQGameplayRule *)addRuleWithName:(NSString *)ruleName forEvent:(TQGameplayEvent)event andObjClass:(NSString *)objClass andObjSubclass:(NSString *)objSubclass andDeltaScore:(int)deltaScore andDeltaLives:(int)deltaLives withPriority:(uint)priority {
	TQGameplayRule *rule = [TQGameplayRule ruleWithName:ruleName 
										   forEvent:event 
										andObjClass:objClass 
									 andObjSubclass:objSubclass 
									  andDeltaScore:deltaScore 
									  andDeltaLives:deltaLives
                                        andPriority:priority];
    [self addRule:rule];
	return rule;
}

- (void)addRule:(TQGameplayRule *)rule {
	int i = [rules_ count] - 1;
	for (; i >= 0; i--) {
		if (rule.priority <= ((TQGameplayRule *)[rules_ objectAtIndex:i]).priority) {
			break;
		}
	}
	[rules_ insertObject:rule atIndex:i + 1];
	[rulekeys_ setObject:rule forKey:[NSValue valueWithPointer:rule]];
}

- (NSArray *)loadRulesFromPlistFile:(NSString *)plistFile {
    NSMutableArray *loadedRules = [NSMutableArray array];

    NSDictionary *allRules = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:plistFile ofType:@"plist"]];
    for (NSString *ruleName in allRules) {
        NSDictionary *ruleConfig = [allRules objectForKey:ruleName];
        NSString *event = [ruleConfig objectForKey:@"event"];
        NSString *objClass = [ruleConfig objectForKey:@"objClass"];
        NSString *objSubclass = [ruleConfig objectForKey:@"objSubclass"];
        NSNumber *deltaScore = [ruleConfig objectForKey:@"deltaScore"];
        NSNumber *deltaLives = [ruleConfig objectForKey:@"deltaLives"];
        NSNumber *priority = [ruleConfig objectForKey:@"priority"];
        
        if (event && objClass) {
            TQGameplayRule *rule = [self addRuleWithName:ruleName
                                                forEvent:event
                                             andObjClass:objClass
                                          andObjSubclass:objSubclass
                                           andDeltaScore:(deltaScore? [deltaScore intValue] : 0)
                                           andDeltaLives:(deltaLives? [deltaLives intValue] : 0)
                                            withPriority:(priority? [priority intValue] : 0)];
            [loadedRules addObject:rule];
        }
    }

    return loadedRules;
}

- (void)removeRule:(TQGameplayRule *)rule {
	NSUInteger idx = [rules_ indexOfObject:rule];
	[rules_ removeObjectAtIndex:idx];
}

- (void)removeAllRules {
	[rules_ removeAllObjects];
}

- (TQGameplayRule *)triggerGameplayEvent:(TQGameplayEvent)event onObject:(id<TQGameplayObject>)object {
	TQGameplayRule *returnRule = nil;
    int newScore = score_;
    int newLives = lives_;
	for (TQGameplayRule *rule in rules_) {
		if ([rule evaluateForEvent:event andObject:object]) {
			[returnRule release];
			returnRule = [rule retain];
            if (rule.triggerAction && [delegate_ respondsToSelector:rule.triggerAction]) {
                [delegate_ performSelector:rule.triggerAction withObject:rule withObject:object];
            }
			if ([rule.returnEvent isEqualToString:EVT_OBJ_EVALUATED]) {
				newScore += rule.deltaScore;
				newLives += rule.deltaLives;
				break;
			}
			else {
				// rules can change the event in the same run for further rules to evaluate
				event = rule.returnEvent;
			}
		}
	}
	if (newScore < minScore_) {
		newScore = minScore_;
	}
	if (newLives > maxLives_) {
		newLives = maxLives_;
	}
    self.score = newScore;
    self.lives = newLives;
	return [returnRule autorelease];
}

- (void)setScore:(int)score {
    if (score < minScore_) {
        score = minScore_;
    }
    if (score != score_) {
        score_ = score;
        if (delegate_ && [delegate_ respondsToSelector:@selector(onGameScoreChanged:withScore:)]) {
            [delegate_ onGameScoreChanged:self withScore:score_];
        }
    }
}

- (void)setLives:(int)lives {
    if (lives > maxLives_) {
        lives = maxLives_;
    }
    if (lives != lives_) {
        lives_ = lives;
        if (delegate_ && [delegate_ respondsToSelector:@selector(onGameLivesChanged:withLives:)]) {
            [delegate_ onGameLivesChanged:self withLives:lives_];
        }
        if (lives_ <= 0 && maxLives_ > 0) {
            [self setState:GAME_NOLIFE];
        }
    }
}

- (NSString *)scheduleEventAtTime:(uint)seconds withData:(id<NSObject>)data {
    // create TQGameplayScheduledEvent object
    TQGameplayScheduledEvent *event = [[TQGameplayScheduledEvent alloc] initWithTime:seconds andData:data];
    NSString *eventId = [event getId];
    
    // only proceed if eventId does not exist yet
    if (![scheduledEventsId_ objectForKey:eventId]) {        
        NSNumber *numkey = [NSNumber numberWithInt:seconds];
        [scheduledEventsTime_ addObject:event intoArrayForKey:numkey];
        [scheduledEventsId_ setObject:event forKey:eventId];
    }
    
    [event release];
    return eventId;
}

- (void)unscheduleEventById:(NSString *)eventId {
    TQGameplayScheduledEvent *event = [scheduledEventsId_ objectForKey:eventId];
    if (event) {
        NSNumber *timeNum = [NSNumber numberWithInt:event.time];
        NSMutableArray *eventArray = [scheduledEventsTime_ objectForKey:timeNum];
        [eventArray removeObject:event];
        if ([eventArray count] == 0) {
            [scheduledEventsTime_ removeObjectForKey:timeNum];
        }
        [scheduledEventsId_ removeObjectForKey:eventId];
    }
}

- (NSArray *)getAllScheduledEvents {
    return [scheduledEventsId_ allValues];
}

- (void)clearAllScheduledEvents {
    [scheduledEventsTime_ removeAllObjects];
    [scheduledEventsId_ removeAllObjects];
}

- (void)setState:(TQGameplayState)state {
    if (state != state_) {
        TQGameplayState old_state = state_;
        state_ = state;
        [delegate_ onGameStateChanged:self fromState:old_state toState:state_];
        if (old_state == GAME_INIT && state == GAME_PLAYING) {
            [[CCDirector sharedDirector].scheduler scheduleUpdateForTarget:self priority:0 paused:NO];
        }
        if (state == GAME_INIT) {
            [self cleanup];
        }
    }
}

- (void)update:(ccTime)dt {
    if ((state_ == GAME_PLAYING || state_ == GAME_PLAYING2 || state_ == GAME_PLAYING3 ||
         state_ == GAME_PLAYING4 || state_ == GAME_PLAYING5 || state_ == GAME_TIMEUP)
        && timeDilation_ > 0.0f) {
        secondsFloat_ += dt * timeDilation_;
        int seconds = floorf(secondsFloat_);
        if (seconds != secondsInt_) {
            secondsInt_ = seconds;
            if (delegate_) {
                if ([delegate_ respondsToSelector:@selector(onGameScheduledEvent:forEvent:)]) {
                    NSArray *eventArray = [scheduledEventsTime_ objectForKey:[NSNumber numberWithInt:secondsInt_]];
                    for (TQGameplayScheduledEvent *eventObject in eventArray) {
                        [delegate_ onGameScheduledEvent:self forEvent:(TQGameplayScheduledEvent *)eventObject];
                    }
                }
                if ([delegate_ respondsToSelector:@selector(onGameCountUp:withSecondsElapsed:)]) {
                    [delegate_ onGameCountUp:self withSecondsElapsed:secondsInt_];
                }
            }
            if (countdown_ > 0) {
                int secondsLeft = countdown_ - secondsInt_;
                if (secondsLeft >= 0 && delegate_ && [delegate_ respondsToSelector:@selector(onGameCountDown:withSecondsLeft:)]) {
                    [delegate_ onGameCountDown:self withSecondsLeft:secondsLeft];
                }
                if (secondsLeft == 0) {
                    self.state = GAME_TIMEUP;
                }
            }
        }
    }
}

- (void)resetScoreAndLives {
    [self reset];
}

- (void)reset {
    self.score = minScore_;
	self.lives = maxLives_;
    secondsInt_ = 0;
    secondsFloat_ = 0.0f;
    timeDilation_ = 1.0f;
    [self setState:GAME_INIT];
}

- (void)start {
    assert(state_ == GAME_INIT);
    [self setState:GAME_PLAYING];
}

- (void)pause:(BOOL)shouldPause {
    if (shouldPause && state_ == GAME_PLAYING) {
        [self setState:GAME_PAUSED];
    }
    if (!shouldPause && state_ == GAME_PAUSED) {
        [self setState:GAME_PLAYING];
    }
}

- (void)suspend:(BOOL)shouldSuspend {
    if (shouldSuspend) {
        [[CCDirector sharedDirector].scheduler pauseTarget:self];
    }
    else {
        [[CCDirector sharedDirector].scheduler resumeTarget:self];
    }
}

- (void)quit {
    [self setState:GAME_QUIT];
}

- (void)triggerGameOver {
    [self setState:GAME_OVER];
}

- (void)triggerVictory {
    [self setState:GAME_VICTORY];
}

- (void)cleanup {
    [[CCDirector sharedDirector].scheduler unscheduleAllForTarget:self];
}

- (void)setSecondsInt:(uint)secondsInt {
    secondsInt_ = secondsInt;
    secondsFloat_ = (float)secondsInt_;
}

@end

@implementation TQGameplayRule
@synthesize deltaScore = deltaScore_, deltaLives = deltaLives_;
@synthesize returnEvent = returnEvent_, triggerEvent = triggerEvent_;
@synthesize name = name_, validator = validator_;
@synthesize priority = priority_;
@synthesize triggerAction = triggerAction_;

+ (TQGameplayRule *)ruleWithName:(NSString *)ruleName forEvent:(TQGameplayEvent)event andObjClass:(NSString *)objClass andObjSubclass:(NSString *)objSubclass
				  andDeltaScore:(int)dscore andDeltaLives:(int)dlives andPriority:(int)prio {
	return [[[self alloc] initWithName:ruleName forEvent:event andObjClass:objClass andObjSubclass:objSubclass andDeltaScore:dscore andDeltaLives:dlives andPriority:prio] autorelease];
}

+ (TQGameplayRule *)ruleWithName:(NSString *)ruleName forEvent:(TQGameplayEvent)event andObjClass:(NSString *)objClass andObjSubclass:(NSString *)objSubclass andCallback:(RuleCallback)callback {
    return [self ruleWithName:ruleName forEvent:event andObjClass:objClass andObjSubclass:objSubclass andValidator:callback];
}

+ (TQGameplayRule *)ruleWithName:(NSString *)ruleName forEvent:(TQGameplayEvent)event andObjClass:(NSString *)objClass andObjSubclass:(NSString *)objSubclass andValidator:(RuleCallback)validator {
	TQGameplayRule *rule = [[TQGameplayRule alloc] initWithName:ruleName forEvent:event andObjClass:objClass andObjSubclass:objSubclass andDeltaScore:0 andDeltaLives:0 andPriority:0];
	rule.validator = validator;
	return [rule autorelease];
}

+ (TQGameplayRule *)ruleWithName:(NSString *)ruleName forEvent:(TQGameplayEvent)event andObjClass:(NSString *)objClass andObjSubclass:(NSString *)objSubclass andTriggerAction:(SEL)triggerAction {
	TQGameplayRule *rule = [[TQGameplayRule alloc] initWithName:ruleName forEvent:event andObjClass:objClass andObjSubclass:objSubclass andDeltaScore:0 andDeltaLives:0 andPriority:0];
	rule.triggerAction = triggerAction;
	return [rule autorelease];
}

- (id)initWithName:(NSString *)ruleName forEvent:(TQGameplayEvent)event andObjClass:(NSString *)objClass andObjSubclass:(NSString *)objSubclass andDeltaScore:(int)dscore andDeltaLives:(int)dlives andPriority:(int)prio {
	self = [super init];
	if (self) {
		name_ = [ruleName copy];
		triggerEvent_ = [event copy];
		reqObjClass_ = [objClass copy];
		reqObjSubclass_ = [objSubclass copy];
		deltaScore_ = dscore;
		deltaLives_ = dlives;
        priority_ = prio;
		returnEvent_ = EVT_OBJ_EVALUATED;
	}
	return self;
}

- (void)dealloc {
    [triggerEvent_ release];
	[name_ release];
	[reqObjClass_ release];
	[reqObjSubclass_ release];
	[super dealloc];
}

- (BOOL)evaluateForEvent:(TQGameplayEvent)event andObject:(id<TQGameplayObject>)object {
	if ([event isEqualToString:triggerEvent_]) {
		BOOL classMatches = (!reqObjClass_ || [reqObjClass_ compare:[object objClass]] == NSOrderedSame);
		BOOL subclassMatches = (!reqObjSubclass_ || [reqObjSubclass_ compare:[object objSubclass]] == NSOrderedSame);
		if (classMatches && subclassMatches) {
			if (!validator_ || validator_(self, event, object)) {
				return YES;
			}
		}
	}
	return NO;
}

@end

@implementation TQGameplayScheduledEvent
@synthesize time = time_, data = data_;

- (id)initWithTime:(uint)time andData:(id<NSObject>)data {
    self = [super init];
    if (self) {
        time_ = time;
        data_ = [data retain];
    }
    return self;
}

- (NSString *)getId {
    return [NSString stringWithFormat:@"%04d:%p", time_, data_];
}

@end

