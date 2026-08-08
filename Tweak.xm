#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#import "SpectrumView.h"
#import "AuroraRingView.h"

static NSString *const kPrefsDomain = @"musicfg";

@interface NSObject (PLPlatterView)
- (UIView *)contentView;
- (UILabel *)titleLabel;
@end

@interface MTMaterialView : UIView
@end

// 频谱视图关联键
static const char *kSpectrumViewKey = "kSpectrumViewKey";
static const char *kAuroraRingViewKey = "kAuroraRingViewKey";
static const char *kDisplayLinkKey = "kDisplayLinkKey";
static const char *kIsPlayingKey = "kIsPlayingKey";

@implementation NSObject (MusicFG)

+ (void)load {
    %orig;
    
    // 监听音乐播放状态
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(musicStateChanged:) 
                                                 name:MPMusicPlayerControllerPlaybackStateDidChangeNotification 
                                               object:nil];
    [[MPMusicPlayerController systemMusicPlayer] beginGeneratingPlaybackNotifications];
}

+ (void)musicStateChanged:(NSNotification *)note {
    // 广播音乐状态变化
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MusicFGPlaybackStateChanged" object:nil];
}

@end

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    
    if (!self.window) return;
    
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kPrefsDomain];
    BOOL enableEffect = [prefs[@"EnableNotificationEffect"] boolValue] ?: YES;
    BOOL enableSpectrum = [prefs[@"EnableSpectrum"] boolValue] ?: YES;
    BOOL enableAurora = [prefs[@"EnableAuroraRing"] boolValue] ?: YES;
    
    if (!enableEffect) return;
    
    // 检查是否是音乐播放器的platter
    BOOL isMusicPlatter = NO;
    UIView *contentView = [self contentView];
    for (UIView *subview in contentView.subviews) {
        if ([NSStringFromClass([subview class]) containsString:@"Music"] ||
            [NSStringFromClass([subview class]) containsString:@"Media"]) {
            isMusicPlatter = YES;
            break;
        }
    }
    
    // 检查标题是否包含音乐相关内容
    UILabel *titleLabel = [self titleLabel];
    if (titleLabel.text.length > 0) {
        // 灵动岛音乐播放器通常有特定的标识
        isMusicPlatter = YES;
    }
    
    if (!isMusicPlatter) {
        // 尝试通过视图层级判断
        UIView *superview = self.superview;
        while (superview) {
            NSString *className = NSStringFromClass([superview class]);
            if ([className containsString:@"Island"] ||
                [className containsString:@"Dynamic"] ||
                [className containsString:@"Music"]) {
                isMusicPlatter = YES;
                break;
            }
            superview = superview.superview;
        }
    }
    
    if (!isMusicPlatter) return;
    
    // 应用基础效果
    [self applyBaseEffects:prefs];
    
    // 添加频谱视图
    if (enableSpectrum) {
        [self addSpectrumViewIfNeeded:prefs];
    }
    
    // 添加灵动光圈
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
    self.layer.borderWidth = borderWidth;
    self.layer.shadowOffset = CGSizeMake(0, shadowOffsetY);
    self.layer.shadowRadius = shadowRadius;
    self.layer.shadowOpacity = 0.8;
    
    // 颜色动画
    NSArray *colors = [self parseColorPresets:prefs[@"ColorPresets"]];
    if (colors.count == 0) {
        colors = @[
            (id)[UIColor redColor].CGColor,
            (id)[UIColor orangeColor].CGColor,
            (id)[UIColor yellowColor].CGColor,
            (id)[UIColor greenColor].CGColor,
            (id)[UIColor cyanColor].CGColor,
            (id)[UIColor blueColor].CGColor,
            (id)[UIColor purpleColor].CGColor
        ];
    }
    
    // 边框颜色动画
    CAKeyframeAnimation *borderAnim = [CAKeyframeAnimation animationWithKeyPath:@"borderColor"];
    borderAnim.values = colors;
    borderAnim.duration = 10.0 / animationSpeed;
    borderAnim.repeatCount = HUGE_VALF;
    borderAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.layer addAnimation:borderAnim forKey:@"borderColorAnimation"];
    
    // 阴影颜色动画
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
    CGFloat barSpacing = [prefs[@"SpectrumBarSpacing"] floatValue] ?: 3;
    BOOL mirrorMode = [prefs[@"SpectrumMirrorMode"] boolValue] ?: YES;
    
    CGRect bounds = self.bounds;
    CGFloat spectrumHeight = 30;
    
    spectrumView = [[SpectrumView alloc] initWithFrame:CGRectMake(0, -spectrumHeight - 5, 
                                                                   bounds.size.width, spectrumHeight)];
    spectrumView.barCount = (NSInteger)barCount;
    spectrumView.sensitivity = sensitivity;
    spectrumView.barWidth = barWidth;
    spectrumView.barSpacing = barSpacing;
    spectrumView.mirrorMode = mirrorMode;
    spectrumView.backgroundColor = [UIColor clearColor];
    
    // 从设置获取颜色
    NSArray *colors = [self parseColorPresets:prefs[@"ColorPresets"]];
    if (colors.count > 0) {
        NSMutableArray *uiColors = [NSMutableArray array];
        for (id cgColor in colors) {
            [uiColors addObject:[UIColor colorWithCGColor:(CGColorRef)cgColor]];
        }
        spectrumView.gradientColors = uiColors;
    }
    
    [self addSubview:spectrumView];
    objc_setAssociatedObject(self, kSpectrumViewKey, spectrumView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 启动动画
    [spectrumView startAnimation];
    
    // 监听音乐状态
    [[NSNotificationCenter defaultCenter] addObserver:spectrumView 
                                             selector:@selector(handlePlaybackStateChange:)
                                                 name:@"MusicFGPlaybackStateChanged" 
                                               object:nil];
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
    CGFloat ringSize = MAX(bounds.size.width, bounds.size.height) + 20;
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
    
    // 从设置获取颜色
    NSArray *colors = [self parseColorPresets:prefs[@"ColorPresets"]];
    if (colors.count > 0) {
        NSMutableArray *uiColors = [NSMutableArray array];
        for (id cgColor in colors) {
            [uiColors addObject:[UIColor colorWithCGColor:(CGColorRef)cgColor]];
        }
        ringView.gradientColors = uiColors;
    }
    
    [self insertSubview:ringView atIndex:0];
    objc_setAssociatedObject(self, kAuroraRingViewKey, ringView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 启动动画
    [ringView startAnimation];
    
    // 监听音乐状态
    [[NSNotificationCenter defaultCenter] addObserver:ringView 
                                             selector:@selector(handlePlaybackStateChange:)
                                                 name:@"MusicFGPlaybackStateChanged" 
                                               object:nil];
}

%end

%hook MTMaterialView

- (void)didMoveToWindow {
    %orig;
    // 材料视图也可以添加效果
}

%end
