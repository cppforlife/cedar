#import <Foundation/Foundation.h>

@protocol CDRExampleReporter <NSObject>

- (void)runWillStartWithGroups:(NSArray *)groups onlyFocused:(BOOL)onlyFocused;
- (void)runDidComplete;
- (int)result;

@end
