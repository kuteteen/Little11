#import <UIKit/UIKit.h>
#include <sys/utsname.h>
#define CGRectSetY(rect, y) CGRectMake(rect.origin.x, y, rect.size.width, rect.size.height)

NSInteger statusBarStyle, screenRoundness, appswitcherRoundness, bottomInsetVersion;
BOOL wantsHomeBarSB, wantsHomeBarLS, wantsKeyboardDock, wantsRoundedAppSwitcher, wantsReduceRows, wantsRoundedCorners, wants11Camera;
BOOL disableGestures = NO, wantsGesturesDisabledWhenKeyboard, wantsCCGrabber, wantsPIP, wantsProudLock, wantsHideSBCC,wantsLSShortcuts, wantsBatteryPercent, wantsiPadDock;

%hook BSPlatform
- (NSInteger)homeButtonType {
	return 2;
}
%end

@interface CSTeachableMomentsContainerView : UIView
@property(retain, nonatomic) UIView *controlCenterGrabberView;
@property(retain, nonatomic) UIView *controlCenterGrabberEffectContainerView;
@property (retain, nonatomic) UIImageView * controlCenterGlyphView; 
@end


%group ForceDefaultKeyboard
%hook UIKeyboardImpl
+(UIEdgeInsets)deviceSpecificPaddingForInterfaceOrientation:(NSInteger)orientation inputMode:(id)mode {
    UIEdgeInsets orig = %orig;
    orig.bottom = 0;
    orig.left = 0;
    orig.right = 0;
    return orig;
}
%end
%end

@interface CSQuickActionsView : UIView
- (UIEdgeInsets)_buttonOutsets;
@property (nonatomic, retain) UIControl *flashlightButton; 
@property (nonatomic, retain) UIControl *cameraButton;
@end

%hook CSQuickActionsView
- (BOOL)_prototypingAllowsButtons {
	return wantsLSShortcuts;
}
- (void)_layoutQuickActionButtons {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    int inset = [self _buttonOutsets].top;

    [self flashlightButton].frame = CGRectMake(46, screenBounds.size.height - 90 - inset, 50, 50);
	[self cameraButton].frame = CGRectMake(screenBounds.size.width - 96, screenBounds.size.height - 90 - inset, 50, 50);
}
%end

%group HideSBCC
%hook CCUIStatusBarStyleSnapshot
-(BOOL)isHidden {
    return YES;
}
%end

%hook CCUIOverlayStatusBarPresentationProvider
- (void)_addHeaderContentTransformAnimationToBatch:(id)arg1 transitionState:(id)arg2 {
    %orig(nil, arg2);
}
%end
%end

%group batteryPercent
%hook _UIBatteryView 
-(void)setShowsPercentage:(BOOL)arg1 {
    return %orig(YES);
}
%end 

%hook _UIStatusBarStringView  
- (void)setText:(NSString *)text {
	if([text containsString:@"%"]) 
      return;
    else 
       %orig(text);
}     
%end
%end

%hook SBReachabilitySettings
- (void)setSystemWideSwipeDownHeight:(double) systemWideSwipeDownHeight { 
    %orig(100);
}
%end

%group StatusBarX
%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    return NSClassFromString(@"_UIStatusBarVisualProvider_Split58");
}
%end

%hook SBIconListGridLayoutConfiguration
- (UIEdgeInsets)portraitLayoutInsets { 
    UIEdgeInsets x = %orig;
    return  UIEdgeInsetsMake(x.top+10, x.left, x.bottom,x.right);
}
%end
%end

%group StatusBariPad
%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    if(screenRoundness > 15) return NSClassFromString(@"_UIStatusBarVisualProvider_RoundedPad_ForcedCellular");
    return NSClassFromString(@"_UIStatusBarVisualProvider_Pad_ForcedCellular");
}
%end

%hook CCUIHeaderPocketView
- (void)setFrame:(CGRect)frame {
    if(screenRoundness > 15) %orig(CGRectSetY(frame, -20));
    else %orig(CGRectSetY(frame, -24));
}
%end
%end

%hook SBFHomeGrabberSettings
- (BOOL)isEnabled {
    return wantsHomeBarSB;
} 
%end


%group hideHomeBarLS
%hook CSTeachableMomentsContainerView
-(void)setHomeAffordanceContainerView:(UIView *)arg1{
    return;
}
%end
%end

%group completelyRemoveHomeBar
%hook MTLumaDodgePillSettings
- (void)setHeight:(double)arg1 {
	arg1 = 0;
	%orig;
}
%end
%end 

