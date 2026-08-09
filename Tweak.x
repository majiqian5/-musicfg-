#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface PLPlatterView : UIView
@end

@implementation UIView (AllGreen)

- (void)makeAllGreen {
    self.backgroundColor = [UIColor greenColor];
    self.layer.borderWidth = 3;
    self.layer.borderColor = [UIColor redColor].CGColor;
    for (UIView *subview in self.subviews) {
        [subview makeAllGreen];
    }
}

@end

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    // 不加任何判断，直接把自己和所有子视图全部改成绿色
    [self makeAllGreen];
}

%end
