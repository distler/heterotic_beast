xml.instruct! :xml, :version => "1.0"
xml.feed(:xmlns => "http://www.w3.org/2005/Atom") do |feed|
  feed.title "Posts for #{[@forum, @topic].compact * ' > '}"
  feed.link :href => request.url
  feed.updated((@posts.first || @topic || current_site).created_at.to_s(:rfc3339))
  feed.id  request.url
  for post in @posts do
    feed.entry do |entry|
      entry.id forum_topic_url(post.topic.forum, post.topic, 
                               :anchor => dom_id(post))
      entry.title post.topic
      entry.content "type" => 'xhtml' do
         entry << ("<div xmlns='http://www.w3.org/1999/xhtml'>\n" + post.body_html + "</div>\n")
      end
      entry.updated post.updated_at.to_s(:rfc3339)
      entry.link :href => forum_topic_url(post.topic.forum, post.topic, 
                                          :anchor => dom_id(post))

      entry.author do |author|
        author.name post.user
      end
    end
  end
end
