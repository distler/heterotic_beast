require 'instiki_stringsupport'

class ItexController < ActionController::Metal

  def index
    tex = (params['tex'] || '').purify.strip
    self.content_type = 'application/mathml+xml'
    case params['display']
      when 'block'
        filter = :block_filter
      else
        filter = :inline_filter
      end
    if tex == ''
      self.response_body = "<math xmlns='http://www.w3.org/1998/Math/MathML' display='" +
        filter.to_s[/(.*?)_filter/] + "'/>"
      return
    end
    begin
      doc = parse_itex(tex, filter)
      # make sure the result is well-formed, before sending it off
      begin
        xmlparse(doc)
      rescue
        self.response_body = error("Ill-formed XML.")
        return
      end
      self.response_body = doc
      return
    rescue Itex2MML::Error => e
      self.response_body = error(e.to_s)
      return
    rescue
      self.response_body = error("Unknown Error")
      return
    end
  end  
  
  protected

  # plugable XML parser; falls back to REXML
  begin
    require 'nokogiri'
    def xmlparse(text)
      Nokogiri::XML(text) { |config| config.strict }
    end
  rescue LoadError
    require 'rexml/document'
    def xmlparse(text)
      REXML::Document.new(text)
    end
  end

  #error message to return
  def error(str)
    "<math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'><merror><mtext>" +
         str + "</mtext></merror></math>"
  end

  # itex2MML parser
  begin
    require 'itextomml'
    def parse_itex(tex, filter)
      Itex2MML::Parser.new.send(filter, tex).to_utf8
    end
  rescue LoadError
    def parse_itex(tex, filter)
      error("Please install the itex2MML Ruby bindings.")
    end  
  end
end 
