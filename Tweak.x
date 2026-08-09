#import <UIKit/UIKit.h>
#import <stdlib.h>

@interface PLPlatterView : UIView
@end

%hook PLPlatterView

- (void)didMoveToWindow {
    %orig;
    // 如果 hook 生效，调用这个方法时就会崩溃
    abort();
}

%end
