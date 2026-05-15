source "https://rubygems.org"

gem 'rails', '~> 8.1.3'
gem 'test-unit'
gem 'ruby-openid', '>= 2.0.4', :require => "openid"
gem 'rexml'  # extracted from Ruby stdlib in 3.0; ruby-openid 2.x still requires it
gem 'pstore' # extracted from Ruby stdlib in 4.0; maruku's blahtex math engine requires it
gem 'cgi'    # extracted from Ruby stdlib in 4.0; rails-deprecated_sanitizer / actionpack require it
gem 'rack-openid'
gem 'open_id_authentication'
gem 'will_paginate', :git => 'https://github.com/distler/will_paginate.git'
gem "itextomml", ">=1.5.1"
gem 'puma'
gem 'sass-rails', "~> 6.0"
gem 'terser'      # ES6+ JS minifier; Uglifier was unmaintained since 2018 and chokes on `const`/`let`/arrow fns.
gem 'mini_racer'  # Embedded V8 for ExecJS — keeps the JS runtime in-process so we don't depend on a system Node.
gem 'httparty'

# Rails 4 extracted these from core:
gem 'rails-deprecated_sanitizer'     # restores HTML::Tokenizer / WhiteListSanitizer
gem 'activemodel-serializers-xml'    # `.to_xml` extracted from Active{Model,Record} in Rails 5

gem 'bcrypt', '~> 3.1'
gem 'acts_as_list'
gem 'aasm'
gem 'friendly_id', '~> 5.1.0'
gem 'nokogiri', "~> 1.16"
gem "syntax", "~> 1.1.0"
gem "maruku", :git => 'https://github.com/distler/maruku.git', :branch => 'nokogiri'
gem 'rake'

# Ruby 3.3+ ships `securerandom` as a default gem; Passenger's
# load order can pick a different version than the bundle resolves to,
# yielding `Gem::LoadError: can't activate securerandom-X, already
# activated securerandom-Y`. Pinning explicitly forces bundler to own
# the resolution.
gem 'securerandom'

group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'rspec-activemodel-mocks'
  gem 'factory_bot_rails', '~> 6.0'
  gem 'highline'
  gem 'sqlite3', '~> 2.1'
  # Rails 5 extracted `assigns` and `assert_template` into this gem.
  gem 'rails-controller-testing'
end

group :production do
#  gem 'trilogy'
  gem 'sqlite3', '~> 2.1'
end