%group KeyboardDock
%hook UIKeyboardImpl
+(UIEdgeInsets)deviceSpecificPaddingForInterfaceOrientation:(NSInteger)orientation inputMode:(id)mode {
    UIEdgeInsets orig = %orig;
    if (!NSClassFromString(@"BarmojiCollectionView")) 
         orig.bottom = 46;
	if (orig.left == 75)  {
        orig.left = 0;
        orig.right = 0;
    }
    return orig;
}
%end

%hook UIKeyboardDockView
- (CGRect)bounds {
    if (NSClassFromString(@"BarmojiCollectionView")) 
        return %orig;

    CGRect bounds = %orig;
    bounds.size.height += 15;
    return bounds;
}
%end
%end


%group roundedDock

%hook UITraitCollection
- (CGFloat)displayCornerRadius {
	return appswitcherRoundness;
}
%end
%end


%group reduceRows
%hook SBIconListView
-(unsigned long long)iconRowsForCurrentOrientation{
    if (%orig<4) return %orig;
	return %orig-wantsReduceRows + wantsiPadDock;
}
%end
%end


%group ccGrabber

%hook CSTeachableMomentsContainerView
- (void)_layoutControlCenterGrabberAndGlyph  {
    %orig;
    if(statusBarStyle == 2) {
        self.controlCenterGrabberEffectContainerView.frame = CGRectMake(self.frame.size.width - 73,36,46,2.5);
        self.controlCenterGrabberView.frame = CGRectMake(0,0,46,2.5);
        self.controlCenterGlyphView.frame = CGRectMake(315,45,16.6,19.3);
    } else if(statusBarStyle == 1) {
        self.controlCenterGrabberEffectContainerView.frame = CGRectMake(self.frame.size.width - 75.5,24,60.5,2.5);
        self.controlCenterGrabberView.frame = CGRectMake(0,0,60.5,2.5);
        self.controlCenterGlyphView.frame = CGRectMake(320,35,16.6,19.3);
    }
}
%end
%end

// Allows you to use the non-X iPhone button combinations. - For some reason only works on some devices
%group originalButtons
%hook SBPressGestureRecognizer
- (void)setAllowedPressTypes:(NSArray *)arg1 {
    NSArray * lockHome = @[@104, @101];
    NSArray * lockVol = @[@104, @102, @103];
    if ([arg1 isEqual:lockVol]) {
        return %orig(lockHome);
    }
    %orig;
}
%end

%hook SBHomeHardwareButton
- (id)initWithScreenshotGestureRecognizer:(id)arg1 homeButtonType:(long long)arg2 {
    return %orig(arg1,1);
}
%end

%hook SBLockHardwareButtonActions
- (id)initWithHomeButtonType:(long long)arg1 proximitySensorManager:(id)arg2 {
    return %orig(1, arg2);
}
%end

%hook SBClickGestureRecognizer
-(void)addShortcutWithPressTypes:(NSArray *)arg1  {
    return;
}
%end
%end

%group roundedCorners

@interface _UIRootWindow : UIView
@property (setter=_setContinuousCornerRadius:, nonatomic) double _continuousCornerRadius;
@end

%hook _UIRootWindow
-(void)layoutSubviews {
    %orig;

    self.clipsToBounds = YES;
    self._continuousCornerRadius = screenRoundness;
}
%end

%hook SBReachabilityBackgroundView
- (double)_displayCornerRadius {
    return screenRoundness;
}
%end
%end 

// Adds the bottom inset to the screen.
%group InsetX	

