#import <UIKit/UIKit.h>
#import <objc/runtime.h>

%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = application.windows.firstObject;
        if (window) {
            window.backgroundColor = [UIColor redColor];
        }
    });
    
    return result;
}

%end
