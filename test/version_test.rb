# frozen_string_literal: true

require 'test_helper'

class VersionTest < Minitest::Test
  def test_version
    refute_nil ODBCAdapter::VERSION
  end
end
