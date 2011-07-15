require 'rubygems'
vend = File.join(File.dirname(__FILE__), '..', 'vendor')
Gem.use_paths File.join(vend, 'bundle', File.basename(Gem.dir)), (Gem.path + [File.join(vend, 'plugins', 'bundler')])

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
