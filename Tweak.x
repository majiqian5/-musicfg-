#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface PLPlatterView : UIView
- (UIView *)contentView;
@end

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    
    if (!self.window) return;
    
    // 直接给所有 platter 都加发光效果（先不判断音乐）
    self.layer.cornerRadius = 22;
    self.layer.masksToBounds = NO;
    self.layer.borderWidth = 3;
    self.layer.borderColor = [UIColor redColor].CGColor;
    self.layer.shadowColor = [UIColor redColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.shadowRadius = 20;
    self.layer.shadowOpacity = 1.0;
}

%end
