//
//  TQGameMechanics+MultiTouch.mm
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 6/8/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import "TQGameMechanics+MultiTouch.h"

@implementation TQTouchInfo
@synthesize tag = tag_, touch = touch_, event = event_, location = location_, start = start_, previous = previous_, stayedDuration = stayedDuration_, duration = duration_, timeLastMoved = timeLastMoved_;
@synthesize data = data_, cdata = cdata_, pointerSprite = pointerSprite_;
@synthesize node = node_, handledByTouchDelegate = handledByTouchDelegate_, targetObject = targetObject_;

- (id)initWithTouch:(UITouch *)touch andEvent:(UIEvent *)event forNode:(CCNode *)node {
    self = [super init];
    if (self) {
        tag_ = 0;
        data_ = NULL;
        touch_ = [touch retain];
        node_ = node; // weak reference only
        [self updateForCurrentEvent:event];
        [self rememberAsPreviousLocation];
        start_ = previous_;
        timeLastMoved_ = 0.0;
        stayedDuration_ = 0.0;
    }
    return self;
}

- (void)dealloc {
    if (pointerSprite_) {
        [pointerSprite_ removeFromParentAndCleanup:YES];
    }
    [event_ release];
    [touch_ release];
    [super dealloc];
}

- (void)updateForCurrentEvent:(UIEvent *)event {
    [event_ release];
    event_ = [event retain];
    location_ = [node_ convertTouchToNodeSpace:touch_];
    if (pointerSprite_) {
        pointerSprite_.position = location_;
    }
}

- (void)rememberAsPreviousLocation {
    previous_ = TQTimeAndLocationCreate(location_, 0.0f);
}

- (void)setPointerSprite:(CCSprite *)sprite {
    if (pointerSprite_) {
        [pointerSprite_ removeFromParentAndCleanup:YES];
    }
    if (sprite) {
        [node_ addChild:sprite];
    }
    pointerSprite_ = sprite;
}

@end

@implementation TQMultiTouchLayer
@synthesize maxTouches = maxTouches_, delegate = delegate_;

- (id)init {
    self = [super init];
    if (self) {
        touches_ = [[NSMutableDictionary alloc] init];
        maxTouches_ = 2; // default to 2, subclass needs to overwrite to change
        [self setTouchEnabled:YES];
        [self schedule:@selector(updateTime:)];
    }
    return self;
}

- (void)dealloc {
    [touches_ release];
    [super dealloc];
}

- (TQTouchInfo *)findTouchInfoByTag:(uint)tag {
    TQTouchInfo *touchInfo = nil;
    for (id key in touches_) {
        TQTouchInfo *checkTouch = (TQTouchInfo *)[touches_ objectForKey:key];
        if (checkTouch.tag == tag) {
            touchInfo = checkTouch;
            break;
        }
    }
    return touchInfo;
}

- (uint)currentNumberOfTouches {
    return [touches_ count];
}

- (void)updateTime:(ccTime)dt {
    for (TQTouchInfo *touchInfo in [touches_ allValues]) {
        float currentTime = [[NSDate date] timeIntervalSince1970];
        touchInfo.duration += dt;
        if (currentTime - touchInfo.timeLastMoved >= dt) {
            touchInfo.stayedDuration += dt;
            if ([touchInfo.handledByTouchDelegate respondsToSelector:@selector(tqTouchStayed:dt:fromLayer:)]) {
                [touchInfo.handledByTouchDelegate tqTouchStayed:touchInfo dt:dt fromLayer:self];
            }
        }
    }
}

