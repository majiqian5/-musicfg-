#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface PLPlatterView : UIView
@end

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    
    if (!self.window) return;
    
    // 遍历子视图，找到材质视图 MTMaterialView
    for (UIView *subview in self.subviews) {
        if ([NSStringFromClass([subview class]) containsString:@"Material"]) {
            // 找到材质视图了，改成绿色背景 + 红色边框
            subview.backgroundColor = [UIColor greenColor];
            subview.layer.borderWidth = 5;
            subview.layer.borderColor = [UIColor redColor].CGColor;
            subview.layer.shadowColor = [UIColor redColor].CGColor;
            subview.layer.shadowOffset = CGSizeZero;
            subview.layer.shadowRadius = 20;
            subview.layer.shadowOpacity = 1.0;
            subview.layer.masksToBounds = NO;
        }
    }
}

%end
