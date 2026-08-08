#import "SpectrumView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface SpectrumView () {
    CADisplayLink *_displayLink;
    CGFloat _phase;
    NSMutableArray *_barLayers;
    NSMutableArray *_barPhases;
    NSMutableArray *_barSpeeds;
}

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation SpectrumView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _barCount = 12;
        _sensitivity = 0.7;
        _barWidth = 4;
        _barSpacing = 3;
        _mirrorMode = YES;
        _isAnimating = NO;
        _isPlaying = YES;
        _phase = 0;
        _barLayers = [NSMutableArray array];
        _barPhases = [NSMutableArray array];
        _barSpeeds = [NSMutableArray array];
        
        [self setupBars];
    }
    return self;
}

- (void)setupBars {
    // 清除旧的
    for (CALayer *layer in _barLayers) {
        [layer removeFromSuperlayer];
    }
    [_barLayers removeAllObjects];
    [_barPhases removeAllObjects];
    [_barSpeeds removeAllObjects];
    
    CGFloat totalWidth = _barCount * (_barWidth + _barSpacing) - _barSpacing;
    CGFloat startX = (self.bounds.size.width - totalWidth) / 2;
    
    for (NSInteger i = 0; i < _barCount; i++) {
        CGFloat x = startX + i * (_barWidth + _barSpacing);
        CGFloat height = self.bounds.size.height * 0.3;
        CGFloat y = (self.bounds.size.height - height) / 2;
        
        CALayer *barLayer = [CALayer layer];
        barLayer.frame = CGRectMake(x, y, _barWidth, height);
        barLayer.cornerRadius = _barWidth / 2;
        barLayer.backgroundColor = [UIColor whiteColor].CGColor;
        barLayer.opacity = 0.9;
        
        // 添加阴影
        barLayer.shadowColor = [UIColor whiteColor].CGColor;
        barLayer.shadowOffset = CGSizeZero;
        barLayer.shadowRadius = 5;
        barLayer.shadowOpacity = 0.5;
        
        [self.layer addSublayer:barLayer];
        [_barLayers addObject:barLayer];
        
        // 随机相位和速度，让每个条的运动不同步
        [_barPhases addObject:@(arc4random_uniform(100) / 100.0 * M_PI * 2)];
        [_barSpeeds addObject:@(0.8 + (arc4random_uniform(60) / 100.0))];
    }
    
    // 应用渐变
    [self applyGradient];
}

- (void)applyGradient {
    if (!_gradientColors || _gradientColors.count == 0) {
        _gradientColors = @[
            [UIColor colorWithRed:1.0 green:0.4 blue:0.4 alpha:1.0],
            [UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:1.0],
            [UIColor colorWithRed:0.4 green:1.0 blue:0.6 alpha:1.0],
            [UIColor colorWithRed:0.3 green:0.7 blue:1.0 alpha:1.0],
            [UIColor colorWithRed:0.7 green:0.4 blue:1.0 alpha:1.0]
        ];
    }
    
    // 创建渐变遮罩
    _gradientLayer = [CAGradientLayer layer];
    _gradientLayer.frame = self.bounds;
    _gradientLayer.colors = @[
        (id)[UIColor clearColor].CGColor,
        (id)[UIColor whiteColor].CGColor,
        (id)[UIColor whiteColor].CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    _gradientLayer.startPoint = CGPointMake(0, 0);
    _gradientLayer.endPoint = CGPointMake(0, 1);
    
    // 创建颜色渐变层
    CAGradientLayer *colorGradient = [CAGradientLayer layer];
    colorGradient.frame = self.bounds;
    
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in _gradientColors) {
        [cgColors addObject:(id)color.CGColor];
    }
    colorGradient.colors = cgColors;
    colorGradient.startPoint = CGPointMake(0, 0.5);
    colorGradient.endPoint = CGPointMake(1, 0.5);
    
    // 用频谱条作为遮罩
    CALayer *maskLayer = [CALayer layer];
    maskLayer.frame = self.bounds;
    for (CALayer *bar in _barLayers) {
        [maskLayer addSublayer:bar];
    }
    
    colorGradient.mask = maskLayer;
    [self.layer addSublayer:colorGradient];
    
    // 重新设置barLayers引用到mask里的层
    [_barLayers removeAllObjects];
    for (CALayer *sublayer in maskLayer.sublayers) {
        [_barLayers addObject:sublayer];
    }
}

