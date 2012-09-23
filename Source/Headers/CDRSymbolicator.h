#import <Foundation/Foundation.h>

NSUInteger CDRCallerStackAddress();

@interface CDRSymbolicator : NSObject
- (id)initWithStackAddresses:(NSArray *)addresses;

- (NSString *)fileNameForStackAddress:(NSUInteger)address;
- (NSUInteger)lineNumberForStackAddress:(NSUInteger)address;
@end
