require File.dirname(__FILE__) + '/../spec_helper'

# Regression tests for the prototype-rails helper shims
# (`link_to_function`, `remote_function`) added to ApplicationHelper after the
# Rails 4 upgrade. Both helpers were extracted into the prototype-rails gem
# in Rails 4.0; the views here still call them, so we re-implemented them
# locally. These tests pin the contract to the views that consume the output.

describe ApplicationHelper, "#link_to_function" do
  include ApplicationHelper

  it "returns an <a> with onclick that runs the function and returns false" do
    html = link_to_function("Hide", "$('foo').hide()")
    expect(html).to match(/\A<a [^>]*>Hide<\/a>\z/)
    # content_tag escapes apostrophes in attribute values to &#39; — the
    # browser decodes them transparently, but the literal string contains
    # the entities, so match the escaped form.
    expect(html).to include(%{onclick="$(&#39;foo&#39;).hide(); return false;"})
    expect(html).to include('href="#"')
  end

  it "honors a custom :href option (used by /search-link in layouts/_head)" do
    html = link_to_function("Search", "", :href => "/", :id => "search-link")
    expect(html).to include('href="/"')
    expect(html).to include('id="search-link"')
  end

  it "preserves caller-supplied html_options other than href/onclick" do
    html = link_to_function("X", "doX()", :class => "utility", :id => "x")
    expect(html).to include('class="utility"')
    expect(html).to include('id="x"')
  end
end

describe ApplicationHelper, "#remote_function" do
  include ApplicationHelper

  before do
    # `remote_function` reaches up into controller-level CSRF helpers; stub
    # them so the helper can be exercised in isolation.
    allow(self).to receive(:protect_against_forgery?).and_return(true)
    allow(self).to receive(:request_forgery_protection_token).and_return("authenticity_token")
    allow(self).to receive(:form_authenticity_token).and_return("TOK")
    allow(self).to receive(:url_for) { |opts| opts.is_a?(String) ? opts : "/monitorships/1" }
  end

  it "emits a Prototype Ajax.Request call with the resolved URL" do
    js = remote_function(:url => "/monitorships/1")
    expect(js).to start_with("new Ajax.Request('/monitorships/1', {")
    expect(js).to end_with("})")
  end

  it "passes :method through as a quoted JS string when given" do
    js = remote_function(:url => "/monitorships/1", :method => :delete)
    expect(js).to include("method:'delete'")
  end

  it "embeds the CSRF token in `parameters` when forgery protection is on" do
    js = remote_function(:url => "/monitorships/1")
    expect(js).to include("parameters:'authenticity_token=' + encodeURIComponent('TOK')")
  end

  it "is html_safe so it can be interpolated into an inline onclick" do
    expect(remote_function(:url => "/x")).to be_html_safe
  end
end
