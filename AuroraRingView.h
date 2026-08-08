#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface AuroraRingView : UIView

@property (nonatomic, assign) CGFloat ringWidth;          // 光圈宽度
@property (nonatomic, assign) CGFloat glowIntensity;      // 发光强度
@property (nonatomic, assign) CGFloat rotationSpeed;      // 旋转速度
@property (nonatomic, assign) CGFloat pulseSpeed;         // 脉动速度
@property (nonatomic, assign) NSInteger style;            // 样式：0-渐变旋转 1-呼吸脉冲 2-双色追逐 3-星光闪烁
@property (nonatomic, strong) NSArray *gradientColors;    // 渐变颜色
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL isPlaying;

- (void)startAnimation;
- (void)stopAnimation;
- (void)handlePlaybackStateChange:(NSNotification *)note;

@end
