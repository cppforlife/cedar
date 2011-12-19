#import <Foundation/Foundation.h>
#import "Base.h"
#import "CDRSpecFailure.h"

#define CDR_VA(c)                   const A##c & a##c
#define CDR_2VA(c1, c2)             CDR_VA(c1), CDR_VA(c2)
#define CDR_4VA(c1, c2, c3, c4)     CDR_2VA(c1, c2), CDR_2VA(c3, c4)

#define CDR_TA(c)                   typename A##c
#define CDR_2TA(c1, c2)             CDR_TA(c1), CDR_TA(c2)
#define CDR_4TA(c1, c2, c3, c4)     CDR_2TA(c1, c2), CDR_2TA(c3, c4)

#define CDR_VAL(c)                  [NSValue valueWithBytes:&a##c objCType:@encode(A##c)]
#define CDR_2VAL(c1, c2)            CDR_VAL(c1), CDR_VAL(c2)
#define CDR_4VAL(c1, c2, c3, c4)    CDR_2VAL(c1, c2), CDR_2VAL(c3, c4)

@interface CDRReceiverObj : NSObject {
    id mock_;

    id object_;
    SEL selector_;
    NSArray *arguments_;
}

- (void)setObject:(id)object;
- (void)setSelector:(SEL)selector;
- (void)setArguments:(NSArray *)arguments;

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

        template<typename A1>
        Receive & with(const A1 &);

        template<typename A1, typename A2>
        Receive & with(const A1 &, const A2 &);

        template<CDR_2TA(1, 2), CDR_TA(3)>
        Receive & with(CDR_2VA(1, 2), CDR_VA(3));

        template<CDR_4TA(1, 2, 3, 4)>
        Receive & with(CDR_4VA(1, 2, 3, 4));

        template<CDR_4TA(1, 2, 3, 4), CDR_TA(5)>
        Receive & with(CDR_4VA(1, 2, 3, 4), CDR_VA(5));

        template<CDR_4TA(1, 2, 3, 4), CDR_2TA(5, 6)>
        Receive & with(CDR_4VA(1, 2, 3, 4), CDR_2VA(5, 6));

        template<CDR_4TA(1, 2, 3, 4), CDR_2TA(5, 6), CDR_TA(7)>
        Receive & with(CDR_4VA(1, 2, 3, 4), CDR_2VA(5, 6), CDR_VA(7));

        template<CDR_4TA(1, 2, 3, 4), CDR_4TA(5, 6, 7, 8)>
        Receive & with(CDR_4VA(1, 2, 3, 4), CDR_4VA(5, 6, 7, 8));

    protected:
        inline /*virtual*/ NSString * failure_message_end() const { return @"receive"; }

    private:
        CDRReceiverObj *receiver_obj;
    };

    inline Receive receive(const char *selector) {
        return Receive(NSSelectorFromString([NSString stringWithUTF8String:selector]));
    }

    inline Receive receive(SEL selector) {
        return Receive(selector);
    }

#pragma mark Generic
    template<typename U>
    bool Receive::matches(const U & actualValue) const {
        [this->receiver_obj setObject:actualValue];
        [this->receiver_obj construct];
        return YES;
    }

#pragma mark with(arg1, arg2, ...) (up to 8 args)
    template<typename A1>
    Receive & Receive::with(const A1 & a1) {
        [this->receiver_obj setArguments:[NSArray arrayWithObject:CDR_VAL(1)]];
        return *this;
    }

    template<typename A1, typename A2>
    Receive & Receive::with(const A1 & a1, const A2 & a2) {
        [this->receiver_obj setArguments:[NSArray arrayWithObjects:CDR_2VAL(1, 2), nil]];
        return *this;
    }

    template<CDR_2TA(1, 2), CDR_TA(3)>
    Receive & Receive::with(CDR_2VA(1, 2), CDR_VA(3)) {
        [this->receiver_obj setArguments:[NSArray arrayWithObjects:CDR_2VAL(1, 2), CDR_VAL(3), nil]];
        return *this;
    }

    template<CDR_4TA(1, 2, 3, 4)>
    Receive & Receive::with(CDR_4VA(1, 2, 3, 4)) {
        [this->receiver_obj setArguments:[NSArray arrayWithObjects:CDR_4VAL(1, 2, 3, 4), nil]];
        return *this;
    }

    template<CDR_4TA(1, 2, 3, 4), CDR_TA(5)>
    Receive & Receive::with(CDR_4VA(1, 2, 3, 4), CDR_VA(5)) {
        [this->receiver_obj setArguments:[NSArray arrayWithObjects:CDR_4VAL(1, 2, 3, 4), CDR_VAL(5), nil]];
        return *this;
    }

    template<CDR_4TA(1, 2, 3, 4), CDR_2TA(5, 6)>
    Receive & Receive::with(CDR_4VA(1, 2, 3, 4), CDR_2VA(5, 6)) {
        [this->receiver_obj setArguments:[NSArray arrayWithObjects:CDR_4VAL(1, 2, 3, 4), CDR_2VAL(5, 6), nil]];
        return *this;
    }

    template<CDR_4TA(1, 2, 3, 4), CDR_2TA(5, 6), CDR_TA(7)>
    Receive & Receive::with(CDR_4VA(1, 2, 3, 4), CDR_2VA(5, 6), CDR_VA(7)) {
        [this->receiver_obj setArguments:[NSArray arrayWithObjects:CDR_4VAL(1, 2, 3, 4), CDR_2VAL(5, 6), CDR_VAL(7), nil]];
        return *this;
    }

    template<CDR_4TA(1, 2, 3, 4), CDR_4TA(5, 6, 7, 8)>
    Receive & Receive::with(CDR_4VA(1, 2, 3, 4), CDR_4VA(5, 6, 7, 8)) {
        [this->receiver_obj setArguments:[NSArray arrayWithObjects:CDR_4VAL(1, 2, 3, 4), CDR_4VAL(5, 6, 7, 8), nil]];
        return *this;
    }

}}
