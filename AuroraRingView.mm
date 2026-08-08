#import "AuroraRingView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface AuroraRingView () {
    CADisplayLink *_displayLink;
    CGFloat _phase;
    CGFloat _rotationAngle;
}

@property (nonatomic, strong) CAGradientLayer *gradientRingLayer;
@property (nonatomic, strong) CAReplicatorLayer *replicatorLayer;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;

@end

@implementation AuroraRingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _ringWidth = 3;
        _glowIntensity = 0.8;
        _rotationSpeed = 1.0;
        _pulseSpeed = 1.5;
        _style = 0;
        _isAnimating = NO;
        _isPlaying = YES;
        _phase = 0;
        _rotationAngle = 0;
        
        [self setupRing];
    }
    return self;
}

- (void)setupRing {
    // 清除旧的
    for (CALayer *layer in self.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    
    if (!_gradientColors || _gradientColors.count == 0) {
        _gradientColors = @[
            [UIColor colorWithRed:1.0 green:0.4 blue:0.6 alpha:1.0],
            [UIColor colorWithRed:1.0 green:0.7 blue:0.3 alpha:1.0],
            [UIColor colorWithRed:0.5 green:0.9 blue:0.7 alpha:1.0],
            [UIColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1.0],
            [UIColor colorWithRed:0.8 green:0.5 blue:1.0 alpha:1.0],
            [UIColor colorWithRed:1.0 green:0.4 blue:0.6 alpha:1.0]
        ];
    }
    
    CGRect bounds = self.bounds;
    CGPoint center = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);
    CGFloat radius = MIN(bounds.size.width, bounds.size.height) / 2 - _ringWidth;
    
    // 创建圆形路径
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center
                                                             radius:radius
                                                         startAngle:0
                                                           endAngle:M_PI * 2
                                                          clockwise:YES];
    
    switch (_style) {
        case 0: // 渐变旋转
            [self setupGradientRotationStyleWithPath:circlePath radius:radius center:center];
            break;
        case 1: // 呼吸脉冲
            [self setupPulseStyleWithPath:circlePath radius:radius center:center];
            break;
        case 2: // 双色追逐
            [self setupChaseStyleWithPath:circlePath radius:radius center:center];
            break;
        case 3: // 星光闪烁
            [self setupSparkleStyleWithPath:circlePath radius:radius center:center];
            break;
        default:
            [self setupGradientRotationStyleWithPath:circlePath radius:radius center:center];
            break;
    }
}

- (void)setupGradientRotationStyleWithPath:(UIBezierPath *)circlePath 
                                     radius:(CGFloat)radius 
                                     center:(CGPoint)center {
    // 创建渐变层
    _gradientRingLayer = [CAGradientLayer layer];
    _gradientRingLayer.frame = self.bounds;
    
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in _gradientColors) {
        [cgColors addObject:(id)color.CGColor];
    }
    _gradientRingLayer.colors = cgColors;
    _gradientRingLayer.startPoint = CGPointMake(0, 0);
    _gradientRingLayer.endPoint = CGPointMake(1, 1);
    _gradientRingLayer.type = kCAGradientLayerConic;
    
    // 创建形状层作为遮罩
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = circlePath.CGPath;
    maskLayer.fillColor = [UIColor clearColor].CGColor;
    maskLayer.strokeColor = [UIColor whiteColor].CGColor;
    maskLayer.lineWidth = _ringWidth;
    maskLayer.lineCap = kCALineCapRound;
    
    _gradientRingLayer.mask = maskLayer;
    
    // 添加发光效果
    _gradientRingLayer.shadowColor = ((UIColor *)_gradientColors.firstObject).CGColor;
    _gradientRingLayer.shadowOffset = CGSizeZero;
    _gradientRingLayer.shadowRadius = 15 * _glowIntensity;
    _gradientRingLayer.shadowOpacity = _glowIntensity;
    
    [self.layer addSublayer:_gradientRingLayer];
}

