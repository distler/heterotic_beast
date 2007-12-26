ModelStubbing.define_models do
  time 2007, 6, 15

  model Site do
    stub :name => 'default', :host => ''
  end

  model User do
    stub :login => 'normal-user', :email => 'normal-user@example.com', :state => 'active',
      :salt => '7e3041ebc2fc05a40c60028e2c4901a81035d3cd', :crypted_password => '00742970dc9e6319f8019fd54864d3ea740f04b1',
      :created_at => current_time - 5.days, :site => all_stubs(:site), :remember_token => 'foo-bar', :remember_token_expires_at => current_time + 5.days,
      :activation_code => '8f24789ae988411ccf33ab0c30fe9106fab32e9b', :activated_at => current_time - 4.days, :posts_count => 3
  end
  
  model Forum do
    stub :name => "Default", :topics_count => 2, :posts_count => 2, :position => 1, :state => 'public', :site => all_stubs(:site)
    stub :other, :name => "Other", :topics_count => 1, :posts_count => 1, :position => 0
  end
  
  model Topic do
    stub :forum => all_stubs(:forum), :user => all_stubs(:user), :title => "initial", :hits => 0, :sticky => 0, :posts_count => 1,
      :last_post_id => 1000, :last_updated_at => current_time - 5.days
    stub :other, :title => "Other", :last_updated_at => current_time - 4.days
    stub :other_forum, :forum => all_stubs(:other_forum)
  end

  model Post do
    stub :topic => all_stubs(:topic), :forum => all_stubs(:forum), :user => all_stubs(:user), :body => 'initial', :created_at => current_time - 5.days
    stub :other, :topic => all_stubs(:other_topic), :body => 'other', :created_at => current_time - 13.days
    stub :other_forum, :forum => all_stubs(:other_forum), :topic => all_stubs(:other_forum_topic)
  end
  
  model Moderatorship
  model Monitorship
end

ModelStubbing.define_models :stubbed, :insert => false