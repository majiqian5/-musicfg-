#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SpectrumView : UIView

@property (nonatomic, assign) NSInteger barCount;        // 频谱条数量
@property (nonatomic, assign) CGFloat sensitivity;       // 灵敏度
@property (nonatomic, assign) CGFloat barWidth;          // 条宽度
@property (nonatomic, assign) CGFloat barSpacing;        // 条间距
@property (nonatomic, assign) BOOL mirrorMode;           // 镜像模式
@property (nonatomic, strong) NSArray *gradientColors;   // 渐变颜色
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL isPlaying;

- (void)startAnimation;
- (void)stopAnimation;
- (void)handlePlaybackStateChange:(NSNotification *)note;

@end
