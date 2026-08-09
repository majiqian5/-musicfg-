#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "SpectrumView.h"
#import "AuroraRingView.h"

static const char *kSpectrumViewKey = "kSpectrumViewKey";
static const char *kAuroraRingViewKey = "kAuroraRingViewKey";

@interface PLPlatterView : UIView
- (UIView *)contentView;
- (void)applyBaseEffects;
- (void)addSpectrumViewIfNeeded;
- (void)addAuroraRingViewIfNeeded;
@end

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    
    if (!self.window) return;
    
    // 先不加判断，所有 platter 都加效果，验证是否生效
    [self applyBaseEffects];
    [self addSpectrumViewIfNeeded];
    [self addAuroraRingViewIfNeeded];
}

- (void)applyBaseEffects {
    self.layer.cornerRadius = 22;
    self.layer.masksToBounds = NO;
    self.layer.borderWidth = 2;
    self.layer.shadowOffset = CGSizeMake(0, 3);
    self.layer.shadowRadius = 5;
    self.layer.shadowOpacity = 0.8;
    
    NSArray *colors = @[
        (id)[UIColor colorWithRed:1.0 green:0.4 blue:0.6 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:1.0 green:0.7 blue:0.3 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.5 green:0.9 blue:0.7 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.8 green:0.5 blue:1.0 alpha:1.0].CGColor
    ];
    
    CAKeyframeAnimation *borderAnim = [CAKeyframeAnimation animationWithKeyPath:@"borderColor"];
    borderAnim.values = colors;
    borderAnim.duration = 10.0 / 3.0;
    borderAnim.repeatCount = HUGE_VALF;
    borderAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.layer addAnimation:borderAnim forKey:@"borderColorAnimation"];
    
    CAKeyframeAnimation *shadowAnim = [CAKeyframeAnimation animationWithKeyPath:@"shadowColor"];
    shadowAnim.values = colors;
    shadowAnim.duration = 10.0 / 3.0;
    shadowAnim.repeatCount = HUGE_VALF;
    shadowAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.layer addAnimation:shadowAnim forKey:@"shadowColorAnimation"];
}

- (void)addSpectrumViewIfNeeded {
    SpectrumView *spectrumView = objc_getAssociatedObject(self, kSpectrumViewKey);
    if (spectrumView) return;
    
    CGRect bounds = self.bounds;
    CGFloat spectrumHeight = 30;
    
    spectrumView = [[SpectrumView alloc] initWithFrame:CGRectMake(0, -spectrumHeight - 5, 
                                                                   bounds.size.width, spectrumHeight)];
    spectrumView.barCount = 12;
    spectrumView.sensitivity = 0.7;
    spectrumView.barWidth = 4;
    spectrumView.mirrorMode = YES;
    spectrumView.backgroundColor = [UIColor clearColor];
    spectrumView.userInteractionEnabled = NO;
    
    [self addSubview:spectrumView];
    objc_setAssociatedObject(self, kSpectrumViewKey, spectrumView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [spectrumView startAnimation];
}

- (void)addAuroraRingViewIfNeeded {
    AuroraRingView *ringView = objc_getAssociatedObject(self, kAuroraRingViewKey);
    if (ringView) return;
    
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
    ringView.backgroundColor = [UIColor clearColor];
    ringView.userInteractionEnabled = NO;
    
    [self insertSubview:ringView atIndex:0];
    objc_setAssociatedObject(self, kAuroraRingViewKey, ringView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [ringView startAnimation];
}

%end
