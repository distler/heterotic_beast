# Rails 8's eager-load finisher iterates `config.eager_load_namespaces`
# and calls `.eager_load!` on every entry. The `rails-deprecated_sanitizer`
# gem (which we still need for `HTML::Tokenizer` in lib/sanitizer.rb)
# adds bare `Rails::HTML` to that list — a plain Module without an
# `eager_load!` method — which crashes the production boot:
#
#     undefined method `eager_load!' for Rails::HTML:Module (NoMethodError)
#       config.eager_load_namespaces.each(&:eager_load!)
#
# Stub a no-op so the iteration succeeds. The contents of Rails::HTML
# don't need to be eager-loaded — they're loaded eagerly anyway by the
# `require` chain rooted at lib/sanitizer.rb.
#
# Filename starts with `zz_` so it sorts after every other initializer;
# the patch needs to be in place before the framework's finisher runs.

if defined?(Rails::HTML) && Rails::HTML.is_a?(Module) && !Rails::HTML.respond_to?(:eager_load!)
  Rails::HTML.define_singleton_method(:eager_load!) { }
end
