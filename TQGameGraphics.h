//
//  TQGameGraphics.h
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 5/6/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TQGameCocos2dExtensions.h"
#import "TQGameDataStructure.h"
#import "ClippingNode.h"
#import "CCBlade.h"

/** @defgroup graphics Graphics
 *  @brief Classes for advanced graphics features
 *  @{
 */

/**
 *  @brief An easy-to-use tiled background layer
 */
@interface TQTiledBackgroundLayer : CCSpriteBatchNode {
    CGPoint bottomLeft_, topRight_;
}

+ (TQTiledBackgroundLayer *)layerWithImageFile:(NSString *)fileImage bottomLeft:(CGPoint)bottomLeft topRight:(CGPoint)topRight;
- (id)initWithFile:(NSString *)fileImage bottomLeft:(CGPoint)bottomLeft topRight:(CGPoint)topRight;

@end

/**
 *  An crossfade-able background layer
 */
@interface TQCrossFadeBackgroundLayer : CCLayer {
    CCSprite *sprite_;
}
@property (nonatomic, readonly) CCSprite *sprite;

+ (TQCrossFadeBackgroundLayer *)layerWithSprite:(CCSprite *)sprite;

- (id)initWithSprite:(CCSprite *)sprite;

- (void)changeSpriteTo:(CCSprite *)sprite withCrossFadeTime:(ccTime)time;

@end

#pragma mark -

/**
 *  @brief A progress bar that is made of sprite
 */
@interface TQProgressBarSprite : CCClippingNode {
    FourDirection direction_;
    CCSprite *spriteImage_;
    int progressPercentage_;
    CCDrawNode *rectangleStencil_;
}
@property (nonatomic, assign) int progressPercentage;

- (id)initWithSprite:(CCSprite *)sprite andDirection:(FourDirection)direction andProgress:(int)progressPercentage;

+ (TQProgressBarSprite *)progressBarWithSprite:(CCSprite *)sprite andDirection:(FourDirection)direction andProgress:(int)progressPercentage;

@end

#pragma mark -

/**
 *  @brief A CCAnimate subclass that reads animation configuration values from property list file.
 *
 *  @details The file must have at least two values: 
 *    "frames" = array of sprite frame names
 *    "delay" = number of seconds to delay from frame to frame
 */
@interface TQAnimateSprite : CCAnimate {
}

/**
 *  Initialize with a property file
 *  @param animateFile The filename of the property list file containing the animation config
 *  @return The initialized instance
 */
- (id)initWithFile:(NSString *)animateFile;

/**
 *  Factory method
 *  @param animateFile The filename of the property list file containing the animation config
 *  @return The initialized instance
 */
+ (TQAnimateSprite *)actionWithFile:(NSString *)animateFile;


/**
 *  Factory method
 *  @param delay The number of seconds to delay from frame to frame
 *  @param frameName Nil-terminated sprite frame names
 *  @return The initialized instance
 */
+ (TQAnimateSprite *)actionWithDelay:(float)delay andSpriteFrameNames:(NSString *)frameName, ... NS_REQUIRES_NIL_TERMINATION;

/**
 *  Create a CCRepeatForever action to be used by CCNode's runWithAction: method
 *  @return The CCRepeatForever instance that encloses this animation
 */
- (CCRepeatForever *)animateForever;

/**
 *  Create a CCSprite using the first animation frame (frame0)
 *  @return The created CCSprite (autoreleased)
 */
- (CCSprite *)createSprite;

@end

typedef TQAnimateSprite TQSpriteAnimate; // for backward compatibility

@interface TQBlade : CCBlade

+ (TQBlade *)bladeWithImage:(NSString *)image andWidth:(float)width andMaximumPoint:(int)limit;

@end

@class TQLabelNumberAnimator;

typedef void(^TQLabelNumberAnimatorCallback)(TQLabelNumberAnimator*, int);

@interface TQLabelNumberAnimator : CCSprite {
    CCNode<CCLabelProtocol> *label_;
    int currentValue_, targetValue_;
    uint deltaValuePerSecond_;
    NSNumberFormatter *formatter_;
    TQLabelNumberAnimatorCallback callback_;
}
@property (nonatomic, assign) int currentValue;
@property (nonatomic, assign) int targetValue;
@property (nonatomic, assign) uint deltaValuePerSecond;
@property (nonatomic, readonly) CCNode<CCLabelProtocol> *label;
@property (nonatomic, readonly) NSNumberFormatter *formatter;
@property (nonatomic, copy) TQLabelNumberAnimatorCallback callback;

- (id)initWithLabel:(CCNode<CCLabelProtocol> *)label andCurrentValue:(int)currentValue andDeltaValuePerSecond:(uint)deltaValuePerSecond;

+ (TQLabelNumberAnimator *)numberAnimatorWithLabel:(CCNode<CCLabelProtocol> *)label andCurrentValue:(int)currentValue andDeltaValuePerSecond:(uint)deltaValuePerSecond;


@end

@interface TQLabelTTF : CCLabelTTF {
    float strokeSize_;
    ccColor3B strokeColor_;
    GLubyte strokeOpacity_, labelOrigOpacity_;
    CCRenderTexture *strokeTexture_;
}

- (void)addStrokeWithSize:(float)size andColor:(ccColor3B)color;
- (void)addStrokeWithSize:(float)size andColor:(ccColor3B)color andOpacity:(GLubyte)opacity;

@end

@interface TQLayer : CCLayer {
    NSMutableDictionary *sublayers_;
}

- (TQLayer *)getSublayerWithName:(NSString *)name;
- (void)removeSublayerWithName:(NSString *)name;

@end

/** @} */ // end of graphics
