#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface PLPlatterView : UIView
- (UIView *)contentView;
@end

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    
    if (!self.window) return;
    
    // 直接改 contentView 的背景色
    UIView *contentView = [self contentView];
    contentView.backgroundColor = [UIColor greenColor];
}

%end