- (void)setupPulseStyleWithPath:(UIBezierPath *)circlePath 
                          radius:(CGFloat)radius 
                          center:(CGPoint)center {
    // 创建形状层
    _shapeLayer = [CAShapeLayer layer];
    _shapeLayer.path = circlePath.CGPath;
    _shapeLayer.fillColor = [UIColor clearColor].CGColor;
    _shapeLayer.strokeColor = ((UIColor *)_gradientColors.firstObject).CGColor;
    _shapeLayer.lineWidth = _ringWidth;
    _shapeLayer.lineCap = kCALineCapRound;
    
    // 发光
    _shapeLayer.shadowColor = ((UIColor *)_gradientColors.firstObject).CGColor;
    _shapeLayer.shadowOffset = CGSizeZero;
    _shapeLayer.shadowRadius = 10 * _glowIntensity;
    _shapeLayer.shadowOpacity = _glowIntensity;
    
    [self.layer addSublayer:_shapeLayer];
    
    // 外层脉冲圈
    CAShapeLayer *pulseLayer = [CAShapeLayer layer];
    pulseLayer.path = circlePath.CGPath;
    pulseLayer.fillColor = [UIColor clearColor].CGColor;
    pulseLayer.strokeColor = ((UIColor *)_gradientColors.firstObject).CGColor;
    pulseLayer.lineWidth = _ringWidth * 0.5;
    pulseLayer.opacity = 0.5;
    pulseLayer.name = @"pulseLayer";
    
    pulseLayer.shadowColor = ((UIColor *)_gradientColors.firstObject).CGColor;
    pulseLayer.shadowOffset = CGSizeZero;
    pulseLayer.shadowRadius = 8 * _glowIntensity;
    pulseLayer.shadowOpacity = _glowIntensity * 0.5;
    
    [self.layer addSublayer:pulseLayer];
}

- (void)setupChaseStyleWithPath:(UIBezierPath *)circlePath 
                          radius:(CGFloat)radius 
                          center:(CGPoint)center {
    // 创建两个追逐的弧
    UIColor *color1 = _gradientColors.firstObject;
    UIColor *color2 = _gradientColors.count > 1 ? _gradientColors[1] : _gradientColors.firstObject;
    
    // 第一个弧
    CAShapeLayer *arc1 = [CAShapeLayer layer];
    UIBezierPath *arcPath1 = [UIBezierPath bezierPathWithArcCenter:center
                                                            radius:radius
                                                        startAngle:-M_PI_2
                                                          endAngle:-M_PI_2 + M_PI_4
                                                         clockwise:YES];
    arc1.path = arcPath1.CGPath;
    arc1.fillColor = [UIColor clearColor].CGColor;
    arc1.strokeColor = color1.CGColor;
    arc1.lineWidth = _ringWidth;
    arc1.lineCap = kCALineCapRound;
    arc1.name = @"arc1";
    
    arc1.shadowColor = color1.CGColor;
    arc1.shadowOffset = CGSizeZero;
    arc1.shadowRadius = 12 * _glowIntensity;
    arc1.shadowOpacity = _glowIntensity;
    
    [self.layer addSublayer:arc1];
    
    // 第二个弧
    CAShapeLayer *arc2 = [CAShapeLayer layer];
    UIBezierPath *arcPath2 = [UIBezierPath bezierPathWithArcCenter:center
                                                            radius:radius
                                                        startAngle:M_PI_2
                                                          endAngle:M_PI_2 + M_PI_4
                                                         clockwise:YES];
    arc2.path = arcPath2.CGPath;
    arc2.fillColor = [UIColor clearColor].CGColor;
    arc2.strokeColor = color2.CGColor;
    arc2.lineWidth = _ringWidth;
    arc2.lineCap = kCALineCapRound;
    arc2.name = @"arc2";
    
    arc2.shadowColor = color2.CGColor;
    arc2.shadowOffset = CGSizeZero;
    arc2.shadowRadius = 12 * _glowIntensity;
    arc2.shadowOpacity = _glowIntensity;
    
    [self.layer addSublayer:arc2];
}

