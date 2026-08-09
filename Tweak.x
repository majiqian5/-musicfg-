#import <stdlib.h>

__attribute__((constructor))
static void test_initializer() {
    // 如果 dylib 被加载，直接崩溃
    abort();
}
