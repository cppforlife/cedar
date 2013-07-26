#import "NSObject+CDRChainSelector.h"
#import <objc/runtime.h>

#define F(f, ...) [NSString stringWithFormat:f, ##__VA_ARGS__]

@implementation NSObject (CDRChainSelector)

// Based on http://blog.walkingsmarts.com/objective-c-method-swizzling-rails-style-a-k-a-alias-method-chain/
+ (void)cdr_chainSelector:(SEL)selector inClass:(Class)klass prefix:(NSString *)prefix {
    NSString *selectorStr = NSStringFromSelector(selector);
    Method method = class_getInstanceMethod(klass, selector);

    // alias without* -> original
    SEL withoutSel = sel_registerName([F(@"without%@_%@", prefix, selectorStr) UTF8String]);
    class_addMethod(klass, withoutSel, method_getImplementation(method), method_getTypeEncoding(method));

    // alias original -> with*
    SEL withSel = sel_registerName([F(@"with%@_%@", prefix, selectorStr) UTF8String]);
    method_setImplementation(method, [self instanceMethodForSelector:withSel]);
}
@end