CFPropertyListRef (*orig_MGCopyAnswer_internal)();
CFPropertyListRef new_MGCopyAnswer_internal(CFStringRef property) {
    CFPropertyListRef r = orig_MGCopyAnswer_internal();
    NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	#define k(string) CFEqual(property, CFSTR(string))
   if (k("oPeik/9e8lQWMszEjbPzng")) {
        CFMutableDictionaryRef copy = CFDictionaryCreateMutableCopy(NULL, 0, (CFDictionaryRef)r);
        CFRelease(r);
        uint32_t deviceSubType = 0x984;
        CFDictionarySetValue(copy, CFSTR("ArtworkDeviceSubType"), CFNumberCreate(NULL, kCFNumberIntType, &deviceSubType));
        return copy;
    }  else if (k("8olRm6C1xqr7AJGpLRnpSw") && [bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        return (__bridge CFPropertyListRef)@YES;
    }
	return r;
}
%end 

%group bottomInset			
%hook UIApplicationSceneSettings		
- (UIEdgeInsets)safeAreaInsetsLandscapeLeft {		
    UIEdgeInsets _insets = %orig;		
    _insets.bottom = 21;		
    return _insets;		
}		
- (UIEdgeInsets)safeAreaInsetsLandscapeRight {		
    UIEdgeInsets _insets = %orig;		
    _insets.bottom = 21;		
    return _insets;		
}		
- (UIEdgeInsets)safeAreaInsetsPortrait {		
    UIEdgeInsets _insets = %orig;		
    _insets.bottom = 21;
    return _insets;		
}				
%end		
%end


%group MobileGestalt
%hookf(Boolean, "_MGGetBoolAnswer", CFStringRef key) {
#define keyy(key_) CFEqual(key, CFSTR(key_))
    if (keyy("nVh/gwNpy7Jv1NOk00CMrw"))
        return wantsPIP;
    else if (keyy("z5G/N9jcMdgPm8UegLwbKg")) 
        return wantsProudLock;
    return %orig;
}
%end

%group ProudLock
%hook SBUIPasscodeBiometricResource
-(BOOL)hasPearlSupport {
    return YES;
}
-(BOOL)hasMesaSupport {
    return NO;
}
%end
%end

%group iPhone11Cam
%hook CAMCaptureCapabilities 
-(BOOL)isCTMSupported {
    return YES;
}
%end
%hook CAMViewfinderViewController 
-(BOOL)_wantsHDRControlsVisible{
    return NO;
}
%end 
%end

// Adds a bottom inset to the camera app.
%group CameraFix
%hook CAMBottomBar 
- (void)setFrame:(CGRect)frame {
    %orig(CGRectSetY(frame, frame.origin.y -40));
}
%end

%hook CAMZoomControl
- (void)setFrame:(CGRect)frame {
    %orig(CGRectSetY(frame, frame.origin.y -30));
}
%end
%end

%group disableGesturesWhenKeyboard

%hook SBFluidSwitcherGestureManager
-(void)grabberTongueBeganPulling:(id)arg1 withDistance:(double)arg2 andVelocity:(double)arg3  {
    if (!disableGestures)
        %orig;
}
%end
%end

%hook SBFloatingDockController
+ (BOOL)isFloatingDockSupported {
	return wantsiPadDock;
}
%end

%group InstagramFix

@interface IGNavigationBar : UINavigationBar
@end

%hook IGNavigationBar

- (void)layoutSubviews {    
    %orig;
    CGRect _frame = self.frame;
    _frame.origin.y = 20;
    //_frame.size.height = 68; Fixes Instagram bug, but makes format weird
    self.frame = _frame;
    
}
%end
%end

%group TikTokFix
%hookf(int, uname, struct utsname *value) {
	int ret = %orig;
	NSString *utsmachine = @"iPhone10,6";
	if (utsmachine) {	 
		const char *utsnameCh = utsmachine.UTF8String; 
		strcpy(value->machine, utsnameCh);
	}
    return ret;
}
%end


%group YTFix
%hook UIScreen
- (CGRect)bounds {
	CGRect bounds = %orig;
	bounds.size.height = 812;
	return bounds;
}
%end
%end

%group bottominsetfix // AWE = TikTok, TFN = Twitter, YT = Youtube
%hook AWETabBar
- (void)setFrame:(CGRect)frame {
    %orig(CGRectSetY(frame, frame.origin.y + 40));
}
%end

%hook AWEFeedTableView
- (void)setFrame:(CGRect)frame {
	%orig(CGRectMake(frame.origin.x,frame.origin.y,frame.size.width,frame.size.height + 40));
}
%end

%hook TFNNavigationBarOverlayView  
- (void)setFrame:(CGRect)frame {
    %orig(CGRectMake(frame.origin.x,frame.origin.y,frame.size.width,frame.size.height + 6));
}
%end

%hook YTPivotBarView
- (void)setFrame:(CGRect)frame {
    %orig(CGRectSetY(frame, frame.origin.y - 40));
}
%end
%hook YTAppView
- (void)setFrame:(CGRect)frame {
	%orig(CGRectMake(frame.origin.x,frame.origin.y,frame.size.width,frame.size.height + 40));
}
%end
%hook YTNGWatchLayerView
-(CGRect)miniBarFrame{
    CGRect frame = %orig;
	return (CGRectSetY(frame, frame.origin.y - 40));
}
%end
%end 

// Preferences.
void loadPrefs() {
     @autoreleasepool {

        NSString *path = @"/User/Library/Preferences/com.ryannair05.little11prefs.plist";
        NSString *pathDefault = @"/Library/PreferenceBundles/little11prefs.bundle/defaults.plist";
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:path]) {
            [fileManager copyItemAtPath:pathDefault toPath:path error:nil];
        }
        path = @"/System/Library/PrivateFrameworks/CameraUI.framework/CameraUI-d4x-n104.strings";
        pathDefault = @"/Library/PreferenceBundles/little11prefs.bundle/CameraUI-d4x-n104.strings";
        if (![fileManager fileExistsAtPath:path]) {
            [fileManager copyItemAtPath:pathDefault toPath:path error:nil];
        }
        
        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.ryannair05.little11prefs.plist"];
        if (prefs) {
            statusBarStyle = [[prefs objectForKey:@"statusBarStyle"] integerValue];
            screenRoundness = [[prefs objectForKey:@"screenRoundness"] integerValue];
            appswitcherRoundness = [[prefs objectForKey:@"appswitcherRoundness"] integerValue];
            bottomInsetVersion = [[prefs objectForKey:@"bottomInsetVersion"] integerValue];
            wantsHomeBarSB = [[prefs objectForKey:@"homeBarSB"] boolValue];
            wantsHomeBarLS = [[prefs objectForKey:@"homeBarLS"] boolValue];
            wantsKeyboardDock =  [[prefs objectForKey:@"keyboardDock"] boolValue];
            wantsRoundedAppSwitcher =[[prefs objectForKey:@"roundedAppSwitcher"] boolValue];
            wantsReduceRows =  [[prefs objectForKey:@"reduceRows"] boolValue];
            wantsCCGrabber = [[prefs objectForKey:@"ccGrabber"] boolValue];
            wantsBatteryPercent = [[prefs objectForKey:@"batteryPercent"] boolValue];
            wantsGesturesDisabledWhenKeyboard = [[prefs objectForKey:@"noGesturesForKeyboard"] boolValue];
            wantsiPadDock = [[prefs objectForKey:@"iPadDock"] boolValue];
        //  wantsOriginalButtons =  [[prefs objectForKey:@"originalButtons"] boolValue];
            wantsRoundedCorners = [[prefs objectForKey:@"roundedCorners"] boolValue];
            wantsPIP = [[prefs objectForKey:@"PIP"] boolValue];
            wantsProudLock = [[prefs objectForKey:@"ProudLock"] boolValue];
            wantsHideSBCC = [[prefs objectForKey:@"HideSBCC"] boolValue];
            wantsLSShortcuts = [[prefs objectForKey:@"lsShortcutsEnabled"] boolValue];
            wants11Camera = [[prefs objectForKey:@"11Camera"] boolValue];
        }
    }
}

