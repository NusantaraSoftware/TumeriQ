//
//  TQGameMechanics.h
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 5/19/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TQGameGraphics.h"
#import "TQGameDataStructure.h"
#import "TQGameCocos2dExtensions.h"

/** @defgroup mechanics Mechanics
 *  @brief Various mechanics and algorithms to the game
 *  @{
 */

/** @defgroup mechanics_multitouch Multi-touches Support
 *  @brief Simplified multi touches support
 *  @{
 */

#pragma mark -

@class TQMultiTouchLayer;
@class TQTouchInfo;

#pragma mark -

/**
 *  @brief Define a protocol that a child of a TQMultiTouchLayer needs to conform to in order
 *  @details Heavily used by TQMultiTouchLayer.
 */

@protocol TQMultiTouchTargetObject <NSObject>
- (BOOL)containsPoint:(CGPoint)point;
@end


@protocol TQMultiTouchLayerDelegate <NSObject>

/**
 * Callback function that will be called on touch began.
 * Override it to return YES to capture the touch,
 * otherwise this delegate won't receive subsequent touch events.
 *  @param touchInfo TQTouchInfo object that holds touch info
 *  @param layer The TQMultiTouchLayer that received the touch
 *  @return YES if the touch is consumed, otherwise NO.
 */
- (BOOL)tqTouchBegan:(TQTouchInfo *)touchInfo fromLayer:(TQMultiTouchLayer *)layer;

@optional

/**
 * Callback function that will be called on touch moved
 *  @param touchInfo TQTouchInfo object that holds touch info
 *  @param layer The TQMultiTouchLayer that received the touch
 */
- (void)tqTouchMoved:(TQTouchInfo *)touchInfo fromLayer:(TQMultiTouchLayer *)layer;

/**
 * Callback function that will be called every tick while the touch stays not moving
 *  @param touchInfo TQTouchInfo object that holds touch info
 *  @param dt The delta time since the previous call to this callback
 *  @param layer The TQMultiTouchLayer that received the touch
 */
- (void)tqTouchStayed:(TQTouchInfo *)touchInfo dt:(ccTime)dt fromLayer:(TQMultiTouchLayer *)layer;

/**
 * Callback function that will be called on touch ended (user lifted finger) or cancelled (interrupted by phone event)
 * To differentiate between touch ended or cancelled, check the value of touchInfo.touch.phase
 *  @param touchInfo TQTouchInfo object that holds touch info
 *  @param layer The TQMultiTouchLayer that received the touch
 */
- (void)tqTouchEnded:(TQTouchInfo *)touchInfo fromLayer:(TQMultiTouchLayer *)layer;

#pragma mark TQMultiTouchTargetObject touch delegate methods

/**
 * Callback function that will be called on touch began on a TQMultiTouchTargetObject.
 * Override it to return YES to capture the touch,
 * otherwise this delegate won't receive subsequent touch events.
 *  @param targetObject The TQMultiTouchTargetObject that received the touch
 *  @return YES if the touch is consumed, otherwise NO.
 */
- (BOOL)tqTouchBegan:(TQTouchInfo *)touchInfo onObject:(CCNode<TQMultiTouchTargetObject> *)targetObject;

/**
 * Callback function that will be called on touch moved
 *  @param targetObject The TQMultiTouchTargetObject that received the touch
 */
- (void)tqTouchMoved:(TQTouchInfo *)touchInfo onObject:(CCNode<TQMultiTouchTargetObject> *)targetObject;

/**
 * Callback function that will be called on touch ended (user lifted finger) or cancelled (interrupted by phone event)
 * To differentiate between touch ended or cancelled, check the value of touchInfo.touch.phase
 *  @param targetObject The TQMultiTouchTargetObject that received the touch
 */
- (void)tqTouchEnded:(TQTouchInfo *)touchInfo onObject:(CCNode<TQMultiTouchTargetObject> *)targetObject;

@end

#pragma mark -

/**
 *  @brief A wrapper for UITouch object that provides tagging, time & location info, and custom data features.
 *  @details Heavily used by TQMultiTouchLayer.
 */

@interface TQTouchInfo : NSObject {
    uint tag_;
    UITouch *touch_;
    UIEvent *event_;
    CCNode *node_;
    TQTimeAndLocation start_, previous_;
    CGPoint location_;
    id<NSObject> data_;
    void *cdata_;
    float stayedDuration_, duration_, timeLastMoved_;
    CCSprite *pointerSprite_;
    id<TQMultiTouchLayerDelegate> handledByTouchDelegate_;
    CCNode<TQMultiTouchTargetObject> *targetObject_;
}
@property (nonatomic, assign) uint tag;
@property (nonatomic, assign) CCNode *node;
@property (nonatomic, readonly) UITouch *touch;
@property (nonatomic, readonly) UIEvent *event;
@property (nonatomic, readonly) TQTimeAndLocation start, previous;
@property (nonatomic, readonly) CGPoint location;
@property (nonatomic, retain) id<NSObject> data;
@property (nonatomic, assign) void *cdata;
@property (nonatomic, assign) float stayedDuration, duration, timeLastMoved;
@property (nonatomic, assign) CCSprite *pointerSprite;
@property (nonatomic, assign) id<TQMultiTouchLayerDelegate> handledByTouchDelegate;
@property (nonatomic, retain) CCNode<TQMultiTouchTargetObject> *targetObject;

