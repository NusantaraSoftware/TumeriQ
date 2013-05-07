//
//  TQGameAppDelegate.h
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 5/1/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

@class TQGameRootViewController;

@protocol TQGameRootViewControllerDelegate <UINavigationControllerDelegate>

- (BOOL)tqShouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (uint)tqSupportedInterfaceOrientations;

@end

@interface TQGameAppDelegate : NSObject <UIApplicationDelegate, CCDirectorDelegate, TQGameRootViewControllerDelegate> {
	UIWindow *window_;
	TQGameRootViewController *rootViewController_;
    BOOL multiTouchEnabled_;
    NSDictionary *applicationLaunchOptions_;
    UIApplication *application_;
    CCDirector *director_;
    BOOL started_;
    
    // orientations
    uint supportedOrientationsMask_;
    BOOL orientationPortraitSupported_;
    BOOL orientationPortraitUpsideDownSupported_;
    BOOL orientationLandscapeLeftSupported_;
    BOOL orientationLandscapeRightSupported_;
    UIInterfaceOrientation initialOrientation_;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) NSDictionary *applicationLaunchOptions;
@property (nonatomic, assign) UIApplication *application; /* weak ref */
@property (readonly) TQGameRootViewController *rootViewController;

/* orientations */
@property(nonatomic, readonly) uint supportedOrientationsMask;
@property(nonatomic, readonly) UIInterfaceOrientation initialOrientation;
@property(nonatomic, assign) BOOL orientationPortraitSupported;
@property(nonatomic, assign) BOOL orientationPortraitUpsideDownSupported;
@property(nonatomic, assign) BOOL orientationLandscapeLeftSupported;
@property(nonatomic, assign) BOOL orientationLandscapeRightSupported;

/**
 * Pause the application
 */
- (void)pause;

/**
 * Resume the application
 */
- (void)resume;

/**
 * Get the active instance
 */
+ (TQGameAppDelegate *)getActiveInstance;

/**
 * Recalculate supported orientation mask. Must be called after changing the supported orientations properties
 */
- (void)recalcSupportedOrientationsMask;

/**
 * Configure supported orientations (to be overloaded by subclass)
 */
- (void)configureSupportedOrientations;

/**
 * Start the game (to be overloaded by subclass)
 */
- (void)start;

@end

@interface TQGameRootViewController : UINavigationController {
    id<TQGameRootViewControllerDelegate> delegate_;
}
@property (nonatomic, assign) id<TQGameRootViewControllerDelegate> delegate;

@end
