//
//  TQGameGraphics.m
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 5/6/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import "TQGameGraphics.h"

@implementation TQTiledBackgroundLayer

+ (TQTiledBackgroundLayer *)layerWithImageFile:(NSString *)fileImage bottomLeft:(CGPoint)bottomLeft topRight:(CGPoint)topRight {
    return [[[TQTiledBackgroundLayer alloc] initWithFile:fileImage bottomLeft:bottomLeft topRight:topRight] autorelease];
}

- (id)initWithFile:(NSString *)fileImage bottomLeft:(CGPoint)bottomLeft topRight:(CGPoint)topRight {
    bottomLeft_ = bottomLeft;
    topRight_ = topRight;
    CCTexture2D *tex = [[CCTextureCache sharedTextureCache] addImage:fileImage];
    [tex setAliasTexParameters];
    CGSize textureSize = [tex contentSize];
    uint verticalTileCount = ceil((topRight_.y - bottomLeft_.y) / textureSize.height);
    uint horizontalTileCount = ceil((topRight_.x - bottomLeft_.x) / textureSize.width);
    
    self = [super initWithTexture:tex capacity:horizontalTileCount * verticalTileCount];
    if (self) {
        for (uint i = 0; i < horizontalTileCount; i++) {
            for (uint j = 0; j < verticalTileCount; j++) {
                CCSprite *tile = [CCSprite spriteWithTexture:tex rect:CGRectMake(0, 0, textureSize.width, textureSize.height)];
                tile.batchNode = self;
                tile.anchorPoint = CGPointZero;
                tile.position = CGPointMake(bottomLeft.x + i * textureSize.width, bottomLeft.y + j * textureSize.height);
                [tile.texture setAliasTexParameters];
                [self addChild:tile];
            }
        }
    }
    return self;
}

@end

@implementation TQCrossFadeBackgroundLayer
@synthesize sprite = sprite_;

- (id)initWithSprite:(CCSprite *)sprite {
    self = [super init];
    if (self) {
        if (sprite) {
            sprite_ = sprite;
            sprite_.position = ccp([CCDirector sharedDirector].winSize.width / 2.0, [CCDirector sharedDirector].winSize.height / 2.0);
            [self addChild:sprite_];
        }
    }
    return self;
}

+ (TQCrossFadeBackgroundLayer *)layerWithSprite:(CCSprite *)sprite {
    return [[[TQCrossFadeBackgroundLayer alloc] initWithSprite:sprite] autorelease];
}

- (void)changeSpriteTo:(CCSprite *)sprite withCrossFadeTime:(ccTime)crossTime {
    __block CCSprite *oldsprite = sprite_;
    sprite_ = sprite;
    sprite_.opacity = 0.0;
    sprite_.position = ccp([CCDirector sharedDirector].winSize.width / 2.0, [CCDirector sharedDirector].winSize.height / 2.0);
    [self addChild:sprite_];
    [sprite_ runAction:[CCFadeIn actionWithDuration:crossTime]];
    if (oldsprite) {
        [oldsprite runAction:
         [CCSequence actions:
          [CCFadeOut actionWithDuration:crossTime],
          [CCCallBlock actionWithBlock:^{ [oldsprite removeFromParentAndCleanup:YES]; }],
          nil]];
    }
}

@end

@implementation TQAnimateSprite

- (id)initWithFile:(NSString *)animateFile {
    // read the config from file
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:animateFile ofType:@"plist"]];
    NSArray *frameNames = (NSArray *)[config objectForKey:@"frames"];
    NSNumber *delay = (NSNumber *)[config objectForKey:@"delay"];
    NSString *spritesheet = (NSString *)[config objectForKey:@"spritesheet"];
    float delayf = (delay? [delay floatValue] : 0.0);
    NSNumber *restore = (NSNumber *)[config objectForKey:@"restore"];
    BOOL restoreb = (restore? [restore boolValue] : YES);
    
    // load spritesheet into CCSpriteFrameCache
    if (spritesheet && ![spritesheet isEqualToString:@""]) {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:spritesheet];
    }
    
    // create array of SpriteFrame
    CCSpriteFrameCache *cache = [CCSpriteFrameCache sharedSpriteFrameCache];
    NSMutableArray *frames = [NSMutableArray array];
    for (NSString *frameName in frameNames) {
        [frames addObject:[cache spriteFrameByName:frameName]];
    }
    
    // create the CCAnimation and init using super call
    CCAnimation *animation = [CCAnimation animationWithSpriteFrames:frames delay:delayf];
    animation.restoreOriginalFrame = restoreb;
    self = [super initWithAnimation:animation];
    return self;
}


- (id)initWithDelay:(float)delay andSpriteFrameNamesArray:(NSArray *)frameNames {
    CCSpriteFrameCache *cache = [CCSpriteFrameCache sharedSpriteFrameCache];
    NSMutableArray *frames = [NSMutableArray array];
    
    for (NSString *frameName in frameNames) {
        [frames addObject:[cache spriteFrameByName:frameName]];
    }
    
    CCAnimation *animation = [CCAnimation animationWithSpriteFrames:frames delay:delay];
    animation.restoreOriginalFrame = YES;
    self = [super initWithAnimation:animation];
    return self;
}

