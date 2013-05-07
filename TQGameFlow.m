//
//  TQGameFlow.m
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 4/8/12.
//  Copyright (c) 2012 Nusantara Software. All rights reserved.
//

#import "TQGameFlow.h"
#import "cocos2d.h"
#import "TQGameAppDelegate.h"

TQGameFlow *TQglobal_gameDirector = nil;

@implementation TQGameFlow
@synthesize director = director_, currentStageLevelNumber = currentStageLevelNumber_;

+ (TQGameFlow *)instance {
    if (!TQglobal_gameDirector) {
        TQglobal_gameDirector = [[[self class] alloc] init];
    }
    return TQglobal_gameDirector;
}

- (id)init {
    if ((self = [super init])) {
        director_ = [CCDirector sharedDirector];
    }
    return self;
}

- (void)dealloc {
    self.currentStageLevelNumber = nil;
    [super dealloc];
}

- (void)start {}

- (void)showMainMenuScreen {}

- (void)showStageSelectScreen {}

- (void)showLevelSelectScreenForStage:(uint)stageNum {}

- (void)playLevel:(uint)levelNum inStage:(uint)stageNum withData:(id)data {
    self.currentStageLevelNumber = [TQStageAndLevelNumber stageAndLevelNumberWithMode:self.currentStageLevelNumber.mode
                                                                stage:stageNum
                                                                level:levelNum
                                                             maxStage:self.currentStageLevelNumber.max_stage
                                                             maxLevel:self.currentStageLevelNumber.max_level];
}

- (BOOL)playNextLevel {
    if ([self.currentStageLevelNumber increaseLevel]) {
        [self playLevel:self.currentStageLevelNumber.level inStage:self.currentStageLevelNumber.stage withData:nil];
        return YES;
    }
    else {
        return NO;
    }
}

- (void)startScene:(CCScene *)scene {
    [self startScene:scene withTransition:nil andDuration:0];
}

- (void)startScene:(CCScene *)scene withTransition:(Class)transitionSceneClass andDuration:(ccTime)duration {
    if (transitionSceneClass && [transitionSceneClass isSubclassOfClass:[CCTransitionScene class]]) {
        scene = [transitionSceneClass transitionWithDuration:duration scene:scene];
    }
    if([self.director runningScene]) {
        [self.director replaceScene:scene];
    }
    else {
        [self.director runWithScene:scene];
    }
}

- (BOOL)isDebugMode {
#if DEBUG
    return YES;
#else
    return NO;
#endif
}

- (void)pause {
    [[TQGameAppDelegate getActiveInstance] pause];
}

- (void)resume {
    [[TQGameAppDelegate getActiveInstance] resume];
}

@end
