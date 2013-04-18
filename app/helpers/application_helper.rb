require 'digest/md5'
module ApplicationHelper
  def feed_icon_tag(title, url)
    (@feed_icons ||= []) << { :url => url, :title => title }
    link_to image_tag('feed-icon.png', :size => '14x14', :alt => "Subscribe to #{title}"), url
  end

  def flash_messages
    flash.map do |name, message|
      content_tag :p, message, :class => [:notice, name].uniq.join(' ')
    end.join.html_safe if flash.present?
  end

  def pagination(collection)
    if collection.total_entries > 1
      "<p class='pages'>" + I18n.t('txt.pages', :default => 'Pages') + ": <strong>" + 
      will_paginate(collection, :inner_window => 10, :next_label => I18n.t('txt.page_next', :default => 'next'), :prev_label => I18n.t('txt.page_prev', :default => 'previous')) +
      "</strong></p>"
    end
  end

  def next_page(collection)
    unless collection.current_page == collection.total_entries or collection.total_entries == 0
      "<p style='float:right;'>" + link_to(I18n.t('txt.next_page', :default => 'next page'), { :page => collection.current_page.next }.merge(params.reject{|k,v| k=="page"})) + "</p>"
    end
  end

  def search_posts_title
    (@q.blank? ? I18n.t('txt.recent_posts', :default => 'Recent Posts') : I18n.t('txt.searching_for', :default => 'Searching for') + " '#{@q}'").tap do |title|
      title << " " + I18n.t('txt.by_user', :default => 'by %{user}', :user => @user.display_name) if @user
      title << " " + I18n.t('txt.in_forum', :default => 'in %{forum}', :forum => @forum.name) if @forum
    end
  end

  def topic_title_link(topic, options)
    if topic.title =~ /^\[([^\]]{1,15})\]((\s+)\w+.*)/
      "<span class='flag'>#{$1}</span>" + 
      link_to($2.strip, forum_topic_path(@forum, topic), options)
    else
      link_to(topic.title, forum_topic_path(@forum, topic), options)
    end
  end

  def avatar_for(user, size=32)
    t = " <svg class='photo' xmlns='http://www.w3.org/2000/svg' height='#{size-6}' width='#{size-6}'>\n" +
        "  <use xlink:href='#svg_logo_svg' xmlns:xlink='http://www.w3.org/1999/xlink'/>\n </svg>\n"
    t = "<object width='#{size}' height='#{size}' type='image/jpeg' data='https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(user.email.downcase.strip)}?rating=PG&amp;size=#{size}&amp;d=404'>\n" + t + "</object>" if (user.email and !(user.email.strip.empty?))
    t.html_safe
  end

  def modify_history(function, name, path, params_hash=nil)
    state = "null"
    query_string = "?"
    if params_hash
       state = params_hash.to_json
       params_hash.each { |k,v| query_string << "#{k}=#{v}&" }
    end
    query_string = query_string.chop
    %{history.#{function}(#{state}, '#{j(name)}', '#{j(path+query_string)}');}.html_safe
  end

  def search_path(atom = false)
    options = @q.blank? ? {} : {:q => @q}
    prefix = 
      if @topic
        options.update :topic_id => @topic, :forum_id => @forum
        :forum_topic
      elsif @forum
        options.update :forum_id => @forum
        :forum
      elsif @user
        options.update :user_id => @user
        :user
      else
        :search
      end
    atom ? send("#{prefix}_posts_path", options.update(:format => :atom)) : send("#{prefix}_posts_path", options)
  end

  def for_moderators_of(record, &block)
    capture(&block) if moderator_of?(record)
  end

  def ajax_spinner_for(id, spinner="spinner.gif")
    "<img src='#{asset_path spinner}' style='display:none; vertical-align:middle;' id='#{id.to_s}_spinner'/>".html_safe
  end

  def edited_on_tag(post)
    if (post.updated_at - post.created_at > 5.minutes)
      %{<p class='date'><abbr class='edited'  title="#{post.created_at.xmlschema}">#{I18n.t 'txt.post_edited',
          :when => time_ago_in_words(post.updated_at), :default => 'edited %{when} ago'}</abbr></p>}.html_safe
    end
  end

end
