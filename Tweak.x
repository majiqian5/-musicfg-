#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#import "SpectrumView.h"
#import "AuroraRingView.h"

static NSString *const kPrefsDomain = @"musicfg";

static const char *kSpectrumViewKey = "kSpectrumViewKey";
static const char *kAuroraRingViewKey = "kAuroraRingViewKey";

@interface PLPlatterView : UIView
- (UIView *)contentView;
- (void)applyBaseEffects:(NSDictionary *)prefs;
- (NSArray *)parseColorPresets:(NSString *)presetStr;
- (void)addSpectrumViewIfNeeded:(NSDictionary *)prefs;
- (void)addAuroraRingViewIfNeeded:(NSDictionary *)prefs;
@end

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    
    if (!self.window) return;
    
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kPrefsDomain];
    BOOL enableEffect = [prefs[@"EnableNotificationEffect"] boolValue] ?: YES;
    
    if (!enableEffect) return;
    
    BOOL isMusicPlatter = NO;
    
    @try {
        UIView *contentView = [self contentView];
        for (UIView *subview in contentView.subviews) {
            NSString *className = NSStringFromClass([subview class]);
            if ([className containsString:@"Music"] ||
                [className containsString:@"Media"] ||
                [className containsString:@"NowPlaying"]) {
                isMusicPlatter = YES;
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
            isMusicPlatter = YES;
            break;
        }
        superview = superview.superview;
        level++;
    }
    
    if (!isMusicPlatter) return;
    
    [self applyBaseEffects:prefs];
    
    BOOL enableSpectrum = [prefs[@"EnableSpectrum"] boolValue] ?: YES;
    if (enableSpectrum) {
        [self addSpectrumViewIfNeeded:prefs];
    }
    
    BOOL enableAurora = [prefs[@"EnableAuroraRing"] boolValue] ?: YES;
    if (enableAurora) {
        [self addAuroraRingViewIfNeeded:prefs];
    }
}

- (void)applyBaseEffects:(NSDictionary *)prefs {
    CGFloat cornerRadius = [prefs[@"CornerRadius"] floatValue] ?: 22;
    CGFloat borderWidth = [prefs[@"NotificationBorderWidth"] floatValue] ?: 2;
    CGFloat shadowOffsetY = [prefs[@"NotificationShadowOffsetY"] floatValue] ?: 3;
    CGFloat shadowRadius = [prefs[@"NotificationShadowRadius"] floatValue] ?: 5;
    CGFloat animationSpeed = [prefs[@"NotificationShadowAnimationSpeed"] floatValue] ?: 3;
    
    self.layer.cornerRadius = cornerRadius;
    self.layer.masksToBounds = NO;
    self.layer.borderWidth = borderWidth;
    self.layer.shadowOffset = CGSizeMake(0, shadowOffsetY);
    self.layer.shadowRadius = shadowRadius;
    self.layer.shadowOpacity = 0.8;
    
    NSArray *colors = [self parseColorPresets:prefs[@"ColorPresets"]];
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
    [self.layer addAnimation:borderAnim forKey:@"borderColorAnimation"];
    
    CAKeyframeAnimation *shadowAnim = [CAKeyframeAnimation animationWithKeyPath:@"shadowColor"];
    shadowAnim.values = colors;
    shadowAnim.duration = 10.0 / animationSpeed;
    shadowAnim.repeatCount = HUGE_VALF;
    shadowAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.layer addAnimation:shadowAnim forKey:@"shadowColorAnimation"];
}

- (NSArray *)parseColorPresets:(NSString *)presetStr {
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

- (void)addSpectrumViewIfNeeded:(NSDictionary *)prefs {
    SpectrumView *spectrumView = objc_getAssociatedObject(self, kSpectrumViewKey);
    if (spectrumView) return;
    
    CGFloat barCount = [prefs[@"SpectrumBarCount"] floatValue] ?: 12;
    CGFloat sensitivity = [prefs[@"SpectrumSensitivity"] floatValue] ?: 0.7;
    CGFloat barWidth = [prefs[@"SpectrumBarWidth"] floatValue] ?: 4;
    BOOL mirrorMode = [prefs[@"SpectrumMirrorMode"] boolValue] ?: YES;
    
    CGRect bounds = self.bounds;
    CGFloat spectrumHeight = 30;
    
    spectrumView = [[SpectrumView alloc] initWithFrame:CGRectMake(0, -spectrumHeight - 5, 
                                                                   bounds.size.width, spectrumHeight)];
    spectrumView.barCount = (NSInteger)barCount;
    spectrumView.sensitivity = sensitivity;
    spectrumView.barWidth = barWidth;
    spectrumView.mirrorMode = mirrorMode;
    spectrumView.backgroundColor = [UIColor clearColor];
    spectrumView.userInteractionEnabled = NO;
    
    [self addSubview:spectrumView];
    objc_setAssociatedObject(self, kSpectrumViewKey, spectrumView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [spectrumView startAnimation];
}

- (void)addAuroraRingViewIfNeeded:(NSDictionary *)prefs {
    AuroraRingView *ringView = objc_getAssociatedObject(self, kAuroraRingViewKey);
    if (ringView) return;
    
    CGFloat ringWidth = [prefs[@"AuroraRingWidth"] floatValue] ?: 3;
    CGFloat glowIntensity = [prefs[@"AuroraGlowIntensity"] floatValue] ?: 0.8;
    CGFloat rotationSpeed = [prefs[@"AuroraRotationSpeed"] floatValue] ?: 1.0;
    CGFloat pulseSpeed = [prefs[@"AuroraPulseSpeed"] floatValue] ?: 1.5;
    NSInteger style = [prefs[@"AuroraStyle"] integerValue] ?: 0;
    
    CGRect bounds = self.bounds;
    CGFloat ringSize = MAX(bounds.size.width, bounds.size.height) + 30;
    CGRect ringFrame = CGRectMake((bounds.size.width - ringSize) / 2, 
                                   (bounds.size.height - ringSize) / 2,
                                   ringSize, ringSize);
    
    ringView = [[AuroraRingView alloc] initWithFrame:ringFrame];
    ringView.ringWidth = ringWidth;
    ringView.glowIntensity = glowIntensity;
    ringView.rotationSpeed = rotationSpeed;
    ringView.pulseSpeed = pulseSpeed;
    ringView.style = style;
    ringView.backgroundColor = [UIColor clearColor];
    ringView.userInteractionEnabled = NO;
    
    [self insertSubview:ringView atIndex:0];
    objc_setAssociatedObject(self, kAuroraRingViewKey, ringView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [ringView startAnimation];
}

%end
