require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  define_models :users

  it 'allows signup' do
    lambda do
      create_user
      response.should be_redirect      
    end.should change(User, :count).by(1)
  end

  it 'requires login on signup' do
    lambda do
      create_user(:login => nil)
      assigns[:user].errors.on(:login).should_not be_nil
      response.should be_success
    end.should_not change(User, :count)
  end
  
  it 'requires password on signup' do
    lambda do
      create_user(:password => nil)
      assigns[:user].errors.on(:password).should_not be_nil
      response.should be_success
    end.should_not change(User, :count)
  end
  
  it 'requires password confirmation on signup' do
    lambda do
      create_user(:password_confirmation => nil)
      assigns[:user].errors.on(:password_confirmation).should_not be_nil
      response.should be_success
    end.should_not change(User, :count)
  end

  it 'requires email on signup' do
    lambda do
      create_user(:email => nil)
      assigns[:user].errors.on(:email).should_not be_nil
      response.should be_success
    end.should_not change(User, :count)
  end
  
  it 'activates user' do
    sites(:default).users.authenticate(users(:pending).login, 'test99').should be_nil
    get :activate, :activation_code => users(:pending).activation_code
    response.should redirect_to('/forums')
    sites(:default).users.authenticate(users(:pending).login, 'test99').should == users(:pending)
    flash[:notice].should_not be_nil
  end
  
  it 'does not activate user without key' do
    get :activate
    flash[:notice].should be_nil
  end
  
  it 'does not activate user with blank key' do
    get :activate, :activation_code => ''
    flash[:notice].should be_nil
  end
  
  it 'activates the first user as admin' do
    User.delete_all
    create_user
    user = User.find_by(login: 'quire')
    user.register!
    user.activate!
    user.active?.should == true
    user.admin?.should == true
  end
  
  it "sends an email to the user on create" do
    create_user :login => "admin", :email => "admin@example.com"
    response.should be_redirect
    lambda{ create_user }.should change(ActionMailer::Base.deliveries, :size).by(1)
  end
  
  def create_user(options = {})
    post :create, :user => { :login => 'quire', :email => 'quire@example.com',
      :password => 'monkey', :password_confirmation => 'monkey' }.merge(options)
  end
end

describe UsersController, "GET #index" do
  define_models :stubbed
  before do
    current_site :default
    @controller.stub(:current_site).and_return(@site)
  end

  act! { get :index, :page => 2 }

  it "should make a paginated list of users available as @users" do
    @site.users.should_receive(:paginate).with(:page => 2).and_return "users"
    acting { assigns(:users).should == "users" }
  end

  describe "with search parameter" do
    define_models :stubbed
    act! { get :index, :q => "bob" }
    define_models do
      model User do
        stub :bob, :display_name => "Bob", :login => "robert"
        stub :rob, :display_name => "Robert", :login => "bob" 
        stub :robby, :display_name => "Robby", :login => "robby"
      end
    end
    it "should find users by name" do
      acting
      assigns(:users).should include(users(:bob))
    end
    it "should find users by login" do
      acting
      assigns(:users).should include(users(:rob))
    end
    it "should not include non-matching users" do
      acting
      assigns(:users).should_not include(users(:robby))
    end
  end
end

describe UsersController, "PUT #make_admin" do
  before do
    login_as :admin
    current_site :default
    @attributes = {'login' => "Default"}
  end
  
  describe UsersController, "(as admin, successful)" do
    define_models :users

    it "sets admin" do
      user = users(:default)
      user.admin.should be_false
      put :make_admin, :id => users(:default).id, :user => { :admin => "1" }
      user.reload.admin.should be_true
    end
    
    it "unsets admin" do
      user = users(:default)
      user.update_attribute :admin, true
      user.admin.should be_true
      put :make_admin, :id => users(:default).id, :user => { }
      user.reload.admin.should be_false
    end
  end
end

