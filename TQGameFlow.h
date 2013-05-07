//
//  TQGameFlow.h
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 4/8/12.
//  Copyright (c) 2012 Nusantara Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ccTypes.h"
#import "TQGameDataStructure.h"

@class CCScene;
@class CCDirector;

@interface TQGameFlow : NSObject {
    CCDirector *director_;
    TQStageAndLevelNumber *currentStageLevelNumber_;
}
@property (nonatomic, readonly) CCDirector *director;
@property (nonatomic, retain) TQStageAndLevelNumber *currentStageLevelNumber;

+ (TQGameFlow *)instance;

- (void)start;

- (void)showMainMenuScreen;

- (void)showStageSelectScreen;

- (void)showLevelSelectScreenForStage:(uint)stageNum;

- (void)playLevel:(uint)levelNum inStage:(uint)stageNum withData:(id)data;

- (BOOL)playNextLevel;

- (void)startScene:(CCScene *)scene;

- (void)startScene:(CCScene *)scene withTransition:(Class)transitionSceneClass andDuration:(ccTime)duration;

- (BOOL)isDebugMode;

- (void)pause;

- (void)resume;

@end
