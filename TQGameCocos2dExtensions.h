//
//  TQGameCocos2dExtensions.h
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 10/19/11.
//  Copyright (c) 2011 Nusantara Software. All rights reserved.
//

#import "cocos2d.h"

@interface CCNode (TQGameExtensions)

/**
 *  A shorthand alias for [node removeFromParentAndCleanup:YES]
 */
- (void)removeFromParentAndCleanupYES;

/**
 *  Scale node to an absolute size
 *  @param size The size to scale to
 */
- (void)scaleToSize:(CGSize)size;

/**
 *  Return center point of the screen
 *  @return Screen center point
 */
- (CGPoint)screenCenter;

/**
 *  Return actual size of the node after taking scale into consideration
 *  @return Node actual size
 */
- (CGSize)actualSize;

/**
 *  Return center point after the node after taking scale into consideration
 *  @return Node center point
 */
- (CGPoint)center;

/**
 *  Check if this node contains a specific point by checking transparency of the pixel at the point
 *  @param point The CGPoint to check
 *  @return YES if this node's boundingBox contains the point
 */
- (BOOL)containsPoint:(CGPoint)point;

/**
 *  Run action after specific delay
 *  @param action The action to run
 *  @param delay The amount of delay in fraction of seconds
 */
- (void)runAction:(CCAction*)action afterDelay:(ccTime)delay;

@end

@interface CCLayer (TQGameExtensions)

/**
 *  Create a CCScene instance with an instance of this CCLayer added as a child
 *  @return The created CCScene
 */
+ (CCScene *)scene;

/**
 *  Shortcut to add node to a specific position and z-index
 *  @param sprite The CCNode to add
 *  @param position The position to add
 *  @param z The z-Index
 *  @return The added CCNode
 */
- (CCNode *)addChild:(CCNode *)node toPosition:(CGPoint)position z:(uint)z;

@end

@interface CCLabelTTF (TQGameExtensions) 

- (CCRenderTexture *)createStrokeWithSize:(float)size andColor:(ccColor3B)cor;
- (CCRenderTexture *)createStrokeWithSize:(float)size andColor:(ccColor3B)cor andOpacity:(GLubyte)opac;

@end

@interface CCSequence (TQGameExtensions)

/**
 *  Append a CCFiniteTimeAction to this CCSequence
 *  @param action The CCFiniteTimeAction instance to be appended
 */
- (void)appendAction:(CCFiniteTimeAction *)action;

@end

@interface CCActionInterval (TQGameExtensions)
    
/**
 *  Create a CCRepeatForever action to be used by CCNode's runWithAction: method
 *  @return The CCRepeatForever instance that encloses this action
 */
- (CCRepeatForever *)repeatForever;
    
@end

@interface TQRemoveFromParentAction : CCActionInstant

+ (TQRemoveFromParentAction *)action;

@end