- (id)initWithTouch:(UITouch *)touch andEvent:(UIEvent *)event forNode:(CCNode *)node;
- (void)updateForCurrentEvent:(UIEvent *)devent;
- (void)rememberAsPreviousLocation;

@end

/**
 *  @brief A CCLayer subclass that enables multi-touch handling with much ease.
 *  @details The power lies in callback functions tqTouchBegan, tqTouchMoved, tqTouchEnded and TQTouchCancelled,
 *  each of which is given TQTouchInfo parameter.
 */

@interface TQMultiTouchLayer : TQLayer <TQMultiTouchLayerDelegate> {
    NSMutableDictionary *touches_;
    uint maxTouches_;
    id <TQMultiTouchLayerDelegate> delegate_;
}
@property (nonatomic, assign) uint maxTouches;
@property (nonatomic, assign) id<TQMultiTouchLayerDelegate> delegate; // weak

/**
 * Callback function that will be called on touch began.
 * Override it to return YES to capture the touch,
 * otherwise this layer won't receive subsequent touch events.
 *  @param touchInfo TQTouchInfo object that holds touch info
 *  @return YES if the touch is consumed, otherwise NO.
 */
- (BOOL)tqTouchBegan:(TQTouchInfo *)touchInfo;

/**
 * Callback function that will be called on touch moved
 *  @param touchInfo TQTouchInfo object that holds touch info
 */
- (void)tqTouchMoved:(TQTouchInfo *)touchInfo;

/**
 * Callback function that will be called every tick while the touch stays not moving
 *  @param touchInfo TQTouchInfo object that holds touch info
 *  @param dt The delta time since the previous call to this callback
 */
- (void)tqTouchStayed:(TQTouchInfo *)touchInfo dt:(ccTime)dt;

/**
 * Callback function that will be called on touch ended (user lifted finger) or cancelled (interrupted by phone event)
 * To differentiate between touch ended or cancelled, check the value of touchInfo.touch.phase
 *  @param touchInfo TQTouchInfo object that holds touch info
 */
- (void)tqTouchEnded:(TQTouchInfo *)touchInfo;

/**
 * Get touchInfo by tag value
 *  @param tag The tag value
 *  @return The TQTouchInfo with the tag value
 */
- (TQTouchInfo *)findTouchInfoByTag:(uint)tag;

/**
 * Get concurrent number of active touches
 */
- (uint)currentNumberOfTouches;

@end

#pragma mark -

typedef enum {
    SCROLL_BOTTOM_LEFT = 0,
    SCROLL_BOTTOM_CENTER,
    SCROLL_BOTTOM_RIGHT,
    SCROLL_MIDDLE_LEFT,
    SCROLL_MIDDLE_CENTER,
    SCROLL_MIDDLE_RIGHT,
    SCROLL_TOP_LEFT,
    SCROLL_TOP_CENTER,
    SCROLL_TOP_RIGHT
} TQScrollPosition;

/**
 *  @brief A CCLayer subclass that is draggable using touch
 */
@interface TQDraggableLayer : TQMultiTouchLayer {
    CGSize screenSize_, actualContentSize_;
    CGPoint dragStartLocation_;

    uint touchInfoTag_; // tag to be used for TQTouchInfo
    BOOL isDragging_;
    BOOL draggingEnabled_;
    
    float scrollingDuration_;
    CGPoint scrollingDestination_;
}
@property (nonatomic, assign) CGSize actualContentSize;
@property (nonatomic, assign) BOOL draggingEnabled;
@property (nonatomic, readonly) BOOL isDragging;

/**
 * Initialize scroll layer with specific content size
 */
- (id)initWithContentSize:(CGSize)size;

/**
 * Scroll to one of the nine positions within the given duration
 */
- (void)scrollToPosition:(TQScrollPosition)position withinDuration:(ccTime)duration;

/**
 * Scroll to a specific point within the given duration
 */
- (void)scrollToPoint:(CGPoint)point withinDuration:(ccTime)duration;

/**
 * Scroll the layer so that a specific point becomes the center of the screen
 */
- (void)scrollToCenterizePoint:(CGPoint)point withinDuration:(ccTime)duration;

/**
 * Get the current point which is at the center of the screen
 */
- (CGPoint)getCurrentCenterPoint;

/**
 * Get the current CGRect which is visible on the screen
 */
- (CGRect)getCurrentRect;

/**
 * Tick function
 */
- (void)scrollTick:(ccTime)dt;

@end

/** @} */ // end of mechanics_multitouch

/** @} */ // end of mechanics