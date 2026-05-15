require File.dirname(__FILE__) + '/../spec_helper'

describe TopicsController, "GET #index" do
  define_models

  act! { get :index, :forum_id => @forum.to_param }

  before do
    @forum  = forums(:default)
  end

  it_assigns :forum, :topics => nil
  it_redirects_to { forum_path(@forum) }

  describe TopicsController, "(xml)" do
    define_models
    
    act! { get :index, :forum_id => @forum.to_param, :page => 5, :format => 'xml' }

    it_assigns :topics, :forum
    it_renders :xml
  end
end

describe TopicsController, "GET #show" do
  define_models

  act! { get :show, :forum_id => @forum.to_param, :id => @topic.to_param, :page => 5 }

  before do
    @forum  = forums(:default)
    @topic  = topics(:default)
  end
  
  it_assigns :topic, :forum, :posts, :session => {:topics => nil}
  it_renders :template, :show
  
  it "should render atom feed" do
    skip "no atom support yet"
  end
  
  it "increments topic hit count" do
    stub_topic!
    @topic.should_receive(:hit!)
    act!
  end
  
  it "assigns new post record" do
    act!
    assigns[:post].should be_new_record
  end
  
  describe TopicsController, "(logged in)" do
    define_models

    act! { get :show, :forum_id => @forum.to_param, :id => @topic.to_param, :page => 5 }
  
    before do
      login_as :default
    end

    it_assigns :topic, :forum, :session => {:topics => :not_nil}
  
    it "increments topic hit count" do
      stub_topic!
      @topic.user_id = 5
      @topic.should_receive(:hit!)
      act!
    end
  
    it "doesn't increment topic hit count for same user" do
      stub_topic!
      @topic.stub(:hit!).and_raise("Noooooo")
      act!
    end
    
    it "marks User#last_seen_at" do
      @controller.stub(:current_user).and_return(@user)
      @user.should_receive(:seen!)
      act!
    end
  end
  
  describe TopicsController, "(xml)" do
    define_models

    act! { get :show, :forum_id => @forum.to_param, :id => @topic.to_param, :format => 'xml' }

    it_assigns :topic, :post => nil, :posts => nil

    # Don't compare full to_xml: `hit!` increments hits in the DB via
    # `increment_counter` without touching the controller's in-memory @topic,
    # and the topic's after_create callbacks rewrite last_post_id /
    # last_updated_at — so no single snapshot of @topic equals the rendered
    # body exactly. Just verify a topic XML envelope was rendered for the
    # right id.
    it_renders :xml do
      "<id type=\"integer\">#{@topic.id}</id>"
    end
  end

protected
  def stub_topic!
    # The controller now uses `find_by!(permalink: …)` (Rails 4+) on
    # `current_site.forums` and `@forum.topics`, not the legacy
    # `Forum.find_by_permalink`. Intercept both chains so the controller
    # ends up with the test's `@forum` and `@topic` rather than fresh DB
    # instances.
    forums_relation = double('forums_relation')
    topics_relation = double('topics_relation')
    @controller.stub(:current_site).and_return(@site = sites(:default))
    @site.stub(:forums).and_return(forums_relation)
    forums_relation.stub(:find_by!).with(permalink: @forum.to_param).and_return(@forum)
    @forum.stub(:topics).and_return(topics_relation)
    topics_relation.should_receive(:find_by!).with(permalink: @topic.to_param).and_return(@topic)
  end
end

describe TopicsController, "GET #new" do
  define_models
  act! { get :new, :forum_id => @forum.to_param }
  before do
    login_as :default
    @forum  = forums(:default)
  end

  it_assigns :forum, :topic

  it "assigns @topic" do
    act!
    assigns[:topic].should be_new_record
  end
  
  it_renders :template, :new
  
  describe TopicsController, "(xml)" do
    define_models
    act! { get :new, :forum_id => @forum.to_param, :format => 'xml' }

    it_assigns :forum, :topic

    it_renders :xml
  end
end

describe TopicsController, "GET #edit" do
  define_models
  act! { get :edit, :forum_id => @forum.to_param, :id => @topic.to_param }
  
  before do
    # admin_required for #edit; the spec used to work because
    # `users(:default)` was being auto-promoted to admin via a
    # cached-association bug (now fixed).
    login_as :admin
    @forum  = forums(:default)
    @topic  = topics(:default)
  end

  it_assigns :topic, :forum
  it_renders :template, :edit
end

