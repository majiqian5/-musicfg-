#import <UIKit/UIKit.h>

@interface PLPlatterView : UIView
@end

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    // 直接给所有 PLPlatterView 都加红色背景
    self.backgroundColor = [UIColor redColor];
}

%end
