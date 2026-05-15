require File.dirname(__FILE__) + '/../../spec_helper'

describe "sites/new.html.erb" do
  define_models :sites_controller

  include SitesHelper
  
  before do
    @site = new_site(:new)
    assign(:site, @site)
  end

  it "should render new form" do
    render template: "sites/new"

    rendered.should have_tag("form[action='#{sites_path}'][method=post]")
  end
end


