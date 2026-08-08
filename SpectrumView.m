#import "SpectrumView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface SpectrumView () {
    CADisplayLink *_displayLink;
    CGFloat *_phases;
    CGFloat *_speeds;
    CGFloat *_amplitudes;
}

@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) NSMutableArray *barLayers;

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
        
        _phases = NULL;
        _speeds = NULL;
        _amplitudes = NULL;
        
        [self setupBars];
    }
    return self;
}

- (void)setupBars {
    if (_phases) free(_phases);
    if (_speeds) free(_speeds);
    if (_amplitudes) free(_amplitudes);
    
    _phases = (CGFloat *)malloc(sizeof(CGFloat) * _barCount);
    _speeds = (CGFloat *)malloc(sizeof(CGFloat) * _barCount);
    _amplitudes = (CGFloat *)malloc(sizeof(CGFloat) * _barCount);
    
    for (NSInteger i = 0; i < _barCount; i++) {
        _phases[i] = (CGFloat)arc4random_uniform(100) / 100.0 * M_PI * 2;
        _speeds[i] = 0.02 + (CGFloat)arc4random_uniform(50) / 1000.0;
        _amplitudes[i] = 0.3 + (CGFloat)arc4random_uniform(70) / 100.0;
    }
    
    for (CALayer *layer in self.barLayers) {
        [layer removeFromSuperlayer];
    }
    self.barLayers = [NSMutableArray array];
    
    CGFloat totalWidth = _barCount * _barWidth + (_barCount - 1) * _barSpacing;
    CGFloat startX = (self.bounds.size.width - totalWidth) / 2;
    
    for (NSInteger i = 0; i < _barCount; i++) {
        CALayer *barLayer = [CALayer layer];
        barLayer.frame = CGRectMake(startX + i * (_barWidth + _barSpacing),
                                     self.bounds.size.height / 2,
                                     _barWidth,
                                     0);
        barLayer.cornerRadius = _barWidth / 2;
        barLayer.backgroundColor = [UIColor whiteColor].CGColor;
        [self.layer addSublayer:barLayer];
        [self.barLayers addObject:barLayer];
    }
    
    [self applyGradient];
}

- (void)applyGradient {
    if (!_gradientColors || _gradientColors.count == 0) {
        _gradientColors = @[
            [UIColor colorWithRed:1.0 green:0.4 blue:0.6 alpha:1.0],
            [UIColor colorWithRed:1.0 green:0.7 blue:0.3 alpha:1.0],
            [UIColor colorWithRed:0.5 green:0.9 blue:0.7 alpha:1.0],
            [UIColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1.0],
            [UIColor colorWithRed:0.8 green:0.5 blue:1.0 alpha:1.0]
        ];
    }
    
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = self.bounds;
    
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in _gradientColors) {
        [cgColors addObject:(id)color.CGColor];
    }
    self.gradientLayer.colors = cgColors;
    self.gradientLayer.startPoint = CGPointMake(0, 1);
    self.gradientLayer.endPoint = CGPointMake(0, 0);
    
    CALayer *maskLayer = [CALayer layer];
    for (CALayer *bar in self.barLayers) {
        [maskLayer addSublayer:bar];
    }
    self.gradientLayer.mask = maskLayer;
    
    [self.layer addSublayer:self.gradientLayer];
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
    CGFloat speedFactor = _isPlaying ? 1.0 : 0.1;
    
    for (NSInteger i = 0; i < _barCount; i++) {
        _phases[i] += _speeds[i] * _sensitivity * speedFactor;
        
        CGFloat centerFactor = 1.0 - fabs((CGFloat)i - _barCount/2.0) / (_barCount/2.0);
        centerFactor = 0.3 + centerFactor * 0.7;
        
        CGFloat height = 0;
        height += sin(_phases[i]) * _amplitudes[i] * 0.5;
        height += sin(_phases[i] * 1.5 + 1.0) * _amplitudes[i] * 0.3;
        height += sin(_phases[i] * 0.7 + 2.0) * _amplitudes[i] * 0.2;
        
        height = height * centerFactor * self.bounds.size.height * 0.45;
        height = MAX(2, height);
        
        if (!_isPlaying) {
            CALayer *bar = self.barLayers[i];
            CGFloat currentHeight = bar.bounds.size.height;
            height = currentHeight * 0.95 + height * 0.05;
        }
        
        CALayer *barLayer = self.barLayers[i];
        
        if (_mirrorMode) {
            barLayer.frame = CGRectMake(barLayer.frame.origin.x,
                                         self.bounds.size.height / 2 - height,
                                         _barWidth,
                                         height * 2);
        } else {
            barLayer.frame = CGRectMake(barLayer.frame.origin.x,
                                         self.bounds.size.height - height,
                                         _barWidth,
                                         height);
        }
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

- (void)dealloc {
    [self stopAnimation];
    if (_phases) free(_phases);
    if (_speeds) free(_speeds);
    if (_amplitudes) free(_amplitudes);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
