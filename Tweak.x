#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#import "SpectrumView.h"
#import "AuroraRingView.h"

static NSString *const kPrefsDomain = @"musicfg";

static const char *kSpectrumViewKey = "kSpectrumViewKey";
static const char *kAuroraRingViewKey = "kAuroraRingViewKey";
static const char *kEffectsAppliedKey = "kEffectsAppliedKey";

@interface PLPlatterView : UIView
- (UIView *)contentView;
@end

@implementation UIView (MusicFG)

- (UIView *)findMaterialView {
    if ([NSStringFromClass([self class]) containsString:@"Material"]) {
        return self;
    }
    for (UIView *subview in self.subviews) {
        UIView *found = [subview findMaterialView];
        if (found) return found;
    }
    return nil;
}

- (BOOL)isMusicPlatter {
    BOOL isMusic = NO;
    
    @try {
        for (UIView *subview in self.subviews) {
            NSString *className = NSStringFromClass([subview class]);
            if ([className containsString:@"Music"] ||
                [className containsString:@"Media"] ||
                [className containsString:@"NowPlaying"]) {
                isMusic = YES;
                break;
            }
        }
    } @catch (NSException *e) {}
    
    UIView *superview = self.superview;
    NSInteger level = 0;
    while (superview && level < 10) {
        NSString *className = NSStringFromClass([superview class]);
        if ([className containsString:@"Island"] ||
            [className containsString:@"Dynamic"] ||
            [className containsString:@"Music"]) {
            isMusic = YES;
            break;
        }
        superview = superview.superview;
        level++;
    }
    
    return isMusic;
}

