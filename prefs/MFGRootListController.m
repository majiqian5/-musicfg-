#import <Preferences/Preferences.h>

@interface MFGRootListController : PSListController
@end

@implementation MFGRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// 设置导航栏标题
	self.title = @"Yec的灵动岛Pro";
}

- (void)respring {
	// 注销SpringBoard以应用更改
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
	                                                               message:@"需要注销才能生效，是否立即注销？"
	                                                        preferredStyle:UIAlertControllerStyleAlert];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
	[alert addAction:[UIAlertAction actionWithTitle:@"注销" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
		pid_t pid;
		const char *args[] = {"sbreload", NULL};
		posix_spawn(&pid, "/usr/bin/sbreload", NULL, NULL, (char *const *)args, NULL);
	}]];
	
	[self presentViewController:alert animated:YES completion:nil];
}

@end