+ (TQAnimateSprite *)actionWithFile:(NSString *)animateFile {
    TQAnimateSprite *action = [[TQAnimateSprite alloc] initWithFile:animateFile];
    return [action autorelease];
}

+ (TQAnimateSprite *)actionWithDelay:(float)delay andSpriteFrameNames:(NSString *)frameName, ... {
    va_list args;
    NSMutableArray *frameNames = [NSMutableArray array];
    va_start(args, frameName);
    while (frameName) {
        [frameNames addObject:frameName];
        frameName = va_arg(args, NSString *);
    }
    va_end(args);
    
    TQAnimateSprite *action = [[TQAnimateSprite alloc] initWithDelay:delay andSpriteFrameNamesArray:frameNames];
    return [action autorelease];
}

- (CCRepeatForever *)animateForever {
    return [self repeatForever];
}

- (CCSprite *)createSprite {
    return [CCSprite spriteWithSpriteFrame:[_animation.frames objectAtIndex:0]];
}

@end

@implementation TQProgressBarSprite
@synthesize progressPercentage = progressPercentage_;

- (id)initWithSprite:(CCSprite *)sprite andDirection:(FourDirection)direction andProgress:(int)progressPercentage {
    rectangleStencil_ = [CCDrawNode node];
    self = [super initWithStencil:rectangleStencil_];
    if (self) {
        spriteImage_ = sprite;
        direction_ = direction;
        
        // Set the default anchor point depending on direction.
        switch (direction_) {
            case DIRECTION_RIGHT: self.anchorPoint = ccp(0, 0.5); break;
            case DIRECTION_LEFT: self.anchorPoint = ccp(1, 0.5); break;
            case DIRECTION_UP: self.anchorPoint = ccp(0.5, 0); break;
            case DIRECTION_DOWN: self.anchorPoint = ccp(1, 0); break;
            default: self.anchorPoint = ccp(0.5, 0.5); break;
        }
        
        [self addChild:spriteImage_];
        self.contentSize = spriteImage_.contentSize;
        spriteImage_.anchorPoint = spriteImage_.position = CGPointZero;
        rectangleStencil_.anchorPoint = rectangleStencil_.position = CGPointZero;
        self.progressPercentage = progressPercentage_;
    }
    return self;
}

+ (TQProgressBarSprite *)progressBarWithSprite:(CCSprite *)sprite andDirection:(FourDirection)direction andProgress:(int)progressPercentage {
    return [[[TQProgressBarSprite alloc] initWithSprite:sprite andDirection:direction andProgress:progressPercentage] autorelease];
}

- (void)setProgressPercentage:(int)percentage {
    progressPercentage_ = MIN(MAX(percentage,0),100);
    CGPoint spriteOrigin = CGPointZero;
    CGPoint verts[4];
    switch (direction_) {
        case DIRECTION_DOWN:
            verts[0] = ccp(spriteOrigin.x, spriteOrigin.y);
            verts[2] = ccp(spriteOrigin.x + spriteImage_.contentSize.width, spriteOrigin.y + spriteImage_.contentSize.height * progressPercentage_ / 100.0);
            break;
            
        case DIRECTION_UP:
            verts[0] = ccp(spriteOrigin.x, spriteOrigin.y + spriteImage_.contentSize.height * (100 - progressPercentage_) / 100.0);
            verts[2] = ccp(spriteOrigin.x + spriteImage_.contentSize.width, spriteOrigin.y + spriteImage_.contentSize.height);
            break;
            
        case DIRECTION_RIGHT:
            verts[0] = ccp(spriteOrigin.x, spriteOrigin.y);
            verts[2] = ccp(spriteOrigin.x + spriteImage_.contentSize.width * progressPercentage_ / 100.0, spriteOrigin.y + spriteImage_.contentSize.height);
            break;
            
        default:
            verts[0] = ccp(spriteOrigin.x + spriteImage_.contentSize.width * (100 - progressPercentage_) / 100.0, spriteOrigin.y);
            verts[2] = ccp(spriteOrigin.x + spriteImage_.contentSize.width, spriteOrigin.y + spriteImage_.contentSize.height);
    }
    verts[1] = ccp(verts[2].x,verts[0].y);
    verts[3] = ccp(verts[0].x, verts[2].y);
    [rectangleStencil_ clear];
    [rectangleStencil_ drawPolyWithVerts:verts count:4 fillColor:ccc4f(0,0,0,255) borderWidth:0 borderColor:ccc4f(0,0,0,255)];
}

@end

@implementation TQBlade

+ (TQBlade *)bladeWithImage:(NSString *)image andWidth:(float)width andMaximumPoint:(int)limit {
    TQBlade *blade = [CCBlade bladeWithMaximumPoint:limit];
    blade.texture = [[CCTextureCache sharedTextureCache] addImage:image];
    blade.width = width;
    return blade;
}

