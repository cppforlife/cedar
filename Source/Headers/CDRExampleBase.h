#import <Foundation/Foundation.h>
#import "CDRExampleParent.h"

@protocol CDRExampleReporter;

typedef void (^CDRSpecBlock)(void);

enum CDRExampleState {
    CDRExampleStateIncomplete = 0x00,
    CDRExampleStatePassed = 0x01,
    CDRExampleStatePending = 0x03,
    CDRExampleStateSkipped = 0x05,
    CDRExampleStateFailed = 0x07,
    CDRExampleStateError = 0x0F
};
typedef enum CDRExampleState CDRExampleState;

@interface CDRExampleBase : NSObject {
  NSString *text_;
  id<CDRExampleParent> parent_;
  BOOL focused_;
}

@property (nonatomic, readonly) NSString *text;
@property (nonatomic, assign) id<CDRExampleParent> parent;
@property (nonatomic, assign, getter=isFocused) BOOL focused;

- (id)initWithText:(NSString *)text;

- (void)runOnlyFocused:(BOOL)onlyFocused;
- (BOOL)hasFocusedExamples;
- (BOOL)hasChildren;
- (NSString *)message;
- (NSString *)fullText;
@end

@interface CDRExampleBase (RunReporting)
- (CDRExampleState)state;
- (float)progress;
@end
