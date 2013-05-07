/*
 * Taken from http://www.learn-cocos2d.com/2011/01/cocos2d-gem-clippingnode/
 */

#import "cocos2d.h"

@interface ClippingNode : CCNode {
    CGRect clippingRegionInNodeCoordinates;
    CGRect clippingRegion;
}
@property (nonatomic) CGRect clippingRegion;

@end
