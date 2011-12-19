#import <Foundation/Foundation.h>
#import "Base.h"
#import "CDRSpecFailure.h"

@interface CDRReceiverObj : NSObject {
    id mock_;
    
    id object_;
    SEL selector_;
    NSArray *as_;
    BOOL hasArguments_;
    va_list arguments_;
}

- (void)setObject:(id)object;
- (void)setSelector:(SEL)selector;
- (void)setArguments:(va_list)arguments;
- (void)setAs:(NSArray *)as;

- (void)construct;
- (void)verify;
@end

namespace Cedar { namespace Matchers {
    class Receive : public Base {
    private:
        Receive & operator=(const Receive &);
    
    public:
        inline Receive(SEL selector) : Base() { 
            this->receiver_obj = [[CDRReceiverObj alloc] init]; // retains!
            [this->receiver_obj setSelector:selector];
        }
        
        inline ~Receive() {
            [this->receiver_obj release]; // balances retain in constructor
        }
        
        template<typename U>
        bool matches(const U &) const;
        
        template<typename U>
        Receive & with(const U &, ...);
        
        template<typename A1, typename A2, typename A3>
        Receive & with_args(const A1 &, const A2 &, const A3 &);
    
    protected:
        inline /*virtual*/ NSString * failure_message_end() const { return @"receive"; }
    
    private:
        SEL selector;
        CDRReceiverObj *receiver_obj;
    };
    
    inline Receive receive(const char *selector) {
        return Receive(NSSelectorFromString([NSString stringWithUTF8String:selector]));
    }

#pragma mark Generic
    template<typename U>
    bool Receive::matches(const U & actualValue) const {
        [this->receiver_obj setObject:actualValue];
        [this->receiver_obj construct];
        return YES;
    }
    
    template<typename U>
    Receive & Receive::with(const U & a1, ...) {
        va_list arguments;
        va_start(arguments, a1);
        [this->receiver_obj setArguments:arguments];
        va_end(arguments);
        return *this;
    }
    
    template<typename A1, typename A2, typename A3>
    Receive & Receive::with_args(const A1 & a1, const A2 & a2, const A3 & a3) {
        NSArray *args = [NSArray arrayWithObjects:
                            [NSValue valueWithBytes:&a1 objCType:@encode(A1)],
                            [NSValue valueWithBytes:&a2 objCType:@encode(A2)],
                            [NSValue valueWithBytes:&a3 objCType:@encode(A3)],
                             nil];
        [this->receiver_obj setAs:args];
        return *this;
    }
    
}}
