# Be sure to restart your server when you modify this file.

# Drop the default Rails registration of text/html (which aliases
# application/xhtml+xml) so we can register HTML and XHTML as distinct
# Mime::Types. Set#unregister + re-register replaces the default.
Mime::Type.unregister(:html) if Mime::Type.lookup_by_extension(:html)
Mime::Type.register "text/html", :html
Mime::Type.register "application/xhtml+xml", :xhtml
