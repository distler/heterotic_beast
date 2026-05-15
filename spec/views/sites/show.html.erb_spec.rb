require File.dirname(__FILE__) + '/../../spec_helper'

describe "sites/show.html.erb" do
  define_models :sites_controller
  include SitesHelper
  
  before do
    @site = sites(:other)
    assign(:site, @site)
    view.stub(:admin?).and_return(false)
  end

  it "should render attributes in <p>" do
    render template: "sites/show"
  end
end

