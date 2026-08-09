#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "SpectrumView.h"
#import "AuroraRingView.h"

static const char *kSpectrumViewKey = "kSpectrumViewKey";
static const char *kAuroraRingViewKey = "kAuroraRingViewKey";

@interface PLPlatterView : UIView
- (UIView *)contentView;
- (void)applyBaseEffects:(id)prefs;
@end

%hook PLPlatterView

- (void)applyBaseEffects:(id)prefs {
    %orig;
    
    // 绿色边框，证明生效了
    self.layer.borderWidth = 5;
    self.layer.borderColor = [UIColor greenColor].CGColor;
    
    // 添加频谱
    SpectrumView *spectrumView = objc_getAssociatedObject(self, kSpectrumViewKey);
    if (!spectrumView) {
        CGRect bounds = self.bounds;
        spectrumView = [[SpectrumView alloc] initWithFrame:CGRectMake(0, -35, bounds.size.width, 30)];
        spectrumView.barCount = 12;
        spectrumView.sensitivity = 0.7;
        spectrumView.barWidth = 4;
        spectrumView.mirrorMode = YES;
        spectrumView.userInteractionEnabled = NO;
        [self addSubview:spectrumView];
        objc_setAssociatedObject(self, kSpectrumViewKey, spectrumView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [spectrumView startAnimation];
    }
    
    // 添加光圈
    AuroraRingView *ringView = objc_getAssociatedObject(self, kAuroraRingViewKey);
    if (!ringView) {
        CGRect bounds = self.bounds;
        CGFloat ringSize = MAX(bounds.size.width, bounds.size.height) + 30;
        CGRect ringFrame = CGRectMake((bounds.size.width - ringSize) / 2, 
                                       (bounds.size.height - ringSize) / 2,
                                       ringSize, ringSize);
        ringView = [[AuroraRingView alloc] initWithFrame:ringFrame];
        ringView.ringWidth = 3;
        ringView.glowIntensity = 0.8;
        ringView.rotationSpeed = 1.0;
        ringView.pulseSpeed = 1.5;
        ringView.style = 0;
        ringView.userInteractionEnabled = NO;
        [self insertSubview:ringView atIndex:0];
        objc_setAssociatedObject(self, kAuroraRingViewKey, ringView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [ringView startAnimation];
    }
}

%end
