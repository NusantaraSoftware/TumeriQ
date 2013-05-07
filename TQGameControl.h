//
//  TQGameControl.h
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 4/2/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import "cocos2d.h"

@interface CCMenuItem (SoundEffect)

+ (void)setActivationSoundEffect:(NSString *)fxfile;
- (void)setActivationSoundEffect:(NSString *)fxfile;

@end

@interface TQMenuItemRect : CCMenuItem {
	CGSize size;
}

+ (id)itemWithSize:(CGSize)size_ target:(id)target selector:(SEL)selector;
- (id)initWithSize:(CGSize)size_ target:(id)target selector:(SEL)selector;

@end

@interface TQMenuItemSpriteToggle : CCMenuItemSprite {
    CCNode<CCRGBAProtocol> *toggledImage_;
    BOOL isToggled_;
}
@property (nonatomic,retain) CCNode<CCRGBAProtocol> *toggledImage;
@property (nonatomic,assign) BOOL isToggled;

+ (void)toggle:(id)sender;

@end;

@class TQMenuItemLabelToggle;

typedef void(^TQMenuItemLabelToggleCallback)(TQMenuItemLabelToggle *, uint);

@interface TQMenuItemLabelToggle : CCMenuItemLabel {
    NSMutableArray *labelStrings_;
    uint currentLabelStringIndex_;
    TQMenuItemLabelToggleCallback callback_;
}
@property (nonatomic, copy) TQMenuItemLabelToggleCallback callback;
@property (nonatomic, assign) uint currentLabelStringIndex;

- (uint)addToggleString:(NSString *)string;
- (uint)toggle;

@end