- (void)registerWithTouchDispatcher {
	[[CCDirector sharedDirector].touchDispatcher addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL)checkIfTouchInfo:(TQTouchInfo *)touchInfo shouldBeHandledBy:(id<TQMultiTouchLayerDelegate>)delegate {
    BOOL shouldConsumeTouch = NO;
    if ([delegate respondsToSelector:@selector(tqTouchBegan:onObject:)]) {
        if (_children) {
            // iterate through children based on z-order from front to the back
            ccArray *arrayData = _children->data;
            int i = arrayData->num;
            while (i > 0) {
                i--;
                CCNode *child = arrayData->arr[i];
                if ([child conformsToProtocol:@protocol(TQMultiTouchTargetObject)] &&
                    [child containsPoint:touchInfo.location] &&
                    [delegate tqTouchBegan:(TQTouchInfo *)touchInfo onObject:(CCNode<TQMultiTouchTargetObject> *)child]) {
                    touchInfo.targetObject = (CCNode<TQMultiTouchTargetObject> *)child;
                    shouldConsumeTouch = YES;
                    break;
                }
            }
        }
    }
    if (!shouldConsumeTouch) {
        shouldConsumeTouch = [delegate tqTouchBegan:touchInfo fromLayer:self];
    }
    if (shouldConsumeTouch) {
        touchInfo.handledByTouchDelegate = delegate;
    }
    return shouldConsumeTouch;
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL shouldConsumeTouch = NO;
    if ([self currentNumberOfTouches] < maxTouches_) {
        TQTouchInfo *touchInfo = [[TQTouchInfo alloc] initWithTouch:touch andEvent:event forNode:self];
        if (delegate_) {
            shouldConsumeTouch = [self checkIfTouchInfo:touchInfo shouldBeHandledBy:delegate_];
        }
        if (!shouldConsumeTouch) {
            shouldConsumeTouch = [self checkIfTouchInfo:touchInfo shouldBeHandledBy:self];
        }
        if (shouldConsumeTouch) {
            [touches_ setObject:touchInfo forKey:[NSNumber numberWithInt:[touch hash]]];
        }
        [touchInfo release];
    }
    return shouldConsumeTouch;
}

- (BOOL)tqTouchBegan:(TQTouchInfo *)touchInfo {
    // to be overloaded by subclass
    return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    TQTouchInfo *touchInfo = [touches_ objectForKey:[NSNumber numberWithInt:[touch hash]]];
    if (touchInfo) {
        touchInfo.timeLastMoved = [[NSDate date] timeIntervalSince1970];
        touchInfo.stayedDuration = 0.0;
        [touchInfo updateForCurrentEvent:event];
        if (touchInfo.targetObject != nil) {
            if ([touchInfo.handledByTouchDelegate respondsToSelector:@selector(tqTouchMoved:onObject:)]) {
                [touchInfo.handledByTouchDelegate tqTouchMoved:touchInfo onObject:touchInfo.targetObject];
            }
        }
        else {
            if ([touchInfo.handledByTouchDelegate respondsToSelector:@selector(tqTouchMoved:fromLayer:)]) {
                [touchInfo.handledByTouchDelegate tqTouchMoved:touchInfo fromLayer:self];
            }
        }
    }
}

- (void)tqTouchMoved:(TQTouchInfo *)touchInfo {
    // to be overloaded by subclass
}

- (void)tqTouchStayed:(TQTouchInfo *)touchInfo dt:(ccTime)dt {
    // to be overloaded by subclass
}

- (void)ccTouchEndedOrCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
    NSNumber *touchHash = [NSNumber numberWithInt:[touch hash]];
    TQTouchInfo *touchInfo = [touches_ objectForKey:touchHash];
    if (touchInfo) {
        [touchInfo updateForCurrentEvent:event];
        if (touchInfo.targetObject != nil) {
            if ([touchInfo.handledByTouchDelegate respondsToSelector:@selector(tqTouchEnded::onObject:)]) {
                [touchInfo.handledByTouchDelegate tqTouchEnded:touchInfo onObject:touchInfo.targetObject];
            }
        }
        else {
            if ([touchInfo.handledByTouchDelegate respondsToSelector:@selector(tqTouchEnded:fromLayer:)]) {
                [touchInfo.handledByTouchDelegate tqTouchEnded:touchInfo fromLayer:self];
            }
        }
        [touches_ removeObjectForKey:touchHash];
    }
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    [self ccTouchEndedOrCancelled:touch withEvent:event];
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
    [self ccTouchEndedOrCancelled:touch withEvent:event];
}

- (void)tqTouchEnded:(TQTouchInfo *)touchInfo {
    // to be overloaded by subclass
}

- (BOOL)tqTouchBegan:(TQTouchInfo *)touchInfo fromLayer:(TQMultiTouchLayer *)layer {
    if (layer != self) {
        return NO;
    }
    return [layer tqTouchBegan:touchInfo];
}

- (void)tqTouchMoved:(TQTouchInfo *)touchInfo fromLayer:(TQMultiTouchLayer *)layer {
    if (layer == self) {
        return [layer tqTouchMoved:touchInfo];
    }
}

- (void)tqTouchStayed:(TQTouchInfo *)touchInfo dt:(ccTime)dt fromLayer:(TQMultiTouchLayer *)layer {
    if (layer == self) {
        return [layer tqTouchStayed:touchInfo dt:dt];
    }
}

- (void)tqTouchEnded:(TQTouchInfo *)touchInfo fromLayer:(TQMultiTouchLayer *)layer {
    if (layer == self) {
        return [layer tqTouchEnded:touchInfo];
    }
}

@end

@implementation TQDraggableLayer
@synthesize actualContentSize = actualContentSize_, isDragging = isDragging_, draggingEnabled = draggingEnabled_;

- (id)init {
    self = [super init];
    if (self) {
        self.actualContentSize = [[CCDirector sharedDirector] winSize];
        self.anchorPoint = CGPointZero;
        screenSize_ = [[CCDirector sharedDirector] winSize];
        draggingEnabled_ = YES;
        
        // just some random integer between 9,000,000 - 9,999,999
        touchInfoTag_ = rand() % 999999 + 9000000;
        [self schedule:@selector(scrollTick:)];
    }
    return self;
}

- (id)initWithContentSize:(CGSize)size {
    self = [self init];
    if (self) {
        self.actualContentSize = size;
    }
    return self;
}

