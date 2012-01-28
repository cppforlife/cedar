#import "HaveReceived.h"
#import "CDRSpy.h"

namespace Cedar { namespace Doubles {
    
    HaveReceived have_received(const SEL expectedSelector) {
        return HaveReceived(expectedSelector);
    }
    
    HaveReceived have_received(const char * expectedMethod) {
        return HaveReceived(NSSelectorFromString([NSString stringWithUTF8String:expectedMethod]));
    }

    HaveReceived::HaveReceived(const SEL expectedSelector)
    : Base<>(), expectedSelector_(expectedSelector) {
    }

    HaveReceived::~HaveReceived() {
        for (arguments_vector_t::const_iterator cit = arguments_.begin(); cit != arguments_.end(); ++cit) {
            delete *cit;
        }
        arguments_.clear();
    }

    /*virtual*/ NSString * HaveReceived::failure_message_end() const {
        NSMutableString *message = [NSMutableString stringWithFormat:@"have received message <%@>", NSStringFromSelector(expectedSelector_)];
        if (arguments_.size()) {
            [message appendString:@", with arguments: <"];
            for (arguments_vector_t::const_iterator cit = arguments_.begin(); cit != arguments_.end(); ++cit) {
                [message appendString:(*cit)->value_string()];
            }
            [message appendString:@">"];
        }
        return message;
    }

    bool HaveReceived::matches(id instance) const {
        for (NSInvocation *invocation in [instance sent_messages]) {
            if (this->matches_invocation(invocation)) {
                return true;
            }
        }
        return false;
    }

    bool HaveReceived::matches_invocation(NSInvocation * const invocation) const {
        return sel_isEqual(invocation.selector, expectedSelector_) && this->matches_arguments(invocation);
    }

    bool HaveReceived::matches_arguments(NSInvocation * const invocation) const {
        bool matches = true;
        
        size_t index = 2;
        for (arguments_vector_t::const_iterator cit = arguments_.begin(); cit != arguments_.end() && matches; ++cit, ++index) {
            const char *actualArgumentEncoding = [invocation.methodSignature getArgumentTypeAtIndex:index];
            NSUInteger actualArgumentSize;
            NSGetSizeAndAlignment(actualArgumentEncoding, &actualArgumentSize, nil);
            
            void * actualArgumentBytes;
            try {
                actualArgumentBytes = malloc(actualArgumentSize);
                [invocation getArgument:actualArgumentBytes atIndex:index];
                matches = (*cit)->matches_bytes(actualArgumentBytes);
                free(actualArgumentBytes);
            }
            catch (...) {
                free(actualArgumentBytes);
                throw;
            }
        }
        return matches;
    }

}}