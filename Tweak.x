#import <UIKit/UIKit.h>

__attribute__((constructor))
static void test_initializer() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *testWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        testWindow.backgroundColor = [UIColor redColor];
        testWindow.windowLevel = UIWindowLevelAlert + 1000;
        testWindow.hidden = NO;
    });
}
