require File.dirname(__FILE__) + '/../spec_helper'

module TopicCreatePostHelper
  def self.included(base)
    base.define_models
    
    base.before do
      @user  = users(:default)
      @attributes = {:body => 'booya', :title => 'foo'}
      @creating_topic = lambda { post! }
    end
  
    base.it "sets topic's last_updated_at" do
      @topic = post!
      @topic.should_not be_new_record
      @topic.reload.last_updated_at.should == @topic.posts.first.created_at
    end
  
    base.it "sets topic's last_user_id" do
      @topic = post!
      @topic.should_not be_new_record
      @topic.reload.last_user.should == @topic.posts.first.user
    end

    base.it "increments Topic.count" do
      @creating_topic.should change { Topic.count }.by(1)
    end
    
    base.it "increments Post.count" do
      @creating_topic.should change { Post.count }.by(1)
    end
    
    base.it "increments cached site topics_count" do
      @creating_topic.should change { sites(:default).reload.topics_count }.by(1)
    end
    
    base.it "increments cached forum topics_count" do
      @creating_topic.should change { forums(:default).reload.topics_count }.by(1)
    end
    
    base.it "increments cached site posts_count" do
      @creating_topic.should change { sites(:default).reload.posts_count }.by(1)
    end
    
    base.it "increments cached forum posts_count" do
      @creating_topic.should change { forums(:default).reload.posts_count }.by(1)
    end
    
    base.it "increments cached user posts_count" do
      @creating_topic.should change { users(:default).reload.posts_count }.by(1)
    end
  end

  def post!
    @user.post forums(:default), new_topic(:default, @attributes).attributes.merge(:body => @attributes[:body])
  end
end

describe User, "#post for users" do  
  include TopicCreatePostHelper
  
  it "ignores sticky bit" do
    @attributes[:sticky] = 1
    @topic = post!
    @topic.should_not be_sticky
  end
  
  it "ignores locked bit" do
    @attributes[:locked] = true
    @topic = post!
    @topic.should_not be_locked
  end
end

describe User, "#post for moderators" do
  include TopicCreatePostHelper
  
  before do
    @user.stub(:moderator_of?).and_return(true)
  end
  
  it "sets sticky bit" do
    @attributes[:sticky] = 1
    @topic = post!
    @topic.should be_sticky
  end
  
  it "sets locked bit" do
    @attributes[:locked] = true
    @topic = post!
    @topic.should be_locked
  end
end

describe User, "#post for admins" do
  include TopicCreatePostHelper
  
  before do
    @user.admin = true
  end
  
  it "sets sticky bit" do
    @attributes[:sticky] = 1
    @topic = post!
    @topic.should_not be_new_record
    @topic.should be_sticky
  end
  
  it "sets locked bit" do
    @attributes[:locked] = true
    @topic = post!
    @topic.should_not be_new_record
    @topic.should be_locked
  end
end

module TopicUpdatePostHelper
  def self.included(base)
    base.define_models
    
    base.before do
      @user  = users(:default)
      @topic = topics(:default)
      @attributes = {:body => 'booya'}
    end
  end
  
  def revise!
    @user.revise @topic, @attributes
  end
end

describe User, "#revise(topic) for users" do  
  include TopicUpdatePostHelper
  
  it "ignores sticky bit" do
    @attributes[:sticky] = 1
    revise!
    @topic.should_not be_sticky
  end
  
  it "ignores locked bit" do
    @attributes[:locked] = true
    revise!
    @topic.should_not be_locked
  end
end

describe User, "#revise(topic) for moderators" do
  include TopicUpdatePostHelper
  
  before do
    @user.stub(:moderator_of?).and_return(true)
  end
  
  it "sets sticky bit" do
    @attributes[:sticky] = 1
    revise!
    @topic.should be_sticky
  end
  
  it "sets locked bit" do
    @attributes[:locked] = true
    revise!
    @topic.should be_locked
  end
end

describe User, "#revise(topic) for admins" do
  include TopicUpdatePostHelper
  
  before do
    @user.admin = true
  end
  
  it "sets sticky bit" do
    @attributes[:sticky] = 1
    revise!
    @topic.should be_sticky
  end
  
  it "sets locked bit" do
    @attributes[:locked] = true
    revise!
    @topic.should be_locked
  end
end

describe User, "#reply" do
  define_models
  
  before do
    @user  = users(:default)
    @topic = topics(:default)
    @creating_post = lambda { post! }
  end
  
  it "doesn't post if topic is locked" do
    @topic.locked = true; @topic.save
    @post = post!
    @post.should be_new_record
  end

  it "sets topic's last_updated_at" do
    @post = post!
    @topic.reload.last_updated_at.should == @post.created_at
  end

  it "sets topic's last_user_id" do
    Topic.update_all 'last_user_id = 3'
    @post = post!
    @topic.reload.last_user.should == @post.user
  end
  
  it "increments Post.count" do
    @creating_post.should change { Post.count }.by(1)
  end
  
  it "increments cached topic posts_count" do
    @creating_post.should change { topics(:default).reload.posts_count }.by(1)
  end
  
  it "increments cached forum posts_count" do
    @creating_post.should change { forums(:default).reload.posts_count }.by(1)
  end
  
  it "increments cached site posts_count" do
    @creating_post.should change { sites(:default).reload.posts_count }.by(1)
  end
  
  it "increments cached user posts_count" do
    @creating_post.should change { users(:default).reload.posts_count }.by(1)
  end

  def post!
    @user.reply topics(:default), 'duane, i think you might be color blind.'
  end
end

# Regression: under strong-parameters, the Topic params hash for an admin
# may not include :forum_id (the form omits the hidden field on
# single-forum sites, and the controller's :forum_id permit is conditional).
# `revise_topic` used to unconditionally write `topic.forum_id =
# attributes[:forum_id]` for moderators, nulling out the value just set by
# `User#post`. Once forum_id is nil, `set_default_attributes` can't derive
# site_id either, and topic creation fails with "Site can't be blank, Forum
# can't be blank". Pin the present-key behavior in both create and revise.
describe User, "#post for admins (forum_id preservation)" do
  before do
    @user  = users(:admin)
    @forum = forums(:default)
  end

  it "leaves forum_id intact when :forum_id is absent from attributes" do
    topic = @user.post(@forum, :title => 'foo', :body => 'bar')
    expect(topic).not_to be_new_record
    expect(topic.forum_id).to eq(@forum.id)
    expect(topic.site_id).to  eq(@forum.site_id)
  end

  it "leaves forum_id intact when :forum_id is explicitly nil" do
    topic = @user.post(@forum, :title => 'foo', :body => 'bar', :forum_id => nil)
    expect(topic).not_to be_new_record
    expect(topic.forum_id).to eq(@forum.id)
  end

  it "still honors a moderator-supplied :forum_id when present" do
    other = forums(:other)
    topic = @user.post(@forum, :title => 'foo', :body => 'bar', :forum_id => other.id)
    expect(topic).not_to be_new_record
    expect(topic.forum_id).to eq(other.id)
  end
end

describe User, "#revise(topic) (forum_id preservation)" do
  before do
    @user  = users(:admin)
    @topic = topics(:default)
  end

  it "does not null out forum_id when the key is absent from attributes" do
    original_forum_id = @topic.forum_id
    @user.revise(@topic, :title => 'renamed')
    expect(@topic.reload.forum_id).to eq(original_forum_id)
  end
end