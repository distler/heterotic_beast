require File.dirname(__FILE__) + '/../spec_helper'

describe Moderatorship do
  define_models do
    model Moderatorship do
      stub :user => all_stubs(:user), :forum => all_stubs(:forum)
    end
    
    model Site do
      stub :other, :name => 'other'
    end
    
    model Forum do
      stub :other_site, :name => "Other", :site => all_stubs(:other_site)
    end
  end

  it "adds user/forum relation" do
    forums(:other).moderators.should == []
    lambda do
      forums(:other).moderators << users(:default)
    end.should change { Moderatorship.count }.by(1)
    forums(:other).moderators.reload.should == [users(:default)]
  end
  
  %w(user forum).each do |attr|
    it "requires #{attr}" do
      mod = new_moderatorship(:default)
      mod.send("#{attr}=", nil)
      mod.should_not be_valid
      mod.errors["#{attr}_id".to_sym].first.should_not be_nil
    end
  end
  
  it "doesn't add duplicate relation" do
    lambda do
      forums(:default).moderators << users(:default)
    end.should raise_error(ActiveRecord::RecordInvalid)
  end
  
  it "doesn't add relation for user and forum in different sites" do
    lambda do
      forums(:other_site).moderators << users(:default)
    end.should raise_error(ActiveRecord::RecordInvalid)
  end
  
  %w(forum user).each do |model|
    it "is cleaned up after a #{model} is deleted" do
      send(model.pluralize, :default).destroy
      lambda do
        moderatorships(:default).reload
      end.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

describe Forum, "#moderators" do
  define_models :moderators

  before do
    # `define_models :moderators` was a legacy plugin keyword that
    # pre-seeded these three records; the modern shim doesn't, so
    # create them explicitly. Two forums × two users, except (other
    # user, other forum) which the tests don't expect.
    Moderatorship.create!(user: users(:default), forum: forums(:default))
    Moderatorship.create!(user: users(:default), forum: forums(:other))
    Moderatorship.create!(user: users(:other),   forum: forums(:default))
  end

  it "finds moderators for forum" do
    forums(:default).moderators.sort_by(&:login).should == [users(:default), users(:other)]
    forums(:other).moderators.should == [users(:default)]
  end
end

describe User, "#forums" do
  define_models :moderators

  before do
    Moderatorship.create!(user: users(:default), forum: forums(:default))
    Moderatorship.create!(user: users(:default), forum: forums(:other))
    Moderatorship.create!(user: users(:other),   forum: forums(:default))
  end

  it "finds forums for users" do
    users(:default).forums.sort_by(&:name).should == [forums(:default), forums(:other)]
    users(:other).forums.should == [forums(:default)]
  end
end