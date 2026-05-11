# RSpec 3 dropped `be_true` and `be_false` (use `be_truthy`/`be_falsey` for
# value truthiness, or `be(true)`/`be(false)` for strict identity). Several
# legacy specs still call `should be_true` / `should be_false` — alias these
# rather than rewrite each callsite.

RSpec::Matchers.alias_matcher :be_true,  :be_truthy
RSpec::Matchers.alias_matcher :be_false, :be_falsey

# Rails 6 removed `Response#success?` (use `successful?`). Several specs
# still call `response.should be_success`; alias the matcher rather than
# rewrite each callsite.
RSpec::Matchers.alias_matcher :be_success, :be_successful
