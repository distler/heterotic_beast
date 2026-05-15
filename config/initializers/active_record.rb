require 'html_formatting'

class ActiveRecord::Base
  class << self
    attr_accessor :formatted_attributes
  end

  def self.formats_attributes(*attributes)
    (self.formatted_attributes ||= []).push *attributes
    before_save :format_attributes
    send :include, HtmlFormatting, ActionView::Helpers::TagHelper, ActionView::Helpers::TextHelper
  end

  def self.paginated_each(options = {}, &block)
    page = 1
    records = [nil]
    until records.empty? do 
      records = paginate(options.update(:page => page, :count => {:select => '*'}))
      records.each &block
      page += 1
    end
  end
end
