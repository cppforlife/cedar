#import "Base.h"
#import "Argument.h"
#import "objc/runtime.h"

namespace Cedar { namespace Doubles {
    class HaveReceived : public Matchers::Base<> {
    private:
        HaveReceived & operator=(const HaveReceived &);

    public:
        explicit HaveReceived(const SEL);
        ~HaveReceived();
        // Allow default copy ctor.

        template<typename T>
        HaveReceived & with(const T & );

        template<typename T>
        HaveReceived & and_with(const T & argument) { return with(argument); }

        bool matches(id) const;

    protected:
        virtual NSString * failure_message_end() const;

    private:
        bool matches_invocation(NSInvocation * const invocation) const;
        bool matches_arguments(NSInvocation * const invocation) const;

    private:
        const SEL expectedSelector_;

        typedef std::vector<Argument *> arguments_vector_t;
        arguments_vector_t arguments_;
    };

    HaveReceived have_received(const SEL expectedSelector);
    HaveReceived have_received(const char * expectedMethod);

    template<typename T>
    HaveReceived & HaveReceived::with(const T & value) {
        Argument *arg = new TypedArgument<T>(value);

        arguments_.push_back(arg);
        return *this;
    }

}}
