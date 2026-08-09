#import <UIKit/UIKit.h>

%hook UIView

- (void)layoutSubviews {
    %orig;
    
    Class platterClass = NSClassFromString(@"PLPlatterView");
    if (!platterClass) return;
    if (![self isKindOfClass:platterClass]) return;
    
    // 直接改成绿色，layoutSubviews 每次都调用，绝对不会被覆盖
    self.backgroundColor = [UIColor greenColor];
}

%end
