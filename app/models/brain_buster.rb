# Inlined from the Rails-2.3-style brain_buster plugin (vendor/plugins/brain_buster).
# Captcha question/answer model.
require 'humane_integer'

class BrainBuster < ApplicationRecord
  VERSION = '0.8.3'

  def attempt?(string)
    string = string.strip.downcase
    if answer_is_integer?
      string == answer || string == HumaneInteger.new(answer.to_i).to_english
    else
      string == answer.downcase
    end
  end

  def self.find_random_or_previous(id = nil)
    id ? find_specific_or_fallback(id) : find_random
  end

  def self.random_function
    case connection.adapter_name.downcase
    when /sqlite/, /postgres/ then 'random()'
    else 'rand()'
    end
  end

  def self.find_random
    order(random_function).first
  end

  def self.find_specific_or_fallback(id)
    find(id)
  rescue ActiveRecord::RecordNotFound
    find_random
  end

  private

  def answer_is_integer?
    int_answer = answer.to_i
    int_answer != 0 || (int_answer == 0 && answer == '0')
  end
end