- (NSArray *)parseColors:(NSString *)presetStr {
    if (!presetStr || presetStr.length == 0) return @[];
    
    NSArray *colorStrings = [presetStr componentsSeparatedByString:@","];
    NSMutableArray *colors = [NSMutableArray array];
    
    for (NSString *colorStr in colorStrings) {
        NSString *trimmed = [colorStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (trimmed.length == 7 && [trimmed hasPrefix:@"#"]) {
            unsigned int rgbValue = 0;
            NSScanner *scanner = [NSScanner scannerWithString:[trimmed substringFromIndex:1]];
            [scanner scanHexInt:&rgbValue];
            
            UIColor *color = [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0
                                             green:((rgbValue & 0x00FF00) >> 8)/255.0
                                              blue:(rgbValue & 0x0000FF)/255.0
                                             alpha:1.0];
            [colors addObject:(id)color.CGColor];
        }
    }
    
    return colors;
}

@end

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    
    if (!self.window) return;
    
    NSNumber *applied = objc_getAssociatedObject(self, kEffectsAppliedKey);
    if (applied && applied.boolValue) return;
    
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kPrefsDomain];
    BOOL enableEffect = [prefs[@"EnableNotificationEffect"] boolValue] ?: YES;
    
    if (!enableEffect) return;
    
    BOOL isMusic = [self isMusicPlatter];
    
    UIView *materialView = [self findMaterialView];
    UIView *targetView = materialView ? materialView : self;
    
    CGFloat cornerRadius = [prefs[@"CornerRadius"] floatValue] ?: 22;
    CGFloat borderWidth = [prefs[@"NotificationBorderWidth"] floatValue] ?: 2;
    CGFloat shadowOffsetY = [prefs[@"NotificationShadowOffsetY"] floatValue] ?: 3;
    CGFloat shadowRadius = [prefs[@"NotificationShadowRadius"] floatValue] ?: 5;
    CGFloat animationSpeed = [prefs[@"NotificationShadowAnimationSpeed"] floatValue] ?: 3;
    
    targetView.layer.cornerRadius = cornerRadius;
    targetView.layer.masksToBounds = NO;
    targetView.layer.borderWidth = borderWidth;
    targetView.layer.shadowOffset = CGSizeMake(0, shadowOffsetY);
    targetView.layer.shadowRadius = shadowRadius;
    targetView.layer.shadowOpacity = 0.8;
    
    NSArray *colors = [self parseColors:prefs[@"ColorPresets"]];
    if (colors.count == 0) {
        colors = @[
            (id)[UIColor colorWithRed:1.0 green:0.4 blue:0.6 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:1.0 green:0.7 blue:0.3 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.5 green:0.9 blue:0.7 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.8 green:0.5 blue:1.0 alpha:1.0].CGColor
        ];
    }
    
    CAKeyframeAnimation *borderAnim = [CAKeyframeAnimation animationWithKeyPath:@"borderColor"];
    borderAnim.values = colors;
    borderAnim.duration = 10.0 / animationSpeed;
    borderAnim.repeatCount = HUGE_VALF;
    borderAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [targetView.layer addAnimation:borderAnim forKey:@"borderColorAnimation"];
    
    CAKeyframeAnimation *shadowAnim = [CAKeyframeAnimation animationWithKeyPath:@"shadowColor"];
    shadowAnim.values = colors;
    shadowAnim.duration = 10.0 / animationSpeed;
    shadowAnim.repeatCount = HUGE_VALF;
    shadowAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [targetView.layer addAnimation:shadowAnim forKey:@"shadowColorAnimation"];
    
    // 音乐播放器才加频谱和光圈
    if (isMusic) {
        BOOL enableSpectrum = [prefs[@"EnableSpectrum"] boolValue] ?: YES;
        if (enableSpectrum) {
            SpectrumView *spectrumView = objc_getAssociatedObject(self, kSpectrumViewKey);
            if (!spectrumView) {
                CGRect bounds = self.bounds;
                spectrumView = [[SpectrumView alloc] initWithFrame:CGRectMake(0, -35, bounds.size.width, 30)];
                spectrumView.barCount = (NSInteger)([prefs[@"SpectrumBarCount"] floatValue] ?: 12);
                spectrumView.sensitivity = [prefs[@"SpectrumSensitivity"] floatValue] ?: 0.7;
                spectrumView.barWidth = [prefs[@"SpectrumBarWidth"] floatValue] ?: 4;
                spectrumView.mirrorMode = [prefs[@"SpectrumMirrorMode"] boolValue] ?: YES;
                spectrumView.userInteractionEnabled = NO;
                [self addSubview:spectrumView];
                objc_setAssociatedObject(self, kSpectrumViewKey, spectrumView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [spectrumView startAnimation];
            }
        }
        
        BOOL enableAurora = [prefs[@"EnableAuroraRing"] boolValue] ?: YES;
        if (enableAurora) {
            AuroraRingView *ringView = objc_getAssociatedObject(self, kAuroraRingViewKey);
            if (!ringView) {
                CGRect bounds = self.bounds;
                CGFloat ringSize = MAX(bounds.size.width, bounds.size.height) + 30;
                CGRect ringFrame = CGRectMake((bounds.size.width - ringSize) / 2, 
                                               (bounds.size.height - ringSize) / 2,
                                               ringSize, ringSize);
                ringView = [[AuroraRingView alloc] initWithFrame:ringFrame];
                ringView.ringWidth = [prefs[@"AuroraRingWidth"] floatValue] ?: 3;
                ringView.glowIntensity = [prefs[@"AuroraGlowIntensity"] floatValue] ?: 0.8;
                ringView.rotationSpeed = [prefs[@"AuroraRotationSpeed"] floatValue] ?: 1.0;
                ringView.pulseSpeed = [prefs[@"AuroraPulseSpeed"] floatValue] ?: 1.5;
                ringView.style = [prefs[@"AuroraStyle"] integerValue] ?: 0;
                ringView.userInteractionEnabled = NO;
                [self insertSubview:ringView atIndex:0];
                objc_setAssociatedObject(self, kAuroraRingViewKey, ringView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [ringView startAnimation];
            }
        }
    }
    
    objc_setAssociatedObject(self, kEffectsAppliedKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end
