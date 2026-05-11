## Heterotic Beast

All the features of Altered Beast, plus

* Markdown syntax (using Maruku instead of RedCloth).
* Full math support, using itex2MML. Serves MathML to
  capable browsers, and MathJax to others.
* Syntax colouring for code blocks.
* Built-in SVG editing (with embedded equations).
* With an optional install of [tex2svg](https://github.com/distler/tex2svg),
  supports Tikz. See [here](https://golem.ph.utexas.edu/wiki/instiki/show/Tikz)
  for more details.
* Updated for Rails 7

## Altered Beast

The popular rails-based Beast forum, rewritten from the ground up with the same database and views.

* updated for Rails 3
* full i18n (with German and English support)
* using rspec/model_stubbing
* added a state machine for user logins
* built-in multi-site support
* spam protection from akismet/viking
* forum authorization rules (public/private/invitation)
* email and atom feed support
* xml/json API (not 100% tested yet, fixing soon)
* highline based easy console installer
* internationalization via the I18n framework

Check out the code via git:

    git clone https://github.com/distler/heterotic_beast.git


## INSTALLATION

    $ git clone https://github.com/distler/heterotic_beast.git
    $ cd heterotic_beast
    $ bundle install --path vendor/bundle
    $ bundle exec rake app:bootstrap
    $ bundle exec rake assets:precompile

    Follow the instructions to create your database and load users.
    Configure how you want to deliver the signup emails in config/initializers/mail.rb .
    Start the application with 
    
    $ bundle exec rails server -e production
    
    and visit http://127.0.0.1:3000 to visit your new forum.