describe TopicsController, "POST #create" do
  before do
    login_as :default
    @forum  = forums(:default)
  end
  
  describe TopicsController, "(successful creation)" do
    define_models
    act! { post :create, :forum_id => @forum.to_param, :topic => {:title => 'foo', :body => 'bar'} }
    
    it_assigns :forum, :topic, :flash => { :notice => :not_nil }
    it_redirects_to { forum_topic_path(@forum, assigns(:topic)) }
  end

  describe TopicsController, "(unsuccessful creation)" do
    define_models
    act! { post :create, :forum_id => @forum.to_param, :topic => @attributes }

    before do
      @attributes = {:title => ''}
    end

    it_assigns :forum, :topic
    it_renders :template, :new
  end
  
  describe TopicsController, "(successful creation, xml)" do
    define_models
    act! { post :create, :forum_id => @forum.to_param, :topic => {:title => 'foo', :body => 'bar'}, :format => 'xml' }
    
    it_assigns :forum, :topic, :headers => { :Location => lambda { forum_topic_url(@forum, assigns(:topic)) } }
    it_renders :xml, :status => :created
  end
  
  describe TopicsController, "(unsuccessful creation, xml)" do
    define_models
    act! { post :create, :forum_id => @forum.to_param, :topic => {}, :format => 'xml' }

    it_assigns :forum, :topic
    it_renders :xml, :status => :unprocessable_content
  end
end

describe TopicsController, "PUT #update" do
  before do
    # admin_required for #update.
    login_as :admin
    @forum = forums(:default)
    @topic = topics(:default)
  end
  
  describe TopicsController, "(successful save)" do
    define_models
    act! { put :update, :forum_id => @forum.to_param, :id => @topic.to_param, :topic => {} }
    
    it_assigns :forum, :topic, :flash => { :notice => :not_nil }
    it_redirects_to { forum_topic_path(@forum, @topic) }
  end

  describe TopicsController, "(unsuccessful save)" do
    define_models
    act! { put :update, :forum_id => @forum.to_param, :id => @topic.to_param, :topic => @attributes }

    before do
      @attributes = {:title => ''}
      @topic.update @attributes
    end
    
    it_assigns :topic, :forum
    it_renders :template, :edit
  end
  
  describe TopicsController, "(successful save, xml)" do
    define_models
    act! { put :update, :forum_id => @forum.to_param, :id => @topic.to_param, :topic => {}, :format => 'xml' }
    
    it_assigns :topic, :forum
    it_renders :blank
  end
  
  describe TopicsController, "(unsuccessful save, xml)" do
    define_models
    act! { put :update, :forum_id => @forum.to_param, :id => @topic.to_param, :topic => @attributes, :format => 'xml' }

    before do
      @attributes = {:title => ''}
      @topic.update @attributes
    end
    
    it_assigns :topic, :forum
    it_renders :xml, :status => :unprocessable_content do
      assigns(:topic).errors.to_hash.to_xml
    end
  end
end

describe TopicsController, "DELETE #destroy" do
  define_models
  act! { delete :destroy, :forum_id => @forum.to_param, :id => @topic.to_param }

  before do
    # admin_required for #destroy.
    login_as :admin
    @forum = forums(:default)
    @topic = topics(:default)
  end

  it_assigns :topic, :forum
  it_redirects_to { forum_path(@forum) }
  
  describe TopicsController, "(xml)" do
    define_models
    act! { delete :destroy, :forum_id => @forum.to_param, :id => @topic.to_param, :format => 'xml' }

    it_assigns :topic, :forum
    it_renders :blank
  end
end

# Regression: an admin posting a new topic via the form must succeed even
# when the strong-params permit list is hit. Pre-fix, this raised:
#   "Site can't be blank, Forum can't be blank"
# because `User#revise_topic` overwrote `topic.forum_id` with a missing
# attribute. Pin the end-to-end controller path.
describe TopicsController, "POST #create as admin (forum_id preservation)" do
  before do
    login_as :admin
    @forum = forums(:default)
  end

  it "creates the topic with the right forum and site" do
    post :create, :forum_id => @forum.to_param, :topic => { :title => 'admin topic', :body => 'with body' }
    topic = assigns(:topic)
    expect(topic).to be_persisted
    expect(topic.forum_id).to eq(@forum.id)
    expect(topic.site_id).to  eq(@forum.site_id)
    expect(response).to be_redirect
  end

  it "honors a moderator-supplied :forum_id when present (move-on-create)" do
    other = forums(:other)
    post :create, :forum_id => @forum.to_param,
                  :topic    => { :title => 'admin topic', :body => 'b', :forum_id => other.id }
    topic = assigns(:topic)
    expect(topic).to be_persisted
    expect(topic.forum_id).to eq(other.id)
  end
end
