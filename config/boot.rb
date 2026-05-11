# Ruby 2.6 + Rails 6.0 compatibility: ActiveSupport patches into the
# Logger class before Ruby autoloads it. Pre-require here so the patch
# has something to mix into.
require 'logger'

require 'rubygems'
vend = File.join(File.dirname(__FILE__), '..', 'vendor')
Gem.use_paths File.join(vend, 'bundle', File.basename(Gem.dir)), (Gem.path + [File.join(vend, 'plugins', 'bundler')])

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

## If running on a sub-URI, uncomment and set this appropriately
## (note leading slash).
#ENV['RAILS_RELATIVE_URL_ROOT'] = "/forum"
