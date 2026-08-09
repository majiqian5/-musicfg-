#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#import "SpectrumView.h"
#import "AuroraRingView.h"

static NSString *const kPrefsPath = @"/var/jb/User/Library/Preferences/musicfg.plist";

static const char *kSpectrumViewKey = "kSpectrumViewKey";
static const char *kAuroraRingViewKey = "kAuroraRingViewKey";
static const char *kEffectsAppliedKey = "kEffectsAppliedKey";

@interface PLPlatterView : UIView
@end

@interface MTMaterialView : UIView
@end

// 公共函数：应用效果到指定视图
static void applyEffectsToView(UIView *targetView, UIView *containerView) {
    NSNumber *applied = objc_getAssociatedObject(containerView, kEffectsAppliedKey);
    if (applied && applied.boolValue) return;
    
    // 读取设置
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    if (!prefs) prefs = @{};
    
    BOOL enableEffect = [[prefs objectForKey:@"EnableNotificationEffect"] boolValue] ?: YES;
    if (!enableEffect) return;
    
    // 判断是不是音乐播放器
    BOOL isMusic = NO;
    for (UIView *subview in containerView.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        if ([className containsString:@"Music"] ||
            [className containsString:@"Media"] ||
            [className containsString:@"NowPlaying"]) {
            isMusic = YES;
            break;
        }
    }
    if (!isMusic) {
        UIView *sv = containerView.superview;
        int lvl = 0;
        while (sv && lvl < 10) {
            NSString *className = NSStringFromClass([sv class]);
            if ([className containsString:@"Island"] ||
                [className containsString:@"Dynamic"] ||
                [className containsString:@"Music"]) {
                isMusic = YES;
                break;
            }
            sv = sv.superview;
            lvl++;
        }
    }
    
    // 基础效果参数
    CGFloat cornerRadius = [[prefs objectForKey:@"CornerRadius"] floatValue] ?: 22;
    CGFloat borderWidth = [[prefs objectForKey:@"NotificationBorderWidth"] floatValue] ?: 2;
    CGFloat shadowOffsetY = [[prefs objectForKey:@"NotificationShadowOffsetY"] floatValue] ?: 3;
    CGFloat shadowRadius = [[prefs objectForKey:@"NotificationShadowRadius"] floatValue] ?: 5;
    CGFloat animationSpeed = [[prefs objectForKey:@"NotificationShadowAnimationSpeed"] floatValue] ?: 3;
    
    // 应用基础效果
    targetView.layer.cornerRadius = cornerRadius;
    targetView.layer.masksToBounds = NO;
    targetView.layer.borderWidth = borderWidth;
    targetView.layer.shadowOffset = CGSizeMake(0, shadowOffsetY);
    targetView.layer.shadowRadius = shadowRadius;
    targetView.layer.shadowOpacity = 0.8;
    
    // 解析颜色
    NSString *presetStr = [prefs objectForKey:@"ColorPresets"];
    NSMutableArray *colors = [NSMutableArray array];
    if (presetStr && presetStr.length > 0) {
        NSArray *colorStrings = [presetStr componentsSeparatedByString:@","];
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
    }
    if (colors.count == 0) {
        [colors addObject:(id)[UIColor colorWithRed:1.0 green:0.4 blue:0.6 alpha:1.0].CGColor];
        [colors addObject:(id)[UIColor colorWithRed:1.0 green:0.7 blue:0.3 alpha:1.0].CGColor];
        [colors addObject:(id)[UIColor colorWithRed:0.5 green:0.9 blue:0.7 alpha:1.0].CGColor];
        [colors addObject:(id)[UIColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1.0].CGColor];
        [colors addObject:(id)[UIColor colorWithRed:0.8 green:0.5 blue:1.0 alpha:1.0].CGColor];
    }
    
    // 边框颜色动画
    CAKeyframeAnimation *borderAnim = [CAKeyframeAnimation animationWithKeyPath:@"borderColor"];
    borderAnim.values = colors;
    borderAnim.duration = 10.0 / animationSpeed;
    borderAnim.repeatCount = HUGE_VALF;
    borderAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [targetView.layer addAnimation:borderAnim forKey:@"borderColorAnimation"];
    
    // 阴影颜色动画
    CAKeyframeAnimation *shadowAnim = [CAKeyframeAnimation animationWithKeyPath:@"shadowColor"];
    shadowAnim.values = colors;
    shadowAnim.duration = 10.0 / animationSpeed;
    shadowAnim.repeatCount = HUGE_VALF;
    shadowAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [targetView.layer addAnimation:shadowAnim forKey:@"shadowColorAnimation"];
    
    // 音乐播放器加频谱和光圈
    if (isMusic) {
        BOOL enableSpectrum = [[prefs objectForKey:@"EnableSpectrum"] boolValue] ?: YES;
        if (enableSpectrum) {
            SpectrumView *spectrumView = objc_getAssociatedObject(containerView, kSpectrumViewKey);
            if (!spectrumView) {
                CGRect bounds = containerView.bounds;
                spectrumView = [[SpectrumView alloc] initWithFrame:CGRectMake(0, -35, bounds.size.width, 30)];
                spectrumView.barCount = (NSInteger)([[prefs objectForKey:@"SpectrumBarCount"] floatValue] ?: 12);
                spectrumView.sensitivity = [[prefs objectForKey:@"SpectrumSensitivity"] floatValue] ?: 0.7;
                spectrumView.barWidth = [[prefs objectForKey:@"SpectrumBarWidth"] floatValue] ?: 4;
                spectrumView.mirrorMode = [[prefs objectForKey:@"SpectrumMirrorMode"] boolValue] ?: YES;
                spectrumView.userInteractionEnabled = NO;
                [containerView addSubview:spectrumView];
                objc_setAssociatedObject(containerView, kSpectrumViewKey, spectrumView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [spectrumView startAnimation];
            }
        }
        
        BOOL enableAurora = [[prefs objectForKey:@"EnableAuroraRing"] boolValue] ?: YES;
        if (enableAurora) {
            AuroraRingView *ringView = objc_getAssociatedObject(containerView, kAuroraRingViewKey);
            if (!ringView) {
                CGRect bounds = containerView.bounds;
                CGFloat ringSize = MAX(bounds.size.width, bounds.size.height) + 30;
                CGRect ringFrame = CGRectMake((bounds.size.width - ringSize) / 2, 
                                               (bounds.size.height - ringSize) / 2,
                                               ringSize, ringSize);
                ringView = [[AuroraRingView alloc] initWithFrame:ringFrame];
                ringView.ringWidth = [[prefs objectForKey:@"AuroraRingWidth"] floatValue] ?: 3;
                ringView.glowIntensity = [[prefs objectForKey:@"AuroraGlowIntensity"] floatValue] ?: 0.8;
                ringView.rotationSpeed = [[prefs objectForKey:@"AuroraRotationSpeed"] floatValue] ?: 1.0;
                ringView.pulseSpeed = [[prefs objectForKey:@"AuroraPulseSpeed"] floatValue] ?: 1.5;
                ringView.style = [[prefs objectForKey:@"AuroraStyle"] integerValue] ?: 0;
                ringView.userInteractionEnabled = NO;
                [containerView insertSubview:ringView atIndex:0];
                objc_setAssociatedObject(containerView, kAuroraRingViewKey, ringView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [ringView startAnimation];
            }
        }
    }
    
    objc_setAssociatedObject(containerView, kEffectsAppliedKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// 递归找指定类的子视图
static UIView *findSubviewOfClass(UIView *rootView, Class targetClass) {
    if (!targetClass) return nil;
    
    NSMutableArray *queue = [NSMutableArray arrayWithArray:rootView.subviews];
    while (queue.count > 0) {
        UIView *view = [queue firstObject];
        [queue removeObjectAtIndex:0];
        if ([view isKindOfClass:targetClass]) {
            return view;
        }
        [queue addObjectsFromArray:view.subviews];
    }
    return nil;
}

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    
    Class materialClass = NSClassFromString(@"MTMaterialView");
    UIView *materialView = findSubviewOfClass(self, materialClass);
    
    if (materialView) {
        applyEffectsToView(materialView, self);
    }
}

%end

%hook MTMaterialView

- (void)didMoveToWindow {
    %orig;
    
    Class platterClass = NSClassFromString(@"PLPlatterView");
    UIView *platterView = nil;
    UIView *superview = self.superview;
    int level = 0;
    while (superview && level < 15) {
        if (platterClass && [superview isKindOfClass:platterClass]) {
            platterView = superview;
            break;
        }
        superview = superview.superview;
        level++;
    }
    
    if (platterView) {
        applyEffectsToView(self, platterView);
    }
}

%end
