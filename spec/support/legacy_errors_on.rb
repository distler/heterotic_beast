# Rails 5 removed `ActiveModel::Errors#on(:attr)`. Replacement is
# `errors[:attr]` (always returns an Array, possibly empty). Several legacy
# specs still call `errors.on(:foo)` and check `should_not be_nil` —
# in the old API `on` returned nil/string/array, so re-add it as a thin
# alias of `errors[:attr].first` so the existing assertions read
# correctly.

ActiveModel::Errors.class_eval do
  unless method_defined?(:on)
    def on(attribute)
      messages = self[attribute]
      messages.size == 1 ? messages.first : (messages.empty? ? nil : messages)
    end
  end
end
