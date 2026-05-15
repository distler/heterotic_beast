require File.dirname(__FILE__) + '/../spec_helper'

describe ModeratorshipsController, "POST #create" do
  before do
    login_as :default
    @attributes = {'user_id' => users(:default).id.to_s, 'forum_id' => forums(:default).id.to_s}
  end
  
  describe ModeratorshipsController, "(successful creation)" do
    define_models
    act! { post :create, :moderatorship => @attributes }
    
    it_assigns :moderatorship, :flash => { :notice => :not_nil }
    it_redirects_to { user_path(users(:default)) }
  end

  describe ModeratorshipsController, "(unsuccessful creation)" do
    define_models
    act! { post :create, :moderatorship => @attributes.merge('forum_id' => '') }
    
    it_assigns :moderatorship, :flash => {:notice => nil, :error => nil}
    it_redirects_to { user_path(users(:default)) }
  end

  # These should definitely check the content of XML rendered at some point.
  describe ModeratorshipsController, "(successful creation, xml)" do
    define_models
    act! { post :create, :moderatorship => @attributes, :format => 'xml' }
    
    it_assigns :moderatorship, :headers => { :Location => lambda { moderatorship_url(assigns(:moderatorship)) } }
    it_renders :xml, :status => :created  do
      assigns(:moderatorship).to_xml
    end
  end
  
  describe ModeratorshipsController, "(unsuccessful creation, xml)" do
    define_models
    act! { post :create, :moderatorship => @attributes.merge('forum_id' => ''), :format => 'xml' }
    
    it_assigns :moderatorship
    it_renders :xml, :status => :unprocessable_entity do
      assigns(:moderatorship).errors.to_hash.to_xml
    end
  end
end

describe ModeratorshipsController, "DELETE #destroy" do
  define_models
  act! { delete :destroy, :id => @moderatorship.to_param }
  
  before do
    login_as :default
    @moderatorship = moderatorships(:default)
  end

  it_assigns :moderatorship
  it_redirects_to { user_path(@moderatorship.user) }
  
  describe ModeratorshipsController, "(xml)" do
    define_models
    act! { delete :destroy, :id => @moderatorship.to_param, :format => 'xml' }

    it_assigns :moderatorship
    it_renders :blank
  end
end
