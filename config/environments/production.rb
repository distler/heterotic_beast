AlteredBeast::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  ####
  # This rotates the log file, keeping 25 files, of 1MB each.
  config.action_controller.logger = Logger.new(Rails.root.join('log', "#{Rails.env}.log"), 25, 1024000)

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true
  config.eager_load    = true

  # Compress JavaScripts and CSS
  config.assets.js_compressor  = :terser
  config.assets.css_compressor = :sass
  # Fall back to building any asset that wasn't precompiled
  config.assets.compile = true
  # Generate digests for assets URLs
  config.assets.digest = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (front-end serves files)
  config.serve_static_files = false if defined?(PhusionPassenger)

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true
  config.i18n.enforce_available_locales = false

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # URL for Tikz server
  # Tikz conversion is disabled if you comment this out
#  ENV['tikz_server'] = 'http://localhost:9292/'
end
