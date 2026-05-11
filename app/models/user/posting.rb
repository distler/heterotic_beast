module User::Posting
  # Creates new topic and post.
  # Only..
  #  - sets sticky/locked bits if you're a moderator or admin
  #  - changes forum_id if you're an admin
  #
  def post(forum, attributes)
    # Normalize to symbol keys (legacy callers sometimes pass an
    # AR#attributes hash with string keys), then only mass-assign safe
    # fields. `sticky`, `locked`, and `forum_id` are moderator-only —
    # `revise_topic` gates them on `is_moderator`. Pre-Rails-4 this
    # was enforced by `attr_accessible`; under strong-parameters the
    # controller's permit list is too coarse.
    attrs      = attributes.to_h.symbolize_keys
    safe_attrs = attrs.slice(:title, :body)
    Topic.new(safe_attrs) do |topic|
      topic.forum = forum
      topic.user  = self
      revise_topic topic, attrs, moderator_of?(forum)
    end
  end

  def reply(topic, body)
    topic.posts.build(:body => body).tap do |post|
      post.site  = topic.site
      post.forum = topic.forum
      post.user  = self
      post.save
    end
  end

  def revise(record, attributes)
    is_moderator = moderator_of?(record.forum)
    return unless record.editable_by?(self, is_moderator)
    attrs = attributes.to_h.symbolize_keys
    case record
      when Topic then revise_topic(record, attrs, is_moderator)
      when Post  then post.save
      else raise "Invalid record to revise: #{record.class.name.inspect}"
    end
    record
  end

  protected

    def revise_topic(topic, attributes, is_moderator)
      topic.title = attributes[:title] if attributes.key?(:title)
      if is_moderator
        topic.sticky   = attributes[:sticky]   if attributes.key?(:sticky)
        topic.locked   = attributes[:locked]   if attributes.key?(:locked)
        topic.forum_id = attributes[:forum_id] if attributes[:forum_id].present?
      end
      topic.save
    end
end