- (void)setupSparkleStyleWithPath:(UIBezierPath *)circlePath 
                            radius:(CGFloat)radius 
                            center:(CGPoint)center {
    // 基础圆环
    CAShapeLayer *baseRing = [CAShapeLayer layer];
    baseRing.path = circlePath.CGPath;
    baseRing.fillColor = [UIColor clearColor].CGColor;
    baseRing.strokeColor = ((UIColor *)_gradientColors.firstObject).CGColor;
    baseRing.lineWidth = _ringWidth * 0.5;
    baseRing.opacity = 0.3;
    
    [self.layer addSublayer:baseRing];
    
    // 星光点
    NSInteger sparkCount = 8;
    for (NSInteger i = 0; i < sparkCount; i++) {
        CGFloat angle = (CGFloat)i / sparkCount * M_PI * 2;
        CGFloat x = center.x + radius * cos(angle);
        CGFloat y = center.y + radius * sin(angle);
        
        CALayer *spark = [CALayer layer];
        spark.bounds = CGRectMake(0, 0, _ringWidth * 2, _ringWidth * 2);
        spark.position = CGPointMake(x, y);
        spark.cornerRadius = _ringWidth;
        spark.backgroundColor = ((UIColor *)_gradientColors[i % _gradientColors.count]).CGColor;
        spark.name = [NSString stringWithFormat:@"spark_%ld", (long)i];
        
        spark.shadowColor = ((UIColor *)_gradientColors[i % _gradientColors.count]).CGColor;
        spark.shadowOffset = CGSizeZero;
        spark.shadowRadius = 8 * _glowIntensity;
        spark.shadowOpacity = _glowIntensity;
        
        [self.layer addSublayer:spark];
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
    CGFloat speedFactor = _isPlaying ? 1.0 : 0.2;
    _phase += 0.02 * _pulseSpeed * speedFactor;
    _rotationAngle += 0.01 * _rotationSpeed * speedFactor;
    
    switch (_style) {
        case 0:
            [self updateGradientRotation];
            break;
        case 1:
            [self updatePulse];
            break;
        case 2:
            [self updateChase];
            break;
        case 3:
            [self updateSparkle];
            break;
        default:
            break;
    }
}

- (void)updateGradientRotation {
    // 旋转渐变
    _gradientRingLayer.transform = CATransform3DMakeRotation(_rotationAngle, 0, 0, 1);
    
    // 呼吸效果
    CGFloat pulse = 0.8 + 0.2 * sin(_phase);
    _gradientRingLayer.shadowOpacity = _glowIntensity * pulse;
    _gradientRingLayer.shadowRadius = 15 * _glowIntensity * pulse;
}

- (void)updatePulse {
    CGFloat pulse = 0.7 + 0.3 * sin(_phase);
    _shapeLayer.opacity = pulse;
    _shapeLayer.shadowOpacity = _glowIntensity * pulse;
    
    // 外层脉冲圈扩散
    CALayer *pulseLayer = [self.layer.sublayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == 'pulseLayer'"]].firstObject;
    if (pulseLayer) {
        CGFloat expand = 1 + 0.1 * sin(_phase);
        pulseLayer.transform = CATransform3DMakeScale(expand, expand, 1);
        pulseLayer.opacity = 0.5 * (1 - (sin(_phase) + 1) / 2 * 0.7);
    }
}

- (void)updateChase {
    CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) / 2 - _ringWidth;
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    
    // 两个弧追逐
    CGFloat arcLength = M_PI_4;
    CGFloat angle1 = _rotationAngle * 2;
    CGFloat angle2 = _rotationAngle * 2 + M_PI; // 相差180度
    
    CAShapeLayer *arc1 = (CAShapeLayer *)[self.layer.sublayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == 'arc1'"]].firstObject;
    CAShapeLayer *arc2 = (CAShapeLayer *)[self.layer.sublayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == 'arc2'"]].firstObject;
    
    if (arc1 && arc2) {
        UIBezierPath *path1 = [UIBezierPath bezierPathWithArcCenter:center
                                                             radius:radius
                                                         startAngle:angle1
                                                           endAngle:angle1 + arcLength
                                                          clockwise:YES];
        arc1.path = path1.CGPath;
        
        UIBezierPath *path2 = [UIBezierPath bezierPathWithArcCenter:center
                                                             radius:radius
                                                         startAngle:angle2
                                                           endAngle:angle2 + arcLength
                                                          clockwise:YES];
        arc2.path = path2.CGPath;
        
        // 亮度变化
        CGFloat brightness = 0.7 + 0.3 * sin(_phase * 2);
        arc1.opacity = brightness;
        arc2.opacity = 1 - brightness * 0.5;
    }
}

- (void)updateSparkle {
    NSInteger sparkCount = 8;
    for (NSInteger i = 0; i < sparkCount; i++) {
        NSString *sparkName = [NSString stringWithFormat:@"spark_%ld", (long)i];
        CALayer *spark = [self.layer.sublayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", sparkName]].firstObject;
        
        if (spark) {
            // 每个星光点有不同的闪烁相位
            CGFloat phaseOffset = (CGFloat)i / sparkCount * M_PI * 2;
            CGFloat brightness = 0.4 + 0.6 * sin(_phase * 3 + phaseOffset);
            spark.opacity = brightness;
            spark.shadowOpacity = _glowIntensity * brightness;
            
            // 大小变化
            CGFloat scale = 0.8 + 0.4 * sin(_phase * 2 + phaseOffset);
            spark.transform = CATransform3DMakeScale(scale, scale, 1);
        }
    }
}

- (void)handlePlaybackStateChange:(NSNotification *)note {
    MPMusicPlaybackState state = [MPMusicPlayerController systemMusicPlayer].playbackState;
    _isPlaying = (state == MPMusicPlaybackStatePlaying);
}

- (void)setStyle:(NSInteger)style {
    _style = style;
    [self setupRing];
}

- (void)setGradientColors:(NSArray *)gradientColors {
    _gradientColors = gradientColors;
    [self setupRing];
}

- (void)setRingWidth:(CGFloat)ringWidth {
    _ringWidth = ringWidth;
    [self setupRing];
}

- (void)dealloc {
    [self stopAnimation];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
