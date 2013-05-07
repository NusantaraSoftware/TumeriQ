/*
 * Taken from http://www.learn-cocos2d.com/2011/01/cocos2d-gem-clippingnode/
 */

#import "ClippingNode.h"

@interface ClippingNode (PrivateMethods)
- (void)deviceOrientationChanged:(NSNotification*)notification;
@end

@implementation ClippingNode

- (id)init {
    self = [super init];
    if (self) {
        // register for device orientation change events
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:)
                                                     name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [super dealloc];
}

- (CGRect)clippingRegion {
    return clippingRegionInNodeCoordinates;
}

- (void)setClippingRegion:(CGRect)region {
    // keep the original region coordinates in case the user wants them back unchanged
    clippingRegionInNodeCoordinates = region;
    self.contentSize = clippingRegionInNodeCoordinates.size;
    
    // convert to retina coordinates if needed
    region = CC_RECT_POINTS_TO_PIXELS(region);
    
    // respect scaling
    clippingRegion = CGRectMake(region.origin.x * _scaleX, region.origin.y * _scaleY,
                                region.size.width * _scaleX, region.size.height * _scaleY);
}

- (void)setScale:(float)newScale {
    [super setScale:newScale];
    // re-adjust the clipping region according to the current scale factor
    [self setClippingRegion:clippingRegionInNodeCoordinates];
}

- (void)deviceOrientationChanged:(NSNotification*)notification {
    // re-adjust the clipping region according to the current orientation
    [self setClippingRegion:clippingRegionInNodeCoordinates];
}

- (void)visit {
    glEnable(GL_SCISSOR_TEST);
    glScissor(clippingRegion.origin.x + _position.x, clippingRegion.origin.y + _position.y,
              clippingRegion.size.width, clippingRegion.size.height);
    
    [super visit];
    
    glDisable(GL_SCISSOR_TEST);
}

@end