- (void)dealloc {
    //[scrollAction_ release];
    [super dealloc];
}

- (void)setActualContentSize:(CGSize)size {
    actualContentSize_ = size;
    [self scrollToPoint:scrollingDestination_ withinDuration:0.0f];
}

#pragma mark Touch event listener

- (BOOL)tqTouchBegan:(TQTouchInfo *)touchInfo {
    if (draggingEnabled_ && [self findTouchInfoByTag:touchInfoTag_] == nil) {
        touchInfo.tag = touchInfoTag_;
        dragStartLocation_ = touchInfo.location;
        isDragging_ = YES;
        scrollingDuration_ = 0.0f; // stop scrolling
        return YES;
    }
    return NO;
}

- (void)tqTouchMoved:(TQTouchInfo *)touchInfo {
    if (touchInfo.tag == touchInfoTag_) {
        CGPoint diffLocation = CGPointMake(touchInfo.location.x - dragStartLocation_.x, touchInfo.location.y - dragStartLocation_.y);
        CGPoint newScrollPoint = CGPointMake(self.position.x + diffLocation.x, self.position.y + diffLocation.y);
        CGPoint oldPosition = self.position;
        [self scrollToPoint:newScrollPoint withinDuration:0];
        dragStartLocation_ = CGPointMake(touchInfo.location.x - self.position.x + oldPosition.x, touchInfo.location.y - self.position.y + oldPosition.y);
    }
}

- (void)tqTouchEnded:(TQTouchInfo *)touchInfo {
    [super tqTouchEnded:touchInfo];
    if (touchInfo.tag == touchInfoTag_) {
        isDragging_ = NO;
    }
}

- (void)scrollToPosition:(TQScrollPosition)position withinDuration:(ccTime)duration {
    CGPoint point;
    switch (position) {
        case SCROLL_BOTTOM_LEFT:
            point = CGPointZero;
            break;
        case SCROLL_BOTTOM_CENTER:
            point = CGPointMake((screenSize_.width - actualContentSize_.width) / 2.0, 0.0);
            break;
        case SCROLL_BOTTOM_RIGHT:
            point = CGPointMake(screenSize_.width - actualContentSize_.width, 0.0);
            break;
        case SCROLL_MIDDLE_LEFT:
            point = CGPointMake(0.0, (screenSize_.height - actualContentSize_.height) / 2.0);
            break;
        case SCROLL_MIDDLE_CENTER:
            point = CGPointMake((screenSize_.width - actualContentSize_.width) / 2.0, (screenSize_.height - actualContentSize_.height) / 2.0);
            break;
        case SCROLL_MIDDLE_RIGHT:
            point = CGPointMake(screenSize_.width - actualContentSize_.width, (screenSize_.height - actualContentSize_.height) / 2.0);
            break;
        case SCROLL_TOP_LEFT:
            point = CGPointMake(0.0, screenSize_.height - actualContentSize_.height);
            break;
        case SCROLL_TOP_CENTER:
            point = CGPointMake((screenSize_.width - actualContentSize_.width) / 2.0, screenSize_.height - actualContentSize_.height);
            break;
        case SCROLL_TOP_RIGHT:
            point = CGPointMake(screenSize_.width - actualContentSize_.width, screenSize_.height - actualContentSize_.height);
            break;
    }
    [self scrollToPoint:point withinDuration:duration];
}

- (void)scrollToPoint:(CGPoint)point withinDuration:(ccTime)duration {
    if (point.x > 0) {
        point.x = 0;
    }
    if (point.y > 0) {
        point.y = 0;
    }
    if (point.x + actualContentSize_.width < screenSize_.width) {
        point.x = screenSize_.width - actualContentSize_.width;         
    }
    if (point.y + actualContentSize_.height < screenSize_.height) {
        point.y = screenSize_.height - actualContentSize_.height;         
    }

    scrollingDestination_ = point;
    if (duration > 0) {
        scrollingDuration_ = duration;
    }
    else {
        self.position = point;
    }
}

- (void)scrollToCenterizePoint:(CGPoint)point withinDuration:(ccTime)duration {
    CGPoint scrollToPoint = CGPointMake(screenSize_.width / 2 - point.x, screenSize_.height / 2 - point.y);
    [self scrollToPoint:scrollToPoint withinDuration:duration];
}

- (void)scrollTick:(ccTime)dt {
    if (scrollingDuration_ > 0.0) {
        self.position = ccpLerp(self.position, scrollingDestination_, dt / scrollingDuration_);
        scrollingDuration_ -= dt;
    }
}

- (BOOL)isDragging {
    return ([self findTouchInfoByTag:touchInfoTag_] != nil);
}

- (CGPoint)getCurrentCenterPoint {
    return ccp(screenSize_.width / 2 - self.position.x, screenSize_.height / 2 - self.position.y);
}

- (CGRect)getCurrentRect {
    return CGRectMake(-self.position.x, -self.position.y, screenSize_.width, screenSize_.height);
}

@end