describe UsersController, "PUT #update" do
  define_models :users
  before do
    login_as :default
    current_site :default
    @attributes = {'login' => "Default"}
  end
  
  describe UsersController, "(successful save)" do
    define_models
    act! { put :update,{ :id => @user.id, :user => @attributes }}

    before do
      @user.stub(:save).and_return(true)
    end
    
    it_assigns :user, :flash => { :notice => :not_nil }
    it_redirects_to { settings_path }

    describe "updating from edit form" do
      define_models :stubbed
      %w(display_name website bio).each do |field|
        it "should update #{field}" do
          put :update, :id => @user.id, :user => { field => "test" }
          assigns(:user).attributes[field].should == "test"
        end
      end
      it "should update openid_url" do
        # Modern ruby-openid (2.7+) requires a URL scheme; the legacy
        # `'test'` → `'http://test/'` normalization is gone. Use a
        # well-formed URL instead.
        put :update, :id => @user.id, :user => { 'openid_url' => 'http://test/' }
        assigns(:user).attributes['openid_url'].should == 'http://test/'
      end
    end
  end
  
  describe UsersController, "(successful save, xml)" do
    define_models
    act! { put :update, :id => @user.id, :user => @attributes, :format => 'xml' }

    before do
      @user.stub(:save).and_return(true)
    end
    
    it_assigns :user
    it_renders :blank
  end

  describe UsersController, "(unsuccessful save)" do
    define_models
    act! { put :update, :id => @user.id, :user => {:email => ''} }
    
    it_assigns :user
    it_renders :template, :edit
  end
  
  describe UsersController, "(unsuccessful save, xml)" do
    define_models
    act! { put :update, :id => @user.id, :user => {:email => ''}, :format => 'xml' }
    
    it_assigns :user
    it_renders :xml, :status => :unprocessable_entity do
      assigns(:user).errors.to_xml
    end
  end
end

# Regression: UsersController#create called `@user.register` (no bang),
# which under AASM 5 transitions in memory only — state and the
# activation_code generated by the before_enter callback never reach the
# DB. Click-the-link lookup (state='pending', activation_code=...) then
# fails. Fix is `@user.register!` (and gating it on `.persisted?`).
describe UsersController, "POST #create persists pending state + activation_code" do
  before do
    sites(:default)
    users(:default)  # so the bootstrap auto-activate path doesn't fire
    User.where(login: 'signup-flow').destroy_all
    ActionMailer::Base.deliveries.clear
  end

  after { User.where(login: 'signup-flow').destroy_all }

  it "leaves the new user in :pending with a persisted activation_code" do
    post :create, :user => { :login                 => 'signup-flow',
                             :email                 => 'signup-flow@example.com',
                             :password              => 'secret123',
                             :password_confirmation => 'secret123' }
    user = User.find_by(login: 'signup-flow')
    expect(user).not_to be_nil
    expect(user.state).to            eq('pending')
    expect(user.activation_code).to  be_present
  end

  it "sends the signup_notification email (the one with the activation link)" do
    post :create, :user => { :login                 => 'signup-flow',
                             :email                 => 'signup-flow@example.com',
                             :password              => 'secret123',
                             :password_confirmation => 'secret123' }
    last = ActionMailer::Base.deliveries.last
    expect(last).not_to be_nil
    expect(last.subject).to match(/please activate your new account/i)
  end

  it "redirects so the user is told to check their email" do
    post :create, :user => { :login                 => 'signup-flow',
                             :email                 => 'signup-flow@example.com',
                             :password              => 'secret123',
                             :password_confirmation => 'secret123' }
    expect(response).to be_redirect
    expect(flash[:notice]).to match(/click the link in your email/i)
  end
end

