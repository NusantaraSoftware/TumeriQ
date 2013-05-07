//
//  TQGameCocos2dExtensions.m
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 10/19/11.
//  Copyright (c) 2011 Nusantara Software. All rights reserved.
//

#import "TQGameCocos2dExtensions.h"

CGPoint global_screenCenter;

@implementation CCNode (TQGameExtensions)

- (void)removeFromParentAndCleanupYES {
    [self removeFromParentAndCleanup:YES];
}

- (void)scaleToSize:(CGSize)size {
    float ratioX = size.width / self.contentSize.width;
    float ratioY = size.height / self.contentSize.height;
    self.scale = MIN(ratioX, ratioY);
}

- (CGPoint)screenCenter {
    if (global_screenCenter.x == 0 && global_screenCenter.y == 0) {
        CGSize winSize = [CCDirector sharedDirector].winSize;
        global_screenCenter = ccp(winSize.width / 2, winSize.height / 2);
    }
    return global_screenCenter;
}

- (CGSize)actualSize {
    return CGSizeMake(self.contentSize.width * self.scaleX, self.contentSize.height * self.scaleY);
}

- (CGPoint)center {
    CGSize actualSize = self.actualSize;
    return ccpAdd(self.position, ccp(actualSize.width * (0.5 - self.anchorPoint.x), actualSize.height * (0.5 - self.anchorPoint.y)));
}

- (BOOL)containsPoint:(CGPoint)point {
    if (CGRectContainsPoint([self boundingBox], point)) {
        // uint array to hold rgba values
        UInt8 pixel[4];
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        
        // render the sprite onto a CCRenderTexture
        CCRenderTexture *renderTexture = [CCRenderTexture renderTextureWithWidth:screenSize.width height:screenSize.height pixelFormat:kCCTexture2DPixelFormat_RGBA8888];
        [renderTexture begin];
        [self draw];
        
        // read the rgba values of pixel at the point
        CGPoint location = [self convertToNodeSpace:point];
        glReadPixels((GLint)location.x,(GLint)location.y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixel);
        [renderTexture end];
        
        // return if the pixel is not transparent (a != 0)
        return (pixel[3] != 0);
    }
    return NO;
}

- (void)runAction:(CCFiniteTimeAction *)action afterDelay:(ccTime)delay {
    [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:delay] two:action]];
}

@end

@implementation CCLayer (TQGameExtensions)

+ (CCScene *)scene {
    CCScene *scene = [CCScene node];
    [scene addChild:[self node]];
	return scene;
}

- (CCNode *)addChild:(CCNode *)node toPosition:(CGPoint)position z:(uint)z {
    node.position = position;
    [self addChild:node z:z];
    return node;
}

@end

@implementation CCLabelTTF (TQGameExtensions)

- (CCRenderTexture *)createStrokeWithSize:(float)size andColor:(ccColor3B)cor {
    return [self createStrokeWithSize:size andColor:cor andOpacity:255];
}

- (CCRenderTexture *)createStrokeWithSize:(float)size andColor:(ccColor3B)cor andOpacity:(GLubyte)opac {
    CCLabelTTF *label = self;
	CCRenderTexture* rt = [CCRenderTexture renderTextureWithWidth:label.texture.contentSize.width + size * 2 
                                                           height:label.texture.contentSize.height + size * 2];
	CGPoint originalPos = [label position];
	ccColor3B originalColor = [label color];
	BOOL originalVisibility = [label visible];
	ccBlendFunc originalBlend = [label blendFunc];
	CGPoint bottomLeft = ccp(label.texture.contentSize.width * label.anchorPoint.x + size, label.texture.contentSize.height * label.anchorPoint.y + size);
    //CGPoint positionOffset = ccp(-label.contentSize.width / 2, -label.contentSize.height / 2);
	//CGPoint position = ccpSub(originalPos, positionOffset);
    GLubyte originalOpacity = [label opacity];
	[label setColor:cor];
	[label setVisible:YES];
	[label setBlendFunc:(ccBlendFunc) { GL_SRC_ALPHA, GL_ONE }];
    [label setOpacity:opac];
    
	[rt begin];
    uint step = 60 / (int)ceilf(size);
	for (int i = 0; i < 360; i += step) {
		[label setPosition:ccp(bottomLeft.x + sin(CC_DEGREES_TO_RADIANS(i)) * size, bottomLeft.y + cos(CC_DEGREES_TO_RADIANS(i)) * size)];
		[label visit];
	}
	[rt end];
    
	[label setPosition:originalPos];
	[label setColor:originalColor];
	[label setBlendFunc:originalBlend];
	[label setVisible:originalVisibility];
    [label setOpacity:originalOpacity];
	[rt setPosition:originalPos];
	return rt;
}

@end


@implementation CCSequence (TQGameExtensions)

- (void)appendAction:(CCFiniteTimeAction *)action {
    if (!action) {
        return;
    }
    _duration += [action duration];

    CCFiniteTimeAction *one = _actions[0];
    CCFiniteTimeAction *two = _actions[1];
    
    _actions[0] = [[CCSequence actionOne:one two:two] retain];
    _actions[1] = [action retain];

    [one release];
    [two release];
}

@end

@implementation CCActionInterval (TQGameExtensions)

- (CCRepeatForever *)repeatForever {
    return [CCRepeatForever actionWithAction:self];
}

@end

@implementation TQRemoveFromParentAction

+ (TQRemoveFromParentAction *)action {
    return [[[self alloc] init] autorelease];
}

-(void) startWithTarget:(id)aTarget {
	[super startWithTarget:aTarget];
	[((CCNode *)_target) removeFromParentAndCleanup:YES];
}

@end