- (void)startAnimation {
    if (_isAnimating) return;
    _isAnimating = YES;
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopAnimation {
    if (!_isAnimating) return;
    _isAnimating = NO;
    
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)update:(CADisplayLink *)displayLink {
    if (!_isPlaying) {
        // 暂停时缓慢回落
        [self decayBars];
        return;
    }
    
    _phase += 0.05 * _sensitivity;
    
    CGFloat midY = self.bounds.size.height / 2;
    CGFloat maxHeight = self.bounds.size.height * 0.9;
    
    for (NSInteger i = 0; i < _barCount; i++) {
        CALayer *barLayer = _barLayers[i];
        CGFloat barPhase = [_barPhases[i] floatValue];
        CGFloat barSpeed = [_barSpeeds[i] floatValue];
        
        // 使用多个正弦波叠加，模拟真实频谱
        CGFloat freq1 = 1.0 + i * 0.15;  // 基础频率
        CGFloat freq2 = 2.3 + i * 0.08;  // 二次谐波
        CGFloat freq3 = 4.7 + i * 0.2;   // 三次谐波
        
        CGFloat value = sin(_phase * freq1 * barSpeed + barPhase) * 0.4;
        value += sin(_phase * freq2 * barSpeed + barPhase * 1.3) * 0.3;
        value += sin(_phase * freq3 * barSpeed + barPhase * 0.7) * 0.2;
        
        // 添加一些随机噪声
        value += (arc4random_uniform(100) / 100.0 - 0.5) * 0.15;
        
        // 归一化到0-1
        value = (value + 1.0) / 2.0;
        value = value * _sensitivity;
        
        // 中间的条更高，两边的低（模拟真实频谱分布）
        CGFloat centerFactor = 1.0 - fabs((CGFloat)i - _barCount / 2.0) / (_barCount / 2.0) * 0.5;
        value *= centerFactor;
        
        // 计算高度
        CGFloat height = maxHeight * MAX(0.1, value);
        
        if (_mirrorMode) {
            // 镜像模式：从中间向上下扩展
            CGFloat y = midY - height / 2;
            barLayer.frame = CGRectMake(barLayer.frame.origin.x, y, _barWidth, height);
        } else {
            // 正常模式：从底部向上
            CGFloat y = self.bounds.size.height - height;
            barLayer.frame = CGRectMake(barLayer.frame.origin.x, y, _barWidth, height);
        }
        
        // 根据高度调整阴影
        barLayer.shadowOpacity = 0.3 + value * 0.5;
        barLayer.shadowRadius = 3 + value * 5;
    }
}

- (void)decayBars {
    CGFloat midY = self.bounds.size.height / 2;
    CGFloat minHeight = self.bounds.size.height * 0.1;
    
    for (NSInteger i = 0; i < _barCount; i++) {
        CALayer *barLayer = _barLayers[i];
        CGFloat currentHeight = barLayer.frame.size.height;
        CGFloat newHeight = currentHeight * 0.95;
        
        if (newHeight < minHeight) newHeight = minHeight;
        
        if (_mirrorMode) {
            CGFloat y = midY - newHeight / 2;
            barLayer.frame = CGRectMake(barLayer.frame.origin.x, y, _barWidth, newHeight);
        } else {
            CGFloat y = self.bounds.size.height - newHeight;
            barLayer.frame = CGRectMake(barLayer.frame.origin.x, y, _barWidth, newHeight);
        }
        
        barLayer.shadowOpacity *= 0.95;
    }
}

- (void)handlePlaybackStateChange:(NSNotification *)note {
    MPMusicPlaybackState state = [MPMusicPlayerController systemMusicPlayer].playbackState;
    _isPlaying = (state == MPMusicPlaybackStatePlaying);
}

- (void)setBarCount:(NSInteger)barCount {
    _barCount = barCount;
    [self setupBars];
}

- (void)setBarWidth:(CGFloat)barWidth {
    _barWidth = barWidth;
    [self setupBars];
}

- (void)setBarSpacing:(CGFloat)barSpacing {
    _barSpacing = barSpacing;
    [self setupBars];
}

- (void)setGradientColors:(NSArray *)gradientColors {
    _gradientColors = gradientColors;
    [self applyGradient];
}

- (void)dealloc {
    [self stopAnimation];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