%ctor {
    @autoreleasepool {
	    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.ryannair05.little11prefs/prefsupdated"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	    loadPrefs();
        NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        
        if(statusBarStyle != 0 || bottomInsetVersion == 2) {
            %init(InstagramFix);
        }

        if(statusBarStyle == 1) %init(StatusBariPad)      
	    else if(statusBarStyle == 2) %init(StatusBarX);
        else wantsHideSBCC = YES;
	    
	    if(bottomInsetVersion == 2) {
            MSHookFunction((void *)((const uint8_t *)MSFindSymbol(MSGetImageByName("/usr/lib/libMobileGestalt.dylib"), "_MGCopyAnswer") + 8), (void *)new_MGCopyAnswer_internal, (void **)&orig_MGCopyAnswer_internal);
            %init(InsetX);
        } else if(bottomInsetVersion == 1 || ([bundleIdentifier isEqualToString:@"com.facebook.Facebook"])) %init(bottomInset);
        
        if(!wantsHomeBarLS) {
            %init(hideHomeBarLS);
            if (!wantsHomeBarSB) %init(completelyRemoveHomeBar);
        }

        if(bottomInsetVersion > 0 || statusBarStyle == 2) {
            if([bundleIdentifier isEqualToString:@"com.zhiliaoapp.musically"]) %init(TikTokFix);
            else if ([bundleIdentifier isEqualToString:@"com.google.ios.youtube"]) %init(YTFix);
            if(bottomInsetVersion == 0) %init(bottominsetfix); 
        }

        if(wants11Camera) {
            if ([bundleIdentifier isEqualToString:@"com.apple.camera"])
                %init(iPhone11Cam);
        }
        else if (bottomInsetVersion > 0) %init(CameraFix);

        if(wantsKeyboardDock) %init(KeyboardDock);
        else %init(ForceDefaultKeyboard);

        if (wantsGesturesDisabledWhenKeyboard) {
            [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardDidShowNotification object:nil queue:nil usingBlock:^(NSNotification *n){
                       disableGestures = true;
                    }];
            [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification object:nil queue:nil usingBlock:^(NSNotification *n){
                        disableGestures = false;
                    }];

            %init(disableGesturesWhenKeyboard);
        }
        
        if(wantsRoundedAppSwitcher) %init(roundedDock);
        %init(reduceRows);
        if(wantsCCGrabber) %init(ccGrabber);
      //  if(wantsOriginalButtons) 
        %init(originalButtons);
      //  else %init (xButtons);
        if(wantsRoundedCorners) %init(roundedCorners);
        %init(MobileGestalt);
        if(wantsHideSBCC) %init(HideSBCC);
        if(wantsBatteryPercent) %init(batteryPercent);
        if(wantsProudLock) %init(ProudLock);
        %init(_ungrouped);
    }
}
