require File.dirname(__FILE__) + '/../../spec_helper'

describe "sites/index.html.erb" do
  include SitesHelper

  before do
    assign(:sites, Site.paginate(page: 1))
    view.stub(:admin?).and_return(false)
    view.stub(:current_site).and_return(nil)
  end

  it "should render list of sites" do
    render template: "sites/index"
  end
end

