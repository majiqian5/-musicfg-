#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#import "SpectrumView.h"
#import "AuroraRingView.h"

static const char *kSpectrumViewKey = "kSpectrumViewKey";
static const char *kAuroraRingViewKey = "kAuroraRingViewKey";
static const char *kEffectsAppliedKey = "kEffectsAppliedKey";

static NSString *const kPrefsPath = @"/var/jb/User/Library/Preferences/musicfg.plist";

@interface PLPlatterView : UIView
@end

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    
    NSNumber *applied = objc_getAssociatedObject(self, kEffectsAppliedKey);
    if (applied && applied.boolValue) return;
    
    // 判断是不是音乐播放器
    BOOL isMusic = NO;
    for (UIView *subview in self.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        if ([className containsString:@"Music"] ||
            [className containsString:@"Media"] ||
            [className containsString:@"NowPlaying"]) {
            isMusic = YES;
            break;
        }
    }
    if (!isMusic) {
        UIView *sv = self.superview;
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
    
    if (!isMusic) return;
    
    // 读取设置
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    if (!prefs) prefs = @{};
    
    // 频谱
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
    
    // 光圈
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
    
    objc_setAssociatedObject(self, kEffectsAppliedKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end
