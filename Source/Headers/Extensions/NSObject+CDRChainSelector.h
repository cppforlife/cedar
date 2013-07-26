#import <Foundation/Foundation.h>

@interface NSObject (CDRChainSelector)
+ (void)cdr_chainSelector:(SEL)selector inClass:(Class)klass prefix:(NSString *)prefix;
@end
