# Rails 4.2's ActionController::TestResponse#recycle! re-runs the parent
# ActionDispatch::Response#initialize, which calls MonitorMixin's
# mon_initialize. Ruby 2.6 raises ThreadError if mon_initialize runs twice
# on the same object. Strip the MonitorMixin state before re-initializing.
#
# This patch can be removed when we upgrade to Rails 5+.

if Rails.version.start_with?('4.') && RUBY_VERSION >= '2.6'
  require 'action_controller/test_case'

  module ActionController
    class TestResponse < ActionDispatch::TestResponse
      def recycle!
        remove_instance_variable(:@mon_mutex) if instance_variable_defined?(:@mon_mutex)
        remove_instance_variable(:@mon_mutex_owner_object_id) if instance_variable_defined?(:@mon_mutex_owner_object_id)
        initialize
      end
    end
  end
end
