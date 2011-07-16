require 'instiki_stringsupport'
require 'maruku'
require 'maruku/ext/math'
require 'sanitizer'

module HtmlFormatting
  protected
  include Sanitizer
  
  def format_attributes
    self.class.formatted_attributes.each do |attr|
      raw  = read_attribute attr
      if raw
        html = Maruku.new("\n" + raw.purify.delete("\r").to_utf8,
             {:math_enabled => true,
              :math_numbered => ['\\[','\\begin{equation}']}).to_html
        write_attribute "#{attr}_html", xhtml_sanitize(html.gsub(
         /\A<div class="maruku_wrapper_div">\n?(.*?)\n?<\/div>\Z/m, '\1') ).html_safe
      end
    end
  end
end
