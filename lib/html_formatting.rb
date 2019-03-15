require 'itex_stringsupport'
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
        text = raw.gsub(/\\begin\{(tikzpicture|tikzcd)\}(.*?)\\end\{(tikzpicture|tikzcd)\}/m) { |match| get_svg($2, $1) }
        html = Maruku.new("\n" + text.purify.delete("\r").to_utf8,
             {:math_enabled => true,
              :math_numbered => ['\\[','\\begin{equation}']}).to_html
        write_attribute "#{attr}_html", xhtml_sanitize(html.gsub(
         /\A<div class="maruku_wrapper_div">\n?(.*?)\n?<\/div>\Z/m, '\1') ).html_safe
      end
    end
  end

  private

  def get_svg(tex, type)
    begin
      response = HTTParty.post(ENV['tikz_server'], body: { tex: tex, type: type }, timeout: 4)
      if response.code == 200
        svg = response.body.sub(/<\?xml .*?\?>\n/, '').chop
        # since the page may contain multiple tikz pictures, we need to make the glyph id's unique
        num = rand(10000)
        return svg.gsub(/(id=\"|xlink:href=\"#)glyph/, "\\1glyph#{num}-").gsub(/id=\"surface/, "id=\"surface#{num}-")
      else
        return '<div>Could not render Tikz code to SVG.</div>'
      end
    rescue Net::ReadTimeout => exception
      return '<div>The Tikz Server timed out or was unreachable.</div>'
    end
  end
end