@end

@implementation TQLabelNumberAnimator
@synthesize currentValue = currentValue_, targetValue = targetValue_;
@synthesize label = label_, deltaValuePerSecond = deltaValuePerSecond_;
@synthesize formatter = formatter_, callback = callback_;

- (id)initWithLabel:(CCNode<CCLabelProtocol> *)label andCurrentValue:(int)currentValue andDeltaValuePerSecond:(uint)deltaValuePerSecond {
    self = [super init];
    if (self) {
        self.currentValue = currentValue;
        self.deltaValuePerSecond = deltaValuePerSecond;
        label_ = label;
        formatter_ = [[NSNumberFormatter alloc] init];
    }
    return self;
}

+ (TQLabelNumberAnimator *)numberAnimatorWithLabel:(CCNode<CCLabelProtocol> *)label andCurrentValue:(int)currentValue andDeltaValuePerSecond:(uint)deltaValuePerSecond {
    return [[[self alloc] initWithLabel:label andCurrentValue:currentValue andDeltaValuePerSecond:deltaValuePerSecond] autorelease];
}

- (void)removeFromParentAndCleanup:(BOOL)cleanup {
    label_ = nil;
    [super removeFromParentAndCleanup:cleanup];
}

- (void)dealloc {
    [[CCDirector sharedDirector].scheduler unscheduleUpdateForTarget:self];
    [formatter_ release];
    [callback_ release];
    [super dealloc];
}

- (void)setTargetValue:(int)targetValue {
    targetValue_ = targetValue;
    [[CCDirector sharedDirector].scheduler unscheduleUpdateForTarget:self];
    [[CCDirector sharedDirector].scheduler scheduleUpdateForTarget:self priority:0 paused:NO];
}

- (void)setCurrentValue:(int)currentValue {
    currentValue_ = currentValue;
    [label_ setString:[self.formatter stringFromNumber:[NSNumber numberWithInt:currentValue_]]];    
}

- (void)setDeltaValuePerSecond:(uint)deltaValuePerSecond {
    NSAssert(deltaValuePerSecond > 0, @"deltaValuePerSecond must be larger than 0.");
    deltaValuePerSecond_ = deltaValuePerSecond;
}

- (void)update:(ccTime)dt {
    int increment = (uint)ceilf(deltaValuePerSecond_ * dt);
    if (targetValue_ > currentValue_) {
        self.currentValue = MIN(targetValue_, currentValue_ + increment);
    }
    else if (targetValue_ < currentValue_) {
        self.currentValue = MAX(targetValue_, currentValue_ - increment);
    }
    else {
        if (callback_) {
            callback_(self, targetValue_);
        }
        [[CCDirector sharedDirector].scheduler unscheduleUpdateForTarget:self];
    }
}

@end

@implementation TQLabelTTF

- (void)addStrokeWithSize:(float)size andColor:(ccColor3B)color {
    [self addStrokeWithSize:size andColor:color andOpacity:255];
}

- (void)addStrokeWithSize:(float)size andColor:(ccColor3B)color andOpacity:(GLubyte)opacity {
    // remove existing stroke
    if (strokeTexture_) {
        [self removeChild:strokeTexture_ cleanup:YES];
        strokeTexture_ = nil;
    }
    // store parameters
    strokeSize_ = size;
    strokeColor_ = color;
    strokeOpacity_ = opacity;
    labelOrigOpacity_ = self.opacity;
    // and add the new one
    if (strokeSize_ > 0.0) {
        strokeTexture_ = [self createStrokeWithSize:size andColor:color andOpacity:opacity];
        strokeTexture_.position = ccp(self.contentSize.width / 2, self.contentSize.height / 2);
        [self addChild:strokeTexture_ z:-1];
    }
}

- (void)setString:(NSString *)str {
    [super setString:str];
    [self addStrokeWithSize:strokeSize_ andColor:strokeColor_ andOpacity:strokeOpacity_];
}

- (void)setOpacity:(GLubyte)opacity {
    [super setOpacity:opacity];
    strokeTexture_.sprite.opacity = MIN(255, opacity * strokeOpacity_ / labelOrigOpacity_);
}

@end

@implementation TQLayer

- (id)init {
    if ((self = [super init])) {
        sublayers_ = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [sublayers_ release];
    [super dealloc];
}

- (TQLayer *)getSublayerWithName:(NSString *)name {
    TQLayer *layer = [sublayers_ objectForKey:name];
    if (!layer) {
        layer = [[TQLayer alloc] init];
        [self addChild:layer];
        [sublayers_ setObject:layer forKey:name];
    }
    return layer;
}

- (void)removeSublayerWithName:(NSString *)name {
    TQLayer *layer = [sublayers_ objectForKey:name];
    if (layer) {
        [self removeChild:layer cleanup:YES];
    }
    [sublayers_ removeObjectForKey:name];
}

@end