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

// 递归找指定类的子视图
static UIView *findSubviewOfClass(UIView *rootView, Class targetClass) {
    if (!rootView || !targetClass) return nil;
    
    for (UIView *subview in rootView.subviews) {
        if ([subview isKindOfClass:targetClass]) {
            return subview;
        }
        UIView *found = findSubviewOfClass(subview, targetClass);
        if (found) return found;
    }
    return nil;
}

// 判断是不是音乐播放器
static BOOL isMusicPlatter(UIView *platterView) {
    for (UIView *subview in platterView.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        if ([className containsString:@"Music"] ||
            [className containsString:@"Media"] ||
            [className containsString:@"NowPlaying"]) {
            return YES;
        }
    }
    
    UIView *sv = platterView.superview;
    int lvl = 0;
    while (sv && lvl < 10) {
        NSString *className = NSStringFromClass([sv class]);
        if ([className containsString:@"Island"] ||
            [className containsString:@"Dynamic"] ||
            [className containsString:@"Music"]) {
            return YES;
        }
        sv = sv.superview;
        lvl++;
    }
    
    return NO;
}

// 解析颜色
static NSArray *parseColors(NSString *presetStr) {
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

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    
    // 已经应用过就跳过
    NSNumber *applied = objc_getAssociatedObject(self, kEffectsAppliedKey);
    if (applied && applied.boolValue) return;
    
    // 读取设置
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    if (!prefs) prefs = @{};
    
    BOOL enableEffect = [[prefs objectForKey:@"EnableNotificationEffect"] boolValue] ?: YES;
    if (!enableEffect) return;
    
    // 找材质视图
    Class materialClass = NSClassFromString(@"MTMaterialView");
    UIView *targetView = findSubviewOfClass(self, materialClass);
    
    // 找不到材质视图就用自己（兜底）
    if (!targetView) targetView = self;
    
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
    NSArray *colors = parseColors([prefs objectForKey:@"ColorPresets"]);
    if (colors.count == 0) {
        colors = @[
            (id)[UIColor colorWithRed:1.0 green:0.4 blue:0.6 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:1.0 green:0.7 blue:0.3 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.5 green:0.9 blue:0.7 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.8 green:0.5 blue:1.0 alpha:1.0].CGColor
        ];
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
    BOOL isMusic = isMusicPlatter(self);
    if (isMusic) {
        BOOL enableSpectrum = [[prefs objectForKey:@"EnableSpectrum"] boolValue] ?: YES;
        if (enableSpectrum) {
            SpectrumView *spectrumView = objc_getAssociatedObject(self, kSpectrumViewKey);
            if (!spectrumView) {
                CGRect bounds = self.bounds;
                spectrumView = [[SpectrumView alloc] initWithFrame:CGRectMake(0, -35, bounds.size.width, 30)];
                spectrumView.barCount = (NSInteger)([[prefs objectForKey:@"SpectrumBarCount"] floatValue] ?: 12);
                spectrumView.sensitivity = [[prefs objectForKey:@"SpectrumSensitivity"] floatValue] ?: 0.7;
                spectrumView.barWidth = [[prefs objectForKey:@"SpectrumBarWidth"] floatValue] ?: 4;
                spectrumView.mirrorMode = [[prefs objectForKey:@"SpectrumMirrorMode"] boolValue] ?: YES;
                spectrumView.userInteractionEnabled = NO;
                [self addSubview:spectrumView];
                objc_setAssociatedObject(self, kSpectrumViewKey, spectrumView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [spectrumView startAnimation];
            }
        }
        
        BOOL enableAurora = [[prefs objectForKey:@"EnableAuroraRing"] boolValue] ?: YES;
        if (enableAurora) {
            AuroraRingView *ringView = objc_getAssociatedObject(self, kAuroraRingViewKey);
            if (!ringView) {
                CGRect bounds = self.bounds;
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
                [self insertSubview:ringView atIndex:0];
                objc_setAssociatedObject(self, kAuroraRingViewKey, ringView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [ringView startAnimation];
            }
        }
    }
    
    objc_setAssociatedObject(self, kEffectsAppliedKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end
