//
//  TQGameControl.m
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 4/2/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import "TQGameControl.h"
#import "TQGameAudio.h"

@implementation CCMenuItem (SoundEffect)

+ (void)setActivationSoundEffect:(NSString *)fxfile {
    [[TQGameAudio sharedInstance] registerSoundEffect:fxfile forObject:self];
}

- (void)setActivationSoundEffect:(NSString *)fxfile {
    [[TQGameAudio sharedInstance] registerSoundEffect:fxfile forObject:self];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

/* Overload activate method to emit the sound effect */
- (void)activate {
	if (_isEnabled&& _block) {
		_block(self);
        TQGameAudio *audio = [TQGameAudio sharedInstanceOptional];
        if ([audio triggerSoundEffectForObject:self] == 0 && audio != nil) {
            Class soundClass = [self class];
            Class menuItemClass = [CCMenuItem class];
            while ([audio triggerSoundEffectForObject:soundClass] == 0 && soundClass != menuItemClass) {
                soundClass = [soundClass superclass];
            }
        }
    }
}

#pragma clang diagnostic pop

@end

@implementation TQMenuItemRect

+ (id)itemWithSize:(CGSize)size_ target:(id)target selector:(SEL)selector {
	return [[[self alloc] initWithSize:size_ target:target selector:selector] autorelease];
}

- (id)initWithSize:(CGSize)size_ target:(id)target selector:(SEL)selector {
	self = [super initWithTarget:target selector:selector];
	if (self) {
		size = size_;
	}
	return self;
}

- (CGRect)rect {
	return CGRectMake(_position.x - size.width / 2, _position.y - size.height / 2, size.width, size.height);
}

@end

@implementation TQMenuItemSpriteToggle
@synthesize toggledImage = toggledImage_, isToggled = isToggled_;

- (void)setToggledImage:(CCNode<CCRGBAProtocol> *)toggledImage {
	if (toggledImage != toggledImage_) {
		toggledImage.anchorPoint = ccp(0,0);
		toggledImage.visible = NO;
		
		[self removeChild:toggledImage_ cleanup:YES];
		[self addChild:toggledImage];
		
		toggledImage_ = toggledImage;
	}
}

- (void)setIsToggled:(BOOL)isToggled {
    isToggled_ = isToggled;
    if (isToggled_ && self.toggledImage) {
        self.normalImage.visible = NO;
        self.toggledImage.visible = YES;
    }
    else {
        self.normalImage.visible = YES;
        self.toggledImage.visible = NO;
    }
}

+ (void)toggle:(id)sender {
    if ([sender class] == [TQMenuItemSpriteToggle class]) {
        TQMenuItemSpriteToggle *toggle = (TQMenuItemSpriteToggle *)sender;
        toggle.isToggled = !toggle.isToggled;
    }
}

@end

@implementation TQMenuItemLabelToggle
@synthesize callback = callback_, currentLabelStringIndex = currentLabelStringIndex_;

-(id) initWithLabel:(CCNode<CCLabelProtocol,CCRGBAProtocol>*)label target:(id)target selector:(SEL)selector {
    self = [super initWithLabel:label target:target selector:selector];
    if (self) {
        labelStrings_ = [NSMutableArray new];
        [labelStrings_ addObject:self.label.string];
        currentLabelStringIndex_ = 0;
    }
    return self;
}

- (void)dealloc {
    [labelStrings_ release];
    [super dealloc];
}

- (uint)addToggleString:(NSString *)string {
    [labelStrings_ addObject:string];
    return [labelStrings_ count] - 1;
}

- (void)setCurrentLabelStringIndex:(uint)currentLabelStringIndex {
    if (currentLabelStringIndex < [labelStrings_ count]) {
        currentLabelStringIndex_ = currentLabelStringIndex;
        self.string = [labelStrings_ objectAtIndex:currentLabelStringIndex_];
        if (callback_) {
            callback_(self, currentLabelStringIndex_);
        }
    }
}

- (uint)toggle {
    uint newLabelStringIndex = currentLabelStringIndex_ + 1;
    if (newLabelStringIndex >= [labelStrings_ count]) {
        newLabelStringIndex = 0;
    }
    self.currentLabelStringIndex = newLabelStringIndex;
    return self.currentLabelStringIndex;
}

+ (void)toggle:(id)sender {
    if ([sender class] == [TQMenuItemLabelToggle class]) {
        TQMenuItemLabelToggle *toggle = (TQMenuItemLabelToggle *)sender;
        [toggle toggle];
    }
}

@end
