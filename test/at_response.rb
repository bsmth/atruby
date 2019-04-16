# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/atruby/atruby.rb'

class TestATResponse < Test::Unit::TestCase
  def test_response
    assert_nothing_raised do
      Atruby.new.getTimeout
    end
  end
end