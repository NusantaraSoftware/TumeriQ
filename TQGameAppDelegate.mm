//
//  TQGameAppDelegate.mm
//  TumeriQ
//
//  Created by Muhammad Lukman Nasaruddin on 5/1/11.
//  Copyright 2011 Nusantara Software. All rights reserved.
//

#import "TQGameAppDelegate.h"

@implementation TQGameAppDelegate

@synthesize window = window_, rootViewController = rootViewController_;
@synthesize application = application_, applicationLaunchOptions = applicationLaunchOptions_;
@synthesize initialOrientation = initialOrientation_, supportedOrientationsMask = supportedOrientationsMask_;
@synthesize orientationLandscapeLeftSupported = orientationLandscapeLeftSupported_, orientationLandscapeRightSupported = orientationLandscapeRightSupported_;
@synthesize orientationPortraitSupported = orientationPortraitSupported_, orientationPortraitUpsideDownSupported = orientationPortraitUpsideDownSupported_;

- (id)init {
    self = [super init];
    if (self) {
        multiTouchEnabled_ = YES;
        started_ = NO;
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.application = application;
    self.applicationLaunchOptions = launchOptions;
    
    window_ = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    
    // Create an CCGLView with a RGB565 color buffer, and a depth buffer of 0-bits
    CCGLView *glView = [CCGLView viewWithFrame:[window_ bounds]
                                   pixelFormat:kEAGLColorFormatRGB565	//kEAGLColorFormatRGBA8
                                   depthFormat:GL_DEPTH24_STENCIL8_OES	//GL_DEPTH_COMPONENT24_OES
                            preserveBackbuffer:NO
                                    sharegroup:nil
                                 multiSampling:NO
                               numberOfSamples:0];
    
    // allow multi touch support
    glView.multipleTouchEnabled = multiTouchEnabled_;
    
    director_ = [CCDirector sharedDirector];
    director_.wantsFullScreenLayout = YES;
    
    // Display FSP and SPF
    //[director_ setDisplayStats:YES];
    
    // set FPS at 60
    [director_ setAnimationInterval:1.0/60];
    
    // attach the openglView to the director
    [director_ setView:glView];
    
    // for rotation and other messages
    [director_ setDelegate:self];
    
    // 2D projection
    [director_ setProjection:kCCDirectorProjection2D];
    //	[director setProjection:kCCDirectorProjection3D];
    
    // Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices
    if( ! [director_ enableRetinaDisplay:YES] )
        CCLOG(@"Retina Display Not supported");
    
    // Default texture format for PNG/BMP/TIFF/JPEG/GIF images
    // It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
    // You can change anytime.
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    
    // If the 1st suffix is not found and if fallback is enabled then fallback suffixes are going to searched. If none is found, it will try with the name without suffix.
    // On iPad HD  : "-ipadhd", "-ipad",  "-hd"
    // On iPad     : "-ipad", "-hd"
    // On iPhone HD: "-hd"
    CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
    [sharedFileUtils setEnableFallbackSuffixes:NO];				// Default: NO. No fallback suffixes are going to be used
    [sharedFileUtils setiPhoneRetinaDisplaySuffix:@"-hd"];		// Default on iPhone RetinaDisplay is "-hd"
    [sharedFileUtils setiPadSuffix:@"-ipad"];					// Default on iPad is "ipad"
    [sharedFileUtils setiPadRetinaDisplaySuffix:@"-ipadhd"];	// Default on iPad RetinaDisplay is "-ipadhd"
    
    // Assume that PVR images have premultiplied alpha
    [CCTexture2D PVRImagesHavePremultipliedAlpha:YES];
    
    // Create a Navigation Controller with the Director
    rootViewController_ = [[[TQGameRootViewController alloc] initWithRootViewController:director_] autorelease];
    [rootViewController_ setNavigationBarHidden:YES];
    [rootViewController_ setDelegate:self];
    [self configureSupportedOrientations];
    [self recalcSupportedOrientationsMask];
    
    // set the Navigation Controller as the root view controller
    [window_ setRootViewController:rootViewController_];
    
    // make main window visible
    [window_ makeKeyAndVisible];
    
    return YES;
}

- (BOOL)tqShouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    BOOL shouldRotate = ((1 << interfaceOrientation) & supportedOrientationsMask_) > 0;
	return shouldRotate;
}

- (uint)tqSupportedInterfaceOrientations {
    return supportedOrientationsMask_;
}


// This is needed for iOS4 and iOS5 in order to ensure
// that the 1st scene has the correct dimensions
// This is not needed on iOS6 and could be added to the application:didFinish...
- (void)directorDidReshapeProjection:(CCDirector*)director {
	if (!started_) {
        // Start the game
        started_ = YES;
        [self start];
	}
}

- (void)pause {
	[director_ pause];
}

- (void)resume {
    // window_ is already set so it must be the case that the app came up from background
    [director_ resume];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	if( [rootViewController_ visibleViewController] == director_ )
        [self pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	if( [rootViewController_ visibleViewController] == director_ )
        [self resume];
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
	if( [rootViewController_ visibleViewController] == director_ )
		[director_ stopAnimation];
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
	if( [rootViewController_ visibleViewController] == director_ )
		[director_ startAnimation];
}

// application will be killed
- (void)applicationWillTerminate:(UIApplication *)application {
	CC_DIRECTOR_END();
}

// purge memory
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[director_ purgeCachedData];
}

// next delta time will be zero
-(void) applicationSignificantTimeChange:(UIApplication *)application {
	[director_ setNextDeltaTimeZero:YES];
}

- (void)dealloc {
    [applicationLaunchOptions_ release];
    [rootViewController_ release];
	[window_ release];
	[director_ end];
	[super dealloc];
}

+ (TQGameAppDelegate *)getActiveInstance {
    return (TQGameAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (void)recalcSupportedOrientationsMask {
    supportedOrientationsMask_ = 0;
    if (orientationLandscapeLeftSupported_) {
        supportedOrientationsMask_ = supportedOrientationsMask_ | (1 << (uint)UIInterfaceOrientationLandscapeLeft);
    }
    if (orientationLandscapeRightSupported_) {
        supportedOrientationsMask_ = supportedOrientationsMask_ | (1 << (uint)UIInterfaceOrientationLandscapeRight);
    }
    if (orientationPortraitSupported_) {
        supportedOrientationsMask_ = supportedOrientationsMask_ | (1 << (uint)UIInterfaceOrientationPortrait);
    }
    if (orientationPortraitUpsideDownSupported_) {
        supportedOrientationsMask_ = supportedOrientationsMask_ | (1 << (uint)UIInterfaceOrientationPortraitUpsideDown);
    }
}

- (void)configureSupportedOrientations {
    initialOrientation_ = UIInterfaceOrientationLandscapeLeft;
    orientationLandscapeLeftSupported_ = YES;
    orientationLandscapeRightSupported_ = YES;
    orientationPortraitSupported_ = NO;
    orientationPortraitUpsideDownSupported_ = NO;
}

- (void)start {
    // to be overloaded
}

@end

@implementation TQGameRootViewController
@synthesize delegate = delegate_;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [delegate_ tqShouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (uint)supportedInterfaceOrientations {
    return [delegate_ tqSupportedInterfaceOrientations];
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