# Regression: the "N topics, M posts" line on a user's profile used to
# read `@user.topics.size`, which is the `has_many :topics` association
# keyed on `topic.user_id` — i.e., topics the user STARTED. A user who
# only ever replied (a common case) thus saw "no topics" no matter how
# many topics they'd participated in. The view now derives the count
# from `@user.posts.select(:topic_id).distinct.count`, which counts
# distinct topics-participated-in.
describe UsersController, "GET #show renders 'topics participated in', not 'topics started'" do
  render_views

  before do
    sites(:default)
    users(:admin)
    @starter   = users(:default)
    @replier   = users(:other)
    @forum     = forums(:default)
    @topic     = topics(:default)  # started by @starter via the factory
    # @replier posts a reply on @starter's topic — this is the case the
    # old `@user.topics.size` got wrong.
    @replier.reply(@topic, 'a reply')
  end

  it "shows '1 topic' for a user who has replied to one topic but started none" do
    expect(@replier.topics.count).to eq(0)        # didn't start any
    expect(@replier.posts.count).to be >= 1        # but did reply

    get :show, :id => @replier.id
    expect(response.body).to match(/\b1 topic\b/)
    expect(response.body).not_to include('no topics')
  end

  it "still shows 'no topics' for a user with no posts at all" do
    silent = sites(:default).all_users.create!(login: 'silent', email: 'silent@example.com',
                                               password: 'secret123', password_confirmation: 'secret123',
                                               state: 'active')
    expect(silent.posts.count).to eq(0)

    get :show, :id => silent.id
    expect(response.body).to include('no topics')
  end
end

# Regression: the "E-mail me the link" reset-password form posts to
# /users (UsersController#create) with `:email => '...'`. The original
# code branched on `params[:user]` but the reset branch only did
# `@user.save if @user.valid?` and `@user.register! if @user.persisted?`
# — both no-ops for an existing active user — and then showed a flash
# saying "click the link in your email." Nothing was ever emailed.
#
# Fixed flow:
#   * POST /users {email: 'a@b'} → regenerate activation_code, send
#     UserMailer#password_reset, redirect to /login
#   * GET /activate/<code> for an *active* user → consume the code,
#     log them in, redirect to /settings
describe UsersController, "password reset: POST #create with :email" do
  before do
    sites(:default)
    users(:admin)
    @user = users(:default)
    ActionMailer::Base.deliveries.clear
  end

  it "regenerates the user's activation_code and emails them a login link" do
    old_code = @user.activation_code
    post :create, :email => @user.email

    @user.reload
    expect(@user.activation_code).not_to eq(old_code)
    expect(@user.activation_code).to be_present

    mail = ActionMailer::Base.deliveries.last
    expect(mail).not_to be_nil
    expect(mail.to).to       eq([@user.email])
    expect(mail.subject).to  match(/password reset/i)
    expect(mail.body.to_s).to include(@user.activation_code)
  end

  it "does not leak whether the email is on file" do
    expect {
      post :create, :email => 'nobody@example.com'
    }.not_to change { ActionMailer::Base.deliveries.count }
    # Same notice text regardless of hit/miss.
    expect(flash[:notice]).to match(/login link/i)
    expect(response).to redirect_to(login_path)
  end
end

describe UsersController, "GET #activate as password-reset login" do
  before do
    sites(:default)
    users(:admin)
    @user = users(:default)
    # Simulate the reset-email path having stamped a fresh code.
    @code = Digest::SHA1.hexdigest("regression-#{SecureRandom.hex}")
    @user.update_columns(activation_code: @code)
  end

  it "logs the user in, clears the code, and redirects to /settings" do
    get :activate, :activation_code => @code
    expect(session[:user_id]).to eq(@user.id)
    expect(@user.reload.activation_code).to eq('')
    expect(response).to redirect_to(settings_path)
  end

  it "still handles the signup-activation flow (pending → active)" do
    pending = users(:pending)
    get :activate, :activation_code => pending.activation_code
    expect(pending.reload.state).to eq('active')
    expect(response).to redirect_to('/forums')
  end
end
