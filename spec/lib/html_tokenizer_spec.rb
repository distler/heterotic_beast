require File.dirname(__FILE__) + '/../spec_helper'
require 'html_tokenizer'

# These tests guard the inlined HTML::Tokenizer (lib/html_tokenizer.rb)
# against two regressions:
#
#   1. A frozen input must not blow up — the wiki passes user content
#      through the sanitizer many times, and any of those callers might
#      hand us a frozen string.
#
#   2. Astral-plane characters (U+10000 and up — e.g. mathematical
#      double-struck letters like U+1D538 𝔸, very much in scope for a
#      maths-flavoured forum) must round-trip unchanged.
#
#      An earlier draft of `initialize` called `text.encode`, which
#      Ruby transcodes to `Encoding.default_internal` when that's set
#      to something other than UTF-8 — and "something other than UTF-8"
#      typically can't represent astral chars, so they'd be replaced
#      with '?'. Using `text.dup` keeps the original encoding.
describe HTML::Tokenizer do
  def tokens_for(text)
    tokenizer = HTML::Tokenizer.new(text)
    out = []
    while (tok = tokenizer.next)
      out << tok
    end
    out
  end

  describe "with astral-plane characters" do
    let(:double_struck_a) { "\u{1D538}" }  # 𝔸  (mathematical double-struck A)

    it "preserves astral chars in plain text" do
      tokens_for("hello #{double_struck_a} world").should == ["hello #{double_struck_a} world"]
    end

    it "preserves astral chars inside tag bodies (text segments)" do
      input = "<p>The set #{double_struck_a} is a field.</p>"
      tokens_for(input).should == ["<p>", "The set #{double_struck_a} is a field.", "</p>"]
    end

    it "preserves astral chars inside double-quoted tag attributes" do
      input = %Q{<span title="#{double_struck_a}">x</span>}
      tokens_for(input).should == [%Q{<span title="#{double_struck_a}">}, "x", "</span>"]
    end

    it "preserves astral chars inside single-quoted tag attributes" do
      input = "<span title='#{double_struck_a}'>x</span>"
      tokens_for(input).should == ["<span title='#{double_struck_a}'>", "x", "</span>"]
    end

    it "survives a non-UTF-8 Encoding.default_internal" do
      # Simulate a host where `default_internal` is set to something that
      # can't represent astral chars. The earlier `.encode` call would
      # corrupt them here; `.dup` preserves them.
      prev = Encoding.default_internal
      begin
        Encoding.default_internal = Encoding::US_ASCII
        tokens_for(double_struck_a).should == [double_struck_a]
      ensure
        Encoding.default_internal = prev
      end
    end
  end

  describe "with frozen input" do
    it "does not raise when handed a frozen string" do
      input = "<p>hi</p>".freeze
      lambda { tokens_for(input) }.should_not raise_error
    end

    it "does not mutate the caller's frozen string" do
      input = "<p>hi</p>".freeze
      tokens_for(input)
      input.should == "<p>hi</p>"
      input.should be_frozen
    end
  end
end
