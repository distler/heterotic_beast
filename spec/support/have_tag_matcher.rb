# Minimal `have_tag` matcher to keep the legacy helper/view specs working.
# rspec-rails dropped its built-in `have_tag` (and its Webrat-era CSS-selector
# matchers) in 2.x; rspec-rails 4+ has nothing comparable. This shim covers
# the small subset of usage the legacy specs need:
#
#   html.should have_tag("a")                      # selector match
#   html.should have_tag("a[href='/users/1']")     # attribute selector
#   html.should have_tag("a.bar")                  # class selector
#   html.should have_tag("a", "exact text")        # selector + exact text
#
# The matcher works on any String (rendered HTML) — Nokogiri parses it as a
# fragment, runs the CSS selector, and (if a text argument is given) checks
# that at least one matched node's exact `.text` equals it.

require 'nokogiri'

RSpec::Matchers.define :have_tag do |selector, text = nil|
  match do |html|
    next false unless html.is_a?(String)
    @doc      = Nokogiri::HTML.fragment(html)
    @matches  = @doc.css(selector)
    next false if @matches.empty?
    text.nil? || @matches.any? { |n| n.text.strip == text.strip }
  end

  failure_message do |html|
    if @matches.nil? || @matches.empty?
      "expected #{html.inspect} to contain element matching #{selector.inspect}"
    else
      "expected #{html.inspect} to contain element #{selector.inspect} with text " \
        "#{text.inspect} but got: " + @matches.map { |n| n.text.inspect }.join(', ')
    end
  end

  failure_message_when_negated do |html|
    "expected #{html.inspect} NOT to contain element matching #{selector.inspect}" \
      "#{text ? " with text #{text.inspect}" : ''}"
  end
end
