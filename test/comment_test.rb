require File.dirname(__FILE__) + '/test_helper.rb'

class CommentTest < Test::Unit::TestCase

  load_schema

  def test_truth
    assert_invalid Comment.new
  end

end